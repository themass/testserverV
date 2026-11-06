-- V005: 《春望》作者归属缺少"采用说"。没有这一行，/content/{id}/claims 里 authorship 的
-- selected 永远是 false，接口上看不出"当前采用哪一署"。审计核查不抓它（结构合法），
-- 但产品语义上必须有：署名也是一个被采用的说法。
-- Requires V002 (creates claim-chun-wang-author) and V003 (creates poetry_review_log).
START TRANSACTION;
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
VALUES ('work-chun-wang', 'authorship', 'claim-chun-wang-author');
INSERT INTO poetry_review_log (subject_table, subject_id, subject_revision, decision, reviewer, note) VALUES
('poetry_claim', 'claim-chun-wang-author', 1, 'SUBMITTED', 'codex-draft',
 '补 authorship 采用说。归属本身仍待核查：来源未 VERIFIED 之前不得发布。');
INSERT INTO poetry_schema_version (version_no, description)
VALUES (5, 'Adoption row for Chun Wang authorship');
COMMIT;
