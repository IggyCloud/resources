import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const errorRate = new Rate('errors');

export let options = {
  stages: [
    { duration: '10s', target: 5 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], 
    http_req_failed: ['rate<0.01'], 
    errors: ['rate<0.01'], 
  },
};
const CATALOG_API_URL = 'http://catalog-api.default.svc.cluster.local:8080';

export default function () {
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
