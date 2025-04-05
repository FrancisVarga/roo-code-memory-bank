#!/usr/bin/env python3
"""
Roo Code Memory Bank Configuration Installer
This script downloads and installs the latest configuration files 
from the Roo Code Memory Bank GitHub repository.
"""

import os
import sys
import json
import shutil
import tempfile
import platform
import urllib.request
import zipfile
import tarfile
import threading
import time
import atexit

# Repository information
GITHUB_REPO = "FrancisVarga/roo-code-memory-bank"
GITHUB_API_URL = f"https://api.github.com/repos/{GITHUB_REPO}/releases/latest"

def print_banner():
    """Print the installation banner."""
    print("--- Starting Roo Code Memory Bank Config Setup ---")

def check_python_version():
    """Check if Python version is compatible."""
    if sys.version_info < (3, 6):
        print("Error: This script requires Python 3.6 or higher.")
        sys.exit(1)

def get_latest_release_url():
    """Get the URL for the latest release package."""
    print("Fetching the latest release information...")
    
    # Set headers to avoid GitHub API rate limiting issues
    headers = {
        "Accept": "application/vnd.github.v3+json",
        "User-Agent": "Roo-Code-Memory-Bank-Installer"
    }
    
    req = urllib.request.Request(GITHUB_API_URL, headers=headers)
    
    try:
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode())
            
            # Determine which asset to download based on the operating system
            is_windows = platform.system() == "Windows"
            file_pattern = "roo-code-memory-bank.zip" if is_windows else "roo-code-memory-bank.tar.gz"
            
            for asset in data.get("assets", []):
                if file_pattern in asset.get("browser_download_url", ""):
                    return asset.get("browser_download_url")
            
            print(f"Error: Could not find {file_pattern} in the latest release.")
            sys.exit(1)
    except Exception as e:
        print(f"Error fetching latest release: {e}")
        sys.exit(1)
    
    return None

def download_file(url, target_path):
    """Download a file from the given URL to the target path."""
    print(f"Downloading from: {url}")
    try:
        with urllib.request.urlopen(url) as response, open(target_path, 'wb') as out_file:
            shutil.copyfileobj(response, out_file)
        return True
    except Exception as e:
        print(f"Error downloading file: {e}")
        return False

def extract_archive(archive_path, extract_dir):
    """Extract the downloaded archive."""
    print("Extracting configuration files...")
    try:
        if archive_path.endswith('.zip'):
            with zipfile.ZipFile(archive_path, 'r') as zip_ref:
                zip_ref.extractall(extract_dir)
        elif archive_path.endswith('.tar.gz'):
            with tarfile.open(archive_path, 'r:gz') as tar_ref:
                tar_ref.extractall(extract_dir)
        return True
    except Exception as e:
        print(f"Error extracting archive: {e}")
        return False

def copy_config_files(extract_dir, dest_dir):
    """Copy configuration files to the destination directory."""
    print("Copying configuration files to current directory...")
    try:
        config_dir = os.path.join(extract_dir, "config")
        for item in os.listdir(config_dir):
            src = os.path.join(config_dir, item)
            dst = os.path.join(dest_dir, item)
            if os.path.isfile(src):
                shutil.copy2(src, dst)
        return True
    except Exception as e:
        print(f"Error copying configuration files: {e}")
        return False

def schedule_self_deletion():
    """Schedule this script to delete itself after execution."""
    script_path = os.path.abspath(__file__)
    
    def delete_file():
        time.sleep(1)  # Wait a bit to make sure the script has finished executing
        try:
            os.remove(script_path)
        except:
            pass
    
    print(f"Scheduling self-deletion of {os.path.basename(script_path)}...")
    threading.Thread(target=delete_file, daemon=True).start()
    atexit.register(lambda: None)  # Placeholder to ensure atexit handler runs

def main():
    """Main installation function."""
    print_banner()
    check_python_version()
    
    # Create a temporary directory
    with tempfile.TemporaryDirectory() as temp_dir:
        # Get download URL for the latest release
        download_url = get_latest_release_url()
        if not download_url:
            print("Error: Could not determine download URL.")
            sys.exit(1)
        
        # Determine file extension based on URL
        file_ext = ".zip" if download_url.endswith(".zip") else ".tar.gz"
        archive_path = os.path.join(temp_dir, f"roo-code-memory-bank{file_ext}")
        
        # Download the release package
        if not download_file(download_url, archive_path):
            print("Error: Failed to download the release package.")
            sys.exit(1)
        
        # Extract the archive
        extract_dir = os.path.join(temp_dir, "extracted")
        os.makedirs(extract_dir, exist_ok=True)
        if not extract_archive(archive_path, extract_dir):
            print("Error: Failed to extract the archive.")
            sys.exit(1)
        
        # Copy config files to current directory
        current_dir = os.getcwd()
        if not copy_config_files(extract_dir, current_dir):
            print("Error: Failed to copy configuration files.")
            sys.exit(1)
    
    print("All configuration files installed successfully.")
    print("--- Roo Code Memory Bank Config Setup Complete ---")
    
    # Schedule this script to delete itself
    schedule_self_deletion()

if __name__ == "__main__":
    main()