#ifndef __PARSER_P4__
#define __PARSER_P4__

#include "headers.p4"

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        /* TODO: add parser logic */
        transition accept;
    }
}


#endif // __PARSER_P4__
