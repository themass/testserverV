-- V012 的回滚：把读者可见文字还原为 V004 的原文。每条都要求当前文字等于 V012 写入的新文字，否则什么也不做。
-- 不删除 version_no=12 的账本行——留着才能看出曾经执行过 V012。

UPDATE poetry_background SET body_text = '城还在，山和河也还在，可它已经不是从前的样子。春天照常来了，草木疯长，长满了没人打理的街巷。（草稿：以景物反衬，措辞待复核）'
 WHERE id = 'bg-chun-wang-scene' AND body_text = '山河还在，城里的草木在春天长得很深。'
   AND NOT EXISTS (SELECT 1 FROM poetry_content c WHERE c.id = poetry_background.id AND c.status = 'PUBLISHED');

UPDATE poetry_background SET body_text = '长安是帝国的心脏。都城被占之后，宫阙、街市、官署还在，但秩序已经不在了。（草稿：城市作为处境，需核对城况史源）'
 WHERE id = 'bg-chun-wang-city' AND body_text = '叛军攻下长安之后，杜甫被困在这座城里。'
   AND NOT EXISTS (SELECT 1 FROM poetry_content c WHERE c.id = poetry_background.id AND c.status = 'PUBLISHED');

UPDATE poetry_background SET body_text = '这场战事从755年打到763年（通行纪年，待核），前后多年，音信断绝是常态。"家书抵万金"不是夸张的说法，是当时的实际处境。（草稿）'
 WHERE id = 'bg-chun-wang-world' AND body_text = '诗里说“烽火连三月，家书抵万金”：战火不停，一封家信比万金还难得。'
   AND NOT EXISTS (SELECT 1 FROM poetry_content c WHERE c.id = poetry_background.id AND c.status = 'PUBLISHED');

UPDATE poetry_background SET body_text = '写这首诗时杜甫正困在长安一带，官职低微、家人离散。（草稿：具体年份与官职待年谱核对，不假设确定故事）'
 WHERE id = 'bg-chun-wang-person' AND body_text = '他被困在长安，家人留在鄜州。'
   AND NOT EXISTS (SELECT 1 FROM poetry_content c WHERE c.id = poetry_background.id AND c.status = 'PUBLISHED');

UPDATE poetry_annotation SET content = '山河：指长安一带的山川。（措辞待与权威注本核对）'
 WHERE id = 'ann-chun-wang-shanhe' AND content = '山河：山和河，指大地山川。'
   AND claim_id IN (SELECT id FROM poetry_claim WHERE status <> 'PUBLISHED');

UPDATE poetry_annotation SET content = '烽火：战火，这里指持续未平的战事。（措辞待核）'
 WHERE id = 'ann-chun-wang-fenghuo' AND content = '烽火：战火，这里指战事。'
   AND claim_id IN (SELECT id FROM poetry_claim WHERE status <> 'PUBLISHED');

UPDATE poetry_claim SET value_text = '山河：指长安一带的山川。'
 WHERE id = 'claim-ann-shanhe' AND value_text = '山河：山和河，指大地山川。' AND status <> 'PUBLISHED';

UPDATE poetry_claim SET value_text = '烽火：战火，借指持续的战事。'
 WHERE id = 'claim-ann-fenghuo' AND value_text = '烽火：战火，借指战事。' AND status <> 'PUBLISHED';

UPDATE poetry_content SET title = '这个天下：打了三年的战事'
 WHERE id = 'bg-chun-wang-world' AND title = '这个天下：战火不停' AND status <> 'PUBLISHED';

UPDATE poetry_content SET title = '这个人：四十六岁的杜甫'
 WHERE id = 'bg-chun-wang-person' AND title = '这个人：被困在长安的杜甫' AND status <> 'PUBLISHED';
