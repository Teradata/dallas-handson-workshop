# API Authentication Patterns

## Bearer Token (OAuth 2.0 / JWT)

**When to use**: Modern APIs, SaaS platforms, cloud services

**Header format**:
```
Authorization: Bearer <token>
```

**Example**:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Token is typically JWT or opaque string. Tokens may expire; refresh tokens may be needed.

## Basic Authentication

**When to use**: Legacy APIs, internal services

**Header format**:
```
Authorization: Basic <base64-encoded-credentials>
```

**Example** (username: `user`, password: `pass`):
```
Authorization: Basic dXNlcjpwYXNz
```

**How to encode**:
1. Combine username and password: `user:pass`
2. Base64-encode: `dXNlcjpwYXNz`
3. Prepend `Basic `

## API Key

**When to use**: Public APIs, third-party services

**Header formats** (varies by provider):
```
X-API-Key: <key>
Authorization: ApiKey <key>
X-Custom-Key: <key>
```

**Example**:
```
X-API-Key: sk_live_abc123def456...
```

Key is long random string. Static, doesn't expire unless rotated. Different APIs use different header names.

## Query Parameter

**When to use**: Simple public APIs, testing

**Format**:
```
https://api.example.com/data?api_key=<key>
```

Key appears in URL and logs. Less secure than headers; avoid for sensitive operations.

## OAuth 2.0 (Full Flow)

**When to use**: User-facing apps with delegated access

**Flow**:
1. Redirect user to provider's login
2. User approves access
3. Provider redirects with auth code
4. Exchange code for access token
5. Use token to call APIs

Involves refresh tokens for new access tokens. Best for third-party integrations.

## Custom Headers

**When to use**: Proprietary APIs, internal services

**Format**:
```
X-Custom-Auth: <value>
X-Request-ID: <uuid>
```

**Example** (AWS Signature):
```
Authorization: AWS4-HMAC-SHA256 Credential=..., SignedHeaders=..., Signature=...
```

Endpoint-specific. May combine multiple headers. Often used with request signing and tracing.

## Best Practices

1. Use HTTPS for all authenticated requests
2. Store credentials in environment variables or vaults
3. Never hardcode API keys
4. Rotate keys regularly
5. Request only needed scopes and permissions
6. Monitor API usage and rate limits
7. Implement token refresh logic for expiring tokens
