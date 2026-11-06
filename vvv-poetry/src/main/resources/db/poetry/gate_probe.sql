-- Read-gate probe: the exact SQL the API runs, executed straight against the database.
-- Expected answers in a DRAFT-only library (V001..V004, nothing published):
--   contents=0 lines=0 versions=0 authors=0 backgrounds=0 themeItems=0 timeline_755_760=0 coverage=2
-- Expected answers right after demo_publish_chunwang.sql:
--   lines=8 versions=1 authors=1 timeline_755_760=3  backgrounds=0 themeItems=0 coverage=2
-- (3 = 春望757 + 杜甫712..770 + 唐618..907 三段都与 755..760 重叠)
-- (backgrounds and the theme line stay hidden because their evidence is still unverified:
--  that is the gate working, not a bug.)
SELECT 'lines' AS probe, COUNT(*) AS n FROM poetry_text_line l
  JOIN poetry_text_version v ON v.id=l.version_id
  JOIN poetry_content c ON c.id=v.work_id AND c.entity_type='WORK'
  JOIN poetry_source s ON s.id=v.source_id
  WHERE c.status='PUBLISHED' AND c.reviewed_by IS NOT NULL AND TRIM(c.reviewed_by)!='' AND c.reviewed_at IS NOT NULL
    AND v.status='PUBLISHED' AND v.reviewed_by IS NOT NULL AND TRIM(v.reviewed_by)!='' AND v.reviewed_at IS NOT NULL
    AND s.verification_status='VERIFIED' AND s.verified_by IS NOT NULL AND TRIM(s.verified_by)!='' AND s.verified_at IS NOT NULL
    AND l.version_id='text-chun-wang-draft'
UNION ALL SELECT 'versions', COUNT(*) FROM poetry_text_version v
  JOIN poetry_content c ON c.id=v.work_id AND c.entity_type='WORK'
  JOIN poetry_source s ON s.id=v.source_id
  WHERE c.status='PUBLISHED' AND c.reviewed_by IS NOT NULL AND TRIM(c.reviewed_by)!='' AND c.reviewed_at IS NOT NULL
    AND v.status='PUBLISHED' AND v.reviewed_by IS NOT NULL AND TRIM(v.reviewed_by)!='' AND v.reviewed_at IS NOT NULL
    AND s.verification_status='VERIFIED' AND s.verified_by IS NOT NULL AND TRIM(s.verified_by)!='' AND s.verified_at IS NOT NULL
    AND v.work_id='work-chun-wang'
UNION ALL SELECT 'authors', COUNT(*) FROM poetry_work_author a
  JOIN poetry_content c ON c.id=a.work_id AND c.entity_type='WORK'
  JOIN poetry_content p ON p.id=a.person_id AND p.entity_type='PERSON'
  JOIN poetry_claim cl ON cl.id=a.claim_id AND cl.subject_id=a.work_id AND cl.property_key='authorship'
  WHERE c.status='PUBLISHED' AND c.reviewed_by IS NOT NULL AND TRIM(c.reviewed_by)!='' AND c.reviewed_at IS NOT NULL
    AND p.status='PUBLISHED' AND p.reviewed_by IS NOT NULL AND TRIM(p.reviewed_by)!='' AND p.reviewed_at IS NOT NULL
    AND cl.status='PUBLISHED' AND cl.reviewed_by IS NOT NULL AND TRIM(cl.reviewed_by)!='' AND cl.reviewed_at IS NOT NULL
    AND a.attribution IN ('ACCEPTED','DISPUTED') AND a.work_id='work-chun-wang'
UNION ALL SELECT 'backgrounds', COUNT(*) FROM poetry_background b
  JOIN poetry_content c ON c.id=b.id AND c.entity_type='BACKGROUND'
  JOIN poetry_content w ON w.id=b.work_id AND w.entity_type='WORK'
  JOIN poetry_claim cl ON cl.id=b.claim_id AND cl.subject_id=b.id
  WHERE c.status='PUBLISHED' AND c.reviewed_by IS NOT NULL AND TRIM(c.reviewed_by)!='' AND c.reviewed_at IS NOT NULL
    AND w.status='PUBLISHED' AND w.reviewed_by IS NOT NULL AND TRIM(w.reviewed_by)!='' AND w.reviewed_at IS NOT NULL
    AND cl.status='PUBLISHED' AND cl.reviewed_by IS NOT NULL AND TRIM(cl.reviewed_by)!='' AND cl.reviewed_at IS NOT NULL
    AND b.work_id='work-chun-wang'
UNION ALL SELECT 'themeItems', COUNT(*) FROM poetry_theme_item ti
  JOIN poetry_theme t ON t.id=ti.theme_id
  JOIN poetry_content c ON c.id=ti.theme_id AND c.entity_type='THEME'
  JOIN poetry_content o ON o.id=ti.item_id
  WHERE c.status='PUBLISHED' AND c.reviewed_by IS NOT NULL AND TRIM(c.reviewed_by)!='' AND c.reviewed_at IS NOT NULL
    AND o.status='PUBLISHED' AND o.reviewed_by IS NOT NULL AND TRIM(o.reviewed_by)!='' AND o.reviewed_at IS NOT NULL
    AND ti.theme_id='theme-anshi-rebellion'
UNION ALL SELECT 'timeline_755_760', COUNT(*) FROM poetry_content c
  WHERE c.status='PUBLISHED' AND c.reviewed_by IS NOT NULL AND TRIM(c.reviewed_by)!='' AND c.reviewed_at IS NOT NULL
    AND c.time_precision!='UNKNOWN' AND c.start_year IS NOT NULL AND c.end_year IS NOT NULL
    AND c.start_year<=760 AND c.end_year>=755
UNION ALL SELECT 'coverage', COUNT(*) FROM poetry_coverage v WHERE v.status='PUBLISHED';
