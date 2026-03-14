# IggyCloud eShop Resources - Performance Engineering & Deployment

This directory contains the infrastructure, deployment, and performance testing suite for the IggyCloud eShop project. It serves as the technical core for our experiments in scaling, database optimization, and high-load API engineering.

## IggyCloud Context

These resources accompany the [IggyCloud YouTube channel](https://www.youtube.com/@IggyCloud) and [IggyCloud.com](https://iggycloud.com). Here, we test various architectural solutions to maximize RPS (Requests Per Second) and Virtual Users (VUs).

Key focus areas:
- **Horizontal Scaling**: Testing how the system behaves under horizontal load.
- **Resource Constraints**: Mimicking Azure B1 tiers (1 vCPU, 1GB RAM) to enforce strict engineering boundaries.
- **Database Mastery**: Deep dives into Postgres, pgvector, replication, and pgpool.

The empirical results of our experiments can be found in the [evidence](./evidence) folder.

## Quick Start

### Deploy to Kubernetes (Terraform) - RECOMMENDED
We use Terraform for predictable, stable deployments. Unlike generated manifests, this approach ensures stable credentials and consistent resource boundaries.

```bash
cd terraform
terraform init
terraform apply
```

### Reddeploying After Code Changes
If you modify the Catalog API source code, use the automation script to build and rollout the new version:
```batch
cd terraform
redeploy-catalog-api.bat
```

### Run Performance Tests (k6)

#### Windows (Interactive Menu)
```batch
cd k6
run-test.bat
```

#### Linux/Unix
```bash
cd k6/
./deploy.sh
./run-test.sh catalog-api-open-model-read-test.js
```

## Accessing Services (Localhost)
- **Catalog API**: [http://localhost:8080/health](http://localhost:8080/health)
- **Grafana**: [http://localhost:30300](http://localhost:30300) (admin/admin123)
- **Prometheus**: [http://localhost:30090](http://localhost:30090)
- **Postgres Hero**: [http://localhost:30050](http://localhost:30050)

## Repository Structure
- `terraform/`: Consolidated IaC for the core solution (API, DB, EventBus).
- `k6/`: Load testing suite with arrival-rate and fixed-VU models.
- `evidence/`: Historical data and screenshots of performance breakthroughs.
- `observability/`: Configurations for the LGTM stack (Loki, Grafana, Tempo, Mimir/Prometheus).
- `pgpool/` & `scripts/`: Advanced database tuning and replication resources.

## Prerequisites
- Docker Desktop with Kubernetes enabled.
- .NET 9 SDK.
- Terraform CLI.
- kubectl configured for `docker-desktop`.
