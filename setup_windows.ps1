# VS Code AI Setup Script for Windows
# This script configures a Windows system for AI research purposes

# Ensure PowerShell execution policy allows script execution
if ((Get-ExecutionPolicy) -ne 'Bypass' -and (Get-ExecutionPolicy) -ne 'Unrestricted') {
    Write-Host "This script requires elevated permissions to run."
    Write-Host "Please run PowerShell as Administrator and use 'Set-ExecutionPolicy Bypass -Scope Process' before running this script."
    exit
}

# Error handling
$ErrorActionPreference = "Stop"

# Define colors for console output
$RED = [System.ConsoleColor]::Red
$GREEN = [System.ConsoleColor]::Green
$YELLOW = [System.ConsoleColor]::Yellow
$BLUE = [System.ConsoleColor]::Blue

# Configuration
$API_KEYS_FILE = "$env:USERPROFILE\.ai-keys.json"
$DRY_RUN = $false
$FORCE_UPGRADE = $false  # Whether to force upgrade packages that are already installed

# Function to print messages
function Print-Message {
    param (
        [string]$messageType,
        [string]$message
    )
    
    switch ($messageType) {
        "info" { Write-Host "[INFO] $message" -ForegroundColor $BLUE }
        "success" { Write-Host "[SUCCESS] $message" -ForegroundColor $GREEN }
        "warning" { Write-Host "[WARNING] $message" -ForegroundColor $YELLOW }
        "error" { Write-Host "[ERROR] $message" -ForegroundColor $RED }
        "dryrun" { Write-Host "[DRY-RUN] Would execute: $message" -ForegroundColor $YELLOW }
        default { Write-Host "$message" }
    }
}

# Function to execute or simulate commands based on dry run mode
function Execute-Command {
    param (
        [string]$command
    )
    
    if ($DRY_RUN) {
        Print-Message "dryrun" "$command"
        return 0
    } else {
        Print-Message "info" "Executing: $command"
        
        try {
            # For PowerShell commands
            if ($command -match '^[a-zA-Z0-9]+\s') {
                Invoke-Expression $command
            } else {
                # For simple commands
                & cmd /c $command
            }
            
            if ($LASTEXITCODE -ne 0) {
                Print-Message "warning" "Command exited with code $LASTEXITCODE"
                return $LASTEXITCODE
            }
            
            return 0
        } catch {
            Print-Message "error" "Error executing command: $_"
            return 1
        }
    }
}

# Function to display help message
function Show-Help {
    Write-Host @"
VS Code AI Setup Script for Windows

Usage: .\setup_windows.ps1 [OPTIONS]

Options:
  -h, --help          Show this help message and exit
  -n, --dry-run       Run in dry-run mode (print commands without executing)
  -u, --force-upgrade Force upgrade of packages that are already installed

This script will configure a Windows system for AI research purposes.
It installs and configures required packages, VSCode, and AI extensions.

Quick install:
  .\setup_windows.ps1

Note: The script will properly prompt for Anthropic API keys during installation.
"@
}

# Parse command-line arguments
function Parse-Arguments {
    param (
        [string[]]$args
    )
    
    for ($i = 0; $i -lt $args.Count; $i++) {
        switch ($args[$i]) {
            { $_ -eq "-h" -or $_ -eq "--help" } {
                Show-Help
                exit 0
            }
            { $_ -eq "-n" -or $_ -eq "--dry-run" } {
                $script:DRY_RUN = $true
                Print-Message "warning" "Running in dry-run mode. No changes will be made."
            }
            { $_ -eq "-u" -or $_ -eq "--force-upgrade" } {
                $script:FORCE_UPGRADE = $true
                Print-Message "warning" "Force upgrade mode enabled. Packages will be upgraded even if already installed."
            }
            default {
                Print-Message "error" "Unknown option: $($args[$i])"
                Show-Help
                exit 1
            }
        }
    }
}

###########################################
# Phase 1: API Key Handling & Script Initialization
###########################################

# Simple function to check if a JSON file has required keys
function Validate-JsonKeys {
    param (
        [string]$file
    )
    
    $valid = $true
    $requiredKeys = @("cline", "kodu", "roocode")
    
    try {
        $content = Get-Content $file -Raw | ConvertFrom-Json
        
        foreach ($key in $requiredKeys) {
            if (-not ($content.PSObject.Properties.Name -contains $key)) {
                $valid = $false
                break
            }
        }
    } catch {
        $valid = $false
    }
    
    return $valid
}

# Function to open the Anthropic console for API keys
function Open-AnthropicConsole {
    if ($DRY_RUN) {
        Print-Message "dryrun" "Would open browser to https://console.anthropic.com/settings/keys"
    } else {
        Print-Message "info" "Opening browser to Anthropic console for API keys..."
        Start-Process "https://console.anthropic.com/settings/keys"
    }
}

# Function to handle API keys
function Setup-ApiKeys {
    if (Test-Path $API_KEYS_FILE) {
        Print-Message "info" "API keys file already exists at $API_KEYS_FILE"
        if ($DRY_RUN) {
            Print-Message "dryrun" "Would read existing API keys from $API_KEYS_FILE"
        } else {
            # Validate the existing file has the expected structure
            $validJson = Validate-JsonKeys $API_KEYS_FILE
            if (-not $validJson) {
                Print-Message "warning" "Existing API keys file does not have the expected structure."
                Print-Message "warning" "It should contain 'cline', 'kodu', and 'roocode' keys."
                Ask-ForApiKeys
            }
        }
    } else {
        Print-Message "info" "API keys file not found at $API_KEYS_FILE"
        Ask-ForApiKeys
    }
}

# Function to prompt for API keys and save them
function Ask-ForApiKeys {
    if ($DRY_RUN) {
        Print-Message "dryrun" "Would open browser to https://console.anthropic.com/settings/keys"
        Print-Message "dryrun" "Would prompt for Cline, Kodu, and Roocode API keys"
        Print-Message "dryrun" "Would save API keys to $API_KEYS_FILE"
    } else {
        # Open browser to the Anthropic console
        Open-AnthropicConsole
        
        Print-Message "info" "Please enter your API keys from https://console.anthropic.com/settings/keys"
        Print-Message "info" "When creating the keys, name them $env:USERNAME-cline, $env:USERNAME-kodu, $env:USERNAME-roocode as recommended"
        
        $clineKey = Read-Host "Enter your Cline API key"
        $koduKey = Read-Host "Enter your Kodu API key"
        $roocodeKey = Read-Host "Enter your Roocode API key"
        
        # Validate that the keys are not empty
        if ([string]::IsNullOrEmpty($clineKey) -or [string]::IsNullOrEmpty($koduKey) -or [string]::IsNullOrEmpty($roocodeKey)) {
            Print-Message "error" "All API keys are required. Please try again."
            Ask-ForApiKeys
            return
        }
        
        # Create JSON structure
        $jsonContent = @{
            "cline" = $clineKey
            "kodu" = $koduKey
            "roocode" = $roocodeKey
        } | ConvertTo-Json
        
        # Save to file
        $jsonContent | Out-File -FilePath $API_KEYS_FILE -Encoding utf8
        
        # Set permissions to restrict to user only
        $acl = Get-Acl $API_KEYS_FILE
        $acl.SetAccessRuleProtection($true, $false)
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, "FullControl", "Allow")
        $acl.AddAccessRule($rule)
        Set-Acl $API_KEYS_FILE $acl
        
        Print-Message "success" "API keys saved to $API_KEYS_FILE"
    }
}

