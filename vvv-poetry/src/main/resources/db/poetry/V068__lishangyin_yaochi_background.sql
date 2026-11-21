-- V068：李商隱《瑤池》(work-t300-026) 四层背景（阶段 D 第 49 首·瑶池与长生）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V014、V015、V016、V018、V035、V048、V057、V058、V059、V060、V061、
--       V062、V063、V064、V065、V066、V067 已执行
--       （work-t300-026 与其 text-work-t300-026-ws、source-quantangshi-539 是 V018 的行
--       （V018 以卷539 卷页立本诗正文，version_code=vol-raw——ws 选本页当时未建源）；
--       source-ws-t300-026 是本迁移新建的选本页源（恰一枚；audit 断言）；
--       source-zizhi-tongjian-events 是 V014/V015 已立的通鉴事件源；
--       source-jiutangshu-wenyuan 是 V016 已立的旧唐书文苑传源（李商隐传在此，简化字录入）；
--       判例在册句（义山/开成二年/岭表/三十六体 V016、绹不之省/坎壈终身 V066、
--       乘興南遊/孫處約諫書/以所业文干之/下笔不能自休 V067）只对照不重开）。
--       **本迁移再新建恰 1 个 source（source-ws-t300-026）——连续第三首开新源（V066/V067
--       判例同构：卷页/诗页两个独立见证面）；audit 断言恰一枚诗源表新建插入语句且 id 唯一、
--       回滚按 id 删且只删此行。**
--
-- 数据源（可复现）：emit_v068.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/瑤池.txt（notes 裸标记同卷两形态首见+title 裸名同卷两形态+poem 全无句读
--   第二见+无评级第三见+零标记+Vtext/poem 双转录+分类三行简繁混排）、
--   全唐詩卷539（锚 ==[[瑤池]]== 全唐诗唯一+卷内穆王/八駿/黃竹各恰一+同卷隋宫双锚在册
--   对照；全唐诗 瑤池字面十条八卷/西王母恰二/阿母恰五/綺窗恰三 档扫闭域）、
--   舊唐書卷190下（李商隐段首引二句+段内瑤池/穆王/八駿/長生/仙/黃竹全零+段边界断言）、
--   通鑑卷199/203/223/240/249（五段逐字入引+四处年标题窗口+两页零年标题断言）+
--   通鑑 75 卷负证计数扫描（八駿/黃竹/阿母/綺窗/三萬里/動地哀/重來/西王母/仙術 全零+
--   瑤池恰三全在tj-199零标题页/瑤池都督恰三/穆王恰三/長生恰十三处七卷/靈藥恰一 闭域）+
--   既有迁移引文域逐句查重——传区间归属、二引/零重开/首引零域/新源不存在前提全部生成时断言。
--
-- 做：新 poetry_source 行 1（source-ws-t300-026，PENDING）+
--   4 BACKGROUND content/claim/background + 5 组逐字引用（(claim,source) 主键每对恰一行）+
--   4 background_line（四句七绝 **1/1/1/1 第五次**（V056/V061/V066/V067 之后）：scene→1
--   city→2 world→3 person→4，绑 text-work-t300-026-ws 的 4 行）+ 不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「诗问死者何不重来，史部的皇帝们活着问长生」）：
--   * 仙界词通鉴全零+瑶池恰三全在零标题页（三连聚首见——不作窗口断言，声明在案）+
--     穆王恰三（奏疏引周王+两谥号——没一个是那个穆王）+長生恰十三双窗口入引+靈藥恰一；
--   * 「诗悯君之迷/传悯士之穷」标明读法声明；「恃才诡激，为当涂者所薄」标明史臣自断；
--   * 同卷单锚/双锚并存系 V067 在册判例上的标本齐备声明，非新证据；
--   * notes 两形态/title 两形态/poem 句读有无均照登不判（选本标记自身有形态谱）；
--   * 新源恰一枚如实开例（连续第三首，两引面不重叠声明在案），回滚可精确撤销；
--   * 全唐詩西王母/阿母/綺窗在册零入引（audit 硬卡零混入）；
--   * KNOWN 零如实记录（第廿四例，audit 反向断言 SQL 无 KNOWN 字面量）；
--   * V066/V067 已引诸句、V016 在册句只对照不重开。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 67，不含 68
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-026-%';             -- 空
--   SELECT id FROM poetry_source WHERE id IN ('source-ws-t300-026','source-quantangshi-539');  -- 只含 539
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-026-ws';  -- 恰 4
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-026-%';       -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-026';                                  -- 4（1/1/1/1）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-026-%';  -- 四行全 LIKELY（有意全 LIKELY）
--   SELECT COUNT(*) FROM poetry_source WHERE id='source-ws-t300-026';   -- 恰 1（本迁移新建）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-026'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-026';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-026-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V068_rollback.sql（按 id 全枚举删除；source 只删本迁移新建的
--   source-ws-t300-026 一行——source-quantangshi-539 系 V018 所立绝不删）
START TRANSACTION;

