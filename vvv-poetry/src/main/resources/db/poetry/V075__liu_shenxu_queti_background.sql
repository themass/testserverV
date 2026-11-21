-- V075：劉眘虛《闕題》(work-t300-363) 四层背景（阶段 D 第 56 首·读书两界）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V014、V015、V016、V018、V026、V033、V035、V039、V048、V053、V057、
--       V058、V059、V060、V061、V062、V063、V064、V065、V066、V067、V068、V069、V070、
--       V071、V072、V073、V074 已执行
--       （work-t300-363 与其 text-work-t300-363-ws（version_code=ws-raw——V018 立此诗正文
--       用的就是《唐詩三百首》选本页，八行带句读全无尾随空格，与本快照 ws 诗页 poem 块
--       逐字同面零分歧，唯页尾「清輝照衣裳。 」一个随行空格存储面已裁——唯一裁切点照登）
--       与其源 source-ws-t300-363（V018 已立的选本页源，本迁移第二次复用零新建——
--       **V066 判例反向首枚：那首《涼思》V018 用卷页立文、诗页无源须新建一枚；这首 V018
--       就用诗页立文、诗页见证早有源行、无源可建。audit 断言本文件恰零枚 poetry_source
--       新建、回滚零 source 删除**）；
--       source-quantangshi-128（V026 已立的卷128 王维卷页源，第五次复用）、
--       source-quantangshi-160（V031 已立的卷160 高適卷页源，第六次复用）、
--       source-zizhi-tongjian-events（V014/V015 已立的通鉴事件源）都是既有行；
--       卷256 无源行亦无快照（抓取失败在册），卷140 无源行（只计数登记不逐字入引）；
--       判例在册句（道由白雲盡句读式全引/清輝照衣裳/header author=劉眘虛 V018、
--       header author=李益 V018（t300-335 江南曲选本页——019 卷署名異注只对照不裁决）、
--       開青溪道 V057、車如流水馬如龍 V058）只对照不重开。
--
-- 数据源（可复现）：emit_v075.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/闕題__劉眘虛_.txt（无Vtext 页=双转录缺位反面标本（全库恰 273 页闭域）+{{唐詩三百首}}
--   body 独立行挂法（59 页闭域）+notes 单行 TQ75+↑底本回指（130 页闭域）+末行页尾随行空格
--   （54 页闭域）+分类恰两行（149 页/「唐詩+五言律詩」对 48 页闭域）+无 VH1/无另/无别/无 */
--   无 ref/无 reflist/无 clr/无 times/type/from/无三百首类目行）、
--   V018 存储面重建比对（text-work-t300-363-ws 八行 vs ws poem 块——同面零分歧+唯一裁切点
--   双向断言）、全唐詩快照卷128（王维闕題二首锚+两空壳转引——闕題题面跨诗人形态；「闕題」
--   字面恰三卷分布 128/234/529 机器断言）+卷160（高適九日龍沙作寄劉大眘虛锚+空壳转引逐字
--   入引）+卷140/卷019（送劉眘虛锚计数恰二/江南曲署名對恰一——只计数不入引）+
--   fetch.log（「卷256: FAILED」恰二条在册——在册外零的生成时凭证，非引用源）+
--   通鑑卷254/201（白雲/宏詞两段逐字入引+年标题窗口：中和二年八八二/總章二年六六九）+
--   通鑑 75 卷负证计数扫描（白雲恰一+宏詞恰一+青溪恰一+流水恰一（后二系 V057/V058 在册句
--   只对照）+落花/幽映/深柳/讀書堂/閑門/向山路/衣裳/青溪長/白雲盡/流水香/歸取宏詞全零）+
--   七史快照（jts 27+xts 8+qss 3+通鉴 75）「眘/劉眘虛/劉慎虛/慎虛」全零机器断言+
--   ws 全库 295 页闭域档扫（无Vtext 273/尾空格 54/body挂三百首 59/notes含↑ 130/恰两类目
--   149/类目对 48/卷256 回指唯一/大写75 评级 142/唯一小写 75 页=夜雨寄北）+
--   既有迁移引文域逐句查重——在册零重开、二引/零重开/首引零域前提全部生成时断言。
--
-- 做：4 BACKGROUND content/claim/background + 6 组逐字引用（(claim,source) 主键每对恰一行）+
--   8 background_line（八句五律 **2/2/2/2 顺次**：scene→1,2 city→3,4 world→5,6 person→7,8，
--   绑 text-work-t300-363-ws 的 8 行）+ 零新建 source + 不碰 poetry_text_line。
-- 不做：**不新建任何 source**（V066 判例反向首枚——audit 断言零枚）；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「在册外零：底本缺席即说底本缺席」）：
--   * 八句在 120 卷全唐诗快照全零是**快照零非书零**——底本卷256 抓取失败（fetch.log 恰二条
--     机器登记），本迁移不逐字引 256、不断言它与选本页一致与否（无快照即无可核切片）；
--   * 「读书两界」「白云是谶宏词是科」系通鉴两段逐字入引支撑的对照判决，非史实因果——
--     通鉴不记这首诗；亦不考本诗系年（编年诸说一律不采信不铸造）；
--   * 「送刘眘虚归取宏词解」的诗题把通鉴铨法条与诗的读书堂并到同一个人身上——读法声明，
--     140 无源行只计数登记不逐字（audit 硬断言「送劉眘虛」不入任何引文）；
--   * 「零传记之人」严格限于本地七史快照——不排除纸面史部另有传（无快照即不能说）；
--   * 019 卷江南曲署名劉眘虛 vs t300-335 选本页署名李益：**两处见证并列只登记不裁决**
--     （异文只登记不裁决总判例），专办留 V079 江南曲；
--   * 闕題 题面跨诗人形态只登形（128 王维/234 杜甫/529 长题异文），不推作者归属；
--   * 分类恰两行与类目行系整理者动作：非史料声明、不升格，V048 判例；
--   * 「无Vtext 273 页」「尾空格 54 页」「七五评级 142 页」均照登不判；
--   * KNOWN 零如实记录（第卅一例，audit 反向断言 SQL 无 KNOWN 字面量）；
--   * V011/V016/V018/V026/V033/V035/V039/V053/V057/V058/V063/V066–V074 已引诸句只对照不重开。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 74，不含 75
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-363-%';             -- 空
--   SELECT id FROM poetry_source WHERE id IN ('source-ws-t300-363',
--     'source-quantangshi-128','source-quantangshi-160');               -- 恰三行（皆既有，本迁移零新建）
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-363-ws';  -- 恰 8
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-363-%';       -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-363';                                  -- 8（2/2/2/2）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-363-%';  -- 四行全 LIKELY
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-363'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-363';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-363-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V075_rollback.sql（按 id 全枚举删除；**零 source 删除**——本迁移零新建
--   source，source-ws-t300-363/source-quantangshi-128/source-quantangshi-160 皆既有行绝不删；
--   work-t300-363 本体与其 text_line 8 行都是 V018 的行，绝不删）
START TRANSACTION;

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-363-scene' AS id, 'BACKGROUND' AS entity_type, '363-scene' AS slug, '眼前：白云尽处的空堂' AS title, '四层处境背景（阶段 D 第 56 首·八句五律 2/2/2/2）；史实句均有逐字引证；系年第五十次判决（题证系列第卅八状·白云与读书各有其账，无一册是读书）「诗的白云与读书，通鉴各有一本账，没有一本在读书」——同字两界第二十形态·读书形态首见：白雲恰一（中和二年青石奇字「玉皇授白雲先生高駢」）/宏詞恰一（總章二年铨法「試文三篇謂之宏詞」）闭域入引；青溪（V057 贡道）/流水（V058 车马喻）在册零重开；落花/幽映/深柳/讀書堂/閑門/向山路/衣裳通鉴全零；在册外零首枚（八句 120 卷快照全零系底本卷256抓取失败在册非书零——不逐字引 256）；同面零分歧+唯一裁切点（V018 ws-raw存储八行≡poem 块，页尾随行空格存储面已裁——照登）；无 Vtext 页 273 页闭域反面标本（双转录缺位——V072–V074 三连之镜像）；闕題题面跨诗人第三枚（快照恰三卷：128 王维二首/234 杜甫/529 长题异文）；眘字七史全零·零传记之人系列首枚（只在朋友诗题与署名行——160 高適逐字入引/140 无源只计数/019 署名异注并列不裁决留 V079）；**零新建 source**（V018 已立 source-ws-t300-363——V066 判例反向首枚）+128/160 在册复用；正文第二引第二十三例零重开；KNOWN 零如实记录第卅一例（audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-363-city' AS id, 'BACKGROUND' AS entity_type, '363-city' AS slug, '这座城：题面不属于这首诗' AS title, '四层处境背景（阶段 D 第 56 首·八句五律 2/2/2/2）；史实句均有逐字引证；系年第五十次判决（题证系列第卅八状·白云与读书各有其账，无一册是读书）「诗的白云与读书，通鉴各有一本账，没有一本在读书」——同字两界第二十形态·读书形态首见：白雲恰一（中和二年青石奇字「玉皇授白雲先生高駢」）/宏詞恰一（總章二年铨法「試文三篇謂之宏詞」）闭域入引；青溪（V057 贡道）/流水（V058 车马喻）在册零重开；落花/幽映/深柳/讀書堂/閑門/向山路/衣裳通鉴全零；在册外零首枚（八句 120 卷快照全零系底本卷256抓取失败在册非书零——不逐字引 256）；同面零分歧+唯一裁切点（V018 ws-raw存储八行≡poem 块，页尾随行空格存储面已裁——照登）；无 Vtext 页 273 页闭域反面标本（双转录缺位——V072–V074 三连之镜像）；闕題题面跨诗人第三枚（快照恰三卷：128 王维二首/234 杜甫/529 长题异文）；眘字七史全零·零传记之人系列首枚（只在朋友诗题与署名行——160 高適逐字入引/140 无源只计数/019 署名异注并列不裁决留 V079）；**零新建 source**（V018 已立 source-ws-t300-363——V066 判例反向首枚）+128/160 在册复用；正文第二引第二十三例零重开；KNOWN 零如实记录第卅一例（audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-363-world' AS id, 'BACKGROUND' AS entity_type, '363-world' AS slug, '这个天下：白云是谶，宏词是科' AS title, '四层处境背景（阶段 D 第 56 首·八句五律 2/2/2/2）；史实句均有逐字引证；系年第五十次判决（题证系列第卅八状·白云与读书各有其账，无一册是读书）「诗的白云与读书，通鉴各有一本账，没有一本在读书」——同字两界第二十形态·读书形态首见：白雲恰一（中和二年青石奇字「玉皇授白雲先生高駢」）/宏詞恰一（總章二年铨法「試文三篇謂之宏詞」）闭域入引；青溪（V057 贡道）/流水（V058 车马喻）在册零重开；落花/幽映/深柳/讀書堂/閑門/向山路/衣裳通鉴全零；在册外零首枚（八句 120 卷快照全零系底本卷256抓取失败在册非书零——不逐字引 256）；同面零分歧+唯一裁切点（V018 ws-raw存储八行≡poem 块，页尾随行空格存储面已裁——照登）；无 Vtext 页 273 页闭域反面标本（双转录缺位——V072–V074 三连之镜像）；闕題题面跨诗人第三枚（快照恰三卷：128 王维二首/234 杜甫/529 长题异文）；眘字七史全零·零传记之人系列首枚（只在朋友诗题与署名行——160 高適逐字入引/140 无源只计数/019 署名异注并列不裁决留 V079）；**零新建 source**（V018 已立 source-ws-t300-363——V066 判例反向首枚）+128/160 在册复用；正文第二引第二十三例零重开；KNOWN 零如实记录第卅一例（audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-363-person' AS id, 'BACKGROUND' AS entity_type, '363-person' AS slug, '这个人：史部无传，诗题有名' AS title, '四层处境背景（阶段 D 第 56 首·八句五律 2/2/2/2）；史实句均有逐字引证；系年第五十次判决（题证系列第卅八状·白云与读书各有其账，无一册是读书）「诗的白云与读书，通鉴各有一本账，没有一本在读书」——同字两界第二十形态·读书形态首见：白雲恰一（中和二年青石奇字「玉皇授白雲先生高駢」）/宏詞恰一（總章二年铨法「試文三篇謂之宏詞」）闭域入引；青溪（V057 贡道）/流水（V058 车马喻）在册零重开；落花/幽映/深柳/讀書堂/閑門/向山路/衣裳通鉴全零；在册外零首枚（八句 120 卷快照全零系底本卷256抓取失败在册非书零——不逐字引 256）；同面零分歧+唯一裁切点（V018 ws-raw存储八行≡poem 块，页尾随行空格存储面已裁——照登）；无 Vtext 页 273 页闭域反面标本（双转录缺位——V072–V074 三连之镜像）；闕題题面跨诗人第三枚（快照恰三卷：128 王维二首/234 杜甫/529 长题异文）；眘字七史全零·零传记之人系列首枚（只在朋友诗题与署名行——160 高適逐字入引/140 无源只计数/019 署名异注并列不裁决留 V079）；**零新建 source**（V018 已立 source-ws-t300-363——V066 判例反向首枚）+128/160 在册复用；正文第二引第二十三例零重开；KNOWN 零如实记录第卅一例（audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-363-scene' AS id, 'bg-363-scene' AS subject_id, 'context' AS property_key, '闕題八句取 ws 选本页 poem 块存原样面入引（V018 句读式「道由白雲盡，……清輝照衣裳。」一引在先，零重开硬断言——正文第二引第二十三例）；同面零分歧+唯一裁切点（V018 ws-raw存储八行≡本快照 poem 块，唯页尾末行带一随行空格而存储面八行全无——照登，全库54页闭域）；双转录缺位反面标本（无Vtext全库273页闭域——V072–V074三连之镜像）；七五页本系列首见（大写142页闭域，唯一小写75页夜雨寄北照登不判）' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-363-city' AS id, 'bg-363-city' AS subject_id, 'context' AS property_key, '闕題题面跨诗人形态在册第三枚（快照120卷「闕題」字面恰三卷——128王维二首锚+两空壳转引逐字入引/234杜甫一首计数/529长题异文消歧计数，机器断言）；底本回指↑卷256全库唯一且256不在快照（fetch.log「卷256: FAILED」恰二入引）——**在册外零首枚**（八句快照全零系底本缺席非书零，不逐字引256）；分类恰两行最简类目面（149页/类目对48页闭域，V048 不升格）；**本迁移零新建 source**（source-ws-t300-363 系 V018 所立、128 源在册复用）' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-363-world' AS id, 'bg-363-world' AS subject_id, 'context' AS property_key, '通鉴白雲恰一（中和二年吕用之刻青石奇字「玉皇授白雲先生高駢」道君称号）/宏詞恰一（總章二年铨法「試文三篇謂之宏詞」科目）闭域入引；青溪（V057 贡道）/流水（V058 车马喻）在册零重开（audit 硬断言）；落花/幽映/深柳/讀書堂/閑門/向山路/衣裳全零；白云与读书各有其账、无一册是他读书（同字两界第二十形态·读书形态首见，对照判决非史实因果）' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-363-person' AS id, 'bg-363-person' AS subject_id, 'context' AS property_key, '眘字七史快照全零（jts 27+xts 8+qss 3+通鉴 75——零传记之人，系列首枚，机器断言）；全唐诗快照眘恰三卷五处全在诗题/署名行；卷160 高適「九日龍沙作寄劉大眘虛」锚+转引逐字入引（160 源复用零新建）；卷019 江南曲署名劉眘虛与选本页署名李益（V018 在册）两见证并列只登记不裁决（V079 专办）；卷140 无源行只计数不逐字（audit 硬断言）；KNOWN 零如实记录第卅一例' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-363-scene' AS subject_id, 'context' AS property_key, 'claim-bg-363-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-363-city' AS subject_id, 'context' AS property_key, 'claim-bg-363-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-363-world' AS subject_id, 'context' AS property_key, 'claim-bg-363-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-363-person' AS subject_id, 'context' AS property_key, 'claim-bg-363-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-363-scene' AS id, 'work-t300-363' AS work_id, 'SCENE' AS layer, '**诗的第一笔是一条走到头的白云路**：「道由白雲盡，春與青溪長」——路被白云拦断，春天却顺着青溪拉长：诗从「走到看不见的地方」开始。**ws 页是无 Vtext 页**——全库273 页闭域（机器断言）的**双转录缺位反面标本**：V072–V074 双转录句读分工三连的镜像，只此一面，poem 块就是唯一转录面。**同面零分歧+唯一裁切点**：V018 以 ws-raw存储的八行与本快照 poem 块逐字同面（生成时八行双向断言），唯页尾「清輝照衣裳。 」带一个随行的空格、V018 存储面八行全无尾随空格（照登——全库尾空格页 54 闭域）：面同一字不差，差只在校存两端对那一个空格的手不同。**七五页本系列首见**（{{Textquality|75%}}——大写 142 页闭域，全库唯一小写 75 评级页是夜雨寄北，照登不判）；{{唐詩三百首}} 走 body 独立行挂法（59 页闭域——本页无三百首类目行）。正文第二引上限用满第二十三例（V018 句读式「道由白雲盡，……清輝照衣裳。」一引在先，零重开硬断言），此后此诗正文关闭。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-363-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-363-city' AS id, 'work-t300-363' AS work_id, 'CITY' AS layer, '**这首诗的题面不属于这首诗**：「闕題」——王维名下有两首、杜甫名下有一首（机器断言：快照 120 卷里「闕題」字面分布恰三卷——128 王维二首/234 杜甫一首/529 把「秋日赴闕題潼關驛樓」卷入长题异文）——卷128「==[[闕題 (王維)|闕題二首]]==」锚带两枚空壳转引照登（V072/V073 空壳卷页侧同款）：闕題作为跨诗人共享的「无名」题面形态在册第三枚（V044 无题谱外新枝）。**底本回指恰一处、底本不在**：「↑ [[全唐詩/卷256#闕題|全唐詩·卷256]]」系全库 130 页含↑回指闭域中唯一指向卷256 的一页，而快照里没有卷256——抓取日志「卷256: FAILED」恰二条（机器登记入引）：**在册外零首枚**——八句在 120 卷全唐诗快照语料全零，此零非书零而是快照零（底本缺席即说底本缺席，不逐字引 256）；页尾分类恰两行（[[Category:唐詩]][[Category:五言律詩]]——恰两类目 149 页/本类目对 48 页闭域）：最简类目面，整理者动作非史料声明、不升格，V048 判例；{{唐詩三百首}} body 独立行挂法与无类目行照登。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-363-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-363-world' AS id, 'work-t300-363' AS work_id, 'WORLD' AS layer, '**诗的白云与读书，通鉴各有一本账，没有一本在读书**（同字两界第二十形态·读书形态首见）：「道由白雲盡」——通鉴「白雲」恰一：中和二年（壬寅，八八二）吕用之「**刻青石為奇字云：『玉皇授白雲先生高駢。』**密令左右置道院香案」——史的白雲是石头开口代天授名的道君称号，诗的白雲是路的尽头。「深柳讀書堂」之「宏詞」侧——通鉴「宏詞」恰一：總章二年（己巳，六六九）铨法「**人有格限未至，而能試文三篇，謂之宏詞**，試判三條，謂之拔萃」——史的宏词是资格未至先送三篇文来试的科目，诗的读书堂是柳荫深处自己读的书（「送刘眘虚归取宏词解」的诗题把这两条线并到同一个人身上——读法声明）。「春與青溪長」之青溪（V057 大中十三年韦皋开青溪道贡使路）、「遠隨流水香」之流水（V058 貞觀十年長孫后「車如流水馬如龍」车马喻）**在册零重开**（audit 硬断言逐字不再入本迁移引文）；落花/幽映/深柳/讀書堂/閑門/向山路/衣裳 通鉴全零（闭域档扫，机器断言）——诗的白云与读书落不进史部任何一本账（对照判决，非史实因果）。' AS body_text, 'SENIOR' AS audience, 'claim-bg-363-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-363-person' AS id, 'work-t300-363' AS work_id, 'PERSON' AS layer, '**史部没有这个人的传**：「眘」（刘眘虚/刘慎虚/慎虛）在 jts 27 卷+xts 8 卷+qss 3 卷+通鉴 75 卷史部快照**全零**（机器断言）——零传记之人，系列首枚：史部不录此人，连异写都不录。他在本库语料里活在别人的诗题与署名行里：全唐诗快照恰三卷五处「眘」——卷140 王昌齡卷「送劉眘虛歸取宏詞解」锚+转引恰二（**140 无源行，只计数登记逐字不入引**，audit 硬断言）；卷160 高適卷「==[[九日龍沙作寄劉大眘虛]]==」锚+空壳转引逐字入引（160 源在册复用零新建）；卷019「==相和歌辭·江南曲==」下署名行「劉眘虛」恰一——与 t300-335 选本页署名李益（V018「header author=李益」在册零重开）**两处见证并列只登记不裁决**，异注留 V079 专办。V018 作者判定「署名 劉眘虛：选本与维基文库页面两处转录一致」在册零重开。史无此人、诗题有其人：朋友的诗题替他留名，选本替他收诗——「无传的人活在朋友的题目里」系读法声明。KNOWN 零如实记录（第卅一例，audit 反向断言）。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-363-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文 ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-363-scene' AS claim_id, 'source-ws-t300-363' AS source_id, '页面 闕題（《唐詩三百首》第 363 首（全库最大序号）选本页，页题裸名；header author 署名行+poem 块四物理行八句存原样以「……」相连——**V018 以此页立正文（ws-raw），source-ws-t300-363 系 V018 所立第二次复用零新建**（V066 判例反向首枚）；**同面零分歧**：存储八行与本块逐字同面（双向断言）；**唯一裁切点照登**：页尾末行「清輝照衣裳。 」带一随行空格而存储面八行全无尾随空格（全库尾空格页 54 闭域）；无 Vtext/VH1——双转录缺位反面标本（全库 273 页闭域）；七五评级大写页本系列首见；正文第二引第二十三例零重开' AS locator, '| author   = 劉眘虛……道由白雲盡，春與青溪長。
時有落花至，遠隨流水香。……閑門向山路，深柳讀書堂。
幽映每白日，清輝照衣裳。 ' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-363-scene' AS claim_id, 'source-quantangshi-128' AS source_id, '卷一百二十八·王維「==[[闕題 (王維)|闕題二首]]==」锚行（闕題题面跨诗人形态之王维侧——锚形「二首」合并消歧器照登；同页两枚「{{:闕題 (…)}}」空壳转引在册（V072/V073 空壳卷页侧同款），锚行随 SCENE 入引、转引行随 CITY 入引——同一 (claim,source) 判例分载）' AS locator, '==[[闕題 (王維)|闕題二首]]==' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-363-city' AS claim_id, 'source-ws-t300-363' AS source_id, '页面 闕題（notes 整值入引：{{Textquality|75%}} 评级+↑底本回指同行——**全库 130 页含↑闭域中唯一指向卷256 的一页**，而卷256 不在快照：抓取日志「卷256: FAILED」恰二机器登记——**在册外零首枚**（八句 120 卷全唐诗快照全零系底本缺席非书零，不逐字引256）+{{唐詩三百首}} body 独立行挂法（59 页闭域，本页无三百首类目行）+页尾分类恰两行（[[Category:唐詩]]+[[Category:五言律詩]]——恰两类目 149 页/类目对 48 页闭域；整理者动作：非史料声明、不升格，V048 判例）' AS locator, '| notes    = {{Textquality|75%}}↑ [[全唐詩/卷256#闕題|全唐詩·卷256]]……
{{唐詩三百首}}
……[[Category:唐詩]]
[[Category:五言律詩]]……全唐詩/卷256: 全唐詩/卷256
全唐詩/卷256: 全唐詩/卷256
卷256: FAILED both name forms
全唐詩/卷263 -> vol263.txt 2589 chars' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-363-city' AS claim_id, 'source-quantangshi-128' AS source_id, '卷一百二十八·王維闕題块两枚空壳转引行（「{{:闕題 (荆谿白石出)}}」+「{{:闕題 (相看不忍發)}}」——锚下无正文、正文各在他页：空壳转引在册形态；「闕題」字面快照恰三卷分布（128/234/529）机器断言，234 杜甫一首与 529 长题异文消歧只计数登记不入引——闕題题面跨诗人形态在册第三枚）' AS locator, '{{:闕題 (荆谿白石出)}}

{{:闕題 (相看不忍發)}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-363-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '卷二百五十四·中和二年（壬寅，八八二）吕用之「刻青石為奇字云：『玉皇授白雲先生高駢。』…同歸上清耳」（**史的白雲是石头代天授名的道君称号**）……卷二百〇一·總章二年（己巳，六六九）铨法「人有格限未至，而能試文三篇，謂之宏詞，試判三條，謂之拔萃」（**史的宏词是格限未至先试三篇文的科目**）；通鉴白雲恰一/宏詞恰一（文件闭域+两处年标题窗口机器断言）；青溪/流水各恰一系 V057（大中十三年贡道）/V058（貞觀十年车马喻）在册句只对照不重开（audit 硬断言逐字不再入引）；落花/幽映/深柳/讀書堂/閑門/向山路/衣裳通鉴全零——两段逐字入引为读书两界判决证据' AS locator, '用之又刻青石為奇字云：「玉皇授白雲先生高駢。」密令左右置道院香案。駢得之，驚喜。用之曰：「玉皇以公焚修功著，將補真官，計鸞鶴不日當降此際。用之等謫限亦滿，必得陪幢節，同歸上清耳！」……人有格限未至，而能試文三篇，謂之宏詞，試判三條，謂之拔萃' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-363-person' AS claim_id, 'source-quantangshi-160' AS source_id, '卷一百六十·高適「==[[九日龍沙作寄劉大眘虛]]==」锚+「{{:九日龍沙作寄劉大眘虛}}」空壳转引整块逐字入引（**零传记之人存证**：史部七库快照「眘」全零——jts 27+xts 8+qss 3+通鉴 75 机器断言；全唐诗快照「眘」恰三卷五处全在诗题/署名行；160 源在册复用零新建；卷140 王昌齡送劉眘虛锚+转引恰二系无源行只计数登记逐字不入引（audit硬断言）；卷019 江南曲署名劉眘虛与选本页署名李益两见证并列只登记不裁决，V079 专办）' AS locator, '==[[九日龍沙作寄劉大眘虛]]==
{{:九日龍沙作寄劉大眘虛}}' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（八句五律 2/2/2/2 顺次） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-363-scene' AS background_id, 'text-work-t300-363-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-363-scene' AS background_id, 'text-work-t300-363-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-363-city' AS background_id, 'text-work-t300-363-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-363-city' AS background_id, 'text-work-t300-363-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-363-world' AS background_id, 'text-work-t300-363-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-363-world' AS background_id, 'text-work-t300-363-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-363-person' AS background_id, 'text-work-t300-363-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-363-person' AS background_id, 'text-work-t300-363-ws' AS version_id, 8 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 75, 'Liu Shen-xu''s Untitled (work-t300-363) background layers (stage-D poem 56, the highest sequence number in the anthology; eight-line regulated verse 2/2/2/2): dating verdict fifty, thirty-eighth shape of the title-evidence series -- the poem''s white cloud and its reading-hall; the histories keep a ledger for each, and not one of them is reading. Same-character-two-realms, twentieth shape: the reading (dushu) shape, first seen. Baiyun (white cloud) appears exactly once in the Tongjian (Zhonghe 2, renyin, 882: Lu Yongzhi "engraved a blue stone with strange characters, saying: The Jade Emperor confers on Gao Pian, Master of the White Cloud," secretly having it placed on the Daoist altar -- the history''s white cloud is a title of Daoist lordship handed out by talking stone, the poem''s white cloud is where the road runs out). Hongci appears exactly once (Zongzhang 2, jisi, 669, the statute on selection: "among those whose quota has not yet arrived, whoever can sit three essays is called hongci, and whoever sits three judgments is called bacui" -- the history''s hongci is a examination subject you present three essays to enter before your turn; the poem''s reading-hall is reading alone deep in the willows). Qingxi (V057, the tribute road) and liushui (V058, the image of horse-drawn carriages "carriages like flowing water, horses like dragons") are closed citations, re-cited zero times -- the audit hard-asserts neither literal re-enters any citation of this migration. Luohua (falling petals), youying (dim light), shenliu (deep willows), dushutang (reading hall), xianmen (idle gate), xiangshanlu (toward the mountain path), yishang (clothes) all score zero in the Tongjian (machine-asserted): the poem''s white cloud and its reading land in no ledger of the histories (declared contrast, not historical causation). OUT-OF-CATALOG ZERO, first seen: the eight lines score zero across the 120-volume Quan Tangshi snapshot, and the reason is on the record -- this page''s notes point their sole back-reference at juan 256, and juan 256 is one of the failed fetches: the fetch log carries exactly two "卷256: FAILED" lines (machine-registered into the CITY citation). This is a snapshot-zero, not a book-zero: with no snapshot there is no verifiable slice, so juan 256 is never quoted and never compared (the honest boundary of this poem). SAME-FACE ZERO-DIVERGENCE + THE SINGLE TRIM POINT: V018 stored this poem with version_code ws-raw -- from this very anthology page -- and its eight stored lines match this snapshot''s poem block character for character (generator asserts both directions), except that the page''s last line ends "清輝照衣裳。" followed by one trailing space while every stored line is space-free: the two faces agree down to the last graph, and the storage end trimmed that one space (registered as-is; closed set: exactly 54 pages corpus-wide end a poem line with a trailing space). The ws page is the NEGATIVE SPECIMEN of the double-transcription series: it has no Vtext block at all (closed set: exactly 273 pages corpus-wide -- the mirror of the V072-V074 three-in-a-row), no {{VH1}}, no variant marks; {{Textquality|75%}} in uppercase (142 pages; the single lowercase-75 page corpus-wide is Ye Yu Ji Bei -- registered, not judged); the anthology marker {{唐詩三百首}} hangs as its own body line (59 pages) with no anthology category line; the footer carries exactly two category lines ([[Category:唐詩]] + [[Category:五言律詩]] -- 149 pages with exactly two categories, 48 with this pair): the minimal category face, editorial, not upgraded (V048). THE TITLE IS NOT THIS POEM''S: "Untitled" is a cross-poet title-form -- the literal appears in exactly three snapshot volumes (128: two Wang Wei untitleds under one merged-disambiguation anchor with two empty transclusion shells, quoted; 234: one Du Fu, counted; 529: a long-title variant, counted) -- third registered member of the untitled-title family. PERSON: ZERO-BIOGRAPHY PERSON, first of the series -- the graph shen (in Liu Shenxu / Liu Shenvu / Shenvu) scores zero across all local history snapshots (27 JTS + 8 XTS + 3 QSS + 75 Tongjian volumes, machine-asserted); he survives in the corpus only inside other people''s poem-titles and signature lines: exactly three Quan-Tangshi volumes carry the graph -- 140 (Wang Changling''s send-off title for him going to sit the hongci, counted only: volume 140 has no source row, and the audit hard-asserts the send-off title never enters any citation), 160 (Gao Shi''s "On Ninth Festival Written at Longsha, Sent to Liu Da Shenxu" anchor plus empty shell, quoted verbatim; the 160 source at its sixth reuse), and 019 (a Jiangnan qu signed Liu Shenxu -- against the anthology page t300-363''s own cousin-page t300-335 signed Li Yi in V018''s closed citation: two witnesses registered side by side, nothing adjudicated; the case belongs to the future Jiangnan-qu migration). NEW SOURCES: exactly zero -- source-ws-t300-363 was V018''s own row (V018 registered the text from the anthology page, so the anthology-page witness already has its source row: the V066 precedent, inverted for the first time; the audit asserts zero source inserts in the migration and zero source deletes in the rollback), while sources 128 and 160 are reused. Body use-ceiling, twenty-third instance: V018''s punctuated excerpt stands first and is never re-opened (hard assertion); the body is now closed. KNOWN zero honestly recorded (thirty-first instance, audit reverse-asserts); closed precedent keywords (V018''s punctuated full quote, header author lines, V057''s qingxi road, V058''s carriage-water simile) stay out of citations'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 75);
COMMIT;
