-- V036：李白《玉階怨》(work-t300-308) 四层背景（阶段 D 第 17 首·绝句第二例）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V015、V016、V018 已执行（work-t300-308 与其 text-work-t300-308-ws、
--       source-ws-t300-308 是 V018 的行；source-jiutangshu-wenyuan / source-xintangshu-wenyi
--       是 V016 的行——不另开行）。本迁移另开 1 个 source（全唐詩卷164，见下）。
--
-- 数据源（可复现）：emit_v036.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/玉階怨__李白_.txt（页内实测无 {{另}}——「查过、干净」）、
--   舊唐書卷190下（李白传——乐府新词段/天宝初段/谪仙人段/醉死宣城段）、
--   新唐書卷202（李白传——乐章段/天宝初段/谪仙人段/葬青山段；与 V032 已用切片零重叠，
--   传区间归属生成时断言）、全唐詩卷164（锚点+转引用桩，noauthor 空——V035 卷126 判例）。
--
-- 做：1 个新 source（source-quantangshi-164，PENDING——桩页教训同款）+
--   4 BACKGROUND content/claim/background + 9 组逐字引用（(claim,source) 主键每对恰一行）+
--   4 行 background_line（**绝句形制：每层一行** scene→1 city→2 world→3 person→4，
--   绑 text-work-t300-308-ws 的 4 行）。本迁移不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「乐府题不纪行旅 + 语境只有模糊时代标签 + 卒地两传分歧」）：
--   * 乐府属性=诗页 title 直证；为谁立于何宫——两传无一字，明说不编；
--   * 「天寶初」两传同款模糊标签：不是年份，不做年表式演算——系年第十一次判决；
--   * 御前醉草乐词=两源独立一致（醉/召/洒水/立就四要素全同）升 KNOWN，
--     但只覆盖语境不外溢到诗（V033/V034/V035 事件判例的语境版：语境比事件更软，
--     连年标题级坐标都没有）；
--   * 贺知章谪仙人之赏=两传各自在场升 KNOWN；
--   * 卒地分歧（醉死宣城/葬当涂青山）——两源直接分歧并列照登不裁决，
--     升 KNOWN 的两处都不覆盖卒地；
--   * KNOWN 共两处，其余照 LIKELY。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 35，不含 36
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-yj-%';              -- 空
--   SELECT id FROM poetry_source WHERE id='source-quantangshi-164';     -- 空
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-308-ws';  -- 恰 4（绝句）
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-yj-%';        -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-308';                                  -- 4（绝句每层一行）
--   SELECT certainty FROM poetry_claim WHERE id IN ('claim-bg-yj-world','claim-bg-yj-person');
--     -- KNOWN / KNOWN（world=醉草语境不外溢；person=谪仙人两源，均不覆盖系年与卒地）
--   SELECT certainty FROM poetry_claim WHERE id IN ('claim-bg-yj-scene','claim-bg-yj-city');
--     -- LIKELY / LIKELY
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-308'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-308';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-yj-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V036_rollback.sql（按 id 全枚举删除；不动 V018 的行，不动共用来源行；
--   本迁移自开的 source-quantangshi-164 随回滚删除）
START TRANSACTION;

