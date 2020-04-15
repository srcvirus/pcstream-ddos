#ifndef __DEFINES_P4__
#define __DEFINES_P4__

#define SKETCH_WIDTH        ((bit<32>)64)
#define NUM_SKETCH_ROWS     ((bit<32>)1024)
#define N_WIDTH             11
#define PSIZE_LS_WIDTH      22
#define IAT_LS_WIDTH        31
#define N_RANGE             10:0
#define PSIZE_LS_RANGE      32:11
#define IAT_LS_RANGE        63:33
#define SKETCH_HASH_BASE    ((bit<32>)0)    
#define SKETCH_HASH_MAX     ((NUM_SKETCH_ROWS) - 1)

const bit<16> ETH_TYPE_IPV4 = 0x800;
const bit<8> IP_TYPE_TCP = 0x06;
const bit<8> IP_TYPE_UDP = 0x14;

// Type definitions for different fields in packet headers.
typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;
typedef bit<16> port_t;

typedef bit<32> hash_index_t;

#endif // __DEFINES_P4__
