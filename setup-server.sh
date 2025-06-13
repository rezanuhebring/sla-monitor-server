#!/bin/bash
# ==============================================================================
# SLA Monitor - Interactive Server Setup Script (HTTP or HTTPS)
# ==============================================================================

# --- Colors for Output ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Pre-run Check ---
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run this script with sudo or as root.${NC}"
  exit 1
fi

# ==============================================================================
# --- HTTPS Setup Function ---
# ==============================================================================
setup_https() {
    echo -e "\n${YELLOW}--- Starting HTTPS Setup ---${NC}"
    
    # 1. Gather User Input
    read -p "Enter your base domain name (e.g., my-monitor.com): " BASE_DOMAIN
    read -p "Enter your email for SSL notifications: " USER_EMAIL
    if [ -z "$BASE_DOMAIN" ] || [ -z "$USER_EMAIL" ]; then
        echo -e "${RED}Error: Domain and email cannot be empty for HTTPS setup.${NC}"; exit 1
    fi

    GRAFANA_DOMAIN="grafana.$BASE_DOMAIN"
    API_DOMAIN="api.$BASE_DOMAIN"
    INFLUX_DOMAIN="influx.$BASE_DOMAIN"

    echo -e "\nServices will be at: https://$GRAFANA_DOMAIN, https://$API_DOMAIN, https://$INFLUX_DOMAIN"
    read -p "Is this correct? (y/n): " -n 1 -r; echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then echo "Setup aborted."; exit 1; fi

    # 2. Generate Nginx Config
    echo -e "\nGenerating Nginx configuration..."
    if [ ! -d "nginx/conf" ]; then mkdir -p nginx/conf; fi
    sed -e "s/_GRAFANA_DOMAIN_/$GRAFANA_DOMAIN/g" -e "s/_API_DOMAIN_/$API_DOMAIN/g" -e "s/_INFLUX_DOMAIN_/$INFLUX_DOMAIN/g" \
        nginx/conf/default.conf.template > nginx/conf/default.conf

    # 3. Launch Services using the HTTPS compose file
    echo -e "\nLaunching Docker services with Nginx..."
    docker-compose -f docker-compose.https.yml up -d --force-recreate
    if [ $? -ne 0 ]; then echo -e "${RED}Docker Compose failed.${NC}"; exit 1; fi

    # 4. Obtain SSL Certificates
    echo -e "\nRequesting SSL certificates from Let's Encrypt..."
    docker-compose -f docker-compose.https.yml run --rm certbot certonly --webroot --webroot-path /var/www/certbot \
        --email $USER_EMAIL --agree-tos --no-eff-email \
        -d $GRAFANA_DOMAIN -d $API_DOMAIN -d $INFLUX_DOMAIN
    if [ $? -ne 0 ]; then echo -e "${RED}Certbot failed. Check your DNS records and firewall.${NC}"; exit 1; fi

    # 5. Final Restart
    echo -e "\nRestarting Nginx to apply SSL..."
    docker-compose -f docker-compose.https.yml restart nginx

    # 6. Final Instructions
    echo -e "\n${GREEN}--- HTTPS Setup Complete! ---${NC}"
    echo "Grafana Dashboard: ${GREEN}https://$GRAFANA_DOMAIN${NC}"
    echo "API Endpoint:      ${GREEN}https://$API_DOMAIN/api/submit${NC}"
    echo "InfluxDB UI:       ${GREEN}https://$INFLUX_DOMAIN${NC}"
    echo -e "\n${YELLOW}IMPORTANT: Update your agent's 'config.ini' with the new API URL.${NC}"
}

# ==============================================================================
# --- HTTP Setup Function ---
# ==============================================================================
setup_http() {
    echo -e "\n${YELLOW}--- Starting HTTP-Only Setup ---${NC}"
    
    # Launch Services using the HTTP compose file
    docker-compose -f docker-compose.http.yml up -d
    if [ $? -ne 0 ]; then echo -e "${RED}Docker Compose failed.${NC}"; exit 1; fi

    SERVER_IP=$(hostname -I | awk '{print $1}')

    # Final Instructions
    echo -e "\n${GREEN}--- HTTP Setup Complete! ---${NC}"
    echo "Grafana Dashboard: ${GREEN}http://$SERVER_IP:3000${NC}"
    echo "API Endpoint:      ${GREEN}http://$SERVER_IP:8000/api/submit${NC}"
    echo "InfluxDB UI:       ${GREEN}http://$SERVER_IP:8086${NC}"
    echo -e "\n${YELLOW}IMPORTANT: Update your agent's 'config.ini' with the API URL.${NC}"
}

# ==============================================================================
# --- Main Script Logic ---
# ==============================================================================
echo -e "${GREEN}--- Welcome to the SLA Monitor Server Setup ---${NC}"

# Stop any existing containers to prevent conflicts
echo "Stopping any existing monitor containers..."
docker-compose -f docker-compose.https.yml down 2>/dev/null
docker-compose -f docker-compose.http.yml down 2>/dev/null

# Set up .env file
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo -e "${GREEN}.env file created.${NC}"
fi

# Ask the user for setup type
echo ""
read -p "Do you want to configure secure HTTPS access with a domain name? (Requires a domain pointed at this server's IP) (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # User chose HTTPS
    setup_https
else
    # User chose HTTP
    setup_http
fi

echo -e "\n${GREEN}Setup script finished.${NC}"