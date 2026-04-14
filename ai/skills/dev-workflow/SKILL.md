---
name: dev-workflow
description: End-to-end development workflow evaluating requirements, generating code, and reviewing. Requires a description; PRD and spec files are optional.
---

# Dev Workflow

Execute the following development workflow:

**Inputs:**

- **Description** (mandatory)
- **PRD file** (optional)
- **Spec file** (optional)

**Workflow Steps:**

## 1 - Planning & Stress-Testing

Using the provided description, PRD, and spec, call the `grill-me` skill. Relentlessly interview the user and resolve the decision tree until a complete shared understanding is reached.

- Present a summary of the plan to the user and ask for approval before proceeding.
- **Wait for the user's answers** before continuing.
- Consolidate everything into a **Requirements Document** containing:
  - **User Stories**
  - **Acceptance Criteria**
  - **Technical Requirements**
  - **Data Requirements**
  - **Performance Requirements**
  - **Maintainability Requirements**
  - **Test Requirements**
  - **Deployment Requirements**

> Do not advance to the step 2 until the user approves the Requirements Document.

## 2 - Implementation

Once the shared understanding and plan are finalized from the first step, use the `/caveman` command with the plan's output and call the `@TheEngineer` agent to implement the code.

***What to pass:***

```text
/caveman <plan from step 1>
```

**What to collect:**

- Implemented code (files, functions, classes, etc...)
- Technical decisions made
- Added dependencies

Consolidate the result into a **Code Package**.

## 3 - Review

After the implementation is completed, call the `@CodeReviewer` agent to review the implemented changes, and compare with the PRD, SPEC and plan from step 1.

**What to pass:**

```text
Task: /caveman <Requirements Document from step 1>
Code: <Code Package from step 2>
```

**What to collect:**

- Issues found (bugs, code smells, pattern violations, etc.)
- Suggestions for improvement
- Final review status (approved/rejected)

## Final Output

After Step 3, present the final result to the user in a clear and organized manner, including:

- **Requirements Document**
- **Code Package**
- **Review Report**
- **Next Steps**

## Important Rules

1. **Never skip a step**
2. **Always wait for the user's approval before proceeding**
3. **Always present the final result to the user in a clear and organized manner**
