import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const errorRate = new Rate('errors');

export let options = {
  stages: [
    { duration: '60s', target: 50 },
    { duration: '60s', target: 50 },
    { duration: '60s', target: 100 }, 
    { duration: '60s', target: 100 },
    { duration: '60s', target: 200 }, 
    { duration: '60s', target: 200 },
    { duration: '60s', target: 400 },
    { duration: '60s', target: 400 },
    { duration: '60s', target: 600 },
    { duration: '60s', target: 600 },
    { duration: '30s', target: 0 }, 
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'],
    http_req_failed: ['rate<0.05'],
    errors: ['rate<0.05'],
  },
};

const CATALOG_API_URL = 'http://catalog-api.default.svc.cluster.local:8080';
const TEST_TIMESTAMP = Date.now();

export function setup() {
  console.log('Setting up test data...');

  const data = {
    catalogTypes: [],
    catalogBrands: []
  };

  // Get catalog types
  let typesResponse = http.get(`${CATALOG_API_URL}/api/catalog/catalogtypes?api-version=1.0`, {
    headers: { 'Accept': 'application/json' }
  });

  if (typesResponse.status === 200) {
    try {
      data.catalogTypes = JSON.parse(typesResponse.body);
      console.log(`Found ${data.catalogTypes.length} catalog types`);
    } catch (e) {
      console.log('Error parsing catalog types:', e);
    }
  } else {
    console.log(`Error fetching catalog types: ${typesResponse.status}`);
  }

  // Get catalog brands
  let brandsResponse = http.get(`${CATALOG_API_URL}/api/catalog/catalogbrands?api-version=1.0`, {
    headers: { 'Accept': 'application/json' }
  });

  if (brandsResponse.status === 200) {
    try {
      data.catalogBrands = JSON.parse(brandsResponse.body);
      console.log(`Found ${data.catalogBrands.length} catalog brands`);
    } catch (e) {
      console.log('Error parsing catalog brands:', e);
    }
  } else {
    console.log(`Error fetching catalog brands: ${brandsResponse.status}`);
  }

  return data;
}

function generateTestItem(data) {
  const itemId = Math.floor(Math.random() * 1000000) + TEST_TIMESTAMP;

  // Get random valid IDs from setup data
  const randomTypeId = data.catalogTypes.length > 0 ?
    data.catalogTypes[Math.floor(Math.random() * data.catalogTypes.length)].id : 1;
  const randomBrandId = data.catalogBrands.length > 0 ?
    data.catalogBrands[Math.floor(Math.random() * data.catalogBrands.length)].id : 1;

  return {
    name: `k6-test-item-${itemId}`,
    description: `Test item created by k6`,
    price: 19.99,
    pictureFileName: "1.png",
    catalogTypeId: randomTypeId,
    catalogBrandId: randomBrandId,
    availableStock: 100,
    restockThreshold: 10,
    maxStockThreshold: 200
  };
}

export default function (data) {
  // Generate and create a test item
  const testItem = generateTestItem(data);

  // Test POST - Create Item
  let createResponse = http.post(`${CATALOG_API_URL}/api/catalog/items?api-version=1.0`,
    JSON.stringify(testItem),
    {
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    }
  );

  // Log errors for debugging
  if (createResponse.status !== 201) {
    console.log(`VU ${__VU}: Error creating item. Status: ${createResponse.status}`);
    console.log(`Response body: ${createResponse.body}`);
    console.log(`Request payload: ${JSON.stringify(testItem)}`);
    console.log(`Available types: ${data.catalogTypes.length}, brands: ${data.catalogBrands.length}`);
  } else {
    // Log successful requests occasionally for debugging
    if (Math.random() < 0.1) {
      console.log(`VU ${__VU}: Successfully created item ${testItem.name}`);
    }
  }

  check(createResponse, {
    'create item status is 201': (r) => r.status === 201,
    'create item response time < 2s': (r) => r.timings.duration < 2000,
  }) || errorRate.add(1);
}