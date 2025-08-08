import http from 'k6/http';
import { check, fail } from 'k6';
import { getAuthHeaders } from './shared.js';

export const options = {
  vus: 400,
  duration: '30s',
};

export default function () {
  // Log request details
  console.log('Making request to catalog API...');
  // console.log('Headers:', JSON.stringify(getAuthHeaders()));

  const response = http.get(
    'http://localhost:5222/api/catalog/items?api-version=1.0',
    // getAuthHeaders()
  );

  // Log response details
  // console.log('Response status:', response.status);
  // console.log('Response headers:', JSON.stringify(response.headers));
  
  // Try to parse and log response body
  // try {
  //   console.log('Response body:', JSON.stringify(response.body));
  // } catch (e) {
  //   console.log('Could not parse response body:', response.body);
  // }

  // Enhanced checks with detailed failure messages
  const checks = check(response, {
    'is status 200': (r) => r.status === 200,
    'has items': (r) => {
      try {
        const items = r.json();
        // console.log(`Found ${items.length} items in response`);
        return items.count > 0;
      } catch (e) {
        console.error('Failed to parse JSON response:', e);
        return false;
      }
    },
  });

  if (!checks) {
    console.error('Test failed with status:', response.status);
    if (response.status === 401) {
      console.error('Authentication failed. Check your auth token.');
    } else if (response.status === 404) {
      console.error('API endpoint not found. Check if the service is running.');
    } else if (response.status >= 500) {
      console.error('Server error occurred:', response.body);
    }
  }
}