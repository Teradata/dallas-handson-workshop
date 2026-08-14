---
name: api-caller
title: API Caller - Make HTTP Requests
description: 'Make HTTP API calls to external REST endpoints with GET, POST, PUT, DELETE. Handle authentication, headers, JSON payloads, and response parsing for integration work.'
domain: general
metadata:
  author: demouser50
  version: 1.0.0
trigger:
  mode: HYBRID
  slash_commands:
    - /api
  keywords:
    - call an API
    - make HTTP request
    - REST API
    - fetch data
    - API integration
  intent_categories:
    - integration
  min_confidence: 0.70
prompt:
  constraints:
    - Always validate API URLs before making requests
    - Never expose credentials in outputs
    - Include error handling for failed requests
  output_format: Report HTTP method, URL, request body, response status, and results
---

# API Caller - Make HTTP Requests

## When to Use

- Call an external REST API to fetch or send data
- Integrate with third-party services or data providers
- Send JSON payloads or complex headers to an HTTP endpoint
- Test or validate API endpoints
- Do NOT use for database queries or Teradata operations

## Core Concepts

### HTTP Methods

| Method | Purpose | Use Case |
|--------|---------|----------|
| GET | Retrieve data | Fetch API data |
| POST | Send data to server | Create records |
| PUT | Replace resource | Full updates |
| PATCH | Partial update | Partial changes |
| DELETE | Remove resource | Delete records |

### Authentication Types

- **Bearer Token**: `Authorization: Bearer <token>` for OAuth and modern APIs
- **Basic Auth**: Base64-encoded username:password
- **API Key**: Custom header like `X-API-Key: <key>`
- **None**: Open endpoints requiring no auth

### Error Categories

- **4xx (400-404)**: Client errors - fix the request or URL
- **5xx (500-503)**: Server errors - retry later or contact provider
- **Connection errors**: Network issues - verify connectivity

## Procedure: GET Request

1. Validate the endpoint URL (protocol, domain, path)
2. Check if authentication is required (token, API key, etc.)
3. Make the GET request to the endpoint
4. Check HTTP status code (200 = success)
5. Parse and validate the JSON response

## Procedure: POST with JSON

1. Prepare JSON payload matching the API schema
2. Set headers: `Content-Type: application/json` and auth headers
3. POST the data to the endpoint
4. Verify status code (200 or 201 = success, 400 = validation error)
5. Extract and use the response data

## Procedure: Paginated API

1. Check API docs for pagination parameters (page, limit, offset, cursor)
2. Make first request with pagination params
3. Check for `next_page`, `has_more`, or `next_token` in response
4. Loop through pages, collecting results
5. Consolidate all pages into final dataset

## Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| 401 Unauthorized | Invalid or expired auth | Verify token/key and refresh if needed |
| 403 Forbidden | No permission | Check account access and scopes |
| 404 Not Found | Wrong URL or missing resource | Verify URL and resource ID |
| 429 Too Many Requests | Rate limit hit | Slow down requests, check rate headers |
| 500 Server Error | Server issue | Retry later or contact provider |
| Timeout | Slow response | Check connectivity, increase timeout |
| Invalid JSON | Malformed response | Verify Content-Type header |

## References

- [HTTP Status Codes](./references/http-status-codes.md) - Response code meanings and solutions
- [Authentication Patterns](./references/authentication-patterns.md) - Auth methods with examples
- [API Testing Checklist](./references/testing-checklist.md) - Validation steps for new APIs
