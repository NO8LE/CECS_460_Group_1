#!/bin/bash

# VS Code AI Setup Script
# This script configures a macOS system for AI research purposes

# Better error handling that tells you exactly which command failed and where
error_handler() {
  local line=$1
  local command=$2
  local exit_code=$3
  print_message "error" "Command '$command' failed with exit code $exit_code at line $line"
  # Print stack trace
  print_message "error" "Stack trace:"
  for i in "${!FUNCNAME[@]}"; do
    if [[ $i -gt 0 ]]; then  # Skip the error_handler function itself
      print_message "error" "  ${BASH_SOURCE[$i]}: ${BASH_LINENO[$i-1]}: ${FUNCNAME[$i]}: $([[ $i -eq 1 ]] && echo "$command" || echo "${BASH_COMMAND}")"
    fi
  done
  
  # Exit with the same code as the failed command
  exit $exit_code
}

# Set up error trapping
trap 'error_handler ${LINENO} "${BASH_COMMAND}" $?' ERR
# We don't use set -e anymore since the trap will handle errors

# Color codes for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
API_KEYS_FILE="$HOME/.ai-keys.json"
DRY_RUN=false
FORCE_UPGRADE=false  # Whether to force upgrade packages that are already installed

# Function to print messages
print_message() {
  local message_type=$1
  local message=$2
  
  case "$message_type" in
    "info") echo -e "${BLUE}[INFO]${NC} $message" ;;
    "success") echo -e "${GREEN}[SUCCESS]${NC} $message" ;;
    "warning") echo -e "${YELLOW}[WARNING]${NC} $message" ;;
    "error") echo -e "${RED}[ERROR]${NC} $message" ;;
    "dryrun") echo -e "${YELLOW}[DRY-RUN]${NC} Would execute: $message" ;;
    *) echo -e "$message" ;;
  esac
}

# Function to execute or simulate commands based on dry run mode
# Always redirects stderr to stdout (2>&1) for better visibility
execute_command() {
  local command="$1"
  
  # Add 2>&1 redirection if not already present
  if ! echo "$command" | grep -q "2>&1"; then
    command="$command 2>&1"
  fi
  
  if [ "$DRY_RUN" = true ]; then
    print_message "dryrun" "$command"
    return 0
  else
    print_message "info" "Executing: $command"
    
    # For long-running or problematic commands, consider using tee to log output
    # Uncomment the next line and comment the one after it if you need logging
    # eval "$command | tee /tmp/ai-setup-$(date +%s).log"
    eval "$command"
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
      print_message "warning" "Command exited with code $exit_code"
    fi
    
    return $exit_code
  fi
}

# Function to display help message
show_help() {
  cat << EOF
VS Code AI Setup Script

Usage: ./setup.sh [OPTIONS]

Options:
  -h, --help          Show this help message and exit
  -n, --dry-run       Run in dry-run mode (print commands without executing)
  -u, --force-upgrade Force upgrade of packages that are already installed

This script will configure a macOS system for AI research purposes.
It installs and configures Homebrew, required packages, VSCode, and AI extensions.

Quick install:
  chmod +x setup.sh
  ./setup.sh

Note: The script will properly prompt for Anthropic API keys during installation.
EOF
}

# Parse command-line arguments
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        show_help
        exit 0
        ;;
      -n|--dry-run)
        DRY_RUN=true
        print_message "warning" "Running in dry-run mode. No changes will be made."
        ;;
      -u|--force-upgrade)
        FORCE_UPGRADE=true
        print_message "warning" "Force upgrade mode enabled. Packages will be upgraded even if already installed."
        ;;
      *)
        print_message "error" "Unknown option: $1"
        show_help
        exit 1
        ;;
    esac
    shift
  done
}

# Check hostname to prevent running on development machines
check_hostname() {
  local hostname=$(hostname)
  if [[ "$hostname" == *"m2pro"* ]]; then
    print_message "error" "This script should not be run on a machine with 'm2pro' in the hostname."
    print_message "error" "Current hostname: $hostname"
    exit 1
  fi
  print_message "info" "Hostname check passed: $hostname"
}

# Simple function to check if a JSON file has required keys without jq dependency
validate_json_keys() {
  local file="$1"
  local required_keys=("cline" "kodu" "roocode")
  local valid=true
  
  # Read the file content
  local content=$(cat "$file")
  
  # Check for each required key
  for key in "${required_keys[@]}"; do
    if ! echo "$content" | grep -q "\"$key\""; then
      valid=false
      break
    fi
  done
  
  echo "$valid"
}

# Function to open the Anthropic console for API keys
open_anthropic_console() {
  if [ "$DRY_RUN" = true ]; then
    print_message "dryrun" "Would open browser to https://console.anthropic.com/settings/keys"
  else
    print_message "info" "Opening browser to Anthropic console for API keys..."
    if command -v open >/dev/null 2>&1; then
      # macOS
      open "https://console.anthropic.com/settings/keys"
    elif command -v xdg-open >/dev/null 2>&1; then
      # Linux with xdg-open
      xdg-open "https://console.anthropic.com/settings/keys"
    else
      print_message "warning" "Could not open browser automatically."
      print_message "info" "Please visit https://console.anthropic.com/settings/keys to create your API keys."
    fi
  fi
}

# Function to handle API keys
setup_api_keys() {
  if [ -f "$API_KEYS_FILE" ]; then
    print_message "info" "API keys file already exists at $API_KEYS_FILE"
    if [ "$DRY_RUN" = true ]; then
      print_message "dryrun" "Would read existing API keys from $API_KEYS_FILE"
    else
      # Validate the existing file has the expected structure
      local valid_json=$(validate_json_keys "$API_KEYS_FILE")
      if [ "$valid_json" = "false" ]; then
        print_message "warning" "Existing API keys file does not have the expected structure."
        print_message "warning" "It should contain 'cline', 'kodu', and 'roocode' keys."
        ask_for_api_keys
      fi
    fi
  else
    print_message "info" "API keys file not found at $API_KEYS_FILE"
    ask_for_api_keys
  fi
}

# Function to prompt for API keys and save them
ask_for_api_keys() {
  if [ "$DRY_RUN" = true ]; then
    print_message "dryrun" "Would open browser to https://console.anthropic.com/settings/keys"
    print_message "dryrun" "Would prompt for Cline, Kodu, and Roocode API keys"
    print_message "dryrun" "Would save API keys to $API_KEYS_FILE"
  else
    # Open browser to the Anthropic console
    open_anthropic_console
    
    print_message "info" "Please enter your API keys from https://console.anthropic.com/settings/keys"
    print_message "info" "When creating the keys, name them $USER-cline, $USER-kodu, $USER-roocode as recommended"
    
    # Use /dev/tty explicitly to ensure interactive input even when piped
    exec < /dev/tty
    
    read -p "Enter your Cline API key: " cline_key
    read -p "Enter your Kodu API key: " kodu_key
    read -p "Enter your Roocode API key: " roocode_key
    
    # Validate that the keys are not empty
    if [ -z "$cline_key" ] || [ -z "$kodu_key" ] || [ -z "$roocode_key" ]; then
      print_message "error" "All API keys are required. Please try again."
      ask_for_api_keys
      return
    fi
    
    # Create JSON structure
    local json_content=$(cat << EOF
{
  "cline": "$cline_key",
  "kodu": "$kodu_key",
  "roocode": "$roocode_key"
}
EOF
)
    
    # Save to file
    echo "$json_content" > "$API_KEYS_FILE"
    chmod 600 "$API_KEYS_FILE"  # Restrict permissions to user only
    print_message "success" "API keys saved to $API_KEYS_FILE"
  fi
}

###########################################
# Phase 2: Install Homebrew & Core Packages
###########################################

# Detect system architecture (Intel vs Apple Silicon)
detect_architecture() {
  local arch=$(uname -m)
  if [ "$arch" = "arm64" ]; then
    print_message "info" "Detected Apple Silicon (M1/M2) architecture"
    ARCH="arm64"
    BREW_PATH="/opt/homebrew/bin/brew"
    BREW_PREFIX="/opt/homebrew"
  else
    print_message "info" "Detected Intel architecture"
    ARCH="x86_64"
    BREW_PATH="/usr/local/bin/brew"
    BREW_PREFIX="/usr/local"
  fi
}

# Check if Homebrew is already installed
check_homebrew() {
  if [ -x "$BREW_PATH" ]; then
    if "$BREW_PATH" --version >/dev/null 2>&1; then
      print_message "success" "Homebrew is already installed at $BREW_PATH"
      return 0
    fi
  fi
  
  # Check for brew in PATH as fallback
  if command -v brew >/dev/null 2>&1; then
    print_message "success" "Homebrew is already installed (found in PATH)"
    BREW_PATH=$(command -v brew)
    return 0
  fi
  
  print_message "info" "Homebrew is not installed"
  return 1
}

