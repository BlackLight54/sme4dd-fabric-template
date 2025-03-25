#!/bin/bash
set -euo pipefail

echo "========================================"
echo "Starting prerequisites installation..."
echo "========================================"

# --- General Utilities (curl, jq) ---
echo "Checking for curl..."
if ! command -v curl &>/dev/null; then
    echo "curl not found. Updating package lists and installing curl..."
    sudo apt-get update || { echo "apt-get update failed"; exit 1; }
    sudo apt-get install -y curl || { echo "Failed to install curl"; exit 1; }
else
    echo "curl is already installed."
fi

echo "Checking for jq..."
if ! command -v jq &>/dev/null; then
    echo "jq not found. Installing jq..."
    sudo apt-get install -y jq || { echo "Failed to install jq"; exit 1; }
else
    echo "jq is already installed."
fi

# --- Docker ---
echo "Checking for Docker..."
if ! command -v docker &>/dev/null; then
    echo "Docker not found. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh || { echo "Failed to download Docker installation script"; exit 1; }
    sudo sh ./get-docker.sh || { echo "Docker installation failed"; exit 1; }
    rm get-docker.sh


echo "Configuring Docker rootless mode..."
# The groupadd command may fail if the group already exists. In that case, continue.
sudo groupadd docker || echo "Group 'docker' already exists. Continuing..."
sudo usermod -aG docker $USER || { echo "Failed to add user to docker group"; exit 1; }
sudo chmod 666 /var/run/docker.sock
echo "Note: For group changes to take effect, please log out and log back in."

echo "Testing Docker installation..."
docker run hello-world || { echo "Docker hello-world test failed"; exit 1; }

else
    echo "Docker is already installed with rootless mode."
fi

# --- Node Version Manager (NVM) ---
echo "Checking for NVM..."
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    echo "NVM is already installed."
    # Source NVM to make its functions available in this session.
    . "$NVM_DIR/nvm.sh"
else
    echo "NVM not found. Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash || { echo "Failed to install NVM"; exit 1; }
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        . "$NVM_DIR/nvm.sh"
    else
        echo "NVM script not found after installation. Please log out and log back in."
        exit 1
    fi
fi

echo "Testing NVM installation..."
nvm -v || { echo "NVM test failed"; exit 1; }

# --- Node.JS ---
echo "Checking for Node.js..."
if command -v node &>/dev/null; then
    echo "Node.js is already installed."
else
    echo "Node.js not found. Installing Node.js v20 using NVM..."
    nvm install v20 || { echo "Node.js installation failed"; exit 1; }
fi

echo "Testing Node.js installation..."
node -v || { echo "Node.js test failed"; exit 1; }
# --- Zip ---
echo "Checking for zip..."
if ! command -v zip &>/dev/null; then
    echo "zip not found. Installing zip..."
    sudo apt-get install -y zip || { echo "Failed to install zip"; exit 1; }
else
    echo "zip is already installed."
fi
# --- SDKMAN! ---
set +u
echo "Checking for SDKMAN!"
if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    echo "SDKMAN! is already installed."
    . "$HOME/.sdkman/bin/sdkman-init.sh"
else
    echo "SDKMAN! not found. Installing SDKMAN!..."
    curl -s "https://get.sdkman.io" | bash || { echo "Failed to install SDKMAN!"; exit 1; }
    if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
        . "$HOME/.sdkman/bin/sdkman-init.sh"
    else
        echo "SDKMAN initialization script not found after installation. Please log out and log back in."
        exit 1
    fi
fi

echo "Testing SDKMAN! installation..."
sdk version || { echo "SDKMAN test failed. You may need to log out and then log in."; exit 1; }

# --- Java JDK ---
echo "Checking for Java JDK..."
if command -v javac &>/dev/null; then
    echo "Java JDK is already installed."
else
    echo "Java JDK not found. Installing Eclipse Temurin 11.0.23 via SDKMAN!..."
    sdk install java 11.0.23-tem || { echo "Java JDK installation failed"; exit 1; }
fi

echo "Testing Java JDK installation..."
javac -version || { echo "Java JDK test failed"; exit 1; }

# --- Fablo ---
echo "Checking for Fablo..."
if [ -x "./fablo" ]; then
    echo "Fablo is already installed locally."
else
    echo "Fablo not found. Installing Fablo..."
    curl -Lf https://github.com/hyperledger-labs/fablo/releases/download/2.2.0/fablo.sh -o ./fablo || { echo "Failed to download Fablo"; exit 1; }
    chmod +x ./fablo || { echo "Failed to set executable permission on Fablo"; exit 1; }
fi

echo "Testing Fablo installation..."
./fablo version || { echo "Fablo test failed"; exit 1; }

echo "Warming up Fablo (pre-pulling Fabric Docker images)..."
mkdir fablo-test || { echo "Failed to create fablo-test directory"; exit 1; }
cd fablo-test || { echo "Failed to change directory to fablo-test"; exit 1; }
# Use the Fablo script from the parent directory
../fablo init node rest || { echo "Fablo init failed"; exit 1; }
../fablo up || { echo "Fablo up failed"; exit 1; }
../fablo prune || { echo "Fablo prune failed"; exit 1; }
cd .. || { echo "Failed to change back to parent directory"; exit 1; }
rm -rf fablo-test || { echo "Failed to remove fablo-test directory"; exit 1; }

echo "========================================"
echo "All prerequisites have been installed successfully."
echo "========================================"
