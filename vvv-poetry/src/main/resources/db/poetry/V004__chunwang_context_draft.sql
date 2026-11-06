-- V004: 《春望》最小闭环的草稿层（DRAFT only, nothing here is student-visible）.
-- Run after V001 + V003 (and V002). Adds: 地点 / 事件 / 年谱条目 / 主题线 / 四层背景 /
-- 注释 / 年代两说并存 / 覆盖声明 / 审核日志。
--
-- HONESTY RULE for this file:
--   * every source row is verification_status='PENDING'; no row claims to have been checked;
--   * every citation locator is an explicit placeholder ("待…"), which audit check
--     C5_citation_locator_placeholder_on_published_claim blocks from ever being published;
--   * interpretive text is 编写草稿, 措辞与依据都待复核;
--   * nothing asserts a definite composition story: 757 与 758 两说并存, 采用说单独记录。
-- Insert order follows the no-foreign-key convention: content -> child -> link rows.
START TRANSACTION;

-- ---------- 1. content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, start_year, end_year, time_precision) VALUES
('place-chang-an', 'PLACE', 'chang-an', '长安', '待核查：唐代京师今地、城址与今名对应。', NULL, NULL, 'UNKNOWN'),
('event-anshi-rebellion', 'EVENT', 'anshi-rebellion', '安史之乱', '待核查：起讫年份采用通行说，需史源定位。', 755, 763, 'RANGE'),
('event-chang-an-capture', 'EVENT', 'chang-an-capture', '叛军陷长安', '待核查：具体月份与史料表述需核对。', 756, 756, 'EXACT'),
('exp-du-fu-chang-an-757', 'EXPERIENCE', 'du-fu-chang-an-757', '杜甫困居长安一带（安史乱中）', '待核查：年谱依据与时间需核对，可能与他说并存。', 757, 757, 'EXACT'),
('theme-anshi-rebellion', 'THEME', 'anshi-rebellion-line', '安史之乱这条线', '主题线草稿：把战乱中的事件、行程与作品串成可停留的一条线。', 755, 763, 'RANGE');

-- Existing V002 rows get their display time filled in (still DRAFT).
UPDATE poetry_content SET start_year=618, end_year=907, time_precision='RANGE' WHERE id='dynasty-tang';
UPDATE poetry_content SET start_year=712, end_year=770, time_precision='APPROXIMATE' WHERE id='person-du-fu';
UPDATE poetry_content SET start_year=757, end_year=757, time_precision='EXACT' WHERE id='work-chun-wang';

-- ---------- 2. entity child rows ----------
INSERT INTO poetry_place (id, modern_name, parent_id) VALUES ('place-chang-an', '西安', NULL);
INSERT INTO poetry_event (id, place_id) VALUES
('event-anshi-rebellion', NULL), ('event-chang-an-capture', 'place-chang-an');
INSERT INTO poetry_experience (id, person_id, event_id, place_id) VALUES
('exp-du-fu-chang-an-757', 'person-du-fu', 'event-chang-an-capture', 'place-chang-an');
INSERT INTO poetry_theme (id, period_scope) VALUES ('theme-anshi-rebellion', NULL);

-- ---------- 3. sources (all PENDING: registered, not verified) ----------
INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status, source_kind, reliability) VALUES
('source-anshi-candidate', '《资治通鉴》唐纪（安史之乱相关段落）', '司马光', '版本待定：需指定通行本与卷次', NULL,
 '正史类候选来源。reliability 是编者分级判断，不代表本条已核对。', 'PENDING', 'OFFICIAL_HISTORY', 'HIGH'),
('source-dufu-zhuan-candidate', '《新唐书·杜甫传》', '欧阳修 等', '版本待定', NULL,
 '正史类候选来源；用于生平与官职，需逐条核对原文。', 'PENDING', 'OFFICIAL_HISTORY', 'HIGH'),
('source-dufu-nianpu-candidate', '杜甫年谱类来源（待指定具体年谱与版本）', '待指定', '待指定', NULL,
 '年谱类候选来源；《春望》写作年份的分歧要靠这类来源判定。', 'PENDING', 'YEAR_BOOK', 'MEDIUM');