###########################################
# Phase 2: Install Chocolatey & Core Packages
###########################################

# Check if Chocolatey is already installed
function Check-Chocolatey {
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Print-Message "success" "Chocolatey is already installed"
        return $true
    }
    
    Print-Message "info" "Chocolatey is not installed"
    return $false
}

# Install Chocolatey
function Install-Chocolatey {
    Print-Message "info" "Installing Chocolatey..."
    
    $installCmd = "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    
    if ($DRY_RUN) {
        Print-Message "dryrun" $installCmd
        return $true
    } else {
        try {
            Invoke-Expression $installCmd
            
            # Refresh environment variables
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            
            if (Get-Command choco -ErrorAction SilentlyContinue) {
                Print-Message "success" "Chocolatey has been successfully installed"
                return $true
            } else {
                Print-Message "error" "Chocolatey installation appears to have failed."
                return $false
            }
        } catch {
            Print-Message "error" "Failed to install Chocolatey: $_"
            return $false
        }
    }
}

# Check if a Chocolatey package is installed
function Is-PackageInstalled {
    param (
        [string]$packageName
    )
    
    if (choco list --local-only $packageName | Select-String -Pattern "^$packageName\s") {
        if ($DRY_RUN) {
            Print-Message "info" "Package $packageName is already installed (verified)"
        }
        return $true
    }
    
    return $false
}

# Install a Chocolatey package
function Install-ChocolateyPackage {
    param (
        [string]$packageName
    )
    
    if (Is-PackageInstalled $packageName) {
        if ($FORCE_UPGRADE) {
            Print-Message "info" "Package $packageName is already installed, but force upgrade is enabled"
            Upgrade-ChocolateyPackage $packageName
        } else {
            Print-Message "success" "Package $packageName is already installed"
        }
        return $true
    }
    
    Print-Message "info" "Installing package: $packageName"
    $installCmd = "choco install $packageName -y"
    
    if ($DRY_RUN) {
        Print-Message "dryrun" $installCmd
        return $true
    } else {
        $result = Execute-Command $installCmd
        
        if ($result -ne 0) {
            Print-Message "error" "Failed to install $packageName"
            return $false
        } else {
            Print-Message "success" "Successfully installed $packageName"
            
            # Refresh environment variables after installation
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            
            return $true
        }
    }
}

# Upgrade a Chocolatey package
function Upgrade-ChocolateyPackage {
    param (
        [string]$packageName
    )
    
    Print-Message "info" "Upgrading package: $packageName"
    $upgradeCmd = "choco upgrade $packageName -y"
    
    if ($DRY_RUN) {
        Print-Message "dryrun" $upgradeCmd
        return $true
    } else {
        $result = Execute-Command $upgradeCmd
        
        if ($result -ne 0) {
            Print-Message "warning" "Failed to upgrade $packageName, but continuing"
            return $false
        } else {
            Print-Message "success" "Successfully upgraded $packageName"
            
            # Refresh environment variables after upgrade
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            
            return $true
        }
    }
}

# Check if Google Chrome is installed
function Is-ChromeInstalled {
    if (Is-PackageInstalled "googlechrome") {
        Print-Message "success" "Google Chrome is already installed"
        return $true
    }
    
    # Additional check for Chrome installation outside of Chocolatey
    if (Test-Path "C:\Program Files\Google\Chrome\Application\chrome.exe" -or 
        Test-Path "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe") {
        Print-Message "success" "Google Chrome is already installed (detected in Program Files)"
        return $true
    }
    
    Print-Message "info" "Google Chrome is not installed"
    return $false
}

# Install Google Chrome
function Install-Chrome {
    if (Is-ChromeInstalled) {
        return $true
    }
    
    Print-Message "info" "Installing Google Chrome"
    return Install-ChocolateyPackage "googlechrome"
}

# Main function for package setup
function Setup-RequiredPackages {
    Print-Message "info" "Phase 2: Setting up package manager and required packages"
    
    # Define required packages
    $corePackages = @("git", "curl", "wget", "7zip", "notepadplusplus", "jq")
    $pythonPackages = @("python3")
    
    # Check and install Chocolatey if needed
    if (-not (Check-Chocolatey)) {
        if ($DRY_RUN) {
            Print-Message "dryrun" "Would install Chocolatey"
        } else {
            if (-not (Install-Chocolatey)) {
                Print-Message "error" "Chocolatey installation failed. Cannot proceed with package installation."
                return $false
            }
        }
    }
    
    # Install core packages
    Print-Message "info" "Installing core packages..."
    foreach ($package in $corePackages) {
        Install-ChocolateyPackage $package
    }
    
    # Install Python
    Print-Message "info" "Installing Python..."
    foreach ($package in $pythonPackages) {
        Install-ChocolateyPackage $package
    }
    
    # Install Google Chrome if needed
    Print-Message "info" "Checking for Google Chrome..."
    Install-Chrome
    
    Print-Message "success" "Phase 2: Required packages setup completed"
    return $true
}

###########################################
# Phase 3: Install NVM & Latest LTS Node
###########################################

# Define NVM paths
$NVM_DIR = "$env:USERPROFILE\AppData\Roaming\nvm"
$NVM_INSTALL_URL = "https://github.com/coreybutler/nvm-windows/releases/download/1.1.11/nvm-setup.exe"
$NVM_SETUP = "$env:TEMP\nvm-setup.exe"

# Check if NVM is already installed
function Is-NvmInstalled {
    if (Test-Path $NVM_DIR) {
        # Check if nvm command works
        try {
            if (Get-Command nvm -ErrorAction SilentlyContinue) {
                Print-Message "success" "NVM is already installed at $NVM_DIR"
                return $true
            }
        } catch {
            # Command might exist but not be in path
        }
        
        # Check for nvm.exe directly
        if (Test-Path "$NVM_DIR\nvm.exe") {
            Print-Message "success" "NVM is already installed at $NVM_DIR"
            return $true
        }
    }
    
    Print-Message "info" "NVM is not installed"
    return $false
}

# Install NVM for Windows
function Install-Nvm {
    if (Is-NvmInstalled) {
        return $true
    }
    
    Print-Message "info" "Installing NVM for Windows..."
    
    if ($DRY_RUN) {
        Print-Message "dryrun" "Would download NVM installer from $NVM_INSTALL_URL"
        Print-Message "dryrun" "Would run NVM installer"
        return $true
    } else {
        # Download the installer
        Print-Message "info" "Downloading NVM installer..."
        try {
            Invoke-WebRequest -Uri $NVM_INSTALL_URL -OutFile $NVM_SETUP
        } catch {
            Print-Message "error" "Failed to download NVM installer: $_"
            return $false
        }
        
        # Run the installer
        Print-Message "info" "Running NVM installer..."
        $result = Execute-Command $NVM_SETUP
        
        # Check if installation was successful
        if (Test-Path $NVM_DIR) {
            Print-Message "success" "NVM installed successfully"
            
            # Refresh environment variables
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            
            return $true
        } else {
            Print-Message "error" "NVM directory not found after installation"
            return $false
        }
    }
}

