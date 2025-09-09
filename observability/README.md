# eShop Observability Stack

Complete observability solution for eShop microservices including monitoring, logging, metrics, and performance testing.

## 🏗️ Architecture

```
observability/
├── grafana/                    # Grafana dashboards and configuration
│   ├── consolidated-grafana-config.yaml    # Datasource and dashboard provisioning
│   ├── grafana-k6-dashboard.yaml          # K6 performance monitoring
│   └── grafana-api-dashboard.yaml         # API metrics and resource monitoring
├── prometheus/                 # Prometheus configuration and RBAC
│   └── patch-prometheus-rbac.sh           # Service discovery permissions
├── k6/                        # Performance testing with K6
│   ├── scripts/               # K6 test scripts
│   ├── k8s/                   # K6 Kubernetes manifests
│   ├── run-test.sh            # Test execution script
│   └── docs/                  # Performance testing documentation
└── scripts/                   # Deployment and management scripts
    └── post-deploy-monitoring.sh          # Main deployment script
```

## 🚀 Quick Start

### 1. Deploy eShop with Aspire
```bash
cd src/eShop.AppHost
aspirate apply
```

### 2. Configure Observability Stack
```bash
cd observability
./scripts/post-deploy-monitoring.sh
```

### 3. Run Performance Tests
```bash
cd k6
./run-test.sh catalog-api-open-model-test.js
```

## 📊 Dashboard Access

- **Grafana**: http://localhost:30300 (admin/admin123)
  - **K6 Performance**: Load testing metrics and performance insights
  - **API Monitoring**: .NET API metrics, resource utilization, and health
- **Prometheus**: http://localhost:9090
- **Catalog API**: http://localhost:31386

## 🎯 Features

### Monitoring & Metrics
- ✅ **API Performance Monitoring**: Response times, throughput, error rates
- ✅ **Resource Utilization**: CPU, memory, garbage collection
- ✅ **Connection Monitoring**: Kestrel connections, ThreadPool usage
- ✅ **Service Health**: Real-time service status and availability

### Performance Testing
- ✅ **K6 Load Testing**: Comprehensive performance testing with various load patterns
- ✅ **Real-time Metrics**: Live performance metrics during test execution
- ✅ **Historical Analysis**: Performance trend analysis and reporting

### Infrastructure
- ✅ **Kubernetes Integration**: Native Kubernetes service discovery
- ✅ **Auto-configuration**: Post-deployment automation scripts
- ✅ **Non-intrusive**: No modification of aspirate-generated manifests

## 📋 Available Dashboards

### K6 Performance Dashboard
- Request rate and throughput metrics
- Virtual user scaling and load patterns
- Response time percentiles (95th, 50th)
- HTTP status code distribution
- Error rate tracking

### API Monitoring Dashboard
- **Service Overview**: Health status and request rates
- **Performance Metrics**: Response time percentiles by service
- **Resource Utilization**: CPU and memory usage
- **Connection Analysis**: Kestrel connection monitoring
- **Garbage Collection**: .NET GC performance tracking

## 🔧 Configuration

The observability stack integrates with your existing eShop deployment through:

1. **Prometheus Configuration**: Located in `src/eShop.AppHost/prometheus.yml`
2. **Service Discovery**: Automatic detection of API services in Kubernetes
3. **Dashboard Provisioning**: Automated Grafana dashboard deployment
4. **NodePort Access**: External access configuration for monitoring tools

## 📈 Performance Testing

### Available Test Scripts
- `catalog-api-open-model-test.js`: Open model load testing
- `catalog-api-closed-model-test.js`: Closed model load testing

### Running Tests
```bash
cd k6
./run-test.sh <script-name>
```

### Monitoring Test Results
- Real-time metrics in Grafana K6 dashboard
- Performance trends and analysis
- Resource impact monitoring during tests

## 🛠️ Troubleshooting

### Common Issues
1. **No data in dashboards**: Ensure Prometheus RBAC is configured
2. **Service discovery not working**: Check Kubernetes permissions
3. **Dashboard not loading**: Verify Grafana datasource configuration

### Debug Commands
```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# Verify service metrics
curl http://localhost:31386/metrics

# Check pod status
kubectl get pods -l app=prometheus
kubectl get pods -l app=grafana
```