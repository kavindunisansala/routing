# Script to find ns-3 installation and compile routing.cc

Write-Host "Searching for ns-3 installation..." -ForegroundColor Cyan

# Common ns-3 installation paths
$possiblePaths = @(
    "C:\ns-3.35",
    "C:\ns-allinone-3.35\ns-3.35",
    "D:\ns-3.35",
    "D:\ns-allinone-3.35\ns-3.35",
    "$env:USERPROFILE\ns-3.35",
    "$env:USERPROFILE\ns-allinone-3.35\ns-3.35",
    "$env:USERPROFILE\Documents\ns-3.35",
    "C:\Program Files\ns-3.35"
)

$ns3Path = $null

# Check each possible path
foreach ($path in $possiblePaths) {
    if (Test-Path "$path\waf") {
        $ns3Path = $path
        Write-Host "Found ns-3 at: $ns3Path" -ForegroundColor Green
        break
    }
}

# If not found in common paths, search
if (-not $ns3Path) {
    Write-Host "Searching C: and D: drives..." -ForegroundColor Yellow
    $found = Get-ChildItem -Path "C:\", "D:\" -Filter "waf" -Recurse -ErrorAction SilentlyContinue -Depth 3 | 
             Where-Object { $_.Directory.Name -like "ns-3*" } | 
             Select-Object -First 1
    
    if ($found) {
        $ns3Path = $found.Directory.FullName
        Write-Host "Found ns-3 at: $ns3Path" -ForegroundColor Green
    }
}

if (-not $ns3Path) {
    Write-Host "ERROR: Could not find ns-3 installation!" -ForegroundColor Red
    Write-Host "Please manually specify the path to your ns-3 installation." -ForegroundColor Yellow
    Write-Host "Example: C:\ns-allinone-3.35\ns-3.35" -ForegroundColor Yellow
    exit 1
}

# Check if routing.cc exists in scratch directory
$scratchPath = Join-Path $ns3Path "scratch\routing.cc"
if (Test-Path $scratchPath) {
    Write-Host "routing.cc found in scratch directory" -ForegroundColor Green
    
    # Ask user if they want to overwrite with current version
    $response = Read-Host "Do you want to copy the current routing.cc to ns-3 scratch? (y/n)"
    if ($response -eq 'y') {
        Copy-Item "d:\routing - Copy\routing.cc" $scratchPath -Force
        Write-Host "Copied routing.cc to $scratchPath" -ForegroundColor Green
    }
} else {
    Write-Host "routing.cc not found in scratch directory" -ForegroundColor Yellow
    $response = Read-Host "Do you want to copy routing.cc to ns-3 scratch? (y/n)"
    if ($response -eq 'y') {
        Copy-Item "d:\routing - Copy\routing.cc" $scratchPath
        Write-Host "Copied routing.cc to $scratchPath" -ForegroundColor Green
    } else {
        Write-Host "Skipping copy" -ForegroundColor Yellow
        exit 0
    }
}

# Compile
Write-Host "`nCompiling ns-3..." -ForegroundColor Cyan
Set-Location $ns3Path

if (Test-Path "waf") {
    Write-Host "Running: python waf --run routing" -ForegroundColor Yellow
    python waf
} else {
    Write-Host "ERROR: waf not found in $ns3Path" -ForegroundColor Red
    exit 1
}

Write-Host "`nCompilation complete!" -ForegroundColor Green
Write-Host "To run with replay attack:" -ForegroundColor Cyan
Write-Host "  cd $ns3Path" -ForegroundColor White
Write-Host "  python waf --run 'routing --enable_replay_attack=true --enable_replay_detection=true --simTime=10'" -ForegroundColor White