# Install Node.js LTS version
function Install-NodeLts {
    Print-Message "info" "Installing Node.js LTS version..."
    
    if ($DRY_RUN) {
        Print-Message "dryrun" "nvm install lts"
        Print-Message "dryrun" "nvm use lts"
        return $true
    } else {
        # Ensure NVM is in PATH
        if (-not (Get-Command nvm -ErrorAction SilentlyContinue)) {
            Print-Message "warning" "NVM command not found in PATH"
            
            # Try to use NVM from its install location
            if (Test-Path "$NVM_DIR\nvm.exe") {
                $env:Path += ";$NVM_DIR"
            } else {
                Print-Message "error" "Cannot find NVM executable"
                return $false
            }
        }
        
        # Install LTS version
        Execute-Command "nvm install lts"
        
        # Use the LTS version
        Execute-Command "nvm use lts"
        
        # Verify installation
        try {
            $nodeVersion = & node --version
            $npmVersion = & npm --version
            
            Print-Message "success" "Node.js $nodeVersion installed successfully"
            Print-Message "success" "npm $npmVersion installed successfully"
            return $true
        } catch {
            Print-Message "error" "Node.js installation verification failed"
            return $false
        }
    }
}

# Configure npm global settings
function Configure-Npm {
    Print-Message "info" "Configuring npm global settings..."
    
    if ($DRY_RUN) {
        Print-Message "dryrun" "Would configure npm global settings"
        return $true
    } else {
        # Ensure npm is available
        if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
            Print-Message "warning" "npm not found, cannot configure"
            return $false
        }
        
        # Create global npm directory in user's profile
        $npmGlobalDir = "$env:USERPROFILE\.npm-global"
        if (-not (Test-Path $npmGlobalDir)) {
            New-Item -Path $npmGlobalDir -ItemType Directory -Force | Out-Null
        }
        
        # Configure npm to use this directory
        Execute-Command "npm config set prefix '$npmGlobalDir'"
        
        # Add to PATH if needed
        $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
        if (-not $userPath.Contains($npmGlobalDir)) {
            $newPath = "$npmGlobalDir;" + $userPath
            [System.Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + $newPath
            
            Print-Message "info" "Added npm global bin directory to PATH"
        }
        
        Print-Message "success" "npm global configuration complete"
        Print-Message "info" "Global packages will be installed in $npmGlobalDir"
        return $true
    }
}

# Main function for NVM and Node.js setup
function Setup-Node {
    Print-Message "info" "Phase 3: Setting up NVM and Node.js"
    
    # Install NVM if needed
    if (-not (Is-NvmInstalled)) {
        if ($DRY_RUN) {
            Print-Message "dryrun" "Would install NVM"
        } else {
            if (-not (Install-Nvm)) {
                Print-Message "error" "NVM installation failed. Cannot proceed with Node.js setup."
                return $false
            }
        }
    }
    
    # Install Node.js LTS version if needed
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        if ($DRY_RUN) {
            Print-Message "dryrun" "Would install Node.js LTS version"
        } else {
            if (-not (Install-NodeLts)) {
                Print-Message "error" "Node.js installation failed"
                return $false
            }
        }
    }
    
    # Configure npm global settings
    if ($DRY_RUN) {
        Print-Message "dryrun" "Would configure npm global settings"
    } else {
        if (-not (Configure-Npm)) {
            Print-Message "warning" "npm global configuration failed, but continuing"
        }
    }
    
    Print-Message "success" "Phase 3: NVM and Node.js setup completed"
    return $true
}

###########################################
# Phase 4: Install & Configure VSCode + Extensions
###########################################

# Define VSCode paths and extensions
$VSCODE_INSTALL_PATH = "${env:ProgramFiles}\Microsoft VS Code"
$VSCODE_PACKAGE_NAME = "vscode"

# Arrays for required extensions
$AI_EXTENSIONS = @("kodu-ai.claude-dev-experimental", "saoudrizwan.claude-dev", "rooveterinaryinc.roo-cline", "GitHub.copilot", "GitHub.copilot-chat")
$OTHER_EXTENSIONS = @("EditorConfig.EditorConfig", "PKief.material-icon-theme", "PaulOlteanu.theme-railscasts")
# Combine all extensions into one array
$ALL_EXTENSIONS = $AI_EXTENSIONS + $OTHER_EXTENSIONS

# Check if VSCode is already installed
function Is-VsCodeInstalled {
    # Method 1: Check through Chocolatey
    if (Is-PackageInstalled $VSCODE_PACKAGE_NAME) {
        Print-Message "success" "VSCode is already installed via Chocolatey"
        return $true
    }
    
    # Method 2: Check for installation in Program Files
    if (Test-Path "$VSCODE_INSTALL_PATH\Code.exe") {
        Print-Message "success" "VSCode is already installed at $VSCODE_INSTALL_PATH"
        return $true
    }
    
    # Method 3: Check for 'code' command in PATH
    if (Get-Command code -ErrorAction SilentlyContinue) {
        Print-Message "success" "VSCode is already installed (command 'code' is available)"
        return $true
    }
    
    Print-Message "info" "VSCode is not installed"
    return $false
}

# Install VSCode using Chocolatey
function Install-VsCode {
    if (Is-VsCodeInstalled) {
        if ($FORCE_UPGRADE) {
            Print-Message "info" "VSCode is already installed, but force upgrade is enabled"
            Upgrade-ChocolateyPackage $VSCODE_PACKAGE_NAME
        }
        return $true
    }
    
    Print-Message "info" "Installing Visual Studio Code..."
    
    if ($DRY_RUN) {
        Print-Message "dryrun" "choco install $VSCODE_PACKAGE_NAME -y"
        return $true
    } else {
        $result = Install-ChocolateyPackage $VSCODE_PACKAGE_NAME
        
        if (-not $result) {
            Print-Message "error" "Failed to install VSCode"
            return $false
        } else {
            # Check if 'code' command is available after installation
            if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
                Print-Message "warning" "VSCode installed but 'code' command is not available in PATH"
                Print-Message "warning" "You may need to restart your PowerShell session for the PATH changes to take effect"
                
                # Update PATH for current session
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            } else {
                Print-Message "success" "VSCode and 'code' command installed successfully"
            }
            
            return $true
        }
    }
}

# Get the VSCode binary path
function Get-VsCodeBinary {
    # Check for command in PATH
    if (Get-Command code -ErrorAction SilentlyContinue) {
        return (Get-Command code).Source
    }
    
    # Check for VSCode in Program Files
    if (Test-Path "$VSCODE_INSTALL_PATH\Code.exe") {
        return "$VSCODE_INSTALL_PATH\Code.exe"
    }
    
    Print-Message "warning" "VSCode 'code' binary not found in expected locations"
    return $null
}

# Check if a VSCode extension is installed
function Is-ExtensionInstalled {
    param (
        [string]$extensionId
    )
    
    $codePath = Get-VsCodeBinary
    
    if (-not $codePath) {
        Print-Message "warning" "Cannot check for installed extensions: VSCode binary not found"
        return $false
    }
    
    try {
        $extensions = & $codePath --list-extensions
        if ($extensions -contains $extensionId) {
            if ($DRY_RUN) {
                Print-Message "info" "Extension $extensionId is already installed"
            } else {
                Print-Message "success" "Extension $extensionId is already installed"
            }
            return $true
        }
    } catch {
        Print-Message "warning" "Error checking installed extensions: $_"
    }
    
    return $false
}

