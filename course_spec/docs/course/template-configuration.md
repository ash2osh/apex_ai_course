# Template Configuration

Apply these values through the `APEX_PROJECT_TEMPLATE` `/init` workflow or its local, gitignored `.env`. Do not commit `.env`, credentials, wallets, tokens, or connection strings.

```dotenv
PROJECT_NAME=hr-leave-course
DB_ENVIRONMENT=development
APEX_APP_ID=100,200
TABLES_SCHEMA=DEMO
TABLES_PREFIXES=HR_
TABLES_SQLCL_CONNECTION=demo
TABLES_EXPECTED_USER=DEMO
CODE_SCHEMA=DEMO
CODE_PREFIXES=HR_
CODE_SQLCL_CONNECTION=demo
CODE_EXPECTED_USER=DEMO
APEX_PARSING_SCHEMA=DEMO
APEX_SQLCL_CONNECTION=demo
APEX_EXPECTED_USER=DEMO
INSTALL_UC_APX=false
UC_APX_SKILLS_AGENT=universal
```

The exact APEX workspace is `DEMO`. The saved SQLcl alias `demo` must resolve to session user and current schema `DEMO`; it is only an alias, never a credential. Both applications use the same parsing schema, so `APEX_APP_ID=100,200` is one comma-separated value.

The schema requires `CREATE JOB` before APEX Workflow or Human Tasks can run. Grant it through an authorized DBA process after reviewing the generated implementation; this specifications package contains no installer.
