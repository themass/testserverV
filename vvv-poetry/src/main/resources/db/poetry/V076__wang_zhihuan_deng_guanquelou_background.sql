-- V076：王之渙《登鸛雀樓》(work-t300-361) 四层背景（阶段 D 第 57 首·看景两界）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V014、V015、V016、V018、V026、V033、V035、V039、V048、V049、V053、
--       V055、V057、V058、V059、V060、V061、V062、V063、V064、V065、V066、V067、V068、
--       V069、V070、V071、V072、V073、V074、V075 已执行
--       （work-t300-361 与其 text-work-t300-361-ws（version_code=ws-raw——V018 立此诗正文
--       用的就是《唐詩三百首》选本页，四行净文全无尾随空格——是本页 poem 块的**折叠面**：
--       题面/句4 {{另}} 取头部主读雀/層、行1内嵌《文苑英華》「一作徹」<ref> 整段裁去；
--       **存储面即定読面首枚**：页面存异读、库存储定读——异文定読分工面）
--       与其源 source-ws-t300-361（V018 已立的选本页源，本迁移第二次复用零新建）；
--       source-quantangshi-283（V033 已立的卷283 卷页源，第三次复用）、
--       source-zizhi-tongjian-events（V014/V015 已立的通鉴事件源）是既有行；
--       **本迁移恰新建一枚 source：source-quantangshi-253**——卷253 多诗人合卷卷页源，
--       承载王之渙小传+双题注+空壳（朱斌系全快照恰一唯一载体）：V018 用选本页立正文，
--       卷页见证面反而无源（V066 判例镜像首枚：那首选本页无源立选本页源，本篇卷页无源
--       立卷页源——V066 以来所立 source 全为选本页源，本篇首立卷页源；audit 断言本文件
--       恰一枚 poetry_source INSERT、回滚恰删此一枚）；
--       判例在册句（白日依山盡句读式全引/header author=王之渙 V018、
--       白馬驛投屍旧唐書句 V015——只对照不重开，audit 硬断言「白馬驛」三字不入引文）。
--
-- 数据源（可复现）：emit_v076.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/登鸛雀樓__王之渙_.txt（全库标记最密诗页：题面 {{另|雀|鵲}}（题面{{另}}5页闭域）+
--   行内 <ref> 孤注无 reflist+{{另|層|重}}+行尾随空格+notes 一作朱斌+满级评级尾置+from 三行
--   （from2+from3 15页闭域）+edition=yes（17页闭域）+类目三连全库唯一+孤儿</sub>全库唯本页+
--   {{Spoken Wikisource}} 有声页恰3页+无三百首标记48页闭域首枚）、
--   V018 存储面重建比对（text-work-t300-361-ws 四行 vs ws poem 块折叠面双向断言）、
--   全唐詩快照卷253（三级锚37/37通例+双题注+空壳+小传——壳在册+卷页层级首见+零传记之人
--   本库唯一传）+卷283（司马都同崔邠登鸛雀樓锚+壳逐字入引）+卷018/140（王之渙字面恰三卷
--   8/1/1 计数只档扫不入引）+
--   通鑑卷255/265（白日/黃河两段逐字入引+年标题窗口：中和二年八八二/天祐二年九〇五）+
--   通鑑 75 卷负证计数扫描（白日恰一+黃河恰一+千里目/層樓/鸛/鹳/王之渙/朱斌/國秀集/
--   文苑英華全零）+全唐詩快照负证（四句净文全零+朱斌恰一在253题注+登鸛雀樓恰两卷253/283+
--   千里目恰一在018只计数）+七史快照（jts 27+xts 8+qss 3+通鉴 75）王之渙/朱斌/崔國輔/
--   鄭昈/之賁全零机器断言（之咸在册系另一人不攀附）+
--   ws 全库 295 页闭域档扫（题面另5/notes一作13/无三百首48/有声3/三连1/孤儿sub1/from二三15/
--   edition17/满级26）+既有迁移引文域逐句查重——在册零重开、二引/零重开/首引零域前提全部生成时断言。
--
-- 做：4 BACKGROUND content/claim/background + 6 组逐字引用（(claim,source) 主键每对恰一行）+
--   4 background_line（四句五绝 **1/1/1/1 第八次**：scene→1 city→2 world→3 person→4，
--   绑 text-work-t300-361-ws 的 4 行）+ 恰新建 source 一枚（source-quantangshi-253）+
--   不碰 poetry_text_line。
-- 不做：**不新建除 253 外的任何 source**（audit 断言恰一枚、回滚恰删此一枚）；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「壳在册：底本在场但正文挂在他页」）：
--   * 四句在 118 卷全唐诗快照全零、在册形态是卷253 锚下空壳转引——**壳在册非正文在册**，
--     本迁移不逐字引壳的目标页（那在他书/他卷，快照里没有即无可核切片）；
--   * 「看景两界」「白日救乱黄河沉人」系通鉴两段逐字入引支撑的对照判决，非史实因果——
--     通鉴不记这首诗；亦不考本诗系年（编年诸说一律不采信不铸造）；
--   * 「名動一時」是总集编者语不是史部语——入引标明承载源；「正史无传」严格限于本地
--     七史快照——不排除纸面史部另有传（无快照即不能说）；
--   * 一作《登鸛鵲樓》/一作朱斌詩：**两处见证（卷253 题注+选本页 notes）并列只登记不裁决**
--     （异文只登记不裁决总判例）；雀/層取 {{另}} 头部主读系 V018 存储事实的登记非本迁移裁决；
--   * 卷283 同崔邠登鸛雀樓系同题另人只登形不推归属；千家詩类目行/有声文献类目系整理者
--     动作：非史料声明、不升格，V048 判例；
--   * 满级 100% 页 26、有声页 3、三连 1 页、孤儿</sub> 1 页均照登不判；
--   * KNOWN 零如实记录（第卅二例——V018 text claim 的 KNOWN 在册零重开不碰，audit
--     反向断言本迁移 SQL 无 KNOWN 字面量）；
--   * V011/V014/V015/V016/V018/V026/V033/V035/V039/V048/V049/V053/V055/V057/V058/V059–V075
--     已引诸句只对照不重开。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 75，不含 76
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-361-%';             -- 空
--   SELECT id FROM poetry_source WHERE id IN ('source-ws-t300-361',
--     'source-quantangshi-283','source-quantangshi-253');               -- 恰两行（253 本迁移新建前不存在）
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-361-ws';  -- 恰 4
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-361-%';       -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-361';                                  -- 4（1/1/1/1）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-361-%';  -- 四行全 LIKELY
--   SELECT COUNT(*) FROM poetry_source WHERE id='source-quantangshi-253';  -- 恰 1（本迁移所立）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-361'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-361';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-361-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V076_rollback.sql（按 id 全枚举删除；**source 只删一行**——
--   source-quantangshi-253 是本迁移新建的卷页源（恰一枚，审计断言）按 id 删除；
--   source-ws-t300-361 是 V018 所立的选本页源、source-quantangshi-283 是 V033 所立的
--   卷283 源（本迁移复用），绝不删；work-t300-361 本体与其 text_line 4 行都是 V018 的行，绝不删）
START TRANSACTION;