# Install a VSCode extension
function Install-VsCodeExtension {
    param (
        [string]$extensionId,
        [bool]$forceUpgrade = $false
    )
    
    $codePath = Get-VsCodeBinary
    
    if (-not $codePath) {
        Print-Message "error" "Cannot install extension: VSCode binary not found"
        return $false
    }
    
    # Check if already installed (unless force upgrade is enabled)
    if (-not $forceUpgrade -and (Is-ExtensionInstalled $extensionId)) {
        return $true
    }
    
    Print-Message "info" "Installing VSCode extension: $extensionId"
    
    # When force upgrade is enabled and the extension is already installed, we need to uninstall it first
    if ($forceUpgrade -and (Is-ExtensionInstalled $extensionId)) {
        Print-Message "info" "Force upgrade enabled, reinstalling extension $extensionId"
        if ($DRY_RUN) {
            Print-Message "dryrun" "& $codePath --uninstall-extension $extensionId"
        } else {
            & $codePath --uninstall-extension $extensionId
        }
    }
    
    # Install the extension
    if ($DRY_RUN) {
        Print-Message "dryrun" "& $codePath --install-extension $extensionId"
        return $true
    } else {
        try {
            & $codePath --install-extension $extensionId
            
            if ($LASTEXITCODE -ne 0) {
                Print-Message "error" "Failed to install extension $extensionId"
                return $false
            } else {
                Print-Message "success" "Successfully installed extension $extensionId"
                return $true
            }
        } catch {
            Print-Message "error" "Error installing extension $extensionId: $_"
            return $false
        }
    }
}

# Check if VSCode is running and close it if needed
function Ensure-VsCodeClosed {
    Print-Message "info" "Checking if VSCode is running..."
    
    $vsCodeProcesses = Get-Process -Name "Code" -ErrorAction SilentlyContinue
    
    if ($vsCodeProcesses) {
        Print-Message "warning" "VSCode is currently running. It must be closed to apply settings correctly."
        
        if ($DRY_RUN) {
            Print-Message "dryrun" "Would close VSCode processes"
            return $true
        } else {
            Print-Message "info" "Closing VSCode..."
            
            try {
                $vsCodeProcesses | ForEach-Object { $_.CloseMainWindow() | Out-Null }
                
                # Wait a bit to see if it closed gracefully
                Start-Sleep -Seconds 2
                
                # If still running, force kill
                $remainingProcesses = Get-Process -Name "Code" -ErrorAction SilentlyContinue
                if ($remainingProcesses) {
                    $remainingProcesses | Stop-Process -Force
                    Start-Sleep -Seconds 2
                }
                
                # Check if it's really closed now
                $finalCheck = Get-Process -Name "Code" -ErrorAction SilentlyContinue
                if ($finalCheck) {
                    Print-Message "warning" "Could not close VSCode completely. Settings may not apply correctly."
                    return $false
                } else {
                    Print-Message "success" "VSCode closed successfully"
                    return $true
                }
            } catch {
                Print-Message "warning" "Error closing VSCode: $_"
                return $false
            }
        }
    } else {
        Print-Message "info" "VSCode is not running. Proceeding with configuration."
        return $true
    }
}

# Get VSCode settings file path
function Get-VsCodeSettingsPath {
    $settingsDir = "$env:APPDATA\Code\User"
    
    if (-not (Test-Path $settingsDir)) {
        # Try the newer location for Windows
        $settingsDir = "$env:USERPROFILE\AppData\Roaming\Code\User"
        
        if (-not (Test-Path $settingsDir)) {
            Print-Message "warning" "Could not find VSCode settings directory"
            return $null
        }
    }
    
    return "$settingsDir\settings.json"
}

# Configure VSCode settings
function Configure-VsCodeThemes {
    Print-Message "info" "Configuring VSCode settings..."
    
    # Get the settings file path
    $settingsFile = Get-VsCodeSettingsPath
    if (-not $settingsFile) {
        Print-Message "error" "Could not determine VSCode settings file location"
        return $false
    }
    
    # Check if settings file exists, create if it doesn't
    if (-not (Test-Path $settingsFile) -and -not $DRY_RUN) {
        Print-Message "info" "VSCode settings file not found, creating it..."
        New-Item -Path (Split-Path $settingsFile) -ItemType Directory -Force | Out-Null
        "{}" | Out-File -FilePath $settingsFile -Encoding utf8
        
        if (-not (Test-Path $settingsFile)) {
            Print-Message "error" "Failed to create VSCode settings file"
            return $false
        }
    }
    
    if ($DRY_RUN) {
        Print-Message "dryrun" "Would update VSCode settings by merging with existing configuration"
        return $true
    } else {
        # Read current settings
        $currentSettings = "{}"
        if (Test-Path $settingsFile) {
            $currentSettings = Get-Content -Path $settingsFile -Raw
            if (-not $currentSettings) {
                $currentSettings = "{}"
            }
        }
        
        # Convert current settings to PSObject
        try {
            $settings = $currentSettings | ConvertFrom-Json
        } catch {
            Print-Message "warning" "Error parsing current settings, creating new settings file"
            $settings = "{}" | ConvertFrom-Json
        }
        
        # Define the settings we want to ensure are set
        $settingsToApply = @{
            "workbench.iconTheme" = "material-icon-theme"
            "workbench.colorTheme" = "Railscasts Renewed"
            "editor.formatOnSave" = $true
            "editor.tabSize" = 2
            "editor.wordWrap" = "on"
            "files.autoSave" = "afterDelay"
            "files.autoSaveDelay" = 1000
            "github.copilot.enable" = @{
                "*" = $true
                "plaintext" = $true
                "markdown" = $true
                "yaml" = $true
            }
            "github.copilot.advanced" = @{
                "indentation.enable" = $true
            }
            "workbench.panel.defaultLocation" = "right"
            "workbench.panel.opensMaximized" = "always"
            "workbench.secondarySideBar.showLabels" = $false
            "workbench.view.extension.kodu-claude-coder-main-ActivityBar.state.hidden" = @(@{ "id" = "kodu-claude-coder-main.SidebarProvider"; "isHidden" = $false })
            "workbench.view.extension.roo-cline-ActivityBar.state.hidden" = @(@{ "id" = "roo-cline.SidebarProvider"; "isHidden" = $false })
            "workbench.view.extension.claude-dev-ActivityBar.state.hidden" = @(@{ "id" = "claude-dev.SidebarProvider"; "isHidden" = $false })
            "workbench.activityBar.hidden" = $false
            "workbench.activityBar.location" = "default"
        }
        
        # Merge settings
        foreach ($key in $settingsToApply.Keys) {
            $settings | Add-Member -MemberType NoteProperty -Name $key -Value $settingsToApply[$key] -Force
        }
        
        # Write updated settings back to file
        $settings | ConvertTo-Json -Depth 10 | Out-File -FilePath $settingsFile -Encoding utf8
        
        Print-Message "success" "VSCode settings configured successfully"
        return $true
    }
}

