-- V065：王維《洛陽女兒行》(work-t300-061) 四层背景（阶段 D 第 46 首·碧玉与良人）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V014、V015、V016、V018、V026、V035、V037、V039、V040、V055、V057、V064 已执行
--       （work-t300-061 与其 text-work-t300-061-ws、source-ws-t300-061 是 V018 的行；
--       source-quantangshi-125 是 V037/V055/V057/V064 已立的卷125 源行（本迁移第五次复用，零新源）；
--       source-xintangshu-wenyi 是 V016 已立的新唐书文艺传源；
--       source-zizhi-tongjian-events 是 V014/V015 已立的通鉴事件源；
--       判例在册句（九歲知屬辭 V040/名盛開元天寶 V016+V035/迎置洛陽迫以偽署 V026+V035/
--       別墅在輞川 V035+V039）只对照不重开）。
--       本迁移零新 source（audit 断言无诗源表新建插入语句）。
--
-- 数据源（可复现）：emit_v065.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/洛陽女兒行.txt（{{另}}×0×75%+底注全锚+尾巴系年注带异说双案+三百首标记恰一）、
--   新唐書卷202（满传逐句扫描唯一零域句首引+停筆而化传区间断言）、
--   舊唐書卷190下/新唐書卷202（两书全文闺阁十一词全零零证）、
--   全唐詩卷125（裸名锚+桩；洛陽女兒恰二自名/綠珠季倫九微全零扫描）、
--   通鑑卷192/194/206/251（碧玉恰二同案+狂夫恰二+良人恰六+綠珠恰一+四处年标题窗口+
--   tj-209/237/255 零标题断言）+ 通鑑 75 卷/全唐詩 118 卷存快照负证计数扫描
--   （洛陽女兒/女兒行/越女/浣紗/季倫/石崇/珊瑚/九微/七香車/趙李/繁華/西施/綠珠）+
--   既有迁移引文域逐句查重——传区间归属、二引/零重开/唯一零域句前提全部生成时断言。
--
-- 做：4 BACKGROUND content/claim/background + 5 组逐字引用（(claim,source) 主键每对恰一行；
--   scene 二十句长篇选段八句——判决词三词所在联+首尾联，余句 background_line 繫行；
--   32 行 background_line 改 20 行（**5/5/5/5 首次**：scene→1-5 city→6-10
--   world→11-15 person→16-20，绑 text-work-t300-061-ws 的 20 行）+ 零 poetry_source 行 + 不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span（底注「時年十六，一作十八。」亦不铸）、不写 event.name、
--   不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「詩有碧玉，史部碧玉是奪死之妾；詩有狂夫，史部狂夫是
-- 諫君之夫；詩有良人，史部良人是掠賣之身」）：
--   * 碧玉恰二整案+狂夫恰二双窗口+良人恰六闭域入引一句+綠珠恰一（40% 页三连不入窗）；
--   * 「诗以香收，人以笔收」「诗的洛陽繁华之乡/传的洛陽失节之地」「两传无少年诗」标明读法声明；
--   * 系年注带异说双案照登皆不采信（编者语非史源，audit 硬卡仍零铸造）；
--   * 裸名锚+裸名文件名照登（消歧链双向之二，同名登记 V062 判例）；
--   * 此诗正文第二引上限用满（V018 在先+双针查重各恰一处），对后来迁移关闭；
--   * 全唐詩越女/浣紗/珊瑚/繁華/西施/碧玉/七香車/趙李/石崇在册零入引（audit 硬卡零混入）；
--   * KNOWN 零如实记录（第廿一例，audit 反向断言 SQL 无 KNOWN 字面量）；
--   * 九歲屬辭（V040）/名盛開元天寶（V016/V035）/迎置洛陽（V026/V035）判例只对照不重开。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 64，不含 65
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-061-%';             -- 空
--   SELECT id FROM poetry_source WHERE id='source-quantangshi-125';     -- 恰 1（四迁移已立，本迁移复用不新建）
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-061-ws';  -- 恰 20
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-061-%';       -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-061';                                  -- 20（5/5/5/5）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-061-%';  -- 四行全 LIKELY（有意全 LIKELY）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-061'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-061';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-061-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
--   SELECT COUNT(*) FROM poetry_source WHERE id='source-quantangshi-125';  -- 恰 1（复用，非本迁移所立）
-- 回滚: recovery/V065_rollback.sql（按 id 全枚举删除；零 source 删除——卷125 源行为四迁移所立）
START TRANSACTION;

