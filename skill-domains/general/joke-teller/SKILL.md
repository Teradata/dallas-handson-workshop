---
name: joke-teller
description: Tell jokes to users from various categories including programming, general, and knock-knock jokes. Supports random selection and category-specific requests with engaging conversational formatting.
usage: |
  Use this skill when users ask for jokes, entertainment, or humor. Works with general requests ("tell me a joke") or specific categories ("tell me a programming joke"). Returns formatted jokes with metadata including category and ID.
argumentHint: Optionally specify a joke category (programming, general, knock-knock, etc.) or request a random joke from any category.
---

# Joke Teller Skill

## Overview
This skill tells random jokes to entertain users. It retrieves jokes from a collection and presents them in a conversational manner.

## Capabilities
- **Tell a Joke**: Returns a random joke from the available collection
- **Joke Categories**: Supports jokes in various categories (programming, general, knock-knock, etc.)
- **Response Formatting**: Presents jokes in a readable, engaging format

## Usage Example
```
User: "Tell me a joke"
Skill: "Why do programmers prefer dark mode? Because light attracts bugs!"
```

## Endpoints
- `GET /joke` - Returns a random joke
- `GET /joke/:category` - Returns a random joke from a specific category

## Response Format
```json
{
  "joke": "Why did the JavaScript developer go broke? Because he lost his JS!",
  "category": "programming",
  "id": "joke_123"
}
```

## Features
- Random selection algorithm
- Joke rotation to minimize repetition
- Support for multiple joke categories
- Quick response times

## Configuration
- `max_jokes_per_session`: Limit jokes told per session (default: unlimited)
- `enable_categories`: Allow category-specific joke requests (default: true)
- `joke_source`: Source of joke data (local or remote API)