# Main function for VSCode setup
function Setup-VsCode {
    Print-Message "info" "Phase 4: Setting up VSCode and extensions"
    
    # Make sure VSCode is closed before we start
    Ensure-VsCodeClosed
    
    # Install VSCode if needed
    if (-not (Is-VsCodeInstalled)) {
        if ($DRY_RUN) {
            Print-Message "dryrun" "Would install VSCode"
        } else {
            if (-not (Install-VsCode)) {
                Print-Message "error" "VSCode installation failed. Cannot proceed with extension installation."
                return $false
            }
        }
    }
    
    # Install required extensions
    Print-Message "info" "Installing required VSCode extensions..."
    
    # Install AI extensions
    Print-Message "info" "Installing AI extensions..."
    foreach ($extension in $AI_EXTENSIONS) {
        Install-VsCodeExtension $extension $FORCE_UPGRADE
    }
    
    # Install other extensions
    Print-Message "info" "Installing additional extensions..."
    foreach ($extension in $OTHER_EXTENSIONS) {
        Install-VsCodeExtension $extension $FORCE_UPGRADE
    }
    
    # Configure themes
    if (-not (Configure-VsCodeThemes)) {
        Print-Message "warning" "Failed to configure VSCode themes, but continuing with setup"
    }
    
    Print-Message "success" "Phase 4: VSCode and extensions setup completed"
    return $true
}

###########################################
# Phase 5: Configure AI Extensions
###########################################

# Define extension IDs and configuration paths
$KODU_EXTENSION_ID = "kodu-ai.claude-dev-experimental"
$CLINE_EXTENSION_ID = "saoudrizwan.claude-dev"
$ROOCODE_EXTENSION_ID = "rooveterinaryinc.roo-cline"
$COPILOT_EXTENSION_ID = "GitHub.copilot"
$COPILOT_CHAT_EXTENSION_ID = "GitHub.copilot-chat"

# Get base path for VSCode extensions configuration
function Get-VsCodeExtensionsPath {
    $basePath = "$env:APPDATA\Code"
    
    if (-not (Test-Path $basePath)) {
        # Try the newer location for Windows
        $basePath = "$env:USERPROFILE\AppData\Roaming\Code"
        
        if (-not (Test-Path $basePath)) {
            Print-Message "error" "Could not determine VSCode extensions base path"
            return $null
        }
    }
    
    return $basePath
}

# Get extension configuration path
function Get-ExtensionConfigPath {
    param (
        [string]$extensionId,
        [string]$configType = "settings"
    )
    
    $vscodePath = Get-VsCodeExtensionsPath
    if (-not $vscodePath) {
        return $null
    }
    
    $configPath = $null
    
    # Different extensions store their settings in different places
    switch ($extensionId) {
        $KODU_EXTENSION_ID {
            $configPath = "$vscodePath\User\globalStorage\$extensionId"
        }
        $CLINE_EXTENSION_ID {
            $configPath = "$vscodePath\User\globalStorage\$extensionId\settings"
        }
        $ROOCODE_EXTENSION_ID {
            $configPath = "$vscodePath\User\globalStorage\$extensionId\settings"
        }
        { $_ -eq $COPILOT_EXTENSION_ID -or $_ -eq $COPILOT_CHAT_EXTENSION_ID } {
            $configPath = "$vscodePath\User\$configType.json"
        }
        default {
            Print-Message "error" "Unknown extension ID: $extensionId"
            return $null
        }
    }
    
    return $configPath
}

# Backup extension configuration before modification
function Backup-ExtensionConfig {
    param (
        [string]$configPath
    )
    
    if (-not (Test-Path $configPath)) {
        Print-Message "info" "No configuration to backup at $configPath"
        return $true
    }
    
    $backupPath = "$configPath.bak-$(Get-Date -Format 'yyyyMMddHHmmss')"
    
    Print-Message "info" "Backing up $configPath to $backupPath"
    
    if ($DRY_RUN) {
        Print-Message "dryrun" "Would backup $configPath to $backupPath"
        return $true
    } else {
        try {
            if (Test-Path $configPath -PathType Container) {
                # It's a directory, so use Copy-Item with -Recurse
                Copy-Item -Path $configPath -Destination $backupPath -Recurse -Force
            } else {
                # It's a file, so use simple Copy-Item
                Copy-Item -Path $configPath -Destination $backupPath -Force
            }
            
            Print-Message "success" "Configuration backup created at $backupPath"
            return $true
        } catch {
            Print-Message "warning" "Failed to backup configuration at $configPath: $_"
            return $false
        }
    }
}

# Create directory if it doesn't exist
function Ensure-DirectoryExists {
    param (
        [string]$dirPath
    )
    
    if (-not (Test-Path $dirPath -PathType Container)) {
        Print-Message "info" "Creating directory: $dirPath"
        
        if ($DRY_RUN) {
            Print-Message "dryrun" "New-Item -Path $dirPath -ItemType Directory -Force"
            return $true
        } else {
            try {
                New-Item -Path $dirPath -ItemType Directory -Force | Out-Null
                Print-Message "success" "Directory created at $dirPath"
                return $true
            } catch {
                Print-Message "error" "Failed to create directory at $dirPath: $_"
                return $false
            }
        }
    }
    
    return $true
}

# Get current Kodu settings to use as a template
function Get-CurrentKoduSettings {
    Print-Message "info" "Reading current Kodu settings..."
    
    # Get Kodu config path for the current machine
    $koduPath = "$env:APPDATA\Code\User\globalStorage\$KODU_EXTENSION_ID"
    $settingsFile = "$koduPath\settings.json"
    
    if (-not (Test-Path $settingsFile)) {
        Print-Message "warning" "Current Kodu settings not found at $settingsFile"
        # Return default template if current settings not found
        return @{
            "defaultModelId" = "claude-3-haiku-20240307"
            "defaultMode" = "direct"
            "enableThinking" = $true
            "tokenBudget" = 4000
        } | ConvertTo-Json
    }
    
    try {
        $currentSettings = Get-Content $settingsFile -Raw | ConvertFrom-Json
        
        # Remove API key for security
        if ($currentSettings.PSObject.Properties.Name -contains "apiKey") {
            $currentSettings.PSObject.Properties.Remove("apiKey")
        }
        
        return $currentSettings | ConvertTo-Json
    } catch {
        Print-Message "warning" "Error reading current Kodu settings: $_"
        # Return default template if error occurs
        return @{
            "defaultModelId" = "claude-3-haiku-20240307"
            "defaultMode" = "direct"
            "enableThinking" = $true
            "tokenBudget" = 4000
        } | ConvertTo-Json
    }
}

