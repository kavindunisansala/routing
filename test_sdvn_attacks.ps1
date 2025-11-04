# SDVN Attack Testing Suite - PowerShell Version
# Tests all 5 SDVN attack types and their mitigation solutions

################################################################################
# Configuration
################################################################################

$NS3_PATH = if ($env:NS3_PATH) { $env:NS3_PATH } else { "." }
$ROUTING_SCRIPT = "routing"
$RESULTS_DIR = ".\results_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$SIM_TIME = 60
$VEHICLES = 18
$RSUS = 10
$TOTAL_NODES = $VEHICLES + $RSUS

# Performance thresholds
$BASELINE_PDR_MIN = 0.85
$ATTACK_PDR_MAX = 0.60
$MITIGATION_PDR_MIN = 0.75
$DETECTION_ACCURACY_MIN = 0.80
$OVERHEAD_MAX = 0.20

################################################################################
# Helper Functions
################################################################################

function Write-Header {
    param([string]$Message)
    Write-Host "`n================================================================" -ForegroundColor Blue
    Write-Host $Message -ForegroundColor Blue
    Write-Host "================================================================`n" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Cyan
}

function Setup-ResultsDir {
    Write-Info "Creating results directory: $RESULTS_DIR"
    
    $dirs = @(
        "$RESULTS_DIR\baseline\logs",
        "$RESULTS_DIR\baseline\csv",
        "$RESULTS_DIR\baseline\stats",
        "$RESULTS_DIR\wormhole\logs",
        "$RESULTS_DIR\wormhole\csv",
        "$RESULTS_DIR\wormhole\stats",
        "$RESULTS_DIR\blackhole\logs",
        "$RESULTS_DIR\blackhole\csv",
        "$RESULTS_DIR\blackhole\stats",
        "$RESULTS_DIR\sybil\logs",
        "$RESULTS_DIR\sybil\csv",
        "$RESULTS_DIR\sybil\stats",
        "$RESULTS_DIR\replay\logs",
        "$RESULTS_DIR\replay\csv",
        "$RESULTS_DIR\replay\stats",
        "$RESULTS_DIR\rtp\logs",
        "$RESULTS_DIR\rtp\csv",
        "$RESULTS_DIR\rtp\stats",
        "$RESULTS_DIR\summary"
    )
    
    foreach ($dir in $dirs) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
}

function Test-Baseline {
    Write-Header "TEST 1: BASELINE (No Attack)"
    
    $outputDir = "$RESULTS_DIR\baseline"
    Write-Info "Running baseline simulation..."
    
    Push-Location $NS3_PATH
    
    & .\waf.bat --run "scratch\$ROUTING_SCRIPT --simTime=$SIM_TIME --N_Vehicles=$VEHICLES --N_RSUs=$RSUS --enable_wormhole_attack=false --enable_blackhole_attack=false --enable_sybil_attack=false --enable_replay_attack=false --enable_rtp_attack=false" > "$outputDir\logs\baseline.log" 2>&1
    
    Pop-Location
    
    Write-Success "Baseline test completed"
}

function Test-WormholeAttack {
    Write-Header "TEST 2: WORMHOLE ATTACK"
    
    $outputDir = "$RESULTS_DIR\wormhole"
    
    # Without mitigation
    Write-Info "Running Wormhole attack without mitigation..."
    
    Push-Location $NS3_PATH
    
    & .\waf.bat --run "scratch\$ROUTING_SCRIPT --simTime=$SIM_TIME --N_Vehicles=$VEHICLES --N_RSUs=$RSUS --enable_wormhole_attack=true --use_enhanced_wormhole=true --wormhole_random_pairing=true --wormhole_start_time=10.0 --attack_percentage=0.20 --enable_wormhole_detection=false --enable_wormhole_mitigation=false" > "$outputDir\logs\wormhole_attack.log" 2>&1
    
    Write-Success "Wormhole attack test completed"
    
    # With mitigation
    Write-Info "Running Wormhole attack WITH mitigation..."
    
    & .\waf.bat --run "scratch\$ROUTING_SCRIPT --simTime=$SIM_TIME --N_Vehicles=$VEHICLES --N_RSUs=$RSUS --enable_wormhole_attack=true --use_enhanced_wormhole=true --wormhole_random_pairing=true --wormhole_start_time=10.0 --attack_percentage=0.20 --enable_wormhole_detection=true --enable_wormhole_mitigation=true --detection_latency_threshold=2.0" > "$outputDir\logs\wormhole_mitigation.log" 2>&1
    
    Pop-Location
    
    Write-Success "Wormhole mitigation test completed"
}

