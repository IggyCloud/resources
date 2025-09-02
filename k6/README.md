# K6 Load Testing

Simple k6 load testing with Grafana + Prometheus stack.

## Usage

1. Deploy: `./deploy.sh`
2. Run Test: `./run-test.sh` 
3. Clean Up: `./cleanup.sh`

## URLs (Permanent - No Port-Forwarding)

- Grafana: http://localhost:30300 (admin/admin123)
  - K6 Dashboard: Available in dashboards menu
- Prometheus: http://localhost:30090

## Structure

```
k6/
├── k8s/                        # Kubernetes manifests
│   ├── namespace.yaml          # k6-loadtest namespace
│   ├── prometheus.yaml         # Prometheus deployment & service
│   ├── grafana-config.yaml     # Grafana datasources & dashboards
│   ├── grafana.yaml            # Grafana deployment & service
│   ├── grafana-dashboard.yaml  # K6 dashboard for Grafana
│   └── k6-job.yaml             # K6 job template
├── scripts/
│   └── catalog-api-test.js     # Your editable k6 test script
├── deploy.sh                   # Deploy infrastructure
├── run-test.sh                 # Run k6 test
└── cleanup.sh                  # Remove everything
```

## Test Details

- Target: catalog-api.default.svc.cluster.local:8080 (catalog API)
- Duration: 15 minutes (5m ramp up to 500, 5m at 700, 5m ramp down)
- High load test with 500-700 virtual users
- Metrics stored in Prometheus, visualized in Grafana
- Real-time monitoring of HTTP requests, response times, VUs, and error rates

## Customize Tests

Edit `scripts/catalog-api-test.js` - changes will be used when you run `./run-test.sh`