# App 100 Leave Workflow

Workflow static ID: `LEAVE_APPROVAL`. Manager task: `LEAVE_MANAGER_APPROVAL`. HR task: `LEAVE_HR_APPROVAL`.

The submit process calls `HR_LEAVE_PKG.CREATE_REQUEST`, then `HR_WORKFLOW_PKG.START_LEAVE_APPROVAL`, in one caller-owned transaction. The package explicitly starts workflow application 200, which owns the workflow and approval task details, while preserving the App 100 employee as initiator. Five or fewer Monday–Friday working days finalize after manager approval. More than five proceed to HR approval while retaining the original balance reservation. Faults use `WORKFLOW_ERROR` without consuming or releasing reserved days.