-- ---------- 0. 新建卷页源一枚（source-quantangshi-253——V066 判例镜像首枚） ----------
INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status, source_kind, reliability)
SELECT * FROM (
SELECT 'source-quantangshi-253' AS id, '御定全唐詩 (四庫全書本) 卷二百五十三（王之渙 閻防 薛據 姚係 令狐峘 滕珦合卷）' AS title, NULL AS author, '御定全唐詩 (四庫全書本)' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷253' AS url, '维基文库录入本，公有领域古籍。本行由 emit_v076.py 对 /tmp/src-dl 快照逐字定位。本诗 V018 立正文时用的是《唐詩三百首》选本页（source-ws-t300-361，version_code ws-raw），此《御定全唐詩》卷253 卷页当时未建源——选本页与卷页是两个独立见证面（选本页 header 署名/notes 一作朱斌 vs 卷页编者可入引载体——王之渙小传+粗斜体双题注「一作《登鸛鵲樓》。一作朱斌詩。」+空壳转引），本迁移引卷页非新源不能承载（V066 判例镜像首枚：V066 以来所立 source 全为选本页源，本篇首立卷页源）。页面 {{Textquality|75%}} 七五评级（照登）；三级诗锚 37/37 通例（卷页层级）。核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status, 'POETRY_COLLECTION' AS source_kind, 'HIGH' AS reliability FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_source x WHERE x.id = t.id);

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-361-scene' AS id, 'BACKGROUND' AS entity_type, '361-scene' AS slug, '眼前：白日与大河的净面' AS title, '四层处境背景（阶段 D 第 57 首·四句五绝 1/1/1/1 第八次）；史实句均有逐字引证；系年第五十一次判决（题证系列第卅九状·白日与黄河各有其账，无一册在看景）「诗的白日与黄河，通鉴各恰一处，没有一处在看景」——同字两界第二十一形态·看景形态首见：白日恰一（中和二年阡能案「如出九泉睹白日」）/黃河恰一（天祐二年李振「宜投之黃河，使為濁流」）闭域入引；千里目/層樓/鸛/鹳/王之渙/朱斌通鉴全零；V015 白馬驛在册句只对照零重开；壳在册（四句净文 118 卷全零、卷253 锚下挂空壳——与 V075 在册外零成谱）；卷页层级首见（三级锚本卷 37/37 通例+编者题注直书归属异议）；存储面即定読面首枚（V018 ws-raw 净文=页折叠面——异文定読分工面：页面存异读/库存储定读）；选本标记缺席首枚（48 页闭域）+有声页全库恰三页+类目三连全库唯一；同题另人卷283 司马都逐字入引（283 源第三次复用）；王之渙/朱斌七史全零·零传记之人第二枚（正史无传、本库唯一传系卷253 编者附记——「名動一時」是编者给的）；朱斌 118 卷恰一在题注+选本 notes 两处成对只登记不裁决（V079 同款规则）；**恰新建卷页源一枚 source-quantangshi-253**（V066 以来立源全为选本页源，本篇首立卷页源——audit 断言恰一枚）+283/ws-361 在册复用；正文第二引第二十四例零重开；KNOWN 零如实记录第卅二例（audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-361-city' AS id, 'BACKGROUND' AS entity_type, '361-city' AS slug, '这座城：全唐诗里的一只空壳' AS title, '四层处境背景（阶段 D 第 57 首·四句五绝 1/1/1/1 第八次）；史实句均有逐字引证；系年第五十一次判决（题证系列第卅九状·白日与黄河各有其账，无一册在看景）「诗的白日与黄河，通鉴各恰一处，没有一处在看景」——同字两界第二十一形态·看景形态首见：白日恰一（中和二年阡能案「如出九泉睹白日」）/黃河恰一（天祐二年李振「宜投之黃河，使為濁流」）闭域入引；千里目/層樓/鸛/鹳/王之渙/朱斌通鉴全零；V015 白馬驛在册句只对照零重开；壳在册（四句净文 118 卷全零、卷253 锚下挂空壳——与 V075 在册外零成谱）；卷页层级首见（三级锚本卷 37/37 通例+编者题注直书归属异议）；存储面即定読面首枚（V018 ws-raw 净文=页折叠面——异文定読分工面：页面存异读/库存储定读）；选本标记缺席首枚（48 页闭域）+有声页全库恰三页+类目三连全库唯一；同题另人卷283 司马都逐字入引（283 源第三次复用）；王之渙/朱斌七史全零·零传记之人第二枚（正史无传、本库唯一传系卷253 编者附记——「名動一時」是编者给的）；朱斌 118 卷恰一在题注+选本 notes 两处成对只登记不裁决（V079 同款规则）；**恰新建卷页源一枚 source-quantangshi-253**（V066 以来立源全为选本页源，本篇首立卷页源——audit 断言恰一枚）+283/ws-361 在册复用；正文第二引第二十四例零重开；KNOWN 零如实记录第卅二例（audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-361-world' AS id, 'BACKGROUND' AS entity_type, '361-world' AS slug, '这个天下：白日救乱，黄河沉人' AS title, '四层处境背景（阶段 D 第 57 首·四句五绝 1/1/1/1 第八次）；史实句均有逐字引证；系年第五十一次判决（题证系列第卅九状·白日与黄河各有其账，无一册在看景）「诗的白日与黄河，通鉴各恰一处，没有一处在看景」——同字两界第二十一形态·看景形态首见：白日恰一（中和二年阡能案「如出九泉睹白日」）/黃河恰一（天祐二年李振「宜投之黃河，使為濁流」）闭域入引；千里目/層樓/鸛/鹳/王之渙/朱斌通鉴全零；V015 白馬驛在册句只对照零重开；壳在册（四句净文 118 卷全零、卷253 锚下挂空壳——与 V075 在册外零成谱）；卷页层级首见（三级锚本卷 37/37 通例+编者题注直书归属异议）；存储面即定読面首枚（V018 ws-raw 净文=页折叠面——异文定読分工面：页面存异读/库存储定读）；选本标记缺席首枚（48 页闭域）+有声页全库恰三页+类目三连全库唯一；同题另人卷283 司马都逐字入引（283 源第三次复用）；王之渙/朱斌七史全零·零传记之人第二枚（正史无传、本库唯一传系卷253 编者附记——「名動一時」是编者给的）；朱斌 118 卷恰一在题注+选本 notes 两处成对只登记不裁决（V079 同款规则）；**恰新建卷页源一枚 source-quantangshi-253**（V066 以来立源全为选本页源，本篇首立卷页源——audit 断言恰一枚）+283/ws-361 在册复用；正文第二引第二十四例零重开；KNOWN 零如实记录第卅二例（audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-361-person' AS id, 'BACKGROUND' AS entity_type, '361-person' AS slug, '这个人：正史无传，编者有记' AS title, '四层处境背景（阶段 D 第 57 首·四句五绝 1/1/1/1 第八次）；史实句均有逐字引证；系年第五十一次判决（题证系列第卅九状·白日与黄河各有其账，无一册在看景）「诗的白日与黄河，通鉴各恰一处，没有一处在看景」——同字两界第二十一形态·看景形态首见：白日恰一（中和二年阡能案「如出九泉睹白日」）/黃河恰一（天祐二年李振「宜投之黃河，使為濁流」）闭域入引；千里目/層樓/鸛/鹳/王之渙/朱斌通鉴全零；V015 白馬驛在册句只对照零重开；壳在册（四句净文 118 卷全零、卷253 锚下挂空壳——与 V075 在册外零成谱）；卷页层级首见（三级锚本卷 37/37 通例+编者题注直书归属异议）；存储面即定読面首枚（V018 ws-raw 净文=页折叠面——异文定読分工面：页面存异读/库存储定读）；选本标记缺席首枚（48 页闭域）+有声页全库恰三页+类目三连全库唯一；同题另人卷283 司马都逐字入引（283 源第三次复用）；王之渙/朱斌七史全零·零传记之人第二枚（正史无传、本库唯一传系卷253 编者附记——「名動一時」是编者给的）；朱斌 118 卷恰一在题注+选本 notes 两处成对只登记不裁决（V079 同款规则）；**恰新建卷页源一枚 source-quantangshi-253**（V066 以来立源全为选本页源，本篇首立卷页源——audit 断言恰一枚）+283/ws-361 在册复用；正文第二引第二十四例零重开；KNOWN 零如实记录第卅二例（audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-361-scene' AS id, 'bg-361-scene' AS subject_id, 'context' AS property_key, '四句取 ws 选本页 poem 块存原样面入引（题面{{另|雀|鵲}}+行内<ref>「入」一作徹孤注（无reflist照登）+{{另|層|重}}+行尾随空格——全页四个异文/归属载体；V018 句读式「白日依山盡，……更上一層樓。」一引在先零重开硬断言——正文第二引第二十四例）；**存储面即定読面首枚**（V018 ws-raw 四行净文=页物理行折叠面：雀/層取头部主读、<ref>整段裁——异文定読分工面：页面存异读/库存储定读，生成时拼合断言）；满级页{{Textquality|100%}}（26页闭域）' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-361-city' AS id, 'bg-361-city' AS subject_id, 'context' AS property_key, '《全唐詩》卷253 三级诗锚「===[[登鸛雀樓 (王之渙)|登鸛雀樓]]===」+粗斜体双题注「一作《登鸛鵲樓》。一作朱斌詩。」+空壳转引整块逐字入引（**卷页层级首见**：本卷37/37 通例机器断言；**编者题注直书归属异议**；四句净文118卷快照全零——**壳在册**，与 V075 在册外零成谱）；卷283 司马都「同崔邠登鸛雀樓」锚+壳逐字入引（283 源第三次复用——题面跨诗人）；**选本标记缺席首枚**（无三百首标记48页闭域）+千家詩类目行（另一选本，本页身兼两选本）+孤儿</sub>全库唯本页照登；**恰新建卷页源一枚**（source-quantangshi-253——V066 以来立源全为选本页源，本篇首立卷页源）' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-361-world' AS id, 'bg-361-world' AS subject_id, 'context' AS property_key, '通鉴白日恰一（中和二年阡能案百姓见高仁厚「如出九泉睹白日，已死而復生矣」出九泉之喻）/黃河恰一（天祐二年李振疾搢紳「此輩常自謂清流，宜投之黃河，使為濁流」拟沉清流之浊水）闭域入引；千里目/層樓/鸛/鹳/王之渙/朱斌通鉴全零；V015 白馬驛旧唐書在册句只对照不重开（audit 硬断言白馬驛不入引文）——白日与黄河各有其账、无一册在看景（同字两界第二十一形态·看景形态首见，对照判决非史实因果）' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-361-person' AS id, 'bg-361-person' AS subject_id, 'context' AS property_key, '王之渙/朱斌/崔國輔/鄭昈/之賁七史快照全零（jts 27+xts 8+qss 3+通鉴 75——零传记之人系列第二枚，机器断言）；本库唯一传系卷253 编者附记「幷州人…聯唱迭和，名動一時。詩六首」逐字入引（新源承载）；朱斌118卷恰一恰在此题注+选本页notes两处独立成对，只登记不裁决（V079 同款规则）；V018 作者判定在册零重开；KNOWN 零如实记录第卅二例' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-361-scene' AS subject_id, 'context' AS property_key, 'claim-bg-361-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-361-city' AS subject_id, 'context' AS property_key, 'claim-bg-361-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-361-world' AS subject_id, 'context' AS property_key, 'claim-bg-361-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-361-person' AS subject_id, 'context' AS property_key, 'claim-bg-361-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-361-scene' AS id, 'work-t300-361' AS work_id, 'SCENE' AS layer, '**诗的第一笔是一轮沉下去的白日与一条停不下来的河**：「白日依山盡，黃河入海流」——二十个字写尽落日与大河，没有一个字在说登楼的人。**ws 页是全库标记最密的诗页**：题面内嵌 {{另|雀|鵲}}（全库题面{{另}}恰 5 页闭域）、第二句行内嵌《文苑英華》「一作徹」<ref> 孤注（全页无 {{reflist}}，孤注无处安放照登）、第四句 {{另|層|重}}——一页四个异文/归属载体。**存储面即定読面首枚**：V018 以 ws-raw 存的四行全是净文——雀/層取{{另}}头部主读、<ref> 片段整段裁去（生成时拼合断言：页物理行=存储行拼合+标记件）：同面零分歧在此不成立，成**异文定読分工面**——页面存异读、库存储定读（V072 跨迁移异体分工的页-库内版）。满级页 {{Textquality|100%}}（26 页闭域）。正文第二引上限用满第二十四例（V018 句读式「白日依山盡，……更上一層樓。」一引在先，零重开硬断言），此后此诗正文关闭。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-361-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-361-city' AS id, 'work-t300-361' AS work_id, 'CITY' AS layer, '**这首诗在《全唐詩》里以一只空壳在册**：卷253 锚行下「{{:登鸛雀樓 (王之渙)}}」转引无正文、四句净文在 118 卷快照全零（机器断言——与 V075 在册外零成谱：那首底本不在、这首底本在而挂壳）。**卷页层级首见**：卷253 是多诗人合卷（王之渙 閻防 薛據…），诗锚为三级「===[[…]]===」且本卷 37/37 通例（机器断言）——作者作二级、诗作三级；锚下粗斜体双注「一作《登鸛鵲樓》。一作朱斌詩。」——**编者题注直书归属异议**（V073「整理者作者注挂题锚」同族升级：异议进题注）；题面异写登鸛雀樓/登鸛鵲樓照登。同题另人：卷283 司马都「==[[同崔邠登鸛雀樓]]==」锚+空壳逐字入引（283 源在册第三次复用）——题面跨诗人形态在册。**选本标记缺席首枚**：选本页无 {{唐詩三百首}} 亦无三百首类目（48 页闭域机器断言）——选本对这首诗的归属不靠页面自我声明；notes「一作朱斌詩，參見《國秀集》」与 from 三行底本链（文苑英華/御定全唐詩/國秀集，15 页闭域）+类目三连（代表作品/千家詩/有声文献全库唯一——**千家詩系另一部选本的类目行，本页身兼两选本**）照登；孤儿 </sub> 闭合标签全库唯本页照登不判；页尾类目系整理者动作，非史料声明、不升格（V048 判例）。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-361-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-361-world' AS id, 'work-t300-361' AS work_id, 'WORLD' AS layer, '**诗的白日与黄河，通鉴各恰一处，没有一处在看景**（同字两界第二十一形态·看景形态首见）：「白日依山盡」——通鉴「白日」恰一：中和二年（壬寅，八八二）阡能之乱平，蜀中百姓见高仁厚「**如出九泉睹白日，已死而復生矣**」——史的白日是解围的军队出九泉之喻，诗的白日是依山沉下去的太阳。「黃河入海流」——通鉴「黃河」恰一：天祐二年（乙丑，九〇五）白馬驛案，李振疾搢紳「**此輩常自謂清流，宜投之黃河，使為濁流**」——史的黄河是拟沉清流的浊水，诗的黄河是入海的活水（V015 旧唐書「投屍於河」在册句只对照不重开，audit 硬断言「白馬驛」不入本迁移引文）；千里目/層樓/鸛/鹳/王之渙/朱斌通鉴全零（闭域档扫，机器断言）——诗的两件大景落不进史部任何一本账（对照判决，非史实因果）。' AS body_text, 'SENIOR' AS audience, 'claim-bg-361-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-361-person' AS id, 'work-t300-361' AS work_id, 'PERSON' AS layer, '**正史没有这个人的传，总集编者给他立了本库唯一传**：王之渙/朱斌/崔國輔/鄭昈在 jts 27 卷+xts 8 卷+qss 3 卷+通鉴 75 卷史部快照**全零**（机器断言）——零传记之人系列第二枚（V075 眘字首枚）；与眘不同，他有传，在《全唐詩》编者的两行附记里：「王之渙，幷州人，兄之咸、之賁皆有文名。天寶間，與王昌齡、崔國輔、鄭昈聯唱迭和，**名動一時**。詩六首。」（逐字入引，新源承载——「名動一時」四字是史部不给、编者给的；之咸两条在册系另一人，不攀附）。**归属异议的对方名字只活在编者注里**：「朱斌」在 118 卷全唐诗快照恰一、恰在卷253 这行题注（机器断言）——与选本页 notes「一作朱斌詩」两处独立成对，**只登记不裁决**（V079 江南曲同款规则）。V018 作者判定「署名 王之渙：选本与维基文库页面两处转录一致」在册零重开；V018 text claim 已持 KNOWN（在册零重开），本迁移自铸 claims 零 KNOWN（如实记录第卅二例，audit 反向断言）。无传的人活在总集编者的附记里——系读法声明。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-361-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文 ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-361-scene' AS claim_id, 'source-ws-t300-361' AS source_id, '页面 登鸛雀樓 (王之渙)（《唐詩三百首》第 361 首選本页；header title+author+poem 块两物理行存原样以「……」相连——题面内嵌 {{另|雀|鵲}}（全库题面{{另}}恰 5 页闭域）、行1内嵌《文苑英華》「一作徹」<ref> 孤注（全页无 reflist，孤注照登）+行尾随空格照登、行4 {{另|層|重}}——一页四个异文/归属载体；**存储面即定読面首枚**：V018 ws-raw 四行净文=本页折叠面（雀/層取头部主读、<ref>整段裁，生成时拼合双向断言）；正文第二引第二十四例零重开' AS locator, '| title    = 登鸛{{另|雀|鵲}}樓……| author   = 王之渙……白日依山盡，黃河入海流。<small><small><ref>「入」：《文苑英華》注「一作''''''徹''''''」</ref></small></small> ……欲窮千里目，更上一{{另|層|重}}樓。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-361-city' AS claim_id, 'source-ws-t300-361' AS source_id, '页面 登鸛雀樓 (王之渙)（from 三行底本链（文苑英華/御定全唐詩/國秀集——from2+from3全库 15 页闭域）+notes 整值（一作朱斌+參見國秀集+满级评级尾置）+edition= yes（17 页闭域）+页尾类目三连含空行（代表作品/千家詩/有声文献**全库唯一**——千家詩系另一选本类目行，本页身兼两选本）+孤儿</sub>（全库唯本页，照登不判）——**选本标记缺席首枚**（无三百首标记 48 页闭域机器断言）；类目系整理者动作：非史料声明、不升格（V048）' AS locator, '| from     = 文苑英華 (四庫全書本)/卷0312
| from2    = 御定全唐詩 (四庫全書本)/卷253
| from3    = 國秀集 (四庫全書本)/卷下……| notes    = 一作[[Author:朱斌|朱斌]]詩，參見《國秀集》<br/>{{Textquality|100%}}……| edition= yes……[[Category:代表作品]]

