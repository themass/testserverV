-- Read-only integrity audit. There are NO foreign keys by project rule, so this file is the
-- enforcement substitute. Run it after EVERY data change and before ANY publish decision.
-- Expected result: every bad_rows = 0. A non-zero row is a blocked publish, not a warning.
-- Currently 106 checks (C1-C7). Since V003 they also cover THEME, poetry_coverage,
-- poetry_review_log, poetry_source.source_kind/reliability and poetry_background.body_text/audience.
-- Conventions checked here (see docs/poetry/data-model.md):
--   C1 every child row has a poetry_content row
--   C2 child row type matches poetry_content.entity_type
--   C3 content with a child row exists for its declared entity_type
--   C4 link rows point at existing rows, and the referenced claim belongs to the same subject
--   C5 published rows satisfy the read-side publication gate, or they silently disappear
--   C6 time fields follow TimeSpan rules (no year 0, ordered bounds, EXACT means one year)
--   C7 enum values are inside the documented vocabulary

SELECT 'C1_orphan_dynasty' AS check_name, COUNT(*) AS bad_rows FROM poetry_dynasty x LEFT JOIN poetry_content c ON c.id=x.id WHERE c.id IS NULL
UNION ALL SELECT 'C1_orphan_period', COUNT(*) FROM poetry_period x LEFT JOIN poetry_content c ON c.id=x.id WHERE c.id IS NULL
UNION ALL SELECT 'C1_orphan_place', COUNT(*) FROM poetry_place x LEFT JOIN poetry_content c ON c.id=x.id WHERE c.id IS NULL
UNION ALL SELECT 'C1_orphan_person', COUNT(*) FROM poetry_person x LEFT JOIN poetry_content c ON c.id=x.id WHERE c.id IS NULL
UNION ALL SELECT 'C1_orphan_event', COUNT(*) FROM poetry_event x LEFT JOIN poetry_content c ON c.id=x.id WHERE c.id IS NULL
UNION ALL SELECT 'C1_orphan_experience', COUNT(*) FROM poetry_experience x LEFT JOIN poetry_content c ON c.id=x.id WHERE c.id IS NULL
UNION ALL SELECT 'C1_orphan_work', COUNT(*) FROM poetry_work x LEFT JOIN poetry_content c ON c.id=x.id WHERE c.id IS NULL
UNION ALL SELECT 'C1_orphan_background', COUNT(*) FROM poetry_background x LEFT JOIN poetry_content c ON c.id=x.id WHERE c.id IS NULL

UNION ALL SELECT 'C2_type_mismatch_period', COUNT(*) FROM poetry_period x JOIN poetry_content c ON c.id=x.id WHERE c.entity_type<>'PERIOD'
UNION ALL SELECT 'C2_type_mismatch_place', COUNT(*) FROM poetry_place x JOIN poetry_content c ON c.id=x.id WHERE c.entity_type<>'PLACE'
UNION ALL SELECT 'C2_type_mismatch_person', COUNT(*) FROM poetry_person x JOIN poetry_content c ON c.id=x.id WHERE c.entity_type<>'PERSON'
UNION ALL SELECT 'C2_type_mismatch_event', COUNT(*) FROM poetry_event x JOIN poetry_content c ON c.id=x.id WHERE c.entity_type<>'EVENT'
UNION ALL SELECT 'C2_type_mismatch_experience', COUNT(*) FROM poetry_experience x JOIN poetry_content c ON c.id=x.id WHERE c.entity_type<>'EXPERIENCE'
UNION ALL SELECT 'C2_type_mismatch_work', COUNT(*) FROM poetry_work x JOIN poetry_content c ON c.id=x.id WHERE c.entity_type<>'WORK'
UNION ALL SELECT 'C2_type_mismatch_background', COUNT(*) FROM poetry_background x JOIN poetry_content c ON c.id=x.id WHERE c.entity_type<>'BACKGROUND'

UNION ALL SELECT 'C3_declared_type_without_child_row', COUNT(*) FROM poetry_content c
  LEFT JOIN poetry_dynasty d ON d.id=c.id LEFT JOIN poetry_period p ON p.id=c.id LEFT JOIN poetry_place pl ON pl.id=c.id
  LEFT JOIN poetry_person pe ON pe.id=c.id LEFT JOIN poetry_event ev ON ev.id=c.id LEFT JOIN poetry_experience ex ON ex.id=c.id
  LEFT JOIN poetry_work w ON w.id=c.id LEFT JOIN poetry_background b ON b.id=c.id
  WHERE (c.entity_type='DYNASTY' AND d.id IS NULL) OR (c.entity_type='PERIOD' AND p.id IS NULL)
     OR (c.entity_type='PLACE' AND pl.id IS NULL) OR (c.entity_type='PERSON' AND pe.id IS NULL)
     OR (c.entity_type='EVENT' AND ev.id IS NULL) OR (c.entity_type='EXPERIENCE' AND ex.id IS NULL)
     OR (c.entity_type='WORK' AND w.id IS NULL) OR (c.entity_type='BACKGROUND' AND b.id IS NULL)