# Check if Homebrew is in PATH
check_brew_in_path() {
  if [ "$ARCH" = "arm64" ]; then
    if ! echo "$PATH" | grep -q "/opt/homebrew/bin"; then
      print_message "warning" "Homebrew is not in your PATH. Adding it temporarily for this session."
      export PATH="/opt/homebrew/bin:$PATH"
      
      print_message "info" "To add Homebrew to PATH permanently, add these lines to your shell profile:"
      print_message "info" 'export PATH="/opt/homebrew/bin:$PATH"'
    fi
  fi
}

# Install Homebrew
install_homebrew() {
  print_message "info" "Installing Homebrew..."
  
  # The official Homebrew installation command
  local install_cmd='/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  
  if [ "$DRY_RUN" = true ]; then
    print_message "dryrun" "$install_cmd"
    # Simulate success for dry run
    return 0
  else
    # Execute the installation command
    eval $install_cmd
    
    # Check if installation was successful
    if [ $? -ne 0 ]; then
      print_message "error" "Failed to install Homebrew. Please check the error messages above."
      return 1
    fi
    
    # Check if Homebrew is now installed
    if check_homebrew; then
      print_message "success" "Homebrew has been successfully installed"
      check_brew_in_path
      return 0
    else
      print_message "error" "Homebrew installation appears to have failed."
      return 1
    fi
  fi
}

# Check if a Homebrew package is installed - checks real state even in dry-run mode
is_package_installed() {
  local package_name=$1
  
  # Always check real state regardless of dry run mode
  # This makes dry run output more accurate by showing only what would actually change
  if [ -x "$BREW_PATH" ]; then
    if "$BREW_PATH" list --formula 2>/dev/null | grep -q "^$package_name\$"; then
      if [ "$DRY_RUN" = true ]; then
        print_message "info" "Package $package_name is already installed (verified)"
      fi
      return 0
    fi
  fi
  
  # If we reach here, the package is not installed
  return 1
}

# Check if a Homebrew cask is installed - checks real state even in dry-run mode
is_cask_installed() {
  local cask_name=$1
  
  # Always check real state regardless of dry run mode
  if [ -x "$BREW_PATH" ]; then
    if "$BREW_PATH" list --cask 2>/dev/null | grep -q "^$cask_name\$"; then
      if [ "$DRY_RUN" = true ]; then
        print_message "info" "Cask $cask_name is already installed (verified)"
      fi
      return 0
    fi
  fi
  
  # Fallback application detection for common casks
  if [ "$cask_name" = "google-chrome" ] && [ -d "/Applications/Google Chrome.app" ]; then
    if [ "$DRY_RUN" = true ]; then
      print_message "info" "Google Chrome is already installed (application detected)"
    fi
    return 0
  fi
  
  # If we reach here, the cask is not installed
  return 1
}

# Check if Google Chrome is installed - simplified since is_cask_installed now checks application directories
is_chrome_installed() {
  # We can now just use is_cask_installed since it checks application directories
  if is_cask_installed "google-chrome"; then
    print_message "success" "Google Chrome is already installed"
    return 0
  fi
  
  print_message "info" "Google Chrome is not installed"
  return 1
}

# Upgrade a Homebrew formula
upgrade_brew_package() {
  local package_name=$1
  
  print_message "info" "Upgrading package: $package_name"
  local upgrade_cmd="$BREW_PATH upgrade $package_name"
  
  if [ "$DRY_RUN" = true ]; then
    print_message "dryrun" "$upgrade_cmd"
    return 0
  else
    execute_command "$upgrade_cmd"
    if [ $? -ne 0 ]; then
      print_message "warning" "Failed to upgrade $package_name, but continuing"
      return 1
    else
      print_message "success" "Successfully upgraded $package_name"
      return 0
    fi
  fi
}

# Upgrade a Homebrew cask
upgrade_brew_cask() {
  local cask_name=$1
  
  print_message "info" "Upgrading cask: $cask_name"
  local upgrade_cmd="$BREW_PATH upgrade --cask $cask_name"
  
  if [ "$DRY_RUN" = true ]; then
    print_message "dryrun" "$upgrade_cmd"
    return 0
  else
    execute_command "$upgrade_cmd"
    if [ $? -ne 0 ]; then
      print_message "warning" "Failed to upgrade $cask_name, but continuing"
      return 1
    else
      print_message "success" "Successfully upgraded $cask_name"
      return 0
    fi
  fi
}

# Install a Homebrew formula
install_brew_package() {
  local package_name=$1
  
  if is_package_installed "$package_name"; then
    if [ "$FORCE_UPGRADE" = true ]; then
      print_message "info" "Package $package_name is already installed, but force upgrade is enabled"
      upgrade_brew_package "$package_name"
    else
      print_message "success" "Package $package_name is already installed"
    fi
    return 0
  fi
  
  print_message "info" "Installing package: $package_name"
  local install_cmd="$BREW_PATH install $package_name"
  
  if [ "$DRY_RUN" = true ]; then
    print_message "dryrun" "$install_cmd"
    return 0
  else
    execute_command "$install_cmd"
    if [ $? -ne 0 ]; then
      print_message "error" "Failed to install $package_name"
      return 1
    else
      print_message "success" "Successfully installed $package_name"
      return 0
    fi
  fi
}

# Install a Homebrew cask
install_brew_cask() {
  local cask_name=$1
  
  if is_cask_installed "$cask_name"; then
    if [ "$FORCE_UPGRADE" = true ]; then
      print_message "info" "Cask $cask_name is already installed, but force upgrade is enabled"
      upgrade_brew_cask "$cask_name"
    else
      print_message "success" "Cask $cask_name is already installed"
    fi
    return 0
  fi
  
  print_message "info" "Installing cask: $cask_name"
  local install_cmd="$BREW_PATH install --cask $cask_name"
  
  if [ "$DRY_RUN" = true ]; then
    print_message "dryrun" "$install_cmd"
    return 0
  else
    execute_command "$install_cmd"
    if [ $? -ne 0 ]; then
      print_message "error" "Failed to install $cask_name"
      return 1
    else
      print_message "success" "Successfully installed $cask_name"
      return 0
    fi
  fi
}

# Install Google Chrome
install_chrome() {
  if is_chrome_installed; then
    return 0
  fi
  
  print_message "info" "Installing Google Chrome"
  
  if [ "$DRY_RUN" = true ]; then
    print_message "dryrun" "$BREW_PATH install --cask google-chrome"
    return 0
  else
    install_brew_cask "google-chrome"
    return $?
  fi
}

# Main function for Homebrew and packages setup
setup_homebrew_and_packages() {
  print_message "info" "Phase 2: Setting up Homebrew and required packages"
  
  # Define required packages
  local core_packages=("jq" "git" "curl" "wget" "git-gui" "git-lfs" "htop" "netcat" "pwgen" "nmap" "coreutils" "gnu-sed")
  local python_packages=("python")
  
  # Detect architecture first
  detect_architecture
  
  # Check and install Homebrew if needed
  if ! check_homebrew; then
    if [ "$DRY_RUN" = true ]; then
      print_message "dryrun" "Would install Homebrew"
    else
      if ! install_homebrew; then
        print_message "error" "Homebrew installation failed. Cannot proceed with package installation."
        return 1
      fi
    fi
  fi
  
  # Ensure Homebrew is in PATH
  check_brew_in_path
  
  # Install core packages
  print_message "info" "Installing core packages..."
  for package in "${core_packages[@]}"; do
    install_brew_package "$package"
  done
  
  # Install Python
  print_message "info" "Installing Python..."
  for package in "${python_packages[@]}"; do
    install_brew_package "$package"
  done
  
  # pip is installed with Python, no need for separate installation
  
  # Install Google Chrome if needed
  print_message "info" "Checking for Google Chrome..."
  install_chrome
  
  print_message "success" "Phase 2: Homebrew and required packages setup completed"
  return 0
}

###########################################
# Phase 3: Install Zsh & Configure Default Shell
###########################################

# Check if Zsh is already installed
is_zsh_installed() {
  if command -v zsh >/dev/null 2>&1; then
    ZSH_PATH=$(command -v zsh)
    print_message "success" "Zsh is already installed at $ZSH_PATH"
    return 0
  else
    print_message "info" "Zsh is not installed"
    return 1
  fi
}