-- ---------- 1. 零新 source（卷125 源行四迁移已立，本迁移第五次复用） ----------
-- ---------- 2. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-061-scene' AS id, 'BACKGROUND' AS entity_type, '061-scene' AS slug, '眼前：洛阳女儿的闺阁自画像' AS title, '四层处境背景（阶段 D 第 46 首·二十句七古 5/5/5/5 首次）；史实句均有逐字引证；系年第四十次判决（题证系列第廿八状·碧玉与良人）「詩有碧玉，史部碧玉是奪死之妾；詩有狂夫，史部狂夫是諫君之夫；詩有良人，史部良人是掠賣之身」——同字两界第十形态·闺阁形态首见：通鉴碧玉恰二整案入引（神功元年丁酉六九七乔知之碧玉赴井死——史部碧玉=夺死之妾/诗碧玉=教舞主人）+狂夫恰二双窗口入引（武德九年丙戌六二六狂夫竊發+貞觀八年甲午六三四狂夫之言聖人擇焉——谏君之夫/娇贵夫婿）+良人恰六闭域入引（咸通十年己丑八六九不傷良人——掠卖之身/丈夫称呼；三处落零标题 50% 页 tj-209/237/255三连不入窗）；綠珠恰一=《綠珠怨》诗题以罪证进史部（诗题进史部通道是刑案，系列首见）；洛陽女兒/女兒行/越女/浣紗/季倫/石崇/珊瑚/九微/七香車/趙李/繁華/西施通鉴全零；全唐詩越女/浣紗/珊瑚/繁華/西施/碧玉/七香車/趙李/石崇在册零入引+季倫/九微/綠珠亦全零；消歧链双向之二（ws 文件名+卷125 锚点两端裸名第三见+自名恰二闭域）；底注系年注带异说双案「時年十六，一作十八。」第六形态（合体首见）照登皆不采信（audit 硬卡仍零铸造）；{{另}}×0×75% 正交零标记侧首录；三百首标记恰一+分类双行閨怨詩；零新源（卷125 第五次复用）；正文第二引上限用满第十三例对后来关闭；PERSON 满传逐句扫描唯一零域句首引（停筆而化。贈秘書監。——诗以香收人以笔收读法声明）；两书全文闺阁十一词全零（全文级零证首用）；KNOWN 零如实记录（第廿一例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-061-city' AS id, 'BACKGROUND' AS entity_type, '061-city' AS slug, '这座城：两端皆裸名的消歧链' AS title, '四层处境背景（阶段 D 第 46 首·二十句七古 5/5/5/5 首次）；史实句均有逐字引证；系年第四十次判决（题证系列第廿八状·碧玉与良人）「詩有碧玉，史部碧玉是奪死之妾；詩有狂夫，史部狂夫是諫君之夫；詩有良人，史部良人是掠賣之身」——同字两界第十形态·闺阁形态首见：通鉴碧玉恰二整案入引（神功元年丁酉六九七乔知之碧玉赴井死——史部碧玉=夺死之妾/诗碧玉=教舞主人）+狂夫恰二双窗口入引（武德九年丙戌六二六狂夫竊發+貞觀八年甲午六三四狂夫之言聖人擇焉——谏君之夫/娇贵夫婿）+良人恰六闭域入引（咸通十年己丑八六九不傷良人——掠卖之身/丈夫称呼；三处落零标题 50% 页 tj-209/237/255三连不入窗）；綠珠恰一=《綠珠怨》诗题以罪证进史部（诗题进史部通道是刑案，系列首见）；洛陽女兒/女兒行/越女/浣紗/季倫/石崇/珊瑚/九微/七香車/趙李/繁華/西施通鉴全零；全唐詩越女/浣紗/珊瑚/繁華/西施/碧玉/七香車/趙李/石崇在册零入引+季倫/九微/綠珠亦全零；消歧链双向之二（ws 文件名+卷125 锚点两端裸名第三见+自名恰二闭域）；底注系年注带异说双案「時年十六，一作十八。」第六形态（合体首见）照登皆不采信（audit 硬卡仍零铸造）；{{另}}×0×75% 正交零标记侧首录；三百首标记恰一+分类双行閨怨詩；零新源（卷125 第五次复用）；正文第二引上限用满第十三例对后来关闭；PERSON 满传逐句扫描唯一零域句首引（停筆而化。贈秘書監。——诗以香收人以笔收读法声明）；两书全文闺阁十一词全零（全文级零证首用）；KNOWN 零如实记录（第廿一例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-061-world' AS id, 'BACKGROUND' AS entity_type, '061-world' AS slug, '这个天下：闺阁词在史部是受害者身份' AS title, '四层处境背景（阶段 D 第 46 首·二十句七古 5/5/5/5 首次）；史实句均有逐字引证；系年第四十次判决（题证系列第廿八状·碧玉与良人）「詩有碧玉，史部碧玉是奪死之妾；詩有狂夫，史部狂夫是諫君之夫；詩有良人，史部良人是掠賣之身」——同字两界第十形态·闺阁形态首见：通鉴碧玉恰二整案入引（神功元年丁酉六九七乔知之碧玉赴井死——史部碧玉=夺死之妾/诗碧玉=教舞主人）+狂夫恰二双窗口入引（武德九年丙戌六二六狂夫竊發+貞觀八年甲午六三四狂夫之言聖人擇焉——谏君之夫/娇贵夫婿）+良人恰六闭域入引（咸通十年己丑八六九不傷良人——掠卖之身/丈夫称呼；三处落零标题 50% 页 tj-209/237/255三连不入窗）；綠珠恰一=《綠珠怨》诗题以罪证进史部（诗题进史部通道是刑案，系列首见）；洛陽女兒/女兒行/越女/浣紗/季倫/石崇/珊瑚/九微/七香車/趙李/繁華/西施通鉴全零；全唐詩越女/浣紗/珊瑚/繁華/西施/碧玉/七香車/趙李/石崇在册零入引+季倫/九微/綠珠亦全零；消歧链双向之二（ws 文件名+卷125 锚点两端裸名第三见+自名恰二闭域）；底注系年注带异说双案「時年十六，一作十八。」第六形态（合体首见）照登皆不采信（audit 硬卡仍零铸造）；{{另}}×0×75% 正交零标记侧首录；三百首标记恰一+分类双行閨怨詩；零新源（卷125 第五次复用）；正文第二引上限用满第十三例对后来关闭；PERSON 满传逐句扫描唯一零域句首引（停筆而化。贈秘書監。——诗以香收人以笔收读法声明）；两书全文闺阁十一词全零（全文级零证首用）；KNOWN 零如实记录（第廿一例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-061-person' AS id, 'BACKGROUND' AS entity_type, '061-person' AS slug, '这个人：满传唯一零域句' AS title, '四层处境背景（阶段 D 第 46 首·二十句七古 5/5/5/5 首次）；史实句均有逐字引证；系年第四十次判决（题证系列第廿八状·碧玉与良人）「詩有碧玉，史部碧玉是奪死之妾；詩有狂夫，史部狂夫是諫君之夫；詩有良人，史部良人是掠賣之身」——同字两界第十形态·闺阁形态首见：通鉴碧玉恰二整案入引（神功元年丁酉六九七乔知之碧玉赴井死——史部碧玉=夺死之妾/诗碧玉=教舞主人）+狂夫恰二双窗口入引（武德九年丙戌六二六狂夫竊發+貞觀八年甲午六三四狂夫之言聖人擇焉——谏君之夫/娇贵夫婿）+良人恰六闭域入引（咸通十年己丑八六九不傷良人——掠卖之身/丈夫称呼；三处落零标题 50% 页 tj-209/237/255三连不入窗）；綠珠恰一=《綠珠怨》诗题以罪证进史部（诗题进史部通道是刑案，系列首见）；洛陽女兒/女兒行/越女/浣紗/季倫/石崇/珊瑚/九微/七香車/趙李/繁華/西施通鉴全零；全唐詩越女/浣紗/珊瑚/繁華/西施/碧玉/七香車/趙李/石崇在册零入引+季倫/九微/綠珠亦全零；消歧链双向之二（ws 文件名+卷125 锚点两端裸名第三见+自名恰二闭域）；底注系年注带异说双案「時年十六，一作十八。」第六形态（合体首见）照登皆不采信（audit 硬卡仍零铸造）；{{另}}×0×75% 正交零标记侧首录；三百首标记恰一+分类双行閨怨詩；零新源（卷125 第五次复用）；正文第二引上限用满第十三例对后来关闭；PERSON 满传逐句扫描唯一零域句首引（停筆而化。贈秘書監。——诗以香收人以笔收读法声明）；两书全文闺阁十一词全零（全文级零证首用）；KNOWN 零如实记录（第廿一例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 3. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-061-scene' AS id, 'bg-061-scene' AS subject_id, 'context' AS property_key, '二十句全诗本文选段（{{另}}×0 而 Textquality 75%——零异文标记与不完备并存，正交横截面零标记侧首录；本页 {{別}}/{{*}}/<ref> 亦全零）；季倫（石崇字）径用——通鉴全唐詩俱不用此名（机器断言）；九微/繁华/赵李通鉴全零词入诗（照登）；全句第二引：正文 V018 text claim 一引在先（生成时全库查重双针「洛陽女兒對門居」「貧賤江頭自浣紗」各恰一处），两度上限至此用满、此诗正文对后来迁移关闭（audit 硬卡）；SCENE 引文系二十句长篇选段（八句判决词所在+首尾联），余句以 background_line 繫行。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-061-city' AS id, 'bg-061-city' AS subject_id, 'context' AS property_key, '消歧链双向之二（ws 文件名与卷125 锚点两端皆裸名——裸名形态第三见；无同名诗则无消歧器，消歧器有无本身即同名登记，V062 判例；audit 照登硬卡裸名锚字样）；全唐詩「洛陽女兒」恰 2=本篇自名（机器断言闭域）；底注尾巴系年注带异说双案「時年十六，一作十八。」首见（第六形态：岁数注 V064 与一作案 V061 首次合体一句）——照登皆不采信为系年（编者语非史源，audit 硬卡仍零铸造）；卷125「洛陽女兒行」恰 2=锚 1+桩 1机器断言；底注全锚（同 V058–V064）；{{唐詩三百首}} 标记恰一照登；分类双行唐詩+閨怨詩照登+非史料声明+不升格（V048/V063 判例）；source-quantangshi-125 V037/V055/V057/V064 已立、第五次复用零新源；行体乐府题而无时→零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-061-world' AS id, 'bg-061-world' AS subject_id, 'context' AS property_key, '通鉴「洛陽女兒/女兒行/越女/浣紗/季倫/石崇/珊瑚/九微/七香車/趙李/繁華/西施」全零（机器断言）；「碧玉」恰二闭域整案入引（神功元年丁酉六九七乔知之案：美妾碧玉/武承嗣留不还/碧玉赴井死——史部碧玉=夺死之妾）；「狂夫」恰二闭域双窗口入引（武德九年丙戌六二六萬一有狂夫竊發+貞觀八年甲午六三四狂夫之言聖人擇焉——史部狂夫=谏君之夫）；「良人」恰六闭域入引一句（咸通十年己丑八六九朝廷唯誅逆黨不傷良人——史部良人=掠卖之身/良家身份；三处落零年标题 50% 页 tj-209/237/255——50% 页永不入围窗口三连实例，生成时断言三页零标题）；「綠珠」恰一=《綠珠怨》诗题以裙帶得詩罪证入史部（诗题以刑案进史部首见）；同字两界第十形态·闺阁形态首见（audit 硬卡）；全唐詩越女/浣紗/珊瑚/繁華/西施/碧玉/七香車/趙李/石崇 在册零入引+季倫/九微/綠珠全唐詩亦全零（机器断言）；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 零铸造零 relation（audit 硬卡）。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-061-person' AS id, 'bg-061-person' AS subject_id, 'context' AS property_key, '满传逐句扫描后唯一零域尾句首引=新传「贈秘書監。」（「停筆而化」V039 已引零重开；生成时断言二十四候选句域全部非空、此句零域，破即中止重设计）；「诗以香收，人以笔收」「诗的洛陽是繁华之乡、传的洛陽是失节之地」「两传无一字记少年诗」均标明读法声明；九歲知屬辭（V040）、名盛於開元天寶（V016/V035）、迎置洛陽迫以偽署（V026/V035）、別墅在輞川（V035/V039）在册零重开；两书全文越女/浣紗/碧玉/珊瑚/狂夫/良人/繁華/季倫/石崇/綠珠/女兒全零（机器断言，全文级零证首用——强于历篇段内级）；certainty 不覆盖任何系年，底注双案岁数不铸 time.span。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-061-scene' AS subject_id, 'context' AS property_key, 'claim-bg-061-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-061-city' AS subject_id, 'context' AS property_key, 'claim-bg-061-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-061-world' AS subject_id, 'context' AS property_key, 'claim-bg-061-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-061-person' AS subject_id, 'context' AS property_key, 'claim-bg-061-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 4. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-061-scene' AS id, 'work-t300-061' AS work_id, 'SCENE' AS layer, '二十句写一个洛阳女儿的闺阁自画像：她对门而居、十五余岁（「洛陽女兒對門居，纔可容顏十五餘」）；丈夫玉勒驄馬、侍女金盤鱠魚（「良人玉勒乘驄馬，侍女金盤鱠鯉魚」）；画阁朱楼相望、红桃绿柳垂檐；罗帏送上七香车、宝扇迎归九华帐；狂夫富贵正青春，意气骄奢过石崇（「狂夫富貴在青春，意氣驕奢劇季倫」——季倫即石崇，通鉴全唐詩皆不用此名，诗径用之）；她自怜碧玉亲自教舞、不惜珊瑚持赠于人（「自憐碧玉親教舞，不惜珊瑚持與人」）；春窗曙色灭九微火（「春窗曙滅九微火」——九微灯通鉴全唐詩俱零）；戏罢不曾理曲，妆成只是薰香坐（「戲罷曾無理曲時，妝成秪是薰香坐」——全诗以闲静收束）；末以越女浣纱对照（「誰憐越女顏如玉，貧賤江頭自浣紗」）。本页 **{{另}}×0 而 Textquality 75%**——零异文标记与不完备并存（正交横截面零标记侧首录：不完备来自转录质量，非异文）；此诗正文系**第二引**：V018 一引在先，全库查重双针各恰一处，两度上限至此用满，此诗正文对后来迁移关闭。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-061-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-061-city' AS id, 'work-t300-061' AS work_id, 'CITY' AS layer, '**消歧链双向之二**：ws 文件名「洛陽女兒行.txt」与卷125 锚点「==[[洛陽女兒行]]==」**两端皆裸名**（裸名形态第三见，V062/V063 之后）——全唐詩「洛陽女兒」恰 2 处即本篇自名（机器断言）：**无同名诗则无消歧器，消歧器有无本身即同名登记**（V062 判例再验）；与 V064《桃源行》两端带作者消歧恰成消歧链的两个方向。底注尾巴「時年十六，一作十八。」：**系年注带异说双案首见（第六形态）**——V052 署名异说/V055 题异/V057 一名/V061 一题两案/V064 单岁数注之后，**岁数注与一作案首次合体一句**：十六与十八两个候选作年照登皆不采信（底注系编者语非史源，audit 硬卡诗 time.span 仍零铸造）。{{唐詩三百首}} 标记恰一（有标记页，与 V064 无标记页互为有无）；底注全锚（同 V058–V064）；分类双行「唐詩+閨怨詩」系整理者动作（第二首双分类，V063 判例：非史料声明、不升格）；source-quantangshi-125 系 V037/V055/V057/V064 已立、**第五次复用零新源**。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-061-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-061-world' AS id, 'work-t300-061' AS work_id, 'WORLD' AS layer, '**詩有碧玉，史部碧玉是奪死之妾；詩有狂夫，史部狂夫是諫君之夫；詩有良人，史部良人是掠賣之身**（同字两界第十形态·闺阁形态首见）：「碧玉」通鉴恰二（闭域，同卷同案两处，整案入引）——則天順聖皇后神功元年（丁酉，六九七）喬知之「有美妾曰碧玉……武承嗣藉以教諸姬，遂留不還……**碧玉赴井死**」：史部碧玉是被权贵夺走后投井的妾；诗「自憐碧玉親教舞」的碧玉是自己教舞的主人。「狂夫」恰二（闭域+双窗口入引）——武德九年（丙戌，六二六）切谏「**萬一有狂夫竊發，出於不意**」、貞觀八年（甲午，六三四）上书「**所謂狂夫之言，聖人擇焉**」：史部狂夫是直谏者的自谦与帝侧的隐患；诗「狂夫富貴在青春」的狂夫是娇贵的夫婿。「良人」恰六（闭域）——咸通十年（己丑，八六九）庞勋乱城喻「**朝廷唯誅逆黨，不傷良人**」入引，另有「掠良人賣爲奴婢」「立得爲良人」诸处：史部良人是良家身份（掠賣/贖身的户口范畴）；诗「良人玉勒乘驄馬」的良人是丈夫的称呼——**同一个词，史部记受害者身份，诗记闺阁的自主**。良人六处中三处（tj-209/237/255）落在**零年标题 50% 页**——50% 页永不入围窗口断言三连实例（audit 断言该三页零标题）。「**綠珠**」通鉴恰一处=喬知之「作《綠珠怨》詩以寄之」（裙帶得詩成罪证）——**诗题以刑案证据进史部（系列首见）**：《桃源行》的仙境整个不进史部，《綠珠怨》以罪证进——诗题进史部的通道是刑案；《洛陽女兒行》诗题通鉴全零、全唐詩恰 2 自名。诗语侧在册零入引（机器断言）：越女恰 7 五卷、浣紗恰 5 四卷、珊瑚恰 17十二卷、繁華恰 7 七卷、西施恰 12 六卷、碧玉恰 12 八卷（他卷他语境）、七香車恰 4 二卷、趙李恰 2 一卷、石崇恰一（vol539）；季倫/九微/綠珠全唐詩亦全零（诗语无同源）。本层零铸造零 relation。' AS body_text, 'SENIOR' AS audience, 'claim-bg-061-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-061-person' AS id, 'work-t300-061' AS work_id, 'PERSON' AS layer, '**满传逐句扫描后唯一零域尾句首引**：新传「疾甚……停筆而化。**贈秘書監。**」——「停筆而化」V039 已引在先（零重开，本层只取追赠官尾句），篇生成时对两传逐句查重，此句零域（audit 断言其余候选域全部非空、此句零域且「停筆而化」域恰 [V039]，破即中止重设计）。
**诗以香收，人以笔收**（读法声明，非史实）：本诗收句「妝成秪是薰香坐」（一生闲静止于坐），本传收段「停筆而化」（一生到写为止）——底注说诗成于十六（或十八）岁，传里「九歲知屬辭」（V040 在册零重开）：少年笔力早已在册，而**两传无一字记少年诗**——传记官历与陷贼（「迎置洛陽，迫以偽署」V026/V035 在册），不记闺阁。**两书全文越女/浣紗/碧玉/珊瑚/狂夫/良人/繁華/季倫/石崇/綠珠/女兒全零**（机器断言——比历篇「段内零」更强的全文级零证）：写遍闺阁的人，两《唐书》里没有一个闺阁字；两传仅存的「洛陽」只在陷贼伪署语境内（在册零重开）——**诗的洛陽是繁华之乡，传的洛陽是失节之地**（读法声明）。certainty 不覆盖任何系年，底注「時年十六，一作十八」不铸 time.span（audit 硬卡）。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-061-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 5. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-061-scene' AS claim_id, 'source-ws-t300-061' AS source_id, '页面 洛陽女兒行（二十句长篇**引文選段**——(claim,source) 主键唯一行内判决词三词所在联+首尾联共八句逐句全引、以「……」相連，余句以 background_line 繫行；全句**第二引**：正文 V018 text claim 一引在先，生成时全库查重双针恰一处，**两度上限至此用满，此诗正文对后来迁移关闭**；{{另}}/{{別}}/{{*}}/<ref> 全零而 75%；九微/繁华/赵李通鉴全零词照登）' AS locator, '洛陽女兒對門居，纔可容顏十五餘。……良人玉勒乘驄馬，侍女金盤鱠鯉魚。……狂夫富貴在青春，意氣驕奢劇季倫。……自憐碧玉親教舞，不惜珊瑚持與人。……春窗曙滅九微火，九微片片飛花璅。……戲罷曾無理曲時，妝成秪是薰香坐。……城中相識盡繁華，日夜經過趙李家。……誰憐越女顏如玉，貧賤江頭自浣紗。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-061-city' AS claim_id, 'source-ws-t300-061' AS source_id, '页面 洛陽女兒行（header title+页底注+分类双行四段并收——底注尾巴系年注带异说双案「時年十六，一作十八。」=第六形态照登（岁数注与一作案首次合体；编者语非史源，两个候选岁数皆不采信为系年，audit 硬卡仍零铸造）；底注全锚「卷125#洛陽女兒行」（同 V058–V064）；{{唐詩三百首}} 标记恰一照登；分类双行唐詩+閨怨詩系整理者动作：非史料声明、不升格）' AS locator, '| title    = 洛陽女兒行……| notes    = {{Textquality|75%}}↑ [[全唐詩/卷125#洛陽女兒行|全唐詩·卷125]] 時年十六，一作十八。……[[Category:唐詩]]……[[Category:閨怨詩]]' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-061-city' AS claim_id, 'source-quantangshi-125' AS source_id, '卷一百二十五·王維《洛陽女兒行》篇题锚点+转引桩（**裸名锚**——同名则无消歧器，全唐詩「洛陽女兒」恰 2=本篇自名（机器断言）；与 V064 桃源行两端作者消歧恰成消歧链两方向；卷125「洛陽女兒行」恰 2=锚 1+桩 1；源行系 V037/V055/V057/V064 已立、本迁移第五次复用零新源）' AS locator, '==[[洛陽女兒行]]==……{{:洛陽女兒行}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-061-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '卷二百零六·神功元年（丁酉，六九七）喬知之碧玉案整案……卷一百九十二·武德九年（丙戌，六二六）狂夫竊發段……卷一百九十四·貞觀八年（甲午，六三四）狂夫之言段……卷二百五十一·咸通十年（己丑，八六九）不傷良人段（**通鉴碧玉恰二同案+狂夫恰二+良人恰六+綠珠恰一（《綠珠怨》诗题罪证入史）**：文件闭域+四处年标题窗口机器断言；良人另三处 tj-209/237/255 落零年标题 50% 页只入闭域——50% 页永不入围窗口三连实例；四段史文逐字入引为判决证据；闺阁诗语十二词通鉴全零；全唐詩在册句零入引）' AS locator, '右司郎中馮翊喬知之有美妾曰碧玉，知之為之不昏。武承嗣藉以教諸姬，遂留不還。知之作《綠珠怨》詩以寄之，碧玉赴井死。……萬一有狂夫竊發，出於不意……所謂狂夫之言，聖人擇焉……朝廷唯誅逆黨，不傷良人' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-061-person' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書卷二〇二·王維临终段（追赠官尾句「贈秘書監。」——满传逐句扫描后唯一零域尾句首引（「停筆而化」V039 已引零重开）；段内传区间归属机器断言；「诗以香收，人以笔收」系读法声明非史实；九歲知屬辭/名盛開元天寶/迎置洛陽诸在册句零重开）' AS locator, '贈秘書監。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 6. background_line（二十句七古 5/5/5/5 首次） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-061-scene' AS background_id, 'text-work-t300-061-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-061-scene' AS background_id, 'text-work-t300-061-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-061-scene' AS background_id, 'text-work-t300-061-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-061-scene' AS background_id, 'text-work-t300-061-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-061-scene' AS background_id, 'text-work-t300-061-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-061-city' AS background_id, 'text-work-t300-061-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-061-city' AS background_id, 'text-work-t300-061-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-061-city' AS background_id, 'text-work-t300-061-ws' AS version_id, 8 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-061-city' AS background_id, 'text-work-t300-061-ws' AS version_id, 9 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-061-city' AS background_id, 'text-work-t300-061-ws' AS version_id, 10 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-061-world' AS background_id, 'text-work-t300-061-ws' AS version_id, 11 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-061-world' AS background_id, 'text-work-t300-061-ws' AS version_id, 12 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-061-world' AS background_id, 'text-work-t300-061-ws' AS version_id, 13 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-061-world' AS background_id, 'text-work-t300-061-ws' AS version_id, 14 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-061-world' AS background_id, 'text-work-t300-061-ws' AS version_id, 15 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-061-person' AS background_id, 'text-work-t300-061-ws' AS version_id, 16 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-061-person' AS background_id, 'text-work-t300-061-ws' AS version_id, 17 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-061-person' AS background_id, 'text-work-t300-061-ws' AS version_id, 18 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-061-person' AS background_id, 'text-work-t300-061-ws' AS version_id, 19 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-061-person' AS background_id, 'text-work-t300-061-ws' AS version_id, 20 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 7. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 65, 'Wang Wei''s Ballad of the Daughters of Luoyang (work-t300-061) background layers (stage-D poem 46, twenty-line geyue quintet 5/5/5/5 first time): dating verdict forty, twenty-eighth shape of the title-evidence series -- bishi and liangren, the boudoir words split in two realms: the poem''s bishi (green jade) is a wife who teaches her own dances; the Tongjian''s bishi (exactly 2, one case, quoted whole) is Qiao Zhizhi''s beautiful concubine taken by Wu Chengsi, who "went and threw herself into the well" (Shenggong 1st year, dingyou, 697); the poem''s kuangfu ("mad husband") is her pampered young spouse; the Tongjian''s kuangfu (exactly 2, windowed, quoted) is a censor''s self-deprecation -- "the words of a mad man" for the sage to weigh (Zhenguan 8th, jiawu, 634) and a feared stray shot near the emperor (Wude 9th, bingxu, 626); the poem''s liangren ("good man") is the polite word for husband; the Tongjian''s liangren (exactly 6, one quoted) is commoner status bought, sold and pardoned -- "the court punishes only the rebels, it will not harm the good" (Xiantong 10th, jichou, 869): one word, the histories record victims'' statuses, the poem records a wife''s agency (the tenth same-character split, first boudoir shape); liuren''s other three hits sit on heading-less 50%-pages tj-209/237/255 (triple instance of the 50%-page window ban, asserted at build); lüzhu appears exactly once -- Qiao''s poem-title "Lament of the Green Pearl", seized from her sash and used as execution evidence: a poem title enters the histories by way of a criminal case (first in the series); luoyang-nver/daughter-ballad/Yue-woman/launders silk/Jilun/Shi Chong/coral/jiawei/seven-fragrance carriage/Zhao-and-Li/splendour/Xishi score zero across the Tongjian; on the poetry side logged never quoted (machine-asserted); the disambiguation chain runs bare-name on both ends for the third time (ws filename + juan 125 bare anchor; luoyang-nver counts exactly 2 = self-naming); the base-note tail is a dating gloss with its own variant: "written at sixteen, alternatively at eighteen" (sixth form, first merger of the age-gloss and the one-said variant) -- both ages logged, neither promoted to chronology (audit hard-assert); zero 另 markers with 75% (orthogonality''s zero-marker side, first); the 三百首 marker present exactly once; paired category rows (唐詩+閨怨詩) per V048/V063; zero new sources (juan 125''s row reused for the fifth time); body quotes hit their two-use ceiling (V018 first, twin needles); PERSON first-cite is the single zero-domain tail sentence left after a sentence-by-sentence scan of both biographies -- "posthumously made Secretary Supervisor" ("he set down the brush and passed away" was cited by V039 and stays unquoted) (build-time asserts all 24 other candidates non-empty, this one empty): the poem ends in incense, the man ends in writing; both full histories contain none of eleven boudoir words (whole-book zero, stronger than the per-segment zero of earlier migrations); KNOWN zero honestly recorded (twenty-first instance, audit reverse-asserts); closed precedent keywords stay out of citations'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 65);
COMMIT;
