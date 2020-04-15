#ifndef __MONITORING_P4__
#define __MONITORING_P4__

#include "defines.p4"

control CMSketch (out bit<11> n,
                  out bit<22> psize_ls,
                  out bit<31> iat_ls,
                  in hash_index_t row1, 
                  in hash_index_t row2, 
                  in bit<48> iat,
                  in headers hdr, 
                  in standard_metadata_t standard_metadata,
                  inout bit<48> curr_window_len) {
    register<bit<SKETCH_WIDTH>>(NUM_SKETCH_ROWS) cms_r1;
    register<bit<SKETCH_WIDTH>>(NUM_SKETCH_ROWS) cms_r2;
    bit<64> buf1 = 0;
    bit<64> buf2 = 0;

    action update_sketch_entry(inout bit<64> buf) {
        buf[N_RANGE] = buf[N_RANGE] + 1;
        buf[PSIZE_LS_RANGE] = 
            buf[PSIZE_LS_RANGE] + 
                (bit<PSIZE_LS_WIDTH>)standard_metadata.packet_length;
        buf[IAT_LS_RANGE] = buf[IAT_LS_RANGE] + ((bit<IAT_LS_WIDTH>)iat);
    }

    action reset_sketch_entry(out bit<64> buf) {
        buf[N_RANGE] = 1;
        buf[PSIZE_LS_RANGE] = 
            (bit<PSIZE_LS_WIDTH>)standard_metadata.packet_length;
        buf[IAT_LS_RANGE] = (bit<IAT_LS_WIDTH>)iat;
    }

    action reset() {
        cms_r1.write(row1, 0);
        cms_r2.write(row2, 0);
    }

    apply{
        cms_r1.read(buf1, row1);
        if (curr_window_len < MAX_WINDOW_SIZE) {
            update_sketch_entry(buf1);
        } else {
            reset_sketch_entry(buf1);
        } 
        cms_r1.write(row1, buf1);
        cms_r2.read(buf2, row2);
        if (curr_window_len < MAX_WINDOW_SIZE) {
            update_sketch_entry(buf2);
        } else {
            reset_sketch_entry(buf2);
        }
        cms_r2.write(row2, buf2);
        n = buf1[N_RANGE] < buf2[N_RANGE] ? buf1[N_RANGE] : buf2[N_RANGE];
        psize_ls = buf1[PSIZE_LS_RANGE] < buf2[PSIZE_LS_RANGE] ? 
                    buf1[PSIZE_LS_RANGE] : buf2[PSIZE_LS_RANGE];
        iat_ls = buf1[IAT_LS_RANGE] < buf2[IAT_LS_RANGE] ? 
                    buf1[IAT_LS_RANGE] : buf2[IAT_LS_RANGE];
    }
}

#endif // __MONITORING_P4__
