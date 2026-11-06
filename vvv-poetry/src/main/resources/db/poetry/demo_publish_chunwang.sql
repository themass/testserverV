-- ============================================================================
-- DEMO / REHEARSAL ONLY.  NOT content QA.  NEVER run against a real corpus.
-- Purpose: prove the publication gate works end to end on a dev database:
--   after this script  ->  GET /versions/.../lines returns the eight lines
--   before this script ->  the same call is 404
-- It "publishes" by writing DEMO-SIMULATION markers, and audit_integrity_checks.sql
-- deliberately reports non-zero afterwards (C5_demo_verified_source_would_publish,
-- C5_citation_locator_placeholder_on_published_claim, and one missing dating claim).
-- Those non-zero rows are the proof that a fake verification cannot pass silently.
-- Requires V001 + V002 + V003 + V004.
-- ============================================================================
START TRANSACTION;
UPDATE poetry_source
   SET source_kind='ONLINE_ENTRY', reliability='MEDIUM', verification_status='VERIFIED',
       verified_by='DEMO-SIMULATION', verified_at=NOW(),
       rights_note=CONCAT(COALESCE(rights_note,''), ' 【DEMO 演练库标记：未做真实核查】')
 WHERE id='source-chun-wang-candidate';
UPDATE poetry_citation
   SET locator='DEMO 演练定位（不是真实卷页，勿当依据）'
 WHERE claim_id='claim-chun-wang-author' AND source_id='source-chun-wang-candidate';
UPDATE poetry_text_version
   SET status='PUBLISHED', reviewed_by='DEMO-SIMULATION', reviewed_at=NOW()
 WHERE id='text-chun-wang-draft';
UPDATE poetry_content
   SET status='PUBLISHED', reviewed_by='DEMO-SIMULATION', reviewed_at=NOW(), revision=revision+1
 WHERE id IN ('work-chun-wang','person-du-fu','dynasty-tang');
UPDATE poetry_claim
   SET status='PUBLISHED', reviewed_by='DEMO-SIMULATION', reviewed_at=NOW()
 WHERE id IN ('claim-chun-wang-author','claim-tang-time','claim-dufu-time');
UPDATE poetry_work_author SET attribution='ACCEPTED' WHERE work_id='work-chun-wang' AND person_id='person-du-fu';
INSERT INTO poetry_review_log (subject_table, subject_id, subject_revision, decision, reviewer, note) VALUES
('poetry_text_version','text-chun-wang-draft',1,'PUBLISHED','DEMO-SIMULATION','演练：仅用于验证发布闸门，非真实核查。'),
('poetry_content','work-chun-wang',2,'PUBLISHED','DEMO-SIMULATION','演练：年代依据未核查，故本库 audit 必然非 0。');
COMMIT;
