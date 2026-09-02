#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";

const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), "..");
const LECTURES = path.join(ROOT, "lectures");

const episodes = [
  {
    dir: "01_project_introduction",
    title: "Project Introduction & Architecture",
    subtitle: "A specification-first leave course for Oracle APEX 26.1.4",
    slides: [
      ["The course contract", [["Two applications", "App 100: employee self service\nApp 200: HR administration\nOne shared DEMO schema"], ["Reproducible scope", "9 tables • 5 packages\n4 roles • 7 AI tools\n14 progressive episodes"]]],
      ["Why split the applications?", [["Employee boundary", "APP_USER determines identity\nOwner-filtered reports\nPackage-backed create and cancel"], ["Administrative boundary", "Manager direct-report scope\nAdmin company scope\nSuper Admin configuration scope"]]],
      ["Three AI integration points", [["For employees", "HR AI Assistant\nEMPLOYEE_HR_AGENT\nConfirmation for write tools"], ["For the process", "LEAVE_SUMMARY_AGENT\nBounded CLOB response\nNeutral approver summary"]]],
      ["What this episode locks in", [["Canonical identity", "APEX 26.1.4\nWorkspace/schema DEMO\nSQLcl connection demo"], ["What comes next", "Copy into APEX_PROJECT_TEMPLATE\nRun guarded initialization\nValidate before import"]]],
    ],
  },
  {
    dir: "02_project_setup_and_tooling",
    title: "APEX Project Template & Developer Tooling",
    subtitle: "Portable specifications, guarded generation, and durable context",
    slides: [
      ["Treating requirements as engineered source", [["Repository assets", "Four direct application specs\nArchitecture and app context\nFourteen lecture packages"], ["Guardrails", "No generated APEX runtime\nNo deployable database source\nTemplate owns environment controls"]]],
      ["The additive specification package", [["Course-owned", "App specifications and UX contracts\nApp context and course docs\nLectures and decks"], ["Template-owned", "AGENTS.md and .agents\n.env and Git attributes\nGuard, export, and backup scripts"]]],
      ["Portable generation workflow", [["Before generation", "Copy specs into a new repo\nRun template /init\nVerify DEMO connection identity"], ["After approval", "Generate reviewed database source\nGenerate both APEX applications\nValidate before any import"]]],
      ["Specs first, generation later", [["No hidden machine state", "Repository-relative paths\nExplicit --check / --write modes\nImport-safe Python entry points"], ["What comes next", "Specify nine target tables\nDefine five package contracts\nPlan deterministic demo data"]]],
    ],
  },
  {
    dir: "03_database_design_and_packages",
    title: "Database Model & Core PL/SQL Packages",
    subtitle: "Target contract: nine tables, five packages, and natural-key seed data",
    slides: [
      ["Nine-table relational model", [["Identity and policy", "HR_DEPARTMENTS • HR_USERS\nHR_ROLES • HR_USER_ROLES\nHR_SYSTEM_SETTINGS"], ["Leave lifecycle", "HR_LEAVE_TYPES • HR_LEAVE_BALANCES\nHR_LEAVE_REQUESTS\nHR_LEAVE_REQUEST_EVENTS"]]],
      ["Balance accounting", [["Reservation model", "Available = entitlement − used − pending\nSubmission increments pending\nFinal approval moves pending to used"], ["Concurrency", "Lock the annual balance row\nReject overlaps\nRelease a reservation exactly once"]]],
      ["Five package boundaries", [["Core", "HR_USER_PKG — identity\nHR_AUTH_PKG — roles and scope\nHR_LEAVE_PKG — accounting"], ["APEX integration", "HR_WORKFLOW_PKG — orchestration\nHR_AI_PKG — seven CLOB tools\nNo package COMMIT or ROLLBACK"]]],
      ["Nine tables, no surprises", [["Generation discipline", "19c-compatible DDL\nNamed constraints and indexes\nNatural-key seed lookups"], ["What comes next", "Generate App 100 from its spec\nUse APP_USER for employee queries\nCall packages from page processes"]]],
    ],
  },
  {
    dir: "04_employee_self_service_app",
    title: "Employee Self Service Application",
    subtitle: "Nine App 100 pages with session-bounded ownership",
    slides: [
      ["App 100 page map", [["Understand", "1 Dashboard • 2 My Profile\n3 My Leave Balances\n5 My Leave Requests"], ["Act and explain", "4 Submit Leave Request\n6 Details • 7 Timeline\n8 Assistant • 9 Agent"]]],
      ["A trustworthy request form", [["Inputs", "Leave type code\nStart and end dates\nReason with clear validation"], ["Server authority", "Working days calculated in package\nBalance rechecked under lock\nOverlap rejected atomically"]]],
      ["One caller-owned transaction", [["Step 1", "HR_LEAVE_PKG.CREATE_REQUEST\nReserves pending days\nReturns request ID"], ["Step 2", "HR_WORKFLOW_PKG.START_LEAVE_APPROVAL\nStarts App 200 workflow\nPage process commits once"]]],
      ["The form employees can trust", [["Security", "Identity comes from APP_USER\nNo arbitrary employee ID input\nDetail and cancel recheck ownership"], ["What comes next", "Define four canonical roles\nProtect pages and processes\nEnforce direct-report approval"]]],
    ],
  },
  {
    dir: "05_hr_admin_application",
    title: "HR Administration Application",
    subtitle: "Twelve App 200 pages for approvals, reporting, and controlled maintenance",
    slides: [
      ["Operational page map", [["Approval work", "1 Dashboard • 2 My Tasks\n3 Pending Requests • 4 Details\n9 Workflow Monitor"], ["HR operations", "5 Employees • 6 History\n7 Leave Types • 8 Balances\n10 Users • 11 Roles • 12 Settings"]]],
      ["Authorization by page", [["Manager or Admin", "Dashboard and task inbox\nPending queue and request details\nDirect-report scope for managers"], ["Admin / Super Admin", "HR reports and balances: ADMIN\nUsers, roles, settings: SUPER_ADMIN\nNavigation is not the boundary"]]],
      ["Safe balance adjustment", [["Page input", "Employee • leave type • year\nSigned entitlement delta\nRequired audit reason"], ["Package call", "HR_LEAVE_PKG.ADJUST_BALANCE\nRechecks authorization and row state\nPage owns the commit"]]],
      ["Twelve pages, four boundaries", [["Task reporting", "APEX_TASKS\nAPEX_TASK_PARTICIPANTS\nUPPER participant matching"], ["What comes next", "Configure authorization schemes\nProtect dual applications\nVerify four seed roles"]]],
    ],
  },
  {
    dir: "06_authorization_and_security",
    title: "Multi-Tier Authorization & Security Model",
    subtitle: "Four roles and package-enforced business scope across App 100 & App 200",
    slides: [
      ["The four-role hierarchy", [["Employee and manager", "EMPLOYEE owns self-service data\nMANAGER handles direct reports\nNeither receives broad administration"], ["Administration", "ADMIN handles company leave operations\nSUPER_ADMIN manages users, roles, settings"]]],
      ["Defense in depth", [["APEX layer", "Authorized navigation\nProtected pages and regions\nAuthorized processes and buttons"], ["Database layer", "HR_AUTH_PKG repeats scope checks\nHR_LEAVE_PKG locks and validates\nURL tampering cannot widen access"]]],
      ["Approval policy", [["Managers", "Must hold MANAGER role\nRequest employee must report directly\nUsername normalized to uppercase"], ["Administrators", "ADMIN and SUPER_ADMIN see company scope\nOnly SUPER_ADMIN changes security metadata"]]],
      ["Enforced twice, bypassed never", [["Schemes", "IS_MANAGER • IS_ADMIN\nIS_SUPER_ADMIN\nCAN_APPROVE_REQUEST"], ["What comes next", "Model LEAVE_APPROVAL\nStart by static ID\nConnect Human Task definitions"]]],
    ],
  },
  {
    dir: "07_apex_workflow_design",
    title: "APEX Workflow Engine Design",
    subtitle: "Two-stage approval owned by App 200",
    slides: [
      ["Workflow contract", [["Identity", "Static ID LEAVE_APPROVAL\nOwner application 200\nValid APEX session required"], ["Inputs", "REQUEST_ID • EMPLOYEE_ID\nMANAGER_ID • REQUESTED_DAYS\nDetail primary key = request ID"]]],
      ["Lifecycle", [["Manager stage", "Always create manager task\nReject releases pending days\nShort approval finalizes balance"], ["HR stage", "Long requests move to PENDING_HR_APPROVAL\nHR task retains reservation\nOutcome finalizes exactly once"]]],
      ["APEX 26.1 start API", [["Correct call", "APEX_WORKFLOW.START_WORKFLOW\np_application_id => 200\np_static_id => 'LEAVE_APPROVAL'"], ["Parameters", "T_WORKFLOW_PARAMETERS\nIndexed T_WORKFLOW_PARAMETER records\nNo obsolete workflow argument"]]],
      ["One workflow, two decision points", [["Runtime prerequisite", "Parsing schema needs CREATE JOB\nWorkflow uses background jobs\nFaults become WORKFLOW_ERROR"], ["What comes next", "Create manager and HR tasks\nResolve participants dynamically\nUse completion actions"]]],
    ],
  },
  {
    dir: "08_human_tasks_and_approvals",
    title: "APEX Human Tasks & Manager Approvals",
    subtitle: "Dynamic participants and completion actions",
    slides: [
      ["Two task definitions", [["Manager", "LEAVE_MANAGER_APPROVAL\nPotential owner = direct manager\nApprove or reject"], ["HR", "LEAVE_HR_APPROVAL\nPotential owners = ADMIN / SUPER_ADMIN\nUsed only for long leave"]]],
      ["Participant resolution", [["No hardcoded users", "Join request employee to manager\nFilter active accounts\nReturn normalized usernames"], ["HR pool", "Resolve through HR_USER_ROLES\nMultiple potential owners supported\nInitiator cannot self-approve"]]],
      ["Documented task inbox", [["Runtime sources", "APEX_TASKS\nAPEX_TASK_PARTICIPANTS\nNo obsolete potential-owner view"], ["Completion", "Task action calls HR_WORKFLOW_PKG\nPackage enforces actor scope\nWorkflow resumes after outcome"]]],
      ["Real owners, no shortcuts", [["Task safety", "Details page is protected\nRequest ID is checksummed\nDatabase repeats approval policy"], ["What comes next", "Configure APEX AI service\nCreate employee and summary agents\nKeep identity session-bound"]]],
    ],
  },
  {
    dir: "09_conversational_ai_assistant",
    title: "Conversational HR AI Assistant",
    subtitle: "Helpful answers grounded in authenticated employee context",
    slides: [
      ["Assistant architecture", [["APEX AI", "Configured Generative AI service\nAPEX_AI.GENERATE API\nCLOB response"], ["Application context", "APP_USER remains authoritative\nHR_AI_PKG supplies leave facts\nNo direct table mutation"]]],
      ["Prompt guardrails", [["Scope", "Answer only for current employee\nNever request another username\nDo not invent leave policy"], ["Action boundary", "Explain before acting\nWrite actions live in AI tools\nConfirmation is mandatory"]]],
      ["Two distinct agents", [["EMPLOYEE_HR_AGENT", "Interactive employee experience\nSeven package-backed tools\nText response"], ["LEAVE_SUMMARY_AGENT", "Neutral manager briefing\nCalled by HR_AI_PKG\nNo approval recommendation"]]],
      ["Helpful, never authoritative", [["Verification", "Inspect APEX_APPL_AI_AGENTS\nMatch static IDs exactly\nTreat generated text as assistive"], ["What comes next", "Define seven declarative tools\nUse explicit parameters\nConfirm create and cancel"]]],
    ],
  },
  {
    dir: "10_ai_agent_and_declarative_tools",
    title: "Autonomous AI Agent & Declarative Tools",
    subtitle: "Seven CLOB tools with session-bounded security",
    slides: [
      ["Seven-tool contract", [["Read tools", "GET_MY_PROFILE\nGET_LEAVE_BALANCE\nGET_MY_LEAVE_REQUESTS\nGET_LEAVE_REQUEST"], ["Calculate and write", "CALCULATE_LEAVE_DAYS\nCREATE_LEAVE_REQUEST\nCANCEL_LEAVE_REQUEST"]]],
      ["Identity cannot be spoofed", [["Inputs allowed", "Leave type code\nDates, status, request ID\nReason"], ["Inputs forbidden", "Employee username\nEmployee user ID\nAny cross-user selector"]]],
      ["Write-tool approval", [["Create", "Show type, dates, and reason\nRequire on-demand confirmation\nPackage validates and reserves"], ["Cancel", "Show request identifier\nRequire on-demand confirmation\nOwner and state rechecked"]]],
      ["Seven tools, one identity", [["Tool implementation", "Thin APEX wrappers\nHR_AI_PKG returns JSON CLOB\nCaller controls transaction outcome"], ["What comes next", "Generate workflow summary\nUse p_agent_static_id\nPersist a bounded projection"]]],
    ],
  },
  {
    dir: "11_ai_inside_workflow",
    title: "AI Inside Workflow Processes",
    subtitle: "A neutral summary without weakening deterministic approval",
    slides: [
      ["Why summarize?", [["Approver signal", "Employee and leave type\nDates and working-day total\nReason and balance impact"], ["What AI must not do", "Approve or reject\nInvent policy\nOverride package state"]]],
      ["APEX 26.1 AI call", [["Correct API", "APEX_AI.GENERATE\np_agent_static_id => 'LEAVE_SUMMARY_AGENT'\nReturns CLOB"], ["Persistence", "Return full CLOB to caller\nStore bounded VARCHAR2 projection\nPage or workflow owns commit"]]],
      ["Failure behavior", [["Deterministic process", "Leave request remains authoritative\nReservation is not altered by AI\nWorkflow state is explicit"], ["Safe recovery", "Unexpected AI fault is visible\nNo fabricated fallback approval\nAudit remains queryable"]]],
      ["AI advises, packages decide", [["Separation of concerns", "LLM explains\nPackages decide state\nHuman Tasks capture outcomes"], ["What comes next", "Add configurable HR threshold\nUse an idempotent migration\nPreserve existing requests"]]],
    ],
  },
  {
    dir: "12_ai_assisted_maintenance_and_changes",
    title: "AI-Assisted Maintenance & Requirement Changes",
    subtitle: "Evolving from one approval stage to two without identity shortcuts",
    slides: [
      ["The new requirement", [["Threshold", "LONG_LEAVE_THRESHOLD = 5\nFive or fewer days: manager final\nMore than five: HR second stage"], ["Invariant", "One initial reservation\nNo duplicate deduction\nEvery outcome remains auditable"]]],
      ["Migration discipline", [["Idempotent change", "MERGE setting by natural key\nNo hardcoded identity values\nSafe to rerun"], ["Compatibility", "Target final schema includes feature\nEpisode teaches progression\nGenerated source follows the spec"]]],
      ["Workflow branch", [["Manager approved", "Compare REQUESTED_DAYS to setting\nShort path finalizes\nLong path creates HR task"], ["Manager rejected", "Release pending balance\nSet REJECTED once\nDo not create HR task"]]],
      ["Grow the process, keep the guarantees", [["Agent-assisted review", "Trace table and package dependencies\nUpdate tests with the requirement\nReview generated diff"], ["What comes next", "Separate MANAGER from ADMIN\nRefactor authorization\nMigrate assignments by natural key"]]],
    ],
  },
  {
    dir: "13_architecture_refactoring_roles",
    title: "Architecture Refactoring — Manager Role Separation",
    subtitle: "Least privilege through a distinct MANAGER role",
    slides: [
      ["The security debt", [["Before", "Manager borrowed ADMIN capability\nNavigation implied authority\nCompany scope was too broad"], ["After", "MANAGER handles direct reports\nADMIN handles HR operations\nSUPER_ADMIN controls security"]]],
      ["Natural-key migration", [["Role creation", "MERGE role_code = MANAGER\nResolve user by username MGR001\nResolve assignments by role_code"], ["Repeatability", "No assumed role IDs\nNo assumed user IDs\nReruns converge safely"]]],
      ["Authorization refactor", [["HR_AUTH_PKG", "IS_MANAGER checks role\nCAN_APPROVE_REQUEST checks reporting line\nAdmins retain company scope"], ["APEX", "Pages reference package schemes\nUnauthorized deep links fail\nHidden navigation is supplementary"]]],
      ["Fewer privileges, clearer boundaries", [["Least privilege", "Four roles with distinct purposes\nDirect-report approval is explicit\nTests cover negative paths"], ["What comes next", "Run full database assertions\nExercise both applications\nPrepare guarded handoff"]]],
    ],
  },
  {
    dir: "14_end_to_end_demo_and_wrap_up",
    title: "End-to-End Design Review & Best Practices",
    subtitle: "Acceptance path from employee request to audited balance update",
    slides: [
      ["Complete target solution map", [["Applications and data", "App 100 employee experience\nApp 200 approvals and administration\nNine shared HR tables"], ["Orchestration and AI", "Five packages\nLEAVE_APPROVAL and two tasks\nTwo agents and seven tools"]]],
      ["The demo journey", [["Submit", "EMP001 checks 14 available days\nCreates a valid request\nBalance moves to pending"], ["Approve", "Manager receives Human Task\nLong leave routes to HR\nFinal approval moves pending to used"]]],
      ["Production rules", [["Database authority", "Lock balance rows\nValidate overlap and scope\nKeep package transactions caller-owned"], ["Deployment authority", "Use template guards\nValidate APEXlang before import\nBack up metadata after deployment"]]],
      ["Specification package complete", [["Verified contract", "APEX 26.1.4 • ORDS 26.1.1+\nDatabase 19c RU 19.18+\nWorkspace/schema DEMO"], ["Reusable outcome", "Public-repo-safe specifications\nPortable generators and tests\nDurable app context for generation"]]],
    ],
  },
];

