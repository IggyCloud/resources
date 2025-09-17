import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  scenarios: {
    items_open_model: {
      executor: 'ramping-arrival-rate',
      timeUnit: '1s',
      startRate: 700,
      preAllocatedVUs: 10,
      maxVUs: 3000,
      stages: [
        { duration: '60s', target: 900 },
        { duration: '60s', target: 900 },
        { duration: '60s', target: 1000 },
        { duration: '60s', target: 1000 },
        { duration: '60s', target: 1200 },
        { duration: '60s', target: 1200 },
        { duration: '60s', target: 1400 },
        { duration: '60s', target: 1400 },
        { duration: '60s', target: 1600 },
        { duration: '60s', target: 1600 },
        { duration: '60s', target: 0 },
      ],
      exec: 'hitItems',
    },
  },
  thresholds: {
    http_req_failed:   ['rate<0.02'],
    http_req_duration: ['p(95)<500'],
    checks:            ['rate>0.98'],
  },
  summaryTrendStats: ['avg','min','med','p(90)','p(95)','p(99)','max'],
};

const BASE = 'http://catalog-api.default.svc.cluster.local:8080';
const URL  = `${BASE}/api/catalog/items?api-version=1.0`;

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
    'Response time < 5s': (r) => r.timings.duration < 5000,
  });
  
  // NO SLEEP - Let K6 send requests as fast as possible
  // The arrival-rate executor will control the rate, not artificial delays
}
