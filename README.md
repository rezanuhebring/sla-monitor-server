# SLA Monitor - Central Server

This repository contains the central server components for a distributed internet quality monitor. It uses Docker Compose to run an API, a time-series database (InfluxDB), and a visualization dashboard (Grafana).

## Quick Setup on a Linux Server

1.  **Prerequisites:** Ensure `git`, `docker`, and `docker-compose` are installed.
2.  Clone this repository:
    ```bash
    git clone https://github.com/your-username/sla-monitor-server.git
    cd sla-monitor-server
    ```
3.  Make the setup script executable:
    ```bash
    chmod +x setup-server.sh
    ```
4.  Run the setup script:
    ```bash
    ./setup-server.sh
    ```
The script will configure and launch all necessary services.

-   **Choose `n` (HTTP Setup):**
    - The script will perform a simple setup, exposing the services on their respective ports.
    - This is ideal for quick local testing or if the server is behind a trusted firewall.
    - The script will finish by displaying the IP-based URLs for each service (e.g., `http://<YOUR_IP>:3000`).

-   **Choose `y` (HTTPS Setup):**
    - The script will proceed to ask for more information.
    - **Domain Name:** You will be prompted to enter your base domain (e.g., `example.com`).
    - **Email Address:** You will be prompted for an email address for Let's Encrypt expiry notifications.
    - The script will then automatically configure Nginx, obtain SSL certificates, and set up secure access.
    - It will finish by displaying the secure `https://...` URLs for your services.

### Choice 2 (HTTPS Only): Confirm Domains

If you choose the HTTPS setup, the script will show you the subdomains it plans to configure (e.g., `grafana.example.com`, `api.example.com`) and ask for final confirmation before proceeding.

## Post-Installation

Once the script finishes, your monitoring server is live.

Your final and most important step is to **update the `config.ini` file of your monitoring agents** to point to the new API endpoint URL provided at the end of the script.

-   **For an HTTP setup, the URL will be:** `http://<YOUR_SERVER_IP>:8000/api/submit`
-   **For an HTTPS setup, the URL will be:** `https://api.yourdomain.com/api/submit`