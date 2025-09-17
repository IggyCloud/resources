# IggyCloud eShop Resources

Kubernetes deployment and performance testing resources for .NET eShop.

## Quick Start

### Deploy to Kubernetes
```bash
cd aspir8/
./Aspir8.sh
```

### Run Performance Tests
```bash
cd k6/
./deploy.sh
./run-test.sh catalog-api-open-model-test.js
```

### Access Services
- eShop: http://localhost:30509
- Grafana: http://localhost:30300 (admin/admin123)
- Prometheus: http://localhost:30090

## Structure

- `aspir8/` - Aspirate deployment scripts
- `k6/` - Load testing suite with Grafana monitoring
- `observability/` - Prometheus & Grafana configurations
- `k8s/` - Kubernetes manifests

## Prerequisites

- Docker Desktop with Kubernetes
- .NET 9 SDK
- kubectl configured for docker-desktop