UNION ALL SELECT 'C4_parent_dynasty_missing_on_period', COUNT(*) FROM poetry_period p LEFT JOIN poetry_dynasty d ON d.id=p.dynasty_id WHERE d.id IS NULL
UNION ALL SELECT 'C4_parent_person_missing_on_experience', COUNT(*) FROM poetry_experience x LEFT JOIN poetry_person p ON p.id=x.person_id WHERE p.id IS NULL
UNION ALL SELECT 'C4_parent_work_missing_on_work_author', COUNT(*) FROM poetry_work_author a LEFT JOIN poetry_work w ON w.id=a.work_id WHERE w.id IS NULL
UNION ALL SELECT 'C4_parent_person_missing_on_work_author', COUNT(*) FROM poetry_work_author a LEFT JOIN poetry_person p ON p.id=a.person_id WHERE p.id IS NULL
UNION ALL SELECT 'C4_claim_missing_on_work_author', COUNT(*) FROM poetry_work_author a LEFT JOIN poetry_claim cl ON cl.id=a.claim_id WHERE cl.id IS NULL
UNION ALL SELECT 'C4_claim_subject_mismatch_on_work_author', COUNT(*) FROM poetry_work_author a JOIN poetry_claim cl ON cl.id=a.claim_id
  WHERE cl.subject_id<>a.work_id OR cl.property_key<>'authorship'
UNION ALL SELECT 'C4_work_missing_on_text_version', COUNT(*) FROM poetry_text_version v LEFT JOIN poetry_work w ON w.id=v.work_id WHERE w.id IS NULL
UNION ALL SELECT 'C4_source_missing_on_text_version', COUNT(*) FROM poetry_text_version v LEFT JOIN poetry_source s ON s.id=v.source_id WHERE s.id IS NULL
UNION ALL SELECT 'C4_version_missing_on_text_line', COUNT(*) FROM poetry_text_line l LEFT JOIN poetry_text_version v ON v.id=l.version_id WHERE v.id IS NULL
UNION ALL SELECT 'C4_text_line_seq_gap', COUNT(*) FROM (SELECT version_id, COUNT(*) AS line_count, MAX(line_seq) AS max_seq FROM poetry_text_line GROUP BY version_id) t
  WHERE t.line_count<>t.max_seq OR t.max_seq<1
UNION ALL SELECT 'C4_line_missing_on_background_line', COUNT(*) FROM poetry_background_line bl
  LEFT JOIN poetry_text_line l ON l.version_id=bl.version_id AND l.line_seq=bl.line_seq WHERE l.version_id IS NULL
UNION ALL SELECT 'C4_background_line_cross_work', COUNT(*) FROM poetry_background_line bl
  JOIN poetry_background b ON b.id=bl.background_id JOIN poetry_text_version v ON v.id=bl.version_id WHERE v.work_id<>b.work_id
UNION ALL SELECT 'C4_background_line_missing_background', COUNT(*) FROM poetry_background_line bl LEFT JOIN poetry_background b ON b.id=bl.background_id WHERE b.id IS NULL
UNION ALL SELECT 'C4_line_missing_on_annotation', COUNT(*) FROM poetry_annotation a
  LEFT JOIN poetry_text_line l ON l.version_id=a.version_id AND l.line_seq=a.line_seq WHERE l.version_id IS NULL
UNION ALL SELECT 'C4_claim_missing_on_annotation', COUNT(*) FROM poetry_annotation a LEFT JOIN poetry_claim cl ON cl.id=a.claim_id WHERE cl.id IS NULL
UNION ALL SELECT 'C4_annotation_claim_subject_mismatch', COUNT(*) FROM poetry_annotation a
  JOIN poetry_text_version v ON v.id=a.version_id JOIN poetry_claim cl ON cl.id=a.claim_id WHERE cl.subject_id<>v.work_id
UNION ALL SELECT 'C4_claim_missing_on_background', COUNT(*) FROM poetry_background b LEFT JOIN poetry_claim cl ON cl.id=b.claim_id WHERE cl.id IS NULL
UNION ALL SELECT 'C4_claim_subject_mismatch_on_background', COUNT(*) FROM poetry_background b JOIN poetry_claim cl ON cl.id=b.claim_id WHERE cl.subject_id<>b.id
UNION ALL SELECT 'C4_work_missing_on_background', COUNT(*) FROM poetry_background b LEFT JOIN poetry_work w ON w.id=b.work_id WHERE w.id IS NULL
UNION ALL SELECT 'C4_claim_missing_on_relation', COUNT(*) FROM poetry_relation r LEFT JOIN poetry_claim cl ON cl.id=r.claim_id WHERE cl.id IS NULL
UNION ALL SELECT 'C4_claim_subject_mismatch_on_relation', COUNT(*) FROM poetry_relation r JOIN poetry_claim cl ON cl.id=r.claim_id WHERE cl.subject_id<>r.subject_id
UNION ALL SELECT 'C4_endpoint_missing_on_relation', COUNT(*) FROM poetry_relation r
  LEFT JOIN poetry_content s ON s.id=r.subject_id LEFT JOIN poetry_content o ON o.id=r.object_id WHERE s.id IS NULL OR o.id IS NULL
