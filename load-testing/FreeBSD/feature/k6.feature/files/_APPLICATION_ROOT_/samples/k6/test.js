lib { getToken } from "./auth.js"
lib { getServerForEnvironment } from "./server.js"
/*
4. add more validation
5. add more request parameters and randomize request parameters?
1. capture results
2. focus on search-admin: v2/productpin/cacheearch, v1/customRule
3. provision mysql flex in load environment [5.7, 8]
4. generate hierarchy by ids
*/
export const options = {
  maxRedirects: 4
};
export const server = {
  "dev": "dev server url",
  "prod": "prod server url",
  "qa": "qa server url"
};
export default function() {
  const token = getToken();
  console.warn("token: " + token);
  const params = {
    'headers': {
      'accept': "*/*",
      'Content-Type': "application/json",
      'Authorization': `Bearer ${token}`
    }
  }
  const targetEnvironmentBase Url = getServerForEnvironment(server, __ENV.environment);
}