# Configure Kodu AI extension
function Configure-Kodu {
    Print-Message "info" "Configuring Kodu AI extension..."
    
    # Load API keys
    if (-not (Test-Path $API_KEYS_FILE)) {
        Print-Message "error" "API keys file not found at $API_KEYS_FILE"
        return $false
    }
    
    # Get Kodu config path for target installation
    $koduPath = Get-ExtensionConfigPath $KODU_EXTENSION_ID
    if (-not $koduPath) {
        Print-Message "error" "Failed to determine Kodu configuration path"
        return $false
    }
    
    # Ensure config directory exists
    Ensure-DirectoryExists $koduPath
    
    # Define Kodu settings file
    $settingsFile = "$koduPath\settings.json"
    
    # Backup existing settings if any
    if (Test-Path $settingsFile) {
        Backup-ExtensionConfig $settingsFile
    }
    
    if ($DRY_RUN) {
        Print-Message "dryrun" "Would get current Kodu settings and merge with API key"
        Print-Message "dryrun" "Would configure Kodu AI with API key from $API_KEYS_FILE"
        return $true
    } else {
        try {
            # Extract Kodu API key
            $apiKeys = Get-Content $API_KEYS_FILE -Raw | ConvertFrom-Json
            $koduKey = $apiKeys.kodu
            
            if (-not $koduKey) {
                Print-Message "error" "Failed to extract Kodu API key from $API_KEYS_FILE"
                return $false
            }
            
            # Get current settings template
            $currentSettingsJson = Get-CurrentKoduSettings
            $currentSettings = $currentSettingsJson | ConvertFrom-Json
            
            # Create new settings with current template and new API key
            $currentSettings | Add-Member -MemberType NoteProperty -Name "apiKey" -Value $koduKey -Force
            
            # Write settings to file
            $currentSettings | ConvertTo-Json -Depth 10 | Out-File -FilePath $settingsFile -Encoding utf8
            
            # Set restrictive permissions on the settings file (contains API key)
            $acl = Get-Acl $settingsFile
            $acl.SetAccessRuleProtection($true, $false)
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, "FullControl", "Allow")
            $acl.AddAccessRule($rule)
            Set-Acl $settingsFile $acl
            
            Print-Message "success" "Kodu AI extension configured successfully with current settings"
            return $true
        } catch {
            Print-Message "error" "Error configuring Kodu AI extension: $_"
            return $false
        }
    }
}

# Get current Cline API settings to use as a template
function Get-CurrentClineApiSettings {
    Print-Message "info" "Reading current Cline API settings..."
    
    # Get Cline config path for the current machine
    $clinePath = "$env:APPDATA\Code\User\globalStorage\$CLINE_EXTENSION_ID\settings"
    $apiSettingsFile = "$clinePath\api_settings.json"
    
    if (-not (Test-Path $apiSettingsFile)) {
        Print-Message "warning" "Current Cline API settings not found at $apiSettingsFile"
        # Return default template if current settings not found
        return @{
            "org" = ""
        } | ConvertTo-Json
    }
    
    try {
        $currentSettings = Get-Content $apiSettingsFile -Raw | ConvertFrom-Json
        
        # Remove API key for security
        if ($currentSettings.PSObject.Properties.Name -contains "key") {
            $currentSettings.PSObject.Properties.Remove("key")
        }
        
        return $currentSettings | ConvertTo-Json
    } catch {
        Print-Message "warning" "Error reading current Cline API settings: $_"
        # Return default template if error occurs
        return @{
            "org" = ""
        } | ConvertTo-Json
    }
}

# Get current Cline model settings to use as a template
function Get-CurrentClineModelSettings {
    Print-Message "info" "Reading current Cline model settings..."
    
    # Get Cline config path for the current machine
    $clinePath = "$env:APPDATA\Code\User\globalStorage\$CLINE_EXTENSION_ID\settings"
    $modelSettingsFile = "$clinePath\model_settings.json"
    
    if (-not (Test-Path $modelSettingsFile)) {
        Print-Message "warning" "Current Cline model settings not found at $modelSettingsFile"
        # Return default template if current settings not found
        return @{
            "model" = "claude-3-sonnet-20240229"
            "temperature" = 0.7
            "maxTokens" = 4000
            "systemPrompt" = "You are Claude, a helpful AI assistant."
        } | ConvertTo-Json
    }
    
    try {
        $currentSettings = Get-Content $modelSettingsFile -Raw | ConvertFrom-Json
        return $currentSettings | ConvertTo-Json
    } catch {
        Print-Message "warning" "Error reading current Cline model settings: $_"
        # Return default template if error occurs
        return @{
            "model" = "claude-3-sonnet-20240229"
            "temperature" = 0.7
            "maxTokens" = 4000
            "systemPrompt" = "You are Claude, a helpful AI assistant."
        } | ConvertTo-Json
    }
}

# Configure Cline extension
function Configure-Cline {
    Print-Message "info" "Configuring Cline extension..."
    
    # Load API keys
    if (-not (Test-Path $API_KEYS_FILE)) {
        Print-Message "error" "API keys file not found at $API_KEYS_FILE"
        return $false
    }
    
    # Get Cline config path for target installation
    $clinePath = Get-ExtensionConfigPath $CLINE_EXTENSION_ID
    if (-not $clinePath) {
        Print-Message "error" "Failed to determine Cline configuration path"
        return $false
    }
    
    # Ensure config directory exists
    Ensure-DirectoryExists $clinePath
    
    # Define Cline settings files
    $apiSettingsFile = "$clinePath\api_settings.json"
    $modelSettingsFile = "$clinePath\model_settings.json"
    
    # Backup existing settings if any
    if (Test-Path $apiSettingsFile) {
        Backup-ExtensionConfig $apiSettingsFile
    }
    if (Test-Path $modelSettingsFile) {
        Backup-ExtensionConfig $modelSettingsFile
    }
    
    if ($DRY_RUN) {
        Print-Message "dryrun" "Would get current Cline settings and merge with API key"
        Print-Message "dryrun" "Would configure Cline with API key from $API_KEYS_FILE"
        return $true
    } else {
        try {
            # Extract Cline API key
            $apiKeys = Get-Content $API_KEYS_FILE -Raw | ConvertFrom-Json
            $clineKey = $apiKeys.cline
            
            if (-not $clineKey) {
                Print-Message "error" "Failed to extract Cline API key from $API_KEYS_FILE"
                return $false
            }
            
            # Get current API settings template
            $currentApiSettingsJson = Get-CurrentClineApiSettings
            $currentApiSettings = $currentApiSettingsJson | ConvertFrom-Json
            
            # Create new API settings with current template and new API key
            $currentApiSettings | Add-Member -MemberType NoteProperty -Name "key" -Value $clineKey -Force
            
            # Get current model settings
            $modelSettingsJson = Get-CurrentClineModelSettings
            $modelSettings = $modelSettingsJson | ConvertFrom-Json
            
            # Write settings to files
            $currentApiSettings | ConvertTo-Json -Depth 10 | Out-File -FilePath $apiSettingsFile -Encoding utf8
            $modelSettings | ConvertTo-Json -Depth 10 | Out-File -FilePath $modelSettingsFile -Encoding utf8
            
            # Set restrictive permissions on the API settings file (contains API key)
            $acl = Get-Acl $apiSettingsFile
            $acl.SetAccessRuleProtection($true, $false)
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, "FullControl", "Allow")
            $acl.AddAccessRule($rule)
            Set-Acl $apiSettingsFile $acl
            
            Print-Message "success" "Cline extension configured successfully with current settings"
            return $true
        } catch {
            Print-Message "error" "Error configuring Cline extension: $_"
            return $false
        }
    }
}

