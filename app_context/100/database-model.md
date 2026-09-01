# App 100 Database Model

The shared model has nine tables: `HR_DEPARTMENTS`, `HR_USERS`, `HR_ROLES`, `HR_USER_ROLES`, `HR_LEAVE_TYPES`, `HR_LEAVE_BALANCES`, `HR_LEAVE_REQUESTS`, `HR_LEAVE_REQUEST_EVENTS`, and `HR_SYSTEM_SETTINGS`.

App 100 reads profiles, balances, requests, and events. It creates or cancels requests only through `HR_LEAVE_PKG`. Submission reserves balance in `PENDING_DAYS`; final approval moves it to `USED_DAYS`; rejection or cancellation releases it once.
