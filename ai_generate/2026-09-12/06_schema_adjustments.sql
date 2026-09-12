-- =============================================================================
-- Migration: 06_schema_adjustments.sql
-- Description: Allow administrative balance adjustments to record audit events
--              without requiring an active leave request ID.
-- Fixes: Critical Finding 2 / Finding 1 (ORA-01400 on HR_LEAVE_REQUEST_EVENTS.REQUEST_ID)
-- =============================================================================
SET DEFINE OFF;

PROMPT Modifying HR_LEAVE_REQUEST_EVENTS.REQUEST_ID to allow NULL ...

ALTER TABLE "DEMO"."HR_LEAVE_REQUEST_EVENTS" MODIFY "REQUEST_ID" NUMBER NULL;

PROMPT Column HR_LEAVE_REQUEST_EVENTS.REQUEST_ID modified to NULL successfully.

