-- Undo demo_publish_chunwang.sql. Run it as soon as the gate rehearsal is done, so that no
-- simulated "verified" row survives in a real database.
-- poetry_review_log is append-only: the DEMO rows stay on purpose as the trail of the rehearsal.
START TRANSACTION;
UPDATE poetry_source SET verification_status='PENDING', verified_by=NULL, verified_at=NULL,
       source_kind=NULL, reliability=NULL,
       rights_note=REPLACE(COALESCE(rights_note,''),' 【DEMO 演练库标记：未做真实核查】','')
 WHERE id='source-chun-wang-candidate';
UPDATE poetry_citation SET locator='待人工核对标题与作者署名'
 WHERE claim_id='claim-chun-wang-author' AND source_id='source-chun-wang-candidate';
UPDATE poetry_text_version SET status='DRAFT', reviewed_by=NULL, reviewed_at=NULL WHERE id='text-chun-wang-draft';
UPDATE poetry_content SET status='DRAFT', reviewed_by=NULL, reviewed_at=NULL, revision=revision-1
 WHERE id IN ('work-chun-wang','person-du-fu','dynasty-tang');
UPDATE poetry_claim SET status='DRAFT', reviewed_by=NULL, reviewed_at=NULL
 WHERE id IN ('claim-chun-wang-author','claim-tang-time','claim-dufu-time');
UPDATE poetry_work_author SET attribution='PENDING' WHERE work_id='work-chun-wang' AND person_id='person-du-fu';
INSERT INTO poetry_review_log (subject_table, subject_id, subject_revision, decision, reviewer, note) VALUES
('poetry_content','work-chun-wang',3,'RETRACTED','DEMO-SIMULATION','演练结束：已撤回模拟发布，恢复 DRAFT；未做真实核查。');
COMMIT;