[[Category:千家詩]]

[[Category:有声文献]]……</sub></center>' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-361-city' AS claim_id, 'source-quantangshi-253' AS source_id, '卷二百五十三（多诗人合卷）「===[[登鸛雀樓 (王之渙)|登鸛雀樓]]===」三级锚+粗斜体双题注「一作《登鸛鵲樓》。一作朱斌詩。」+「{{:登鸛雀樓 (王之渙)}}」空壳整块逐字入引（**卷页层级首见**：三级锚系本卷 37/37 通例机器断言；**编者题注直书归属异议**；四句净文 118 卷快照全零——壳在册与 V075 在册外零成谱；**本迁移恰新建此卷页源一枚**）' AS locator, '===[[登鸛雀樓 (王之渙)|登鸛雀樓]]===
''''''{{*|一作《登鸛鵲樓》。一作朱斌詩。}}

{{:登鸛雀樓 (王之渙)}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-361-city' AS claim_id, 'source-quantangshi-283' AS source_id, '卷二百八十三·司马都「==[[同崔邠登鸛雀樓]]==」锚+空壳转引逐字入引（同题另人——题面跨诗人形态之 283 侧；283 源在册第三次复用零新建；「登鸛雀樓」字面快照恰两卷 253/283机器断言）' AS locator, '==[[同崔邠登鸛雀樓]]==
{{:同崔邠登鸛雀樓}} ' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-361-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '卷二百五十五·中和二年（壬寅，八八二）阡能之乱平，蜀中百姓见高仁厚「如出九泉睹白日，已死而復生矣」（**史的白日是解围军队出九泉之喻**）……卷二百六十五·天祐二年（乙丑，九〇五）李振疾搢紳「此輩常自謂清流，宜投之黃河，使為濁流！」（**史的黄河是拟沉清流的浊水**）；通鉴白日恰一/黃河恰一（文件闭域+两处年标题窗口机器断言）；千里目/層樓/鸛/鹳/王之渙/朱斌全零；V015 白馬驛旧唐書在册句只对照不重开——两段逐字入引为看景两界判决证据' AS locator, '如出九泉睹白日，已死而復生矣！」……此輩常自謂清流，宜投之黃河，使為濁流！」' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-361-person' AS claim_id, 'source-quantangshi-253' AS source_id, '卷二百五十三·王之渙小传整段逐字入引（**正史无传、总集编者给的本库唯一传**：王之渙/朱斌/崔國輔/鄭昈/之賁史部快照全零——jts 27+xts 8+qss 3+通鉴 75 机器断言；「朱斌」118 卷恰一恰在本卷题注——归属异议对方名字只活在编者注里；与选本页 notes 两处独立成对只登记不裁决，V079 同款规则；之咸在册两条系另一人不攀附；新源承载）' AS locator, '王之渙，幷州人，兄之咸、之賁皆有文名。天寶間，與王昌齡、崔國輔、鄭昈聯唱迭和，名動一時。詩六首。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（四句五绝 1/1/1/1 第八次） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-361-scene' AS background_id, 'text-work-t300-361-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-361-city' AS background_id, 'text-work-t300-361-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-361-world' AS background_id, 'text-work-t300-361-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-361-person' AS background_id, 'text-work-t300-361-ws' AS version_id, 4 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 76, 'Wang Zhihuan''s Climbing the Stork Tower (work-t300-361) background layers (stage-D poem 57, the most-marked poem page in the whole corpus; four-line quatrain 1/1/1/1, eighth time): dating verdict fifty-one, thirty-ninth shape of the title-evidence series -- the poem''s white sun and yellow river; the Tongjian has exactly one entry for each, and not one of them is watching the view. Same-character-two-realms, twenty-first shape: the scenic (kanjing) shape, first seen. Baiyun (white sun) appears exactly once in the Tongjian (Zhonghe 2, renyin, 882: after the Qian Neng revolt was crushed, the people of Shu greeted Gao Renhou "as if raised from the nine springs to see the white sun, dead and born again" -- the history''s white sun is the metaphor for a relieving army, the poem''s white sun is the sun setting behind the mountains). Huanghe appears exactly once (Tianyou 2, yichou, 905: at Baima station Li Zhen, hating the gentry, told Zhu Quanzhong "these fellows always called themselves the pure stream -- better throw them into the Yellow River and let them become the muddy flow" -- the history''s Yellow River is the ditch proposed for drowning the pure stream, the poem''s Yellow River is living water running to the sea; V015''s closed Old Tangshu sentence on the same massacre is juxtaposed only, and the audit hard-asserts the three characters for the station name never re-enter any citation of this migration). Qianlimu (thousand-li gaze), cenglou (upper storey), the heron characters in both graphforms, Wang Zhihuan and Zhu Bin all score zero in the Tongjian (machine-asserted): the poem''s two great landscapes land in no ledger of the histories (declared contrast, not historical causation). SHELL-ON-RECORD: unlike V075''s out-of-catalog zero, the base book here is present in the snapshot -- Quan Tangshi juan 253 carries the poem as an empty transclusion shell {{:登鸛雀樓 (王之渙)}}, and the four clean lines score zero across the 118 snapshot volumes (machine-asserted): on record as a shell, not as text; the shell''s target page is never quoted (if it is not in the snapshot there is no verifiable slice -- the honest boundary of this poem). VOLUME-HIERARCHY, first seen: juan 253 is a multi-poet volume and anchors poems at heading level three, "===[[...]]===" -- 37 of 37 anchors in this volume (machine-asserted); under the anchor sits the editors'' bold-italic double note "variant title: Climbing the Stork-and-Magpie Tower; alternatively by Zhu Bin" -- the editors'' title-note stating an attribution dispute outright (an upgrade of V073''s curator author-note at the anchor; registered, never adjudicated). THE STORED FACE IS THE READING FACE, first seen: the page is the most heavily marked poem page of the corpus -- title carries {{另|雀|鵲}}, line 1 carries an inline {{文苑英華}} "variant: 徹" <ref> with no reflist anywhere on the page (an orphan note, registered as-is), line 4 carries {{另|層|重}}, and the notes field says "alternatively by Zhu Bin, see Guoxiuji": four variant/attribution carriers on one page. V018 stored the poem with version_code ws-raw as four clean lines -- the folded face of this page: 雀/層 taken from the head of {{另}}, the whole <ref> fragment trimmed (generator asserts the pair-join both directions). Same-face-zero-divergence does not hold here; what holds is DIVISION OF LABOR BETWEEN VARIANTS AND READING: the page keeps the readings, the store keeps the decision. THE ANTHOLOGY MARKER IS ABSENT, first of its closed set: the page carries neither {{唐詩三百首}} nor its category (closed set: exactly 48 pages corpus-wide, machine-asserted) -- the anthology''s claim on this poem rests on the editorial ledger, not on the page''s self-declaration; the footer categories include the 千家詩 line (a different anthology''s category: this page serves two anthologies) in a triple-category run unique in the corpus (代表作品/千家詩/有声文献), with {{Spoken Wikisource}} putting this page in the corpus-wide set of exactly three voiced pages (a 2020 Mandarin recording -- a modern layer, registered, not a historical source), plus an orphan </sub> closer unique corpus-wide (registered, not judged); the category lines are curator actions: not source claims, not upgraded (V048). Same-title-different-poet: juan 283 anchors "同崔邠登鸛雀樓" (Tong Cbin climbing the tower, under Sima Du) with its own shell, quoted verbatim (the 283 source at its third reuse; the literal 登鸛雀樓 appears in exactly two snapshot volumes, machine-asserted). PERSON: ZERO-BIOGRAPHY PERSON, second of the series -- Wang Zhihuan, Zhu Bin, Cui Guofu and Zheng Hu all score zero across the local history snapshots (27 JTS + 8 XTS + 3 QSS + 75 Tongjian volumes, machine-asserted; the two Zhi Xian hits belong to a different man and are not claimed). But unlike the man of V075, he has a biography -- two lines in the Quan-Tangshi editors'' appendix, quoted verbatim as this migration''s PERSON evidence: "Wang Zhihuan, a man of Bingzhou; his brothers Zhixian and Zhibi were all known for letters. In the Tianbao era he traded verses in turn with Wang Changling, Cui Guofu and Zheng Hu, and his name moved the age in one breath. Six poems." -- "his name moved the age" is a sentence the histories never gave him and the anthology editors did. The rival name lives only in an editor''s note: 朱斌 appears exactly once in all 118 Quan-Tangshi snapshot volumes -- inside this very note (machine-asserted) -- and once more, independently, in the anthology page''s notes: two witnesses registered side by side, nothing adjudicated (the V079 Jiangnan-qu rule). NEW SOURCES: exactly one -- source-quantangshi-253, the volume page (first volume-page source ever created: every source created since V066 was an anthology-page source; here it is the volume page that lacks a row while the anthology page already has V018''s -- the V066 precedent, mirrored for the first time; the audit asserts exactly one source insert and exactly one source delete in the rollback), while sources ws-t300-361 (second reuse) and quantangshi-283 (third reuse) are existing rows. Body use-ceiling, twenty-fourth instance: V018''s punctuated excerpt stands first and is never re-opened (hard assertion); the body is now closed. KNOWN zero honestly recorded (thirty-second instance -- V018''s own KNOWN text claim stays closed and untouched; audit reverse-asserts no KNOWN literal in this migration); closed precedent keywords (V018''s punctuated full quote and header-author line, V015''s Baima-station sentence) stay out of all citations'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 76);
COMMIT;
