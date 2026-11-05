-- Draft-only starter corpus. NOT a textbook edition, not reviewed, not student-visible.
-- Sources below are candidate verification locations, NOT a claim that they were inspected.
-- No dates, historical explanations, coordinates or modern textbook annotations are asserted.
-- Run once after V001. DML and version entry commit together; repeat fails without overwriting edits.
START TRANSACTION;
INSERT INTO poetry_content (id, entity_type, slug, title, summary) VALUES
('dynasty-tang', 'DYNASTY', 'tang', '唐', '待核查：朝代时间范围与背景。'),
('person-du-fu', 'PERSON', 'du-fu', '杜甫', '待核查：生平、年谱与相关史料。'),
('work-chun-wang', 'WORK', 'chun-wang', '春望', '待核查：作者归属、文本版本、写作时地与解释依据。');
INSERT INTO poetry_dynasty (id) VALUES ('dynasty-tang');
INSERT INTO poetry_person (id, dynasty_id) VALUES ('person-du-fu', 'dynasty-tang');
INSERT INTO poetry_work (id, dynasty_id, genre) VALUES ('work-chun-wang', 'dynasty-tang', NULL);
INSERT INTO poetry_source (id, title, url, rights_note) VALUES
('source-chun-wang-candidate', '《春望》公开文本核查入口（待核对版本）',
 'https://zh.wikisource.org/wiki/春望', '仅作待核查入口；需另行核对底本、版本及使用条件。');
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty) VALUES
('claim-chun-wang-author', 'work-chun-wang', 'authorship', '杜甫', 'FACT', 'UNKNOWN');
INSERT INTO poetry_citation (claim_id, source_id, locator) VALUES
('claim-chun-wang-author', 'source-chun-wang-candidate', '待人工核对标题与作者署名');
INSERT INTO poetry_work_author (work_id, person_id, attribution, claim_id) VALUES
('work-chun-wang', 'person-du-fu', 'PENDING', 'claim-chun-wang-author');
INSERT INTO poetry_text_version (id, work_id, version_code, label, script, source_id, source_locator) VALUES
('text-chun-wang-draft', 'work-chun-wang', 'draft-simplified-001', '简体录入草稿（非教材核定版）',
 'SIMPLIFIED', 'source-chun-wang-candidate', '全诗；待逐字核对');
INSERT INTO poetry_text_line (version_id, line_seq, content) VALUES
('text-chun-wang-draft', 1, '国破山河在，'),
('text-chun-wang-draft', 2, '城春草木深。'),
('text-chun-wang-draft', 3, '感时花溅泪，'),
('text-chun-wang-draft', 4, '恨别鸟惊心。'),
('text-chun-wang-draft', 5, '烽火连三月，'),
('text-chun-wang-draft', 6, '家书抵万金。'),
('text-chun-wang-draft', 7, '白头搔更短，'),
('text-chun-wang-draft', 8, '浑欲不胜簪。');
INSERT INTO poetry_schema_version (version_no, description) VALUES (2, 'Draft-only Chun Wang starter data');
COMMIT;
