-- V019 精确回滚：恢复到 V019 执行前的状态（V004 原文/占位引证/V011 引证原样/DISPUTED）。
-- 逐条 UPDATE 都带当前值守卫：只在 V019 的效果确实存在时回滚，幂等。
START TRANSACTION;
UPDATE poetry_background SET body_text = '城还在，山和河也还在，可它已经不是从前的样子。春天照常来了，草木疯长，长满了没人打理的街巷。（草稿：以景物反衬，措辞待复核）'
 WHERE id = 'bg-chun-wang-scene' AND body_text <> '城还在，山和河也还在，可它已经不是从前的样子。春天照常来了，草木疯长，长满了没人打理的街巷。（草稿：以景物反衬，措辞待复核）';
UPDATE poetry_background SET body_text = '长安是帝国的心脏。都城被占之后，宫阙、街市、官署还在，但秩序已经不在了。（草稿：城市作为处境，需核对城况史源）'
 WHERE id = 'bg-chun-wang-city' AND body_text <> '长安是帝国的心脏。都城被占之后，宫阙、街市、官署还在，但秩序已经不在了。（草稿：城市作为处境，需核对城况史源）';
UPDATE poetry_background SET body_text = '这场战事从755年打到763年（通行纪年，待核），前后多年，音信断绝是常态。"家书抵万金"不是夸张的说法，是当时的实际处境。（草稿）'
 WHERE id = 'bg-chun-wang-world' AND body_text <> '这场战事从755年打到763年（通行纪年，待核），前后多年，音信断绝是常态。"家书抵万金"不是夸张的说法，是当时的实际处境。（草稿）';
UPDATE poetry_background SET body_text = '写这首诗时杜甫正困在长安一带，官职低微、家人离散。（草稿：具体年份与官职待年谱核对，不假设确定故事）'
 WHERE id = 'bg-chun-wang-person' AND body_text <> '写这首诗时杜甫正困在长安一带，官职低微、家人离散。（草稿：具体年份与官职待年谱核对，不假设确定故事）';
UPDATE poetry_claim SET value_text = '以"城在而山河在"反衬物是人非。'
 WHERE id = 'claim-bg-scene' AND value_text <> '以"城在而山河在"反衬物是人非。';
UPDATE poetry_claim SET value_text = '长期战事与音信断绝构成天下层。'
 WHERE id = 'claim-bg-world' AND value_text <> '长期战事与音信断绝构成天下层。';
UPDATE poetry_citation
   SET source_id = 'source-dufu-nianpu-candidate', locator = '待人工核对：解诗依据（注本/研究）', evidence_excerpt = NULL
 WHERE claim_id = 'claim-bg-scene' AND source_id <> 'source-dufu-nianpu-candidate';
UPDATE poetry_citation
   SET source_id = 'source-anshi-candidate', locator = '待人工核对：城况记载卷次', evidence_excerpt = NULL
 WHERE claim_id = 'claim-bg-city' AND source_id <> 'source-anshi-candidate';
UPDATE poetry_citation
   SET source_id = 'source-anshi-candidate', locator = '待人工核对：战事时长与交通阻断记载', evidence_excerpt = NULL
 WHERE claim_id = 'claim-bg-world' AND source_id <> 'source-anshi-candidate';
DELETE FROM poetry_citation WHERE claim_id = 'claim-bg-world' AND source_id = 'source-dushi-xiangzhu';
DELETE FROM poetry_citation WHERE claim_id = 'claim-bg-person' AND source_id = 'source-dushi-xiangzhu';
UPDATE poetry_citation
   SET locator = '卷二百一·文藝上·杜甫传',
       evidence_excerpt = '時所在寇奪，甫家寓鄜，彌年艱窶，孺弱至餓死；肅宗立，自鄜州羸服欲奔行在，為賊所得'
 WHERE claim_id = 'claim-bg-person' AND source_id = 'source-dufu-zhuan-candidate'
   AND evidence_excerpt LIKE '%……%';
UPDATE poetry_citation
   SET locator = '卷一百九十下·杜甫传',
       evidence_excerpt = '十五載，禄山䧟京師，肅宗徴兵靈武，甫自京師宵遁赴河西謁肅宗，於彭原郡拜右拾遺'
 WHERE claim_id = 'claim-bg-person' AND source_id = 'source-jiutangshu-dufu'
   AND evidence_excerpt LIKE '%……%';
UPDATE poetry_claim SET certainty = 'DISPUTED'
 WHERE id = 'claim-bg-city' AND certainty = 'LIKELY';
UPDATE poetry_claim SET certainty = 'DISPUTED'
 WHERE id = 'claim-bg-world' AND certainty = 'LIKELY';
UPDATE poetry_claim SET certainty = 'DISPUTED'
 WHERE id = 'claim-bg-person' AND certainty = 'LIKELY';
DELETE FROM poetry_schema_version WHERE version_no = 19;
COMMIT;
