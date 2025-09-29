# IggyCloud eShop Resources

Kubernetes deployment and performance testing resources for .NET eShop.

## Quick Start

### Deploy to Kubernetes
```bash
cd aspir8/
./Aspir8.sh
```

### Run Performance Tests

#### Windows (Interactive)
```batch
cd k6
run-test.bat
```

#### Linux/Unix (Command line)
```bash
cd k6/
./deploy.sh
./run-test.sh catalog-api-open-model-read-test.js
```

#### Available Tests
- **Catalog API Open Model Read Test** - High-load read operations (open loop)
- **Catalog API Closed Model Read Test** - Controlled read operations (closed loop)
- **Catalog API Closed Model Write Test** - CRUD operations testing (POST/PUT/DELETE)

### Access Services
- eShop: http://localhost:30509
- Grafana: http://localhost:30300 (admin/admin123)
- Prometheus: http://localhost:30090

## K6 Performance Testing

### Test Naming Convention

All k6 test files follow this naming pattern:
```
{service}-{model}-{operation}-test.js
```

Where:
- **service**: API being tested (e.g., `catalog-api`, `order-api`)
- **model**: Load model type (`open-model` or `closed-model`)
- **operation**: Type of operations (`read`, `write`, `mixed`)

### Load Models

- **Open Model**: High-throughput testing with unlimited virtual users and arrival rates
- **Closed Model**: Controlled testing with fixed number of virtual users and thinking time

### Current Test Suite

| Test File | Description | Operations | Load Model |
|-----------|-------------|------------|-------------|
| `catalog-api-open-model-read-test.js` | High-load read testing | GET only | Open (arrival rate) |
| `catalog-api-closed-model-read-test.js` | Controlled read testing | GET only | Closed (fixed VUs) |
| `catalog-api-closed-model-write-test.js` | CRUD operations testing | POST/PUT/DELETE/GET | Closed (fixed VUs) |

### Adding New Tests

When creating new test files, follow the naming convention and update:
1. `run-test.bat` - Add menu option and script name
2. `README.md` - Document the new test
3. Consider load model appropriateness for the test scenario

## Structure

- `aspir8/` - Aspirate deployment scripts
- `k6/` - Load testing suite with Grafana monitoring
  - `scripts/` - K6 test scripts following naming convention
  - `k8s/` - Kubernetes Job configurations for k6
- `observability/` - Prometheus & Grafana configurations
- `k8s/` - Kubernetes manifests

## Prerequisites

- Docker Desktop with Kubernetes
- .NET 9 SDK
- kubectl configured for docker-desktop