#############################################################################
# SDVN Fixed Issues Validation Script (PowerShell Version)
# Date: November 6, 2025
# Purpose: Validate all committed fixes are working correctly
# Usage: .\validate_fixes.ps1
#############################################################################

# Configuration
$NS3_DIR = "$env:USERPROFILE\Downloads\ns-allinone-3.35\ns-3.35"
$RESULTS_DIR = "validation_results_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$ROUTING_SCRIPT = "routing"

#############################################################################
# Helper Functions
#############################################################################

function Print-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "========================================================================" -ForegroundColor Blue
    Write-Host $Message -ForegroundColor Blue
    Write-Host "========================================================================" -ForegroundColor Blue
    Write-Host ""
}

function Print-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Print-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Print-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Print-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

function Check-Environment {
    Print-Header "CHECKING ENVIRONMENT"
    
    if (-not (Test-Path $NS3_DIR)) {
        Print-Error "NS-3 directory not found: $NS3_DIR"
        Print-Info "Please update NS3_DIR variable in this script"
        exit 1
    }
    
    $routingFile = Join-Path $NS3_DIR "scratch\routing.cc"
    if (-not (Test-Path $routingFile)) {
        Print-Error "routing.cc not found in $NS3_DIR\scratch\"
        Print-Info "Please copy routing.cc to NS-3 scratch directory"
        exit 1
    }
    
    Print-Success "NS-3 directory found: $NS3_DIR"
    Print-Success "routing.cc found in scratch directory"
}

function Build-Project {
    Print-Header "BUILDING NS-3 PROJECT"
    
    Push-Location $NS3_DIR
    
    Print-Info "Running waf build..."
    $buildLog = "build.log"
    
    try {
        python waf build > $buildLog 2>&1
        if ($LASTEXITCODE -eq 0) {
            Print-Success "Build completed successfully"
            Pop-Location
            return $true
        } else {
            Print-Error "Build failed! Check build.log for details"
            Get-Content $buildLog -Tail 50
            Pop-Location
            exit 1
        }
    } catch {
        Print-Error "Build failed with exception: $_"
        Pop-Location
        exit 1
    }
}

function Run-Test {
    param(
        [int]$TestNum,
        [string]$TestName
    )
    
    $testDir = Join-Path $RESULTS_DIR ("test{0:D2}_{1}" -f $TestNum, $TestName)
    New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    
    Print-Info "Running Test $TestNum`: $TestName..."
    
    Push-Location $NS3_DIR
    
    $outputLog = Join-Path $testDir "output.log"
    
    try {
        python waf --run "$ROUTING_SCRIPT --test=$TestNum" > $outputLog 2>&1
        Pop-Location
        
        if ($LASTEXITCODE -eq 0) {
            Print-Success "Test $TestNum completed"
            return $true
        } else {
            Print-Error "Test $TestNum failed"
            return $false
        }
    } catch {
        Print-Error "Test $TestNum failed with exception: $_"
        Pop-Location
        return $false
    }
}

function Get-PDR {
    param([string]$LogFile)
    
    if (-not (Test-Path $LogFile)) {
        return $null
    }
    
    $content = Get-Content $LogFile
    $pdrLine = $content | Where-Object { $_ -match "Packet Delivery Ratio" } | Select-Object -Last 1
    
    if ($pdrLine -match "(\d+\.?\d*)%?") {
        return [double]$matches[1]
    }
    
    return $null
}

function Check-PDR {
    param(
        [string]$LogFile,
        [double]$MinPDR,
        [double]$MaxPDR = 100.0
    )
    
    $pdr = Get-PDR -LogFile $LogFile
    
    if ($null -eq $pdr) {
        Print-Warning "PDR not found in log"
        return @{ PDR = $null; Passed = $false }
    }
    
    $passed = ($pdr -ge $MinPDR) -and ($pdr -le $MaxPDR)
    
    return @{ PDR = $pdr; Passed = $passed }
}

#############################################################################
# Test Validation Functions
#############################################################################

function Validate-Baseline {
    Print-Header "FIX VALIDATION 1: Baseline Performance"
    
    Run-Test -TestNum 1 -TestName "baseline"
    
    $log = Join-Path $RESULTS_DIR "test01_baseline\output.log"
    $result = Check-PDR -LogFile $log -MinPDR 99.0
    
    if ($result.Passed) {
        Print-Success "Baseline test passed: PDR = $($result.PDR)%"
        return $true
    } else {
        Print-Error "Baseline test failed: PDR = $($result.PDR)% (expected >= 99%)"
        return $false
    }
}

