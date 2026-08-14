# API Testing Checklist

Use this checklist when integrating a new API.

## Pre-Request Validation

- [ ] URL Format - verify protocol, domain, path, query params
- [ ] Authentication - confirm method (Bearer, API Key, Basic) and credentials valid
- [ ] Headers - all required headers present (Content-Type, Authorization)
- [ ] Request Body - JSON syntax valid, required fields present
- [ ] Rate Limits - check limits and window size
- [ ] Documentation - review API docs for endpoint, method, response format

## Request Execution

- [ ] Simple Test - basic GET to confirm connectivity
- [ ] Auth Test - verify authentication works, test with invalid credentials
- [ ] Method Test - test each HTTP method (GET, POST, PUT, DELETE)
- [ ] Parameters - test with valid and invalid parameters
- [ ] Payloads - test with valid and invalid JSON
- [ ] Timeouts - check request timing, set appropriate timeouts

## Response Validation

- [ ] Status Code - verify correct HTTP status (200 success)
- [ ] Content-Type - check response format matches (application/json)
- [ ] Response Body - parse and verify structure matches docs
- [ ] Error Messages - confirm errors are clear and actionable
- [ ] Pagination - test pagination if applicable
- [ ] Timestamps - verify timestamp formats (ISO 8601, Unix)

## Error Handling

- [ ] 4xx Errors - test invalid inputs, expired tokens, wrong URLs
- [ ] 5xx Errors - confirm server errors handled gracefully
- [ ] Network Failures - test timeouts and connection interruptions
- [ ] Malformed Responses - test responses that don't match schema
- [ ] Rate Limiting - verify rate-limit headers present and respected

## Integration

- [ ] Data Transformation - response data correctly transformed
- [ ] Logging - requests/responses logged without exposing secrets
- [ ] Security - no API keys in logs, use environment variables
- [ ] Performance - request latency meets requirements
- [ ] Retry Logic - retry and backoff logic works correctly

## Documentation

- [ ] Endpoint Summary - URL, method, auth, purpose documented
- [ ] Example Requests - curl or code examples included
- [ ] Example Responses - success and error responses shown
- [ ] Rate Limits - rate limits documented
- [ ] Changes - version, breaking changes, deprecations noted
