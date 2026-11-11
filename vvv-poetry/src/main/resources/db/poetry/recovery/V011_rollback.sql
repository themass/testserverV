-- V011 的回滚。先回滚应用代码（如依赖 V011 的数据），再执行本文件。尽力还原，不保证回到执行前一刻。
-- 不删除 version_no=11 的账本行——留着才能看出「曾经执行过 V011」。
--
-- 执行前先看（若新来源已被核验或被发布内容引用，回滚会破坏引用，请先人工处理）：
--   SELECT id, verification_status FROM poetry_source WHERE id = 'source-quantangshi-224';

-- 1) 纪年标签还原
UPDATE poetry_claim
   SET value_text = '758..758 (EXACT) 说二：至德元载说，另有年谱系于此年'
 WHERE id = 'claim-chun-wang-time-758';

-- 2) 引用还原为「待人工核对」
UPDATE poetry_citation
   SET locator = '待人工核对：本传相关原文', evidence_excerpt = NULL
 WHERE claim_id = 'claim-bg-person' AND source_id = 'source-dufu-zhuan-candidate';

DELETE FROM poetry_citation
 WHERE source_id = 'source-jiutangshu-dufu'
   AND claim_id IN ('claim-bg-person', 'claim-bg-city', 'claim-chang-an-capture-time');

UPDATE poetry_citation
   SET source_id = 'source-chun-wang-candidate', locator = '待人工核对标题与作者署名', evidence_excerpt = NULL
 WHERE claim_id = 'claim-chun-wang-author' AND source_id = 'source-quantangshi-224';

-- 3) 来源版本与网址还原
UPDATE poetry_source SET edition = '版本待定', url = NULL
 WHERE id = 'source-dufu-zhuan-candidate' AND verification_status = 'PENDING';
UPDATE poetry_source SET edition = NULL, url = NULL
 WHERE id = 'source-jiutangshu-dufu' AND verification_status = 'PENDING';

-- 4) 文本版本指回原候选来源，再删除新来源（仅当没有任何引用/版本还在用它）
UPDATE poetry_text_version
   SET source_id = 'source-chun-wang-candidate', source_locator = '全诗；待逐字核对',
       label = '简体录入草稿（非教材核定版）'
 WHERE id = 'text-chun-wang-draft' AND status = 'DRAFT';

DELETE FROM poetry_source
 WHERE id = 'source-quantangshi-224' AND verification_status = 'PENDING'
   AND NOT EXISTS (SELECT 1 FROM poetry_citation c WHERE c.source_id = 'source-quantangshi-224')
   AND NOT EXISTS (SELECT 1 FROM poetry_text_version v WHERE v.source_id = 'source-quantangshi-224');
