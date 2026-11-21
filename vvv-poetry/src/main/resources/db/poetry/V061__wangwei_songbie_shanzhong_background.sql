-- V061：王維《送別》(work-t300-145「山中相送罷」) 四层背景（阶段 D 第 42 首·送目与王孫）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V014、V015、V016、V018、V026、V037、V040、V057、V059、V060 已执行
--       （work-t300-145 与其 text-work-t300-145-ws、source-ws-t300-145 是 V018 的行；
--       source-quantangshi-128 是 V026/V040 已立的卷128 源行（本迁移第六次复用，零新源）；
--       source-xintangshu-wenyi 是 V016 的行；source-zizhi-tongjian-events 是 V014/V015
--       已立的通鉴事件源；同名另一首 054「下馬飲君酒」的背景是 V037）。
--       本迁移零新 source（audit 断言无诗源表新建插入语句）。
--
-- 数据源（可复现）：emit_v061.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/送別__山中相送罷_.txt（{{另}}×1×75%+底注尾巴双一作异题注+繁体 title 行）、
--   舊唐書卷190下/新唐書卷202（传无送字负证+召缙句首引+願歸所任官零重开）、
--   全唐詩卷128（首句消歧锚+桩）/卷523（归不归撞句在册）、
--   通鑑卷228/232/234（王孫恰二+春草恰一+三处年标题窗口）+ 通鑑 75 卷/全唐詩 118 卷
--   存快照负证计数扫描（送別/送友/柴扉/歸不歸/年年/王孫/春草）+
--   既有迁移引文域逐句查重——传区间归属、首引/二引/零重开前提全部生成时断言。
--
-- 做：4 BACKGROUND content/claim/background + 5 组逐字引用（(claim,source) 主键每对恰一行）+
--   4 行 background_line（四句绝句 1/1/1/1 第二次（V056 首用）：scene→1 city→2 world→3 person→4，
--   绑 text-work-t300-145-ws 的 4 行）+ 零 poetry_source 行 + 不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「題有送目，送目在史部七十五卷全零；詩有王孫，王孫在史部唯宗室之裔與君長之孫」）：
--   * 送目/送友类名全零（类名不进史部第二例）；王孫恰二+春草恰一逐卷闭域+三窗口入引为判决证据；
--   * 王孫之楚辞典与问而不复问/问而上表均标明读法声明非史实（页上无自注）；
--   * 异文明年/年年引文含标记原样；同页两形并存再验（V018 归一形 vs 本迁移原样形）；
--   * 双一作异题注（一作山中送別，一作送友）一题两案照登不裁决（audit 硬卡）；
--   * 同名两首（054/145）消歧谱：首句消歧式首见（对照 V059 作者消歧式）；
--   * 此诗正文第二引上限用满：V018 一引在先（查重针归一形恰一处），对后来迁移关闭；
--   * vol523 撞句「今宵歸不歸」在册不引（audit 硬卡零混入）；
--   * KNOWN 零如实记录（第十七例，audit 反向断言 SQL 无 KNOWN 字面量）；
--   * 願歸所任官（V040）/柴毁骨立（V057）/歴右拾遺三连（V059）/服除句（V060）判例只引不重开。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 60，不含 61
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-145-%';             -- 空
--   SELECT id FROM poetry_source WHERE id='source-quantangshi-128';     -- 恰 1（V026/V040 已立，本迁移复用不新建）
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-145-ws';  -- 恰 4
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-145-%';       -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-145';                                  -- 4（1/1/1/1）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-145-%';  -- 四行全 LIKELY（有意全 LIKELY）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-145'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-145';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-145-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
--   SELECT COUNT(*) FROM poetry_source WHERE id='source-quantangshi-128';  -- 恰 1（复用，非本迁移所立）
-- 回滚: recovery/V061_rollback.sql（按 id 全枚举删除；零 source 删除——卷128 源行为 V026/V040 所立）
START TRANSACTION;

