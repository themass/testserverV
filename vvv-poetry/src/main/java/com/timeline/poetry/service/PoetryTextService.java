package com.timeline.poetry.service;

import com.timeline.poetry.api.PoetryDraftModels.*;
import com.timeline.poetry.domain.Vocabulary;
import com.timeline.poetry.persistence.PoetryDraftWriter;
import com.timeline.poetry.persistence.PoetryDraftWriter2;
import com.timeline.poetry.service.PoetryDraftService.Dirty;
import com.timeline.poetry.service.PoetryDraftService.Invalid;
import org.springframework.transaction.annotation.Transactional;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/**
 * Slice-2 authoring: text versions and their lines, the four background layers, background->line links,
 * annotations, relations, authorship and textbook placements.
 *
 * The hard part is not the INSERT: it is ordering. background.claim_id is NOT NULL while the claim's
 * subject must be the background itself, so the content row, the claim and the background row are
 * created inside ONE transaction. Because there are no foreign keys, the 106 audit checks are the only
 * net that catches a mistake, so they run before commit and a dirty result rolls the whole write back.
 */
public class PoetryTextService {
    private static final String ID_PATTERN = "[A-Za-z][A-Za-z0-9_-]{1,63}";

    private final PoetryDraftWriter2 w2;
    private final PoetryDraftWriter w1;
    private final AuditRunner audit;

    public PoetryTextService(PoetryDraftWriter2 w2, PoetryDraftWriter w1, AuditRunner audit) {
        this.w2 = w2; this.w1 = w1; this.audit = audit;
    }

    // ---------------------------------------------------------------- text version + lines

    @Transactional
    public Written createVersion(VersionCreate v) {
        id(v.id());
        requireWork(v.workId());
        if (orZero(w2.existsVersion(v.id())) > 0) throw new Invalid("version id already exists: " + v.id());
        if (v.versionCode() == null || v.versionCode().isBlank()) throw new Invalid("version_code is required");
        if (v.label() == null || v.label().isBlank()) throw new Invalid("label is required");
        if (!Vocabulary.isMember(Vocabulary.SCRIPTS, upper(v.script())))
            throw new Invalid("script outside vocabulary: " + v.script() + " (SIMPLIFIED/TRADITIONAL)");
        if (orZero(w1.existsSource(v.sourceId())) == 0)
            throw new Invalid("source not found (录入顺序：先 source 后 text_version): " + v.sourceId());
        if (v.sourceLocator() == null || v.sourceLocator().isBlank())
            throw new Invalid("source_locator is required: a text version without a page reference cannot be verified");
        VersionCreate stored = new VersionCreate(v.id(), v.workId(), v.versionCode().trim(), v.label().trim(),
            upper(v.script()), v.sourceId(), v.sourceLocator().trim());
        w2.insertVersion(stored);
        return done("poetry_text_version/" + v.id(), List.of(
            "定本还没有行：用 POST /draft/version/{id}/lines 逐句录入；没有行的定本不能发布。"));
    }

    @Transactional
    public Written updateVersion(String id, VersionUpdate u) {
        id(id);
        if (w2.draftVersion(id) == null) throw new Invalid("version not found: " + id);
        if (u.label() == null || u.label().isBlank()) throw new Invalid("label is required");
        if (u.sourceId() != null && orZero(w1.existsSource(u.sourceId())) == 0)
            throw new Invalid("source not found: " + u.sourceId());
        VersionUpdate stored = new VersionUpdate(u.label().trim(),
            u.sourceId() == null ? w2.draftVersion(id).sourceId() : u.sourceId(),
            u.sourceLocator() == null || u.sourceLocator().isBlank() ? w2.draftVersion(id).sourceLocator() : u.sourceLocator().trim());
        w2.updateVersion(id, stored);
        return done("poetry_text_version/" + id, List.of());
    }

    public List<DraftVersion> versions(String workId) { return List.copyOf(w2.versionsOf(workId)); }
    public DraftVersion version(String id) { return w2.draftVersion(id); }
    public List<DraftLine> lines(String versionId) { return List.copyOf(w2.linesOf(versionId)); }

