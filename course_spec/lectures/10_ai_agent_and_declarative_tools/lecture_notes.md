# Lecture 10: Autonomous AI Agent & Declarative Tools

## 📋 Lecture Metadata
* **Episode**: 10 of 14
* **Target Duration**: 15–20 minutes
* **Target Audience**: APEX Developers, AI Engineers, Full-Stack Developers
* **Prerequisites**: Generative AI Service configured (Episode 9), PL/SQL packages active
* **Related Specs**:
  * [`AI_AGENT_TOOLS.md`](../../AI_AGENT_TOOLS.md)
  * [`AUTHORIZATION_MODEL.md`](../../AUTHORIZATION_MODEL.md)

---

## 🎯 Key Learning Objectives
By the end of this lecture, viewers will understand:
1. The architectural difference between an informational AI Assistant vs. an action-oriented AI Agent.
2. How to create declarative APEX AI Tools backed by PL/SQL (`HR_AI_PKG`).
3. The 7 core employee tools and their parameter schemas.
4. How session-bounding prevents identity spoofing and prompt injection vulnerabilities.
5. How an employee can complete a multi-step leave booking transaction purely through natural language.

---

## ⏱️ Slide Outline & Timed Talking Points

### 1. Assistant vs. Agent with Tools (00:00 – 03:30)
* **What to Show**: Comparison table:
  | Capability | AI Assistant (Ep 9) | AI Agent + Tools (Ep 10) |
  |---|---|---|
  | Primary Function | Chat & Explain Policies | Execute Database Transactions |
  | Database Access | Read-only / Knowledge | Structured PL/SQL Tool Calls |
  | Execution Style | Conversational | Multi-Step Function Calling |
* **Talking Points**:
  * "An AI Agent doesn't just reply with words; it decides which functions to call, provides parameters, inspects results, and chains actions together."

### 2. The 7 Declarative AI Tools (03:30 – 09:00)
* **What to Show**: Tool catalog and parameter definitions:
  1. `GET_MY_PROFILE`: Reads caller info (No parameters).
  2. `GET_LEAVE_BALANCE`: Inputs: `LEAVE_TYPE_CODE`. Returns: Available days.
  3. `GET_MY_LEAVE_REQUESTS`: Inputs: optional `STATUS`, `DATE_FROM`.
  4. `GET_LEAVE_REQUEST`: Inputs: `REQUEST_ID`.
  5. `CALCULATE_LEAVE_DAYS`: Inputs: `START_DATE`, `END_DATE`.
  6. `CREATE_LEAVE_REQUEST`: Inputs: `LEAVE_TYPE_CODE`, `START_DATE`, `END_DATE`, `REASON`.
  7. `CANCEL_LEAVE_REQUEST`: Inputs: `REQUEST_ID`.
* **Talking Points**:
  * "Notice tool #1 and #6: they never accept `p_user_id` as an input parameter! The PL/SQL package always resolves identity from `v('APP_USER')`. This makes prompt injection attacks that attempt to book leave on behalf of someone else impossible."

### 3. Implementing `HR_AI_PKG` & Tool Signatures (09:00 – 13:30)
* **What to Show**: Declaring an APEX AI Tool in Page Designer:
  * Tool Name: `CREATE_LEAVE_REQUEST`
  * Description: *"Submit a new leave request for the authenticated employee and start the approval workflow."*
  * Parameters: JSON Schema for dates, leave type, and reason.
  * PL/SQL Body: Invokes `hr_leave_pkg.create_request`.
* **Talking Points**:
  * "APEX handles tool invocation, parameter parsing, and serialization automatically."

### 4. Live Multi-Step Transaction (13:30 – 17:00)
* **What to Show**: Live Chat prompt in App 100:
  * User: *"I need to take annual leave from 20-Sep-2026 to 22-Sep-2026 for a personal matter."*
  * Agent Thought Process:
    1. Calls `CALCULATE_LEAVE_DAYS('2026-09-20', '2026-09-22')` $\to$ Returns 3 days.
    2. Calls `GET_LEAVE_BALANCE('ANNUAL')` $\to$ Returns 14 available.
    3. Responds: *"You have 14 days available. Requesting 3 days from 20-Sep to 22-Sep. Should I proceed?"*
    4. User: *"Yes, please submit it."*
    5. Calls `CREATE_LEAVE_REQUEST(...)` $\to$ Returns Request `#105` in `PENDING_MANAGER_APPROVAL` status.
* **Talking Points**:
  * "Notice how the agent executes a structured, multi-step transaction with confirmation before committing."

### 5. Wrap-up (17:00 – 18:00)
* **Talking Points**:
  * "We now have an autonomous AI Agent executing safe transactions."
  * "In Episode 11, we will bring AI inside the APEX Workflow engine itself to generate manager briefings automatically."

---

## 💻 Tool Definition JSON Schema Reference

### `CREATE_LEAVE_REQUEST` Tool Schema
```json
{
  "name": "CREATE_LEAVE_REQUEST",
  "description": "Submits a leave request for the current authenticated employee and starts the approval workflow.",
  "parameters": {
    "type": "object",
    "properties": {
      "leave_type_code": { "type": "string", "enum": ["ANNUAL", "SICK", "UNPAID", "EMERGENCY"] },
      "start_date": { "type": "string", "description": "Format YYYY-MM-DD" },
      "end_date": { "type": "string", "description": "Format YYYY-MM-DD" },
      "reason": { "type": "string", "description": "Reason for leave" }
    },
    "required": ["leave_type_code", "start_date", "end_date", "reason"]
  }
}
```

---

## 🖥️ Live Demo Script
1. In App 100, open **HR AI Agent** (Page 9).
2. Type: *"Check my leave balance and book leave for next Wednesday to Friday."*
3. Watch the agent inspect balances and ask for confirmation.
4. Reply *"Confirmed"* $\to$ Verify request ID created and visible in **My Leave Requests**.

---

## ❓ Common Questions & Pitfalls
* **Q: Why shouldn't we give the AI Agent tools to approve leave?**
  * *A*: In our business model, approvals require human manager accountability. Manager approvals are preserved as Human Tasks, while employee self-service actions are delegated to AI tools.

---

## ⏭️ Next Episode
* **[Lecture 11: AI Inside Workflow Processes](../11_ai_inside_workflow/lecture_notes.md)**
