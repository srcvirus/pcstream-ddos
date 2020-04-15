#ifndef __DURATION_SKETCH_P4__
#define __DURATION_SKETCH_P4__

#include "defines.p4"

control DurationSketch (out bit<48> iat,
                        in hash_index_t  row1, 
                        in hash_index_t row2, 
                        in standard_metadata_t standard_metadata) {
    register<bit<48>>(NUM_SKETCH_ROWS) prev_ts_r1;
    register<bit<48>>(NUM_SKETCH_ROWS) prev_ts_r2;
    bit<48> ts_r1 = 0;
    bit<48> ts_r2 = 0;

    apply{
        prev_ts_r1.read(ts_r1, row1);
        prev_ts_r1.write(row1, standard_metadata.ingress_global_timestamp);
        prev_ts_r2.read(ts_r2, row2);
        prev_ts_r2.write(row2, standard_metadata.ingress_global_timestamp);
        if (ts_r1 == 0 || ts_r2 == 0) {
            iat = 0;
        } else {
            iat = (ts_r1 < ts_r2 ? ts_r1 : ts_r2);
            iat = standard_metadata.ingress_global_timestamp - iat;
        }
    }
}

#endif // __DURATION_SKETCH_P4__