function Validate-WormholeFix {
    Print-Header "FIX VALIDATION 2: Wormhole Timing Fix (Commit e91023f)"
    Print-Info "Issue: Wormhole tests showed 0% PDR"
    Print-Info "Fix: Changed default start time from 0.0s to 10.0s"
    Print-Info "Expected: PDR > 95%"
    
    Run-Test -TestNum 2 -TestName "wormhole_no_mitigation"
    Run-Test -TestNum 3 -TestName "wormhole_detection"
    Run-Test -TestNum 4 -TestName "wormhole_mitigation"
    
    $log2 = Join-Path $RESULTS_DIR "test02_wormhole_no_mitigation\output.log"
    $log3 = Join-Path $RESULTS_DIR "test03_wormhole_detection\output.log"
    $log4 = Join-Path $RESULTS_DIR "test04_wormhole_mitigation\output.log"
    
    $result2 = Check-PDR -LogFile $log2 -MinPDR 90.0
    $result3 = Check-PDR -LogFile $log3 -MinPDR 95.0
    $result4 = Check-PDR -LogFile $log4 -MinPDR 95.0
    
    Write-Host ""
    Write-Host "Results:"
    
    if ($result2.Passed) {
        Print-Success "Test 2 (No Mitigation): PDR = $($result2.PDR)%"
    } else {
        Print-Error "Test 2 (No Mitigation): PDR = $($result2.PDR)% (expected >= 90%)"
    }
    
    if ($result3.Passed) {
        Print-Success "Test 3 (Detection): PDR = $($result3.PDR)%"
    } else {
        Print-Error "Test 3 (Detection): PDR = $($result3.PDR)% (expected >= 95%)"
    }
    
    if ($result4.Passed) {
        Print-Success "Test 4 (Mitigation): PDR = $($result4.PDR)%"
    } else {
        Print-Error "Test 4 (Mitigation): PDR = $($result4.PDR)% (expected >= 95%)"
    }
    
    if ($result2.Passed -and $result3.Passed -and $result4.Passed) {
        Print-Success "Wormhole fix validated successfully!"
        return $true
    } else {
        Print-Error "Wormhole fix validation failed"
        return $false
    }
}

function Validate-BlackholeFix {
    Print-Header "FIX VALIDATION 3: Blackhole Infrastructure Protection (Commit fe878e4)"
    Print-Info "Issue: Test06 showed 31.58% PDR (worse than no mitigation at 73.68%)"
    Print-Info "Root Cause: Random selection chose RSU node 34 as attacker"
    Print-Info "Fix: Protected RSU nodes from being attackers + added fixed seed"
    Print-Info "Expected: Test06 PDR > 70% (should be comparable to Test05)"
    
    Run-Test -TestNum 5 -TestName "blackhole_no_mitigation"
    Run-Test -TestNum 6 -TestName "blackhole_detection"
    Run-Test -TestNum 7 -TestName "blackhole_mitigation"
    
    $log5 = Join-Path $RESULTS_DIR "test05_blackhole_no_mitigation\output.log"
    $log6 = Join-Path $RESULTS_DIR "test06_blackhole_detection\output.log"
    $log7 = Join-Path $RESULTS_DIR "test07_blackhole_mitigation\output.log"
    
    $result5 = Check-PDR -LogFile $log5 -MinPDR 60.0
    $result6 = Check-PDR -LogFile $log6 -MinPDR 70.0
    $result7 = Check-PDR -LogFile $log7 -MinPDR 85.0
    
    Write-Host ""
    Write-Host "Results:"
    
    if ($result5.Passed) {
        Print-Success "Test 5 (No Mitigation): PDR = $($result5.PDR)%"
    } else {
        Print-Warning "Test 5 (No Mitigation): PDR = $($result5.PDR)% (expected >= 60%)"
    }
    
    if ($result6.Passed) {
        Print-Success "Test 6 (Detection): PDR = $($result6.PDR)% ⭐ CRITICAL FIX!"
    } else {
        Print-Error "Test 6 (Detection): PDR = $($result6.PDR)% (expected >= 70%) ⭐ CRITICAL!"
    }
    
    if ($result7.Passed) {
        Print-Success "Test 7 (Mitigation): PDR = $($result7.PDR)%"
    } else {
        Print-Error "Test 7 (Mitigation): PDR = $($result7.PDR)% (expected >= 85%)"
    }
    
    # Check if Test06 is now better than or comparable to Test05
    Write-Host ""
    Print-Info "Comparing Test05 vs Test06:"
    Write-Host "  Test05 (No Mitigation): $($result5.PDR)%"
    Write-Host "  Test06 (Detection):     $($result6.PDR)%"
    
    if ($result6.PDR -ge ($result5.PDR - 5)) {
        Print-Success "Test06 is now comparable to Test05 (within 5% tolerance)"
        Print-Success "Infrastructure protection fix is working!"
    } else {
        Print-Error "Test06 still significantly worse than Test05"
        Print-Error "Infrastructure protection fix may not be working correctly"
        return $false
    }
    
    # Check for infrastructure protection logs
    if (Select-String -Path $log6 -Pattern "Protected infrastructure nodes" -Quiet) {
        Print-Success "Infrastructure protection logging detected"
    } else {
        Print-Warning "Infrastructure protection logs not found"
    }
    
    if ($result6.Passed) {
        Print-Success "Blackhole fix validated successfully!"
        return $true
    } else {
        Print-Error "Blackhole fix validation failed"
        return $false
    }
}

