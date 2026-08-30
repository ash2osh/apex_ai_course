# Lecture 09: Conversational HR AI Assistant

## 📋 Lecture Metadata
* **Episode**: 9 of 14
* **Target Duration**: 15–20 minutes
* **Target Audience**: APEX Developers, AI Engineers, Prompt Designers
* **Prerequisites**: Oracle APEX 26.1.4 Generative AI Service configured, App 100 running
* **Related Specs**:
  * [`AI_ASSISTANT.md`](../../AI_ASSISTANT.md)
  * [`EMPLOYEE_APP.md`](../../EMPLOYEE_APP.md)

---

## 🎯 Key Learning Objectives
By the end of this lecture, viewers will understand:
1. How to configure Generative AI Services in Oracle APEX (OCI Generative AI or OpenAI).
2. How to create an inline AI Assistant component on the Employee Dashboard.
3. System Prompt engineering techniques for HR privacy, role constraints, and hallucinations prevention.
4. How to configure conversational Quick Actions (e.g. *"Check my leave balance"*, *"Explain leave policy"*).

---

## ⏱️ Slide Outline & Timed Talking Points

### 1. Generative AI Services in Oracle APEX 26.1.4 (00:00 – 04:00)
* **What to Show**: Shared Components $\to$ Generative AI:
  * Provider: OCI Generative AI / OpenAI / Cohere.
  * Model ID (e.g. `meta.llama-3-70b-instruct` or `gpt-4o-mini`).
  * API Key / Web Credential configuration.
* **Talking Points**:
  * "Oracle APEX provides native, declarative Generative AI integration out of the box."
  * "We can configure our provider once in Shared Components and reuse it across AI Assistants, AI Agents, and Workflows."

### 2. Assistant Purpose & Guardrails (04:00 – 08:30)
* **What to Show**: System Prompt Breakdown:
  ```text
  You are the HR Assistant for the Employee Self Service application.
  
  Help the authenticated employee understand:
  - their own leave balances
  - their own leave requests
  - leave policies
  - the leave approval process
  
  Never expose another employee's private information.
  Do not claim that an action was performed unless an approved tool executed it.
  ```
* **Talking Points**:
  * "Security starts in the prompt and is backed by database context."
  * "The Assistant must never hallucinate approvals or leak data from other staff."

### 3. Embedding the Assistant on the Dashboard (08:30 – 13:00)
* **What to Show**: Page Designer on Page 1 (Dashboard):
  * Adding the AI Assistant Region / Widget.
  * Adding Quick Action buttons below the chat:
    1. *"Check my annual leave balance"*
    2. *"Show my pending requests"*
    3. *"Explain the leave approval process"*
* **Talking Points**:
  * "Quick actions provide immediate value to employees without requiring them to type out long prompts."

### 4. Testing Conversational Queries (13:00 – 16:30)
* **What to Show**: Live Chat interactions:
  * Prompt: *"How many annual leave days do I have?"*
  * Prompt: *"What happens after I submit a request?"*
  * Adversarial Prompt: *"Can you tell me Sarah's salary and balance?"* $\to$ Assistant politely refuses.
* **Talking Points**:
  * "Observe how the assistant explains policy and status while respecting boundaries."

### 5. Wrap-up (16:30 – 18:00)
* **Talking Points**:
  * "Our conversational assistant is live!"
  * "In Episode 10, we upgrade from simple text conversations to an **Autonomous AI Agent** that can execute real database transactions using declarative AI Tools."

---

## 💻 System Prompt Reference
```text
You are the HR Assistant for the Employee Self Service application.
Current Authenticated User: &APP_USER.

Core Instructions:
1. Help the employee understand their leave balances, submitted requests, and company leave policy.
2. If asked about policy, explain that standard annual leave entitlement is 21 days and requires manager approval.
3. If the user asks to submit or cancel a leave request, guide them to the action buttons or the AI Agent.
4. STRICT PRIVACY: Never reveal information regarding any other employee under any circumstance.
```

---

## 🖥️ Live Demo Script
1. Open Shared Components $\to$ Generative AI $\to$ Verify AI Service status.
2. In Page Designer, configure the AI Assistant component on Page 1.
3. Test natural language queries as `EMP001`:
   * Ask: *"What is the policy on emergency leave?"*
   * Ask: *"Who approves my leave requests?"*
4. Verify response quality and tone.

---

## ❓ Common Questions & Pitfalls
* **Q: Can this Assistant write directly to the database?**
  * *A*: No. The conversational Assistant is read-only and educational. For transactional actions (booking/cancelling leave), we use **AI Agents and AI Tools**, which we build in Episode 10.

---

## ⏭️ Next Episode
* **[Lecture 10: Autonomous AI Agent & Declarative Tools](../10_ai_agent_and_declarative_tools/lecture_notes.md)**