UNION ALL SELECT 'C4_source_missing_on_citation', COUNT(*) FROM poetry_citation ci LEFT JOIN poetry_source s ON s.id=ci.source_id WHERE s.id IS NULL
UNION ALL SELECT 'C4_claim_missing_on_citation', COUNT(*) FROM poetry_citation ci LEFT JOIN poetry_claim cl ON cl.id=ci.claim_id WHERE cl.id IS NULL
UNION ALL SELECT 'C4_selection_claim_missing_or_mismatched', COUNT(*) FROM poetry_claim_selection sel
  LEFT JOIN poetry_claim cl ON cl.id=sel.claim_id
  WHERE cl.id IS NULL OR cl.subject_id<>sel.subject_id OR cl.property_key<>sel.property_key
UNION ALL SELECT 'C4_work_missing_on_textbook_work', COUNT(*) FROM poetry_textbook_work tw LEFT JOIN poetry_work w ON w.id=tw.work_id WHERE w.id IS NULL
UNION ALL SELECT 'C4_version_cross_work_on_textbook_work', COUNT(*) FROM poetry_textbook_work tw
  JOIN poetry_text_version v ON v.id=tw.version_id WHERE v.work_id<>tw.work_id
UNION ALL SELECT 'C4_page_locator_blank_on_textbook_work', COUNT(*) FROM poetry_textbook_work tw WHERE TRIM(tw.page_locator)=''

UNION ALL SELECT 'C5_published_content_without_review', COUNT(*) FROM poetry_content c
  WHERE c.status='PUBLISHED' AND (c.reviewed_by IS NULL OR TRIM(c.reviewed_by)='' OR c.reviewed_at IS NULL)
UNION ALL SELECT 'C5_published_claim_without_review', COUNT(*) FROM poetry_claim cl
  WHERE cl.status='PUBLISHED' AND (cl.reviewed_by IS NULL OR TRIM(cl.reviewed_by)='' OR cl.reviewed_at IS NULL)
UNION ALL SELECT 'C5_published_claim_without_verified_citation', COUNT(*) FROM poetry_claim cl
  WHERE cl.status='PUBLISHED' AND cl.claim_kind IN ('FACT','INTERPRETATION') AND NOT EXISTS (
    SELECT 1 FROM poetry_citation ci JOIN poetry_source s ON s.id=ci.source_id
    WHERE ci.claim_id=cl.id AND TRIM(ci.locator)<>'' AND s.verification_status='VERIFIED'
      AND s.verified_by IS NOT NULL AND TRIM(s.verified_by)<>'' AND s.verified_at IS NOT NULL)
UNION ALL SELECT 'C5_published_dramatization_not_labeled', COUNT(*) FROM poetry_claim cl
  WHERE cl.status='PUBLISHED' AND cl.claim_kind='DRAMATIZATION' AND cl.dramatization_labeled<>1
UNION ALL SELECT 'C5_citation_locator_blank', COUNT(*) FROM poetry_citation ci WHERE TRIM(ci.locator)=''
UNION ALL SELECT 'C5_verified_source_without_reviewer', COUNT(*) FROM poetry_source s
  WHERE s.verification_status='VERIFIED' AND (s.verified_by IS NULL OR TRIM(s.verified_by)='' OR s.verified_at IS NULL)
UNION ALL SELECT 'C5_published_version_without_verified_source', COUNT(*) FROM poetry_text_version v
  JOIN poetry_source s ON s.id=v.source_id
  WHERE v.status='PUBLISHED' AND NOT (s.verification_status='VERIFIED' AND s.verified_by IS NOT NULL
    AND TRIM(s.verified_by)<>'' AND s.verified_at IS NOT NULL)
UNION ALL SELECT 'C5_published_version_without_review', COUNT(*) FROM poetry_text_version v
  WHERE v.status='PUBLISHED' AND (v.reviewed_by IS NULL OR TRIM(v.reviewed_by)='' OR v.reviewed_at IS NULL)
UNION ALL SELECT 'C5_published_version_without_lines', COUNT(*) FROM poetry_text_version v
  LEFT JOIN poetry_text_line l ON l.version_id=v.id WHERE v.status='PUBLISHED' AND l.version_id IS NULL
