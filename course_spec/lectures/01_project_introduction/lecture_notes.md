# Lecture 01: Project Introduction & Architecture

## 📋 Lecture Metadata
* **Episode**: 1 of 14
* **Target Duration**: 15–20 minutes
* **Target Audience**: APEX Developers, PL/SQL Developers, Solution Architects
* **Prerequisites**: Basic familiarity with Oracle APEX and SQL
* **Related Specs**:
  * [`README_TUTORIAL_PLAN.md`](../../README_TUTORIAL_PLAN.md)
  * [`APP_ARCHITECTURE.md`](../../APP_ARCHITECTURE.md)

---

## 🎯 Key Learning Objectives
By the end of this lecture, viewers will understand:
1. The business scenario: An enterprise Leave Management System.
2. Why two separate APEX applications (Employee Self Service vs. HR Administration) share one database schema.
3. The three distinct ways AI is integrated into this project (for the User, inside the Workflow, and for the Developer).
4. The high-level journey of a leave request from conversational creation to final approval and balance reconciliation.

---

## ⏱️ Slide Outline & Timed Talking Points

### 1. Welcome & Hook (00:00 – 03:00)
* **What to Show**: A fast 30-second teaser of the finished application:
  * Employee logs in $\to$ speaks to the AI Agent: *"Book annual leave next Monday for 3 days"* $\to$ Request is submitted $\to$ Manager receives a Human Task notification $\to$ Manager views AI-generated summary $\to$ Manager clicks **Approve** $\to$ Employee balance updates automatically.
* **Talking Points**:
  * "Welcome to the Oracle APEX AI and Workflow Masterclass."
  * "In this series, we are building a dual-application enterprise leave management system on Oracle APEX 26.1.4, combining native Workflows, Human Tasks, and Generative AI Agents."
  * "More importantly, we will show how modern AI coding agents and tools like Graphify assist us in building, understanding, and safely refactoring this application from start to finish."

### 2. Dual-Application Architecture (03:00 – 08:00)
* **What to Show**: Architecture diagram:
  ```text
                  ORACLE DATABASE
                        │
                Shared DEMO Schema (HR_ objects)
                        │
            ┌───────────┴───────────┐
            │                       │
            ▼                       ▼
   App 100: Employee Self Service   App 200: HR Administration
            │                       │
   - Employees & Managers           - HR Admins & Super Admins
   - Submit & Track Requests        - Approve / Reject Tasks
   - AI Assistant & Agent           - Manage Balances & Roles
  ```
* **Talking Points**:
  * "Why two apps instead of one giant application?"
  * "Separation of concerns: Employee Self-Service has high user concurrency, self-service UX, and strict row-level data isolation. HR Administration is a back-office tool with analytical dashboards, task inboxes, and system configuration."
  * "They share the `DEMO` schema; its course-owned objects use the `HR_` prefix, and business logic stays in PL/SQL packages rather than being duplicated across APEX pages."

### 3. The 3 Pillars of AI in this Series (08:00 – 13:00)
* **What to Show**: 3-box comparison slide:
  1. **AI for the User**: Conversational Assistant answering policy questions + Autonomous AI Agent invoking 7 secure transactional tools.
  2. **AI in the Business Process**: APEX Workflow automated activity that generates concise briefings for approvers before human tasks are assigned.
  3. **AI for the Developer**: Using AI coding agents, durable project knowledge (`app_context/`), and Graphify dependency graphs for impact analysis and refactoring.
* **Talking Points**:
  * "AI isn't just a chatbot widget glued to a webpage."
  * "We demonstrate AI across the full lifecycle: in the user interface, inside the transactional business workflow, and in the developer's IDE."

### 4. End-to-End Request Flow (13:00 – 17:00)
* **What to Show**: Sequence flow diagram:
  ```text
  Employee (App 100) ──► Submit Leave (or AI Agent)
                                │
                                ▼
                       HR_LEAVE_PKG (PL/SQL)
                                │
                                ▼
                      APEX Workflow Engine
                                │
                                ▼
                    AI Step: Generate Summary
                                │
                                ▼
                 Human Task: Manager Approval (App 200)
                                │
                                ▼
                  Approve / Reject ──► Balance Updated
  ```
* **Talking Points**:
  * "Notice where security happens: PL/SQL packages enforce data ownership and date validations. The AI agent cannot bypass validation rules or access another employee's records."

### 5. Series Roadmap & Wrap-up (17:00 – 18:30)
* **Talking Points**:
  * "Over the next 13 episodes, we will build this step-by-step."
  * "Next up in Episode 2: We will set up our modern APEX developer environment, repository structure, SQLcl connections, and project context."

---

## 🖥️ Live Demo Script
1. **Show Slide 1**: Title slide with project goals.
2. **Show Slide 2**: Dual-app architecture diagram.
3. **Show Slide 3**: Request lifecycle sequence.
4. **Quick Teaser in Browser**:
   * Open App 100 (Employee) $\to$ highlight clean UI and AI Assistant.
   * Open App 200 (Admin) $\to$ highlight My Tasks and Approval timeline.

---

## ❓ Common Questions & Pitfalls
* **Q: Can we build this in a single APEX application?**
  * *A*: Yes, but in enterprise settings, separating self-service from administrative consoles simplifies authorization schemes, reduces attack surfaces, and improves maintainability.
* **Q: Do we need external third-party servers for the AI workflow?**
  * *A*: No! APEX natively integrates with OCI Generative AI or OpenAI compatible endpoints via APEX Generative AI Services.

---

## ⏭️ Next Episode
* **[Lecture 02: APEX Project Template & Developer Tooling](../02_project_setup_and_tooling/lecture_notes.md)**
