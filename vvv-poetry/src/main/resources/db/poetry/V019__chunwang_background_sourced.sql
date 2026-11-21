-- V019：《春望》四层背景去草稿化——正文带证 + V004 剩余占位引证换逐字原文（阶段 D）。MySQL 5.6.40 兼容。
-- 只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。前置：V004、V011、V015、V017 已执行。
--
-- 数据源（可复现）：引文由 emit_v019.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，
--   与快照逐字节一致；{{YL|}}、{{SK notes|}}、{{SKchar|}} 等录入标记原样保留（含 {{SKchar|2593}} 占位字符——
--   那是扫描版缺字的录入标记，照登不猜字）。快照：杜詩詳註(四庫全書本)卷四、資治通鑑卷217/218/222、
--   新唐書卷201、舊唐書卷190下。
--
-- 做：4 段背景正文重写（只说引文支撑得起的话，注家读法言明是读法）；
--   V004 剩的 3 条「待人工核对」背景占位引证换成真实来源+定位+逐字原文（scene/city/world）；
--   2 条新增引用（world×注本顾宸语、person×鹤注陷贼营）；person 两条既有引证「……」扩接新证据句；
--   2 条 claim 文本修正（world 层「音信断绝」史无明文，改为注家分歧的如实转述）；
--   3 条 certainty DISPUTED→LIKELY（两史+注本逐字引文齐备；不升 KNOWN——系年未裁决）。
-- 不做：不核验来源（走 verifySource + scripts/db/verify-sources.sh）、不改 status、不发布；
--   不裁决 757/758 系年（758 说至今无来源，gap-chunwang-dating-open 保持 OPEN）；
--   不写 poetry_review_log（append-only，评审结论走 Studio）；
--   不动 background_line、不动 V004/V011/V017 的迁移文件。
--
-- 诚实边界：
--   * 「家书抵万金≠音信断绝是史实」——顾宸语就录在同一条鹤注注文里，正文如实呈现分歧；
--   * 司马光语见于四库本《杜詩詳註》转引，页面自述需据扫描版校对：正文与引文照登快照，不据记忆改写；
--   * 生卒两说（766/大历中，皆年五十九、无生年）不裁决，正文不给年龄；
--   * 通鉴卷222 的 763 年标题在 V015 已引用于事件起讫，此处引于 world 层是不同 claim 上的独立引用，不冲突。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 18，不含 19
--   SELECT claim_id, source_id, locator FROM poetry_citation
--    WHERE claim_id IN ('claim-bg-scene','claim-bg-city','claim-bg-world') AND locator LIKE '待%';  -- 恰 3 行
--   SELECT COUNT(*) FROM poetry_citation WHERE locator LIKE '待%';      -- 记下来（应为 4：上述3条+claim-exp?若已清则3）
--   SELECT body_text FROM poetry_background WHERE id LIKE 'bg-chun-wang-%';  -- 4 段都含「待」
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_citation WHERE claim_id LIKE 'claim-bg-%' AND locator LIKE '待%';   -- 0
--   SELECT COUNT(*) FROM poetry_background WHERE id LIKE 'bg-chun-wang-%' AND body_text LIKE '%待复核%'; -- 0
--   SELECT certainty FROM poetry_claim WHERE id IN ('claim-bg-city','claim-bg-world','claim-bg-person'); -- LIKELY
--   SELECT COUNT(*) FROM poetry_citation WHERE locator LIKE '待%';      -- 比执行前少 3
-- 回滚: recovery/V019_rollback.sql（恢复 V004 原文/占位引证/原 certainty，删新增行与账本行）
START TRANSACTION;

-- ---------- 1. 四层正文重写（只替换仍含「待」的草稿文本，幂等且不误伤已复核文本） ----------
UPDATE poetry_background SET body_text = '城还在，山和河也还在，可城里已经没有从前那种人气了。春天照常来了，草木没人打理，越长越深。
这四句的读法不是我们编的：宋人录司马光的话说——「国破山河在」，明是无余物矣；「城春草木深」，明无人迹矣；花与鸟本是平时可娱之物，见之而泣、闻之而悲，「则时可知矣」。注家把这四句叫「春望之景，睹物伤怀」。以景物反衬城破，是历代注家公认的读法——它是解读的入口，不是史书记载的现场。'
 WHERE id = 'bg-chun-wang-scene' AND body_text LIKE '%待%';
UPDATE poetry_background SET body_text = '长安是帝国的心脏。756 年秋天叛军入城之后，宫阙、街市、官署还在，但秩序已经不在了。
秩序不在是什么样子，《资治通鉴》卷二一八记了两笔：禄山「命搜捕百官、宦者、宫女等，每获数百人，辄以兵卫送洛阳」，扈从不及、留在长安的王侯将相「诛及婴孩」；同年冬天同罗、突厥叛军逃归时，「长安大扰，官吏窜匿，狱囚自出」。杜甫此刻就在城里：两《唐书》都记他陷在贼中。'
 WHERE id = 'bg-chun-wang-city' AND body_text LIKE '%待%';