# Install Zsh using Homebrew
install_zsh() {
  if is_zsh_installed; then
    return 0
  fi
  
  print_message "info" "Installing Zsh..."
  
  if [ "$DRY_RUN" = true ]; then
    print_message "dryrun" "$BREW_PATH install zsh"
    # Simulate success for dry run
    ZSH_PATH="/usr/local/bin/zsh"
    return 0
  else
    install_brew_package "zsh"
    local result=$?
    
    if [ $result -eq 0 ]; then
      # Update ZSH_PATH after successful installation
      ZSH_PATH=$(command -v zsh)
      print_message "success" "Zsh has been successfully installed at $ZSH_PATH"
      return 0
    else
      print_message "error" "Failed to install Zsh"
      return 1
    fi
  fi
}

# Check if grml-zsh-config is already installed
is_grml_config_installed() {
  if [ -f "/etc/zshrc-grml" ]; then
    print_message "success" "grml-zsh-config is already installed"
    return 0
  else
    print_message "info" "grml-zsh-config is not installed"
    return 1
  fi
}

# Install grml-zsh-config
install_grml_config() {
  if is_grml_config_installed; then
    return 0
  fi
  
  print_message "info" "Installing grml-zsh-config..."
  
  local download_cmd="sudo wget https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc -O /etc/zshrc-grml"
  local symlink_cmd="sudo ln -sf /etc/zshrc-grml /etc/zshrc"
  
  # Check if running non-interactively (e.g., through SSH by AI)
  if ! tty -s; then
    print_message "warning" "Running in non-interactive mode, skipping sudo commands for grml-zsh-config"
    print_message "info" "Please run the following commands manually to install grml-zsh-config:"
    print_message "info" "$download_cmd"
    print_message "info" "$symlink_cmd"
    return 0
  fi
  
  if [ "$DRY_RUN" = true ]; then
    print_message "dryrun" "$download_cmd"
    print_message "dryrun" "$symlink_cmd"
    return 0
  else
    # Download the configuration file
    execute_command "$download_cmd"
    local download_result=$?
    
    if [ $download_result -ne 0 ]; then
      print_message "error" "Failed to download grml-zsh-config"
      return 1
    fi
    
    # Create the symlink
    execute_command "$symlink_cmd"
    local symlink_result=$?
    
    if [ $symlink_result -ne 0 ]; then
      print_message "error" "Failed to create symlink for grml-zsh-config"
      return 1
    fi
    
    print_message "success" "grml-zsh-config has been successfully installed"
    return 0
  fi
}

# Check if Zsh is already the default shell
is_zsh_default_shell() {
  # Get the current default shell
  local current_shell=$(dscl . -read /Users/$USER UserShell | awk '{print $2}')
  
  # First check: Compare with exact Zsh path
  if [ "$current_shell" = "$ZSH_PATH" ]; then
    print_message "success" "Zsh is already the default shell"
    return 0
  fi
  
  # Second check: Check if current shell ends with "zsh" (for system variants)
  if [[ "$current_shell" == */zsh ]]; then
    print_message "success" "Zsh (at $current_shell) is already the default shell"
    # Update ZSH_PATH to match the actual path being used
    ZSH_PATH="$current_shell"
    return 0
  else
    print_message "info" "Current default shell is $current_shell, not Zsh"
    return 1
  fi
}

# Set Zsh as the default shell
set_zsh_as_default() {
  # Ensure we have the ZSH_PATH
  if [ -z "$ZSH_PATH" ]; then
    if command -v zsh >/dev/null 2>&1; then
      ZSH_PATH=$(command -v zsh)
    else
      print_message "error" "Cannot set Zsh as default: ZSH_PATH is not defined and zsh not found in PATH"
      return 1
    fi
  fi
  
  if is_zsh_default_shell; then
    return 0
  fi
  
  print_message "info" "Setting Zsh as the default shell..."
  
  # Change the default shell with chsh directly
  local change_shell_cmd="chsh -s $ZSH_PATH"
  
  # Check if running non-interactively (e.g., through SSH by AI)
  if ! tty -s; then
    print_message "warning" "Running in non-interactive mode, skipping chsh command"
    print_message "info" "Please run 'chsh -s $ZSH_PATH' manually to set Zsh as your default shell"
    return 0
  fi
  
  if [ "$DRY_RUN" = true ]; then
    print_message "dryrun" "$change_shell_cmd"
    return 0
  else
    # Change the default shell
    execute_command "$change_shell_cmd"
    local result=$?
    
    if [ $result -ne 0 ]; then
      print_message "error" "Failed to set Zsh as the default shell"
      print_message "info" "You may need to run 'chsh -s $ZSH_PATH' manually"
      return 1
    else
      print_message "success" "Zsh has been set as the default shell"
      print_message "info" "Note: You may need to log out and log back in for the changes to take effect"
      return 0
    fi
  fi
}

# Main function for Zsh setup
setup_zsh() {
  print_message "info" "Phase 3: Setting up Zsh and configuring default shell"
  
  # First check/install Zsh
  if ! is_zsh_installed; then
    if [ "$DRY_RUN" = true ]; then
      print_message "dryrun" "Would install Zsh"
      ZSH_PATH="/usr/local/bin/zsh"  # Simulate a ZSH_PATH for dry run
    else
      if ! install_zsh; then
        print_message "error" "Zsh installation failed. Cannot proceed with Zsh configuration."
        return 1
      fi
    fi
  fi
  
  # Then check/install grml-zsh-config
  if ! is_grml_config_installed; then
    if [ "$DRY_RUN" = true ]; then
      print_message "dryrun" "Would install grml-zsh-config"
    else
      if ! install_grml_config; then
        print_message "warning" "grml-zsh-config installation failed, but continuing with Zsh setup"
      fi
    fi
  fi
  
  # Finally, set Zsh as the default shell if needed
  if ! is_zsh_default_shell; then
    if [ "$DRY_RUN" = true ]; then
      print_message "dryrun" "Would set Zsh as the default shell"
    else
      if ! set_zsh_as_default; then
        print_message "warning" "Failed to set Zsh as the default shell"
      fi
    fi
  fi
  
  print_message "success" "Phase 3: Zsh setup completed"
  return 0
}

###########################################
# Phase 4: Install NVM & Latest LTS Node
###########################################

# Define NVM paths and URLs
NVM_DIR="$HOME/.nvm"
NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh"
NVM_LOAD_SCRIPT="[ -s \"$NVM_DIR/nvm.sh\" ] && \. \"$NVM_DIR/nvm.sh\""
NVM_COMPLETION_SCRIPT="[ -s \"$NVM_DIR/bash_completion\" ] && \. \"$NVM_DIR/bash_completion\""

# Check if NVM is already installed
is_nvm_installed() {
  if [ -d "$NVM_DIR" ] && [ -f "$NVM_DIR/nvm.sh" ]; then
    print_message "success" "NVM is already installed at $NVM_DIR"
    return 0
  else
    print_message "info" "NVM is not installed"
    return 1
  fi
}

# Check if NVM is configured in shell profile
is_nvm_configured() {
  local shell_profile=""
  
  # Determine which shell profile to check
  if [ -f "$HOME/.zshrc" ]; then
    shell_profile="$HOME/.zshrc"
  elif [ -f "$HOME/.bashrc" ]; then
    shell_profile="$HOME/.bashrc"
  elif [ -f "$HOME/.bash_profile" ]; then
    shell_profile="$HOME/.bash_profile"
  else
    print_message "warning" "No shell profile found to check for NVM configuration"
    return 1
  fi
  
  # Check if NVM load script is in profile
  if grep -q "nvm.sh" "$shell_profile"; then
    print_message "success" "NVM is configured in $shell_profile"
    return 0
  else
    print_message "info" "NVM is not configured in $shell_profile"
    return 1
  fi
}

# Install NVM
install_nvm() {
  if is_nvm_installed; then
    return 0
  fi
  
  print_message "info" "Installing NVM..."
  
  local install_cmd="curl -o- $NVM_INSTALL_URL | bash"
  
  if [ "$DRY_RUN" = true ]; then
    print_message "dryrun" "$install_cmd"
    return 0
  else
    execute_command "$install_cmd"
    local result=$?
    
    if [ $result -ne 0 ]; then
      print_message "error" "Failed to install NVM"
      return 1
    fi
    
    # Check if installation was successful
    if [ -d "$NVM_DIR" ] && [ -f "$NVM_DIR/nvm.sh" ]; then
      print_message "success" "NVM installed successfully"
      return 0
    else
      print_message "error" "NVM directory or script not found after installation"
      return 1
    fi
  fi
}

