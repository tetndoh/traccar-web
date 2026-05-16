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

## Step 3: Deploy using Quadlets

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

## Step 4: Initialize Default Users

Once the services are up and running, you need to configure the database with default mockup users. We provide a bash script that interacts with the Traccar API to update the default admin and create a mock user.

Run the initialization script:

```bash
./deploy/init-users.sh
```

**Default Credentials:**
- **Admin**: `admin@geoneo.com` / `admin1234`
- **User**: `user@geoneo.com` / `user1234`

## Step 5: Access the Application

Open your web browser and navigate to:

`http://localhost:80` (or the IP address of your server).

You should see the modern GeoNeo public homepage. Clicking "Sign In" will take you to the login screen, and successfully logging in with the credentials above will take you to the interactive tracking dashboard and billing features.

## Future Development

To fully realize the GeoNeo vision (restricting devices based on payment, custom subscriptions), modifications to the Java code inside the `traccar` engine repository or a separate microservice will be required to handle payment gateway integrations (MTN MoMo, Orange Money) and API validations.
