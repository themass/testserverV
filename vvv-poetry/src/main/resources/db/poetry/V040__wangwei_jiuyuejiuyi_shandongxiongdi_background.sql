-- V040：王维《九月九日憶山東兄弟》(work-t300-148) 四层背景（阶段 D 第 21 首·绝句第二用）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V015、V016、V018 已执行（work-t300-148 与其 text-work-t300-148-ws、
--       source-ws-t300-148 是 V018 的行；source-jiutangshu-wenyuan / source-xintangshu-wenyi
--       是 V016 的行；source-quantangshi-128 是 V026 的行；source-zizhi-tongjian-events
--       早期迁移已立——均不另开）。本迁移零新 source（断言）。
--
-- 数据源（可复现）：emit_v040.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/九月九日憶山東兄弟.txt（{{别|為|爲}} 标记原样+页底整理者注「時年十七」照登
--   并声明非史料——variants.md 先登记后照登）、
--   舊唐書卷190下（王维传籍贯段+兄弟段）、新唐書卷202（兄弟段+自表换官段；
--   切片传区间归属生成时断言）、
--   通鉴 tj-205（695 刘知几条）+tj-241（819 重阳大宴条）——两条目均生成时
--   位置断言其落在各自年标题区间内（V034 年标题归属立规）。
--
-- 做：0 个新 source（断言）+ 4 BACKGROUND content/claim/background +
--   8 组逐字引用（(claim,source) 主键每对恰一行）+
--   4 行 background_line（**绝句形制：每层一行** scene→1 city→2 world→3 person→4，
--   绑 text-work-t300-148-ws 的 4 行）。本迁移不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「页注系年，史无系年」）：
--   * 页底注「時年十七」系整理者注无出处——照登入引文、标非史料、不入库为事实；
--   * 通鉴两条重阳条年份可钉（位置断言）但与王维零关联——节令入正史不推及诗；
--   * 「山東」零史料（旧传单得河东/新传零地址）——三读法并列不裁决，兄弟不发明；
--   * KNOWN 一处：兄弟齐名友悌两源合龙；不外溢到诗（诗 time.span/event.name/
--     written_during 零铸造、零 relation）；
--   * V039 卒段只引别书一句续线不重开；鳏居/奉佛等判例不入本迁移（audit 断言）。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 39，不含 40
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-99-%';              -- 空
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-148-ws';  -- 恰 4（绝句）
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-99-%';        -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-148';                                  -- 4（绝句每层一行）
--   SELECT certainty FROM poetry_claim WHERE id = 'claim-bg-99-person'; -- KNOWN（兄弟两源合龙）
--   SELECT certainty FROM poetry_claim WHERE id IN ('claim-bg-99-scene','claim-bg-99-city','claim-bg-99-world');
--     -- LIKELY / LIKELY / LIKELY（通鉴条年份可钉但 claim 含节令解读整体 LIKELY）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-148'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-148';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-99-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V040_rollback.sql（按 id 全枚举删除；不动 V018/V026 的行，不动共用来源行）
START TRANSACTION;

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-99-scene' AS id, 'BACKGROUND' AS entity_type, '99-scene' AS slug, '眼前：数出来的缺口' AS title, '四层处境背景（阶段 D 第 21 首·绝句第二用）；史实句均有逐字引证；background_line 绝句形制：每层一行（1/2/3/4）；系年第十五次判决「页注系年，史无系年」（题证系列第三状：页底整理者注「時年十七」照登标非史料）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 一处（兄弟齐名友悌两源合龙）；通鉴两条重阳条年标题位置断言（V034 立规）；{{别|為|爲}} 先登记后照登。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-99-city' AS id, 'BACKGROUND' AS entity_type, '99-city' AS slug, '这座城：河东人说山東' AS title, '四层处境背景（阶段 D 第 21 首·绝句第二用）；史实句均有逐字引证；background_line 绝句形制：每层一行（1/2/3/4）；系年第十五次判决「页注系年，史无系年」（题证系列第三状：页底整理者注「時年十七」照登标非史料）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 一处（兄弟齐名友悌两源合龙）；通鉴两条重阳条年标题位置断言（V034 立规）；{{别|為|爲}} 先登记后照登。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-99-world' AS id, 'BACKGROUND' AS entity_type, '99-world' AS slug, '这个天下：重阳是国家日程' AS title, '四层处境背景（阶段 D 第 21 首·绝句第二用）；史实句均有逐字引证；background_line 绝句形制：每层一行（1/2/3/4）；系年第十五次判决「页注系年，史无系年」（题证系列第三状：页底整理者注「時年十七」照登标非史料）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 一处（兄弟齐名友悌两源合龙）；通鉴两条重阳条年标题位置断言（V034 立规）；{{别|為|爲}} 先登记后照登。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-99-person' AS id, 'BACKGROUND' AS entity_type, '99-person' AS slug, '这个人：传里存了两封给弟弟的信' AS title, '四层处境背景（阶段 D 第 21 首·绝句第二用）；史实句均有逐字引证；background_line 绝句形制：每层一行（1/2/3/4）；系年第十五次判决「页注系年，史无系年」（题证系列第三状：页底整理者注「時年十七」照登标非史料）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 一处（兄弟齐名友悌两源合龙）；通鉴两条重阳条年标题位置断言（V034 立规）；{{别|為|爲}} 先登记后照登。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-99-scene' AS id, 'bg-99-scene' AS subject_id, 'context' AS property_key, '四句全诗本文（{{别|為|爲}} 页内标记首读爲照登，variants.md 先登记；缺席者想象在场为本层读法声明）；页底「時年十七」系整理者注无出处——照登入引文但明标非史料，不入库为事实。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-99-city' AS id, 'bg-99-city' AS subject_id, 'context' AS property_key, '题证节令（重阳）不证地理：旧传籍贯「徙家于蒲，遂為河東人」单源 LIKELY，新传零地址；「山東」三读法并列不裁决（负证：两传零山东记载）；兄弟不载名数，不发明。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-99-world' AS id, 'bg-99-world' AS subject_id, 'context' AS property_key, '重阳=国家日程两条通鉴条目（695 刘知几表「重陽之節，佇降皇恩」/819「九月，欲以重陽大宴」+李玨疏）各在其年标题区间内（生成时位置断言，V034 立规）；两条与王维零关联——节令入正史不推及诗入正史；诗 time.span/event.name/written_during 零铸造、零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-99-person' AS id, 'bg-99-person' AS subject_id, 'context' AS property_key, '王维与弟縉齐名友悌两源独立一致（旧「俱有俊才…齊名，閨門友悌」/新「與弟縉齊名，資孝友」）→升 KNOWN；兄弟数人山东一差不载，不外溢；自表换官+临终别书新传单得 LIKELY 级细节（V039 卒段只引不重开）；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-99-scene' AS subject_id, 'context' AS property_key, 'claim-bg-99-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-99-city' AS subject_id, 'context' AS property_key, 'claim-bg-99-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-99-world' AS subject_id, 'context' AS property_key, 'claim-bg-99-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-99-person' AS subject_id, 'context' AS property_key, 'claim-bg-99-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-99-scene' AS id, 'work-t300-148' AS work_id, 'SCENE' AS layer, '诗只给了四件事：一个人在外地（「獨在異鄉{{别|為|爲}}異客」，页内為/爲异读照登不裁决，V018 正文取首读「爲」）；今天是个好节日，而且**每**逢都加倍（「每逢佳節倍思親」——不是今天才想）；他想象远方：兄弟们登高，每人插着茱萸，数下来少一个（「遙知兄弟登高處，遍插茱萸少一人」）。全诗没有一处实景——只有缺席者对在场的想象。茱萸是重阳的佩戴物，「少一人」是缺席者替在场者补出来的缺口。
页底整理者注「時年十七」给了个年纪——**照登，标明系底注无出处**：注者说十七岁写的，注者没说注者是谁。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-99-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-99-city' AS id, 'work-t300-148' AS work_id, 'CITY' AS layer, '题里的「山東」是这首诗最大的悬案：题眼「九月九日」有节令、「兄弟」有人，「山東」有方向却没有可核之地。旧传给王维家的地址：「父處㢘，終汾州司馬，徙家于蒲，遂為河東人」——**河东**，蒲州，在山西，不在太行山之东；新传连地址都不给。旧传单源，不升。
于是「山東兄弟」至少有三种读法（故里在他乡人对故乡的称呼/兄弟真在山东/语感词）——史料一种都不支持裁决，BG 到此为止：节令真实（重阳）、方向存疑（山東）、兄弟无名（零记载）。题证节令，不证地理。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-99-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-99-world' AS id, 'work-t300-148' AS work_id, 'WORLD' AS layer, '重阳在正史里的样子，本迁移用通鉴两条**位置核验**的条目立起来：695 年（上天冊萬歲元年）条内刘知几表陈四事，抱怨朝廷滥赦——「元日之朝，指期天澤，重陽之節，佇降皇恩」：连最无赖的人都把重阳当作等恩赦的日子；819 年（元和十四年）条「九月，欲以重陽大宴」，拾遗李玨率同僚上疏谏止——皇帝想在重阳办大宴，谏官把它当国事拦。两条各在其年标题区间内（生成器位置断言，V034 立规）。
这就是王维那个「佳節」的天下形状：重阳是**国家日程**——恩赦候它，宴饮候它，谏疏也候它；诗把它当私人记忆的容器用。两条通鉴与王维**零关联**——节令入正史不意味诗入正史。' AS body_text, 'SENIOR' AS audience, 'claim-bg-99-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-99-person' AS id, 'work-t300-148' AS work_id, 'PERSON' AS layer, '两传写得最实的兄弟关系是**弟弟王縉**：旧传「與弟縉俱有俊才，博學多藝亦齊名，閨門友悌，多士推之」+新传「九歲知屬辭，與弟縉齊名，資孝友」——齐名与友悌/孝友要素两两相当，**王维兄弟友悌升 KNOWN**（两源合龙）。
但诗题「山東兄弟」不是王縉的实名的任何一步：两传只给一个弟弟，给不出「山東」那一群——兄弟几人不载，不发明。
兄弟线在传里有两封存信：新传王维自表「己有五短，縉五長，臣在省戶，縉遠方，願歸所任官，放田里，使縉得還京師」——拿自己的官换弟弟回京；临终「疾甚，縉在鳳翔，作書與別」——最后一封信还是给弟弟的（V039 已直书卒段，此处只引别书一句续线，不重开卒年裁决）。他一生写给兄弟的信，传里存了两封；诗里这首，传里不收。' AS body_text, 'SENIOR' AS audience, 'claim-bg-99-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-99-scene' AS claim_id, 'source-ws-t300-148' AS source_id, '页面 九月九日憶山東兄弟（header title+author+notes 行尾整理者注「時年十七」+四句全文，六段以「……」相連——第1句含页内异文标记 {{别|為|爲}} 原样入证（V018 正文取首读爲，variants.md 已先登记）；「時年十七」照登并声明系整理者注无出处、非史料；同一 (claim,source) 主键下一行容全文，V037/V039 判例）' AS locator, '| title    = 九月九日憶山東兄弟……| author   = 王維……[[全唐詩/卷128#九月九日憶山東兄弟|全唐詩·卷128]]時年十七……獨在異鄉{{别|為|爲}}異客，……獨在異鄉{{别|為|爲}}異客，每逢佳節倍思親。……遙知兄弟登高處，……遙知兄弟登高處，遍插茱萸少一人。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-99-city' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·王维传籍贯段（徙家于蒲/河东人——单源不升；「山東」零记载之负证在本段；「河东在山西」是今地理常识注非本证）' AS locator, '父處㢘，終汾州司馬，徙家于蒲，遂為河東人。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-99-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '通鉴卷二百零五·上天冊萬歲元年（695）条+卷二百四十一·元和十四年（819）条（两条四段以「……」相連，同一 (claim,source) 主键一行，V037/V039 判例——695：年标题+刘知几表陈四事至「重陽之節，佇降皇恩」，生成时位置断言：语在695与696标题之间；819：年标题+「九月，欲以重陽大宴」李玨上疏，生成时位置断言：条在819与821标题之间；两条与王维零关联）' AS locator, '上天冊萬歲元年（乙未，公元六九五年）……獲嘉主簿彭城劉知幾表陳四事。其一以為：「皇業權輿，天地開闢，嗣君即位，黎元更始，則時藉非常之慶，以申再造之恩。今六合清晏而赦令不息，近則一年再降，遠則每歲無遺，至於違法悖禮之徒，無賴不仁之輩，編戶則寇攘為業，當官則贓賄是求。而元日之朝，指期天澤，重陽之節，佇降皇恩……元和十四年（己亥，公元八一九年）……九月，欲以重陽大宴。拾遺李玨帥其同僚上疏' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-99-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·王维传兄弟段（俱俊才/齐名/闺门友悌——两源合龙旧传侧逐字）' AS locator, '與弟縉俱有俊才，博學多藝亦齊名，閨門友悌，多士推之。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-99-person' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零二·文藝中·王维传（九岁属辞/齐名孝友段+自表换官段以「……」相連；同卷同传——齐名两源合龙新传侧/五短五长单得；临终别书 V039 已立不重开）' AS locator, '九歲知屬辭，與弟縉齊名，資孝友。……己有五短，縉五長，臣在省戶，縉遠方，願歸所任官，放田里，使縉得還京師。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-99-city' AS claim_id, 'source-quantangshi-128' AS source_id, '卷一百二十八·王维诗目下本诗条目（锚点+转引用桩——卷页无正文，桩文照登；来源行 V026 已立，此处零新开）' AS locator, '==[[九月九日憶山東兄弟]]==
{{:九月九日憶山東兄弟}}' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（绝句：每层一行） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-99-scene' AS background_id, 'text-work-t300-148-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-99-city' AS background_id, 'text-work-t300-148-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-99-world' AS background_id, 'text-work-t300-148-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-99-person' AS background_id, 'text-work-t300-148-ws' AS version_id, 4 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 40, 'Wang Wei Sep 9th Missing Shan-dong Brothers background layers (stage-D poem 21, second quatrain): dating verdict fifteen, third shape of the title-evidence series -- the wikisource page carries an editor note shi nian shi-qi (written at seventeen) with no source given: transcribed verbatim in the citation, labelled a curator note, never entered as fact -- page-notes date, history does not; the Tongjian carries two Double-Ninth entries whose years ARE pin-able by heading-position assertions (695 Liu Zhiji memorial yin zhong-yang zhi jie zhu jiang huang-en, and 819 the court plans a great Double-Ninth banquet and Li Jue memorializes against it, V034 positional rule enforced at generation) yet neither touches Wang Wei -- a festival in the annals never drags the poem in; shan-dong itself stays unclaimed: JTS gives only xi jia yu pu (a Hedong home, single-source, not raised), XTS gives no address at all, three readings left un-ruled and no brothers invented; one KNOWN: the brotherhood itself, JTS yu di Jin ... qi-ming, gui-men you-ti plus XTS yu di Jin qi-ming, zi xiao-you -- two independent wordings agreeing; the self-memorial trading his post to recall his brother and the deathbed letter to Jin cited as line-continuation only (V039 owns the death ruling, not reopened); zero new sources (juan 128 opened by V026, tongjian source row already standing)'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 40);
COMMIT;
