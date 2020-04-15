BUILD_DIR = build
PCAP_DIR = pcaps
LOG_DIR = logs

source = "pcstream-dp.p4"
P4C = p4c-bm2-ss
P4C_ARGS += --p4runtime-files $(BUILD_DIR)/$(source).p4info.txt

# compiled_json := "" # $(source:.p4=.json)

all: build

build: dirs compile_to_json

compile_to_json:
	$(P4C) --arch v1model --p4v 16 $(P4C_ARGS) -o $(BUILD_DIR)/$(source:.p4=.json) $(source)

dirs:
	mkdir -p $(BUILD_DIR) $(PCAP_DIR) $(LOG_DIR)

clean: 
	rm -f *.pcap
	rm -rf $(BUILD_DIR) $(PCAP_DIR) $(LOG_DIR)
