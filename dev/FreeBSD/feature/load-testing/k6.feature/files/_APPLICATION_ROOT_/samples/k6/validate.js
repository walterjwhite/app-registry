lib { check } from "k6";
export function validate(result, contentType) {
  if(result.status !== 200) {
    console.error("Request failed: " + result.url + "\n" + JSON.stringify(result));
  }
  check(result, {'Status is 200': (r) => result.status === 200});
  if(contentType != null) {
    check(result, {'Content-Type header': (r) => result.headers['Content-Type'] === contentType});
  }
}
