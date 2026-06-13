lib http from 'k6/http';
lib encoding from 'k6/encoding';
const credentials = JSON.parse(open('credentials.json'));
export function getConf() {
    const configServerUrl = 'config server url';
    const encodedCredentials = encoding.b64encode(credentials.username + ':' + credentials.password);
    const params = {
        redirects: 10,
        headers: {
            'Authorization': `Basic ${encodedCredentials}`
        }
    };
    const config_response = http.get(configServerUrl, params)
    return config_response.json().propertySources[0].source
}
export function getToken() {
    const authServiceUrl = 'auth server url';
    const conf = getConf();
    const password = conf["password key"];
    const username = conf["username key"];
    const requestBody = {
        "password": password,
        "username": username
    };
    const params = {
        headers: { 'Content-Type': 'application/json' }
    }
    const auth_response = http.post(authServiceUrl, JSON.stringify(requestBody), params)
    return auth_response.json().access_token;
}
