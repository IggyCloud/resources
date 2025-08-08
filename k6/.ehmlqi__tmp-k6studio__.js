import http from 'k6/http';
;
(function () {
  const httpRequest = http.request;
  const httpAsyncRequest = http.asyncRequest;
  class Client {
    request(method, url, ...args) {
      return httpRequest(method, url, ...instrumentArguments(args));
    }
    async asyncRequest(method, url, ...args) {
      return httpAsyncRequest(method, url, ...instrumentArguments(args));
    }
    del(url, ...args) {
      return this.request('DELETE', url, ...args);
    }
    get(url, ...args) {
      return this.request('GET', url, null, ...args);
    }
    head(url, ...args) {
      return this.request('HEAD', url, null, ...args);
    }
    $c26e2908c2e948ef883369abc050ce2f(url, ...args) {
      return this.request('OPTIONS', url, ...args);
    }
    patch(url, ...args) {
      return this.request('PATCH', url, ...args);
    }
    post(url, ...args) {
      return this.request('POST', url, ...args);
    }
    put(url, ...args) {
      return this.request('PUT', url, ...args);
    }
  }
  function trimAndRemovePrefix(input) {
    return input.trim().replace(/^::/, '');
  }
  function instrumentArguments(args) {
    const [body = null, params = {}] = args;
    const groupHeaders = {
      'X-k6-group': trimAndRemovePrefix(execution.vu.tags.group)
    };
    const updatedParams = Object.assign({}, params, {
      headers: Object.assign({}, params.headers || ({}), groupHeaders)
    });
    return [body, updatedParams];
  }
  function instrumentHTTP() {
    const client = new Client();
    http.del = client.del.bind(client);
    http.get = client.get.bind(client);
    http.head = client.head.bind(client);
    http.$c26e2908c2e948ef883369abc050ce2f = client.$c26e2908c2e948ef883369abc050ce2f.bind(client);
    http.patch = client.patch.bind(client);
    http.post = client.post.bind(client);
    http.put = client.put.bind(client);
    http.request = client.request.bind(client);
    http.asyncRequest = client.asyncRequest.bind(client);
  }
  instrumentHTTP();
})();
import {check} from 'k6';
import {getAuthHeaders} from './shared.ts';
export const $c26e2908c2e948ef883369abc050ce2f = {
  vus: 5,
  duration: '20s'
};
export default function () {
  const basketItem = {
    catalogItemId: 1,
    quantity: 1,
    basketId: 'test-basket'
  };
  const response = http.post('https://localhost:5104/api/v1/basket', JSON.stringify(basketItem), getAuthHeaders());
  check(response, {
    'is status 201': r => r.status === 201,
    'basket created': r => r.json().basketId === 'test-basket'
  });
}
export function handleSummary(data) {
  const checks = [];
  function traverseGroup(group) {
    if (group.checks) {
      group.checks.forEach(check => {
        checks.push(check);
      });
    }
    if (group.groups) {
      group.groups.forEach(subGroup => {
        traverseGroup(subGroup);
      });
    }
  }
  data.root_group.checks.forEach(check => {
    checks.push(check);
  });
  data.root_group.groups.forEach(group => {
    traverseGroup(group);
  });
  return {
    stdout: JSON.stringify(checks)
  };
}
export const options = {
  scenarios: {
    default: {
      executor: "shared-iterations",
      vus: 1,
      iterations: 1
    }
  }
};