function Test-BlackholeAttack {
    Write-Header "TEST 3: BLACKHOLE ATTACK"
    
    $outputDir = "$RESULTS_DIR\blackhole"
    
    # Without mitigation
    Write-Info "Running Blackhole attack without mitigation..."
    
    Push-Location $NS3_PATH
    
    & .\waf.bat --run "scratch\$ROUTING_SCRIPT --simTime=$SIM_TIME --N_Vehicles=$VEHICLES --N_RSUs=$RSUS --enable_blackhole_attack=true --blackhole_drop_data=true --blackhole_advertise_fake_routes=true --blackhole_start_time=10.0 --blackhole_attack_percentage=0.15 --enable_blackhole_mitigation=false" > "$outputDir\logs\blackhole_attack.log" 2>&1
    
    Write-Success "Blackhole attack test completed"
    
    # With mitigation
    Write-Info "Running Blackhole attack WITH mitigation..."
    
    & .\waf.bat --run "scratch\$ROUTING_SCRIPT --simTime=$SIM_TIME --N_Vehicles=$VEHICLES --N_RSUs=$RSUS --enable_blackhole_attack=true --blackhole_drop_data=true --blackhole_advertise_fake_routes=true --blackhole_start_time=10.0 --blackhole_attack_percentage=0.15 --enable_blackhole_mitigation=true --blackhole_pdr_threshold=0.5" > "$outputDir\logs\blackhole_mitigation.log" 2>&1
    
    Pop-Location
    
    Write-Success "Blackhole mitigation test completed"
}

function Test-SybilAttack {
    Write-Header "TEST 4: SYBIL ATTACK"
    
    $outputDir = "$RESULTS_DIR\sybil"
    
    # Without mitigation
    Write-Info "Running Sybil attack without mitigation..."
    
    Push-Location $NS3_PATH
    
    & .\waf.bat --run "scratch\$ROUTING_SCRIPT --simTime=$SIM_TIME --N_Vehicles=$VEHICLES --N_RSUs=$RSUS --enable_sybil_attack=true --sybil_identities_per_node=3 --sybil_clone_legitimate_nodes=true --sybil_start_time=10.0 --sybil_attack_percentage=0.15 --enable_sybil_detection=false --enable_sybil_mitigation=false" > "$outputDir\logs\sybil_attack.log" 2>&1
    
    Write-Success "Sybil attack test completed"
    
    # With mitigation
    Write-Info "Running Sybil attack WITH mitigation..."
    
    & .\waf.bat --run "scratch\$ROUTING_SCRIPT --simTime=$SIM_TIME --N_Vehicles=$VEHICLES --N_RSUs=$RSUS --enable_sybil_attack=true --sybil_identities_per_node=3 --sybil_clone_legitimate_nodes=true --sybil_start_time=10.0 --sybil_attack_percentage=0.15 --enable_sybil_detection=true --enable_sybil_mitigation=true --enable_sybil_mitigation_advanced=true --use_trusted_certification=true --use_rssi_detection=true" > "$outputDir\logs\sybil_mitigation.log" 2>&1
    
    Pop-Location
    
    Write-Success "Sybil mitigation test completed"
}

