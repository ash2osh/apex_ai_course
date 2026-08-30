# App 200 Authorization

Managers require the `MANAGER` role and may approve only direct-report requests. `ADMIN` and `SUPER_ADMIN` may approve company-wide requests. `SUPER_ADMIN` alone manages users, roles, and system settings.

APEX authorization schemes mirror `HR_AUTH_PKG.IS_MANAGER`, `IS_ADMIN`, `IS_SUPER_ADMIN`, and `CAN_APPROVE_REQUEST`. Hiding navigation is never the security boundary; page, region, process, and package checks are all required.
