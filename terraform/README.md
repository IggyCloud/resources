# Terraform Deployment for eShop

This directory contains a Terraform-based deployment solution for the eShop application, focusing on the `catalog-api` and its dependencies.

## Prerequisites

*   A local Kubernetes cluster (e.g., Docker Desktop with Kubernetes enabled).
*   `kubectl` configured to point to your local cluster.
*   Terraform installed.
*   Docker running.

## Deployment

1.  **Build the `catalog-api` image:**
    Open a PowerShell terminal and run the following command from the root of the repository:
    ```powershell
    ./resources/terraform/build-catalog-api.ps1
    ```

2.  **Initialize Terraform:**
    Navigate to the `resources/terraform` directory and run:
    ```bash
    terraform init
    ```

3.  **Apply the configuration:**
    ```bash
    terraform apply
    ```

This will deploy the following components to your Kubernetes cluster:

*   `catalog-db`: A PostgreSQL database.
*   `rabbitmq`: The event bus.
*   `otel-collector`: An OpenTelemetry collector.
*   `catalog-api`: The catalog API.

## Destruction

To remove all the deployed resources, run:

```bash
terraform destroy
```
