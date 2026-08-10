---
name: hello-tera
title: Hello Tera
description: A minimal demo skill that greets the user, confirms the skills registry is connected, and briefly explains how skills work. Use for smoke-testing the registry during customer demos.
domain: general
version: 1.0.0
status: active
metadata:
  author: Dallas Hands-On Workshop
trigger:
  slash_commands:
    - /hello-tera
    - /hello
  keywords:
    - hello tera
    - say hello
    - test skill
    - demo skill
    - is the registry working
  intent_categories:
    - greeting
    - demo
  mode: HYBRID
  min_confidence: 0.7
prompt:
  constraints:
    - Keep the greeting short and friendly.
    - Confirm that the skill was loaded from this skills registry.
    - Do not perform any external actions; this is a demo skill.
  output_format: |
    Respond with:
    1. A one-line friendly greeting.
    2. A short confirmation that the skills registry is connected and working.
    3. One sentence on how the user can add or use more skills.
tools:
  required_tools: []
  preferred_order: []
---

# Hello Tera

A minimal demo skill used to verify that this skills registry is correctly connected to Tera
and that skills can be discovered and activated.

## When to Use

- The user runs `/hello-tera` or `/hello`.
- The user says "hello tera", "test skill", or asks whether the registry is working.
- You want a quick smoke test during a customer demo.

## Goal

Greet the user, confirm the registry connection, and point them toward creating and using more
skills — without taking any real actions.

## Behavior

When this skill activates:

1. Greet the user warmly in a single line.
2. Confirm that this response came from the **Dallas Hands-On Workshop** skills registry, so
   the user knows the wiring works end to end.
3. Briefly explain that they can add more skills under `skill-domains/` and trigger them via
   slash commands or keywords.

## Example

**User:** `/hello-tera`

**Tera:**
> 👋 Hello from Tera!
> This response was served by the **hello-tera** skill from your Dallas Hands-On Workshop
> skills registry — everything is connected and working.
> Add more skills under `skill-domains/` and call them with a slash command or keyword to
> extend what I can do.

## Notes

- This skill performs no external actions and requires no tools.
- Use it as a template when scaffolding new demo skills.
