#!/usr/bin/env python3
"""
Setup script for SDVN Attack Analysis dependencies
"""

import subprocess
import sys

def install_package(package_name):
    """Install a Python package using pip"""
    try:
        print(f"Installing {package_name}...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", package_name])
        print(f"✓ {package_name} installed successfully\n")
        return True
    except subprocess.CalledProcessError:
        print(f"✗ Failed to install {package_name}\n")
        return False

def check_package(package_name):
    """Check if a package is already installed"""
    try:
        __import__(package_name)
        print(f"✓ {package_name} already installed")
        return True
    except ImportError:
        print(f"✗ {package_name} not found")
        return False

def main():
    print("=" * 60)
    print("SDVN Attack Analysis - Dependency Setup")
    print("=" * 60)
    print()
    
    packages = {
        'pandas': 'pandas',
        'numpy': 'numpy',
        'matplotlib': 'matplotlib',
        'seaborn': 'seaborn'
    }
    
    print("Checking installed packages...")
    print("-" * 60)
    
    missing_packages = []
    for package_name, import_name in packages.items():
        if not check_package(import_name):
            missing_packages.append(package_name)
    
    print()
    
    if not missing_packages:
        print("✓ All required packages are already installed!")
        print()
        print("You can now run the analysis script:")
        print("  python3 analyze_attack_results.py attack_results_<timestamp>/")
        return 0
    
    print(f"Found {len(missing_packages)} missing package(s)")
    print("-" * 60)
    print()
    
    # Try to upgrade pip first
    print("Upgrading pip...")
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "--upgrade", "pip"])
        print("✓ pip upgraded\n")
    except subprocess.CalledProcessError:
        print("⚠ Could not upgrade pip, continuing anyway...\n")
    
    # Install missing packages
    failed_packages = []
    for package in missing_packages:
        if not install_package(package):
            failed_packages.append(package)
    
    print()
    print("=" * 60)
    print("Installation Summary")
    print("=" * 60)
    
    if not failed_packages:
        print("✓ All packages installed successfully!")
        print()
        print("You can now run the analysis script:")
        print("  python3 analyze_attack_results.py attack_results_<timestamp>/")
        return 0
    else:
        print("✗ Some packages failed to install:")
        for package in failed_packages:
            print(f"  - {package}")
        print()
        print("Try installing manually with:")
        print(f"  sudo apt-get install python3-pip")
        print(f"  pip3 install {' '.join(failed_packages)}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
