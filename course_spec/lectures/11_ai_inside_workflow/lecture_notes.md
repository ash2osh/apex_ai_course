# Lecture 11: AI Inside Workflow Processes

## 📋 Lecture Metadata
* **Episode**: 11 of 14
* **Target Duration**: 15–20 minutes
* **Target Audience**: APEX Developers, Enterprise Architects, Automation Engineers
* **Prerequisites**: APEX Workflow (Episode 7) & Human Tasks (Episode 8)
* **Related Specs**:
  * [`LEAVE_WORKFLOW.md`](../../LEAVE_WORKFLOW.md)
  * [`ADMIN_APP.md`](../../ADMIN_APP.md)

---

## 🎯 Key Learning Objectives
By the end of this lecture, viewers will understand:
1. How to embed AI Generative steps directly inside APEX Workflow activities.
2. How to pass runtime workflow variables (`EMPLOYEE_NAME`, `START_DATE`, `REASON`) into prompt templates.
3. How to store the AI-generated briefing in `HR_LEAVE_REQUESTS.AI_SUMMARY`.
4. How displaying AI summaries in the Manager Approval Task inbox accelerates human decision-making.

---

## ⏱️ Slide Outline & Timed Talking Points

### 1. The Power of "AI in the Loop" for Workflows (00:00 – 03:30)
* **What to Show**: Concept slide:
  * Raw employee reasons can be rambling or informal:
    * *Raw Reason*: "Hey Sarah, got some family in town from overseas and want to spend a long weekend showing them around the coast."
    * *AI Summary*: "Ahmed requests 3 days of Annual Leave (18-Sep to 20-Sep) for family hosting and personal travel."
* **Talking Points**:
  * "Managers receive dozens of requests. Having an automated, standardized AI summary attached to the task makes reviewing and approving significantly faster."

### 2. Adding the Generative AI Workflow Activity (03:30 – 08:30)
* **What to Show**: APEX Workflow Designer:
  * Activity Type: **Generative AI Activity** (or Execute PL/SQL calling `APEX_AI.GENERATE`).
  * Prompt Template:
    ```text
    Generate a professional 1-sentence summary of this leave request for the approver:
    Employee: &EMPLOYEE_NAME.
    Leave Type: &LEAVE_TYPE_NAME.
    Dates: &START_DATE. to &END_DATE. (&REQUESTED_DAYS. days)
    Employee Reason: &REQUEST_REASON.
    ```
  * Output Target: Workflow Variable `AI_SUMMARY`.
* **Talking Points**:
  * "The workflow engine handles API communication asynchronously. If the LLM takes 1.5 seconds to generate the text, the workflow manages the state safely."

### 3. Persisting & Displaying the AI Summary (08:30 – 13:00)
* **What to Show**:
  * Updating `HR_LEAVE_REQUESTS.AI_SUMMARY` via workflow activity.
  * Adding an "AI Summary" callout card on Page 4 (Leave Request Details) and Page 2 (Task Details) in the HR Admin App (App 200).
* **Talking Points**:
  * "When the manager opens the task on mobile or desktop, the AI summary is front and center."

### 4. End-to-End Live Workflow Verification (13:00 – 16:30)
* **What to Show**:
  * Submit request as Ahmed $\to$ Check Workflow Monitor in App 200.
  * View active instance activity log: `Validation Passed` $\to$ `AI Summary Generated` $\to$ `Task Assigned`.
  * Open Task as Sarah Manager $\to$ Highlight the generated summary.
* **Talking Points**:
  * "Everything works cohesively—the AI generated content seamlessly passes into the human task."

### 5. Wrap-up (16:30 – 18:00)
* **Talking Points**:
  * "Our core application features are 100% complete!"
  * "In Episode 12, we begin the real-world maintenance phase: using AI coding agents and Graphify to execute a complex requirement change."

---

## 💻 PL/SQL AI Summary Generation Code
```sql
PROCEDURE generate_workflow_ai_summary(
    p_request_id IN NUMBER,
    p_summary    OUT VARCHAR2
) IS
    l_prompt   VARCHAR2(4000);
    l_response VARCHAR2(4000);
    l_req      hr_leave_requests%ROWTYPE;
    l_emp_name hr_users.full_name%TYPE;
    l_type     hr_leave_types.leave_type_name%TYPE;
BEGIN
    SELECT r.*, u.full_name, t.leave_type_name
      INTO l_req, l_emp_name, l_type
      FROM hr_leave_requests r
      JOIN hr_users u ON r.user_id = u.user_id
      JOIN hr_leave_types t ON r.leave_type_id = t.leave_type_id
     WHERE r.request_id = p_request_id;

    l_prompt := 'Summarize this leave request in one clear, concise sentence for the manager: ' ||
                'Employee: ' || l_emp_name || ', Type: ' || l_type || 
                ', Duration: ' || l_req.requested_days || ' days, Reason: ' || l_req.reason;

    l_response := apex_ai.generate(
        p_prompt         => l_prompt,
        p_service_static_id => 'DEFAULT_AI_SERVICE'
    );

    UPDATE hr_leave_requests
       SET ai_summary = l_response
     WHERE request_id = p_request_id;

    p_summary := l_response;
END generate_workflow_ai_summary;
```

---

## 🖥️ Live Demo Script
1. Submit leave request from App 100 with a detailed multi-line reason.
2. In App 200 $\to$ Open **Workflow Monitor** (Page 9) $\to$ Show workflow step details.
3. Open **My Tasks** as `MGR001` $\to$ Point to the cleanly formatted AI Briefing box.

---

## ❓ Common Questions & Pitfalls
* **Q: What if the AI service is temporarily offline or rate-limited?**
  * *A*: In `HR_WORKFLOW_PKG`, we catch AI exceptions and fallback to a default string (`"Standard leave request for X days"`), ensuring the workflow continues without blocking the human approval process.

---

## ⏭️ Next Episode
* **[Lecture 12: AI-Assisted Maintenance & Requirement Changes](../12_ai_assisted_maintenance_and_changes/lecture_notes.md)**