# Configure NVM in shell profile if needed
configure_nvm() {
  if is_nvm_configured; then
    return 0
  fi
  
  print_message "info" "Configuring NVM in shell profile..."
  
  local shell_profile=""
  
  # Determine which shell profile to use
  if [ -f "$HOME/.zshrc" ]; then
    shell_profile="$HOME/.zshrc"
  elif [ -f "$HOME/.bashrc" ]; then
    shell_profile="$HOME/.bashrc"
  elif [ -f "$HOME/.bash_profile" ]; then
    shell_profile="$HOME/.bash_profile"
  else
    print_message "warning" "No shell profile found to configure NVM"
    print_message "info" "Creating .zshrc file"
    shell_profile="$HOME/.zshrc"
    if [ "$DRY_RUN" = false ]; then
      touch "$shell_profile"
    fi
  fi
  
  local config_cmd="echo '
# NVM Configuration
export NVM_DIR=\"\$HOME/.nvm\"
$NVM_LOAD_SCRIPT
$NVM_COMPLETION_SCRIPT
' >> $shell_profile"
  
  if [ "$DRY_RUN" = true ]; then
    print_message "dryrun" "$config_cmd"
    return 0
  else
    execute_command "$config_cmd"
    local result=$?
    
    if [ $result -ne 0 ]; then
      print_message "error" "Failed to configure NVM in shell profile"
      return 1
    fi
    
    print_message "success" "NVM configured in $shell_profile"
    return 0
  fi
}

# Load NVM for the current session
load_nvm() {
  print_message "info" "Loading NVM for current session..."
  
  if [ "$DRY_RUN" = true ]; then
    print_message "dryrun" "Would load NVM from $NVM_DIR/nvm.sh"
    return 0
  else
    if [ -f "$NVM_DIR/nvm.sh" ]; then
      # Source NVM script
      export NVM_DIR="$HOME/.nvm"
      \. "$NVM_DIR/nvm.sh"
      \. "$NVM_DIR/bash_completion" 2>/dev/null
      
      # Verify NVM is loaded
      if command -v nvm >/dev/null 2>&1; then
        print_message "success" "NVM loaded successfully"
        return 0
      else
        print_message "error" "Failed to load NVM for current session"
        return 1
      fi
    else
      print_message "error" "NVM script not found at $NVM_DIR/nvm.sh"
      return 1
    fi
  fi
}

# Install Node.js LTS version
install_node_lts() {
  print_message "info" "Installing Node.js LTS version..."
  
  if [ "$DRY_RUN" = true ]; then
    print_message "dryrun" "nvm install --lts"
    return 0
  else
    # Ensure NVM is loaded
    if ! command -v nvm >/dev/null 2>&1; then
      print_message "warning" "NVM not loaded, attempting to load..."
      if ! load_nvm; then
        print_message "error" "Cannot install Node.js without NVM"
        return 1
      fi
    fi
    
    # Install LTS version
    execute_command "nvm install --lts"
    local result=$?
    
    if [ $result -ne 0 ]; then
      print_message "error" "Failed to install Node.js LTS"
      return 1
    fi
    
    # Set as default
    execute_command "nvm alias default node"
    
    # Verify installation
    if node --version >/dev/null 2>&1; then
      print_message "success" "Node.js $(node --version) installed successfully"
      print_message "success" "npm $(npm --version) installed successfully"
      return 0
    else
      print_message "error" "Node.js installation verification failed"
      return 1
    fi
  fi
}

# Configure npm global settings
configure_npm() {
  print_message "info" "Configuring npm global settings..."
  
  if [ "$DRY_RUN" = true ]; then
    print_message "dryrun" "Would configure npm global settings"
    return 0
  else
    # Ensure npm is available
    if ! command -v npm >/dev/null 2>&1; then
      print_message "warning" "npm not found, cannot configure"
      return 1
    fi
    
    # Create global npm directory in user's home
    local npm_global_dir="$HOME/.npm-global"
    execute_command "mkdir -p $npm_global_dir"
    
    # Configure npm to use this directory
    execute_command "npm config set prefix '$npm_global_dir'"
    
    # Add to PATH in profile if needed
    local shell_profile=""
    if [ -f "$HOME/.zshrc" ]; then
      shell_profile="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
      shell_profile="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
      shell_profile="$HOME/.bash_profile"
    fi
    
    if [ -n "$shell_profile" ]; then
      if ! grep -q "NPM_GLOBAL" "$shell_profile"; then
        execute_command "echo '
# NPM Global Path
export PATH=\"\$HOME/.npm-global/bin:\$PATH\"
' >> $shell_profile"
      fi
    fi
    
    print_message "success" "npm global configuration complete"
    print_message "info" "Global packages will be installed in $npm_global_dir"
    return 0
  fi
}

# Main function for NVM and Node.js setup
setup_node() {
  print_message "info" "Phase 4: Setting up NVM and Node.js"
  
  # Install NVM if needed
  if ! is_nvm_installed; then
    if [ "$DRY_RUN" = true ]; then
      print_message "dryrun" "Would install NVM"
    else
      if ! install_nvm; then
        print_message "error" "NVM installation failed. Cannot proceed with Node.js setup."
        return 1
      fi
    fi
  fi
  
  # Configure NVM in shell profile if needed
  if ! is_nvm_configured; then
    if [ "$DRY_RUN" = true ]; then
      print_message "dryrun" "Would configure NVM in shell profile"
    else
      if ! configure_nvm; then
        print_message "warning" "NVM configuration in shell profile failed, but continuing"
      fi
    fi
  fi
  
  # Load NVM for current session if needed
  if ! command -v nvm >/dev/null 2>&1; then
    if [ "$DRY_RUN" = true ]; then
      print_message "dryrun" "Would load NVM for current session"
    else
      if ! load_nvm; then
        print_message "warning" "Failed to load NVM for current session, but continuing"
      fi
    fi
  fi
  
  # Install Node.js LTS version if needed
  if ! command -v node >/dev/null 2>&1; then
    if [ "$DRY_RUN" = true ]; then
      print_message "dryrun" "Would install Node.js LTS version"
    else
      if ! install_node_lts; then
        print_message "error" "Node.js installation failed"
        return 1
      fi
    fi
  fi
  
  # Configure npm global settings
  if [ "$DRY_RUN" = true ]; then
    print_message "dryrun" "Would configure npm global settings"
  else
    if ! configure_npm; then
      print_message "warning" "npm global configuration failed, but continuing"
    fi
  fi
  
  print_message "success" "Phase 4: NVM and Node.js setup completed"
  return 0
}

###########################################
# Phase 5: Install & Configure VSCode + Extensions
###########################################

# Define VSCode paths and extensions
VSCODE_APP_PATH="/Applications/Visual Studio Code.app"
VSCODE_CASK_NAME="visual-studio-code"

# Arrays for required extensions
AI_EXTENSIONS=("kodu-ai.claude-dev-experimental" "saoudrizwan.claude-dev" "rooveterinaryinc.roo-cline" "GitHub.copilot" "GitHub.copilot-chat")
OTHER_EXTENSIONS=("EditorConfig.EditorConfig" "PKief.material-icon-theme" "PaulOlteanu.theme-railscasts")
# Combine all extensions into one array
ALL_EXTENSIONS=("${AI_EXTENSIONS[@]}" "${OTHER_EXTENSIONS[@]}")

# Check if VSCode is already installed
is_vscode_installed() {
  # Method 1: Check if the app exists in Applications
  if [ -d "$VSCODE_APP_PATH" ]; then
    print_message "success" "VSCode is already installed at $VSCODE_APP_PATH"
    return 0
  fi
  
  # Method 2: Check through Homebrew cask
  if is_cask_installed "$VSCODE_CASK_NAME"; then
    print_message "success" "VSCode is already installed via Homebrew"
    return 0
  fi
  
  # Method 3: Check for 'code' command in PATH
  if command -v code >/dev/null 2>&1; then
    print_message "success" "VSCode is already installed (command 'code' is available)"
    return 0
  fi
  
  print_message "info" "VSCode is not installed"
  return 1
}

