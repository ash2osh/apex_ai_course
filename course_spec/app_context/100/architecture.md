# App 100 Architecture

Employee Self Service is Oracle APEX application 100 in workspace `DEMO`, parsing schema `DEMO`. Its nine pages are Dashboard, My Profile, My Leave Balances, Submit Leave Request, My Leave Requests, Leave Request Details, Workflow Timeline, HR AI Assistant, and HR AI Agent.

The target implementation derives employee identity from `APP_USER` through `HR_USER_PKG`. Page processes call `HR_LEAVE_PKG` and `HR_WORKFLOW_PKG`; they never update balances directly. The frozen app design is `apps/DEMO/100/application-spec.md` plus `app-ux-contract.json`; database and APEX runtime source are generated later inside the initialized template repository.
