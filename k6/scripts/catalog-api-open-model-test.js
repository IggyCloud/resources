import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  scenarios: {
    items_open_model: {
      executor: 'ramping-arrival-rate',
      timeUnit: '1s',
      startRate: 50,
      preAllocatedVUs: 200,
      maxVUs: 1000,
      stages: [
        { duration: '30s', target: 100 }, // ramp to 100 RPS
        { duration: '1min', target: 100 }, // hold
        { duration: '30s', target: 200 }, // ramp to 200 RPS
        { duration: '1min', target: 200 }, // hold
        { duration: '30s', target: 0 },  // ramp down
      ],
      exec: 'hitItems',
    },
  },
  thresholds: {
    http_req_failed:   ['rate<0.02'],
    http_req_duration: ['p(90)<300','p(99)<900'],
  },
  summaryTrendStats: ['avg','min','med','p(90)','p(95)','p(99)','max'],
};

const BASE = 'http://catalog-api.default.svc.cluster.local:8080';
const URL  = `${BASE}/api/catalog/items?api-version=1.0&limit=20`;

export function hitItems() {
  const res = http.get(URL, { headers: { Accept: 'application/json' } });
  check(res, { '200 OK': (r) => r.status === 200 });
  sleep(Math.random() * 0.2);
}