UPDATE poetry_background SET body_text = '这场战事的起与止，《资治通鉴》的年标题给出两个锚点：起于天宝十四年（乙未，公元七五五年）「禄山发所部兵……反于范阳」，终于广德元年（癸卯，公元七六三年）史朝义「穷蹙，缢于林中」。
但「烽火连三月、家书抵万金」是不是因为音信断绝，注家自己就在争：仇注引黄鹤认为此诗作于陷贼之时；同一注条里顾宸反驳说，杜甫移家奉先、入鄜州时「道路未尝隔绝」，质疑「家书抵万金」的处境。所以史书上并没有「战期音信断绝是常态」的直接记载——它是这首诗的说法，也是注家取舍后的读法，不是我们替杜甫补的事实。'
 WHERE id = 'bg-chun-wang-world' AND body_text LIKE '%待%';
UPDATE poetry_background SET body_text = '写这首诗前后，杜甫困在长安一带，官职低微，家人不在身边。
旧《唐书》本传记他天宝末献《三大礼赋》后被召试文章，只授了京兆府兵曹参军这样的小官；新《唐书》本传记「举进士不中第，困长安」，又说战乱中他家寄在鄜州，他衣衫破旧想去行在，半路被叛军抓住。至于写诗时他多大年纪——生卒年本身两说（旧传永泰二年卒、年五十九，新传只说大历中卒、年五十九，都没写生年），所以我们不给他标年龄。'
 WHERE id = 'bg-chun-wang-person' AND body_text LIKE '%待%';

-- ---------- 2. claim 文本修正（旧文本断言了史料没写的东西） ----------
UPDATE poetry_claim SET value_text = '「国破山河在」明无余物、「城春草木深」明无人迹（司马光语，见仇注卷四）：以春景反衬城破是注家读法。'
 WHERE id = 'claim-bg-scene' AND value_text = '以"城在而山河在"反衬物是人非。';
UPDATE poetry_claim SET value_text = '战事起于755（通鉴年标题+反于范阳）终于763（通鉴年标题+史朝义死）；「家书抵万金」是否因音信断绝，注家内部有分歧（顾宸质疑鹤注）。'
 WHERE id = 'claim-bg-world' AND value_text = '长期战事与音信断绝构成天下层。';

-- ---------- 3. V004 占位引证替换（WHERE 精确匹配旧 source+locator，幂等） ----------
UPDATE poetry_citation
   SET source_id = 'source-dushi-xiangzhu',
       locator = '卷四·春望·司馬溫公語（四庫本仇注转引；页面自述需据扫描版校对，引文照登快照）',
       evidence_excerpt = '司馬温公曰古人為詩貴於意在言外使人思而得之故言之者無罪聞之者足以戒近世惟杜子美最得詩人之體如春望詩國破山河在明無餘物矣城春草木深明無人跡矣花鳥平時可娛之物見之而泣聞之而悲則時可知矣他皆類此'
 WHERE claim_id = 'claim-bg-scene' AND source_id = 'source-dufu-nianpu-candidate'
   AND locator = '待人工核对：解诗依据（注本/研究）';
UPDATE poetry_citation
   SET source_id = 'source-zizhi-tongjian-events',
       locator = '通鑑卷二百十八·唐紀三十四（至德元載=756，由年表換算）；搜捕句與大擾句以「……」相連（同卷两事，同 claim 同来源只允许一行）',
       evidence_excerpt = '祿山命搜捕百官、宦者、宮女等，每獲數百人，輒以兵衛送洛陽。王、侯、將、相扈從車駕、家留長安者，誅及嬰孩。……同羅、突厥之逃歸也，長安大擾，官吏竄匿，獄囚自出。'
 WHERE claim_id = 'claim-bg-city' AND source_id = 'source-anshi-candidate'
   AND locator = '待人工核对：城况记载卷次';
UPDATE poetry_citation
   SET source_id = 'source-zizhi-tongjian-events',
       locator = '通鑑卷二百十七·唐紀三十三（天寶十四年標題）起點＋卷二百二十二·唐紀三十八（廣德元年標題）終點；年標題與紀事句以「……」相連；卷217內年標題作「天寶十四年」不作「載」，照登',
       evidence_excerpt = '玄宗至道大聖大明孝皇帝下之下天寶十四年（乙未，公元七五五年）……十一月，甲子，祿山發所部兵及同羅、奚、契丹、室韋凡十五萬眾，號二十萬，反於范陽。……肅宗文明武德大聖大宣孝皇帝下之下廣德元年（癸卯，公元七六三年）……朝義窮蹙，縊於林中，懷仙取其首以獻。'
 WHERE claim_id = 'claim-bg-world' AND source_id = 'source-anshi-candidate'
   AND locator = '待人工核对：战事时长与交通阻断记载';

