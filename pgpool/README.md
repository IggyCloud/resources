# Pgpool-II Kubernetes Deployment Example

This directory contains Kubernetes manifests to deploy `pgpool-II` with read/write routing and a browser UI (`pgAdmin`) for day-to-day database operations through the Pgpool endpoint.

## Overview

The goal of this setup is to have your application connect to a single database endpoint (the `pgpool-II` service) and have `pgpool-II` automatically route queries based on their type:
- `SELECT` queries go to a read replica.
- `INSERT`, `UPDATE`, `DELETE` queries go to the primary database.

## Manifests

1.  **`pgpool-configmap.yaml`**: This file contains the configuration for `pgpool-II`.
    - It defines the `pgpool.conf` file, which is the main configuration.
    - Key settings enabled here include `load_balance_mode` and `read_write_splitting_mode`.
    - **You must edit this file** to set the correct hostnames/services for your primary (`backend_hostname0`) and replica (`backend_hostname1`) PostgreSQL instances.
    - It also contains placeholders for authentication. In a real environment, you should use Kubernetes Secrets for passwords.

2.  **`pgpool-deployment.yaml`**: This manifest runs the `pgpool-II` software in a pod.
    - It uses the official `pgpool/pgpool-ii` Docker image.
    - It mounts the `pgpool-configmap` as a volume to configure the service.

3.  **`pgpool-service.yaml`**: This exposes the `pgpool-II` deployment as a stable network service within the cluster.
    - Your application will use the name of this service (`pgpool-service`) as the database host in its connection string.

4.  **`pgadmin-secret.yaml`**: Credentials for pgAdmin login.
    - Change the default values before deploying.

5.  **`pgadmin-configmap.yaml`**: Pre-registers a pgAdmin server that points to `pgpool-service:5432`.

6.  **`pgadmin-pvc.yaml`**: Persistent volume claim for pgAdmin metadata.

7.  **`pgadmin-deployment.yaml`** and **`pgadmin-service.yaml`**:
    - Deploy pgAdmin.
    - Expose pgAdmin at NodePort `30307`.

## How to Use

1.  **Customize the ConfigMap**: Edit `pgpool-configmap.yaml` to match your database hostnames and authentication setup.
2.  **Set pgAdmin credentials**: Edit `pgadmin-secret.yaml`.
3.  **Deploy**: Apply the manifests to your Kubernetes cluster:
    ```bash
    kubectl apply -f pgpool-configmap.yaml
    kubectl apply -f pgpool-deployment.yaml
    kubectl apply -f pgpool-service.yaml
    kubectl apply -f pgadmin-secret.yaml
    kubectl apply -f pgadmin-configmap.yaml
    kubectl apply -f pgadmin-pvc.yaml
    kubectl apply -f pgadmin-deployment.yaml
    kubectl apply -f pgadmin-service.yaml
    ```
4.  **Open pgAdmin UI**:
    - URL: `http://localhost:30307`
    - Login with `PGADMIN_DEFAULT_EMAIL` and `PGADMIN_DEFAULT_PASSWORD` from `pgadmin-secret.yaml`.
    - The server entry `pgpool-service` is pre-created and routes through Pgpool.

5.  **Update Your Application**: Change the connection string in your `catalog-api`'s `appsettings.json` to point to the `pgpool-service`.

    **Before:**
    `"catalogdb": "Host=your-postgres-server;..."`

    **After:**
    `"catalogdb": "Host=pgpool-service;Port=5432;..."`

This moves the read/write splitting logic out of the application and into infrastructure while giving you a UI for database operations.

## Important Notes

- pgAdmin manages PostgreSQL objects and queries via the Pgpool endpoint; it does not replace Pgpool PCP administration commands.
- For production, move pgAdmin credentials and database passwords into Kubernetes Secrets managed by your secret workflow.