    /** Lines are appended, never inserted in the middle: a gap in line_seq breaks C4_text_line_seq_gap. */
    @Transactional
    public Written addLine(String versionId, LineWrite line) {
        id(versionId);
        if (orZero(w2.existsVersion(versionId)) == 0) throw new Invalid("version not found: " + versionId);
        if (line.content() == null || line.content().isBlank()) throw new Invalid("line content is required");
        int next = orZero(w2.maxLineSeq(versionId)) + 1;
        int seq = line.lineSeq() == null ? next : line.lineSeq();
        if (seq != next)
            throw new Invalid("line_seq must be " + next + " (append only: gaps and mid-insertions break the audit check)");
        w2.insertLine(new LineWrite(versionId, seq, line.content().trim(), line.pinyin()));
        return done("poetry_text_line/" + versionId + "/" + seq, List.of());
    }

    @Transactional
    public Written updateLine(LineWrite line) {
        id(line.versionId());
        if (line.lineSeq() == null) throw new Invalid("line_seq is required");
        if (line.content() == null || line.content().isBlank()) throw new Invalid("line content is required");
        if (orZero(w2.existsLine(line.versionId(), line.lineSeq())) == 0)
            throw new Invalid("line not found: " + line.versionId() + "#" + line.lineSeq());
        w2.updateLine(new LineWrite(line.versionId(), line.lineSeq(), line.content().trim(), line.pinyin()));
        return done("poetry_text_line/" + line.versionId() + "/" + line.lineSeq(), List.of());
    }

    // ---------------------------------------------------------------- background (one of the four layers)

    /** content row + its claim + the background row are created together: background.claim_id is NOT NULL. */
    @Transactional
    public Written createBackground(BackgroundWrite b) {
        id(b.id());
        requireWork(b.workId());
        if (orZero(w1.existsContent(b.id())) > 0) throw new Invalid("id already exists: " + b.id());
        if (b.title() == null || b.title().isBlank()) throw new Invalid("title is required");
        if (b.bodyText() == null || b.bodyText().isBlank()) throw new Invalid("body_text is required");
        if (!Vocabulary.isMember(Vocabulary.LAYERS, upper(b.layer())))
            throw new Invalid("layer outside vocabulary: " + b.layer() + " (SCENE/CITY/WORLD/PERSON)");
        if (b.audience() != null && !Vocabulary.isMember(Vocabulary.AUDIENCES, upper(b.audience())))
            throw new Invalid("audience outside vocabulary: " + b.audience());
        String kind = upper(b.claimKind()) == null ? "FACT" : upper(b.claimKind());
        if (!"FACT".equals(kind) && !"INTERPRETATION".equals(kind))
            throw new Invalid("background claim_kind must be FACT or INTERPRETATION, got " + b.claimKind()
                + " (演绎属于台词层，不属于背景层)");
        id(b.claimId());
        if (orZero(w1.existsClaim(b.claimId())) > 0) throw new Invalid("claim id already exists: " + b.claimId());
        if (b.claimValue() == null || b.claimValue().isBlank()) throw new Invalid("claim value is required");
        String certainty = upper(b.certainty()) == null ? "KNOWN" : upper(b.certainty());
        if (!Vocabulary.isMember(Vocabulary.CERTAINTIES, certainty))
            throw new Invalid("certainty outside vocabulary: " + b.certainty());

        w2.insertBackgroundContent(b.id(), b.title().trim(), "背景（" + upper(b.layer()) + "）");
        w1.insertClaim(new ClaimCreate(b.claimId(), b.id(), "summary", b.claimValue().trim(), kind, certainty));
        BackgroundWrite stored = new BackgroundWrite(b.id(), b.workId(), b.title().trim(), upper(b.layer()),
            upper(b.audience()), b.bodyText(), b.claimId(), b.claimValue(), kind, certainty, b.sourceId(), b.locator());
        w2.insertBackground(stored);

        List<String> notices = new ArrayList<>();
        if (b.sourceId() != null && !b.sourceId().isBlank()) cite(b.claimId(), b.sourceId(), b.locator());
        else notices.add("背景没有出处：这样的背景永远不能发布（C5_published_background 需要可核查依据）。");
        notices.add("背景还没有绑定诗句：POST /draft/background/{id}/lines；绑不上的背景就是资料堆砌。");
        return done("poetry_background/" + b.id(), notices);
    }

