#ifndef __HEADER_P4__
#define __HEADER_P4__

#include "defines.p4"

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

header tcp_t{
    port_t srcPort;
    port_t dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<4>  res;
    bit<1>  cwr;
    bit<1>  ece;
    bit<1>  urg;
    bit<1>  ack;
    bit<1>  psh;
    bit<1>  rst;
    bit<1>  syn;
    bit<1>  fin;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

header udp_t {
    port_t srcPort;
    port_t dstPort;
    bit<16> len;
    bit<16> checksum;
}

struct metadata {
    // Sketch indices.
    hash_index_t sip_row1;
    hash_index_t sip_row2;
    hash_index_t sip_dip_row1;
    hash_index_t sip_dip_row2;
    hash_index_t sp_dp_row1;
    hash_index_t sp_dp_row2;

    bit<N_WIDTH>        sip_n;
    bit<PSIZE_LS_WIDTH> sip_psize_ls;
    bit<IAT_LS_WIDTH>   sip_iat_ls;
    bit<N_WIDTH>        sip_dip_n;
    bit<PSIZE_LS_WIDTH> sip_dip_psize_ls;
    bit<IAT_LS_WIDTH>   sip_dip_iat_ls;
    bit<N_WIDTH>        sp_dp_n;
    bit<PSIZE_LS_WIDTH> sp_dp_psize_ls;
    bit<IAT_LS_WIDTH>   sp_dp_iat_ls;
}

struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    tcp_t        tcp;
    udp_t        udp;
}

#endif // __HEADER_P4__
