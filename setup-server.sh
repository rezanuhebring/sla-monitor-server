#!/bin/bash
# ==============================================================================
# SLA Monitor - Central Server Setup Script (with Dependency Installation)
# ==============================================================================

# --- Colors for Output ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Pre-run Check ---
# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run this script with sudo or as root.${NC}"
  echo "Usage: sudo ./setup-server.sh"
  exit 1
fi

# --- Helper Functions ---
install_dependency() {
    local dep_name=$1
    echo -e "${YELLOW}Dependency '$dep_name' not found. Attempting installation...${NC}"
    
    # Update package list before first install
    if [ "$first_install" = true ]; then
        echo "Updating package lists..."
        apt-get update -y > /dev/null
        first_install=false
    fi

    case $dep_name in
        git)
            apt-get install -y git
            ;;
        docker)
            apt-get install -y apt-transport-https ca-certificates curl software-properties-common
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            apt-get update -y > /dev/null
            apt-get install -y docker-ce docker-ce-cli containerd.io
            # Add current user to docker group
            usermod -aG docker ${SUDO_USER:-$(whoami)}
            echo -e "${YELLOW}NOTE: You may need to log out and log back in for Docker group changes to take effect.${NC}"
            ;;
        docker-compose)
            # Install Docker Compose v2 (recommended)
            apt-get install -y docker-compose-plugin
            ;;
    esac

    if ! command -v $dep_name &> /dev/null; then
        echo -e "${RED}Failed to install '$dep_name'. Please install it manually and re-run the script.${NC}"
        exit 1
    fi
    echo -e "${GREEN}'$dep_name' installed successfully.${NC}"
}

echo -e "${GREEN}Starting SLA Monitor Server Setup...${NC}\n"

# 1. Check for and install required dependencies
echo "Step 1: Checking for dependencies..."
first_install=true
dependencies=("git" "docker" "docker-compose")
for dep in "${dependencies[@]}"; do
    if ! command -v $dep &> /dev/null; then
        install_dependency $dep
    else
        echo -e "Dependency '$dep' is already installed."
    fi
done
echo -e "${GREEN}All dependencies are present.${NC}\n"

# --- The rest of the script is the same as before ---

# 2. Set up the environment configuration
echo "Step 2: Setting up configuration..."
if [ -f ".env" ]; then
    echo -e "${YELLOW}'.env' file already exists. Skipping creation.${NC}"
else
    echo "Creating .env file from .env.example..."
    cp .env.example .env
    # Set correct ownership for the folder
    chown -R ${SUDO_USER:-$(whoami)}:${SUDO_USER:-$(whoami)} .
    echo -e "${GREEN}.env file created. You can edit this file later to change your secrets.${NC}"
fi
echo ""

# 3. Launch the Docker containers
echo "Step 3: Building and launching Docker containers..."
echo "This may take a few minutes on the first run..."
docker-compose up -d

if [ $? -ne 0 ]; then
    echo -e "\n${RED}Docker Compose failed to start. Please check the output for errors.${NC}"
    exit 1
fi

echo -e "\n${GREEN}=====================================================${NC}"
echo -e "${GREEN}  SLA Monitor Server Setup Complete!               ${NC}"
echo -e "${GREEN}=====================================================${NC}\n"

# 4. Display status and next steps
echo "Verifying services are running..."
docker-compose ps
SERVER_IP=$(hostname -I | awk '{print $1}')
echo -e "\n${YELLOW}--- Your Services ---${NC}"
echo -e "API Server is running at:      ${GREEN}http://${SERVER_IP}:8000${NC}"
echo -e "Grafana Dashboard is at:     ${GREEN}http://${SERVER_IP}:3000${NC}"
echo -e "\n${YELLOW}--- Next Steps ---${NC}"
echo "1. Configure the Agent's 'config.ini' to point to the API URL: ${GREEN}api_url = http://${SERVER_IP}:8000/api/submit${NC}"
echo ""