# Install VSCode using Homebrew
install_vscode() {
  if is_vscode_installed; then
    if [ "$FORCE_UPGRADE" = true ]; then
      print_message "info" "VSCode is already installed, but force upgrade is enabled"
      upgrade_brew_cask "$VSCODE_CASK_NAME"
    fi
    return 0
  fi
  
  print_message "info" "Installing Visual Studio Code..."
  
  if [ "$DRY_RUN" = true ]; then
    print_message "dryrun" "$BREW_PATH install --cask $VSCODE_CASK_NAME"
    return 0
  else
    install_brew_cask "$VSCODE_CASK_NAME"
    local result=$?
    
    if [ $result -ne 0 ]; then
      print_message "error" "Failed to install VSCode"
      return 1
    else
      # Check if 'code' command is available after installation
      if ! command -v code >/dev/null 2>&1; then
        print_message "warning" "VSCode installed but 'code' command is not available in PATH"
        print_message "warning" "You may need to manually add the VSCode bin directory to your PATH"
        print_message "info" "Try opening VSCode and running the 'Shell Command: Install 'code' command in PATH' command from the Command Palette"
        
        # Attempt to install the command if VSCode is available
        if [ -d "$VSCODE_APP_PATH" ]; then
          print_message "info" "Attempting to install 'code' command automatically..."
          local install_cmd="ln -sf '$VSCODE_APP_PATH/Contents/Resources/app/bin/code' /usr/local/bin/code"
          execute_command "$install_cmd"
        fi
      else
        print_message "success" "VSCode and 'code' command installed successfully"
      fi
      
      return 0
    fi
  fi
}

# Get the VSCode binary path
get_vscode_binary() {
  local code_path=""
  
  # Check for macOS VSCode binary with proper quoting for paths with spaces
  if [ -f "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]; then
    code_path='"/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"'
  # Check for command in PATH
  elif command -v code >/dev/null 2>&1; then
    code_path="\"$(command -v code)\""
  else
    print_message "warning" "VSCode 'code' binary not found in expected locations"
    return 1
  fi
  
  echo "$code_path"
}

# Check if a VSCode extension is installed
is_extension_installed() {
  local extension_id=$1
  local code_path=$(get_vscode_binary)
  
  if [ -z "$code_path" ]; then
    print_message "warning" "Cannot check for installed extensions: VSCode binary not found"
    return 1
  fi
  
  if [ "$DRY_RUN" = true ]; then
    # In dry-run mode, we still want to check if the extension is actually installed
    # This makes dry-run output more accurate by showing only what would actually change
    if "$code_path" --list-extensions 2>/dev/null | grep -q "^$extension_id$"; then
      print_message "info" "Extension $extension_id is already installed"
      return 0
    fi
    return 1
  else
    # Normal mode
    if "$code_path" --list-extensions 2>/dev/null | grep -q "^$extension_id$"; then
      print_message "success" "Extension $extension_id is already installed"
      return 0
    else
      return 1
    fi
  fi
}

# Install a VSCode extension
install_vscode_extension() {
  local extension_id=$1
  local force_upgrade=$2
  local code_path=$(get_vscode_binary)
  
  if [ -z "$code_path" ]; then
    print_message "error" "Cannot install extension: VSCode binary not found"
    return 1
  fi
  
  # Check if already installed (unless force upgrade is enabled)
  if [ "$force_upgrade" != true ] && is_extension_installed "$extension_id"; then
    return 0
  fi
  
  print_message "info" "Installing VSCode extension: $extension_id"
  
  # When force upgrade is enabled and the extension is already installed, we need to uninstall it first
  if [ "$force_upgrade" = true ] && is_extension_installed "$extension_id"; then
    print_message "info" "Force upgrade enabled, reinstalling extension $extension_id"
    if [ "$DRY_RUN" = true ]; then
      print_message "dryrun" "$code_path --uninstall-extension $extension_id"
    else
      execute_command "$code_path --uninstall-extension $extension_id"
    fi
  fi
  
  # Install the extension
  if [ "$DRY_RUN" = true ]; then
    print_message "dryrun" "$code_path --install-extension $extension_id"
    return 0
  else
    execute_command "$code_path --install-extension $extension_id"
    local result=$?
    
    if [ $result -ne 0 ]; then
      print_message "error" "Failed to install extension $extension_id"
      return 1
    else
      print_message "success" "Successfully installed extension $extension_id"
      return 0
    fi
  fi
}

# Check if VSCode is running and close it if needed
ensure_vscode_closed() {
  print_message "info" "Checking if VSCode is running..."
  
  if pgrep -x "Code" > /dev/null || pgrep -x "Visual Studio Code" > /dev/null; then
    print_message "warning" "VSCode is currently running. It must be closed to apply settings correctly."
    
    if [ "$DRY_RUN" = true ]; then
      print_message "dryrun" "Would kill VSCode processes"
      return 0
    else
      print_message "info" "Closing VSCode..."
      # Try gentle approach first with osascript (macOS only)
      if command -v osascript >/dev/null 2>&1; then
        osascript -e 'tell application "Visual Studio Code" to quit' 2>/dev/null || true
        # Wait a bit to see if it closed gracefully
        sleep 2
      fi
      
      # If still running, use force approach
      if pgrep -x "Code" > /dev/null || pgrep -x "Visual Studio Code" > /dev/null; then
        # Kill processes
        pkill -x "Code" 2>/dev/null || true
        pkill -x "Visual Studio Code" 2>/dev/null || true
        
        # Wait for processes to terminate
        sleep 2
        
        # Check if it's really closed now
        if pgrep -x "Code" > /dev/null || pgrep -x "Visual Studio Code" > /dev/null; then
          print_message "warning" "Could not close VSCode completely. Settings may not apply correctly."
        else
          print_message "success" "VSCode closed successfully"
        fi
      else
        print_message "success" "VSCode closed successfully"
      fi
    fi
  else
    print_message "info" "VSCode is not running. Proceeding with configuration."
  fi
}

# Get VSCode settings file path
get_vscode_settings_path() {
  local settings_dir=""
  
  # Mac OS location
  if [ -d "$HOME/Library/Application Support/Code/User" ]; then
    settings_dir="$HOME/Library/Application Support/Code/User"
  # Linux location
  elif [ -d "$HOME/.config/Code/User" ]; then
    settings_dir="$HOME/.config/Code/User"
  # Windows location (WSL)
  elif [ -d "$HOME/.vscode/User" ]; then
    settings_dir="$HOME/.vscode/User"
  else
    print_message "warning" "Could not find VSCode settings directory"
    return 1
  fi
  
  echo "$settings_dir/settings.json"
}

# Configure VSCode settings
configure_vscode_themes() {
  print_message "info" "Configuring VSCode settings..."
  
  # Get the settings file path
  local settings_file=$(get_vscode_settings_path)
  if [ $? -ne 0 ] || [ -z "$settings_file" ]; then
    print_message "error" "Could not determine VSCode settings file location"
    return 1
  fi
  
  # Check if settings file exists, create if it doesn't
  if [ ! -f "$settings_file" ] && [ "$DRY_RUN" = false ]; then
    print_message "info" "VSCode settings file not found, creating it..."
    execute_command "mkdir -p $(dirname \"$settings_file\")"
    execute_command "echo '{}' > \"$settings_file\""
    
    if [ ! -f "$settings_file" ]; then
      print_message "error" "Failed to create VSCode settings file"
      return 1
    fi
  fi
  
  if [ "$DRY_RUN" = true ]; then
    print_message "dryrun" "Would update VSCode settings by merging with existing configuration"
    return 0
  else
    # Read current settings
    local current_settings=""
    if [ -f "$settings_file" ]; then
      current_settings=$(cat "$settings_file")
    else
      current_settings="{}"
    fi
    
    # Ensure jq is available for JSON manipulation (it should be installed by Homebrew)
    if ! command -v jq >/dev/null 2>&1; then
      print_message "error" "jq is not installed but is required for configuration. Please ensure Homebrew and jq are properly installed."
      return 1
    fi
    
    print_message "info" "Using jq to update VSCode settings by merging with existing configuration..."
    
    # Create a temporary file
    local temp_file=$(mktemp)
    
    # Define the settings we want to ensure are set
    local settings_to_apply='{
  "workbench.iconTheme": "material-icon-theme",
  "workbench.colorTheme": "Railscasts Renewed",
  "editor.formatOnSave": true,
  "editor.tabSize": 2,
  "editor.wordWrap": "on",
  "files.autoSave": "afterDelay",
  "files.autoSaveDelay": 1000,
  "github.copilot.enable": {
    "*": true,
    "plaintext": true,
    "markdown": true,
    "yaml": true
  },
  "github.copilot.advanced": {
    "indentation.enable": true
  },
  "workbench.panel.defaultLocation": "right",
  "workbench.panel.opensMaximized": "always",
  "workbench.secondarySideBar.showLabels": false,
  "workbench.view.extension.kodu-claude-coder-main-ActivityBar.state.hidden": [{"id":"kodu-claude-coder-main.SidebarProvider","isHidden":false}],
  "workbench.view.extension.roo-cline-ActivityBar.state.hidden": [{"id":"roo-cline.SidebarProvider","isHidden":false}],
  "workbench.view.extension.claude-dev-ActivityBar.state.hidden": [{"id":"claude-dev.SidebarProvider","isHidden":false}],
  "workbench.activityBar.hidden": false,
  "workbench.activityBar.location": "default"
}'
    
    # Merge existing settings with our settings (our settings take precedence)
    echo "$current_settings" | jq --argjson new "$settings_to_apply" '. * $new' > "$temp_file"
    
    # Replace the original file
    execute_command "mv \"$temp_file\" \"$settings_file\""
    print_message "success" "VSCode settings configured successfully"
    return 0
  fi
}

