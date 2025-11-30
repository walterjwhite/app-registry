export function getServerForEnvironment(server, environment) {
    if (typeof environment === 'undefined' || environment === null || environment === '') {
      environment = 'dev';
      console.debug('env:' + environment + ' [default]');
    } else {
      console.debug('env:' + environment);
    }
    const targetUrl = server[environment];
    console.debug('server:' + targetUrl);
    return targetUrl
}
