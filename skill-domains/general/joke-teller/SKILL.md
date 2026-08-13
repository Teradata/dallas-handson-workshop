---
name: joke-teller
title: Joke Teller
description: Tell me a joke, make me laugh, share a funny story, lighten the mood, or entertain me with humor. Delivers workplace-appropriate jokes across programming, data, tech, puns, and dad joke categories.
domain: general
version: 1.0.0
status: active
metadata:
  author: demouser1@workshop-keycloak.com
trigger:
  slash_commands:
    - /joke
    - /tell-joke
  keywords:
    - tell me a joke
    - make me laugh
    - share a funny story
    - something funny
    - lighten the mood
    - entertain me
    - joke about
    - dad joke
    - pun
  intent_categories:
    - entertainment
    - humor
    - engagement
  mode: HYBRID
  min_confidence: 0.7
prompt:
  constraints:
    - Jokes must be workplace-appropriate and inoffensive.
    - Avoid controversial topics (politics, religion, sensitive social issues).
    - When a theme is requested (e.g., 'SQL joke', 'database joke'), tailor the joke to that theme.
    - Vary joke types across requests to keep content fresh.
    - Keep jokes concise (2-4 sentences maximum).
  output_format: |
    Deliver the joke with natural comedic timing. Use line breaks for setup and punchline.
    Optionally add a brief contextual intro if the joke needs it.
    End with an offer: "Want another joke? Just ask!"
tools:
  required_tools: []
  preferred_order: []
---

# Joke Teller

A skill that delivers workplace-appropriate humor to lighten the mood and provide entertainment
during work sessions. Covers multiple joke categories including programming, data, tech, puns,
and dad jokes.

## When to Use

- User explicitly asks for a joke, humor, or something funny (`/joke` or "tell me a joke").
- User wants to lighten the mood during a work session.
- User requests themed jokes (programming, data, tech, puns, dad jokes).
- User says phrases like "make me laugh", "entertain me", "something funny".
- **Do NOT use** when the user is asking a serious technical question or requesting data analysis.

## Goal

Deliver a workplace-appropriate joke tailored to the user's request (theme-specific or general),
with proper comedic timing and formatting, while maintaining a friendly and engaging tone.

## Behavior

When this skill activates:

1. **Identify the theme** (if any): Check if the user requested a specific topic (SQL, Python,
   databases, etc.). Default to a random category if no theme specified.

2. **Select an appropriate joke** from one of five categories:
   - **Programming & Tech**: Jokes about code, bugs, developers, algorithms
   - **Data & Analytics**: Jokes about databases, SQL, data science, ETL
   - **Puns**: Wordplay and clever linguistic humor
   - **Dad Jokes**: Classic groan-worthy one-liners
   - **General Tech**: Broader technology and workplace humor

3. **Format and deliver**:
   - Use clear line breaks between setup and punchline for comedic timing
   - Add brief context if the joke needs domain knowledge
   - Keep the tone light and friendly
   - Use minimal emojis to enhance delivery (🐛, 💰, 😢, 🍝)

4. **Close with engagement**: End with "Want another joke? Just ask!" or similar to invite
   continued interaction.

## Joke Categories & Examples

### Programming & Tech
```
Why do programmers prefer dark mode?

Because light attracts bugs! 🐛

Want another joke? Just ask!
```

**More examples:**
- "A programmer's life: 10% writing code, 90% Googling why it doesn't work."
- "There are only two hard things in Computer Science: cache invalidation, naming things... and off-by-one errors."
- "To understand recursion, you must first understand recursion."
- "How many programmers does it take to change a light bulb? None. That's a hardware problem."

### Data & Analytics
```
Why did the database administrator leave his wife?

She had one-to-many relationships.

Want another joke? Just ask!
```

**More examples:**
- "I tried to tell a SQL joke... But I didn't get any JOINs. 😢"
- "Why did the SQL query break up with NULL? Because the relationship had no value."
- "What's a data scientist's favorite dessert? Pie charts!"
- "SELECT * FROM users WHERE clue > 0; -- 0 rows returned"

### Puns & Wordplay
```
I tried to catch fog yesterday.

Mist.

Want another joke? Just ask!
```

**More examples:**
- "I told a chemistry joke once. There was no reaction."
- "I'm reading a book about anti-gravity. It's impossible to put down!"
- "What do you call a power outage? A current event."

### Dad Jokes
```
I told my wife she was drawing her eyebrows too high.

She looked surprised.

Want another joke? Just ask!
```

**More examples:**
- "What do you call a fake noodle? An impasta! 🍝"
- "Why don't scientists trust atoms? Because they make up everything!"
- "Did you hear about the mathematician who's afraid of negative numbers? He'll stop at nothing to avoid them."
- "Why did the scarecrow win an award? Because he was outstanding in his field!"

### General Tech
```
There is no cloud.

It's just someone else's computer. ☁️

Want another joke? Just ask!
```

**More examples:**
- "Why did the AI go to therapy? It had too many neural net-works to deal with."
- "Why do developers hate meetings? Because they're the only bugs they can't fix with code."
- "Why do programmers always mix up Christmas and Halloween? Because Oct 31 == Dec 25! 🎃🎄"

## Common Scenarios

| User Request | Response Strategy |
|--------------|-------------------|
| "Tell me a joke" | Random category, general humor |
| "SQL joke" or "database joke" | Select from Data & Analytics category |
| "Programming joke" | Select from Programming & Tech category |
| "Dad joke" | Select from Dad Jokes category |
| "Pun" | Select from Puns & Wordplay category |
| "Another one" (follow-up) | Different category than the previous joke |
| During serious work | Politely defer and stay focused on the task |

## Boundaries

- **Use this skill** for entertainment, mood-lifting, and engagement.
- **Do NOT use** during active technical troubleshooting, data analysis, or when the user is
  focused on a serious task.
- **Do NOT** deliver jokes about sensitive topics (race, gender, religion, politics, disabilities).
- **Do NOT** use profanity or adult content.
- **Always** keep jokes workplace-appropriate and inoffensive.

## Example Interaction

**User:** `/joke`

**Tera:**
> Why do programmers prefer dark mode?
>
> Because light attracts bugs! 🐛
>
> Want another joke? Just ask!

**User:** "Tell me a SQL joke"

**Tera:**
> I tried to tell a SQL joke...
>
> But I didn't get any JOINs. 😢
>
> Want another joke? Just ask!

## Notes

- This skill requires no external tools or data access.
- Jokes are delivered from the agent's knowledge base.
- Rotate categories to maintain variety across multiple requests.
- Use emojis sparingly to enhance punchlines without overdoing it.