# Get current Roocode settings to use as a template
function Get-CurrentRoocodeSettings {
    Print-Message "info" "Reading current Roocode settings..."
    
    # Get Roocode config path for the current machine
    $roocodePath = "$env:APPDATA\Code\User\globalStorage\$ROOCODE_EXTENSION_ID\settings"
    $settingsFile = "$roocodePath\roocode_settings.json"
    
    if (-not (Test-Path $settingsFile)) {
        Print-Message "warning" "Current Roocode settings not found at $settingsFile"
        # Return default template if current settings not found
        return @{
            "defaultModel" = "claude-3-opus-20240229"
            "defaultThinking" = $true
            "tokenBudget" = 4000
        } | ConvertTo-Json
    }
    
    try {
        $currentSettings = Get-Content $settingsFile -Raw | ConvertFrom-Json
        
        # Remove API key for security
        if ($currentSettings.PSObject.Properties.Name -contains "apiKey") {
            $currentSettings.PSObject.Properties.Remove("apiKey")
        }
        
        return $currentSettings | ConvertTo-Json
    } catch {
        Print-Message "warning" "Error reading current Roocode settings: $_"
        # Return default template if error occurs
        return @{
            "defaultModel" = "claude-3-opus-20240229"
            "defaultThinking" = $true
            "tokenBudget" = 4000
        } | ConvertTo-Json
    }
}

# Configure Roocode extension
function Configure-Roocode {
    Print-Message "info" "Configuring Roocode extension..."
    
    # Load API keys
    if (-not (Test-Path $API_KEYS_FILE)) {
        Print-Message "error" "API keys file not found at $API_KEYS_FILE"
        return $false
    }
    
    # Get Roocode config path for target installation
    $roocodePath = Get-ExtensionConfigPath $ROOCODE_EXTENSION_ID
    if (-not $roocodePath) {
        Print-Message "error" "Failed to determine Roocode configuration path"
        return $false
    }
    
    # Ensure config directory exists
    Ensure-DirectoryExists $roocodePath
    
    # Define Roocode settings file
    $settingsFile = "$roocodePath\roocode_settings.json"
    
    # Backup existing settings if any
    if (Test-Path $settingsFile) {
        Backup-ExtensionConfig $settingsFile
    }
    
    if ($DRY_RUN) {
        Print-Message "dryrun" "Would get current Roocode settings and merge with API key"
        Print-Message "dryrun" "Would configure Roocode with API key from $API_KEYS_FILE"
        return $true
    } else {
        try {
            # Extract Roocode API key
            $apiKeys = Get-Content $API_KEYS_FILE -Raw | ConvertFrom-Json
            $roocodeKey = $apiKeys.roocode
            
            if (-not $roocodeKey) {
                Print-Message "error" "Failed to extract Roocode API key from $API_KEYS_FILE"
                return $false
            }
            
            # Get current settings template
            $currentSettingsJson = Get-CurrentRoocodeSettings
            $currentSettings = $currentSettingsJson | ConvertFrom-Json
            
            # Create new settings with current template and new API key
            $currentSettings | Add-Member -MemberType NoteProperty -Name "apiKey" -Value $roocodeKey -Force
            
            # Write settings to file
            $currentSettings | ConvertTo-Json -Depth 10 | Out-File -FilePath $settingsFile -Encoding utf8
            
            # Set restrictive permissions on the settings file (contains API key)
            $acl = Get-Acl $settingsFile
            $acl.SetAccessRuleProtection($true, $false)
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, "FullControl", "Allow")
            $acl.AddAccessRule($rule)
            Set-Acl $settingsFile $acl
            
            Print-Message "success" "Roocode extension configured successfully with current settings"
            return $true
        } catch {
            Print-Message "error" "Error configuring Roocode extension: $_"
            return $false
        }
    }
}

# Configure GitHub Copilot extensions
function Configure-Copilot {
    Print-Message "info" "Configuring GitHub Copilot extensions..."
    
    # Get VSCode settings path
    $settingsFile = Get-VsCodeSettingsPath
    if (-not $settingsFile) {
        Print-Message "error" "Failed to determine VSCode settings path"
        return $false
    }
    
    # Backup existing settings
    if (Test-Path $settingsFile) {
        Backup-ExtensionConfig $settingsFile
    }
    
    if ($DRY_RUN) {
        Print-Message "dryrun" "Would configure GitHub Copilot settings in $settingsFile"
        return $true
    } else {
        try {
            # Check if settings file exists
            if (-not (Test-Path $settingsFile)) {
                # Create a new settings file with empty JSON
                "{}" | Out-File -FilePath $settingsFile -Encoding utf8
            }
            
            # Read current settings
            $currentSettingsJson = Get-Content -Path $settingsFile -Raw
            if (-not $currentSettingsJson -or $currentSettingsJson -eq "") {
                $currentSettingsJson = "{}"
            }
            
            $currentSettings = $currentSettingsJson | ConvertFrom-Json
            
            # Update Copilot settings
            $copilotEnable = @{ "*" = $true }
            $copilotAdvanced = @{ "internal.debug" = $false }
            
            if (-not $currentSettings.PSObject.Properties.Name -contains "github.copilot.enable") {
                $currentSettings | Add-Member -MemberType NoteProperty -Name "github.copilot.enable" -Value $copilotEnable -Force
            } else {
                $currentSettings."github.copilot.enable" = $copilotEnable
            }
            
            if (-not $currentSettings.PSObject.Properties.Name -contains "github.copilot.editor.enableAutoCompletions") {
                $currentSettings | Add-Member -MemberType NoteProperty -Name "github.copilot.editor.enableAutoCompletions" -Value $true -Force
            } else {
                $currentSettings."github.copilot.editor.enableAutoCompletions" = $true
            }
            
            if (-not $currentSettings.PSObject.Properties.Name -contains "github.copilot.chat.enabled") {
                $currentSettings | Add-Member -MemberType NoteProperty -Name "github.copilot.chat.enabled" -Value $true -Force
            } else {
                $currentSettings."github.copilot.chat.enabled" = $true
            }
            
            if (-not $currentSettings.PSObject.Properties.Name -contains "github.copilot.advanced") {
                $currentSettings | Add-Member -MemberType NoteProperty -Name "github.copilot.advanced" -Value $copilotAdvanced -Force
            } else {
                $currentSettings."github.copilot.advanced" = $copilotAdvanced
            }
            
            # Write updated settings back to file
            $currentSettings | ConvertTo-Json -Depth 10 | Out-File -FilePath $settingsFile -Encoding utf8
            
            Print-Message "success" "GitHub Copilot extensions configured successfully"
            return $true
        } catch {
            Print-Message "error" "Error configuring GitHub Copilot extensions: $_"
            return $false
        }
    }
}