-- ---------- 4. time span claims (FACT) + adopted selection ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty) VALUES
('claim-tang-time', 'dynasty-tang', 'time.span', '618..907 (RANGE)', 'FACT', 'KNOWN'),
('claim-dufu-time', 'person-du-fu', 'time.span', '712..770 (APPROXIMATE)', 'FACT', 'LIKELY'),
('claim-anshi-time', 'event-anshi-rebellion', 'time.span', '755..763 (RANGE)', 'FACT', 'KNOWN'),
('claim-chang-an-capture-time', 'event-chang-an-capture', 'time.span', '756..756 (EXACT)', 'FACT', 'LIKELY'),
('claim-exp-757-time', 'exp-du-fu-chang-an-757', 'time.span', '757..757 (EXACT)', 'FACT', 'DISPUTED'),
('claim-theme-anshi-time', 'theme-anshi-rebellion', 'time.span', '755..763 (RANGE)', 'FACT', 'KNOWN'),
('claim-chun-wang-time-757', 'work-chun-wang', 'time.span', '757..757 (EXACT) 说一：至德二载春困居长安时作', 'FACT', 'DISPUTED'),
('claim-chun-wang-time-758', 'work-chun-wang', 'time.span', '758..758 (EXACT) 说二：至德元载说，另有年谱系于此年', 'FACT', 'DISPUTED');
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id) VALUES
('dynasty-tang', 'time.span', 'claim-tang-time'),
('person-du-fu', 'time.span', 'claim-dufu-time'),
('event-anshi-rebellion', 'time.span', 'claim-anshi-time'),
('event-chang-an-capture', 'time.span', 'claim-chang-an-capture-time'),
('exp-du-fu-chang-an-757', 'time.span', 'claim-exp-757-time'),
('theme-anshi-rebellion', 'time.span', 'claim-theme-anshi-time'),
('work-chun-wang', 'time.span', 'claim-chun-wang-time-757');
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt) VALUES
('claim-anshi-time', 'source-anshi-candidate', '待人工核对：通鉴卷次与起止表述', NULL),
('claim-dufu-time', 'source-dufu-zhuan-candidate', '待人工核对：杜甫传本传原文', NULL),
('claim-chang-an-capture-time', 'source-anshi-candidate', '待人工核对：通鉴纪事年月', NULL),
('claim-exp-757-time', 'source-dufu-nianpu-candidate', '待人工核对：年谱系年', NULL),
('claim-chun-wang-time-757', 'source-dufu-nianpu-candidate', '待人工核对：系年于至德二载的年谱与页码', NULL),
('claim-chun-wang-time-758', 'source-dufu-nianpu-candidate', '待人工核对：系年于至德元载的年谱与页码', NULL);

-- ---------- 5. four-layer background, one layer = one body text ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision) VALUES
('bg-chun-wang-scene', 'BACKGROUND', 'chun-wang-scene', '眼前：春天的长安城', '编写草稿，措辞待复核。', 'UNKNOWN'),
('bg-chun-wang-city', 'BACKGROUND', 'chun-wang-city', '这座城：沦陷后的京城', '编写草稿，措辞与史实依据待复核。', 'UNKNOWN'),
('bg-chun-wang-world', 'BACKGROUND', 'chun-wang-world', '这个天下：打了三年的战事', '编写草稿，措辞与史实依据待复核。', 'UNKNOWN'),
('bg-chun-wang-person', 'BACKGROUND', 'chun-wang-person', '这个人：四十六岁的杜甫', '编写草稿，生平依据待复核。', 'UNKNOWN');
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty) VALUES
('claim-bg-scene', 'bg-chun-wang-scene', 'reading', '以"城在而山河在"反衬物是人非。', 'INTERPRETATION', 'LIKELY'),
('claim-bg-city', 'bg-chun-wang-city', 'context', '沦陷中的京城作为处境层。', 'INTERPRETATION', 'DISPUTED'),
('claim-bg-world', 'bg-chun-wang-world', 'context', '长期战事与音信断绝构成天下层。', 'INTERPRETATION', 'DISPUTED'),
('claim-bg-person', 'bg-chun-wang-person', 'context', '困居长安、家人离散构成个人处境层。', 'INTERPRETATION', 'DISPUTED');

INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id) VALUES
('bg-chun-wang-scene', 'work-chun-wang', 'SCENE',
 '城还在，山和河也还在，可它已经不是从前的样子。春天照常来了，草木疯长，长满了没人打理的街巷。（草稿：以景物反衬，措辞待复核）',
 'PRIMARY', 'claim-bg-scene'),
('bg-chun-wang-city', 'work-chun-wang', 'CITY',
 '长安是帝国的心脏。都城被占之后，宫阙、街市、官署还在，但秩序已经不在了。（草稿：城市作为处境，需核对城况史源）',
 'JUNIOR', 'claim-bg-city'),
('bg-chun-wang-world', 'work-chun-wang', 'WORLD',
 '这场战事从755年打到763年（通行纪年，待核），前后多年，音信断绝是常态。"家书抵万金"不是夸张的说法，是当时的实际处境。（草稿）',
 'SENIOR', 'claim-bg-world'),
