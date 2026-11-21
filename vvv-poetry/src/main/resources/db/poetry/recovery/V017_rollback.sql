-- V017 回滚：撤销本迁移写入的挂接断言/出处/关系，并把三处占位出处与一处 certainty 还原。
-- 不删除 version_no=17 账本行；不碰 poetry_review_log（本迁移没写它，那张表也只可追加）。
-- V004/V011/V013/V015/V016 的行一律不删：claim-chun-wang-time-757、claim-exp-757-time、
-- claim-chang-an-capture-time 及其引用属 V004/V011，回滚只把值条件命中的一处还原成迁移前的那个值。
-- 来源行仅在仍无引用且仍为 PENDING 时删除。
START TRANSACTION;

-- 挂接：关系、引用、选择、断言（都是本迁移新增的行）
DELETE FROM poetry_relation WHERE id IN ('rel-work-chun-wang-written-during-anshi');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-chun-wang-in-anshi');
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-chun-wang-in-anshi');
DELETE FROM poetry_claim WHERE id IN ('claim-chun-wang-in-anshi');

-- 本迁移新增的引用（按 (claim_id, source_id) 主键精确删）
DELETE FROM poetry_citation WHERE (claim_id, source_id) IN (('claim-exp-757-time', 'source-dufu-zhuan-candidate'));

-- certainty 还原（只在本迁移升级过的值上生效）
UPDATE poetry_claim SET certainty = 'LIKELY'
 WHERE id = 'claim-chang-an-capture-time' AND certainty = 'KNOWN' AND status <> 'PUBLISHED';

-- 占位出处还原：只有仍指向本迁移写入的来源与定位时才还原（中间被人工改过就不动）
UPDATE poetry_citation
   SET source_id = 'source-dufu-nianpu-candidate',
       locator = '待人工核对：系年于至德二载的年谱与页码',
       evidence_excerpt = NULL
 WHERE claim_id = 'claim-chun-wang-time-757' AND source_id = 'source-dushi-xiangzhu'
   AND locator = '卷四·春望·鶴注（至德二載=757，由年表換算；同一條注內顧宸異議與「當從鶴説為正」並存，單源注本，故係年仍 DISPUTED）';
UPDATE poetry_citation
   SET source_id = 'source-dufu-nianpu-candidate',
       locator = '待人工核对：年谱系年',
       evidence_excerpt = NULL
 WHERE claim_id = 'claim-exp-757-time' AND source_id = 'source-dushi-xiangzhu'
   AND locator = '卷四·春望·鶴注（「陷賊營時所作」：人在賊佔長安的注本依據；至德二載=757，由年表換算）';
UPDATE poetry_citation
   SET source_id = 'source-anshi-candidate',
       locator = '待人工核对：通鉴纪事年月',
       evidence_excerpt = NULL
 WHERE claim_id = 'claim-chang-an-capture-time' AND source_id = 'source-zizhi-tongjian-events'
   AND locator = '通鑑卷二百十八·唐紀三十四（卷首注「起柔兆涒灘五月，至九月」；卷內唯一帶公元的年標題）；起點年標題與入長安句以「……」相連';

-- 通鉴来源标题还原
UPDATE poetry_source SET title = '《資治通鑑》唐紀（大事件用：卷222、254）'
 WHERE id = 'source-zizhi-tongjian-events' AND title = '《資治通鑑》唐紀（大事件用：卷218、222、254）' AND verification_status = 'PENDING';

DELETE FROM poetry_source WHERE id IN ('source-dushi-xiangzhu')
  AND verification_status = 'PENDING'
  AND NOT EXISTS (SELECT 1 FROM poetry_citation c WHERE c.source_id = poetry_source.id);
COMMIT;