UNION ALL SELECT 'C5_published_work_without_accepted_author', COUNT(*) FROM poetry_work w
  JOIN poetry_content c ON c.id=w.id AND c.status='PUBLISHED'
  WHERE NOT EXISTS (SELECT 1 FROM poetry_work_author a JOIN poetry_claim cl ON cl.id=a.claim_id
    WHERE a.work_id=w.id AND a.attribution IN ('ACCEPTED','DISPUTED') AND cl.status='PUBLISHED')
UNION ALL SELECT 'C5_published_background_without_visible_lines', COUNT(*) FROM poetry_background b
  JOIN poetry_content c ON c.id=b.id AND c.status='PUBLISHED'
  WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line bl JOIN poetry_text_version v ON v.id=bl.version_id
    JOIN poetry_source s ON s.id=v.source_id WHERE bl.background_id=b.id AND v.work_id=b.work_id
    AND v.status='PUBLISHED' AND v.reviewed_by IS NOT NULL AND TRIM(v.reviewed_by)<>'' AND v.reviewed_at IS NOT NULL
    AND s.verification_status='VERIFIED' AND s.verified_by IS NOT NULL AND TRIM(s.verified_by)<>'' AND s.verified_at IS NOT NULL)

UNION ALL SELECT 'C6_time_unknown_with_years', COUNT(*) FROM poetry_content c
  WHERE c.time_precision='UNKNOWN' AND (c.start_year IS NOT NULL OR c.end_year IS NOT NULL)
UNION ALL SELECT 'C6_time_known_missing_bounds', COUNT(*) FROM poetry_content c
  WHERE c.time_precision<>'UNKNOWN' AND (c.start_year IS NULL OR c.end_year IS NULL)
UNION ALL SELECT 'C6_time_reversed_bounds', COUNT(*) FROM poetry_content c
  WHERE c.start_year IS NOT NULL AND c.end_year IS NOT NULL AND c.start_year>c.end_year
UNION ALL SELECT 'C6_time_year_zero', COUNT(*) FROM poetry_content c WHERE c.start_year=0 OR c.end_year=0
UNION ALL SELECT 'C6_time_exact_spans_years', COUNT(*) FROM poetry_content c WHERE c.time_precision='EXACT' AND c.start_year<>c.end_year
UNION ALL SELECT 'C6_published_timed_content_without_adopted_time_claim', COUNT(*) FROM poetry_content c
  WHERE c.status='PUBLISHED' AND c.time_precision<>'UNKNOWN' AND NOT EXISTS (
    SELECT 1 FROM poetry_claim cl JOIN poetry_claim_selection sel ON sel.claim_id=cl.id AND sel.subject_id=cl.subject_id
    WHERE cl.subject_id=c.id AND cl.property_key='time.span' AND cl.claim_kind='FACT' AND cl.status='PUBLISHED')

UNION ALL SELECT 'C7_invalid_content_entity_type', COUNT(*) FROM poetry_content c
  WHERE c.entity_type NOT IN ('DYNASTY','PERIOD','PLACE','PERSON','EVENT','EXPERIENCE','WORK','BACKGROUND','THEME')
UNION ALL SELECT 'C7_invalid_content_status', COUNT(*) FROM poetry_content c
  WHERE c.status NOT IN ('DRAFT','IN_REVIEW','PUBLISHED','RETRACTED')
UNION ALL SELECT 'C7_invalid_time_precision', COUNT(*) FROM poetry_content c
  WHERE c.time_precision NOT IN ('UNKNOWN','EXACT','RANGE','APPROXIMATE')
UNION ALL SELECT 'C7_invalid_claim_status', COUNT(*) FROM poetry_claim cl
  WHERE cl.status NOT IN ('DRAFT','IN_REVIEW','PUBLISHED','RETRACTED')
UNION ALL SELECT 'C7_invalid_claim_kind', COUNT(*) FROM poetry_claim cl
  WHERE cl.claim_kind NOT IN ('FACT','INTERPRETATION','DRAMATIZATION')
UNION ALL SELECT 'C7_invalid_certainty', COUNT(*) FROM poetry_claim cl
  WHERE cl.certainty NOT IN ('KNOWN','LIKELY','DISPUTED','UNKNOWN')
UNION ALL SELECT 'C7_invalid_source_verification_status', COUNT(*) FROM poetry_source s
  WHERE s.verification_status NOT IN ('PENDING','VERIFIED','REJECTED')
UNION ALL SELECT 'C7_invalid_text_version_status', COUNT(*) FROM poetry_text_version v
  WHERE v.status NOT IN ('DRAFT','IN_REVIEW','PUBLISHED','RETRACTED')
UNION ALL SELECT 'C7_invalid_script', COUNT(*) FROM poetry_text_version v WHERE v.script NOT IN ('SIMPLIFIED','TRADITIONAL')
UNION ALL SELECT 'C7_invalid_attribution', COUNT(*) FROM poetry_work_author a
  WHERE a.attribution NOT IN ('PENDING','ACCEPTED','DISPUTED','REJECTED')
