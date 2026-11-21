-- V071：李商隱《錦瑟》(work-t300-010) 四层背景（阶段 D 第 52 首·惘然两界）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V014、V015、V016、V018、V033、V035、V039、V048、V053、V057、V058、
--       V059、V060、V061、V062、V063、V064、V065、V066、V067、V068、V069、V070 已执行
--       （work-t300-010 与其 text-work-t300-010-ws（version_code=ws-raw，八行带句读）
--       与其源 source-ws-t300-010（edition 字段即底本「全唐詩」）都是 V018 的行；
--       source-quantangshi-539 是 V018 已立的卷539 卷页源（V018/V067/V068/V069/V070 已引，
--       本迁移第六次复用——**这次引到的是与诗页互指的空壳 {{:錦瑟}}**）；
--       source-zizhi-tongjian-events 是 V014/V015 已立的通鉴事件源；
--       source-jiutangshu-wenyuan 是 V016 已立的旧唐书文苑传源（李商隐传在此，简化字录入）；
--       判例在册句（义山/开成二年/岭表/三十六体/未几病卒/大中末/仲郢坐/还郑州 V016、
--       锦瑟句读式正文与春眠不覺曉/穆王何事不重來/嵩雲秦樹/茂陵秋雨/乘興南遊 V018、
--       家書抵萬金/感時花濺淚 V011/V017、別來滄海事 V033、得宋之問藍田别墅 V035/V039、
--       凝碧池頭奏筦絃 V026/V035、樹杪百重泉 V063、雲能合長生藥 V068、
--       ↑ [[全唐詩/卷539#寄令狐郎中 V069、{{:夜雨寄北}}/秋霖双案/天子何在/亞貶循州/
--       俄而茂元卒/检校水部员外郎 V070）只对照不重开。
--       **本迁移零新建 source（连续第三首）——
--       audit 断言本文件零 poetry_source INSERT、回滚零 source 删除。**
--
-- 数据源（可复现）：emit_v071.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/錦瑟.txt（一枚诗行双 {{另|絃|弦}} 全库独串+notes 三连一行+页尾分类两行
--   无作者分类+无空格排版 times+poem 存原样+无注表无<ref>无from行）、
--   全唐詩卷539（锚 ==[[錦瑟]]== 全唐诗唯一+壳 {{:錦瑟}} 恰一+
--   **壳外全卷无本篇正文十一语全零**+春心/無端/滄海各恰一闭域）、
--   舊唐書卷190下（李商隐段首引一段+**段内诗面十六字全零（瑟弦单字亦零）**+段边界断言）、
--   通鑑卷203/206/215/263（四段逐字入引+四处年标题窗口断言：光宅元年六八四/
--   神功元年六九七/天復二年九〇二/天寶六年七四七）+
--   通鑑 75 卷负证计数扫描（錦瑟/莊生/庄生/望帝/杜鵑/蝴蝶/春心/華年/無端/追憶/滄海月/
--   曉夢 全零+惘然恰一在 203/滄海恰二分 206,263/淚恰三 215,236,256/能不惘然恰一/
--   是為龜鏡恰一/珠57/煙26/五十172 闭域）+
--   全唐詩负证（錦瑟恰四 225/539×2/540+本篇六整句全库零+房中曲恰一/錦瑟長於人恰一/
--   何時詔此金錢會恰一）+
--   既有迁移引文域逐句查重——传区间归属、二引/零重开/首引零域前提全部生成时断言。
--
-- 做：4 BACKGROUND content/claim/background + 5 组逐字引用（(claim,source) 主键每对恰一行）+
--   8 background_line（八句七律 **2/2/2/2 顺次**（V020 以来八句篇常规）：
--   scene→1,2 city→3,4 world→5,6 person→7,8，绑 text-work-t300-010-ws 的 8 行）+ 不碰 poetry_text_line。
-- 不做：**不新建任何 source（连续第三首）**；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「通鉴唯一的惘然是太后诏——史部的惘然有龟镜，诗的惘然没有」）：
--   * 「惘然两界」系通鉴四段逐字入引支撑的对照判决，非史实因果——通鉴不记这首诗本身；
--   * 「本事」（适梦/悼亡/自悼诸旧说）不裁决——本迁移引文一字不能裁决；系年零铸造；
--   * 「不喜偶对的人留下最工偶对的诗」「官历党籍对一架瑟」「藏珠泪」标明读法声明；
--     异文絃/弦只页内折叠登记不裁决；
--   * 通鉴惘然恰一是太后慰谕诏（光宅元年）、滄海恰一是狄疏国界恰一是杨行密弃路（天復二年）、
--     淚恰三是哥舒翰/杜甫语/御袍（与诗只共享字面，绝不当同一事）；
--   * 正文第二引上限用满：V018 句读式一引在先，本迁移引 ws 页 poem 块存原样面——
--     各从其录，V018 句读式引文不重开（生成时硬断言），此后此诗正文关闭；
--   * 「互指循环指针」「六整句只活在诗页」「双{{另}}独串」「notes 三连」「分类无作者」
--     均照登不判；
--   * 通鉴珠57/煙26/五十172 在册零入引（audit 硬卡零混入）；
--   * KNOWN 零如实记录（第廿七例，audit 反向断言 SQL 无 KNOWN 字面量）；
--   * V011/V016/V018/V026/V033/V035/V039/V053/V063/V066–V070 已引诸句只对照不重开。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 70，不含 71
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-010-%';             -- 空
--   SELECT id FROM poetry_source WHERE id IN ('source-ws-t300-010','source-quantangshi-539');
--    -- 两行（均 V018 所立，本迁移不新建）
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-010-ws';  -- 恰 8
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-010-%';       -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-010';                                  -- 8（2/2/2/2）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-010-%';  -- 四行全 LIKELY
--   SELECT COUNT(*) FROM poetry_source WHERE id='source-ws-t300-010';   -- 恰 1（V018 所立）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-010'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-010';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-010-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V071_rollback.sql（按 id 全枚举删除；**零 source 删除**——
--   source-ws-t300-010 与 source-quantangshi-539 皆 V018 所立，绝不删）
START TRANSACTION;

-- ---------- 0. 零新建 source（连续第三首；两源皆 V018 所立复用） ----------

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-010-scene' AS id, 'BACKGROUND' AS entity_type, '010-scene' AS slug, '眼前：五十弦的无端' AS title, '四层处境背景（阶段 D 第 52 首·八句七律 2/2/2/2）；史实句均有逐字引证；系年第四十六次判决（题证系列第卅四状·锦瑟无端与能不惘然）「诗里那一架瑟通鉴全库没有；通鉴唯一的惘然是太后慰谕老臣的诏书」——同字两界第十六形态·惘然形态首见：通鉴錦瑟/莊生/庄生/望帝/杜鵑/蝴蝶/春心/華年/無端/追憶/滄海月/曉夢全零（机器断言）；「惘然」恰一在光宅元年甲申六八四太后使武承嗣赍玺书慰谕刘仁轨（「初聞此語能不惘然靜而思之是為龜鏡」——**史部的惘然有龟镜（回思即规戒），诗的惘然没有**（只是當時已惘然，无镜可照））；「滄海」恰二分神功元年丁酉六九七狄仁傑疏（東拒滄海西阻流沙北橫大漠南阻五嶺——国界）与天復二年壬戌九〇二杨行密说冯弘鐸（胡為自棄滄海之外——弃路）——**史部的沧海分中外弃路，诗的沧海藏珠泪**；「淚」恰三（215/236/256 闭域），天寶六年丁亥七四七哥舒翰救王忠嗣「力陳忠嗣之冤請以己官爵贖之叩頭隨之言與淚俱」——**史部的泪落在官位旁边，诗的泪在月明的海上无官可赎**；珠57/煙26/五十172 在册闭域；**绑定形态三角齐·互指循环指针首见**：ws 诗页 notes「↑ 卷539#錦瑟」向上回指、卷539 本篇正文恰为「{{:錦瑟}}」向下转引——同一首诗两面互指，底本声明与转引方向相反（V069 单向↑/V070 单向{{:}}各见一次，本篇**同时在场成闭环**；壳外 539 全卷无本篇正文——莊生/望帝/蝴蝶/杜鵑/惘然/華年/追憶/藍田/五十絃/錦瑟無端/思華年 全零机器断言，春心/無端/滄海各恰一皆他诗闭域）；**本篇六整句全唐诗语料零存在**而「錦瑟」恰四：杜甫「何時詔此金錢會暫醉佳人錦瑟旁」+李賀《房中曲》「歸來已不見錦瑟長於人」+539 壳二——**此诗以宾语在他诗里活在《全唐诗》**；**零新建 source 连续第三首**（source-ws-t300-010 与 source-quantangshi-539皆 V018 所立，539 第六次复用——壳本身就是证据）；正文第二引上限用满第十九例（V018 句读式在先+本迁移 ws 原样面含双 {{另|絃|弦}}，各从其录，V018 句读式引文零重开断言）；异文絃/弦只页内折叠登记不裁决（无 <ref>无 {{reflist}} 无 from 行——与 V070 三件套页恰成两极）；**一枚诗行双{{另}} 全 ws 库独串**+**notes 三连一行**（三百首+100%+↑同值——V069顺序形态相反）+**页尾分类仅两行无 [[Category:李商隱]]**（21 页署名中仅 3 页：春雨/籌筆驛/錦瑟——机器断言；非史料声明不升格 V048）+无空格排版「| times=唐」照登；本事诸旧说一律不裁决；PERSON 旧传简化段首引一段（商隐能为古文不喜偶对——**史部记他文学习惯，锦瑟恰是律对典范**：读法声明）；**段内十六诗字全零（瑟弦单字亦零）：写尽锦瑟的人传里无一瑟字**——段级零证机器断言；V016 在册句零重开（域断言）；KNOWN 零如实记录（第廿七例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-010-city' AS id, 'BACKGROUND' AS entity_type, '010-city' AS slug, '这座城：互相指向的两个页面' AS title, '四层处境背景（阶段 D 第 52 首·八句七律 2/2/2/2）；史实句均有逐字引证；系年第四十六次判决（题证系列第卅四状·锦瑟无端与能不惘然）「诗里那一架瑟通鉴全库没有；通鉴唯一的惘然是太后慰谕老臣的诏书」——同字两界第十六形态·惘然形态首见：通鉴錦瑟/莊生/庄生/望帝/杜鵑/蝴蝶/春心/華年/無端/追憶/滄海月/曉夢全零（机器断言）；「惘然」恰一在光宅元年甲申六八四太后使武承嗣赍玺书慰谕刘仁轨（「初聞此語能不惘然靜而思之是為龜鏡」——**史部的惘然有龟镜（回思即规戒），诗的惘然没有**（只是當時已惘然，无镜可照））；「滄海」恰二分神功元年丁酉六九七狄仁傑疏（東拒滄海西阻流沙北橫大漠南阻五嶺——国界）与天復二年壬戌九〇二杨行密说冯弘鐸（胡為自棄滄海之外——弃路）——**史部的沧海分中外弃路，诗的沧海藏珠泪**；「淚」恰三（215/236/256 闭域），天寶六年丁亥七四七哥舒翰救王忠嗣「力陳忠嗣之冤請以己官爵贖之叩頭隨之言與淚俱」——**史部的泪落在官位旁边，诗的泪在月明的海上无官可赎**；珠57/煙26/五十172 在册闭域；**绑定形态三角齐·互指循环指针首见**：ws 诗页 notes「↑ 卷539#錦瑟」向上回指、卷539 本篇正文恰为「{{:錦瑟}}」向下转引——同一首诗两面互指，底本声明与转引方向相反（V069 单向↑/V070 单向{{:}}各见一次，本篇**同时在场成闭环**；壳外 539 全卷无本篇正文——莊生/望帝/蝴蝶/杜鵑/惘然/華年/追憶/藍田/五十絃/錦瑟無端/思華年 全零机器断言，春心/無端/滄海各恰一皆他诗闭域）；**本篇六整句全唐诗语料零存在**而「錦瑟」恰四：杜甫「何時詔此金錢會暫醉佳人錦瑟旁」+李賀《房中曲》「歸來已不見錦瑟長於人」+539 壳二——**此诗以宾语在他诗里活在《全唐诗》**；**零新建 source 连续第三首**（source-ws-t300-010 与 source-quantangshi-539皆 V018 所立，539 第六次复用——壳本身就是证据）；正文第二引上限用满第十九例（V018 句读式在先+本迁移 ws 原样面含双 {{另|絃|弦}}，各从其录，V018 句读式引文零重开断言）；异文絃/弦只页内折叠登记不裁决（无 <ref>无 {{reflist}} 无 from 行——与 V070 三件套页恰成两极）；**一枚诗行双{{另}} 全 ws 库独串**+**notes 三连一行**（三百首+100%+↑同值——V069顺序形态相反）+**页尾分类仅两行无 [[Category:李商隱]]**（21 页署名中仅 3 页：春雨/籌筆驛/錦瑟——机器断言；非史料声明不升格 V048）+无空格排版「| times=唐」照登；本事诸旧说一律不裁决；PERSON 旧传简化段首引一段（商隐能为古文不喜偶对——**史部记他文学习惯，锦瑟恰是律对典范**：读法声明）；**段内十六诗字全零（瑟弦单字亦零）：写尽锦瑟的人传里无一瑟字**——段级零证机器断言；V016 在册句零重开（域断言）；KNOWN 零如实记录（第廿七例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-010-world' AS id, 'BACKGROUND' AS entity_type, '010-world' AS slug, '这个天下：有龟镜的惘然' AS title, '四层处境背景（阶段 D 第 52 首·八句七律 2/2/2/2）；史实句均有逐字引证；系年第四十六次判决（题证系列第卅四状·锦瑟无端与能不惘然）「诗里那一架瑟通鉴全库没有；通鉴唯一的惘然是太后慰谕老臣的诏书」——同字两界第十六形态·惘然形态首见：通鉴錦瑟/莊生/庄生/望帝/杜鵑/蝴蝶/春心/華年/無端/追憶/滄海月/曉夢全零（机器断言）；「惘然」恰一在光宅元年甲申六八四太后使武承嗣赍玺书慰谕刘仁轨（「初聞此語能不惘然靜而思之是為龜鏡」——**史部的惘然有龟镜（回思即规戒），诗的惘然没有**（只是當時已惘然，无镜可照））；「滄海」恰二分神功元年丁酉六九七狄仁傑疏（東拒滄海西阻流沙北橫大漠南阻五嶺——国界）与天復二年壬戌九〇二杨行密说冯弘鐸（胡為自棄滄海之外——弃路）——**史部的沧海分中外弃路，诗的沧海藏珠泪**；「淚」恰三（215/236/256 闭域），天寶六年丁亥七四七哥舒翰救王忠嗣「力陳忠嗣之冤請以己官爵贖之叩頭隨之言與淚俱」——**史部的泪落在官位旁边，诗的泪在月明的海上无官可赎**；珠57/煙26/五十172 在册闭域；**绑定形态三角齐·互指循环指针首见**：ws 诗页 notes「↑ 卷539#錦瑟」向上回指、卷539 本篇正文恰为「{{:錦瑟}}」向下转引——同一首诗两面互指，底本声明与转引方向相反（V069 单向↑/V070 单向{{:}}各见一次，本篇**同时在场成闭环**；壳外 539 全卷无本篇正文——莊生/望帝/蝴蝶/杜鵑/惘然/華年/追憶/藍田/五十絃/錦瑟無端/思華年 全零机器断言，春心/無端/滄海各恰一皆他诗闭域）；**本篇六整句全唐诗语料零存在**而「錦瑟」恰四：杜甫「何時詔此金錢會暫醉佳人錦瑟旁」+李賀《房中曲》「歸來已不見錦瑟長於人」+539 壳二——**此诗以宾语在他诗里活在《全唐诗》**；**零新建 source 连续第三首**（source-ws-t300-010 与 source-quantangshi-539皆 V018 所立，539 第六次复用——壳本身就是证据）；正文第二引上限用满第十九例（V018 句读式在先+本迁移 ws 原样面含双 {{另|絃|弦}}，各从其录，V018 句读式引文零重开断言）；异文絃/弦只页内折叠登记不裁决（无 <ref>无 {{reflist}} 无 from 行——与 V070 三件套页恰成两极）；**一枚诗行双{{另}} 全 ws 库独串**+**notes 三连一行**（三百首+100%+↑同值——V069顺序形态相反）+**页尾分类仅两行无 [[Category:李商隱]]**（21 页署名中仅 3 页：春雨/籌筆驛/錦瑟——机器断言；非史料声明不升格 V048）+无空格排版「| times=唐」照登；本事诸旧说一律不裁决；PERSON 旧传简化段首引一段（商隐能为古文不喜偶对——**史部记他文学习惯，锦瑟恰是律对典范**：读法声明）；**段内十六诗字全零（瑟弦单字亦零）：写尽锦瑟的人传里无一瑟字**——段级零证机器断言；V016 在册句零重开（域断言）；KNOWN 零如实记录（第廿七例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-010-person' AS id, 'BACKGROUND' AS entity_type, '010-person' AS slug, '这个人：传里无一瑟字' AS title, '四层处境背景（阶段 D 第 52 首·八句七律 2/2/2/2）；史实句均有逐字引证；系年第四十六次判决（题证系列第卅四状·锦瑟无端与能不惘然）「诗里那一架瑟通鉴全库没有；通鉴唯一的惘然是太后慰谕老臣的诏书」——同字两界第十六形态·惘然形态首见：通鉴錦瑟/莊生/庄生/望帝/杜鵑/蝴蝶/春心/華年/無端/追憶/滄海月/曉夢全零（机器断言）；「惘然」恰一在光宅元年甲申六八四太后使武承嗣赍玺书慰谕刘仁轨（「初聞此語能不惘然靜而思之是為龜鏡」——**史部的惘然有龟镜（回思即规戒），诗的惘然没有**（只是當時已惘然，无镜可照））；「滄海」恰二分神功元年丁酉六九七狄仁傑疏（東拒滄海西阻流沙北橫大漠南阻五嶺——国界）与天復二年壬戌九〇二杨行密说冯弘鐸（胡為自棄滄海之外——弃路）——**史部的沧海分中外弃路，诗的沧海藏珠泪**；「淚」恰三（215/236/256 闭域），天寶六年丁亥七四七哥舒翰救王忠嗣「力陳忠嗣之冤請以己官爵贖之叩頭隨之言與淚俱」——**史部的泪落在官位旁边，诗的泪在月明的海上无官可赎**；珠57/煙26/五十172 在册闭域；**绑定形态三角齐·互指循环指针首见**：ws 诗页 notes「↑ 卷539#錦瑟」向上回指、卷539 本篇正文恰为「{{:錦瑟}}」向下转引——同一首诗两面互指，底本声明与转引方向相反（V069 单向↑/V070 单向{{:}}各见一次，本篇**同时在场成闭环**；壳外 539 全卷无本篇正文——莊生/望帝/蝴蝶/杜鵑/惘然/華年/追憶/藍田/五十絃/錦瑟無端/思華年 全零机器断言，春心/無端/滄海各恰一皆他诗闭域）；**本篇六整句全唐诗语料零存在**而「錦瑟」恰四：杜甫「何時詔此金錢會暫醉佳人錦瑟旁」+李賀《房中曲》「歸來已不見錦瑟長於人」+539 壳二——**此诗以宾语在他诗里活在《全唐诗》**；**零新建 source 连续第三首**（source-ws-t300-010 与 source-quantangshi-539皆 V018 所立，539 第六次复用——壳本身就是证据）；正文第二引上限用满第十九例（V018 句读式在先+本迁移 ws 原样面含双 {{另|絃|弦}}，各从其录，V018 句读式引文零重开断言）；异文絃/弦只页内折叠登记不裁决（无 <ref>无 {{reflist}} 无 from 行——与 V070 三件套页恰成两极）；**一枚诗行双{{另}} 全 ws 库独串**+**notes 三连一行**（三百首+100%+↑同值——V069顺序形态相反）+**页尾分类仅两行无 [[Category:李商隱]]**（21 页署名中仅 3 页：春雨/籌筆驛/錦瑟——机器断言；非史料声明不升格 V048）+无空格排版「| times=唐」照登；本事诸旧说一律不裁决；PERSON 旧传简化段首引一段（商隐能为古文不喜偶对——**史部记他文学习惯，锦瑟恰是律对典范**：读法声明）；**段内十六诗字全零（瑟弦单字亦零）：写尽锦瑟的人传里无一瑟字**——段级零证机器断言；V016 在册句零重开（域断言）；KNOWN 零如实记录（第廿七例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-010-scene' AS id, 'bg-010-scene' AS subject_id, 'context' AS property_key, '八句七律本文**第二引上限用满第十九例**：V018 句读式一引在先（「錦瑟無端五十絃，……只是當時已惘然。」——絃已展开），本迁移二引 ws 页 poem 块**存原样**（八句带句读、首行两枚 {{另|絃|弦}} 原样保留，各从其录；生成时断言V018 句读式引文不重开），此后正文对后来迁移关闭；异文絃/弦只页内折叠登记不裁决（无 <ref> 无 {{reflist}} 无 from 行——与 V070 三件套页恰成两极）；**一枚诗行双 {{另}} 全 ws 库独串**（机器断言）；**notes 三连一行**（三百首+100%+↑回指同值——V069 顺序形态相反）；页尾分类仅两行无作者分类（21 页署名中仅 3 页——机器断言；分类非史料声明不升格 V048）；无空格排版「| times=唐」照登；本事诸旧说（适梦/悼亡/自悼）一律不裁决，系年零铸造。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-010-city' AS id, 'bg-010-city' AS subject_id, 'context' AS property_key, '本篇系**互指循环指针**：ws 诗页 notes「↑ [[全唐詩/卷539#錦瑟|全唐詩·卷五百三十九]]」向上回指，卷539 本篇正文恰为「{{:錦瑟}}」向下转引——底本声明与转引方向相反（V018 底本字段「全唐詩」指向 539、539 正文又是诗页转引；机器断言：壳锚唯一）；绑定三角至此齐（V069 单向↑/V070 单向{{:}}/本篇互指闭环——V070 是两个方向各见一次，本篇是同时在场）；壳外 539 全卷无本篇正文（莊生/望帝/蝴蝶/杜鵑/惘然/華年/追憶/藍田/五十絃/錦瑟無端/思華年 全零；春心/無端/滄海各恰一皆他诗闭域——机器断言）；**本篇六整句全唐诗语料零存在**而「錦瑟」恰四：杜甫「何時詔此金錢會暫醉佳人錦瑟旁」+李賀《房中曲》「歸來已不見錦瑟長於人」+壳二——**此诗以宾语在他诗里活在《全唐诗》**；**零新建 source 连续第三首**（source-ws-t300-010 与 source-quantangshi-539 皆V018 所立，539 第六次复用——壳本身就是证据）。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-010-world' AS id, 'bg-010-world' AS subject_id, 'context' AS property_key, '通鉴「錦瑟/莊生/庄生/望帝/杜鵑/蝴蝶/春心/華年/無端/追憶/滄海月/曉夢」全零（机器断言）而惘然沧海泪在他字：「惘然」恰一在光宅元年甲申六八四太后慰谕刘仁轨（「初聞此語能不惘然靜而思之是為龜鏡」——**史部的惘然有龟镜，诗的惘然没有**）；「滄海」恰二分神功元年丁酉六九七狄仁傑疏（東拒滄海西阻流沙——国界）与天復二年壬戌九〇二杨行密说冯弘鐸（胡為自棄滄海之外——弃路）——**史部的沧海分中外弃路，诗的沧海藏珠泪**；「淚」恰三（215/236/256），天寶六年丁亥七四七哥舒翰救王忠嗣「力陳忠嗣之冤請以己官爵贖之叩頭隨之言與淚俱」——**史部的泪落在官位旁边，诗的泪在月明的海上无官可赎**（同字两界第十六形态·惘然形态首见，audit 硬卡）；珠57/煙26/五十172 在册零入引；certainty 不覆盖任何系年，time.span/event.name/written_during 零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-010-person' AS id, 'bg-010-person' AS subject_id, 'context' AS property_key, '旧传李商隐段（简化字录入照登原样）首引一段零域=「商隐能为古文，不喜偶对。」（传区间归属机器断言）；**段级十六诗字全零**：段内錦/瑟/絃/弦/柱/蝶/望帝/杜鵑/滄海/藍田/珠/淚/煙/惘然/追憶/華年全零（机器断言，瑟弦单字亦零）——**写尽锦瑟的人传里无一瑟字**；「不喜偶对的人留下最工偶对的诗」「官历党籍对一架瑟」系读法声明非史实因果；本诗 ws 页 notes 有回指注（V070 空壳的反面）；V016 在册句（字义山/开成二年/岭表/三十六体/未几病卒/大中末/仲郢坐/还郑州）零重开（域断言）；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-010-scene' AS subject_id, 'context' AS property_key, 'claim-bg-010-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-010-city' AS subject_id, 'context' AS property_key, 'claim-bg-010-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-010-world' AS subject_id, 'context' AS property_key, 'claim-bg-010-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-010-person' AS subject_id, 'context' AS property_key, 'claim-bg-010-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-010-scene' AS id, 'work-t300-010' AS work_id, 'SCENE' AS layer, '八句是一架瑟上的终身账（2/2/2/2 起两句入眼前层）：锦瑟无端五十弦，一弦一柱思华年——瑟为什么是五十弦？「无端」（「錦瑟無端五十{{另|絃|弦}}，一{{另|絃|弦}}一柱思華年。」）。此后的六个意象只并置不解释：庄生晓梦、望帝春心、沧海月明、蓝田日暖、可待追忆、当时惘然。**此诗没有本事，本迁移不铸造本事**（适梦/悼亡/自悼诸旧说一律不裁决——引文一字不能裁决）。ws 诗页：**一枚诗行内两枚 {{另|絃|弦}} 折叠——全 ws 库独串**（机器断言：该串全库仅此页有；异文絃/弦只页内折叠，无 <ref> 无 {{reflist}} 无 from 行——与 V070 三件套页恰成两极）；**notes 三连一行**：{{唐詩三百首}}+{{Textquality|100%}}+↑底本回指挤在同一 notes 值里（V069 是↑+评级在 notes、三百首在 header 外尾——顺序形态相反，照登）；页尾分类仅两行、**无 [[Category:李商隱]]**（李商隱署名 21 页中无作者分类仅 3 页：春雨/籌筆驛/錦瑟——机器断言；整理者分类动作非史料声明、不升格，V048 判例）；无空格排版「| times=唐」照登。**此诗正文系第二引（上限用满第十九例）**：V018 已引句读式（「錦瑟無端五十絃，……只是當時已惘然。」——絃已展开），本迁移改引 ws 页 poem 块**存原样**：八句带句读、首行两枚 {{另|絃|弦}} 原样保留（各从其录；生成时断言 V018 句读式引文不重开）；异文絃/弦只登记不裁决；此后此诗正文关闭。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-010-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-010-city' AS id, 'work-t300-010' AS work_id, 'CITY' AS layer, '卷539 侧是本迁移最特殊的一块——**同一首诗，两个页面互相指向对方**：ws 诗页 notes 带「↑ [[全唐詩/卷539#錦瑟|全唐詩·卷五百三十九]]」向上回指卷页，而卷539 的本篇正文恰恰是「==[[錦瑟]]==」+「{{:錦瑟}}」向下转引诗页——**底本声明与转引方向相反：底本是个循环指针**（V018 底本字段「全唐詩」指向 539，539 正文又是 ws 页的转引；机器断言：{{:錦瑟}} 壳恰一，壳外全卷无本篇正文——莊生/望帝/蝴蝶/杜鵑/惘然/華年/追憶/藍田/五十絃/錦瑟無端/思華年 全零，春心/無端/滄海各恰一皆他诗闭域）。绑定形态至此三角齐：V069 诗页单向↑回指、V070 卷页单向{{:}}转引、**本篇同一首诗两面互指**——V070 说「双向绑定集齐」是两个方向各见过一次，本篇是**两个方向同时在场**（闭环）。壳本身就是证据：编诗者视此诗归属已定、不必重抄。**全唐诗语料里本篇六整句零存在**（机器断言：錦瑟無端五十/莊生曉夢迷蝴蝶/……/只是當時已惘然 七段全零）——**此诗以宾语在他诗里活在《全唐诗》**：「錦瑟」全唐诗恰四=225 杜甫「何時詔此金錢會，暫醉佳人錦瑟旁」+539 壳二+540 李賀《房中曲》「歸來已不見，錦瑟長於人」——杜甫酒边的锦瑟、李贺悼亡的锦瑟，都不是这一首。（本层零 relation。）**本迁移零新建 source（连续第三首）**：source-ws-t300-010 与 source-quantangshi-539 皆 V018 所立，539 第六次复用。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-010-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-010-world' AS id, 'work-t300-010' AS work_id, 'WORLD' AS layer, '**诗里那一架瑟，通鉴全库没有；通鉴唯一的惘然，是太后慰谕老臣的诏书**（同字两界第十六形态·惘然形态首见）：通鉴「**錦瑟/莊生/庄生/望帝/杜鵑/蝴蝶/春心/華年/無端/追憶/滄海月/曉夢**」全零（机器断言）——诗面典故群史部一个都不接。可通鉴不是没有惘然与沧海：① 「**惘然**」恰一，在光宅元年（甲申，六八四）：太后代亲政，刘仁轨上疏以吕后祸败申规戒，太后使武承嗣赍玺书慰谕：「**初聞此語，能不惘然；靜而思之，是為龜鏡**」——**史部的惘然有龟镜**：惘然之后静而思之，老臣的逆耳话被供为镜鉴；**诗的惘然没有**：「只是當時已惘然」——当时已惘然，何况成追忆，无镜可照（对照判决，非史实因果——通鉴不记这首诗本身）；② 「**滄海**」恰二：神功元年（丁酉，六九七）狄仁傑上疏「**東拒滄海，西阻流沙，北橫大漠，南阻五嶺**，此天所以限夷狄而隔中外也」——沧海是国界；天復二年（壬戌，九〇二）冯弘鐸兵败将入海，杨行密说之「**胡為自棄滄海之外**！吾府雖小，足以容公之眾」——沧海是弃路。**史部的沧海分中外、标弃路；诗的沧海藏珠泪**（「滄海月明珠有淚」——同一个沧海，史部用来划界，诗用来藏一颗眼泪）；③ 「**淚**」恰三（215/236/256 闭域），最近诗面的一条在天寶六年（丁亥，七四七）三司按王忠嗣，哥舒翰「**力陳忠嗣之冤，且請以己官爵贖忠嗣罪；上起，入禁中，翰叩頭隨之，言與淚俱**」——**史部的泪落在官位旁边**（叩头随驾、请以官爵赎罪）；诗的泪在月明的海上，无官可赎。「珠」恰五十七/「煙」恰二十六/「五十」恰一百七十二在册零入引（闭域档扫）。本层零铸造零 relation。' AS body_text, 'SENIOR' AS audience, 'claim-bg-010-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-010-person' AS id, 'work-t300-010' AS work_id, 'PERSON' AS layer, '旧传李商隐段（**简化字录入**，V016 locator 同款标注，引文照登简体原样）首引一段（零域）：「**商隐能为古文，不喜偶对。**」
史部记他早年的文学习惯：能写古文，不喜欢对偶——**而《锦瑟》恰恰是律对最工的诗**：莊生对望帝、沧海对蓝田、晓梦梦迷对春心托—（读法声明：「不喜偶对的人留下最工偶对的诗」是读者的一句感叹，非史实因果）。
**写尽锦瑟的人，传里无一瑟字**：段内诗面十六字「錦/瑟/絃/弦/柱/蝶/望帝/杜鵑/滄海/藍田/珠/淚/煙/惘然/追憶/華年」全零（机器断言——瑟、弦单字亦零，比历篇段级零证更强），连「梦」字也无。史部给他的是另一串事：令狐楚幕、今体章奏、茂元娶、牛李党隙（V016 在册诸句零重开，域断言）——传把这个人写成官历与党籍，诗把这个人写成一架瑟（读法声明）。
本诗 ws 页 notes **有**回指注（V070 空壳的反面：注的有无本身也是形态，且本页注与卷页壳互指）；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 仍零铸造（audit 硬卡）。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-010-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文 ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-010-scene' AS claim_id, 'source-ws-t300-010' AS source_id, '页面 錦瑟（《唐詩三百首》第 10 首选本页，页题裸名；title+无空格排版 times+author+poem 块以「……」相连——poem 块**存原样**：八句带句读、首行一枚诗行内两枚 {{另|絃|弦}} 折叠（絃/弦异文只页内登记不裁决，无 <ref> 无 {{reflist}} 无 from 行——与 V070 三件套页恰成两极）；正文第二引上限用满第十九例（V018 句读式一引在先，本迁移引原样面，各从其录，生成时断言 V018 句读式引文不重开）' AS locator, '| title    = 錦瑟……| times=唐……| author   = 李商隱……錦瑟無端五十{{另|絃|弦}}，一{{另|絃|弦}}一柱思華年。
莊生曉夢迷蝴蝶，望帝春心託杜鵑。
滄海月明珠有淚，藍田日暖玉生煙。
此情可待成追憶，只是當時已惘然。
</poem>' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-010-city' AS claim_id, 'source-quantangshi-539' AS source_id, '卷五百三十九·李商隱《錦瑟》**空壳转引块**（「==[[錦瑟]]==」+「{{:錦瑟}}」——壳外全卷无本篇正文一字：莊生/望帝/蝴蝶/杜鵑/惘然/華年/追憶/藍田/五十絃/錦瑟無端/思華年 全零机器断言；春心/無端/滄海各恰一皆他诗闭域；**与本页 notes ↑回指互指**——底本声明与转引方向相反，循环指针（V069 单向↑/V070 单向{{:}}之三角第三态）；锚全唐诗唯一；源行系 V018 已立、本迁移第六次复用零新建）' AS locator, '==[[錦瑟]]==
{{:錦瑟}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-010-city' AS claim_id, 'source-ws-t300-010' AS source_id, '页面 錦瑟（notes 三连一行整值入引（{{唐詩三百首}}+{{Textquality|100%}}+↑底本回指同挤一个 notes 值——V069 顺序形态相反；↑ 指向恰是转引本篇的 539 壳——互指之诗页侧）+页尾分类两行（简繁并立；**无 [[Category:李商隱]]**——李商隱署名 21 页中无作者分类仅 3 页机器断言；分类行系整理者分类动作：非史料声明、不升格，V048 判例）；本迁移零新建源连续第三首）' AS locator, '| notes    = {{唐詩三百首}}{{Textquality|100%}}↑ [[全唐詩/卷539#錦瑟|全唐詩·卷五百三十九]]……[[Category:唐诗]]
[[Category:唐詩三百首|李]]' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-010-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '卷二百零三·光宅元年（甲申，六八四）太后慰谕刘仁轨诏（「初聞此語能不惘然靜而思之是為龜鏡」——史部唯一惘然有龟镜）……卷二百零六·神功元年（丁酉，六九七）狄仁傑上疏「東拒滄海西阻流沙」（国界）……卷二百六十三·天復二年（壬戌，九〇二）杨行密说冯弘鐸「胡為自棄滄海之外」（弃路）……卷二百一十五·天寶六年（丁亥，七四七）哥舒翰救王忠嗣「叩頭隨之言與淚俱」（泪落官位旁）；通鉴诗面錦瑟/莊生等十二语全零，惘然恰一/滄海恰二/淚恰三（四段逐字入引为判决证据）' AS locator, '初聞此語，能不惘然；靜而思之，是為龜鏡。……東拒滄海，西阻流沙，北橫大漠，南阻五嶺，……胡為自棄滄海之外！……力陳忠嗣之冤，且請以己官爵贖忠嗣罪；上起，入禁中，翰叩頭隨之，言與淚俱。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-010-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書卷一九〇下·李商隱（**简化字录入**照登原样，V016 locator 同款标注）（「商隐能为古文，不喜偶对」段（史部记他早年的文学习惯——全库查重恰零域首引；传区间归属机器断言；段内诗面十六字錦/瑟/絃/弦/柱/蝶/望帝/杜鵑/滄海/藍田/珠/淚/煙/惘然/追憶/華年全零——写尽锦瑟的人传里无一瑟字；「最工偶对」系读法声明；V016/V070 在册句零重开）' AS locator, '商隐能为古文，不喜偶对。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（八句七律 2/2/2/2 顺次） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-010-scene' AS background_id, 'text-work-t300-010-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-010-scene' AS background_id, 'text-work-t300-010-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-010-city' AS background_id, 'text-work-t300-010-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-010-city' AS background_id, 'text-work-t300-010-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-010-world' AS background_id, 'text-work-t300-010-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-010-world' AS background_id, 'text-work-t300-010-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-010-person' AS background_id, 'text-work-t300-010-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-010-person' AS background_id, 'text-work-t300-010-ws' AS version_id, 8 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 71, 'Li Shang-yin''s Inscribed Harps (work-t300-010) background layers (stage-D poem 52, eight-line regulated verse 2/2/2/2): dating verdict forty-six, thirty-fourth shape of the title-evidence series -- the harp in the poem is nowhere in the whole Zizhi Tongjian, and the histories'' one and only "wangran" (dazed) is an empress dowager''s console to an old minister. Same-character-two-realms, sixteenth shape: the wangran shape, first seen. The Tongjian scores zero on every allusion of the poem -- jinse (inscribed harp), Zhuangzi, Wangdi, the cuckoo, the butterfly, spring heart, florid years, "without reason", "recollecting", "the moon over the dark blue sea", "dawn dream" (machine-asserted). Yet "wangran" appears exactly once, in Guangzhai 1, jiashen, 684: when Liu Ren-gui remonstrated by citing the fall of the吕 clan, the empress dowager had Wu Chengsi carry a seal-letter consoling him: "at first hearing these words, how could I not feel dazed; ponder them in stillness, and they become a mirror" -- the histories'' daze has a mirror (reflection turns into admonition); the poem''s daze has none (it was already dazed at the time -- 只是當時已惘然 -- no mirror to hold it up). "Dark blue sea (canghai)" appears exactly twice, in two different worlds: in Shengong 1, dingyou, 697, Di Renjie memorialises that "east it bars the dark blue sea, west the flowing sands, north the great desert, south the five ridges -- this is how heaven limits the barbarians and separates inside from outside" (a frontier); in Tianfu 2, renxu, 902, Yang Xingmi persuades Feng Hongduo: "why cast yourself beyond the dark blue sea!" (a road of no return) -- the histories'' dark blue sea draws borders and marks desperate roads; the poem''s dark blue sea hides a pearl''s tear. "Tears" appear exactly three times, the closest in Tianbao 6, dinghai, 747, when Geshu Han pleads for the wrongfully condemned Wang Zhongsi: "he kowtowed following the emperor into the forbidden precincts, his words and his tears together" -- the histories'' tears fall beside an office, begged away from a throne; the poem''s tear sits on the moonlit sea with no office to redeem it. The binding forms of scroll page and poem page now form a closed triangle: V069 pointed up (the poem page''s arrow), V070 pointed down (the scroll page''s transclusion), and this poem is pointed at from both sides at once -- the ws page''s notes carry the back-reference arrow to 卷539#錦瑟 while the scroll page''s text of this very poem is the transclusion stub {{:錦瑟}} -- base-text declaration and transclusion direction reversed: the base text is a circular pointer (machine-asserted: exactly one stub; outside the shell, not one phrase of this poem anywhere in juan 539 -- Zhuangzi/Wangdi/butterfly/cuckoo/wangran/florid years/recollecting/Lantian/fifty-strings all zero; three lone other-poem fragments closed out). All seven full lines of this poem score zero across the whole Quan Tangshi corpus, yet the two words "錦瑟" appear exactly four times -- Du Fu''s "drunk a while beside a lady''s inscribed harp", Li He''s "home again, it is no longer seen; the inscribed harp lingers longer than the person" from his Chamber Song, plus the two shell graphs: this poem lives inside the Quan Tangshi only as other poems'' object; the text itself lives only on the poem page. ZERO new sources, third poem running (audit asserts zero poetry_source INSERT and zero source deletion); both sources were established by V018, the 539 source at its sixth reuse. Body use-ceiling reached, nineteenth instance: V018 quoted the punctuated abbreviation (fifty strings... already dazed at the time); this migration quotes the ws page''s raw poem block, first line keeping both inline {{另}} variant folds (xian vs. xian-simplified) -- registering only, never adjudicating, and the apparatus here is the mirror opposite of V070''s page (no <ref>, no reflist, no from-chain; machine-asserted unique two-fold line across the whole ws corpus); the notes field packs the anthology tag, the 100 percent rating and the base-text arrow into one value (reverse order-shape of V069); the category footer is just two lines with no author category (only three of the 21 Li Shang-yin pages, machine-asserted; editorial, not a source claim, not upgraded, V048 precedent); the spacing form | times=唐 logged as-is. The poem''s old biographical readings (dream, mourning, self-mourning) are all left undecided -- no本事 is cast; dating stays unforged. PERSON first-cites one zero-domain simplified JTS passage -- "Shang-yin could write old-style prose and disliked parallel pairs" -- while the biography segment holds not one of the sixteen character-words of the poem''s imagery, neither se nor xian even singly (machine-asserted): the man who wrote the harp out of existence leaves not one harp-graph in his biography; "the man who disliked parallel pairs left the most perfectly paired poem" is a reading declared, not a fact. KNOWN zero honestly recorded (twenty-seventh instance, audit reverse-asserts); closed precedent keywords (including V033''s sea of parting, V035/V039''s Lantian villa and V070''s empty shell) stay out of citations'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 71);
COMMIT;