const colors = {
  navy: "#0f172a",
  slate: "#1e293b",
  red: "#c74634",
  blue: "#2563eb",
  white: "#ffffff",
  bg: "#f8fafc",
  border: "#dbe3ee",
  text: "#0f172a",
  muted: "#475569",
  light: "#e2e8f0",
};

function textbox(slide, text, position, style = {}) {
  const shape = slide.shapes.add({
    geometry: "textbox",
    position,
    fill: "none",
    line: { style: "solid", fill: "none", width: 0 },
  });
  shape.text = text;
  shape.text.style = { fontFamily: "Aptos", fontSize: 20, color: colors.text, ...style };
  return shape;
}

function addTitleSlide(presentation, episode, index) {
  const slide = presentation.slides.add();
  slide.background.fill = colors.navy;
  slide.shapes.add({ geometry: "rect", position: { left: 74, top: 122, width: 10, height: 430 }, fill: colors.red, line: { fill: "none", width: 0 } });
  const pill = slide.shapes.add({ geometry: "roundRect", position: { left: 116, top: 126, width: 190, height: 42 }, fill: colors.slate, line: { fill: colors.blue, width: 1 }, borderRadius: "rounded-xl" });
  pill.text = `EPISODE ${index + 1} OF 14`;
  pill.text.style = { fontFamily: "Aptos", fontSize: 14, bold: true, color: colors.white, alignment: "center", verticalAlignment: "middle" };
  textbox(slide, episode.title, { left: 116, top: 214, width: 1000, height: 150 }, { fontSize: 42, bold: true, color: colors.white });
  textbox(slide, episode.subtitle, { left: 116, top: 382, width: 980, height: 72 }, { fontSize: 22, color: colors.light });
  textbox(slide, "Oracle APEX 26.1.4  •  Workflow  •  Human Tasks  •  Generative AI", { left: 116, top: 510, width: 980, height: 34 }, { fontSize: 16, bold: true, color: colors.blue });
}

