import http from 'k6/http';

export function getJwtToken() {
  const url = 'https://localhost:5243/connect/token';
  const payload = {
    client_id: 'catalogswaggerui',    // Changed to a client that supports client_credentials
    client_secret: 'secret',
    grant_type: 'client_credentials',  // Changed grant type
    scope: 'catalog'                   // Simplified scope for catalog API
  };

  const params = {
    headers: { 
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept': 'application/json'
    },
    insecureSkipTLSVerify: true
  };

  console.log('Requesting token with payload:', JSON.stringify(payload));
  const res = http.post(
    url, 
    Object.entries(payload).map(([k, v]) => `${k}=${encodeURIComponent(v)}`).join('&'),
    params
  );

  console.log('Token request status:', res.status);
  if (res.status !== 200) {
    console.error('Token request failed. Response:', res.body);
    console.error('Full response:', JSON.stringify(res));
    return null;
  }

  try {
    const tokenResponse = JSON.parse(res.body);
    console.log('Token received successfully');
    return tokenResponse.access_token;
  } catch (e) {
    console.error('Failed to parse token response:', e);
    return null;
  }
}

export function getAuthHeaders() {
  const token = getJwtToken();
  if (!token) {
    console.error('No valid token received, authentication will fail');
  }
  
  return {
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    insecureSkipTLSVerify: true
  };
}
