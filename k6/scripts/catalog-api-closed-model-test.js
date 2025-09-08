import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

// OPTIMIZED test - Start from proven capacity, find true breaking point
export let options = {
  stages: [
    { duration: '20s', target: 200 },  // Start at proven 200 VUs  
    { duration: '60s', target: 200 },  // Hold at 200 VUs
    { duration: '30s', target: 400 },  // Jump to 400 VUs
    { duration: '60s', target: 400 },  // Hold at 400 VUs - expect issues
    { duration: '30s', target: 600 },  // BREAKING POINT: 600 VUs
    { duration: '60s', target: 600 },  // Hold at 600 VUs - should break
    { duration: '30s', target: 0 },    // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],  // Production-realistic: 500ms max
    http_req_failed: ['rate<0.01'],    // Production-realistic: 1% error rate
    errors: ['rate<0.01'],             // Catch degradation early
  },
};
// Base URL for the catalog-api service (using Kubernetes service name)
const CATALOG_API_URL = 'http://catalog-api.default.svc.cluster.local:8080';

export default function () {
  // Test 1: Get catalog items with API versioning
  let catalogResponse = http.get(`${CATALOG_API_URL}/api/catalog/items?api-version=1.0`, {
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  });

  check(catalogResponse, {
    'catalog API status is 200': (r) => r.status === 200,
    'catalog API response time < 500ms': (r) => r.timings.duration < 500,
    'catalog API returns JSON data': (r) => {
      try {
        const data = JSON.parse(r.body);
        return data && data.data && Array.isArray(data.data);
      } catch (e) {
        return false;
      }
    },
  }) || errorRate.add(1);
}