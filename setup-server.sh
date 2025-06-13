#!/bin/bash
# ==============================================================================
# SLA Monitor - Central Server Setup Script
# ==============================================================================
# This script automates the deployment of the central monitoring server using Docker.
# ==============================================================================

# --- Configuration ---
# This will be automatically set to the repository it's run from.
REPO_URL="https://github.com/$(git config --get remote.origin.url | sed 's/https:\/\/github.com\///' | sed 's/\.git$//').git"
PROJECT_DIR="." # Install in the current directory

# --- Colors for Output ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Helper Functions ---
check_dependency() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}Error: Dependency '$1' not found.${NC}"
        echo -e "${YELLOW}Please install it and run this script again.${NC}"
        if [ "$1" == "docker" ]; then
            echo "For Docker installation, please visit: https://docs.docker.com/engine/install/"
        fi
        exit 1
    fi
}

echo -e "${GREEN}Starting SLA Monitor Server Setup...${NC}\n"

# 1. Check for required dependencies
echo "Step 1: Checking for dependencies (git, docker, docker-compose)..."
check_dependency "git"
check_dependency "docker"
check_dependency "docker-compose"
echo -e "${GREEN}All dependencies found.${NC}\n"

# 2. Set up the environment configuration
echo "Step 2: Setting up configuration..."
if [ -f ".env" ]; then
    echo -e "${YELLOW}'.env' file already exists. Skipping creation.${NC}"
else
    echo "Creating .env file from .env.example..."
    cp .env.example .env
    echo -e "${GREEN}.env file created. You can edit this file later to change your secrets.${NC}"
fi
echo ""

# 3. Launch the Docker containers
echo "Step 3: Building and launching Docker containers..."
echo "This may take a few minutes on the first run..."
docker-compose up -d

if [ $? -ne 0 ]; then
    echo -e "\n${RED}Docker Compose failed to start. Please check the output for errors.${NC}"
    echo -e "${YELLOW}Try running 'docker-compose up' manually to see detailed logs.${NC}"
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
echo -e "Grafana Dashboard is at:     ${GREEN}http://${SERVER_IP}:3000${NC} (Login: admin/admin)"
echo -e "InfluxDB UI is at:           ${GREEN}http://${SERVER_IP}:8086${NC}\n"

echo -e "${YELLOW}--- Next Steps ---${NC}"
echo "1. Configure the Agent's 'config.ini' to point to the API URL:"
echo -e "   ${GREEN}api_url = http://${SERVER_IP}:8000/api/submit${NC}"
echo "2. Set up and run the agent script on your client machines."
echo "3. Access Grafana to build your dashboards."
echo ""