# GeoNeo Deployment Guide

GeoNeo is built on top of the powerful Traccar GPS tracking engine, offering a modernized, business-focused web frontend. This guide explains how to build and run the entire operational stack (Database, Traccar Engine, and Web Frontend) using **Podman Quadlets**.

## Prerequisites

1.  **Podman**: Ensure Podman is installed on your Linux machine (minimum version 4.4+ is recommended for Quadlet support).
2.  **Systemd**: Quadlets rely on `systemd` to manage container lifecycles.

## Architecture overview

The deployment consists of three main components running in the `geoneo.network`:
1.  **geoneo-db**: A MySQL container for storing users, devices, and positional data.
2.  **geoneo-engine**: The official Traccar Java backend which handles device protocols and API logic.
3.  **geoneo-web**: Our custom GeoNeo React frontend, served via NGINX. NGINX also acts as a reverse proxy for all `/api/` traffic, routing it directly to the engine.

## Step 1: Build the GeoNeo Frontend Image

Before deploying the containers, build the custom GeoNeo React application into a local container image using the provided `Dockerfile`.

Run this from the root of the repository:

```bash
podman build -t localhost/geoneo-web:latest .
```

## Step 2: Configure the Traccar Engine

For the Traccar engine to connect to our MySQL database, you need a `traccar.xml` configuration file. Create a directory on your host (e.g., `/etc/geoneo/`) and place your `traccar.xml` there. Ensure it has the correct MySQL JDBC connection string pointing to `geoneo-db:3306`.

*Note: Update `deploy/quadlet/geoneo-engine.container` to uncomment and map your `traccar.xml` volume if you want a custom configuration.*

## Step 3: Configure Traefik Proxy (Optional)

If you are using a Traefik instance in your production environment to proxy applications, the `geoneo-web.container` is pre-configured with Traefik labels.

Before deploying, edit `deploy/quadlet/geoneo-web.container` and adjust the Traefik rules to match your production domain:

```ini
Label=traefik.http.routers.geoneo.rule=Host(`your-production-domain.com`)
```

Ensure your Traefik container shares a network with the GeoNeo Podman containers or is capable of routing traffic to the internal port 80 exposed by the GeoNeo Web container.

## Step 4: Deploy using Quadlets

Quadlet files simplify deploying podman containers as systemd services.

1.  Copy all the Quadlet configuration files from `deploy/quadlet` to the systemd directory.
    *   For **rootful** containers: `/etc/containers/systemd/`
    *   For **rootless** containers (recommended): `~/.config/containers/systemd/`

    ```bash
    mkdir -p ~/.config/containers/systemd/
    cp deploy/quadlet/* ~/.config/containers/systemd/
    ```

2.  Reload the systemd daemon so it reads the new Quadlet files and generates the necessary service units.

    ```bash
    systemctl --user daemon-reload
    ```

3.  Start the services. Quadlet files map directly to systemd services with a `.service` extension.

    ```bash
    # Start the Database
    systemctl --user start geoneo-db.service

    # Start the Backend Engine
    systemctl --user start geoneo-engine.service

    # Start the Frontend App
    systemctl --user start geoneo-web.service
    ```

4.  Enable them to start automatically on boot:

    ```bash
    systemctl --user enable geoneo-db.service geoneo-engine.service geoneo-web.service
    ```

## Step 5: Initialize Default Users

Once the services are up and running, you need to configure the database with default mockup users. We provide a bash script that interacts with the Traccar API to update the default admin and create a mock user.

Run the initialization script:

```bash
./deploy/init-users.sh
```

**Default Credentials:**
- **Admin**: `admin@geoneo.com` / `admin1234`
- **User**: `user@geoneo.com` / `user1234`

## Step 6: Access the Application

Open your web browser and navigate to the domain you configured in your Traefik labels (or `http://localhost` if you exposed the port manually).

You should see the modern GeoNeo public homepage. Clicking "Sign In" will take you to the login screen, and successfully logging in with the credentials above will take you to the interactive tracking dashboard and billing features.

## Roadmap & Future Development Checklist

To fully realize the GeoNeo vision as a complete, autonomous business SaaS, several features remain to be developed or completed. Since this repository focuses on the frontend, many of these require backend changes in the Traccar Engine or a supplementary microservice.

### 1. Backend & Billing Engine (The Core Missing Piece)
- [ ] **Subscription Database Models:** Create tables to store subscription tiers (e.g., Fleet Pro, Individual), billing cycles, and payment histories.
- [ ] **Local Payment Gateway Integration:** Implement backend API controllers to process and verify transactions via MTN Mobile Money, Orange Money, and Visa/Mastercard.
- [ ] **Access Control & Restriction Logic:** Update the Traccar authorization middleware so that users with expired or unpaid subscriptions are restricted from adding new assets or accessing live maps.
- [ ] **Automated Invoicing:** Generate and email monthly PDF invoices to enterprise clients.

### 2. Frontend & UX Enhancements
- [ ] **Complete Bilingual Support:** Translate all new marketing copy and dashboard additions into French. Currently, the framework is in place, but exact UI strings need translation keys.
- [ ] **Dynamic Billing Dashboard:** Connect the `BillingPage.jsx` mockups to the new backend endpoints to display real subscription status, active devices count, and actual payment history.
- [ ] **Advanced Fleet Reporting:** Build customized, exportable reports (Excel/PDF) specifically tailored to the logistics and container tracking market in Central Africa.
- [ ] **Custom Onboarding Flow:** Create a guided tutorial for new users who sign up via the public marketing site to help them connect their first GPS tracker.

### 3. Infrastructure & Operations
- [ ] **Automated SSL/TLS (Let's Encrypt):** Configure Traefik to automatically fetch and renew HTTPS certificates for the production domain.
- [ ] **CI/CD Pipeline:** Set up GitHub Actions or GitLab CI to automatically run `npm run build`, create the Docker image, and push it to a registry upon code commits.
- [ ] **Database Backups:** Implement automated nightly backups for the MySQL `geoneo-db` volume to AWS S3 or a secondary storage instance.