function Validate-RTPFix {
    Print-Header "FIX VALIDATION 6: RTP Probe Verification (Commit 0aae467)"
    Print-Info "Issue: ProbePacketsSent was 0"
    Print-Info "Fix: Enhanced MHL detection + synthetic probe mechanism"
    Print-Info "Expected: ProbePacketsSent > 0"
    
    Run-Test -TestNum 14 -TestName "rtp_no_mitigation"
    Run-Test -TestNum 15 -TestName "rtp_detection"
    Run-Test -TestNum 16 -TestName "rtp_mitigation"
    
    $log15 = Join-Path $RESULTS_DIR "test15_rtp_detection\output.log"
    
    Write-Host ""
    Print-Info "Checking probe verification..."
    
    $probesLine = Select-String -Path $log15 -Pattern "Probe Packets Sent:" | Select-Object -Last 1
    
    if ($probesLine) {
        $probeCount = [int]($probesLine.Line -replace '.*Probe Packets Sent:\s*', '')
        
        if ($probeCount -gt 0) {
            Print-Success "ProbePacketsSent: $probeCount (was 0 before fix) ⭐"
        } else {
            Print-Error "ProbePacketsSent: 0 (fix not working)"
            return $false
        }
    } else {
        Print-Error "ProbePacketsSent metric not found"
        return $false
    }
    
    # Check for probe logs
    if (Select-String -Path $log15 -Pattern "Sending probe packet" -Quiet) {
        Print-Success "Probe sending logs detected"
    } else {
        Print-Warning "Probe sending logs not found"
    }
    
    if (Select-String -Path $log15 -Pattern "MHL appears FABRICATED" -Quiet) {
        Print-Success "MHL fabrication detection logs found"
    } else {
        Print-Warning "MHL fabrication detection logs not found"
    }
    
    if ($probeCount -gt 0) {
        Print-Success "RTP probe verification fix validated successfully!"
        return $true
    } else {
        Print-Error "RTP probe verification fix validation failed"
        return $false
    }
}

function Validate-CombinedScenario {
    Print-Header "FIX VALIDATION 7: Combined Attack Scenario"
    Print-Info "Expected: PDR > 90% with all mitigations"
    
    Run-Test -TestNum 17 -TestName "combined_all_mitigations"
    
    $log17 = Join-Path $RESULTS_DIR "test17_combined_all_mitigations\output.log"
    $result17 = Check-PDR -LogFile $log17 -MinPDR 90.0
    
    Write-Host ""
    Write-Host "Results:"
    
    if ($result17.Passed) {
        Print-Success "Test 17 (Combined): PDR = $($result17.PDR)%"
        Print-Success "Combined scenario validated successfully!"
        return $true
    } else {
        Print-Warning "Test 17 (Combined): PDR = $($result17.PDR)% (expected >= 90%)"
        Print-Warning "Combined scenario could be improved with MitigationCoordinator"
        return $false
    }
}

#############################################################################
# Main Execution
#############################################################################

function Main {
    Print-Header "SDVN FIXED ISSUES VALIDATION"
    Write-Host "Date: $(Get-Date)"
    Write-Host "Results Directory: $RESULTS_DIR"
    Write-Host ""
    
    # Create results directory
    New-Item -ItemType Directory -Path $RESULTS_DIR -Force | Out-Null
    
    # Track overall status
    $totalTests = 0
    $passedTests = 0
    
    # Step 1: Check environment
    Check-Environment
    
    # Step 2: Build project
    Build-Project
    
    # Step 3: Validate fixes
    Write-Host ""
    Print-Info "Starting validation tests..."
    Write-Host ""
    
    # Baseline
    if (Validate-Baseline) { $passedTests++ }
    $totalTests++
    
    # Wormhole fix
    if (Validate-WormholeFix) { $passedTests++ }
    $totalTests++
    
    # Blackhole fix (CRITICAL)
    if (Validate-BlackholeFix) { $passedTests++ }
    $totalTests++
    
    # RTP fix (CRITICAL)
    if (Validate-RTPFix) { $passedTests++ }
    $totalTests++
    
    # Combined scenario
    if (Validate-CombinedScenario) { $passedTests++ }
    $totalTests++
    
    # Final status
    Print-Header "FINAL STATUS"
    Write-Host ""
    Write-Host "Validation Tests Passed: $passedTests / $totalTests"
    Write-Host ""
    
    if ($passedTests -eq $totalTests) {
        Print-Success "ALL FIXES VALIDATED SUCCESSFULLY! 🎉"
        Write-Host ""
        Print-Info "All committed fixes are working as expected."
        Print-Info "The SDVN security evaluation is complete and meets requirements."
    } elseif ($passedTests -ge ($totalTests - 1)) {
        Print-Warning "MOST FIXES VALIDATED ($passedTests/$totalTests)"
        Write-Host ""
        Print-Info "Minor issues detected. Review the logs for details."
    } else {
        Print-Error "SOME FIXES FAILED VALIDATION"
        Write-Host ""
        Print-Info "Please review the logs in $RESULTS_DIR for details."
        Print-Info "Re-run specific tests as needed."
    }
    
    Write-Host ""
    Print-Info "Results saved to: $RESULTS_DIR"
}

# Run main function
Main