# Setup MCP file sharing
function Setup-McpFileSharing {
    Print-Message "info" "Phase 6: Setting up MCP file sharing"
    
    # Define source and target paths
    $clineBasePath = Get-ExtensionConfigPath $CLINE_EXTENSION_ID
    $roocodeBasePath = Get-ExtensionConfigPath $ROOCODE_EXTENSION_ID
    
    if (-not $clineBasePath -or -not $roocodeBasePath) {
        Print-Message "error" "Could not determine extension configuration paths"
        return $false
    }
    
    $clineMcpSettings = "$clineBasePath\cline_mcp_settings.json"
    $roocodeMcpSettings = "$roocodeBasePath\mcp_settings.json"
    
    # Create parent directories if they don't exist
    if ($DRY_RUN) {
        Print-Message "dryrun" "Would ensure MCP settings directories exist"
        Print-Message "dryrun" "Would set up file sharing between $clineMcpSettings and $roocodeMcpSettings"
        return $true
    } else {
        # Ensure parent directories exist
        Ensure-DirectoryExists (Split-Path $clineMcpSettings)
        Ensure-DirectoryExists (Split-Path $roocodeMcpSettings)
        
        # Check if source file exists
        if (-not (Test-Path $clineMcpSettings)) {
            Print-Message "info" "Cline MCP settings file does not exist, creating it with default content"
            
            # Create a default MCP settings file with common MCP servers
            $defaultMcpContent = @{
                "version" = 1
                "servers" = @()
            } | ConvertTo-Json
            
            $defaultMcpContent | Out-File -FilePath $clineMcpSettings -Encoding utf8
        } else {
            Print-Message "info" "Using existing Cline MCP settings from $clineMcpSettings"
        }
        
        # For Windows, we can't use symlinks as easily, so copy the file instead
        if (Test-Path $roocodeMcpSettings) {
            Print-Message "info" "Removing existing Roocode MCP settings file"
            Remove-Item -Path $roocodeMcpSettings -Force
        }
        
        # Copy the file
        try {
            Copy-Item -Path $clineMcpSettings -Destination $roocodeMcpSettings -Force
            Print-Message "success" "Copied MCP settings from Cline to Roocode"
            return $true
        } catch {
            Print-Message "error" "Failed to copy MCP settings: $_"
            return $false
        }
    }
    
    Print-Message "success" "Phase 6: MCP file sharing setup completed"
    return $true
}

# Setup AI workspace
function Setup-AiWorkspace {
    Print-Message "info" "Phase 7: Setting up AI workspace directory"
    
    # Define workspace directory
    $aiWorkspaceDir = "$env:USERPROFILE\projects\ai-workspace"
    
    # Create the directory if it doesn't exist
    if (-not (Test-Path $aiWorkspaceDir)) {
        Print-Message "info" "Creating AI workspace directory at $aiWorkspaceDir"
        
        if ($DRY_RUN) {
            Print-Message "dryrun" "Would create directory: $aiWorkspaceDir"
        } else {
            try {
                New-Item -Path $aiWorkspaceDir -ItemType Directory -Force | Out-Null
                Print-Message "success" "Created AI workspace directory at $aiWorkspaceDir"
            } catch {
                Print-Message "error" "Failed to create AI workspace directory: $_"
                return $false
            }
        }
    } else {
        Print-Message "info" "AI workspace directory already exists at $aiWorkspaceDir"
    }
    
    # For Windows, we'll create a copy of the API keys file in the workspace
    $targetFile = "$aiWorkspaceDir\ai-keys.json"
    
    if (Test-Path $targetFile) {
        Print-Message "info" "API keys file already exists in workspace, updating it"
        if ($DRY_RUN) {
            Print-Message "dryrun" "Would update API keys copy in workspace"
        } else {
            try {
                Remove-Item -Path $targetFile -Force
            } catch {
                Print-Message "warning" "Failed to remove existing API keys file in workspace: $_"
            }
        }
    }
    
    if ($DRY_RUN) {
        Print-Message "dryrun" "Would copy API keys from $API_KEYS_FILE to $targetFile"
    } else {
        try {
            Copy-Item -Path $API_KEYS_FILE -Destination $targetFile -Force
            
            # Set restrictive permissions
            $acl = Get-Acl $targetFile
            $acl.SetAccessRuleProtection($true, $false)
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, "FullControl", "Allow")
            $acl.AddAccessRule($rule)
            Set-Acl $targetFile $acl
            
            Print-Message "success" "Copied API keys file to workspace at $targetFile"
        } catch {
            Print-Message "error" "Failed to copy API keys file to workspace: $_"
            return $false
        }
    }
    
    # Open the AI workspace directory and file in VSCode
    if ($DRY_RUN) {
        Print-Message "dryrun" "Would open AI workspace directory and keys file in VSCode: $aiWorkspaceDir"
    } else {
        # Check if VSCode is available
        if (Get-Command code -ErrorAction SilentlyContinue) {
            Print-Message "info" "Opening AI workspace directory in VSCode"
            & code "$aiWorkspaceDir"
            
            Print-Message "info" "Opening AI keys file in VSCode"
            & code "$targetFile"
        } else {
            Print-Message "warning" "VSCode 'code' command not found in PATH"
            Print-Message "info" "Please manually open $aiWorkspaceDir and $targetFile in VSCode"
            
            # Fall back to regular file explorer as backup
            Start-Process "explorer.exe" -ArgumentList "`"$aiWorkspaceDir`""
        }
    }
    
    Print-Message "success" "Phase 7: AI workspace setup completed"
    return $true
}

# Main function to orchestrate the entire setup process
function Start-Setup {
    Print-Message "info" "Starting AI setup for Windows..."
    
    # Phase 1: API Key Handling & Script Initialization
    Setup-ApiKeys
    
    # Phase 2: Package Installation
    if (-not (Setup-RequiredPackages)) {
        Print-Message "error" "Failed to set up required packages. Some features may not work correctly."
    }
    
    # Phase 3: NVM and Node.js setup
    if (-not (Setup-Node)) {
        Print-Message "error" "Failed to set up Node.js. Some features may not work correctly."
    }
    
    # Phase 4: VSCode and extensions setup
    if (-not (Setup-VsCode)) {
        Print-Message "error" "Failed to set up VSCode. AI features may not be available."
    }
    
    # Phase 5: AI extensions configuration
    Print-Message "info" "Phase 5: Configuring AI extensions"
    
    # Make sure VSCode is closed before configuration
    Ensure-VsCodeClosed
    
    Print-Message "info" "Checking and configuring Kodu AI..."
    if (-not (Configure-Kodu)) {
        Print-Message "warning" "Failed to configure Kodu AI, but continuing with setup"
    }
    
    Print-Message "info" "Checking and configuring Cline..."
    if (-not (Configure-Cline)) {
        Print-Message "warning" "Failed to configure Cline, but continuing with setup"
    }
    
    Print-Message "info" "Checking and configuring Roocode..."
    if (-not (Configure-Roocode)) {
        Print-Message "warning" "Failed to configure Roocode, but continuing with setup"
    }
    
    Print-Message "info" "Checking and configuring GitHub Copilot..."
    if (-not (Configure-Copilot)) {
        Print-Message "warning" "Failed to configure GitHub Copilot, but continuing with setup"
    }
    
    Print-Message "success" "Phase 5: AI extensions configuration completed"
    
    # Phase 6: MCP File Sharing Setup (Similar to the symlink in macOS)
    # Commented out as in the original script but left in code for reference
    # if (-not (Setup-McpFileSharing)) {
    #     Print-Message "warning" "Failed to set up MCP file sharing, but continuing with setup"
    # }
    
    # Phase 7: Setup AI workspace directory
    if (-not (Setup-AiWorkspace)) {
        Print-Message "warning" "Failed to set up AI workspace, but continuing with setup"
    }
    
    Print-Message "success" "Setup completed successfully!"
}

# Parse command-line arguments
Parse-Arguments $args

# Execute the setup process
Start-Setup