('bg-chun-wang-person', 'work-chun-wang', 'PERSON',
 '写这首诗时杜甫正困在长安一带，官职低微、家人离散。（草稿：具体年份与官职待年谱核对，不假设确定故事）',
 'JUNIOR', 'claim-bg-person');
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt) VALUES
('claim-bg-scene', 'source-dufu-nianpu-candidate', '待人工核对：解诗依据（注本/研究）', NULL),
('claim-bg-city', 'source-anshi-candidate', '待人工核对：城况记载卷次', NULL),
('claim-bg-world', 'source-anshi-candidate', '待人工核对：战事时长与交通阻断记载', NULL),
('claim-bg-person', 'source-dufu-zhuan-candidate', '待人工核对：本传相关原文', NULL);
INSERT INTO poetry_background_line (background_id, version_id, line_seq) VALUES
('bg-chun-wang-scene', 'text-chun-wang-draft', 1),
('bg-chun-wang-scene', 'text-chun-wang-draft', 2),
('bg-chun-wang-city', 'text-chun-wang-draft', 1),
('bg-chun-wang-city', 'text-chun-wang-draft', 2),
('bg-chun-wang-world', 'text-chun-wang-draft', 5),
('bg-chun-wang-world', 'text-chun-wang-draft', 6),
('bg-chun-wang-person', 'text-chun-wang-draft', 7),
('bg-chun-wang-person', 'text-chun-wang-draft', 8);

-- ---------- 6. annotations (vocabulary: WORD/PHRASE/ALLUSION/IMAGE/RHYME/OTHER) ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty) VALUES
('claim-ann-shanhe', 'work-chun-wang', 'note.word.1', '山河：指长安一带的山川。', 'INTERPRETATION', 'LIKELY'),
('claim-ann-fenghuo', 'work-chun-wang', 'note.word.5', '烽火：战火，借指持续的战事。', 'INTERPRETATION', 'LIKELY');
INSERT INTO poetry_annotation (id, version_id, line_seq, annotation_kind, audience, content, claim_id) VALUES
('ann-chun-wang-shanhe', 'text-chun-wang-draft', 1, 'WORD', 'PRIMARY', '山河：指长安一带的山川。（措辞待与权威注本核对）', 'claim-ann-shanhe'),
('ann-chun-wang-fenghuo', 'text-chun-wang-draft', 5, 'WORD', 'JUNIOR', '烽火：战火，这里指持续未平的战事。（措辞待核）', 'claim-ann-fenghuo');
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt) VALUES
('claim-ann-shanhe', 'source-dufu-nianpu-candidate', '待指定注本与页码', NULL),
('claim-ann-fenghuo', 'source-dufu-nianpu-candidate', '待指定注本与页码', NULL);

-- ---------- 7. theme membership (one stayable line) ----------
INSERT INTO poetry_theme_item (theme_id, item_id, ordinal, item_role, note) VALUES
('theme-anshi-rebellion', 'event-anshi-rebellion', 1, 'ANCHOR', '主线锚点'),
('theme-anshi-rebellion', 'event-chang-an-capture', 2, 'MEMBER', '转折'),
('theme-anshi-rebellion', 'exp-du-fu-chang-an-757', 3, 'MEMBER', '人在其中'),
('theme-anshi-rebellion', 'work-chun-wang', 4, 'MEMBER', '由此读出');

-- ---------- 8. coverage declaration (data, not a Java string) ----------
INSERT INTO poetry_coverage (id, entity_type, from_year, to_year, coverage_kind, status, note, updated_by, updated_at) VALUES
('cov-work-755-760', 'WORK', 755, 760, 'PARTIAL', 'PUBLISHED',
 '当前只录入极小样本；空白只代表尚未覆盖，不代表这段时间没有作品。', 'codex-draft', NOW()),
('cov-person-700-780', 'PERSON', 700, 780, 'PARTIAL', 'PUBLISHED',
 '唐代诗人只录入个位数。', 'codex-draft', NOW()),
('cov-event-750-770', 'EVENT', 750, 770, 'PLANNED', 'DRAFT',
 '事件层待补：战事、灾异、迁转、科举等。', 'codex-draft', NOW());

-- ---------- 9. review log (append-only; what is blocked and why) ----------
INSERT INTO poetry_review_log (subject_table, subject_id, subject_revision, decision, reviewer, note) VALUES
('poetry_content', 'work-chun-wang', 1, 'SUBMITTED', 'codex-draft', '草稿录入完成，未审核；年代两说并存，当前采用 757。'),
('poetry_claim', 'claim-chun-wang-time-757', 1, 'CHANGES_REQUESTED', 'codex-draft', '缺年谱具体来源与页码，禁止发布。'),
('poetry_claim', 'claim-chun-wang-time-758', 1, 'CHANGES_REQUESTED', 'codex-draft', '保留并存，等人工判定采用哪一说。'),
('poetry_text_version', 'text-chun-wang-draft', 1, 'CHANGES_REQUESTED', 'codex-draft', '逐字核对未完成，底本未定，禁止发布。'),
('poetry_content', 'theme-anshi-rebellion', 1, 'SUBMITTED', 'codex-draft', '主题线需要 >=2 个已发布成员才能发布。');

INSERT INTO poetry_schema_version (version_no, description)
VALUES (4, 'Chun Wang minimal closed loop, DRAFT only, two datings kept side by side');
COMMIT;
