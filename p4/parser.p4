#ifndef __PARSER_P4__
#define __PARSER_P4__

#include "headers.p4"

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            ETH_TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        meta.fkey_sp_dp = 0;
        transition select(hdr.ipv4.protocol) {
           IP_TYPE_TCP: parse_tcp;
           IP_TYPE_UDP: parse_udp;
           default: accept;
        }
    }

    state parse_tcp {
        packet.extract(hdr.tcp);
        meta.fkey_sp_dp = hdr.tcp.srcPort++hdr.tcp.dstPort;
        transition accept;
    }

    state parse_udp {
        packet.extract(hdr.udp);
        meta.fkey_sp_dp = hdr.udp.srcPort++hdr.udp.dstPort;
        transition accept;
    }
}


#endif // __PARSER_P4__