# Main function for VSCode setup
setup_vscode() {
  print_message "info" "Phase 5: Setting up VSCode and extensions"
  
  # Make sure VSCode is closed before we start
  ensure_vscode_closed
  
  # Install VSCode if needed
  if ! is_vscode_installed; then
    if [ "$DRY_RUN" = true ]; then
      print_message "dryrun" "Would install VSCode"
    else
      if ! install_vscode; then
        print_message "error" "VSCode installation failed. Cannot proceed with extension installation."
        return 1
      fi
    fi
  fi
  
  # Install required extensions
  print_message "info" "Installing required VSCode extensions..."
  
  # Install AI extensions
  print_message "info" "Installing AI extensions..."
  for extension in "${AI_EXTENSIONS[@]}"; do
    install_vscode_extension "$extension" "$FORCE_UPGRADE"
  done
  
  # Install other extensions
  print_message "info" "Installing additional extensions..."
  for extension in "${OTHER_EXTENSIONS[@]}"; do
    install_vscode_extension "$extension" "$FORCE_UPGRADE"
  done
  
  # Configure themes
  if ! configure_vscode_themes; then
    print_message "warning" "Failed to configure VSCode themes, but continuing with setup"
  fi
  
  print_message "success" "Phase 5: VSCode and extensions setup completed"
  return 0
}

###########################################
# Phase 6: Configure AI Extensions
###########################################

# Define extension IDs and configuration paths
KODU_EXTENSION_ID="kodu-ai.claude-dev-experimental"
CLINE_EXTENSION_ID="saoudrizwan.claude-dev"
ROOCODE_EXTENSION_ID="rooveterinaryinc.roo-cline"
COPILOT_EXTENSION_ID="GitHub.copilot"
COPILOT_CHAT_EXTENSION_ID="GitHub.copilot-chat"

# Get base path for VSCode extensions configuration
get_vscode_extensions_path() {
  local base_path=""
  
  # Check for macOS path
  if [ -d "$HOME/Library/Application Support/Code" ]; then
    base_path="$HOME/Library/Application Support/Code"
  # Check for Linux path
  elif [ -d "$HOME/.config/Code" ]; then
    base_path="$HOME/.config/Code"
  # Check for Windows WSL path
  elif [ -d "$HOME/.vscode" ]; then
    base_path="$HOME/.vscode"
  else
    print_message "error" "Could not determine VSCode extensions base path"
    return 1
  fi
  
  echo "$base_path"
}

# Get extension configuration path
get_extension_config_path() {
  local extension_id=$1
  local config_type=$2  # "settings", "globalState", etc.
  
  local vscode_path=$(get_vscode_extensions_path)
  if [ $? -ne 0 ] || [ -z "$vscode_path" ]; then
    return 1
  fi
  
  local config_path=""
  
  # Different extensions store their settings in different places
  case "$extension_id" in
    "$KODU_EXTENSION_ID")
      config_path="$vscode_path/User/globalStorage/$extension_id"
      ;;
    "$CLINE_EXTENSION_ID")
      config_path="$vscode_path/User/globalStorage/$extension_id/settings"
      ;;
    "$ROOCODE_EXTENSION_ID")
      config_path="$vscode_path/User/globalStorage/$extension_id/settings"
      ;;
    "$COPILOT_EXTENSION_ID"|"$COPILOT_CHAT_EXTENSION_ID")
      config_path="$vscode_path/User/$config_type.json"
      ;;
    *)
      print_message "error" "Unknown extension ID: $extension_id"
      return 1
      ;;
  esac
  
  echo "$config_path"
}

# Backup extension configuration before modification
backup_extension_config() {
  local config_path=$1
  
  if [ ! -e "$config_path" ]; then
    print_message "info" "No configuration to backup at $config_path"
    return 0
  fi
  
  local backup_path="${config_path}.bak-$(date +%Y%m%d%H%M%S)"
  
  print_message "info" "Backing up $config_path to $backup_path"
  
  if [ "$DRY_RUN" = true ]; then
    print_message "dryrun" "Would backup $config_path to $backup_path"
    return 0
  else
    if [ -d "$config_path" ]; then
      # It's a directory, so use cp -r
      execute_command "cp -r \"$config_path\" \"$backup_path\""
    else
      # It's a file, so use cp
      execute_command "cp \"$config_path\" \"$backup_path\""
    fi
    
    local result=$?
    if [ $result -ne 0 ]; then
      print_message "warning" "Failed to backup configuration at $config_path"
      return 1
    else
      print_message "success" "Configuration backup created at $backup_path"
      return 0
    fi
  fi
}

# Create directory if it doesn't exist
ensure_directory_exists() {
  local dir_path=$1
  
  if [ ! -d "$dir_path" ]; then
    print_message "info" "Creating directory: $dir_path"
    
    if [ "$DRY_RUN" = true ]; then
      print_message "dryrun" "mkdir -p \"$dir_path\""
      return 0
    else
      execute_command "mkdir -p \"$dir_path\""
      local result=$?
      
      if [ $result -ne 0 ]; then
        print_message "error" "Failed to create directory at $dir_path"
        return 1
      else
        print_message "success" "Directory created at $dir_path"
        return 0
      fi
    fi
  fi
  
  return 0
}

# Get current Kodu settings to use as a template
get_current_kodu_settings() {
  print_message "info" "Reading current Kodu settings..."
  
  # Get Kodu config path for the current machine
  local kodu_path="$HOME/Library/Application Support/Code/User/globalStorage/$KODU_EXTENSION_ID"
  local settings_file="$kodu_path/settings.json"
  
  if [ ! -f "$settings_file" ]; then
    print_message "warning" "Current Kodu settings not found at $settings_file"
    # Return default template if current settings not found
    echo '{
  "defaultModelId": "claude-3-haiku-20240307",
  "defaultMode": "direct",
  "enableThinking": true,
  "tokenBudget": 4000
}'
    return 0
  fi
  
  # Ensure jq is available to manipulate JSON
  if ! command -v jq >/dev/null 2>&1; then
    print_message "error" "jq is not installed but is required for configuration. Please ensure Homebrew and jq are properly installed."
    return 1
  fi
  
  # Read current settings and remove the API key
  local current_settings=$(cat "$settings_file" | jq 'del(.apiKey)')
  echo "$current_settings"
}

# Configure Kodu AI extension
configure_kodu() {
  print_message "info" "Configuring Kodu AI extension..."
  
  # Load API keys
  if [ ! -f "$API_KEYS_FILE" ]; then
    print_message "error" "API keys file not found at $API_KEYS_FILE"
    return 1
  fi
  
  # Get Kodu config path for target installation
  local kodu_path=$(get_extension_config_path "$KODU_EXTENSION_ID")
  if [ $? -ne 0 ] || [ -z "$kodu_path" ]; then
    print_message "error" "Failed to determine Kodu configuration path"
    return 1
  fi
  
  # Ensure config directory exists
  ensure_directory_exists "$kodu_path"
  
  # Define Kodu settings file
  local settings_file="$kodu_path/settings.json"
  
  # Backup existing settings if any
  if [ -f "$settings_file" ]; then
    backup_extension_config "$settings_file"
  fi
  
  if [ "$DRY_RUN" = true ]; then
    print_message "dryrun" "Would get current Kodu settings and merge with API key"
    print_message "dryrun" "Would configure Kodu AI with API key from $API_KEYS_FILE"
    return 0
  else
    # Ensure jq is available for JSON manipulation
    if ! command -v jq >/dev/null 2>&1; then
      print_message "error" "jq is not installed but is required for configuration. Please ensure Homebrew and jq are properly installed."
      return 1
    fi
    
    # Extract Kodu API key
    local kodu_key=""
    kodu_key=$(jq -r .kodu "$API_KEYS_FILE")
    
    if [ -z "$kodu_key" ] || [ "$kodu_key" = "null" ]; then
      print_message "error" "Failed to extract Kodu API key from $API_KEYS_FILE"
      return 1
    fi
    
    # Get current settings template
    local current_settings=$(get_current_kodu_settings)
    
    # Create new settings with current template and new API key
    local settings_content=""
    settings_content=$(echo "$current_settings" | jq --arg key "$kodu_key" '. + {apiKey: $key}')
    
    # Write settings to file
    echo "$settings_content" > "$settings_file"
    
    # Set restrictive permissions on the settings file (contains API key)
    chmod 600 "$settings_file"
    
    print_message "success" "Kodu AI extension configured successfully with current settings"
    return 0
  fi
}

