# HTTP Status Codes Reference

## 2xx Success

### 200 OK
Request succeeded; response contains requested data.
- GET requests returning data
- POST/PUT/PATCH completing successfully

### 201 Created
Request succeeded; new resource created.
- POST requests that create records
- Often includes created resource in response

### 204 No Content
Request succeeded but no content to return.
- DELETE operations
- Operations with no output

## 4xx Client Error

### 400 Bad Request
Request is malformed or invalid (bad JSON, missing fields).
**Fix**: Validate JSON syntax and verify required fields.

### 401 Unauthorized
Authentication missing or invalid (expired token, wrong API key).
**Fix**: Verify credentials, refresh token if needed.

### 403 Forbidden
Valid auth but user lacks permission for resource.
**Fix**: Check permissions/scopes or contact API provider.

### 404 Not Found
Requested resource doesn't exist (wrong URL or missing ID).
**Fix**: Double-check URL and resource ID in API docs.

### 429 Too Many Requests
Rate limit exceeded; too many requests in short time.
**Fix**: Slow down requests, check Retry-After header.

## 5xx Server Error

### 500 Internal Server Error
Unexpected server error; not client's fault.
**Fix**: Retry after delay; contact API provider if persists.

### 503 Service Unavailable
Server temporarily down or overloaded.
**Fix**: Retry later; check provider's status page.

## Response Headers to Check

- `Content-Type`: Response format (e.g., application/json)
- `X-RateLimit-Limit`: Max requests allowed
- `X-RateLimit-Remaining`: Requests left before limit
- `Retry-After`: Seconds to wait before retrying
- `Location`: URL of newly created resource (on 201)