-- ---------- 1. 零新 source（卷128 源行 V026/V040 已立，本迁移第六次复用） ----------
-- ---------- 2. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-145-scene' AS id, 'BACKGROUND' AS entity_type, '145-scene' AS slug, '眼前：送罢人掩门的一路安静' AS title, '四层处境背景（阶段 D 第 42 首·四句绝句 1/1/1/1 第二次）；史实句均有逐字引证；系年第三十六次判决（题证系列第廿四状·送目与王孫）「題有送目，送目在史部七十五卷全零；詩有王孫，王孫在史部唯宗室之裔與君長之孫」——通鉴「送別」「送友」类名全零（类名不进史部第二例，V059 雜詩之后）而王孫恰二（闭域+双窗口）：建中四年（癸亥，七八三）杀郡王王子王孫凡七十七人+貞元九年（癸酉，七九三）異牟尋自稱唐故雲南王孫（同字两界第六形态，三段史文逐字入引为判决证据）；春草恰一=貞元三年（丁卯，七八七）「春草未生，馬不能舉足」（史的春草系马，诗的春草系人，入引）；全唐詩「歸不歸」恰一=vol523 今宵歸不歸（撞句在册不引）+「柴扉」恰 8 在册；同名诗的消歧谱首录（三百首王维两首《送別》054/145——卷128 首句消歧式锚点首见，对照 V059 作者消歧式；同名两页 title 繁简互异各按原样）；底注尾巴双一作异题注「一作山中送別，一作送友」=一题两案纯文本第四形态照登；{{另}}×1×75% 正交第五度+同页两形并存再验；零新源（卷128 源 V026/V040 已立第六次复用）；此诗正文第二引上限用满对后来关闭（V018 在先+全库查重归一形针）；PERSON 首引新传召缙结局句（願歸所任官 V040 零重开；两传王维段送字全零——传无送字）；KNOWN 零如实记录（第十七例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-145-city' AS id, 'BACKGROUND' AS entity_type, '145-city' AS slug, '这座城：两首同名诗的消歧谱' AS title, '四层处境背景（阶段 D 第 42 首·四句绝句 1/1/1/1 第二次）；史实句均有逐字引证；系年第三十六次判决（题证系列第廿四状·送目与王孫）「題有送目，送目在史部七十五卷全零；詩有王孫，王孫在史部唯宗室之裔與君長之孫」——通鉴「送別」「送友」类名全零（类名不进史部第二例，V059 雜詩之后）而王孫恰二（闭域+双窗口）：建中四年（癸亥，七八三）杀郡王王子王孫凡七十七人+貞元九年（癸酉，七九三）異牟尋自稱唐故雲南王孫（同字两界第六形态，三段史文逐字入引为判决证据）；春草恰一=貞元三年（丁卯，七八七）「春草未生，馬不能舉足」（史的春草系马，诗的春草系人，入引）；全唐詩「歸不歸」恰一=vol523 今宵歸不歸（撞句在册不引）+「柴扉」恰 8 在册；同名诗的消歧谱首录（三百首王维两首《送別》054/145——卷128 首句消歧式锚点首见，对照 V059 作者消歧式；同名两页 title 繁简互异各按原样）；底注尾巴双一作异题注「一作山中送別，一作送友」=一题两案纯文本第四形态照登；{{另}}×1×75% 正交第五度+同页两形并存再验；零新源（卷128 源 V026/V040 已立第六次复用）；此诗正文第二引上限用满对后来关闭（V018 在先+全库查重归一形针）；PERSON 首引新传召缙结局句（願歸所任官 V040 零重开；两传王维段送字全零——传无送字）；KNOWN 零如实记录（第十七例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-145-world' AS id, 'BACKGROUND' AS entity_type, '145-world' AS slug, '这个天下：史的春草系马，诗的春草系人' AS title, '四层处境背景（阶段 D 第 42 首·四句绝句 1/1/1/1 第二次）；史实句均有逐字引证；系年第三十六次判决（题证系列第廿四状·送目与王孫）「題有送目，送目在史部七十五卷全零；詩有王孫，王孫在史部唯宗室之裔與君長之孫」——通鉴「送別」「送友」类名全零（类名不进史部第二例，V059 雜詩之后）而王孫恰二（闭域+双窗口）：建中四年（癸亥，七八三）杀郡王王子王孫凡七十七人+貞元九年（癸酉，七九三）異牟尋自稱唐故雲南王孫（同字两界第六形态，三段史文逐字入引为判决证据）；春草恰一=貞元三年（丁卯，七八七）「春草未生，馬不能舉足」（史的春草系马，诗的春草系人，入引）；全唐詩「歸不歸」恰一=vol523 今宵歸不歸（撞句在册不引）+「柴扉」恰 8 在册；同名诗的消歧谱首录（三百首王维两首《送別》054/145——卷128 首句消歧式锚点首见，对照 V059 作者消歧式；同名两页 title 繁简互异各按原样）；底注尾巴双一作异题注「一作山中送別，一作送友」=一题两案纯文本第四形态照登；{{另}}×1×75% 正交第五度+同页两形并存再验；零新源（卷128 源 V026/V040 已立第六次复用）；此诗正文第二引上限用满对后来关闭（V018 在先+全库查重归一形针）；PERSON 首引新传召缙结局句（願歸所任官 V040 零重开；两传王维段送字全零——传无送字）；KNOWN 零如实记录（第十七例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-145-person' AS id, 'BACKGROUND' AS entity_type, '145-person' AS slug, '这个人：传里一个送字没有' AS title, '四层处境背景（阶段 D 第 42 首·四句绝句 1/1/1/1 第二次）；史实句均有逐字引证；系年第三十六次判决（题证系列第廿四状·送目与王孫）「題有送目，送目在史部七十五卷全零；詩有王孫，王孫在史部唯宗室之裔與君長之孫」——通鉴「送別」「送友」类名全零（类名不进史部第二例，V059 雜詩之后）而王孫恰二（闭域+双窗口）：建中四年（癸亥，七八三）杀郡王王子王孫凡七十七人+貞元九年（癸酉，七九三）異牟尋自稱唐故雲南王孫（同字两界第六形态，三段史文逐字入引为判决证据）；春草恰一=貞元三年（丁卯，七八七）「春草未生，馬不能舉足」（史的春草系马，诗的春草系人，入引）；全唐詩「歸不歸」恰一=vol523 今宵歸不歸（撞句在册不引）+「柴扉」恰 8 在册；同名诗的消歧谱首录（三百首王维两首《送別》054/145——卷128 首句消歧式锚点首见，对照 V059 作者消歧式；同名两页 title 繁简互异各按原样）；底注尾巴双一作异题注「一作山中送別，一作送友」=一题两案纯文本第四形态照登；{{另}}×1×75% 正交第五度+同页两形并存再验；零新源（卷128 源 V026/V040 已立第六次复用）；此诗正文第二引上限用满对后来关闭（V018 在先+全库查重归一形针）；PERSON 首引新传召缙结局句（願歸所任官 V040 零重开；两传王维段送字全零——传无送字）；KNOWN 零如实记录（第十七例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 3. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-145-scene' AS id, 'bg-145-scene' AS subject_id, 'context' AS property_key, '四句全诗本文（ws 页 {{另}}×1、其余标记全零、Textquality 75%——单枚异文与不完备并存，正交横截面第五度复现）；异文（明年/年年）引文含标记原样照登不裁决；同页两形并存再验：V018 正文引文系异文取首项的归一文本，本迁移 SCENE 引文含标记原样，各从其录；王孫=楚辞「王孫游兮不歸」之典系读法声明非史料断言（页上无自注）；全句第二引：正文 V018 text claim一引在先（生成时全库查重恰一处，查重针取归一形「王孫歸不歸」），两度上限至此用满、此诗正文对后来迁移关闭（audit 硬卡）。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-145-city' AS id, 'bg-145-city' AS subject_id, 'context' AS property_key, '同名诗的消歧谱首录：三百首里王维两首《送別》（054 V037 已立/本篇 145），卷128 锚点系首句消歧式「(山中相送罷)|送別」（首句消歧式首见——对照 V059作者消歧式「(王維)」，同一体系两种消歧器，audit 照登硬卡）；同名两页 title 行繁简互异（054 简体送别 V037 已录/本篇繁体送別）各按原样；底注尾巴双一作异题注「一作山中送別，一作送友」=一题两案纯文本第四形态（V052/V055/V057 之后，audit 硬卡字样）；底注全锚（同 V058–V060）；卷128「送別」恰 3=锚 2+桩 1（机器断言闭域）；source-quantangshi-128 V026/V040 已立、第六次复用零新源；分类行「送別詩」照登+非史料声明+不升格；题有送目而无时→零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-145-world' AS id, 'bg-145-world' AS subject_id, 'context' AS property_key, '通鉴「送別」「送友」类名全零（类名不进史部第二例，V059 之后）+柴扉/歸不歸/年年全零；王孫恰二（闭域+双窗口机器断言）=tj-228 建中四年（癸亥，七八三）杀郡王王子王孫凡七十七人+tj-234 貞元九年（癸酉，七九三）異牟尋自稱唐故雲南王孫——史部的王孫一为宗室之裔一为君长之孙，与诗中楚辞典同字两界（第六形态），三段史文逐字入引为判决证据（audit 硬卡）；春草恰一处（闭域+窗口断言）=tj-232 貞元三年（丁卯，七八七）「吾在河曲，春草未生，馬不能舉足」——史的春草系马、诗的春草系人（入引为判决证据）；全唐詩「歸不歸」恰一=vol523 他人句今宵歸不歸（撞句在册不引，机器断言）；「柴扉」恰 8 他卷在册；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-145-person' AS id, 'bg-145-person' AS subject_id, 'context' AS property_key, '新传召缙结局句首引（生成时全库引文域查重：召縉為左散騎常侍既往零命中，audit 硬卡）；其前句「願歸所任官，放田里」V040 已引在册零重开（audit 硬卡字样）；问而不复问是诗/问而上表是史为读法声明非史实；两传王维段送字/柴扉/王孫全零（机器断言——写尽送别的人传无送字）；已用判例句零重开；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-145-scene' AS subject_id, 'context' AS property_key, 'claim-bg-145-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-145-city' AS subject_id, 'context' AS property_key, 'claim-bg-145-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-145-world' AS subject_id, 'context' AS property_key, 'claim-bg-145-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-145-person' AS subject_id, 'context' AS property_key, 'claim-bg-145-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 4. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-145-scene' AS id, 'work-t300-145' AS work_id, 'SCENE' AS layer, '四句是送罢人回家的一路安静：山里送走朋友回来，天黑了，把柴门掩上（「山中相送罷，日暮掩柴扉」——送与掩，一贯到底：门掩上，心还开着）；明年春草再绿的时候，你回不回来呢（「春草{{另|明年|年年}}綠，王孫歸不歸」——明年一作年年，照登；王孫用的是《楚辞》「王孫游兮不歸」的典——问的是朋友，此读法系本层声明，页上无一字自注；此诗正文系**第二引**：V018 text claim 已一引在先（其形系异文取首项的归一文本），全库查重恰一处，两度上限至此用满，此诗正文对后来迁移关闭）。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-145-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-145-city' AS id, 'work-t300-145' AS work_id, 'CITY' AS layer, '《唐詩三百首》里王维有**两首《送別》**：054「下馬飲君酒」（V037 已立背景）与本首 145「山中相送罷」——同名两首靠首句消歧：ws 页文件名送別__山中相送罷_.txt 是消歧的，卷128 的锚点「==[[送別 (山中相送罷)|送別]]==」把首句写进消歧器、把「送別」留给展示（**首句消歧式首见**：V059 雜詩是作者消歧式「(王維)」，本篇是首句消歧式，同一体系两种消歧器，audit 照登硬卡）。两页 title 行形制互异：054 页简体「送别」（V037 已录）、本篇繁体「送別」——同名两页繁简各按各页原样照登。底注尾巴「一作山中送別，一作送友」：**一页同时两异题候选（一题两案，纯文本异注第四形态**：V052 署名异说、V055 川一作水、V057 一名式之后），照登不裁决（audit 硬卡字样）。页 {{另}}×1（明年/年年）而其余标记全零、75%；V018 正文归一形与本迁移标记原样形**同页两形并存再验**。底注全锚（卷128#送別，同 V058–V060 全锚形态）；source-quantangshi-128 系 V026/V040已立、第六次复用**零新源**；分类行「送別詩」系整理者动作（V048 判例）——「送別詩」这个类目与 WORLD 层「送目」的通鉴全零恰成一对：整理者建了柜，史部不收。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-145-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-145-world' AS id, 'work-t300-145' AS work_id, 'WORLD' AS layer, '**題有送目，送目在史部七十五卷全零**：通鉴「送別」「送友」两个类名零命中（类名不进史部第二例，V059 雜詩之后），「柴扉」「歸不歸」「年年」也全零——送别的语汇整场进不了史部。而「王孫」恰二处（文件闭域+双年标题窗口机器断言），处处不是这场相送：建中四年（癸亥，七八三）朱泚之乱，「**殺郡王、王子、王孫凡七十七人**」——史部的王孫是被屠戮的宗室之裔；貞元九年（癸酉，七九三）南诏異牟尋上表「**自稱唐故雲南王孫、吐蕃贊普義弟日東王**」——史部的王孫是君长之孙的政治头衔。**诗的「王孫歸不歸」用楚辞的典问朋友回不回来；史部的王孫是族谱与封号：七十七人被杀，或自称以要盟**（同字两界第六形态，三段史文逐字入引为判决证据，audit 硬卡）。**「春草」恰一处**（闭域+窗口断言）：貞元三年（丁卯，七八七）突厥语者追忆「**吾在河曲，春草未生，馬不能舉足**」——史的春草是马料季：春草未生则马不能行；诗的春草明年绿是候归之草——**史的春草系马，诗的春草系人**。全唐詩「歸不歸」恰一处=vol523 他人句「今宵歸不歸」（撞句在册不引不牵合，机器断言）；「柴扉」恰 8 处他卷在册。本层零铸造零 relation。' AS body_text, 'SENIOR' AS audience, 'claim-bg-145-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-145-person' AS id, 'work-t300-145' AS work_id, 'PERSON' AS layer, '诗里说「但去莫復問」——你去吧，我不再问了；传里他却为一问写过表：V040 已引新传他自表「願歸所任官，放田里」求换弟弟王縉还京（在册零重开，audit 硬卡字样）；本迁移首引紧接的结局一句——「**久乃召縉為左散騎常侍。**」（生成时全库查重：既往零入引，audit 硬卡）：朝廷终究把王縉召回朝做了左散騎常侍。**问而不复问是诗，问而上表是史**：「春草明年綠，王孫歸不歸」的问出口就收在诗里；「弟弟几时回来」的问，他写成了一道表（读法声明，非史实）。
**两传王维段「送」字全零**（机器断言——写尽送别的人，传里一个送字没有；「柴扉」「王孫」两传段亦全零）；已用判例句（願歸所任官 V040/柴毁骨立 V057/歴右拾遺三连 V059/服除句 V060/輞川系列 V035 起）一个不重开；certainty 不覆盖任何系年。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-145-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 5. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-145-scene' AS claim_id, 'source-ws-t300-145' AS source_id, '页面 送別 (山中相送罷)（header author+两联四句，三段以「……」相連——全句**第二引**：正文 V018 text claim 一引在先（其形系异文取首项的归一文本，本引文含 {{另}} 标记原样——同页两形并存各从其录），生成时全库查重恰一处，**两度上限至此用满，此诗正文对后来迁移关闭**；{{别}}/{{*}}/<ref> 全零、75%；王孫之典页上无自注，系引者读法声明）' AS locator, '| author   = 王維……山中相送罷，日暮掩柴扉。……春草{{另|明年|年年}}綠，王孫歸不歸。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-145-city' AS claim_id, 'source-ws-t300-145' AS source_id, '页面 送別 (山中相送罷)（header title+页底注+分类行三段并收——title 行繁体「送別」（同名两首之另一页 054 系简体，各按各页原样）；底注尾巴双一作异题注「一作山中送別，一作送友」=一题两案纯文本第四形态，照登不裁决；分类行系整理者动作：非史料声明、不升格）' AS locator, '| title    = 送別……| notes    = {{Textquality|75%}}↑ [[全唐詩/卷128#送別|全唐詩·卷128]] 一作山中送別，一作送友……[[Category:送別詩]]' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-145-city' AS claim_id, 'source-quantangshi-128' AS source_id, '卷一百二十八·王維《送別》篇题锚点+转引桩（**首句消歧式首见**：锚点「(山中相送罷)|送別」把首句写进消歧器、题目留给展示——对照 V059 作者消歧式；卷128「送別」恰 3=锚 2+桩 1 机器断言；源行系 V026/V040 已立、本迁移第六次复用零新源）' AS locator, '==[[送別 (山中相送罷)|送別]]==……{{:送別 (山中相送罷)}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-145-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '卷二百二十八·建中四年（癸亥，七八三）殺郡王王子王孫段……卷二百三十四·貞元九年（癸酉，七九三）異牟尋自稱雲南王孫段……卷二百三十二·貞元三年（丁卯，七八七）春草未生馬不能舉足段（**通鉴「送別」「送友」类名全零、王孫恰二、春草恰一**：文件闭域+三处年标题窗口机器断言——史部的王孫一为被屠宗室一为君长头衔，与诗中楚辞典同字两界第六形态；史的春草系马，诗的春草系人；三段史文逐字入引为判决证据；vol523 他人撞句「今宵歸不歸」在册零入引）' AS locator, '殺郡王、王子、王孫凡七十七人。……自稱唐故雲南王孫、吐蕃贊普義弟日東王。……吾在河曲，春草未生，馬不能舉足' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-145-person' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百二·文艺中·王維传召缙结局句（生成时全库引文域查重：既往零入引，本迁移首引；其前「願歸所任官，放田里」V040 已引零重开；与诗中「但去莫復問」并置是读法声明；两传王维段送字全零——传无送字，机器断言）' AS locator, '久乃召縉為左散騎常侍。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 6. background_line（四句绝句 1/1/1/1 第二次） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-145-scene' AS background_id, 'text-work-t300-145-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-145-city' AS background_id, 'text-work-t300-145-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-145-world' AS background_id, 'text-work-t300-145-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-145-person' AS background_id, 'text-work-t300-145-ws' AS version_id, 4 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 7. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 61, 'Wang Wei''s Farewell (the mountain poem, work-t300-145) background layers (stage-D poem 42, quatrain 1/1/1/1, second use): dating verdict thirty-six, twenty-fourth shape of the title-evidence series -- the farewell label and the prince''s grandson in two realms: the character-strings farewell/farewell-to-a-friend (the category names of parting poetry) score zero across all seventy-five Tongjian volumes (second instance of category-names-barred-from-the-histories after za-shi in V059), and brush-gate, will-he-return, year-upon-year likewise zero; yet prince''s grandson appears exactly twice (file-closed, twin year-heading windows): in 783, during the Zhu Ci coup, commandery princes, princes and prince''s-grandsons -- seventy-seven imperial kinsmen -- were slaughtered to cut off the people''s hope, and in 793 the Nanzhao king Yimouxun styled himself in his throne table "grandson of a former king of Yunnan under Tang, sworn younger brother of the Tibetan emperor" -- in the histories a prince''s grandson is either butchered kin or a political title, while the poem''s "prince, will you return?" borrows the Chuci''s gentle allusion to ask a friend: the sixth same-character split (three history sentences excerpted as the verdict''s evidence, audit hard-assert); spring grass exactly once (file-closed, windowed): in 787 a Turkic-speaker recalls that at the He-qu bend when spring grass had not yet grown the horses could not lift a foot -- the histories'' spring grass tethers horses, the poem''s spring grass tethers the homeward hope of a friend; quan tang shi holds exactly one will-he-return line (vol 523, someone else''s palace verse: logged never quoted) and eight brush-gate lines logged elsewhere; the disambiguation genealogy of same-titled poems first recorded: the Three Hundred Poems carry two Farewells by Wang Wei (054 done in V037, this 145) -- juan 128''s anchor is a first-line-disambiguation (the disambiguator is the opening line, the display name stays Farewell; against V059''s author-disambiguation: two disambiguators in one system), and the two ws pages differ in script (054 simplified, 145 traditional, each logged as found); the base-note tail carries a double alternative-title gloss (one title, two candidates: the fourth plain-text form) logged never adjudicated; one {{另}} marker with 75% (orthogonality fifth time) and same-page two-forms co-existence re-verified; zero new sources (juan 128''s row reused for the sixth time); the poem body hits its two-use ceiling (V018 first, normalized needle, closure declared); PERSON first-cites the New History''s sentence on the court finally recalling Wang Jin as 左散騎常侍 (the earlier self-immolation table sentence stays closed to V040; both biographies contain not one occurrence of the character farewell -- the man who wrote parting for the ages, machine-asserted); KNOWN zero honestly recorded (seventeenth instance, audit reverse-asserts); closed precedent keywords stay out of citations'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 61);
COMMIT;