-- ---------- 0. 新 source 恰一枚（source-ws-t300-026 选本页；PENDING 照 V066/V067 判例） ----------
INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status, source_kind, reliability)
SELECT * FROM (
SELECT 'source-ws-t300-026' AS id, '维基文库《唐詩三百首》页面：瑤池' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/瑤池' AS url, '维基文库录入本，公有领域古籍。本行由 emit_v068.py 对 /tmp/src-dl 快照逐字定位。本诗 V018 立正文时用的是《全唐詩》卷539 卷页（source-quantangshi-539，version_code vol-raw），此《唐詩三百首》选本页当时未建源——卷页与诗页是两个独立见证面（卷页锚点归属 vs 选本页 header/notes/分类），本迁移引诗页非新源不能承载（V066 source-ws-t300-031、V067 source-ws-t300-022 判例同构，连续第三首）。页面 notes 只有 {{唐詩三百首}} 裸标记不挂诗体名（对照同卷隋宫页挂「七绝」——同卷 notes 两形态照登）；title 裸名；poem 块四句全无句读；无 Textquality 评级。核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status, 'POETRY_COLLECTION' AS source_kind, 'HIGH' AS reliability FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_source x WHERE x.id = t.id);

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-026-scene' AS id, 'BACKGROUND' AS entity_type, '026-scene' AS slug, '眼前：窗一直开着，人不来了' AS title, '四层处境背景（阶段 D 第 49 首·四句七绝 1/1/1/1 第五次）；史实句均有逐字引证；系年第四十三次判决（题证系列第卅一状·瑶池与长生）「诗问死者何不重来，史部的皇帝们活着问长生」——同字两界第十三形态·仙界形态首见：通鉴八駿/黃竹/阿母/綺窗/三萬里/動地哀/重來/西王母/仙術全零；瑤池恰三**全在 tj-199 且该页零年标题（50% 页三连聚首见——不可作窗口断言，整句入引+声明）**且三处全是安西边州建制（仙池史部没有，同名是边州任命）；穆王恰三分布三卷双窗口入引+一处零标题闭域（永淳元年壬午六八二奏疏引周王伯冏+廣德二年甲辰七六四谥号武穆王+tj-255 零标题页常山忠穆王——**没一个是巡游瑶池的那个**）；長生恰十三处七卷双窗口入引（元和十三年戊戌八一八柳泌「雲能合長生藥」+大中十一年丁丑八五七宣宗问轩辕集「長生可學乎/何處更求長生」——活着求长生的皇帝们，史部唯一正面回答是「何处更求长生」）；靈藥恰一在册；本篇锚「==[[瑤池]]==」全《全唐詩》唯一（字面十条八卷中锚恰一——对照 V067 同卷隋宫双锚：同卷单锚/双锚两种同名形态标本齐备）；卷内穆王/八駿/黃竹各恰一（诗面专名卷内自足）；西王母恰二/阿母恰五/綺窗恰三在册零入引；ws 页 notes 裸选本标记不挂体名（对照同卷隋宫页挂「七绝」——**同卷 notes 两形态首见**）+title 裸名（同卷 title 两形态首见）+poem 全无句读第二见+无评级页第三见+{{另}}/{{別}}/{{*}}/<ref> 全零；**再新建 source-ws-t300-026 恰一枚（连续第三首开新源 146→147——V066/V067 判例同构，卷页/诗页两个独立见证面；audit 断言恰一枚新源 INSERT）**；正文第二引上限用满第十六例（V018 在先+双针恰一，两引面不重叠）；PERSON 旧传简化段再首引二句（会昌二年书判拔萃+恃才诡激为当涂者所薄——诗悯君之迷/传悯士之穷读法声明）；段内瑤池/穆王/八駿/長生/仙字全零（**「仙」字段级零证首用——写尽瑶池的人传里无一仙字**）；V066/V067 已引诸句零重开（域断言）；KNOWN 零如实记录（第廿四例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-026-city' AS id, 'BACKGROUND' AS entity_type, '026-city' AS slug, '这座城：全唐诗唯一的瑶池锚' AS title, '四层处境背景（阶段 D 第 49 首·四句七绝 1/1/1/1 第五次）；史实句均有逐字引证；系年第四十三次判决（题证系列第卅一状·瑶池与长生）「诗问死者何不重来，史部的皇帝们活着问长生」——同字两界第十三形态·仙界形态首见：通鉴八駿/黃竹/阿母/綺窗/三萬里/動地哀/重來/西王母/仙術全零；瑤池恰三**全在 tj-199 且该页零年标题（50% 页三连聚首见——不可作窗口断言，整句入引+声明）**且三处全是安西边州建制（仙池史部没有，同名是边州任命）；穆王恰三分布三卷双窗口入引+一处零标题闭域（永淳元年壬午六八二奏疏引周王伯冏+廣德二年甲辰七六四谥号武穆王+tj-255 零标题页常山忠穆王——**没一个是巡游瑶池的那个**）；長生恰十三处七卷双窗口入引（元和十三年戊戌八一八柳泌「雲能合長生藥」+大中十一年丁丑八五七宣宗问轩辕集「長生可學乎/何處更求長生」——活着求长生的皇帝们，史部唯一正面回答是「何处更求长生」）；靈藥恰一在册；本篇锚「==[[瑤池]]==」全《全唐詩》唯一（字面十条八卷中锚恰一——对照 V067 同卷隋宫双锚：同卷单锚/双锚两种同名形态标本齐备）；卷内穆王/八駿/黃竹各恰一（诗面专名卷内自足）；西王母恰二/阿母恰五/綺窗恰三在册零入引；ws 页 notes 裸选本标记不挂体名（对照同卷隋宫页挂「七绝」——**同卷 notes 两形态首见**）+title 裸名（同卷 title 两形态首见）+poem 全无句读第二见+无评级页第三见+{{另}}/{{別}}/{{*}}/<ref> 全零；**再新建 source-ws-t300-026 恰一枚（连续第三首开新源 146→147——V066/V067 判例同构，卷页/诗页两个独立见证面；audit 断言恰一枚新源 INSERT）**；正文第二引上限用满第十六例（V018 在先+双针恰一，两引面不重叠）；PERSON 旧传简化段再首引二句（会昌二年书判拔萃+恃才诡激为当涂者所薄——诗悯君之迷/传悯士之穷读法声明）；段内瑤池/穆王/八駿/長生/仙字全零（**「仙」字段级零证首用——写尽瑶池的人传里无一仙字**）；V066/V067 已引诸句零重开（域断言）；KNOWN 零如实记录（第廿四例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-026-world' AS id, 'BACKGROUND' AS entity_type, '026-world' AS slug, '这个天下：史部的穆王与长生' AS title, '四层处境背景（阶段 D 第 49 首·四句七绝 1/1/1/1 第五次）；史实句均有逐字引证；系年第四十三次判决（题证系列第卅一状·瑶池与长生）「诗问死者何不重来，史部的皇帝们活着问长生」——同字两界第十三形态·仙界形态首见：通鉴八駿/黃竹/阿母/綺窗/三萬里/動地哀/重來/西王母/仙術全零；瑤池恰三**全在 tj-199 且该页零年标题（50% 页三连聚首见——不可作窗口断言，整句入引+声明）**且三处全是安西边州建制（仙池史部没有，同名是边州任命）；穆王恰三分布三卷双窗口入引+一处零标题闭域（永淳元年壬午六八二奏疏引周王伯冏+廣德二年甲辰七六四谥号武穆王+tj-255 零标题页常山忠穆王——**没一个是巡游瑶池的那个**）；長生恰十三处七卷双窗口入引（元和十三年戊戌八一八柳泌「雲能合長生藥」+大中十一年丁丑八五七宣宗问轩辕集「長生可學乎/何處更求長生」——活着求长生的皇帝们，史部唯一正面回答是「何处更求长生」）；靈藥恰一在册；本篇锚「==[[瑤池]]==」全《全唐詩》唯一（字面十条八卷中锚恰一——对照 V067 同卷隋宫双锚：同卷单锚/双锚两种同名形态标本齐备）；卷内穆王/八駿/黃竹各恰一（诗面专名卷内自足）；西王母恰二/阿母恰五/綺窗恰三在册零入引；ws 页 notes 裸选本标记不挂体名（对照同卷隋宫页挂「七绝」——**同卷 notes 两形态首见**）+title 裸名（同卷 title 两形态首见）+poem 全无句读第二见+无评级页第三见+{{另}}/{{別}}/{{*}}/<ref> 全零；**再新建 source-ws-t300-026 恰一枚（连续第三首开新源 146→147——V066/V067 判例同构，卷页/诗页两个独立见证面；audit 断言恰一枚新源 INSERT）**；正文第二引上限用满第十六例（V018 在先+双针恰一，两引面不重叠）；PERSON 旧传简化段再首引二句（会昌二年书判拔萃+恃才诡激为当涂者所薄——诗悯君之迷/传悯士之穷读法声明）；段内瑤池/穆王/八駿/長生/仙字全零（**「仙」字段级零证首用——写尽瑶池的人传里无一仙字**）；V066/V067 已引诸句零重开（域断言）；KNOWN 零如实记录（第廿四例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-026-person' AS id, 'BACKGROUND' AS entity_type, '026-person' AS slug, '这个人：当涂者的眼神' AS title, '四层处境背景（阶段 D 第 49 首·四句七绝 1/1/1/1 第五次）；史实句均有逐字引证；系年第四十三次判决（题证系列第卅一状·瑶池与长生）「诗问死者何不重来，史部的皇帝们活着问长生」——同字两界第十三形态·仙界形态首见：通鉴八駿/黃竹/阿母/綺窗/三萬里/動地哀/重來/西王母/仙術全零；瑤池恰三**全在 tj-199 且该页零年标题（50% 页三连聚首见——不可作窗口断言，整句入引+声明）**且三处全是安西边州建制（仙池史部没有，同名是边州任命）；穆王恰三分布三卷双窗口入引+一处零标题闭域（永淳元年壬午六八二奏疏引周王伯冏+廣德二年甲辰七六四谥号武穆王+tj-255 零标题页常山忠穆王——**没一个是巡游瑶池的那个**）；長生恰十三处七卷双窗口入引（元和十三年戊戌八一八柳泌「雲能合長生藥」+大中十一年丁丑八五七宣宗问轩辕集「長生可學乎/何處更求長生」——活着求长生的皇帝们，史部唯一正面回答是「何处更求长生」）；靈藥恰一在册；本篇锚「==[[瑤池]]==」全《全唐詩》唯一（字面十条八卷中锚恰一——对照 V067 同卷隋宫双锚：同卷单锚/双锚两种同名形态标本齐备）；卷内穆王/八駿/黃竹各恰一（诗面专名卷内自足）；西王母恰二/阿母恰五/綺窗恰三在册零入引；ws 页 notes 裸选本标记不挂体名（对照同卷隋宫页挂「七绝」——**同卷 notes 两形态首见**）+title 裸名（同卷 title 两形态首见）+poem 全无句读第二见+无评级页第三见+{{另}}/{{別}}/{{*}}/<ref> 全零；**再新建 source-ws-t300-026 恰一枚（连续第三首开新源 146→147——V066/V067 判例同构，卷页/诗页两个独立见证面；audit 断言恰一枚新源 INSERT）**；正文第二引上限用满第十六例（V018 在先+双针恰一，两引面不重叠）；PERSON 旧传简化段再首引二句（会昌二年书判拔萃+恃才诡激为当涂者所薄——诗悯君之迷/传悯士之穷读法声明）；段内瑤池/穆王/八駿/長生/仙字全零（**「仙」字段级零证首用——写尽瑶池的人传里无一仙字**）；V066/V067 已引诸句零重开（域断言）；KNOWN 零如实记录（第廿四例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-026-scene' AS id, 'bg-026-scene' AS subject_id, 'context' AS property_key, '四句七绝本文（ws 选本页 poem 块四句**全无句读**第二见，各从其录）；notes 裸选本标记不挂体名——对照同卷《隋宮》页挂「七绝」：**同卷 notes 两形态首见**；title 裸名——对照同卷隋宫页 title 内嵌异注：同卷 title 两形态首见；无评级页第三见；{{另}}/{{別}}/{{*}}/<ref> 全零；页内 Vtext/poem 双转录并存首末句各恰 2；全句**第二引**：正文 V018 卷539 卷页 claim 一引在先（生成时全库查重双针「瑤池阿母綺窗開」「穆王何事不重來」各恰一处），本迁移引 ws 诗页——两引两面（卷页+诗页）上限恰满不重叠；两度上限至此用满、此诗正文对后来迁移关闭（audit 硬卡）。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-026-city' AS id, 'bg-026-city' AS subject_id, 'context' AS property_key, '本篇锚「==[[瑤池]]==」**全《全唐詩》唯一**（机器断言：字面十条八卷中锚恰一）——对照 V067 同卷《隋宮》双锚恰二：**同卷单锚/双锚两种同名形态标本齐备**；卷内穆王/八駿/黃竹各恰一=诗面专名卷内自足（机器断言）；「西王母」恰二「阿母」恰五「綺窗」恰三在册零入引（闭域断言）；ws 分类三行简繁混排第三见（分类行非史料声明+不升格，V048 判例）；**再新建 source-ws-t300-026 恰一枚（连续第三首开新源——V066/V067 判例同构，卷页/诗页两个独立见证面；audit 断言恰一枚新源 INSERT）**。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-026-world' AS id, 'bg-026-world' AS subject_id, 'context' AS property_key, '通鉴「八駿/黃竹/阿母/綺窗/三萬里/動地哀/重來/西王母/仙術」全零（诗的仙界不在史部，机器断言）；「瑤池」恰三**全在 tj-199 且该页零年标题**（50% 页三连聚首见——不可作窗口断言，整句入引+locator 声明零标题；三处全是「瑤池都督府/瑤池都督」边州建制恰三断言——**仙池史部没有，同名是边州**）；「穆王」恰三分布三卷闭域双窗口入引=永淳元年（壬午，六八二）「故周穆王命伯冏為太僕正」奏疏引周王+廣德二年（甲辰，七六四）「臨淮武穆王李光弼」谥号+tj-255 零标题页常山忠穆王（又一谥号闭域不入引）——**三个穆王没一个是那个穆王**（同字两界第十三形态·仙界形态首见，audit 硬卡）；「長生」恰十三处七卷闭域双窗口入引=元和十三年（戊戌，八一八）「雲能合長生藥」（活着求长生）+大中十一年（丁丑，八五七）「長生可學乎/何處更求長生」（史部唯一正面回答）；「靈藥」恰一闭域在册零入引；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 零铸造零 relation（audit 硬卡）。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-026-person' AS id, 'bg-026-person' AS subject_id, 'context' AS property_key, '旧传李商隐段（简化字录入，引文照登简体原样）再首引二句皆生成时全库查重域恰零=「会昌二年，又以书判拔萃。」+「恃才诡激，为当涂者所薄。」（传区间归属机器断言）；「诗悯君之迷/传悯士之穷」系读法声明；「恃才诡激，为当涂者所薄」系史臣自断（照登 LIKELY）；段内瑤池/穆王/八駿/長生/仙字全零（机器断言，「仙」字段级零证首用）；V066「绹不之省/坎壈终身」域恰[V066]、V067「以所业文干之/下笔不能自休」域恰 [V067]、字义山/开成二年/岭表/三十六体（V016）零重开；本诗无底注（无注可登）；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-026-scene' AS subject_id, 'context' AS property_key, 'claim-bg-026-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-026-city' AS subject_id, 'context' AS property_key, 'claim-bg-026-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-026-world' AS subject_id, 'context' AS property_key, 'claim-bg-026-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-026-person' AS subject_id, 'context' AS property_key, 'claim-bg-026-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-026-scene' AS id, 'work-t300-026' AS work_id, 'SCENE' AS layer, '四句是一场没等来的重访：瑶池的西王母（阿母）绮窗大开（「瑤池阿母綺窗開」）——仙境的主人把窗打开，等着那位客人；穆王东归途中，黄竹之歌声声动地皆哀（「黃竹歌聲動地哀」——《穆天子传》里穆王见冻人作《黄竹》诗三章）；八骏日行三万里（「八駿日行三萬里」）——脚力何止万里；可穆王为什么再也不来了（「穆王何事不重來」）——窗一直开着，人不来了。ws 诗页 notes **只有 {{唐詩三百首}} 裸标记、不挂诗体名**——对照同卷《隋宮》ws 页 notes 挂「七绝」：**同卷 notes 两形态首见**（挂不挂体名非强制，选本标记自身也有形态谱）；title 行裸名「瑤池」——对照同卷《隋宮》页 title 内嵌异注：**同卷 title 两形态首见**；poem 块**全无句读**（第二见，V067 首见）；无 Textquality 评级**第三见**（V066 首见）；{{另}}/{{別}}/{{*}}/<ref> 全零；页内 Vtext/poem 双转录并存（首末句页内各恰 2）。此诗正文系**第二引**：V018 卷539 卷页一引在先，本迁移引 ws 选本页——**两引两面（卷页+诗页），上限恰满而不重叠**；生成时全库查重双针各恰一处，两度上限至此用满，此诗正文对后来迁移关闭。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-026-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-026-city' AS id, 'work-t300-026' AS work_id, 'CITY' AS layer, '卷539 侧：本篇锚「==[[瑤池]]==」**全《全唐詩》唯一**（机器断言：全库扫描锚恰一；字面「瑤池」十条八卷中只有此一处是诗题锚——他人诗句在册零入引）——对照 V067 同卷《隋宮》双锚：**同卷同作者，单锚诗题与双锚诗题并存**，「锚点恰一」「锚点恰二」两种同名形态在同一卷里标本齐备。卷内「穆王/八駿/黃竹」各恰一（机器断言）——**诗面三个专名在整卷里自足**：李商隱这卷诗里，穆天子只出场一次，且是「不重來」那一次。ws 诗页分类三行简繁混排第三见（整理者分类：非史料声明、不升格，V048 判例）。**本迁移再新建 1 个 source（source-ws-t300-026）——连续第三首开新源**（V066 賈生/V067 隋宮 判例同构：V018 以卷539 卷页立本诗（source-quantangshi-539，vol-raw），ws 选本页从未建源——卷页与诗页是两个独立见证面）。全唐詩「西王母」恰二（301/540 他人句在册零入引）、「阿母」恰五、「綺窗」恰三在册（机器断言闭域）。（本层零 relation。）' AS body_text, 'JUNIOR' AS audience, 'claim-bg-026-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-026-world' AS id, 'work-t300-026' AS work_id, 'WORLD' AS layer, '**诗问死者何不重来，史部的皇帝们活着问长生**（同字两界第十三形态·仙界形态首见）：通鉴「八駿/黃竹/阿母/綺窗/三萬里/動地哀/重來/西王母/仙術」全零（机器断言——诗的整个仙界不在史部）；「**瑤池**」恰三**全在 tj-199 一页且该页零年标题**（50% 页三连聚首见；窗口断言不可入围——闭域整句入引，locator 声明零标题）：三处全是安西边州建制「**置瑤池都督府，隸安西都護；戊子，以左衛將軍阿史那賀魯為瑤池都督。**」——**诗问的仙池史部没有，同名的是一份边州任命**；「**穆王**」恰三闭域双窗口逐字入引+一处零标题闭域：永淳元年（壬午，六八二）铨选议引「**故周穆王命伯冏為太僕正**」（谏书里的穆王是官制案例）、廣德二年（甲辰，七六四）「**臨淮武穆王李光弼**」（谥法之穆）、tj-255 零标题页常山忠穆王（又一谥号，闭域不入引）——**史部三个穆王没有一个是巡游瑶池的那个：一个是奏疏引的周王，两个是唐人谥号；诗问「穆王何事不重來」，史部连可以当面问的穆王都没有**；而史部反向接题——「**長生**」恰十三处七卷（太宗合药/则天胡超/玄宗符瑞/肃宗长生殿/宪宗柳泌/宣宗轩辕集分布闭域）双窗口入引：元和十三年（戊戌，八一八）宪宗纳山人柳泌「**雲能合長生藥**」（谏官争论而帝曰「煩一州之力而能為人主致長生」——群臣莫敢言）、大中十一年（丁丑，八五七）宣宗问轩辕集「**長生可學乎？**」对以「**王者屏欲而崇德，則自然受天遐福，何處更求長生？**」——**诗问死者为何不回来，史部活着皇帝前赴后继求解长生；史部唯一的正面回答是「何处更求长生」**；「靈藥」恰一处（開元中胡人求師子國靈藥——tj-211 闭域档扫在册零入引）。本层零铸造零 relation。' AS body_text, 'SENIOR' AS audience, 'claim-bg-026-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-026-person' AS id, 'work-t300-026' AS work_id, 'PERSON' AS layer, '旧传李商隐段（**简化字录入**，V016 locator 已注，引文照登简体原样）再首引二句（皆生成时全库查重域恰零）：「**会昌二年，又以书判拔萃。**」「**恃才诡激，为当涂者所薄。**」
**诗悯君之迷，传悯士之穷**（读法声明，非史实）：诗的瑶池里，君主迷上仙界一去不回头；传里的「当涂者」（掌权者）看这个人的眼神是「薄」——同是上位者的目光，一边望向神仙，一边鄙薄人才。书判拔萃是才调的第二道入场券（继弱冠干文之后），入场券一路发，「名宦不进」一路兑到底。
「恃才诡激，为当涂者所薄」系**史臣自断**（照登，certainty LIKELY——与 V066 已引「名宦不进，坎壈终身」同段同调，彼句零重开）；段内**瑤池/穆王/八駿/長生/仙 字全零**（机器断言，「仙」字段级零证首用——写尽瑶池八骏的人，传里没有一个仙字）；V066「绹不之省/名宦不进，坎壈终身」、V067「以所业文干之/下笔不能自休」、字义山/开成二年/岭表/三十六体（V016）在册句零重开（域断言）；本诗无底注（无注可登）；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 仍零铸造（audit 硬卡）。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-026-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-026-scene' AS claim_id, 'source-ws-t300-026' AS source_id, '页面 瑤池（《唐詩三百首》第 26 首选本页，页题裸名——同卷 title 两形态之一；title+author+notes+poem 块四句——poem **全无句读**（第二见）；notes 裸选本标记不挂体名（对照同卷隋宫页挂「七绝」——同卷 notes 两形态首见）；全句**第二引**：V018 卷539 卷页一引在先——两引面不重叠，上限恰满，生成时全库查重双针恰一处，此后此诗正文关闭；{{另}}/{{別}}/{{*}}/<ref> 全零；页内 Vtext/poem 双转录并存）' AS locator, '| title    = 瑤池……| author   = 李商隱……| notes    = {{唐詩三百首}}……瑤池阿母綺窗開
黃竹歌聲動地哀
八駿日行三萬里
穆王何事不重來
</poem>' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-026-city' AS claim_id, 'source-quantangshi-539' AS source_id, '卷五百三十九·李商隱《瑤池》块（锚「==[[瑤池]]==」**全《全唐詩》唯一**——字面十条八卷中锚恰一机器断言；对照同卷《隋宮》双锚恰二：同卷单锚/双锚两种同名形态标本齐备；卷内穆王/八駿/黃竹各恰一（诗面专名卷内自足）；源行系 V018 已立、本迁移复用零新建）' AS locator, '==[[瑤池]]==
<poem>
瑤池阿母綺窗開　黃竹歌聲動地哀
八駿日行三萬里　穆王何事不重來
</poem>' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-026-city' AS claim_id, 'source-ws-t300-026' AS source_id, '页面 瑤池（整页 notes 行（裸选本标记——同卷 notes 两形态首见）+分类三行连片（简体「唐诗」与繁体「唐詩三百首」同页混排第三见）；分类行系整理者/编排动作：非史料声明、不升格；**本迁移新建 source-ws-t300-026 恰一枚**（连续第三首开新源，V066/V067 判例同构）' AS locator, '| notes    = {{唐詩三百首}}……[[Category:李商隱]]
[[Category:唐诗]]
[[Category:唐詩三百首|李]]' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-026-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '卷一百九十九·安西瑶池都督府除授段（**通鉴瑤池恰三全在此页且该页零年标题50%页——三连聚首见，不作窗口断言，整句入引+此声明**；三处皆瑤池都督府/都督边州建制）……卷二百零三·永淳元年（壬午，六八二）铨选议引周穆王伯冏段……卷二百二十三·廣德二年（甲辰，七六四）臨淮武穆王李光弼段（穆王恰三分布三卷——第三个落零标题页闭域不入引：没一个是瑶池穆王）……卷二百四十·元和十三年（戊戌，八一八）柳泌長生药段……卷二百四十九·大中十一年（丁丑，八五七）宣宗问轩辕集段（**長生恰十三处七卷——活着求长生的皇帝们；唯一正面回答「何處更求長生」**；五段史文逐字入引为判决证据）' AS locator, '置瑤池都督府，隸安西都護；戊子，以左衛將軍阿史那賀魯為瑤池都督。……故周穆王命伯冏為太僕正……臨淮武穆王李光弼……薦山人柳泌，雲能合長生藥……上召入禁中，問曰：「長生可學乎？」對曰：「王者屏欲而崇德，則自然受天遐福，何處更求長生？」' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-026-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書卷一九〇下·李商隱（**简化字录入**照登原样，V016 locator 同款标注）（「会昌二年，又以书判拔萃」句+「恃才诡激，为当涂者所薄」句——皆全库查重恰零域首引；传区间归属机器断言；后者系史臣自断非自家语；「诗悯君之迷/传悯士之穷」系读法声明；段内瑤池/穆王/長生/仙字全零；V066/V067 已引诸句与字义山/岭表/三十六体在册句零重开）' AS locator, '会昌二年，又以书判拔萃。……恃才诡激，为当涂者所薄。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（四句七绝 1/1/1/1 第五次） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-026-scene' AS background_id, 'text-work-t300-026-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-026-city' AS background_id, 'text-work-t300-026-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-026-world' AS background_id, 'text-work-t300-026-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-026-person' AS background_id, 'text-work-t300-026-ws' AS version_id, 4 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 68, 'Li Shang-yin''s Jade Pool (work-t300-026) background layers (stage-D poem 49, four-line jueju 1/1/1/1 fifth time): dating verdict forty-three, thirty-first shape of the title-evidence series -- the Jade Pool and longevity, the immortal realm split in two realms: the poem asks why King Mu never came back, while the histories keep living emperors asking after immortality one after another; all staging words of the poem''s immortal realm (ba-jun the eight steeds, huang-zhu, a-mu, qi-chuang, san-wan-li, dong-di-ai, chong-lai, xi-wang-mu, xian-shu) score zero across the Tongjian (machine-asserted); yao-chi appears exactly three times, ALL on the zero-year-heading page tj-199 (first triple-gathering on a 50-percent page -- no window assertion possible, full-sentence quote with the zero-heading declaration in the locator) and all three are frontier administration -- the Yao-chi Commandery-Governorate under Anxi and the post granted to Ashina Helu (the poem''s immortal pool does not exist in the histories; the same name is a frontier appointment); mu-wang appears exactly three times across three files, two quoted with year-heading windows (Yongchun 1st, renwu, 682, a memorial citing "of old King Mu of Zhou appointed Bo Jiong as Grand Coachman" -- in the histories'' memorials King Mu is a staffing precedent; Guangde 2nd, jiachen, 764, "Li Guangbi, Prince Wu-mu of Linhuai" -- a posthumous name; the third on zero-heading page tj-255, closed-domain, not quoted): not one of the three Kings Mu is the king who toured the Jade Pool -- the histories have no King Mu left to ask; and the histories answer the poem from the other side: chang-sheng (longevity) appears thirteen times in seven scroll-volumes, two quoted with windows (Yuanhe 13th, wuxu, 818, Emperor Xianzong takes in the recluse Liu Bi "who claims to compound the medicine of longevity"; Dazhong 11th, dingchou, 857, Emperor Xuan asks Xuanyuan Ji "can longevity be learned?" and is answered: "if a king casts off desire and honors virtue, heaven''s long blessing comes by itself -- where would one further seek longevity?") -- the poem questions the dead about not returning, the living emperors queue up seeking never to die, and the histories'' only straight answer is "where would one further seek it"; ling-yao exactly once (closed-domain archive scan); the anchor ==[[瑤池]]== for this poem is UNIQUE in the entire Quan Tangshi (ten literal hits in eight volumes, one anchor -- contrast the double anchors of Sui Palace in the same juan per V067: single-anchor and double-anchor title shapes coexist as specimens in one volume); inside juan 539 the words mu-wang, ba-jun and huang-zhu each occur exactly once, all in this poem (the poem''s proper names are self-contained in the scroll); xi-wang-mu exactly 2 / a-mu exactly 5 / qi-chuang exactly 3 remain on the record unquoted; the ws anthology page carries a bare selection mark in notes without appending the form-name (contrast the Sui Palace page of the same juan which appends the colloquial form-name -- two notes shapes in one juan, first seen) plus a bare title line (two title shapes in one juan), a poem block with NO punctuation (second time), no Textquality grade (third time) and zero variant markers, Vtext/poem double transcription; exactly ONE new poetry_source row (source-ws-t300-026), the third consecutive new source (V066/V067 pattern: scroll page and anthology page are two independent witnesses); body quotes hit their two-use ceiling (sixteenth instance; twin needles; witnesses never overlap); PERSON first-cites two more zero-domain sentences from the simplified JTS biography -- in 842 he passed the special clerical exam, and "relying on talent he was wilful and sharp, and those in power thought little of him" (historian''s own verdict, logged): the poem mourns a ruler bewitched by immortality, the biography mourns a talent despised by power (reading declared); the biography segment holds no yao-chi/mu-wang/ba-jun/chang-sheng/xian/huang-zhu character (machine-asserted, first segment-level zero for the character xian itself); V066/V067 quoted sentences stay closed (domains asserted); KNOWN zero honestly recorded (twenty-fourth instance, audit reverse-asserts); closed precedent keywords stay out of citations'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 68);
COMMIT;