UNION ALL SELECT 'C7_invalid_audience', COUNT(*) FROM poetry_annotation a
  WHERE a.audience NOT IN ('PRIMARY','JUNIOR','SENIOR')
UNION ALL SELECT 'C7_invalid_background_layer', COUNT(*) FROM poetry_background b
  WHERE b.layer NOT IN ('SCENE','CITY','WORLD','PERSON')

-- ---- added by V003 (theme / coverage / review log / source grading / background body) ----
UNION ALL SELECT 'C1_orphan_theme', COUNT(*) FROM poetry_theme x LEFT JOIN poetry_content c ON c.id=x.id WHERE c.id IS NULL
UNION ALL SELECT 'C2_type_mismatch_theme', COUNT(*) FROM poetry_theme x JOIN poetry_content c ON c.id=x.id WHERE c.entity_type<>'THEME'
UNION ALL SELECT 'C3_declared_theme_without_child_row', COUNT(*) FROM poetry_content c
  LEFT JOIN poetry_theme t ON t.id=c.id WHERE c.entity_type='THEME' AND t.id IS NULL

UNION ALL SELECT 'C4_parent_place_missing_on_place', COUNT(*) FROM poetry_place p
  LEFT JOIN poetry_place q ON q.id=p.parent_id WHERE p.parent_id IS NOT NULL AND q.id IS NULL
UNION ALL SELECT 'C4_place_parent_is_self', COUNT(*) FROM poetry_place p WHERE p.parent_id=p.id
UNION ALL SELECT 'C4_theme_missing_on_theme_item', COUNT(*) FROM poetry_theme_item ti
  LEFT JOIN poetry_theme t ON t.id=ti.theme_id WHERE t.id IS NULL
UNION ALL SELECT 'C4_item_missing_on_theme_item', COUNT(*) FROM poetry_theme_item ti
  LEFT JOIN poetry_content o ON o.id=ti.item_id WHERE o.id IS NULL
UNION ALL SELECT 'C4_theme_item_points_at_itself', COUNT(*) FROM poetry_theme_item ti WHERE ti.item_id=ti.theme_id
UNION ALL SELECT 'C4_period_scope_missing_on_theme', COUNT(*) FROM poetry_theme t
  LEFT JOIN poetry_content c ON c.id=t.period_scope WHERE t.period_scope IS NOT NULL AND c.id IS NULL
UNION ALL SELECT 'C4_period_scope_wrong_type_on_theme', COUNT(*) FROM poetry_theme t
  JOIN poetry_content c ON c.id=t.period_scope WHERE c.entity_type<>'PERIOD'
UNION ALL SELECT 'C4_review_subject_missing_on_review_log', COUNT(*) FROM poetry_review_log rl
  LEFT JOIN poetry_content c ON c.id=rl.subject_id WHERE rl.subject_table='poetry_content' AND c.id IS NULL
UNION ALL SELECT 'C4_claim_missing_on_review_log', COUNT(*) FROM poetry_review_log rl
  LEFT JOIN poetry_claim cl ON cl.id=rl.subject_id WHERE rl.subject_table='poetry_claim' AND cl.id IS NULL
UNION ALL SELECT 'C4_version_missing_on_review_log', COUNT(*) FROM poetry_review_log rl
  LEFT JOIN poetry_text_version v ON v.id=rl.subject_id WHERE rl.subject_table='poetry_text_version' AND v.id IS NULL
UNION ALL SELECT 'C4_source_missing_on_review_log', COUNT(*) FROM poetry_review_log rl
  LEFT JOIN poetry_source s ON s.id=rl.subject_id WHERE rl.subject_table='poetry_source' AND s.id IS NULL
UNION ALL SELECT 'C4_reviewer_blank_on_review_log', COUNT(*) FROM poetry_review_log rl WHERE TRIM(rl.reviewer)=''

UNION ALL SELECT 'C5_published_background_without_body', COUNT(*) FROM poetry_background b
  JOIN poetry_content c ON c.id=b.id AND c.status='PUBLISHED'
  WHERE b.body_text IS NULL OR TRIM(b.body_text)=''
UNION ALL SELECT 'C5_published_background_without_audience', COUNT(*) FROM poetry_background b
  JOIN poetry_content c ON c.id=b.id AND c.status='PUBLISHED'
  WHERE b.audience IS NULL OR b.audience NOT IN ('PRIMARY','JUNIOR','SENIOR')
UNION ALL SELECT 'C5_verified_source_without_grading', COUNT(*) FROM poetry_source s
  WHERE s.verification_status='VERIFIED' AND (s.source_kind IS NULL OR TRIM(s.source_kind)=''
    OR s.reliability IS NULL OR TRIM(s.reliability)='')