    @Transactional
    public Written updateBackground(String id, BackgroundWrite b) {
        id(id);
        DraftBackground current = w2.draftBackground(id);
        if (current == null) throw new Invalid("background not found: " + id);
        if (b.bodyText() == null || b.bodyText().isBlank()) throw new Invalid("body_text is required");
        String layer = upper(b.layer()) == null ? current.layer() : upper(b.layer());
        if (!Vocabulary.isMember(Vocabulary.LAYERS, layer)) throw new Invalid("layer outside vocabulary: " + b.layer());
        String audience = upper(b.audience()) == null ? current.audience() : upper(b.audience());
        if (audience != null && !Vocabulary.isMember(Vocabulary.AUDIENCES, audience))
            throw new Invalid("audience outside vocabulary: " + b.audience());
        w2.updateBackground(new BackgroundWrite(id, current.workId(), null, layer, audience, b.bodyText(),
            current.claimId(), null, null, null, null, null));
        return done("poetry_background/" + id, List.of());
    }

    public List<DraftBackground> backgrounds(String workId) { return List.copyOf(w2.backgroundsOf(workId)); }
    public List<DraftLine> backgroundLines(String backgroundId) { return List.copyOf(w2.backgroundLines(backgroundId)); }

    /** The link that makes "背景帮助理解哪一句" explicit — the product's anti-pile-up rule, in data. */
    @Transactional
    public Written linkBackgroundLine(BackgroundLineWrite l) {
        id(l.backgroundId()); id(l.versionId());
        if (l.lineSeq() == null) throw new Invalid("line_seq is required");
        if (orZero(w2.existsBackground(l.backgroundId())) == 0) throw new Invalid("background not found: " + l.backgroundId());
        if (orZero(w2.existsVersion(l.versionId())) == 0) throw new Invalid("version not found: " + l.versionId());
        String bgWork = w2.backgroundWork(l.backgroundId());
        String versionWork = w2.versionWork(l.versionId());
        if (!java.util.Objects.equals(bgWork, versionWork))
            throw new Invalid("background belongs to " + bgWork + " but the text version belongs to " + versionWork);
        if (orZero(w2.existsLine(l.versionId(), l.lineSeq())) == 0)
            throw new Invalid("line not found: " + l.versionId() + "#" + l.lineSeq());
        w2.insertBackgroundLine(l);
        return done("poetry_background_line/" + l.backgroundId() + "/" + l.versionId() + "/" + l.lineSeq(), List.of());
    }

    // ---------------------------------------------------------------- annotations (字词/意象/韵律)

    @Transactional
    public Written createAnnotation(AnnotationWrite a) {
        id(a.id()); id(a.versionId());
        if (a.lineSeq() == null) throw new Invalid("line_seq is required");
        if (orZero(w2.existsLine(a.versionId(), a.lineSeq())) == 0)
            throw new Invalid("line not found (先录行，再注释): " + a.versionId() + "#" + a.lineSeq());
        if (a.content() == null || a.content().isBlank()) throw new Invalid("annotation content is required");
        if (!Vocabulary.isMember(Vocabulary.ANNOTATION_KINDS, upper(a.annotationKind())))
            throw new Invalid("annotation_kind outside vocabulary: " + a.annotationKind());
        if (!Vocabulary.isMember(Vocabulary.AUDIENCES, upper(a.audience())))
            throw new Invalid("audience outside vocabulary: " + a.audience());
        id(a.claimId());
        if (orZero(w1.existsClaim(a.claimId())) > 0) throw new Invalid("claim id already exists: " + a.claimId());
        if (a.claimValue() == null || a.claimValue().isBlank()) throw new Invalid("claim value is required");
        String certainty = upper(a.certainty()) == null ? "KNOWN" : upper(a.certainty());
        if (!Vocabulary.isMember(Vocabulary.CERTAINTIES, certainty))
            throw new Invalid("certainty outside vocabulary: " + a.certainty());
        String workId = w2.versionWork(a.versionId());

        w1.insertClaim(new ClaimCreate(a.claimId(), workId, "annotation." + upper(a.annotationKind()),
            a.claimValue().trim(), "INTERPRETATION", certainty));
        w2.insertAnnotation(new AnnotationWrite(a.id(), a.versionId(), a.lineSeq(), upper(a.annotationKind()),
            upper(a.audience()), a.content().trim(), a.claimId(), a.claimValue(), certainty, a.sourceId(), a.locator()));
        List<String> notices = new ArrayList<>();
        if (a.sourceId() != null && !a.sourceId().isBlank()) cite(a.claimId(), a.sourceId(), a.locator());
        else notices.add("注释没有出处：教材注释/字书出处要写进 source，否则无法核查。");
        return done("poetry_annotation/" + a.id(), notices);
    }

