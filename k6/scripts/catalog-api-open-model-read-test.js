import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

export const options = {
  discardResponseBodies: true,
  scenarios: {
    items_open_model: {
      executor: 'ramping-arrival-rate',
      timeUnit: '1s',
      startRate: 50,
      preAllocatedVUs: 100,
      maxVUs: 500,
      stages: [
        { duration: '60s', target: 500 },
        { duration: '90s', target: 500 },
        { duration: '30s', target: 700 },
        { duration: '90s', target: 700 },
        { duration: '30s', target: 800 },
        { duration: '90s', target: 800 },
        { duration: '60s', target: 1000 },
        { duration: '90s', target: 1000 },
        { duration: '30s', target: 1200 },
        { duration: '90s', target: 1200 },
        { duration: '30s', target: 0 },
      ],
      exec: 'hitItems',
    }
  },
  thresholds: {
    http_req_failed:   ['rate<0.02'],
    http_req_duration: ['p(95)<500'],
    checks:            ['rate>0.98'],
    errors: ['rate<0.01']
  }
};

const BASE = 'http://catalog-api.default.svc.cluster.local:8080';
const URL  = `${BASE}/api/catalog/items?api-version=1.0&pageSize=20`;

export function hitItems() {
  const res = http.get(URL, { 
    headers: { 
      'Accept': 'application/json',
      'Connection': 'keep-alive',  // Reuse connections
      'User-Agent': 'k6-load-test' 
    },
    timeout: '5s',  // Prevent hanging requests
  });
  
  check(res, { 
    '200 OK': (r) => r.status === 200,
    'Response time < 500ms': (r) => r.timings.duration < 500,
  })  || errorRate.add(1);
}