UNION ALL SELECT 'C5_published_theme_with_fewer_than_two_published_items', COUNT(*) FROM poetry_content c
  JOIN poetry_theme t ON t.id=c.id
  WHERE c.entity_type='THEME' AND c.status='PUBLISHED' AND c.reviewed_by IS NOT NULL
    AND TRIM(c.reviewed_by)<>'' AND c.reviewed_at IS NOT NULL
    AND (SELECT COUNT(*) FROM poetry_theme_item ti JOIN poetry_content o ON o.id=ti.item_id
      WHERE ti.theme_id=c.id AND o.status='PUBLISHED' AND o.reviewed_by IS NOT NULL
        AND TRIM(o.reviewed_by)<>'' AND o.reviewed_at IS NOT NULL) < 2
UNION ALL SELECT 'C5_published_content_without_review_log', COUNT(*) FROM poetry_content c
  WHERE c.status='PUBLISHED' AND NOT EXISTS (SELECT 1 FROM poetry_review_log rl
    WHERE rl.subject_table='poetry_content' AND rl.subject_id=c.id)

UNION ALL SELECT 'C6_coverage_reversed_range', COUNT(*) FROM poetry_coverage v WHERE v.from_year>v.to_year
UNION ALL SELECT 'C6_coverage_year_zero', COUNT(*) FROM poetry_coverage v WHERE v.from_year=0 OR v.to_year=0

UNION ALL SELECT 'C7_invalid_source_kind', COUNT(*) FROM poetry_source s
  WHERE s.source_kind IS NOT NULL AND s.source_kind NOT IN
    ('OFFICIAL_HISTORY','YEAR_BOOK','ANTHOLOGY','TEXTBOOK','MODERN_STUDY','DIGITIZED_TEXT','ONLINE_ENTRY','OTHER')
UNION ALL SELECT 'C7_invalid_reliability', COUNT(*) FROM poetry_source s
  WHERE s.reliability IS NOT NULL AND s.reliability NOT IN ('HIGH','MEDIUM','LOW','UNKNOWN')
UNION ALL SELECT 'C7_invalid_coverage_entity_type', COUNT(*) FROM poetry_coverage v
  WHERE v.entity_type NOT IN ('DYNASTY','PERIOD','PLACE','PERSON','EVENT','EXPERIENCE','WORK','BACKGROUND','THEME')
UNION ALL SELECT 'C7_invalid_coverage_kind', COUNT(*) FROM poetry_coverage v
  WHERE v.coverage_kind NOT IN ('FULL','PARTIAL','PLANNED')
UNION ALL SELECT 'C7_invalid_coverage_status', COUNT(*) FROM poetry_coverage v
  WHERE v.status NOT IN ('DRAFT','IN_REVIEW','PUBLISHED','RETRACTED')
UNION ALL SELECT 'C7_invalid_review_decision', COUNT(*) FROM poetry_review_log rl
  WHERE rl.decision NOT IN ('SUBMITTED','CHANGES_REQUESTED','APPROVED','REJECTED','PUBLISHED','RETRACTED','REOPENED')
UNION ALL SELECT 'C7_invalid_theme_item_role', COUNT(*) FROM poetry_theme_item ti
  WHERE ti.item_role NOT IN ('ANCHOR','MEMBER','CONTEXT')
UNION ALL SELECT 'C7_invalid_background_audience', COUNT(*) FROM poetry_background b
  WHERE b.audience IS NOT NULL AND b.audience NOT IN ('PRIMARY','JUNIOR','SENIOR')
UNION ALL SELECT 'C7_invalid_annotation_kind', COUNT(*) FROM poetry_annotation a
  WHERE a.annotation_kind NOT IN ('WORD','PHRASE','ALLUSION','IMAGE','RHYME','OTHER')
UNION ALL SELECT 'C5_citation_locator_placeholder_on_published_claim', COUNT(*) FROM poetry_citation ci
  WHERE (ci.locator LIKE '待%' OR ci.locator LIKE '%待核查%' OR ci.locator LIKE '%待人工%' OR ci.locator LIKE '%未核对%'
    OR ci.locator LIKE '%DEMO%' OR ci.locator LIKE '%演练%')
    AND EXISTS (SELECT 1 FROM poetry_claim cl WHERE cl.id=ci.claim_id AND cl.status='PUBLISHED')
UNION ALL SELECT 'C5_demo_verified_source_would_publish', COUNT(*) FROM poetry_source s
  WHERE s.verification_status='VERIFIED' AND (s.verified_by LIKE 'DEMO%' OR s.rights_note LIKE '%DEMO%')
-- C8 media/script referential integrity (V006). With no foreign keys, these are the substitute.
UNION ALL SELECT 'C8_asset_missing_fallback_non_l0', COUNT(*) FROM poetry_asset a
  WHERE a.level<>'L0' AND (a.fallback_id IS NULL OR a.fallback_id='')