    public List<DraftAnnotation> annotations(String versionId) { return List.copyOf(w2.annotationsOf(versionId)); }

    // ---------------------------------------------------------------- relations

    @Transactional
    public Written createRelation(RelationWrite r) {
        id(r.id()); id(r.claimId());
        if (orZero(w1.existsContent(r.subjectId())) == 0) throw new Invalid("subject not found: " + r.subjectId());
        if (orZero(w1.existsContent(r.objectId())) == 0) throw new Invalid("object not found: " + r.objectId());
        if (r.predicate() == null || r.predicate().isBlank()) throw new Invalid("predicate is required");
        if (r.predicate().length() > 40) throw new Invalid("predicate longer than 40 characters");
        if (orZero(w1.existsClaim(r.claimId())) > 0) throw new Invalid("claim id already exists: " + r.claimId());
        if (r.claimValue() == null || r.claimValue().isBlank()) throw new Invalid("claim value is required");
        String certainty = upper(r.certainty()) == null ? "KNOWN" : upper(r.certainty());
        if (!Vocabulary.isMember(Vocabulary.CERTAINTIES, certainty))
            throw new Invalid("certainty outside vocabulary: " + r.certainty());
        // C4_claim_subject_mismatch_on_relation: the claim must be about the relation's subject
        w1.insertClaim(new ClaimCreate(r.claimId(), r.subjectId(), "relation." + r.predicate().trim().toUpperCase(Locale.ROOT),
            r.claimValue().trim(), "FACT", certainty));
        w2.insertRelation(new RelationWrite(r.id(), r.subjectId(), r.predicate().trim().toUpperCase(Locale.ROOT),
            r.objectId(), r.claimId(), r.claimValue(), certainty, r.sourceId(), r.locator()));
        List<String> notices = new ArrayList<>();
        if (r.sourceId() != null && !r.sourceId().isBlank()) cite(r.claimId(), r.sourceId(), r.locator());
        else notices.add("关系没有出处。predicate 约定用大写短语（WAS_AT/PARTICIPATED_IN/MET/STUDIED_UNDER）。");
        return done("poetry_relation/" + r.id(), notices);
    }

    public List<DraftRelation> relations(String subjectId) { return List.copyOf(w2.relationsOf(subjectId)); }

    // ---------------------------------------------------------------- authorship (采用说)

    @Transactional
    public Written attachWorkAuthor(WorkAuthorWrite a) {
        requireWork(a.workId());
        if (w1.draftContent(a.personId()) == null || !"PERSON".equals(w1.entityType(a.personId())))
            throw new Invalid("person not found: " + a.personId());
        if (!Vocabulary.isMember(Vocabulary.ATTRIBUTIONS, upper(a.attribution())))
            throw new Invalid("attribution outside vocabulary: " + a.attribution() + " (PENDING/ACCEPTED/DISPUTED/REJECTED)");
        id(a.claimId());
        if (orZero(w1.existsClaim(a.claimId())) == 0) {
            if (a.claimValue() == null || a.claimValue().isBlank()) throw new Invalid("claim value is required");
            String certainty = upper(a.certainty()) == null ? "DISPUTED" : upper(a.certainty());
            if (!Vocabulary.isMember(Vocabulary.CERTAINTIES, certainty))
                throw new Invalid("certainty outside vocabulary: " + a.certainty());
            // audit C4_claim_subject_mismatch_on_work_author: the claim must be about the work AND be keyed 'authorship'
            w1.insertClaim(new ClaimCreate(a.claimId(), a.workId(), "authorship", a.claimValue().trim(), "FACT", certainty));
        } else {
            boolean belongs = w1.draftClaims(a.workId()).stream().anyMatch(c ->
                c.id().equals(a.claimId()) && "authorship".equals(c.propertyKey()));
            if (!belongs) throw new Invalid("claim " + a.claimId()
                + " cannot carry this authorship: it must be a claim about " + a.workId() + " with property_key='authorship'");
        }
        WorkAuthorWrite stored = new WorkAuthorWrite(a.workId(), a.personId(), upper(a.attribution()), a.claimId(), null, null);
        if (w2.updateWorkAuthor(stored) == 0) w2.insertWorkAuthor(stored);
        return done("poetry_work_author/" + a.workId() + "/" + a.personId(),
            List.of("署名争议用 certainty=DISPUTED；发布前 C5 需要至少一条已核查的署名依据。"));
    }