-- ---------- 4. 新增引用 ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT 'claim-bg-world', 'source-dushi-xiangzhu',
       '卷四·春望·注條（顧宸語：對「家書抵萬金」处境的质疑，紧接趙氏語後；同條內另有仇氏「當從鶴説為正」的取舍，引文止于顧語）',
       '顧宸云十五年正月明皇在長安六月始幸蜀安得謂之破是時公移家在奉先五月方入鄜州道路未嘗隔絶安得云家書抵萬金'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_citation
  WHERE claim_id = 'claim-bg-world' AND source_id = 'source-dushi-xiangzhu');
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT 'claim-bg-person', 'source-dushi-xiangzhu',
       '卷四·春望·鶴注（「陷賊營時所作」：人在賊佔長安的注本依据；至德二載=757，由年表換算，係年仍 DISPUTED）',
       '春望{{SK notes|鶴注此當是{{YL|至德二載}}三月䧟賊營時所作'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_citation
  WHERE claim_id = 'claim-bg-person' AND source_id = 'source-dushi-xiangzhu');

-- ---------- 5. person 层既有引证扩接（同一 claim 同一来源只能一行，用「……」补证据句） ----------
UPDATE poetry_citation
   SET locator = '卷二百一·文藝上·杜甫传（V011 定位；困長安句與奔行在被獲句以「……」相連）',
       evidence_excerpt = '舉進士不中第，困長安。……時所在寇奪，甫家寓鄜，彌年艱窶，孺弱至餓死；肅宗立，自鄜州羸服欲奔行在，為賊所得'
 WHERE claim_id = 'claim-bg-person' AND source_id = 'source-dufu-zhuan-candidate'
   AND evidence_excerpt = '時所在寇奪，甫家寓鄜，彌年艱窶，孺弱至餓死；肅宗立，自鄜州羸服欲奔行在，為賊所得';
UPDATE poetry_citation
   SET locator = '卷一百九十下·杜甫传（V011 定位；授兵曹句與陷京師宵遁句以「……」相連，先卑官後陷賊，时序如传文）',
       evidence_excerpt = '天寳末，獻《三大禮賦》，{{SKchar|2593}}宗奇之，召試文章，授京兆府兵曹叅軍。……十五載，禄山䧟京師，肅宗徴兵靈武，甫自京師宵遁赴河西謁肅宗，於彭原郡拜右拾遺'
 WHERE claim_id = 'claim-bg-person' AND source_id = 'source-jiutangshu-dufu'
   AND evidence_excerpt = '十五載，禄山䧟京師，肅宗徴兵靈武，甫自京師宵遁赴河西謁肅宗，於彭原郡拜右拾遺';

-- ---------- 6. certainty DISPUTED→LIKELY（逐字引文齐备；系年未裁决所以不升 KNOWN） ----------
UPDATE poetry_claim SET certainty = 'LIKELY'
 WHERE id = 'claim-bg-city' AND certainty = 'DISPUTED' AND status <> 'PUBLISHED';
UPDATE poetry_claim SET certainty = 'LIKELY'
 WHERE id = 'claim-bg-world' AND certainty = 'DISPUTED' AND status <> 'PUBLISHED';
UPDATE poetry_claim SET certainty = 'LIKELY'
 WHERE id = 'claim-bg-person' AND certainty = 'DISPUTED' AND status <> 'PUBLISHED';

-- ---------- 7. 说明 ----------
-- source-anshi-candidate / source-dufu-nianpu-candidate 两行保留（PENDING）：
--   它们在别的 claim 上仍可能被引用（如 claim-anshi-time），本迁移只挪走背景层对它们的占位引用；
--   来源行何时退役是核验后的事，不由本迁移裁决。
-- background_line 未动：4 层×2 行绑定（text-chun-wang-draft 1,2/1,2/5,6/7,8）仍然有效。
-- V018 为 work-chun-wang 新立的 text-work-chun-wang-ws（8 行同文）如要接背景，等场景链
--   切到该版本时再补绑定，避免 facts 导出的 background_line_counts 与校验器对不上。

-- ---------- 8. 版本账本 ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 19, 'chun-wang background layers de-drafted: sourced body text, 3 placeholder citations replaced by verbatim tongjian/commentary text, 2 inserts, 2 extends; dating stays unresolved'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 19);
COMMIT;