# Get current Cline API settings to use as a template
get_current_cline_api_settings() {
  print_message "info" "Reading current Cline API settings..."
  
  # Get Cline config path for the current machine
  local cline_path="$HOME/Library/Application Support/Code/User/globalStorage/$CLINE_EXTENSION_ID/settings"
  local api_settings_file="$cline_path/api_settings.json"
  
  if [ ! -f "$api_settings_file" ]; then
    print_message "warning" "Current Cline API settings not found at $api_settings_file"
    # Return default template if current settings not found
    echo '{
  "org": ""
}'
    return 0
  fi
  
  # Ensure jq is available for JSON manipulation
  if ! command -v jq >/dev/null 2>&1; then
    print_message "error" "jq is not installed but is required for configuration. Please ensure Homebrew and jq are properly installed."
    return 1
  fi
  
  # Read current settings and remove the API key
  local current_settings=$(cat "$api_settings_file" | jq 'del(.key)')
  echo "$current_settings"
}

# Get current Cline model settings to use as a template
get_current_cline_model_settings() {
  print_message "info" "Reading current Cline model settings..."
  
  # Get Cline config path for the current machine
  local cline_path="$HOME/Library/Application Support/Code/User/globalStorage/$CLINE_EXTENSION_ID/settings"
  local model_settings_file="$cline_path/model_settings.json"
  
  if [ ! -f "$model_settings_file" ]; then
    print_message "warning" "Current Cline model settings not found at $model_settings_file"
    # Return default template if current settings not found
    echo '{
  "model": "claude-3-sonnet-20240229",
  "temperature": 0.7,
  "maxTokens": 4000,
  "systemPrompt": "You are Claude, a helpful AI assistant."
}'
    return 0
  fi
  
  # Read current model settings
  cat "$model_settings_file"
}

# Configure Cline extension
configure_cline() {
  print_message "info" "Configuring Cline extension..."
  
  # Load API keys
  if [ ! -f "$API_KEYS_FILE" ]; then
    print_message "error" "API keys file not found at $API_KEYS_FILE"
    return 1
  fi
  
  # Get Cline config path for target installation
  local cline_path=$(get_extension_config_path "$CLINE_EXTENSION_ID")
  if [ $? -ne 0 ] || [ -z "$cline_path" ]; then
    print_message "error" "Failed to determine Cline configuration path"
    return 1
  fi
  
  # Ensure config directory exists
  ensure_directory_exists "$cline_path"
  
  # Define Cline settings files
  local api_settings_file="$cline_path/api_settings.json"
  local model_settings_file="$cline_path/model_settings.json"
  
  # Backup existing settings if any
  if [ -f "$api_settings_file" ]; then
    backup_extension_config "$api_settings_file"
  fi
  if [ -f "$model_settings_file" ]; then
    backup_extension_config "$model_settings_file"
  fi
  
  if [ "$DRY_RUN" = true ]; then
    print_message "dryrun" "Would get current Cline settings and merge with API key"
    print_message "dryrun" "Would configure Cline with API key from $API_KEYS_FILE"
    return 0
  else
    # Ensure jq is available for JSON manipulation
    if ! command -v jq >/dev/null 2>&1; then
      print_message "error" "jq is not installed but is required for configuration. Please ensure Homebrew and jq are properly installed."
      return 1
    fi
    
    # Extract Cline API key
    local cline_key=""
    cline_key=$(jq -r .cline "$API_KEYS_FILE")
    
    if [ -z "$cline_key" ] || [ "$cline_key" = "null" ]; then
      print_message "error" "Failed to extract Cline API key from $API_KEYS_FILE"
      return 1
    fi
    
    # Get current API settings template
    local current_api_settings=$(get_current_cline_api_settings)
    
    # Create new API settings with current template and new API key
    local api_settings_content=""
    api_settings_content=$(echo "$current_api_settings" | jq --arg key "$cline_key" '. + {key: $key}')
    
    # Get current model settings
    local model_settings_content=$(get_current_cline_model_settings)
    
    # Write settings to files
    echo "$api_settings_content" > "$api_settings_file"
    echo "$model_settings_content" > "$model_settings_file"
    
    # Set restrictive permissions on the API settings file (contains API key)
    chmod 600 "$api_settings_file"
    
    print_message "success" "Cline extension configured successfully with current settings"
    return 0
  fi
}

# Get current Roocode settings to use as a template
get_current_roocode_settings() {
  print_message "info" "Reading current Roocode settings..."
  
  # Get Roocode config path for the current machine
  local roocode_path="$HOME/Library/Application Support/Code/User/globalStorage/$ROOCODE_EXTENSION_ID/settings"
  local settings_file="$roocode_path/roocode_settings.json"
  
  if [ ! -f "$settings_file" ]; then
    print_message "warning" "Current Roocode settings not found at $settings_file"
    # Return default template if current settings not found
    echo '{
  "defaultModel": "claude-3-opus-20240229",
  "defaultThinking": true,
  "tokenBudget": 4000
}'
    return 0
  fi
  
  # Ensure jq is available for JSON manipulation
  if ! command -v jq >/dev/null 2>&1; then
    print_message "error" "jq is not installed but is required for configuration. Please ensure Homebrew and jq are properly installed."
    return 1
  fi
  
  # Read current settings and remove the API key
  local current_settings=$(cat "$settings_file" | jq 'del(.apiKey)')
  echo "$current_settings"
}

# Configure Roocode extension
configure_roocode() {
  print_message "info" "Configuring Roocode extension..."
  
  # Load API keys
  if [ ! -f "$API_KEYS_FILE" ]; then
    print_message "error" "API keys file not found at $API_KEYS_FILE"
    return 1
  fi
  
  # Get Roocode config path for target installation
  local roocode_path=$(get_extension_config_path "$ROOCODE_EXTENSION_ID")
  if [ $? -ne 0 ] || [ -z "$roocode_path" ]; then
    print_message "error" "Failed to determine Roocode configuration path"
    return 1
  fi
  
  # Ensure config directory exists
  ensure_directory_exists "$roocode_path"
  
  # Define Roocode settings file
  local settings_file="$roocode_path/roocode_settings.json"
  
  # Backup existing settings if any
  if [ -f "$settings_file" ]; then
    backup_extension_config "$settings_file"
  fi
  
  if [ "$DRY_RUN" = true ]; then
    print_message "dryrun" "Would get current Roocode settings and merge with API key"
    print_message "dryrun" "Would configure Roocode with API key from $API_KEYS_FILE"
    return 0
  else
    # Ensure jq is available for JSON manipulation
    if ! command -v jq >/dev/null 2>&1; then
      print_message "error" "jq is not installed but is required for configuration. Please ensure Homebrew and jq are properly installed."
      return 1
    fi
    
    # Extract Roocode API key
    local roocode_key=""
    roocode_key=$(jq -r .roocode "$API_KEYS_FILE")
    
    if [ -z "$roocode_key" ] || [ "$roocode_key" = "null" ]; then
      print_message "error" "Failed to extract Roocode API key from $API_KEYS_FILE"
      return 1
    fi
    
    # Get current settings template
    local current_settings=$(get_current_roocode_settings)
    
    # Create new settings with current template and new API key
    local settings_content=""
    settings_content=$(echo "$current_settings" | jq --arg key "$roocode_key" '. + {apiKey: $key}')
    
    # Write settings to file
    echo "$settings_content" > "$settings_file"
    
    # Set restrictive permissions on the settings file (contains API key)
    chmod 600 "$settings_file"
    
    print_message "success" "Roocode extension configured successfully with current settings"
    return 0
  fi
}

