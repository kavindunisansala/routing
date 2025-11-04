#!/bin/bash

################################################################################
# Quick Test Script - Individual SDVN Attacks
# Run individual attack scenarios quickly for testing
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
NS3_PATH="${NS3_PATH:-.}"
ROUTING_SCRIPT="routing"
SIM_TIME=30
VEHICLES=18
RSUS=10

print_usage() {
    echo -e "${BLUE}Usage: $0 [attack_type] [with_mitigation]${NC}"
    echo ""
    echo "Attack types:"
    echo "  baseline    - Run baseline (no attack)"
    echo "  wormhole    - Test wormhole attack"
    echo "  blackhole   - Test blackhole attack"
    echo "  sybil       - Test Sybil attack"
    echo "  replay      - Test replay attack"
    echo "  rtp         - Test routing table poisoning"
    echo "  all         - Run all attacks"
    echo ""
    echo "Options:"
    echo "  with_mitigation - Enable mitigation (default: without)"
    echo ""
    echo "Examples:"
    echo "  $0 wormhole"
    echo "  $0 blackhole with_mitigation"
    echo "  $0 all"
}

run_baseline() {
    echo -e "${GREEN}Running BASELINE (no attack)...${NC}"
    
    cd "$NS3_PATH"
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        --enable_wormhole_attack=false \
        --enable_blackhole_attack=false \
        --enable_sybil_attack=false \
        --enable_replay_attack=false \
        --enable_rtp_attack=false"
}

run_wormhole() {
    local with_mitigation=$1
    
    echo -e "${GREEN}Running WORMHOLE attack $([ "$with_mitigation" = "true" ] && echo "WITH mitigation" || echo "WITHOUT mitigation")...${NC}"
    
    cd "$NS3_PATH"
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        
        --enable_wormhole_attack=true \
        --use_enhanced_wormhole=true \
        --wormhole_random_pairing=true \
        --wormhole_start_time=10.0 \
        --attack_percentage=0.20 \
        --enable_wormhole_detection=$([ "$with_mitigation" = "true" ] && echo "true" || echo "false") \
        --enable_wormhole_mitigation=$([ "$with_mitigation" = "true" ] && echo "true" || echo "false") \
        --detection_latency_threshold=2.0"
}

run_blackhole() {
    local with_mitigation=$1
    
    echo -e "${GREEN}Running BLACKHOLE attack $([ "$with_mitigation" = "true" ] && echo "WITH mitigation" || echo "WITHOUT mitigation")...${NC}"
    
    cd "$NS3_PATH"
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        
        --enable_blackhole_attack=true \
        --blackhole_drop_data=true \
        --blackhole_advertise_fake_routes=true \
        --blackhole_start_time=10.0 \
        --blackhole_attack_percentage=0.15 \
        --enable_blackhole_mitigation=$([ "$with_mitigation" = "true" ] && echo "true" || echo "false") \
        --blackhole_pdr_threshold=0.5"
}

run_sybil() {
    local with_mitigation=$1
    
    echo -e "${GREEN}Running SYBIL attack $([ "$with_mitigation" = "true" ] && echo "WITH mitigation" || echo "WITHOUT mitigation")...${NC}"
    
    cd "$NS3_PATH"
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        
        --enable_sybil_attack=true \
        --sybil_identities_per_node=3 \
        --sybil_clone_legitimate_nodes=true \
        --sybil_start_time=10.0 \
        --sybil_attack_percentage=0.15 \
        --enable_sybil_detection=$([ "$with_mitigation" = "true" ] && echo "true" || echo "false") \
        --enable_sybil_mitigation=$([ "$with_mitigation" = "true" ] && echo "true" || echo "false") \
        --use_trusted_certification=true \
        --use_rssi_detection=true"
}

run_replay() {
    local with_mitigation=$1
    
    echo -e "${GREEN}Running REPLAY attack $([ "$with_mitigation" = "true" ] && echo "WITH mitigation" || echo "WITHOUT mitigation")...${NC}"
    
    cd "$NS3_PATH"
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        
        --enable_replay_attack=true \
        --replay_start_time=10.0 \
        --replay_attack_percentage=0.10 \
        --replay_interval=1.0 \
        --replay_count_per_node=5 \
        --enable_replay_detection=$([ "$with_mitigation" = "true" ] && echo "true" || echo "false") \
        --enable_replay_mitigation=$([ "$with_mitigation" = "true" ] && echo "true" || echo "false") \
        --bf_filter_size=8192 \
        --bf_num_hash_functions=4"
}

run_rtp() {
    local with_mitigation=$1
    
    echo -e "${GREEN}Running RTP attack $([ "$with_mitigation" = "true" ] && echo "WITH mitigation" || echo "WITHOUT mitigation")...${NC}"
    
    cd "$NS3_PATH"
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        
        --enable_rtp_attack=true \
        --rtp_inject_fake_routes=true \
        --rtp_fabricate_mhls=true \
        --rtp_start_time=10.0 \
        --rtp_attack_percentage=0.10 \
        --enable_hybrid_shield_detection=$([ "$with_mitigation" = "true" ] && echo "true" || echo "false") \
        --enable_hybrid_shield_mitigation=$([ "$with_mitigation" = "true" ] && echo "true" || echo "false")"
}

run_all() {
    echo -e "${BLUE}Running ALL attack scenarios...${NC}\n"
    
    run_baseline
    echo -e "\n${YELLOW}---${NC}\n"
    
    run_wormhole "false"
    echo -e "\n${YELLOW}---${NC}\n"
    
    run_wormhole "true"
    echo -e "\n${YELLOW}---${NC}\n"
    
    run_blackhole "false"
    echo -e "\n${YELLOW}---${NC}\n"
    
    run_blackhole "true"
    echo -e "\n${YELLOW}---${NC}\n"
    
    run_sybil "false"
    echo -e "\n${YELLOW}---${NC}\n"
    
    run_sybil "true"
    echo -e "\n${YELLOW}---${NC}\n"
    
    run_replay "false"
    echo -e "\n${YELLOW}---${NC}\n"
    
    run_replay "true"
    echo -e "\n${YELLOW}---${NC}\n"
    
    run_rtp "false"
    echo -e "\n${YELLOW}---${NC}\n"
    
    run_rtp "true"
    
    echo -e "\n${GREEN}All tests completed!${NC}"
}

# Main
if [ $# -eq 0 ]; then
    print_usage
    exit 1
fi

ATTACK_TYPE=$1
WITH_MITIGATION="false"

if [ $# -eq 2 ] && [ "$2" = "with_mitigation" ]; then
    WITH_MITIGATION="true"
fi

case "$ATTACK_TYPE" in
    baseline)
        run_baseline
        ;;
    wormhole)
        run_wormhole "$WITH_MITIGATION"
        ;;
    blackhole)
        run_blackhole "$WITH_MITIGATION"
        ;;
    sybil)
        run_sybil "$WITH_MITIGATION"
        ;;
    replay)
        run_replay "$WITH_MITIGATION"
        ;;
    rtp)
        run_rtp "$WITH_MITIGATION"
        ;;
    all)
        run_all
        ;;
    *)
        echo -e "${RED}Unknown attack type: $ATTACK_TYPE${NC}"
        print_usage
        exit 1
        ;;
esac

echo -e "\n${GREEN}✓ Test completed successfully!${NC}"
