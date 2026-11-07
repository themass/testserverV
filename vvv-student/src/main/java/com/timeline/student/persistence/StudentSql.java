package com.timeline.student.persistence;

/**
 * Publish predicates for the few poetry_* reads this module cannot get from PoetryCatalog.
 *
 * These deliberately repeat the shape of vvv-poetry's PoetrySql (which is package-private) and are
 * deliberately NOT looser anywhere. They exist only until vvv-poetry exposes published annotations and
 * published scripts as public read methods (docs/handoff/B-needs-from-java.md, item 1). When that lands,
 * delete this class and the two content queries that use it. StudentSqlGuardTest fails if any
 * poetry_* query here loses its PUBLISHED condition.
 */
final class StudentSql {
    private StudentSql() {}

    static final String PUBLIC_WORK = "w.entity_type='WORK' AND w.status='PUBLISHED' AND w.reviewed_by IS NOT NULL "
        + "AND TRIM(w.reviewed_by)!='' AND w.reviewed_at IS NOT NULL";

    static final String VERIFIED_SOURCE = "s.verification_status='VERIFIED' AND s.verified_by IS NOT NULL "
        + "AND TRIM(s.verified_by)!='' AND s.verified_at IS NOT NULL";

    static final String PUBLIC_VERSION = "v.status='PUBLISHED' AND v.reviewed_by IS NOT NULL "
        + "AND TRIM(v.reviewed_by)!='' AND v.reviewed_at IS NOT NULL AND " + VERIFIED_SOURCE;

    /** A claim is public when published+reviewed and either a labelled dramatization or backed by a verified citation. */
    static final String PUBLIC_CLAIM = "cl.status='PUBLISHED' AND cl.reviewed_by IS NOT NULL "
        + "AND TRIM(cl.reviewed_by)!='' AND cl.reviewed_at IS NOT NULL AND ("
        + "(cl.claim_kind='DRAMATIZATION' AND cl.dramatization_labeled=1) OR "
        + "(cl.claim_kind IN ('FACT','INTERPRETATION') AND EXISTS (SELECT 1 FROM poetry_citation ci "
        + "JOIN poetry_source s2 ON s2.id=ci.source_id WHERE ci.claim_id=cl.id AND TRIM(ci.locator)!='' "
        + "AND s2.verification_status='VERIFIED' AND s2.verified_by IS NOT NULL "
        + "AND TRIM(s2.verified_by)!='' AND s2.verified_at IS NOT NULL)))";

    /** A script is servable only when published, compiled (has a bundle hash) and its work is published. */
    static final String PUBLIC_SCRIPT = "sc.status='PUBLISHED' AND sc.bundle_hash IS NOT NULL "
        + "AND TRIM(sc.bundle_hash)!='' AND EXISTS (SELECT 1 FROM poetry_content w WHERE w.id=sc.work_id AND "
        + PUBLIC_WORK + ")";
}