# Configure GitHub Copilot extensions
configure_copilot() {
  print_message "info" "Configuring GitHub Copilot extensions..."
  
  # Get VSCode settings path
  local settings_file=$(get_vscode_settings_path)
  if [ $? -ne 0 ] || [ -z "$settings_file" ]; then
    print_message "error" "Failed to determine VSCode settings path"
    return 1
  fi
  
  # Backup existing settings
  if [ -f "$settings_file" ]; then
    backup_extension_config "$settings_file"
  fi
  
  if [ "$DRY_RUN" = true ]; then
    print_message "dryrun" "Would configure GitHub Copilot settings in $settings_file"
    return 0
  else
    # Check if settings file exists
    if [ ! -f "$settings_file" ]; then
      # Create a new settings file with empty JSON
      echo "{}" > "$settings_file"
    fi
    
    # Read current settings
    local current_settings=$(cat "$settings_file")
    
    # Ensure jq is available for JSON manipulation
    if ! command -v jq >/dev/null 2>&1; then
      print_message "error" "jq is not installed but is required for configuration. Please ensure Homebrew and jq are properly installed."
      return 1
    fi
    
    # Create a temporary file
    local temp_file=$(mktemp)
    
    # Use jq to update Copilot settings
    echo "$current_settings" | jq '.["github.copilot.enable"] = {"*": true} |
                               .["github.copilot.editor.enableAutoCompletions"] = true |
                               .["github.copilot.chat.enabled"] = true |
                               .["github.copilot.advanced"] = {"internal.debug": false}' > "$temp_file"
    
    # Replace the original file
    execute_command "mv \"$temp_file\" \"$settings_file\""
    
    print_message "success" "GitHub Copilot extensions configured successfully"
    return 0
  fi
}

# Main function for AI extensions setup
setup_ai_extensions() {
  print_message "info" "Phase 6: Configuring AI extensions"
  
  # Make sure VSCode is closed before configuration
  ensure_vscode_closed
  
  print_message "info" "Checking and configuring Kodu AI..."
  if ! configure_kodu; then
    print_message "warning" "Failed to configure Kodu AI, but continuing with setup"
  fi
  
  print_message "info" "Checking and configuring Cline..."
  if ! configure_cline; then
    print_message "warning" "Failed to configure Cline, but continuing with setup"
  fi
  
  print_message "info" "Checking and configuring Roocode..."
  if ! configure_roocode; then
    print_message "warning" "Failed to configure Roocode, but continuing with setup"
  fi
  
  print_message "info" "Checking and configuring GitHub Copilot..."
  if ! configure_copilot; then
    print_message "warning" "Failed to configure GitHub Copilot, but continuing with setup"
  fi
  
  print_message "success" "Phase 6: AI extensions configuration completed"
  return 0
}

# Phase 7: MCP Symlink Setup
setup_mcp_symlink() {
  print_message "info" "Phase 7: Setting up MCP symlinks"
  
  # Define source and target paths
  local cline_mcp_settings="$HOME/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json"
  local roocode_mcp_settings="$HOME/Library/Application Support/Code/User/globalStorage/rooveterinaryinc.roo-cline/settings/mcp_settings.json"
  
  # Create parent directories if they don't exist
  if [ "$DRY_RUN" = true ]; then
    print_message "dryrun" "Would ensure MCP settings directories exist"
    print_message "dryrun" "Would create symlink from $cline_mcp_settings to $roocode_mcp_settings"
  else
    # Ensure parent directories exist
    ensure_directory_exists "$(dirname "$cline_mcp_settings")"
    ensure_directory_exists "$(dirname "$roocode_mcp_settings")"
    
    # Check if source file exists
    if [ ! -f "$cline_mcp_settings" ]; then
      print_message "info" "Cline MCP settings file does not exist, creating it with default content"
      
      # Create a default MCP settings file with common MCP servers
      local default_mcp_content='{
  "version": 1,
  "servers": []
}'
      echo "$default_mcp_content" > "$cline_mcp_settings"
    else
      print_message "info" "Using existing Cline MCP settings from $cline_mcp_settings"
    fi
    
    # Create the symlink
    if [ -f "$roocode_mcp_settings" ] || [ -L "$roocode_mcp_settings" ]; then
      print_message "info" "Removing existing Roocode MCP settings file/symlink"
      rm -f "$roocode_mcp_settings"
    fi
    
    print_message "info" "Creating symlink from Cline to Roocode MCP settings"
    ln -sf "$cline_mcp_settings" "$roocode_mcp_settings"
    
    if [ $? -eq 0 ]; then
      print_message "success" "MCP symlink created successfully"
    else
      print_message "error" "Failed to create MCP symlink"
    fi
  fi
  
  print_message "success" "Phase 7: MCP symlink setup completed"
  return 0
}

# Check if Xcode Command Line Tools are installed
# Set up AI workspace directory, symlink and open it
setup_ai_workspace() {
  print_message "info" "Setting up AI workspace directory and symlink"
  
  # Define workspace directory
  local ai_workspace_dir="$HOME/projects/ai-workspace"
  
  # Create the directory if it doesn't exist
  if [ ! -d "$ai_workspace_dir" ]; then
    print_message "info" "Creating AI workspace directory at $ai_workspace_dir"
    
    if [ "$DRY_RUN" = true ]; then
      print_message "dryrun" "Would create directory: $ai_workspace_dir"
    else
      execute_command "mkdir -p \"$ai_workspace_dir\""
      if [ $? -ne 0 ]; then
        print_message "error" "Failed to create AI workspace directory"
        return 1
      fi
    fi
  else
    print_message "info" "AI workspace directory already exists at $ai_workspace_dir"
  fi
  
  # Create the symlink to the AI keys file
  local target_symlink="$ai_workspace_dir/ai-keys.json"
  
  if [ -L "$target_symlink" ]; then
    print_message "info" "Symlink already exists at $target_symlink, updating it"
    if [ "$DRY_RUN" = true ]; then
      print_message "dryrun" "Would remove existing symlink and create new one"
    else
      rm "$target_symlink"
    fi
  fi
  
  if [ "$DRY_RUN" = true ]; then
    print_message "dryrun" "Would create symlink from $API_KEYS_FILE to $target_symlink"
  else
    execute_command "ln -sf \"$API_KEYS_FILE\" \"$target_symlink\""
    if [ $? -ne 0 ]; then
      print_message "error" "Failed to create symlink to AI keys file"
      return 1
    fi
    print_message "success" "Created symlink to AI keys file at $target_symlink"
  fi
  
  # Open the AI workspace directory and file in VSCode
  if [ "$DRY_RUN" = true ]; then
    print_message "dryrun" "Would open AI workspace directory and keys file in VSCode: $ai_workspace_dir"
  else
    # Check if VSCode is available
    if command -v code >/dev/null 2>&1; then
      print_message "info" "Opening AI workspace directory in VSCode"
      execute_command "code \"$ai_workspace_dir\""
      
      print_message "info" "Opening AI keys file in VSCode"
      execute_command "code \"$target_symlink\""
    else
      print_message "warning" "VSCode 'code' command not found in PATH"
      print_message "info" "Please manually open $ai_workspace_dir and $target_symlink in VSCode"
      
      # Fall back to regular file browser as backup
      if command -v open >/dev/null 2>&1; then
        # macOS
        print_message "info" "Falling back to opening directory in file browser"
        execute_command "open \"$ai_workspace_dir\""
      elif command -v xdg-open >/dev/null 2>&1; then
        # Linux with xdg-open
        print_message "info" "Falling back to opening directory in file browser"
        execute_command "xdg-open \"$ai_workspace_dir\""
      fi
    fi
  fi
  
  print_message "success" "AI workspace setup completed"
  return 0
}

check_command_line_tools() {
  print_message "info" "Checking for Xcode Command Line Tools..."
  
  # Try to run a command that requires the CLI tools
  if xcode-select -p &>/dev/null; then
    print_message "success" "Xcode Command Line Tools are already installed"
    return 0
  else
    print_message "warning" "Xcode Command Line Tools are not installed"
    
    if [ "$DRY_RUN" = true ]; then
      print_message "dryrun" "Would run: xcode-select --install"
      return 1
    else
      print_message "info" "Installing Xcode Command Line Tools..."
      print_message "info" "A dialog will appear asking to install the Command Line Tools."
      print_message "info" "Please click 'Install' to continue and run this script again after installation completes."
      
      xcode-select --install
      
      print_message "info" "Setup will exit now. Please run the script again after Command Line Tools installation completes."
      exit 0
    fi
  fi
}

# Main function
main() {
  parse_arguments "$@"
  
  print_message "info" "Starting AI setup..."
  
  # Check for Command Line Tools before anything else
  if ! check_command_line_tools; then
    print_message "info" "Setup cannot continue without Xcode Command Line Tools."
    exit 1
  fi
  
  # Phase 1: API Key Handling & Script Initialization
  check_hostname
  setup_api_keys
  
  # Placeholder calls for future phases
  setup_homebrew_and_packages
  setup_zsh
  setup_node
  setup_vscode
  setup_ai_extensions
  # setup_mcp_symlink # Temporarily disabled. Do not remove from here.
  
  # Setup AI workspace directory and symlink to AI keys file
  setup_ai_workspace
  
  print_message "success" "Setup completed successfully!"
}

# Add note about execution permissions
print_message "info" "NOTE: When deploying this script, make it executable with:"
print_message "info" "chmod +x setup.sh"

# Execute main function with all arguments
main "$@"
