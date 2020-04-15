#ifndef __DATAPLANE_BUFFER_P4__
#define __DATAPLANE_BUFFER_P4__

#include "defines.p4"

control DPBuffer(in bit<11> n,
                 in bit<22> psize_ls,
                 in bit<31> iat_ls,
                 inout bit<48> curr_window_len) {
    register<bit<SKETCH_WIDTH>>(MAX_BUFFER_SIZE) buffer;

    // tail contains the index where the next entry will be written.
    register<bit<32>>(1) tail;

    bit<32> curr_tail = 0;
    apply {
        tail.read(curr_tail, 0);
        if (curr_tail + 1 >= MAX_BUFFER_SIZE || curr_window_len > MAX_WINDOW_SIZE) {
            curr_tail = 0;
            tail.write(0, 0);
        }
        else tail.write(0, curr_tail + 1);
        buffer.write(curr_tail, (bit<SKETCH_WIDTH>)(n++psize_ls++iat_ls));
    }
}
#endif // __DATAPLANE_BUFFER_P4__
