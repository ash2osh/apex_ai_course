# App 100 Authorization

`IS_EMPLOYEE` calls `HR_AUTH_PKG.IS_EMPLOYEE(:APP_USER)`. Managers, administrators, and super administrators also receive the `EMPLOYEE` role when they need self-service access.

Reports filter by `HR_USER_PKG.CURRENT_USER_ID`. Request detail and cancellation enforce ownership again in database packages. No page item, URL parameter, AI tool, or report predicate may accept an arbitrary employee username or user ID for a self-service operation.