function addCard(slide, left, top, width, height, heading, body) {
  slide.shapes.add({ geometry: "roundRect", position: { left, top, width, height }, fill: colors.white, line: { fill: colors.border, width: 1 }, borderRadius: "rounded-2xl", shadow: "shadow-sm" });
  textbox(slide, heading, { left: left + 30, top: top + 32, width: width - 60, height: 50 }, { fontSize: 23, bold: true });
  textbox(slide, body.split("\n").map((line) => `• ${line}`).join("\n"), { left: left + 34, top: top + 108, width: width - 68, height: height - 138 }, { fontSize: 19, color: colors.muted });
}

function addContentSlide(presentation, episodeIndex, slideNumber, title, cards) {
  const slide = presentation.slides.add();
  slide.background.fill = colors.bg;
  textbox(slide, `EPISODE ${episodeIndex + 1}  •  SLIDE ${slideNumber} OF 5`, { left: 72, top: 44, width: 460, height: 24 }, { fontSize: 12, bold: true, color: colors.blue });
  textbox(slide, title, { left: 72, top: 82, width: 1136, height: 72 }, { fontSize: 32, bold: true });
  const gap = 28;
  const cardWidth = (1136 - gap) / 2;
  addCard(slide, 72, 184, cardWidth, 448, cards[0][0], cards[0][1]);
  addCard(slide, 72 + cardWidth + gap, 184, cardWidth, 448, cards[1][0], cards[1][1]);
  slide.shapes.add({ geometry: "rect", position: { left: 72, top: 664, width: 1136, height: 4 }, fill: colors.red, line: { fill: "none", width: 0 } });
}

