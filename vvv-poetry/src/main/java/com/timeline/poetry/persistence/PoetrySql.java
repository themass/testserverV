package com.timeline.poetry.persistence;

final class PoetrySql {
    private PoetrySql() {}
    static final String COLUMNS = "c.id,c.entity_type,c.slug,c.title,c.summary,c.start_year,c.end_year,c.time_precision,c.revision";
    static final String PUBLIC_CONTENT = "c.status='PUBLISHED' AND c.reviewed_by IS NOT NULL "
        + "AND TRIM(c.reviewed_by)!='' AND c.reviewed_at IS NOT NULL";
    static final String VERIFIED_SOURCE = "s.verification_status='VERIFIED' AND s.verified_by IS NOT NULL "
        + "AND TRIM(s.verified_by)!='' AND s.verified_at IS NOT NULL";
    static final String PUBLIC_CLAIM = "cl.status='PUBLISHED' AND cl.reviewed_by IS NOT NULL "
        + "AND TRIM(cl.reviewed_by)!='' AND cl.reviewed_at IS NOT NULL AND ("
        + "(cl.claim_kind='DRAMATIZATION' AND cl.dramatization_labeled=1) OR "
        + "(cl.claim_kind IN ('FACT','INTERPRETATION') AND EXISTS (SELECT 1 FROM poetry_citation ci "
        + "JOIN poetry_source s ON s.id=ci.source_id WHERE ci.claim_id=cl.id AND TRIM(ci.locator)!='' AND "
        + VERIFIED_SOURCE + ")))";
    static final String PUBLIC_VERSION = "v.status='PUBLISHED' AND v.reviewed_by IS NOT NULL "
        + "AND TRIM(v.reviewed_by)!='' AND v.reviewed_at IS NOT NULL AND " + VERIFIED_SOURCE;
    static final String PAGE = " LIMIT #{fetchLimit} OFFSET #{offset}";
}
