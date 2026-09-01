# Examples

## Weak input

```
Fix the login. It's flaky. Make it production-ready and follow best practices.
```

## Strong output (abbreviated)

```
# BUG — Session cookie dropped on /login when 2FA is enabled

You are a coding agent working in this repository. Do the job below. Do not expand scope.

## Objective
Users with 2FA enabled sometimes land back on /login after submitting a valid password. After the change, a valid password + valid TOTP must create a session and redirect to /app every time in the documented repro.

## Context
- Repo: web-app
- Area: auth session
- Current: password step succeeds; after TOTP the Set-Cookie is missing on the final 302
- Desired: session cookie present after TOTP, user reaches /app
- Impact: 2FA users cannot stay signed in

Relevant code (current state only):

```ts
// file: src/auth/completeLogin.ts
[excerpt that shows the 302 and cookie write]
```

## Requirements
1. Repro in the prompt fails after the fix.
2. A regression test covers password + TOTP → session cookie + /app redirect.
3. Non-2FA login behavior is unchanged.

## Constraints and non-goals
- Do not change the public auth API.
- Do not add a new session store or auth library.
- Out of scope: password-reset, SSO, remember-me.
- Compatibility: existing session cookie name and flags stay the same.

## Read first
- `src/auth/completeLogin.ts` — cookie write vs redirect order
- `src/auth/totp.ts` — [UNVERIFIED] if the workspace does not contain it

## Done when
- `pnpm test src/auth` passes
- Manual repro no longer drops the cookie
- Diff is limited to auth session files plus the new test

## Output
Implement the fix, run the test command, list files touched and any remaining risk.
```

Why this works: typed job, current-state evidence, testable requirements, two "do not" lines, observable DONE, unverified path tagged.
