-- V034：王翰《涼州詞二首 一》(work-t300-106) 四层背景（阶段 D 第 15 首·第一首绝句）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V015、V016、V018 已执行（work-t300-106 与其 text-work-t300-106-ws、
--       source-ws-t300-106 是 V018 的行；source-jiutangshu-wenyuan / source-xintangshu-wenyi
--       是 V016 的行；source-zizhi-tongjian-events 是 V015 的行——都不另开行）。
--
-- 数据源（可复现）：emit_v034.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/涼州詞__葡萄美酒夜光杯_.txt（页内实测无 {{另}}——「查过、干净」）、
--   舊唐書卷190上（张说品文段——旧传无王翰传，唯一直证）、新唐書卷202（王翰完整本传）、
--   資治通鑑卷213（726/727/728 三个标准形年标题+本年罢相/致仕/罢政事条；
--   快照为 2026-11-20 缺口补齐+错误页全量重抓后版本，tj-191–265 75/75 完整性已验证）。
--   **全唐詩卷156 本地缺**——本诗无卷页桩，诚实缺一条 citation（V032 先例）。
--
-- 做：0 个新 source + 4 BACKGROUND content/claim/background +
--   7 组逐字引用（(claim,source) 主键每对恰一行）+
--   4 行 background_line（**绝句形制：每层一行** scene→1 city→2 world→3 person→4，
--   绑 text-work-t300-106-ws 的 4 行）。本迁移不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「乐府题不纪行旅」——年份边界已在缺口补齐后重划）：
--   * 乐府属性=诗页 title「涼州詞二首」+section「一」直证；到过凉州/边地本地史料零记载
--     （通鉴 75/75 全量复扫零命中）——明说拟乐府，不编边塞行旅；
--   * 张说罢知政事=通鉴卷213 開元十四年（丙寅，公元七二六年）条「但罷說中書令，餘如故」，
--     逐字可得，升 KNOWN——但 KNOWN 只覆盖事件本体，不外溢到诗；
--   * 逐年归属硬断言：727「制說致仕」（致仕≠罢相）、728「雖罷政事」各随本年标题；
--     初稿曾把这两条误挂 730 标题下（当时 tj-211/213 为坏页所致误判），执行前已改正；
--   * KNOWN 共两处（张说知遇王翰：两源独立一致；726 罢相：编年体直书 V028/V033 判例）；
--     新传独得处（豪健/蒱酒/声伎/贬死/因果链措辞）按 LIKELY 照登；
--   * 写作酒席不编（本传无一字）。
--
-- 干支对账：726=丙寅、727=丁卯、728=戊辰（tj-213 标准形年标题，audit 检查4 覆盖）。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 33，不含 34
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-lz-%';              -- 空
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-106-ws';  -- 恰 4（绝句）
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-lz-%';        -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-106';                                  -- 4（绝句每层一行）
--   SELECT certainty FROM poetry_claim WHERE id IN ('claim-bg-lz-city','claim-bg-lz-world','claim-bg-lz-person');
--     -- KNOWN / KNOWN / KNOWN（city=乐府题+城串有据；world=726 罢相事件，不外溢到诗；
--     --   person 的 KNOWN 仅知遇一处）
--   SELECT certainty FROM poetry_claim WHERE id='claim-bg-lz-scene';    -- LIKELY
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-106'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-106';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-lz-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V034_rollback.sql（按 id 全枚举删除；不动 V018 的行，不动共用来源行）
START TRANSACTION;

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-lz-scene' AS id, 'BACKGROUND' AS entity_type, 'lz-scene' AS slug, '眼前：一桌核不到酒席的酒' AS title, '四层处境背景（阶段 D 第 15 首·第一首绝句）；史实句均有逐字引证；background_line 绝句形制：每层一行（1/2/3/4）；乐府题不系年→time.span/event.name/written_during 全缺席、零 relation；张说罢相 726 通鉴标准形年标题逐字（KNOWN 仅事件本体，不外溢到诗）；KNOWN 两处：张说知遇（两源一致）+726 罢相（编年体直书）。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-lz-city' AS id, 'BACKGROUND' AS entity_type, 'lz-city' AS slug, '这座城：凉州是曲名不是脚步' AS title, '四层处境背景（阶段 D 第 15 首·第一首绝句）；史实句均有逐字引证；background_line 绝句形制：每层一行（1/2/3/4）；乐府题不系年→time.span/event.name/written_during 全缺席、零 relation；张说罢相 726 通鉴标准形年标题逐字（KNOWN 仅事件本体，不外溢到诗）；KNOWN 两处：张说知遇（两源一致）+726 罢相（编年体直书）。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-lz-world' AS id, 'BACKGROUND' AS entity_type, 'lz-world' AS slug, '这个天下：吊在张说身上的起落' AS title, '四层处境背景（阶段 D 第 15 首·第一首绝句）；史实句均有逐字引证；background_line 绝句形制：每层一行（1/2/3/4）；乐府题不系年→time.span/event.name/written_during 全缺席、零 relation；张说罢相 726 通鉴标准形年标题逐字（KNOWN 仅事件本体，不外溢到诗）；KNOWN 两处：张说知遇（两源一致）+726 罢相（编年体直书）。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-lz-person' AS id, 'BACKGROUND' AS entity_type, 'lz-person' AS slug, '这个人：玉杯多玷' AS title, '四层处境背景（阶段 D 第 15 首·第一首绝句）；史实句均有逐字引证；background_line 绝句形制：每层一行（1/2/3/4）；乐府题不系年→time.span/event.name/written_during 全缺席、零 relation；张说罢相 726 通鉴标准形年标题逐字（KNOWN 仅事件本体，不外溢到诗）；KNOWN 两处：张说知遇（两源一致）+726 罢相（编年体直书）。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-lz-scene' AS id, 'bg-lz-scene' AS subject_id, 'context' AS property_key, '酒器/琵琶/催发全诗本文；家畜声伎/自视王侯为新传单源（LIKELY 照登）；写作酒席不编（本传无一字，本地核不到）。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-lz-city' AS id, 'bg-lz-city' AS subject_id, 'context' AS property_key, '乐府题属性由诗页 title+section 双字段逐字支撑（组诗其一）；行迹城串（晋阳→昌乐→长安→汝州→仙州→道州）全新传逐字；到过凉州/边地——本地史料零记载（通鉴 75/75 全量复扫零命中，2026-11-20），明说不编。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-lz-world' AS id, 'bg-lz-world' AS subject_id, 'context' AS property_key, '726 罢相条+727 致仕条+728 罢政事条，通鉴三个标准形年标题逐年归属逐字（干支对账 audit 检查4 覆盖）——罢相事件本体升 KNOWN（V028/V033 事件判例：编年体直书）；此 KNOWN **只覆盖事件，不外溢到诗**：乐府题不纪行旅→诗 time.span/event.name/written_during 零铸造、零 relation；致仕≠罢相的逐年声明在本 claim 与 locator 双重在场。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-lz-person' AS id, 'bg-lz-person' AS subject_id, 'context' AS property_key, 'KNOWN 两处之一：张说知遇王翰——新传（礼遇/召用/出贬三处因果）与旧传张说品文语两源独立一致；新传独得处（性格/奢侈/贬死细节）与因果链措辞均 LIKELY 并列照登；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-lz-scene' AS subject_id, 'context' AS property_key, 'claim-bg-lz-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-lz-city' AS subject_id, 'context' AS property_key, 'claim-bg-lz-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-lz-world' AS subject_id, 'context' AS property_key, 'claim-bg-lz-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-lz-person' AS subject_id, 'context' AS property_key, 'claim-bg-lz-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-lz-scene' AS id, 'work-t300-106' AS work_id, 'SCENE' AS layer, '这首诗的开场是一桌酒席上最贵的一件器物：「葡萄美酒夜光杯」——葡萄酒盛在夜光杯里。第二句人就开始起身：「欲飲琵琶馬上催」——正要喝，琵琶弹起了催发的曲子。
但这是诗里的酒席，不是史料里的酒席。本传能给的最近的一条是「家畜聲伎，目使頤令，自視王侯」——家里养着歌伎，使唤仆妾像动下巴一样随意，把自己看得和王侯一样——新传记他的豪奢是这种规格。至于这首诗写于哪一场酒，本传无一字，本地核不到就不编。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-lz-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-lz-city' AS id, 'work-t300-106' AS work_id, 'CITY' AS layer, '这座城不在诗里发生——《涼州詞》是乐府旧题。维基文库诗页就标着两层：title「涼州詞二首」+ section「一」（组诗第一首）。凉州是曲调的名字，不是王翰的脚步：本地史料里没有一行说他到过凉州或任何边地。所以这首诗的正确读法先要摆正：他是**在长安的繁华里写边塞的歌**——拟乐府的写法，唐人也明知是拟作。
他一生实际走过的城在本传里排成一串：并州晋阳人（字子羽），进士及第后调昌乐尉，召为秘书正字、通事舍人、驾部员外郎都在长安，「說罷宰相，翰出為汝州長史，徙仙州別駕」——贬出长安后辗转汝州、仙州，「坐貶道州司馬，卒」——最后死在道州。从长安到道州，就是他的全部地图。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-lz-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-lz-world' AS id, 'work-t300-106' AS work_id, 'WORLD' AS layer, '「醉臥沙場君莫笑，古來征戰幾人回」——诗里的沙场是乐府的沙场；这个人的沙场在朝堂，而且是当时最大的那一场：张说。这一场通鉴系了年。
通鉴卷 213 给这条因果链钉了三个标准形年标题，各带本年条目：開元十四年（丙寅，公元七二六年）「庚申，但罷說中書令，餘如故」——这就是新传「說罷宰相」的正身；開元十五年（丁卯，公元七二七年）「二月，乙巳，制說致仕」——致仕，不是罢相；開元十六年（戊辰，公元七二八年）「說雖罷政事，專文史之任」——收口。三条逐年归属，初稿曾把后两条误挂七三〇标题下，已改正——致仕≠罢相，年份错一格就是张冠李戴。
王翰的全部起伏都吊在这根线上：张说当国他被召进中枢，张说倒他外放贬死。因果链的第一个绝对年份现在是硬的（726 罢相，通鉴编年体直书升 KNOWN），但诗仍是乐府题——乐府不纪行旅，锚到事件也到不了诗。time.span、event.name、written_during 一个都不造。' AS body_text, 'SENIOR' AS audience, 'claim-bg-lz-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-lz-person' AS id, 'work-t300-106' AS work_id, 'PERSON' AS layer, '王翰这个人的全部证词，新旧唐书各留一半，两半在「张说」身上合龙。
新唐书（卷202 文艺中，他唯一完整的一传）写他的狂：「少豪健恃才，及進士第，然喜蒱酒」；张嘉贞厚遇他，他「自歌以舞屬嘉貞，神氣軒舉自如」；「家畜聲伎，目使頤令，自視王侯，人莫不惡之」；贬出后还「日與才士豪俠飲樂游畋，伐鼓窮歡」——天天和豪侠饮宴打猎，擂鼓尽欢——最后为这份排场获罪「坐貶道州司馬，卒」。
旧唐书（卷190上，无王翰传）留下张说的原话：张说对徐坚品评后进文士——「王翰之文，如瓊懷玉斝，雖爛然可珍，而多有玷缺」——像玉杯，灿烂可爱，可惜疤多。这句话和「瓊杯」的比喻本身，就是知遇的实物证据：两源独立一致升 KNOWN 的第一点：张说认识、赏识并品评过王翰。
因果链由新传单源给出：「方說輔政，故召為秘書正字」——因果一步；「說罷宰相，翰出為汝州長史」——因果二步（此步的年份由通鉴 726 条独立钉实）；贬死——结局。独得处（豪健、蒱酒、自视王侯、伐鼓穷欢、贬死）按 LIKELY 照登不升。
「古来征战几人回」放在这样一个人身上，不是慷慨，是他整个人的口径：把命看得和一场酒一样轻——本传的每一个字都在给这句诗当注脚。' AS body_text, 'SENIOR' AS audience, 'claim-bg-lz-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-lz-scene' AS claim_id, 'source-ws-t300-106' AS source_id, '页面 涼州詞二首（header title+section+author 三字段+第1、2句，五段以「……」相連——乐府组诗其一之页内直证+开场酒席；页内实测无 {{另|}} 异文，「查过、干净」；全文另见 V018 claim-t300-106-text 引文）' AS locator, '| title    = 涼州詞二首……| section  = 一……| author   = 王翰……葡萄美酒夜光杯，……葡萄美酒夜光杯，欲飲琵琶馬上催。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-lz-city' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零二·文藝中·王翰传（首段——晋阳人/进士第；行迹城串起点，城串全程与终点在 PERSON 层引文段；乐府题属性之证在 SCENE 层引文段）' AS locator, '王翰，字子羽，并州晉陽人。少豪健恃才，及進士第，然喜蒱酒。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-lz-world' AS claim_id, 'source-ws-t300-106' AS source_id, '页面 涼州詞二首（第3句逐字——沙场为乐府意象）' AS locator, '醉臥沙場君莫笑，' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-lz-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '通鑑卷二百十三·玄宗·三组「年标题+本年条目」（726 罢相/727 致仕/728 罢政事，六段以「……」相連，归属=各条目在本年标题与下一年标题之间；**致仕≠罢相**——罢宰相正身是 726「但罷說中書令」，727 制說致仕、728 雖罷政事各归本年，不冒名顶替）' AS locator, '=== 玄宗至道大聖大明孝皇帝中之上開元十四年（丙寅，公元七二六年）===……源乾曜等鞫張說，事頗有狀，上使高力士視說，力士還奏：「說蓬首垢面，席蒿，食以瓦器，惶懼待罪。」上意憐之。力士因言說有功於國，上以為然。庚申，但罷說中書令，餘如故。……=== 玄宗至道大聖大明孝皇帝中之上開元十五年（丁卯，公元七二七年）===……御史大夫崔隱甫、中丞宇文融，恐右丞相張說復用，數奏毀之，各為朋黨。上惡之，二月，乙巳，制說致仕，隱甫免官侍母，融出為魏州刺史。……=== 玄宗至道大聖大明孝皇帝中之上開元十六年（戊辰，公元七二八年）===……二月，壬申，以尚書右丞相致仕張說兼集賢院學士。說雖罷政事，專文史之任，朝廷每有大事，上常遣中使訪之。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-lz-person' AS claim_id, 'source-ws-t300-106' AS source_id, '页面 涼州詞二首（第4句逐字——几人回之口吻与下方两传证词对读）' AS locator, '醉臥沙場君莫笑，古來征戰幾人回。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-lz-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十上·文苑上·张说品文段（张说对徐坚语中「王翰之文」一句——旧传无王翰传，此为旧传侧唯一直证，知遇关系第二源）' AS locator, '王翰之文，如瓊懷玉斝，雖爛然可珍，而多有玷缺。」' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-lz-person' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零二·文藝中·王翰传（首段+礼遇段+辅政召用段+出贬贬死段；四段以「……」相連，出处同卷同传——因果链三步与城串终点全在此四段）' AS locator, '王翰，字子羽，并州晉陽人。少豪健恃才，及進士第，然喜蒱酒。……張嘉貞為本州長史，偉其人，厚遇之。翰自歌以舞屬嘉貞，神氣軒舉自如。張說至，禮益加。……復舉直言極諫，調昌樂尉，又舉超拔君類。方說輔政，故召為秘書正字，擢通事舍人、駕部員外郎。家畜聲伎，目使頤令，自視王侯，人莫不惡之。……說罷宰相，翰出為汝州長史，徙仙州別駕。日與才士豪俠飲樂游畋，伐鼓窮歡，坐貶道州司馬，卒。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（绝句：每层一行） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-lz-scene' AS background_id, 'text-work-t300-106-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-lz-city' AS background_id, 'text-work-t300-106-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-lz-world' AS background_id, 'text-work-t300-106-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-lz-person' AS background_id, 'text-work-t300-106-ws' AS version_id, 4 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 34, 'Wang Han Liang-zhou-ci background layers (stage-D poem 15, first quatrain): the biography supplies a full rise-and-fall causal chain but the poem itself gets no year -- every rung of Wang Han-s career hangs on Zhang Yue (summoned while Yue was in power, sent out when Yue was dismissed, died of a later demotion); the yuefu title is proven by the ws page header itself (title Liang-zhou-ci er-shou plus section yi: no.1 of a pair), and no local source puts Wang Han anywhere near Liang-zhou or the frontier (rescanned over the complete tong-jian snapshot tj-191 to tj-265, 75 of 75 volumes integrity-verified after the 2026-11-20 gap refill), so the poem is a Chang-an yuefu imitation, said so plainly; the dismissal year was re-checked after the gap refill and IS localizable -- tong-jian ju 213 carries it under the standard-form year heading Kaiyuan 14 (bing-yin, 726 CE): geng-shen, dan-ba-yue-zhong-shu-ling (Zhang Yue was merely dismissed as Zhong-shu-ling), and the two follow-up entries each keep their own year heading: Kaiyuan 15 (ding-mao, 727): zhi-yue-zhi-shi (retirement, NOT the dismissal) and Kaiyuan 16 (wu-chen, 728): sui-ba-zheng-shi; the first draft had wrongly hung the latter two under the 730 heading (a misjudgment caused by the then-broken ju-211 snapshot) -- corrected before execution, attribution asserted in the generator; KNOWN covers the dismissal event only and never the poem (dating still zero-cast: no time.span, no event.name, no written_during, zero relations -- yuefu titles record no journey); KNOWN raised at exactly two points (the Zhang-Yue-Wang-Han bond, JTS quote plus XTS chain, two independent sources; and the 726 dismissal as annalistic text, V028/V033 event precedent); background_line uses the quatrain shape: one line per layer (1/2/3/4)'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 34);
COMMIT;