UNION ALL SELECT 'C8_asset_fallback_points_nowhere', COUNT(*) FROM poetry_asset a
  LEFT JOIN poetry_asset f ON f.id=a.fallback_id
  WHERE a.fallback_id IS NOT NULL AND a.fallback_id<>'' AND f.id IS NULL
UNION ALL SELECT 'C8_asset_fallback_not_lower_level', COUNT(*) FROM poetry_asset a
  JOIN poetry_asset f ON f.id=a.fallback_id
  WHERE f.level NOT IN ('L0','L1','L2','L3','L4')
     OR (a.level='L4' AND f.level='L4') OR (a.level='L3' AND f.level IN ('L3','L4'))
     OR (a.level='L2' AND f.level IN ('L2','L3','L4')) OR (a.level='L1' AND f.level IN ('L1','L2','L3','L4'))
UNION ALL SELECT 'C8_asset_empty_meaning', COUNT(*) FROM poetry_asset a WHERE TRIM(a.meaning)=''
UNION ALL SELECT 'C8_asset_missing_rights', COUNT(*) FROM poetry_asset a
  WHERE TRIM(a.rights_origin)='' OR TRIM(a.rights_license)=''
UNION ALL SELECT 'C8_asset_bad_hash', COUNT(*) FROM poetry_asset a
  WHERE a.hash NOT REGEXP '^[a-f0-9]{12,64}$'
UNION ALL SELECT 'C8_asset_hash_duplicate_row', COUNT(*) FROM
  (SELECT hash FROM poetry_asset GROUP BY hash HAVING COUNT(*)>1) d
UNION ALL SELECT 'C8_script_missing_work', COUNT(*) FROM poetry_script s
  LEFT JOIN poetry_content c ON c.id=s.work_id WHERE c.id IS NULL OR c.entity_type<>'WORK'
UNION ALL SELECT 'C8_script_missing_text_version', COUNT(*) FROM poetry_script s
  LEFT JOIN poetry_text_version v ON v.id=s.text_version_id WHERE v.id IS NULL
UNION ALL SELECT 'C8_script_text_version_wrong_work', COUNT(*) FROM poetry_script s
  JOIN poetry_text_version v ON v.id=s.text_version_id WHERE v.work_id<>s.work_id
UNION ALL SELECT 'C8_script_empty_coverage_notice', COUNT(*) FROM poetry_script s
  WHERE TRIM(s.coverage_notice)=''
UNION ALL SELECT 'C8_published_script_without_bundle', COUNT(*) FROM poetry_script s
  WHERE s.status='PUBLISHED' AND (s.bundle_hash IS NULL OR TRIM(s.bundle_hash)='')
UNION ALL SELECT 'C8_published_script_on_draft_text_version', COUNT(*) FROM poetry_script s
  JOIN poetry_text_version v ON v.id=s.text_version_id
  WHERE s.status='PUBLISHED' AND v.status<>'PUBLISHED'
UNION ALL SELECT 'C8_published_script_draft_asset', COUNT(*) FROM poetry_script_asset sa
  JOIN poetry_script s ON s.id=sa.script_id AND s.script_version=sa.script_version
  JOIN poetry_asset a ON a.id=sa.asset_id
  WHERE s.status='PUBLISHED' AND a.status<>'PUBLISHED'
UNION ALL SELECT 'C8_script_asset_orphan', COUNT(*) FROM poetry_script_asset sa
  LEFT JOIN poetry_script s ON s.id=sa.script_id AND s.script_version=sa.script_version
  LEFT JOIN poetry_asset a ON a.id=sa.asset_id WHERE s.id IS NULL OR a.id IS NULL
UNION ALL SELECT 'C8_script_asset_bad_step', COUNT(*) FROM poetry_script_asset sa
  WHERE sa.step NOT IN ('read','arrive','meet','return','recite')
UNION ALL SELECT 'C8_invalid_asset_level', COUNT(*) FROM poetry_asset a
  WHERE a.level NOT IN ('L0','L1','L2','L3','L4')
UNION ALL SELECT 'C8_invalid_asset_kind', COUNT(*) FROM poetry_asset a
  WHERE a.kind NOT IN ('illustration','map','character','audio','voice','subtitle','video')
UNION ALL SELECT 'C8_invalid_asset_status', COUNT(*) FROM poetry_asset a
  WHERE a.status NOT IN ('DRAFT','PUBLISHED','RETIRED')
UNION ALL SELECT 'C8_invalid_script_status', COUNT(*) FROM poetry_script s
  WHERE s.status NOT IN ('DRAFT','PUBLISHED','RETIRED')
-- C9 Agent domain integrity (V007/V008). Associations are conventions; no SQL foreign keys exist.
UNION ALL SELECT 'C9_agent_task_missing_work', COUNT(*) FROM poetry_agent_task t
  LEFT JOIN poetry_content w ON w.id=t.work_id WHERE w.id IS NULL OR w.entity_type<>'WORK'