    public List<DraftWorkAuthor> authors(String workId) { return List.copyOf(w2.authorsOf(workId)); }

    // ---------------------------------------------------------------- textbooks

    @Transactional
    public Written createTextbook(TextbookCreate t) {
        id(t.id());
        if (orZero(w2.existsTextbook(t.id())) > 0) throw new Invalid("textbook id already exists: " + t.id());
        for (String v : new String[]{t.title(), t.publisher(), t.edition(), t.volume()})
            if (v == null || v.isBlank()) throw new Invalid("title/publisher/edition/volume are all required");
        if (!Vocabulary.isMember(Vocabulary.AUDIENCES, upper(t.schoolStage())))
            throw new Invalid("school_stage outside vocabulary: " + t.schoolStage() + " (PRIMARY/JUNIOR/SENIOR)");
        if (t.gradeNo() == null || t.gradeNo() < 1 || t.gradeNo() > 12) throw new Invalid("grade_no must be 1..12");
        w2.insertTextbook(t);
        return done("poetry_textbook/" + t.id(),
            List.of("教材未核查：verification_status=PENDING，直到有人对照实物/电子版页码（教材错误是最贵的错误）。"));
    }

    @Transactional
    public Written attachTextbookWork(TextbookWorkWrite tw) {
        id(tw.textbookId()); id(tw.workId()); id(tw.versionId());
        if (orZero(w2.existsTextbook(tw.textbookId())) == 0) throw new Invalid("textbook not found: " + tw.textbookId());
        requireWork(tw.workId());
        if (orZero(w2.existsVersion(tw.versionId())) == 0) throw new Invalid("version not found: " + tw.versionId());
        if (!java.util.Objects.equals(w2.versionWork(tw.versionId()), tw.workId()))
            throw new Invalid("the text version belongs to another work: " + tw.versionId());
        if (tw.pageLocator() == null || tw.pageLocator().isBlank())
            throw new Invalid("page_locator is required: '第X课/页Y' is how a textbook claim gets re-checked");
        w2.insertTextbookWork(tw);
        return done("poetry_textbook_work/" + tw.textbookId() + "/" + tw.workId(), List.of());
    }

    public List<DraftTextbook> textbooks() { return List.copyOf(w2.textbooks()); }
    public List<TextbookWorkWrite> textbookWorks(String workId) { return List.copyOf(w2.textbookWorksOf(workId)); }

    // ---------------------------------------------------------------- shared helpers

    private void cite(String claimId, String sourceId, String locator) {
        if (orZero(w1.existsSource(sourceId)) == 0) throw new Invalid("source not found: " + sourceId);
        if (locator == null || locator.isBlank()) throw new Invalid("locator is required with a source");
        w1.insertCitation(new CitationCreate(claimId, sourceId, locator.trim(), null));
    }

    private void requireWork(String workId) {
        if (orZero(w1.existsContent(workId)) == 0) throw new Invalid("work not found: " + workId);
        if (!"WORK".equals(w1.entityType(workId))) throw new Invalid("not a WORK: " + workId);
    }

    private Written done(String subject, List<String> notices) {
        AuditRunner.Result result = audit.run();
        if (!result.clean())
            throw new Dirty("write left the library unverified, rolling back: " + result.nonZero().stream().limit(10).toList());
        return new Written(subject, true, List.copyOf(notices), result.totalChecks(), List.of());
    }

    private static void id(String value) {
        if (value == null || !value.matches(ID_PATTERN))
            throw new Invalid("id must match " + ID_PATTERN + " (got: " + value + ")");
    }

    private static String upper(String value) { return value == null ? null : value.trim().toUpperCase(Locale.ROOT); }
    private static int orZero(Integer value) { return value == null ? 0 : value; }
}
