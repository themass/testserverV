-- EMERGENCY / CLEANUP. Sets EVERY poetry content row back to DRAFT and clears review markers.
-- Only safe while this library has no genuinely reviewed content (which is true until a human
-- reviewer is named in poetry_review_log with decision='PUBLISHED'). Reason it exists: a probe
-- script opened a JDBC session that committed instead of rolling back, leaving simulated
-- "published" rows in the database. Run it any time rehearsal state must be erased.
-- poetry_review_log stays append-only: this script records why it was run.
START TRANSACTION;
UPDATE poetry_content      SET status='DRAFT', reviewed_by=NULL, reviewed_at=NULL WHERE status<>'DRAFT';
UPDATE poetry_claim        SET status='DRAFT', reviewed_by=NULL, reviewed_at=NULL WHERE status<>'DRAFT';
UPDATE poetry_text_version SET status='DRAFT', reviewed_by=NULL, reviewed_at=NULL WHERE status<>'DRAFT';
UPDATE poetry_source       SET verification_status='PENDING', verified_by=NULL, verified_at=NULL
 WHERE verification_status<>'PENDING';
UPDATE poetry_work_author  SET attribution='PENDING' WHERE attribution<>'PENDING';
UPDATE poetry_citation     SET locator='待人工核对标题与作者署名'
 WHERE claim_id='claim-chun-wang-author' AND source_id='source-chun-wang-candidate' AND locator LIKE '%演练%';
UPDATE poetry_source       SET rights_note=REPLACE(COALESCE(rights_note,''),' 【DEMO 演练库标记：未做真实核查】','')
 WHERE rights_note LIKE '%DEMO 演练库标记%';
INSERT INTO poetry_review_log (subject_table, subject_id, subject_revision, decision, reviewer, note) VALUES
('poetry_content','work-chun-wang',1,'RETRACTED','LIVE-PROBE','演练/探针留下的模拟发布已全部撤回，全库回到 DRAFT；无任何内容对外可见。');
COMMIT;