function Test-ReplayAttack {
    Write-Header "TEST 5: REPLAY ATTACK"
    
    $outputDir = "$RESULTS_DIR\replay"
    
    # Without mitigation
    Write-Info "Running Replay attack without mitigation..."
    
    Push-Location $NS3_PATH
    
    & .\waf.bat --run "scratch\$ROUTING_SCRIPT --simTime=$SIM_TIME --N_Vehicles=$VEHICLES --N_RSUs=$RSUS --enable_replay_attack=true --replay_start_time=10.0 --replay_attack_percentage=0.10 --replay_interval=1.0 --enable_replay_detection=false --enable_replay_mitigation=false" > "$outputDir\logs\replay_attack.log" 2>&1
    
    Write-Success "Replay attack test completed"
    
    # With mitigation
    Write-Info "Running Replay attack WITH Bloom Filter mitigation..."
    
    & .\waf.bat --run "scratch\$ROUTING_SCRIPT --simTime=$SIM_TIME --N_Vehicles=$VEHICLES --N_RSUs=$RSUS --enable_replay_attack=true --replay_start_time=10.0 --replay_attack_percentage=0.10 --replay_interval=1.0 --enable_replay_detection=true --enable_replay_mitigation=true --bf_filter_size=8192 --bf_num_hash_functions=4" > "$outputDir\logs\replay_mitigation.log" 2>&1
    
    Pop-Location
    
    Write-Success "Replay mitigation test completed"
}

function Test-RTPAttack {
    Write-Header "TEST 6: ROUTING TABLE POISONING (RTP) ATTACK"
    
    $outputDir = "$RESULTS_DIR\rtp"
    
    # Without mitigation
    Write-Info "Running RTP attack without mitigation..."
    
    Push-Location $NS3_PATH
    
    & .\waf.bat --run "scratch\$ROUTING_SCRIPT --simTime=$SIM_TIME --N_Vehicles=$VEHICLES --N_RSUs=$RSUS --enable_rtp_attack=true --rtp_inject_fake_routes=true --rtp_fabricate_mhls=true --rtp_start_time=10.0 --rtp_attack_percentage=0.10 --enable_hybrid_shield_detection=false --enable_hybrid_shield_mitigation=false" > "$outputDir\logs\rtp_attack.log" 2>&1
    
    Write-Success "RTP attack test completed"
    
    # With mitigation
    Write-Info "Running RTP attack WITH HybridShield mitigation..."
    
    & .\waf.bat --run "scratch\$ROUTING_SCRIPT --simTime=$SIM_TIME --N_Vehicles=$VEHICLES --N_RSUs=$RSUS --enable_rtp_attack=true --rtp_inject_fake_routes=true --rtp_fabricate_mhls=true --rtp_start_time=10.0 --rtp_attack_percentage=0.10 --enable_hybrid_shield_detection=true --enable_hybrid_shield_mitigation=true" > "$outputDir\logs\rtp_mitigation.log" 2>&1
    
    Pop-Location
    
    Write-Success "RTP mitigation test completed"
}

function Generate-Summary {
    Write-Header "GENERATING SUMMARY REPORT"
    
    $summaryFile = "$RESULTS_DIR\summary\test_summary.txt"
    
    $summary = @"
================================================================================
SDVN ATTACK TESTING SUMMARY REPORT
================================================================================
Test Date: $(Get-Date)
Configuration:
  - Simulation Time: ${SIM_TIME}s
  - Vehicles: $VEHICLES
  - RSUs: $RSUS
  - Total Nodes: $TOTAL_NODES

================================================================================
PERFORMANCE THRESHOLDS
================================================================================
  - Baseline PDR (min):          $BASELINE_PDR_MIN
  - Attack PDR (max):             $ATTACK_PDR_MAX
  - Mitigation PDR (min):         $MITIGATION_PDR_MIN
  - Detection Accuracy (min):     $DETECTION_ACCURACY_MIN
  - Overhead (max):               $OVERHEAD_MAX

================================================================================
TEST RESULTS
================================================================================

All detailed logs are available in: $RESULTS_DIR

================================================================================
"@
    
    $summary | Out-File -FilePath $summaryFile
    
    Write-Success "Summary report generated: $summaryFile"
    Write-Host $summary
}

################################################################################
# Main Execution
################################################################################

Write-Header "SDVN ATTACK TESTING SUITE (PowerShell)"
Write-Info "Testing all 5 SDVN attack types and mitigation solutions"
Write-Info "Results will be saved to: $RESULTS_DIR"

Setup-ResultsDir

Test-Baseline
Test-WormholeAttack
Test-BlackholeAttack
Test-SybilAttack
Test-ReplayAttack
Test-RTPAttack

Generate-Summary

Write-Header "TESTING COMPLETE"
Write-Success "All tests finished. Check $RESULTS_DIR for detailed results."
