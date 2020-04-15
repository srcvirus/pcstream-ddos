/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

#include "dataplane_buffer.p4"
#include "defines.p4"
#include "duration_sketch.p4"
#include "headers.p4"
#include "monitoring.p4"
#include "parser.p4"

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {   
    apply {  }
}

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
                  
    DurationSketch() sip_dsketch;
    DurationSketch() sip_dip_dsketch;
    DurationSketch() sp_dp_dsketch;
    CMSketch() sip;
    CMSketch() sip_dip;
    CMSketch() sp_dp;
    DPBuffer() sip_buf;
    DPBuffer() sip_dip_buf;
    DPBuffer() sp_dp_buf;
    bit<48> sip_iat = 0;
    bit<48> sip_dip_iat = 0;
    bit<48> sp_dp_iat = 0;
    bit<48> curr_window_len = 0;

    register<bit<48>>(1) window_start_ts;
    action drop() {
        mark_to_drop(standard_metadata);
    }

    action compute_sketch_index() {
        hash(meta.sip_row1, HashAlgorithm.crc16, SKETCH_HASH_BASE,
                {hdr.ipv4.srcAddr}, SKETCH_HASH_MAX);
        hash(meta.sip_row2, HashAlgorithm.csum16, SKETCH_HASH_BASE,
                {hdr.ipv4.srcAddr}, SKETCH_HASH_MAX);
        hash(meta.sip_dip_row1, HashAlgorithm.crc16, SKETCH_HASH_BASE,
                {hdr.ipv4.srcAddr, hdr.ipv4.dstAddr}, SKETCH_HASH_MAX);
        hash(meta.sip_dip_row2, HashAlgorithm.csum16, SKETCH_HASH_BASE,
                {hdr.ipv4.srcAddr, hdr.ipv4.dstAddr}, SKETCH_HASH_MAX);
        hash(meta.sp_dp_row1, HashAlgorithm.crc16, SKETCH_HASH_BASE,
                {meta.fkey_sp_dp}, SKETCH_HASH_MAX);
        hash(meta.sp_dp_row2, HashAlgorithm.csum16, SKETCH_HASH_BASE,
                {meta.fkey_sp_dp}, SKETCH_HASH_MAX);
    }

    action update_window_start_ts() {
        window_start_ts.write(0, standard_metadata.ingress_global_timestamp);
    }

    // TODO: Fix the following hack.
    // This is a really bad hack for now. No IP-based forwarding. Currently the
    // switch has only two ports, each connected to a host. This action creates
    // a pipe between the two ports. If input port is 1 then output port is set
    // to 2, and vice-versa. This needs to be fixed.
    action forward(egressSpec_t dst_port, macAddr_t dst_mac) {
        standard_metadata.egress_spec = dst_port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dst_mac;
    }
    table port_exact {
        key = {
            standard_metadata.ingress_port : exact;
        }
        actions = {
            forward;
            NoAction;
        }
        default_action = NoAction;
        const entries = {
            (1) : forward(2, 48w0x080000000222);
            (2) : forward(1, 48w0x080000000111);
        }
    }
    table debug {
        key = {
            hdr.ipv4.srcAddr        : exact;
            hdr.ipv4.dstAddr        : exact;
            meta.sip_n              : exact;
            meta.sip_psize_ls       : exact;
            meta.sip_iat_ls         : exact;
            meta.sip_dip_n          : exact;
            meta.sip_dip_psize_ls   : exact;
            meta.sip_dip_iat_ls     : exact;
            meta.sp_dp_n            : exact;
            meta.sp_dp_psize_ls     : exact;
            meta.sp_dp_iat_ls       : exact;
        }
        actions = {
            NoAction;
        }
        default_action = NoAction;
    }

    apply {
        if (hdr.ipv4.isValid()) {
            // First compute the indices of different rows of different sketches
            // by applying hash function on appropriate set of header(s).
            compute_sketch_index();

            // Statistics in the data plane is computed for a fixed window size of
            // MAX_WINDOW_SIZE defined in defines.p4. Currently this is set to
            // 5 seconds. Statistics is reset reactively when a packet arrives.
            window_start_ts.read(curr_window_len, 0);
            curr_window_len = standard_metadata.ingress_global_timestamp - 
                                curr_window_len;
            if (curr_window_len > MAX_WINDOW_SIZE) {
                update_window_start_ts();
            }

            // Compute packet inter-arrival time for different flow aggregation
            // levels.
            sip_dsketch.apply(sip_iat, meta.sip_row1, meta.sip_row2, 
                                standard_metadata);
            sip_dip_dsketch.apply(sip_dip_iat, meta.sip_dip_row1, meta.sip_dip_row2, 
                                    standard_metadata);
            sp_dp_dsketch.apply(sp_dp_iat, meta.sp_dp_row1, meta.sp_dp_row2, 
                                    standard_metadata);

            // Then update all the sketches. Three different sketches contain
            // information aggregated based on three different keys, namely,
            // source_ip_address, (source_ip_address, destination_ip_address), and
            // (source_port, destination_port). 
            sip.apply(meta.sip_n, meta.sip_psize_ls, meta.sip_iat_ls, 
                        meta.sip_row1, meta.sip_row2, sip_iat, hdr, 
                        standard_metadata, curr_window_len); 
            sip_dip.apply(meta.sip_dip_n, meta.sip_dip_psize_ls, 
                            meta.sip_dip_iat_ls, meta.sip_dip_row1, 
                            meta.sip_dip_row2, sip_dip_iat, hdr, standard_metadata,
                            curr_window_len);
            sp_dp.apply(meta.sp_dp_n, meta.sp_dp_psize_ls, meta.sp_dp_iat_ls,
                            meta.sp_dp_row1, meta.sp_dp_row2, sp_dp_iat, hdr, 
                            standard_metadata, curr_window_len);
            
            // Once the sketches have been updated and the queried data is stored
            // instide metadata, update the data plane buffers with the monitoring
            // data.
            sip_buf.apply(meta.sip_n, meta.sip_psize_ls, meta.sip_iat_ls,
                            curr_window_len);
            sip_dip_buf.apply(meta.sip_dip_n, meta.sip_dip_psize_ls,
                                meta.sip_dip_iat_ls, curr_window_len);
            sp_dp_buf.apply(meta.sp_dp_n, meta.sp_dp_psize_ls, meta.sp_dp_iat_ls,
                                curr_window_len);
            hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
            debug.apply();
        }

        // Currently the following performs a switch port based forwarding. This
        // needs to be updated with IP-based forwarding.
        port_exact.apply();
    }
}

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {  }
}

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
     apply {
  update_checksum(
      hdr.ipv4.isValid(),
            { hdr.ipv4.version,
        hdr.ipv4.ihl,
              hdr.ipv4.diffserv,
              hdr.ipv4.totalLen,
              hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.fragOffset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.srcAddr,
              hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16);
    }
}

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
        packet.emit(hdr.udp);
    }
}

V1Switch(
    MyParser(),
    MyVerifyChecksum(),
    MyIngress(),
    MyEgress(),
    MyComputeChecksum(),
    MyDeparser()
) main;