UNION ALL SELECT 'C9_agent_run_missing_task', COUNT(*) FROM poetry_agent_run r
  LEFT JOIN poetry_agent_task t ON t.id=r.task_id WHERE t.id IS NULL
UNION ALL SELECT 'C9_agent_task_bad_orchestration_state', COUNT(*) FROM poetry_agent_task t
  WHERE t.status NOT IN ('CREATED','RUNNING','WAITING_FOR_RUNTIME','AWAITING_REVIEW','COMPLETED','FAILED')
     OR t.requested_role NOT IN ('CONTENT_EDITOR','HISTORICAL_REVIEWER','RELEASE_MANAGER','PLATFORM_ADMIN')
UNION ALL SELECT 'C9_agent_task_active_run_mismatch', COUNT(*) FROM poetry_agent_task t
  LEFT JOIN poetry_agent_run r ON r.id=t.active_run_id AND r.task_id=t.id
  WHERE t.active_run_id IS NOT NULL AND r.id IS NULL
UNION ALL SELECT 'C9_agent_run_missing_mandate', COUNT(*) FROM poetry_agent_run r
  LEFT JOIN poetry_agent_mandate m ON m.run_id=r.id AND m.mandate_id=r.mandate_id
  WHERE m.run_id IS NULL
UNION ALL SELECT 'C9_agent_run_bad_orchestration_state', COUNT(*) FROM poetry_agent_run r
  WHERE r.status NOT IN ('RUNNING','WAITING_FOR_RUNTIME','AWAITING_REVIEW','COMPLETED','FAILED')
     OR r.runtime NOT IN ('DEERFLOW','STUB')
UNION ALL SELECT 'C9_agent_mandate_bad_role', COUNT(*) FROM poetry_agent_mandate m
  WHERE m.actor_role NOT IN ('CONTENT_EDITOR','HISTORICAL_REVIEWER') OR m.status NOT IN ('ACTIVE','REVOKED','COMPLETED')
UNION ALL SELECT 'C9_agent_mandate_missing_work', COUNT(*) FROM poetry_agent_mandate m
  LEFT JOIN poetry_content w ON w.id=m.work_id WHERE w.id IS NULL OR w.entity_type<>'WORK'
UNION ALL SELECT 'C9_agent_proposal_missing_work', COUNT(*) FROM poetry_agent_proposal p
  LEFT JOIN poetry_content w ON w.id=p.work_id WHERE w.id IS NULL OR w.entity_type<>'WORK'
UNION ALL SELECT 'C9_agent_proposal_missing_mandate', COUNT(*) FROM poetry_agent_proposal p
  LEFT JOIN poetry_agent_mandate m ON m.run_id=p.run_id AND m.mandate_id=p.mandate_id AND m.work_id=p.work_id WHERE m.run_id IS NULL
UNION ALL SELECT 'C9_agent_proposal_bad_state', COUNT(*) FROM poetry_agent_proposal p
  WHERE p.status NOT IN ('DRAFT','APPLIED') OR p.review_status NOT IN ('PENDING','APPROVED','REJECTED')
UNION ALL SELECT 'C9_agent_applied_without_approval', COUNT(*) FROM poetry_agent_proposal p
  WHERE p.status='APPLIED' AND (p.review_status<>'APPROVED' OR p.applied_at IS NULL)
UNION ALL SELECT 'C9_agent_review_missing_proposal', COUNT(*) FROM poetry_agent_review r
  LEFT JOIN poetry_agent_proposal p ON p.id=r.proposal_id WHERE p.id IS NULL
UNION ALL SELECT 'C9_agent_review_bad_decision', COUNT(*) FROM poetry_agent_review r
  WHERE r.decision NOT IN ('APPROVE','REJECT')
UNION ALL SELECT 'C9_agent_receipt_missing_mandate', COUNT(*) FROM poetry_agent_tool_receipt r
  LEFT JOIN poetry_agent_mandate m ON m.run_id=r.run_id AND m.mandate_id=r.mandate_id WHERE m.run_id IS NULL
UNION ALL SELECT 'C9_agent_compile_missing_work', COUNT(*) FROM poetry_agent_compile_request c
  LEFT JOIN poetry_content w ON w.id=c.work_id WHERE w.id IS NULL OR w.entity_type<>'WORK'
UNION ALL SELECT 'C9_agent_compile_missing_mandate', COUNT(*) FROM poetry_agent_compile_request c
  LEFT JOIN poetry_agent_mandate m ON m.run_id=c.run_id AND m.mandate_id=c.mandate_id AND m.work_id=c.work_id WHERE m.run_id IS NULL
UNION ALL SELECT 'C9_agent_compile_bad_status', COUNT(*) FROM poetry_agent_compile_request c
  WHERE c.status NOT IN ('PENDING_REVIEW','BLOCKED','COMPLETED','REJECTED');
