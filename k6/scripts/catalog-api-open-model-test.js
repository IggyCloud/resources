import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  scenarios: {
    items_open_model: {
      executor: 'ramping-arrival-rate',
      timeUnit: '1s',
      startRate: 150,
      preAllocatedVUs: 300,
      maxVUs: 800,
      stages: [
        { duration: '20s', target: 1000 }, // Start at 1000 RPS
        { duration: '60s', target: 1000 }, // hold at 1000 RPS
        { duration: '30s', target: 1500 }, // ramp to 1500 RPS
        { duration: '60s', target: 1500 }, // hold at 1500 RPS
        { duration: '30s', target: 2000 }, // BREAKING POINT: 2000 RPS
        { duration: '60s', target: 2000 }, // hold at 2000 RPS - should break
        { duration: '30s', target: 0 },    // ramp down
      ],
      exec: 'hitItems',
    },
  },
  thresholds: {
    http_req_failed:   ['rate<0.01'],    // Production-realistic: 1% error rate
    http_req_duration: ['p(95)<500'],    // Production-realistic: 500ms max
  },
  summaryTrendStats: ['avg','min','med','p(90)','p(95)','p(99)','max'],
};

const BASE = 'http://catalog-api.default.svc.cluster.local:8080';
const URL  = `${BASE}/api/catalog/items?api-version=1.0`;

export function hitItems() {
  const res = http.get(URL, { headers: { Accept: 'application/json' } });
  check(res, { '200 OK': (r) => r.status === 200 });
  sleep(Math.random() * 0.2);
}