async function artifactTool() {
  const root = process.env.RUNTIME_NODE_MODULES;
  if (!root) throw new Error("RUNTIME_NODE_MODULES is required for --write");
  const modulePath = path.join(root, "@oai", "artifact-tool", "dist", "artifact_tool.mjs");
  return import(pathToFileURL(modulePath).href);
}

async function writeDecks() {
  const { Presentation, PresentationFile } = await artifactTool();
  for (const [index, episode] of episodes.entries()) {
    const presentation = Presentation.create({ slideSize: { width: 1280, height: 720 } });
    addTitleSlide(presentation, episode, index);
    episode.slides.forEach(([title, cards], contentIndex) => addContentSlide(presentation, index, contentIndex + 2, title, cards));
    const output = path.join(LECTURES, episode.dir, "slides.pptx");
    const pptx = await PresentationFile.exportPptx(presentation);
    await pptx.save(output);
    process.stdout.write(`WROTE ${path.relative(ROOT, output)}\n`);
  }
}

async function checkDecks() {
  const manifest = JSON.parse(await fs.readFile(path.join(ROOT, "docs", "course", "course-manifest.json"), "utf8"));
  if (episodes.length !== manifest.counts.episodes) throw new Error("deck data does not match manifest episode count");
  for (const episode of episodes) {
    const output = path.join(LECTURES, episode.dir, "slides.pptx");
    const bytes = await fs.readFile(output);
    if (bytes.length < 4 || bytes[0] !== 0x50 || bytes[1] !== 0x4b) throw new Error(`${output} is not an OOXML ZIP`);
  }
  process.stdout.write("Deck inventory and OOXML signatures are valid.\n");
}

async function main() {
  const mode = process.argv[2];
  if (mode === "--write") await writeDecks();
  else if (mode === "--check") await checkDecks();
  else {
    process.stdout.write("Usage: node scripts/edit_lecture_decks.mjs --check | --write\n");
    process.exitCode = 2;
  }
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
});
