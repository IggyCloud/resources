# PostgreSQL Persistent Monitoring Setup

This guide provides step-by-step instructions for deploying persistent PostgreSQL monitoring without requiring port-forwarding.

## Overview

The updated monitoring setup includes:
- **PostgreSQL Exporter**: Now configured with NodePort (30187) for persistent external access
- **Prometheus**: Optimized with Kubernetes service discovery for automatic target detection
- **Grafana**: Enhanced with PostgreSQL-specific monitoring panels
- **Validation Scripts**: Automated health checks for the entire monitoring pipeline

## Deployment Steps

### 1. Deploy PostgreSQL Exporter

```bash
kubectl apply -f observability/postgres-exporter.yaml
```

**Key Changes:**
- Service type changed from `ClusterIP` to `NodePort`
- NodePort `30187` assigned for external access
- Added `prometheus.io/path` annotation for explicit metrics path

### 2. Update Prometheus Configuration

```bash
kubectl apply -f observability/prometheus/prometheus-config.yaml
```

**Key Improvements:**
- PostgreSQL exporter now uses Kubernetes service discovery
- Automatic target detection based on service annotations
- Better reliability and resilience to pod restarts

### 3. Deploy Enhanced Grafana Dashboard

```bash
kubectl apply -f observability/grafana/grafana-config.yaml
```

**New PostgreSQL Panels Added:**
- PostgreSQL Connection Status
- Transaction Rates (Commits/Rollbacks)
- I/O Operations (Disk Reads vs Cache Hits)
- Buffer Cache Hit Ratio
- Database Activity (Tuples)

### 4. Restart Services (if needed)

```bash
# Restart Prometheus to reload configuration
kubectl rollout restart deployment prometheus

# Restart Grafana to load new dashboard
kubectl rollout restart deployment grafana
```

## Verification and Testing

### Automated Validation

Run the comprehensive validation script:

```bash
chmod +x observability/validate-postgres-monitoring.sh
./observability/validate-postgres-monitoring.sh
```

This script will check:
- PostgreSQL Exporter pod and service status
- Metrics endpoint accessibility
- Prometheus scraping configuration
- Target health in Prometheus
- Grafana dashboard availability

### Manual Verification

#### 1. Check PostgreSQL Exporter Status

```bash
# Check pod status
kubectl get pods -l app=postgres-exporter

# Check service and NodePort
kubectl get svc postgres-exporter
```

#### 2. Test External Access (NodePort)

```bash
# Get node IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

# Test metrics endpoint
curl http://$NODE_IP:30187/metrics
```

#### 3. Verify Prometheus Targets

```bash
# Port-forward to Prometheus
kubectl port-forward svc/prometheus 9090:9090

# Check targets in browser: http://localhost:9090/targets
# Look for postgres-exporter target with "UP" status
```

#### 4. Access Grafana Dashboard

```bash
# Port-forward to Grafana
kubectl port-forward svc/grafana 3000:3000

# Access dashboard: http://localhost:3000
# Look for "eShop API Monitoring Dashboard"
# Verify PostgreSQL panels are showing data
```

## Persistent Access Methods

### Method 1: NodePort (Recommended for Development)

**PostgreSQL Exporter**: `http://NODE_IP:30187/metrics`

Advantages:
- No port-forwarding required
- Persistent access across pod restarts
- Simple to use for development and testing

### Method 2: LoadBalancer (Production)

For production environments, consider changing the service type to LoadBalancer:

```yaml
spec:
  type: LoadBalancer  # Instead of NodePort
  ports:
  - port: 9187
    targetPort: 9187
    protocol: TCP
    name: metrics
```

### Method 3: Ingress (Advanced)

Create an Ingress resource for more sophisticated routing:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: postgres-exporter-ingress
spec:
  rules:
  - host: postgres-metrics.your-domain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: postgres-exporter
            port:
              number: 9187
```

## Monitoring Metrics Available

### Core PostgreSQL Metrics

1. **Connection Status**
   - `pg_up`: PostgreSQL server availability
   - `pg_stat_database_numbackends`: Active connections

2. **Transaction Metrics**
   - `pg_stat_database_xact_commit`: Committed transactions
   - `pg_stat_database_xact_rollback`: Rolled back transactions

3. **I/O Performance**
   - `pg_stat_database_blks_read`: Disk blocks read
   - `pg_stat_database_blks_hit`: Cache blocks hit
   - Cache hit ratio calculation

4. **Database Activity**
   - `pg_stat_database_tup_inserted`: Rows inserted
   - `pg_stat_database_tup_updated`: Rows updated
   - `pg_stat_database_tup_deleted`: Rows deleted

## Troubleshooting

### Common Issues

1. **PostgreSQL Exporter Pod Not Starting**
   ```bash
   kubectl describe pod -l app=postgres-exporter
   kubectl logs -l app=postgres-exporter
   ```

2. **Metrics Endpoint Not Accessible**
   ```bash
   # Check service endpoints
   kubectl get endpoints postgres-exporter

   # Test from within cluster
   kubectl run test-pod --image=curlimages/curl -it --rm -- curl postgres-exporter:9187/metrics
   ```

3. **Prometheus Not Scraping**
   ```bash
   # Check Prometheus configuration
   kubectl logs -l app=prometheus | grep postgres

   # Verify service discovery
   kubectl get svc postgres-exporter -o yaml | grep annotations -A 3
   ```

4. **No Data in Grafana**
   - Verify Prometheus is receiving metrics
   - Check dashboard panel queries
   - Confirm data source configuration

### Performance Considerations

- **Scrape Interval**: Default 15s is suitable for most scenarios
- **Retention**: Configure Prometheus retention based on storage capacity
- **Resource Limits**: Monitor exporter resource usage and adjust limits

## Security Considerations

1. **Network Policies**: Implement network policies to restrict access
2. **RBAC**: Ensure proper Kubernetes RBAC for service accounts
3. **Authentication**: Consider adding authentication for production deployments
4. **TLS**: Enable TLS for metrics endpoints in production

## Next Steps

1. **Alerting**: Set up Prometheus alerts for critical PostgreSQL metrics
2. **Backup Monitoring**: Add metrics for backup operations
3. **Query Performance**: Implement pg_stat_statements for query monitoring
4. **Log Integration**: Combine with log aggregation for complete observability

For additional help or questions, refer to the validation script output or check the individual component logs.