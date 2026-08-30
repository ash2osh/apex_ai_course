# App 200 Architecture

HR Administration is Oracle APEX application 200 in workspace `DEMO`, parsing schema `DEMO`. Its twelve pages are Dashboard, My Tasks, Pending Leave Requests, Leave Request Details, Employees, Employee Leave History, Leave Types, Leave Balances, Workflow Monitor, Users, Roles, and System Settings.

Task and approval pages serve managers and HR administrators. Protected maintenance pages serve super administrators. The frozen app design is `apps/DEMO/200/application-spec.md` plus `app-ux-contract.json`; generated runtime source is not included. Database business rules belong in the five target shared packages.