-- ---------- 0. 新 source（1 个；桩页如实标注，PENDING 照 V031/V035 判例） ----------
INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status, source_kind, reliability)
SELECT * FROM (
SELECT 'source-quantangshi-164' AS id, '《全唐詩》全唐詩/卷164（维基文库录入本）' AS title, NULL AS author, '全唐詩/卷164（维基文库《全唐詩》录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷164' AS url, '维基文库录入本，公有领域古籍。卷首 Collection header 的 noauthor 字段为空——卷页无作者标注（与卷160 的孟浩然标注不同，同卷126/卷164 无标注情形；本卷多数为李白诗，但标注缺失就按缺失声明）。本诗条目只有锚点+转引用桩（异名消歧「玉階怨 (李白)」），正文在诗页。本行由 emit_v036.py 对快照逐字定位。核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status, 'POETRY_COLLECTION' AS source_kind, 'HIGH' AS reliability FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_source x WHERE x.id = t.id);

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-yj-scene' AS id, 'BACKGROUND' AS entity_type, 'yj-scene' AS slug, '眼前：一级台阶上的站立' AS title, '四层处境背景（阶段 D 第 17 首·绝句第二例）；史实句均有逐字引证；background_line 绝句形制：每层一行（1/2/3/4）；乐府题不纪行旅+创作语境只有「天寶初」模糊标签→time.span/event.name/written_during 全缺席、零 relation；KNOWN 两处：御前醉草乐词语境（两源四要素全同）+贺知章谪仙人之赏（两源）；卒地两传分歧并列不裁决。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-yj-city' AS id, 'BACKGROUND' AS entity_type, 'yj-city' AS slug, '这座城：天宝初不是年份' AS title, '四层处境背景（阶段 D 第 17 首·绝句第二例）；史实句均有逐字引证；background_line 绝句形制：每层一行（1/2/3/4）；乐府题不纪行旅+创作语境只有「天寶初」模糊标签→time.span/event.name/written_during 全缺席、零 relation；KNOWN 两处：御前醉草乐词语境（两源四要素全同）+贺知章谪仙人之赏（两源）；卒地两传分歧并列不裁决。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-yj-world' AS id, 'BACKGROUND' AS entity_type, 'yj-world' AS slug, '这个天下：皇帝要新乐词的时候' AS title, '四层处境背景（阶段 D 第 17 首·绝句第二例）；史实句均有逐字引证；background_line 绝句形制：每层一行（1/2/3/4）；乐府题不纪行旅+创作语境只有「天寶初」模糊标签→time.span/event.name/written_during 全缺席、零 relation；KNOWN 两处：御前醉草乐词语境（两源四要素全同）+贺知章谪仙人之赏（两源）；卒地两传分歧并列不裁决。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-yj-person' AS id, 'BACKGROUND' AS entity_type, 'yj-person' AS slug, '这个人：谪仙人的着陆点' AS title, '四层处境背景（阶段 D 第 17 首·绝句第二例）；史实句均有逐字引证；background_line 绝句形制：每层一行（1/2/3/4）；乐府题不纪行旅+创作语境只有「天寶初」模糊标签→time.span/event.name/written_during 全缺席、零 relation；KNOWN 两处：御前醉草乐词语境（两源四要素全同）+贺知章谪仙人之赏（两源）；卒地两传分歧并列不裁决。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-yj-scene' AS id, 'bg-yj-scene' AS subject_id, 'context' AS property_key, '白露/罗袜/下帘/望月全诗本文；玉阶=宫殿台阶为汉诗传统（非本地史料，标注为读法）；为谁立、立于何宫——两传无一字，不编。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-yj-city' AS id, 'bg-yj-city' AS subject_id, 'context' AS property_key, '长安关联由两传「天寶初」段给出（入京因果链逐字：筠被召故白至长安）；「天宝初」是时代标签不是年份——模糊时代照登不铸造；诗本身乐府题零城串，长安为最有依据的猜想、非断言。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-yj-world' AS id, 'bg-yj-world' AS subject_id, 'context' AS property_key, '御前醉草乐词语境——旧传「水灑面成十餘章」段与新传「靧面援筆成文」段两源独立一致（醉/召/洒水/立就四要素全同）升 KNOWN；此 KNOWN 只覆盖语境，两传均无年标题级坐标（只说天宝初）→ 诗 time.span/event.name/written_during 零铸造、零 relation；语境年不可得即诗年不可得。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-yj-person' AS id, 'bg-yj-person' AS subject_id, 'context' AS property_key, 'KNOWN 两处之一：贺知章谪仙人之赏——旧传「此天上謫仙人也」与新传「子，謫仙人也」两源独立一致；**两传分歧处不升任何等级**：卒地（旧传醉死宣城/新传葬当涂青山）并列照登不裁决；certainty 不覆盖任何系年与卒地。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-yj-scene' AS subject_id, 'context' AS property_key, 'claim-bg-yj-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-yj-city' AS subject_id, 'context' AS property_key, 'claim-bg-yj-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-yj-world' AS subject_id, 'context' AS property_key, 'claim-bg-yj-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-yj-person' AS subject_id, 'context' AS property_key, 'claim-bg-yj-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-yj-scene' AS id, 'work-t300-308' AS work_id, 'SCENE' AS layer, '这首诗只有二十个字，开场就是一级台阶：「玉階生白露，夜久侵羅襪」——玉石台阶上露水一点点积起来，久了，凉意漫进丝袜。没有人，没有事，只有一个站了很久的人的脚边证据。
本传给不了这场站立——两传写李白全是动（召/召入/醉/放还/流夜郎），没有一条说他站在谁的阶下。玉阶在汉诗传统里是宫殿的台阶，但把它坐实成某座宫、某个人，本地史料无一字——诗内证据到「侵罗袜」为止，再往前一步就是编。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-yj-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-yj-city' AS id, 'work-t300-308' AS work_id, 'CITY' AS layer, '这座城诗里不出现，但要给这首诗找一个发生的城，史料里唯一够格的是长安——理由不是诗，是传：两传都把李白与「樂府新詞/樂章」拴在天寶初的长安上。旧传「天寳初，客遊會稽，與道士吳筠隱於剡中」——吴筠被召，新传补上因果「筠被召，故白亦至長安」。
但「天寶初」就是两传能给的全部：不是年，是一个时代标签。乐府旧题不纪行旅，本传不系年——长安是最有依据的猜想，猜想不是断言。time.span/event.name/written_during 一个都不造。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-yj-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-yj-world' AS id, 'work-t300-308' AS work_id, 'WORLD' AS layer, '「却下水晶簾，玲瓏望秋月」——进了屋，放下水精帘，隔着帘子望月亮。诗里的天下小到一个闺阁；这个人的天下大到一个词牌：玄宗要新乐词的时候，两唐书各自记下了同一场征召。
旧传：「玄宗度曲，欲造樂府新詞，亟召白，白已臥於酒肆矣。召入，以水灑面，即令秉筆，頃之成十餘章」；新传：「帝坐沈香亭子，意有所感，欲得白為樂章；召入，而白已醉，左右以水靧面，稍解，援筆成文，婉麗精切無留思」——醉/召/洒水/立就，四个要素两个独立讲法全同：**皇帝的乐词需求就是李白一部分作品的真实生产场景**，这是本传能给的最硬的「为什么写」。但两传都只说「天寶初」，没有年标题级坐标——语境 KNOWN，年份照样不可得。' AS body_text, 'SENIOR' AS audience, 'claim-bg-yj-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-yj-person' AS id, 'work-t300-308' AS work_id, 'PERSON' AS layer, '李白的定场诗不是他写的，是贺知章说的——而且两传各自在场：旧传「初賀知章見白，賞之曰：『此天上謫仙人也。』」；新传「往見賀知章，知章見其文，歎曰：『子，謫仙人也！』」——两源独立一致升 KNOWN：贺知章以「谪仙人」赏识过李白。
但同一个人在两传里连**死在哪**都不一致：旧传「竟以飲酒過度，醉死於宣城」；新传「度牛渚磯至姑孰，悅謝家青山，欲終焉。及卒，葬東麓」（当涂青山）。宣城对当涂，两源直接分歧——不裁决，并列照登；「谪仙人」飘下来的仙人，连着陆点两传都没谈拢，这本身就是李白传写的诚实样子。
「玲珑望秋月」二十个字的怨，放在这样一个人名下：他的诗一部分是皇帝要的，一部分是自己要的——这首哪边都不是，本地史料给不了判词，就不给判词。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-yj-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-yj-scene' AS claim_id, 'source-ws-t300-308' AS source_id, '页面 玉階怨（header title+author 两字段+第1、2句，四段以「……」相連——乐府旧题之页内直证+开场台阶；页内实测无 {{另|}} 异文，「查过、干净」；全文另见 V018 claim-t300-308-text 引文）' AS locator, '| title    = [[玉階怨]]……| author   = 李白……玉階生白露，……玉階生白露，夜久侵羅襪。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-yj-city' AS claim_id, 'source-quantangshi-164' AS source_id, '页面 全唐詩/卷164（本诗锚点+转引用桩 {{:玉階怨 (李白)}}；卷首 Collection header 的 noauthor 字段为空——卷页无作者标注、无正文，正文证据在诗页；同 V022/V025–V035 桩教训）' AS locator, '==[[玉階怨 (李白)|玉階怨]]==
{{:玉階怨 (李白)}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-yj-city' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·李白传天宝初段（天寳初/会稽吴筠——模糊时代标签原文，旧传侧）' AS locator, '天寳初，客遊會稽，與道士吳筠隱於剡中。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-yj-city' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零二·文藝中·李白传天宝初段（筠被召故白亦至长安——入京因果，新传侧；与旧传同段并证「天宝初」为两传共同的模糊标签）' AS locator, '天寶初，南入會稽，與吳筠善，筠被召，故白亦至長安。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-yj-world' AS claim_id, 'source-ws-t300-308' AS source_id, '页面 玉階怨（第3、4句逐字——闺阁的小天下与下方御前的大场景并读）' AS locator, '却下水晶簾，……却下水晶簾，玲瓏望秋月。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-yj-world' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·李白传乐府新词段（玄宗度曲欲造乐府新词/水灑面/頃之成十餘章——两源合龙第一源）' AS locator, '白旣嗜酒，日與飲徒醉於酒肆。玄宗度曲，欲造樂府新詞，亟召白，白已臥於酒肆矣。召入，以水灑面，即令秉筆，頃之成十餘章，帝頗嘉之。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-yj-world' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零二·文藝中·李白传乐章段（沈香亭欲得乐章/水靧面/援筆成文——两源合龙第二源；醉/召/洒水/立就四要素与旧传全同，措辞各自逐字）' AS locator, '帝坐沈香亭子，意有所感，欲得白為樂章；召入，而白已醉，左右以水靧面，稍解，援筆成文，婉麗精切無留思。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-yj-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·李白传（谪仙人段+传统卒地段；两段以「……」相連，出处同卷同传——谪仙人两源合龙旧传侧/卒地分歧旧传侧）' AS locator, '初賀知章見白，賞之曰：「此天上謫仙人也。」……竟以飲酒過度，醉死於宣城。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-yj-person' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零二·文藝中·李白传（谪仙人段+青山卒段；两段以「……」相連，出处同卷同传——谪仙人两源合龙新传侧/卒地分歧新传侧，与旧传并列不裁决）' AS locator, '往見賀知章，知章見其文，歎曰：「子，謫仙人也！」……白晚好黃老，度牛渚磯至姑孰，悅謝家青山，欲終焉。及卒，葬東麓。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（绝句：每层一行） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-yj-scene' AS background_id, 'text-work-t300-308-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-yj-city' AS background_id, 'text-work-t300-308-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-yj-world' AS background_id, 'text-work-t300-308-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-yj-person' AS background_id, 'text-work-t300-308-ws' AS version_id, 4 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 36, 'Li Bai Yu-jie-yuan background layers (stage-D poem 17, second quatrain): the two Tang histories jointly supply a creation context instead of a year -- JTS records the emperor fixing a tune and wanting new yuefu lyrics, Bai drunk at the wine-shop, water splashed on his face, a dozen-plus pieces composed at once, XTS independently tells the same scene at the Incense-Pavilion with face-washed and brush flowing (drunk / summoned / water / composed-on-the-spot: all four elements agree across two sources) -- KNOWN for the context only; both biographies date it merely kai-yuan-era tian-bao chu, a vague era label with no year-heading coordinate, so the dating verdict for the eleventh poem is: yuefu title records no journey AND the creation context itself has no year -- no year-table arithmetic, time.span/event.name/written_during absent, zero relations; He Zhizhang-s Banished-Immortal praise quoted verbatim from both biographies -- second KNOWN; a registered divergence: JTS says he died drunk at Xuancheng, XTS says he loved Qing-shan at Dangtu and was buried at its east foot -- two sources directly disagree on the place of death, side by side with no ruling, and neither KNOWN covers it; slices deliberately avoid every biography passage V032 already cited (Han-lin recommendation, Gao Lishi boot, Prince Yong, exile, Cui Zongzhi) and are range-checked into the Li Bai biography block at generation time; one new source: quan-tang-shi juan 164 page (anchor plus disambiguated transclusion stub Yu-jie-yuan (Li Bai); Collection header noauthor field empty -- no author attribution on the volume page, said honestly; PENDING per V031/V035 precedent); background_line uses the quatrain shape: one line per layer (1/2/3/4)'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 36);
COMMIT;
