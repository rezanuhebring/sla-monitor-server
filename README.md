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