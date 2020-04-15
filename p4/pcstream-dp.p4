/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

#include "defines.p4"
#include "headers.p4"
#include "parser.p4"
#include "monitoring.p4"


control MyVerifyChecksum(inout headers hdr, inout metadata meta) {   
    apply {  }
}

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    CMSketch() sip;
    CMSketch() sip_dip;
    CMSketch() sp_dp;
    bit<48> iat = 0;

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

    // TODO: Fix the following hack.
    // This is a really bad hack for now. No IP-based forwarding. Currently the
    // switch has only two ports, each connected to a host. This action creates
    // a pipe between the two ports. If input port is 1 then output port is set
    // to 2, and vice-versa. This needs to be fixed.
    action forward() {
        standard_metadata.egress_spec = 2 - standard_metadata.ingress_port + 1;
    }

    apply {
        // First update all the sketches. Three different sketches contain
        // information aggregated based on three different keys, namely,
        // source_ip_address, (source_ip_address, destination_ip_address), and
        // (source_port, destination_port). 
        sip.apply(meta.sip_n, meta.sip_psize_ls, meta.sip_iat_ls, 
                    meta.sip_row1, meta.sip_row2, iat, hdr, standard_metadata); 
        sip_dip.apply(meta.sip_dip_n, meta.sip_dip_psize_ls, 
                        meta.sip_dip_iat_ls, meta.sip_dip_row1, 
                        meta.sip_dip_row2, iat, hdr, standard_metadata); 
        sp_dp.apply(meta.sp_dp_n, meta.sp_dp_psize_ls, meta.sp_dp_iat_ls, 
                    meta.sp_dp_row1, meta.sp_dp_row2, iat, hdr, standard_metadata); 

        // Currently the following performs a switch port based forwarding. This
        // needs to be updated with IP-based forwarding.
        forward();
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
