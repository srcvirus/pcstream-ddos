#ifndef __DEFINES_P4__
#define __DEFINES_P4__

const bit<16> ETH_TYPE_IPV4 = 0x800;
const bit<8> IP_TYPE_TCP = 0x06;
const bit<8> IP_TYPE_UDP = 0x14;

// Type definitions for different fields in packet headers.
typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;
typedef bit<16> port_t;

#endif // __DEFINES_P4__
