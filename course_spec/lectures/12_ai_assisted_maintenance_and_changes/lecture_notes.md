# Lecture 12: AI-Assisted Maintenance & Requirement Changes

## 📋 Lecture Metadata
* **Episode**: 12 of 14
* **Target Duration**: 15–20 minutes
* **Target Audience**: APEX Developers, Technical Leads, AI Pair-Programmers
* **Prerequisites**: Full application stack completed (Episodes 1–11)
* **Related Specs**:
  * [`AGENT_DEVELOPMENT_WORKFLOW.md`](../../AGENT_DEVELOPMENT_WORKFLOW.md)
  * [`DEMO_SCENARIOS.md`](../../DEMO_SCENARIOS.md)
  * [`LEAVE_WORKFLOW.md`](../../LEAVE_WORKFLOW.md)

---

## 🎯 Key Learning Objectives
By the end of this lecture, viewers will understand:
1. How to manage real-world requirement changes using an AI coding agent.
2. How to use Graphify for dependency tracking and impact analysis before modifying code.
3. The new requirement: **Leave requests longer than 5 days require secondary HR Admin approval**.
4. How to guide the AI agent to update PL/SQL packages, APEX workflow branches, and test cases without introducing regressions.
5. How to verify changes via SQLcl application export and Git diff review.

---

## ⏱️ Slide Outline & Timed Talking Points

### 1. The Maintenance Challenge in APEX (00:00 – 03:30)
* **What to Show**: The New Business Requirement:
  ```text
  "Due to company policy, any leave request exceeding 5 working days
   must first be approved by the Manager, and then undergo a secondary
   review by an HR Administrator before final approval."
  ```
* **Talking Points**:
  * "In real life, software requirements change constantly."
  * "Instead of manually hunting down every script, package, and workflow step, we leverage our AI coding agent equipped with `app_context/` and Graphify."

### 2. Graphify Impact Analysis (03:30 – 07:30)
* **What to Show**: Terminal running Graphify query:
  ```bash
  # Query components that interact with LEAVE_APPROVAL workflow and approval stages
  graphify query "Find all database packages and workflow activities dependent on leave duration and approval states."
  ```
  * Graphify reveals: `LEAVE_WORKFLOW.md`, `HR_LEAVE_PKG`, `LEAVE_APPROVAL` workflow definition, `HR_SYSTEM_SETTINGS`.
* **Talking Points**:
  * "Before writing code, Graphify identifies the exact blast radius of our change."

### 3. Prompting the Coding Agent (07:30 – 12:00)
* **What to Show**: Structuring the agent prompt:
  ```text
  Read app_context/leave-workflow.md and the current database implementation.
  Implement conditional two-stage approval:
  1. If REQUESTED_DAYS <= 5 -> Manager Approval -> Final Approved.
  2. If REQUESTED_DAYS > 5  -> Manager Approval -> HR Admin Task -> Final Approved.
  Update HR_LEAVE_PKG, workflow activities, and documentation.
  Do not duplicate approval logic.
  ```
* **Talking Points**:
  * "Notice how clear and constrained our prompt is. We refer to our durable architecture docs."

### 4. Executing & Verifying the Changes (12:00 – 16:30)
* **What to Show**:
  * AI updates the APEX Workflow with a switch condition on `REQUESTED_DAYS > 5`.
  * AI adds a second Human Task (`LEAVE_HR_APPROVAL`) routed to `ADMIN`.
  * Running SQLcl export:
    ```bash
    apex export -split -applicationid 100
    apex export -split -applicationid 200
    git diff
    ```
* **Talking Points**:
  * "Reviewing the clean Git diff gives us full confidence in what changed."

### 5. Wrap-up (16:30 – 18:00)
* **Talking Points**:
  * "We successfully modified a multi-tier workflow with AI assistance and zero regressions."
  * "In Episode 13, we tackle an even bigger architectural refactor: separating the `MANAGER` role from `ADMIN`."

---

## 💻 Workflow Branching Logic
```sql
-- Workflow switch expression
CASE 
    WHEN :REQUESTED_DAYS > 5 THEN 'REQUIRES_HR_APPROVAL'
    ELSE 'APPROVE_AND_COMPLETE'
END;
```

---

## 🖥️ Live Demo Script
1. Submit a 3-day request as `EMP001` $\to$ Approve as `MGR001` $\to$ Verify immediate final approval.
2. Submit a 7-day request as `EMP001` $\to$ Approve as `MGR001`:
   * Verify status remains `PENDING_HR_APPROVAL`.
3. Log in as `HR001` (HR Admin) $\to$ Open the second task $\to$ Click **Approve** $\to$ Verify final status is now `APPROVED`.

---

## ❓ Common Questions & Pitfalls
* **Q: How does the AI know where to place the new Human Task?**
  * *A*: Because the AI agent inspects the APEX Workflow export files and `app_context/leave-workflow.md`, it places the second activity directly in sequence following manager sign-off.

---

## ⏭️ Next Episode
* **[Lecture 13: Architectural Refactoring — Manager Role Separation](../13_architecture_refactoring_roles/lecture_notes.md)**
