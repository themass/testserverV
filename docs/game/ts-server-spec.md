# TS 服务端移植规格（table / matchmaking / hub / bot）

> 本文是移植过程中从 TS 源码逐行提取的行为契约（行号指向 `plane-duel/apps/server/src/` 与 `packages/shared/src/`）。
> 用途：service 层 Java 实现的对拍依据；实现与本契约不一致即为 bug，除非本文标注了"有意差异"。
> 引擎/协议层的移植已完成（engine 包 + protocol 包，166 条单测绿）。

## 0. 共享类型与常量

```
Capacity = 2|3|4；PresetId = beginner|standard|advanced|expert；BotDifficulty = PresetId
RuleSet = {boardSize:6..16, planeCount:1..maxPlanes, turnSeconds∈[10,15,20,30,45,60], hintAllowed:bool}
  maxPlanes(n) = min(6, floor(0.3·n²/9))；placeSeconds = 30+15·planeCount（秒）
PRESETS: beginner 8/1/30/true，standard 10/1/20/true，advanced 12/2/20/false，expert 14/3/15/false
TableKind = friend|match|practice；TablePhase = waiting|inGame
TicketId = free|standard|advanced；TICKETS: free 0/0, standard 50/80, advanced 100/160
BOT_ID_PREFIX = "bot:"——人类 playerId 禁止以此开头（auth 拒）
INITIAL_MMR=1200；MMR_BUCKET=120；MATCH_RELAX_MS=15000
```

Java 侧对应：`domain/Ruleset`、`domain/Coins.TICKETS`、`domain/Rank`（matchRelaxGate 已实现）、`domain/GameTypes` 桌子段（TableKind/TablePhase/SeatView/TableResult/TableView/RoomListEntry）。

### ServerMessage → wire evt 映射（已在 protocol 层落定）

ready→握手回执（**有意差异**：Java 侧身份走 `Vpn-Token` 握手鉴权，无服务端自签 token，故无 ready/BAD_TOKEN）；
tableState→`table.state`；state→`state`（全量快照 `{table, game}`）；queueStatus→`queue.status`；queueTimeout→`queue.timeout`；
roomList→`room.list`；kicked→`table.kicked`；roomClosed→`table.closed`；
引擎事件 phaseChanged/planeAccepted/shotResult/planeDestroyed/submitted/roundResult/playerOut/presence/gameOver →
`phase.changed`/`game.planeAccepted`/`game.shot`/`game.destroyed`/`game.submitted`/`game.roundResult`/`game.playerOut`/`player.presence`/`game.over`（编码在 `protocol/EngineEventCodec`）；
error→`error{code,message}`；profile→`profile.now`；rankChanged→`rank.changed`；rankList→`rank.list`；coins→`coins.ledger`（**有意差异**：展示统一走 coins.ledger，`coins.now` 留给广告奖励回执）。

### 错误码差异（Java 枚举 `GameErrorCode` 为准）

`BAD_TOKEN` 不引入；`NOT_ENOUGH_COINS`→`BALANCE_LOW`；`DAILY_TICKET_LIMIT`/`AD_LIMIT`→`QUOTA_EXCEEDED`；`UNKNOWN_TYPE`→`UNKNOWN_CMD`。其余同名。

## 1. 时钟

全部逻辑时间从参数注入（Java：`long now` 参数），Table/Matchmaking/Hub 内禁止读墙钟；只有传输层与 id 生成可用 `System.currentTimeMillis()`。

## 2. Table（table.ts）

常量：`FRIEND_SEAT_GRACE_MS=300_000`（仅当掉线者是桌内唯一人类）、否则等待座位宽限 `60_000`（table.ts:28-30,455-459）；tableId 16 hex。

状态：roomCode（6 位数字，Hub 生成）、kind、capacity、rules、rulesVersion（updateRules 成功 +1）、phase、closed、engine、hostId（仅 friend）、lastResult、gamesPlayed、lastGameId=`tableId:gamesPlayed`（幂等键）、lastMode、lastHumans（finish 瞬间快照，结算必须在 close 清座前消费）、banned（被踢者直到桌关不可再进）、botIds、preset（匹配桌）、listed（构造时强制 `listed && kind==friend`）、seats[capacity]（Seat: playerId,nickname,ready,connected,disconnectedAt,left,bot）。

方法契约（全部返回 Outbound[]，且**所有出参在桌边界过滤 `bot:` 前缀收件人**——bot 永不收信，table.ts:439）：

- `join(playerId,nickname,now)`：已坐且未离开 → 只回 state 快照。否则 admitError（closed→ROOM_NOT_FOUND；banned→BANNED；inGame→ROOM_IN_GAME；满→ROOM_FULL）→error。占最低空座（昵称 sanitize，失败兜底"玩家{index+1}"），ready=false。friend 且无 host → 成为 host。然后 afterSeat：match/practice 首局坐满 → **立即 startGame+broadcastStart**；否则 broadcastTable。
- `canJoin(playerId)`：practice 恒 ROOM_NOT_FOUND；否则 admitError。Hub 先校验再挪人。
- `addBot(difficulty,now)`：closed/非 waiting/满 → 空。id=`bot:{roomCode}:{seatIndex}:{++botSeq}`，昵称"电脑{index+1}"（不经 sanitize，服务端指派），ready/connected=true。afterSeat 同上。
- `leave(playerId,now)`：inGame→leaveInGame；waiting→release。
- `setReady(playerId,ready,rulesVersion,now)`：无座→NOT_IN_ROOM；非 waiting→WRONG_PHASE；`rulesVersion≠当前` → error STALE_RULES **+ 私有 tableState 重发**。置 ready；坐满且全 ready → startGame+broadcastStart，否则 broadcastTable。重复 ready 幂等且仍广播。
- `updateRules(playerId,rules,now)`：NOT_IN_ROOM→NOT_HOST（仅 friend host）→ROOM_IN_GAME。换 rules 副本，++rulesVersion，resetReady（bot 保持 ready），broadcastTable。
- `kick(hostId,targetId,now)`：次序错误依次 NOT_HOST/ROOM_IN_GAME；目标须存在、未离开、非自己、非 bot→TARGET_NOT_FOUND；目标已 ready→TARGET_READY。**顺序**：先给被踢者 `kicked{roomCode}`，再 release（只广播给留守）。banned.add。
- `setNickname(playerId,nickname)`：sanitize（旧昵称兜底），broadcastTable。
- `handleGame(playerId,cmd,now)`：无座→NOT_IN_ROOM；无 engine→WRONG_PHASE；`Leave`→leave()；否则转发 engine.handle 再追加 afterEngine。
- `tick(now)`：closed→空。无 engine → 仅 releaseExpired。有 engine → engine.tick+afterEngine，然后 pollBots（engine 存在且未 finished 时才轮询 bot）。
- `setConnected(playerId,connected,now)`：closed/无座/left/**bot**（bot 恒在线）→空。置连接态。有 engine：engine.setConnected+afterEngine；engine 已结束（afterEngine 置空）即返回；否则追加 broadcastTable。无 engine：broadcastTable。
- `view()`→TableView；`stateFor(playerId)`→单条 `{table, game}` 快照。
- `listing()`：仅 !closed && friend && listed && waiting && !full 才给 RoomListEntry（**不含 roomCode/playerId/ready**）。
- `setListed(playerId,listed)`：NOT_IN_ROOM→NOT_HOST→ROOM_IN_GAME→置值广播。

内部流不变式：
- broadcastTable = tableState 给**活跃**座位；broadcastStart = broadcastTable + 每人 state（唯一客户端提前拿到摆放 deadline 的地方）。
- `startGame(now)`：快照 rules 建 engine，resetReady，清 lastResult，快照 botIds，phase=inGame；对已掉线座位调 engine.setConnected(false) **丢弃输出**（随后 state 快照覆盖，评审 I1）。
- `release(seat)`（等待期离座，leave 与掉线超时共用）：清座 → 无人类 → close(false) 静默；kind==match && gamesPlayed>0 → close(true)（**匹配桌局后不留桌**，发 roomClosed）→ fixHost → broadcastTable。
- `releaseExpired(now)`：掉线座位超 seatGraceMs → release。
- `leaveInGame`：engine.handle(Leave)（duel 判负 / melee 出局），seat.left=true（保留到局末），fixHost，afterEngine；无人类 → out+close(false)；engine 仍在则追加 broadcastTable。
- `afterEngine(now)`（每次碰引擎后的收口钩子）：engine finished → lastResult=result∪botIds、lastGameId=`tableId:gamesPlayed`、lastMode、**lastHumans 此刻快照**（close/release 可能同轮清座）、engine=null、phase=waiting、gamesPlayed++。清 left 座位；仍掉线者 disconnectedAt=now（等待宽限从局末重新起算）。无人类 → close(false) 静默。**match 桌且有人离开时：先 broadcast tableState（带 lastResult）再 close(true)**（评审 C1，否则留守者看不到名次）。fixHost+broadcastTable。
- `fixHost()`：仅 friend；host 座位没了 → 最低活跃座位或 null。
- `close(notify)`：notify → 先给活跃座位 roomClosed；然后 closed=true，清 host/engine/bot/seats。

事件序列（必须保持）：ready 触发终局开局 → [tableState×N, state×N] 一批原子送达；kick：kicked→tableState(留守)；局末：引擎事件…gameOver→（Hub 侧结算插 profile/rankChanged/coinsChanged）→tableState(带 lastResult)→（match+有人离开时）roomClosed；friend 加入：广播给老成员 + 新人得 state。

## 3. Matchmaking（matchmaking.ts）

状态：`queues: key→{entries}`；`byPlayer: playerId→key`（一人至多一队）。Entry={playerId, since, notified, mmr}。
Key=`capacity:preset:ticket(缺省free)`；容量×预设×门票互相隔离。
`BOT_FILL_AFTER_MS={2:30000,3:30000,4:45000}`；`MIN_HUMANS=2`；enqueueWaitMs 默认 60000（仅关 bot 填充时用）。

- `join(playerId,key,now,mmr)`：同 key 重复 = no-op（门票不重扣，Hub 层保证）。异 key 先自动 leave 旧队。入队即达容量 → formGroup；成组：带走，组={key,playerIds,botSeats:0}，**只给剩余成员重发 status**（被配走的人不再收 queueStatus，tableState 由 Hub 给）。容量满但 gate 拒绝 → 继续等，重发 status（宁等不错配）。空队列删键。
- `leave(playerId,now)`：重发该队剩余成员 status（队空/不在队 → 空）。
- `tick(now)`：逐队按插入序：(1) `entries≥capacity` 时贪心 formGroup，成组带走并出组（botSeats=0）直到 gate 拒绝；(2) bot 填充开：仍 ≥capacity（被 gate 挡）→ continue，**不强行混合成组**；`<MIN_HUMANS` → 不动（绝不给单人类填 bot）；否则锚点=**第 2 人的 since**（后来者不重置倒计时），`now-anchor.since ≥ botFillMs(capacity)` → 全员成组 botSeats=capacity-人数；(3) bot 填充关：`!notified && now-since≥enqueueWaitMs` → 置 notified 发 `queueTimeout`。
- `formGroup(q,now,count)`：按队序贪心；候选与已选每人都要过 `matchRelaxGate(p.mmr,e.mmr, min(now-e.since, now-p.since))`；凑不满 count → null。
- `status(key,entries)`→每人 `queue.status{capacity,preset,waiting,botFillAt,humansNeeded=max(0,2-waiting),ticket?}`；`botFillAt=entries[1].since+botFillMs`（有填充且≥2人）否则 null——全队列共享倒计时。

Hub 交接协议（两处调用同此）：成组 → newTable('match', capacity, PRESETS[preset], listed=false, preset) → joinTable（按组序进人；bot 以 preset 作难度补空位）→ settleQueueIntoTable 门票记账。roomCode 只由 Hub 生成。

## 4. Hub（hub.ts）

状态表：tables roomCode→Table；tableByPlayer playerId→roomCode（**只存人类**）；membersByTable；nicknames；sessions；sessionByPlayer；room 列表订阅（sessionId→capacity、dirty 集、last 内容）；门票 ticketQueue（已付费在队）、ticketByTable（桌内记账，含 ids 名单）。ROOM_LIST_MAX=50、ROOM_LIST_MIN_INTERVAL_MS=1000、RANK_LIST_MAX=50。

生命周期：
- connect：注册未认证会话。**（有意差异：Java 在 WS 握手期用 Vpn-Token 解析出 userId，建连即已认证；无 auth 命令、无 ready/token 下发、无 BAD_TOKEN。同 playerId 新会话顶掉旧会话并显式 close 旧 socket——保留。）**
- 重连恢复（原 auth 尾段）：若仍挂在某桌，**无条件** setConnected(true) 并派发（半开连接，I2），再补私有 state 快照。断线 ≠ 移除座位——座位只被 tick 宽限计时器回收。
- disconnect(sessionId)：删会话（已被顶掉则忽略）；dropQueue（离队 + 退款）；table.setConnected(false) 派发。

命令路由（无桌也可用）：setNickname（sanitize+落档案，推 profile，再转桌）、profileRequest、rankListRequest（top50：tier↓stars↓wins↓，仅 scoringGames>0，**条目不含 playerId**）、coinRequest、adRewardRequest（日上限 5×30，id `ad:{day}:{n+1}`，超额 QUOTA_EXCEEDED(AD_LIMIT 语义)）、room.list（订阅式：立即快照 + 记录基线；进桌/进队即退订）、createRoom（先 leaveCurrent+退订订阅）、createPractice（self + capacity-1 bot，难度=preset）、joinRoom、joinListed、queueJoin、queueLeave、纯排队时的 leaveRoom。
其余全部要求有桌否则 NOT_IN_ROOM：room.rules、room.ready、room.listed、room.kick、room.leave、game.place/game.fire。
- joinRoom：已在目标桌 → join 快照；在别的桌且在对局中 → ALREADY_IN_ROOM；**先校验目标**（ROOM_NOT_FOUND/canJoin 码，BANNED 有专门文案）**再离开现桌**（RF#5：失败不能把人赶走）。
- joinListed：同上按 tableId；listing()==null 且原因非 inGame/full → 按 ROOM_NOT_FOUND（不可寻址）。
- queueJoin：同队重复 = 静默 no-op（不重扣费）；leaveCurrent(keepQueue)；先退已在队门票；付费票：日配额检查（20/日）→ 扣 `-fee`，id `ticket-fee:{playerId}:{now}:{++ticketSeq}`（**seq 必需**：同毫秒切换票档会撞键白嫖高级票并退款，评审 #1）；不足 → BALANCE_LOW；然后 ticketQueue.set。mmr 从档案取。门票字段只在客户端传了才进 key（v4 兼容）。成组 → 建匹配桌 → joinTable → settleQueueIntoTable。

门票/退款状态机：
- 已付费在队 → ticketQueue。离队（显式/断线/换队/换桌）→ **全额退**，id `ticket-refund:{playerId}:{now}:{seq}`，**不受日净增上限**；applied==0 不推送。
- 成组含 bot → 组内人类全退（**bot 局永不收/发门票**）。
- 全人类成组 → 删 ticketQueue、countTicketPlay（日配额消费）、ticketByTable.set。首次 gameOver 结算：rank==1 得 `+reward`，id `ticket-win:{gameId}:{playerId}`；败者只损失门票费。**仅首局**，重开是免费普通局。
- 首局未打完桌就关 → sync 时按 ticketByTable.ids 全退。shutdown 全退（map 删除保证幂等）。

桌子管道：
- newTable：roomCode=6 位数字唯一（重试 100 次）。
- joinTable(table,ids,botSeats,difficulty)：按序进人；**归因注册以进桌后 members 里有它为准**；逐个派发；再 addBot×botSeats。
- `dispatchTable(table, out)`——投递闸门，顺序固定：(1) 收件人**当前归因于本桌**才投递；例外：桌已 closed 且收件人无归因（roomClosed/kicked 的"告别例外"），防串桌旧消息打错人（I4）；(2) 有 gameOver → 先投递后 `scoreTable`（留守者还在归因内），**先于 sync**；(3) sync(table)；(4) friend 桌 → 该容量列表标脏。
- sync(table)：membersByTable vs humanMembers 差集 → 丢归因；closed → 删成员集+删桌+退门票。
- `scoreTable`：friend 桌**完全不记账**；需 lastGame 非空；humans=**快照**（中途离开者不计分不记录）；withBots=practice||有 bot → 记录统计但**星级 delta 强制 0、不发 rankChanged**；opponentMmr=其他人类均值（四舍五入，独狼=自己）；`record(id=tableId:gamesPlayed)` 幂等（重放返回原 delta，不双发星）；每人类 `+5` id `game:{gameId}:{playerId}`（bot 局也发，日上限 20/净增 500 在 applyCoin 内）；**推送顺序**：先全簿记后全推送，每人 profile（须已含最终余额）→ rankChanged（仅计分段）→ coinsChanged[]。
- leaveCurrent({keepQueue})：对局中→拒绝；否则离桌+离队（+退款）。

限流：TS Hub 无每消息限流（仅 4KB 帧上限+解析校验）；Java 多实例端口在传输层加令牌桶（design.md：20/s），Hub 语义不依赖。

tick 循环（顺序有意义，200ms 驱动）：now=clock → resetSeasons（跨季：profile 重置→在线者推 profile+rankChanged(delta0,'season-reset')；发币 `(tier+1)×50` id `season-grant:{season}` 幂等）→ **逐桌快照遍历** dispatchTable(table.tick) → matchmaking.tick（成组同 queueJoin 交接）→ pushRoomLists。心跳走 WS ping 15s（Java：Tomcat 容器侧配置），无应用层心跳命令；presence 是游戏态广播不是活性信号。

room 列表推送：roomSnapshot(capacity)=该容量所有 listing() 非空桌，seated↓ 再 createdAt↓，截 50；pushRoomLists：dirty 容量距上次推送 <1s 跳过（保持脏下次重试）；重建内容，**与上次 JSON 不同才推**，只推给该容量订阅者。订阅立即发快照并记基线；进桌/进队退订；断线删订阅。

## 5. Bot（bot/driver.ts, bot/brain.ts）

仅由 Table.pollBots 驱动：`bot.poll(engine.view(botId), rules, now)` → 可选动作回喂 engine.handle。思考时长 1200–3500ms 随机，钳到 `deadlineAt−1000ms`。决策键：placing（未摆）→'place'；duel 轮到自己→`turn:{shotsSoFar}`；melee 本轮未提交→`round:{round}`。每个键只动作一次（doneKey）。
难度误着率 {beginner .4, standard .25, advanced .1, expert 0}；候选打分含机身格 PART_WEIGHT .3 的贝叶斯式启发；**rng 调用次序固定**（先误着骰，再可选均匀挑，再并列挑）——保确定性测试可移植。Java：实现 `service/GameBot` 接口（已定义）。

## 6. 不变式清单（移植后逐条自查）

1. 门票退款矩阵：退 ⟺ 局从未真正开成。退：离队任意路径、换队、bot 填充组、首局未成桌关、优雅停机。开成人局并到首次 gameOver → 不退；胜者固定奖励、败者门票归公；重开局免费无奖。退款免净增上限；全部金币操作按 id 幂等；fee/refund id 带单调 seq。bot 局不收票不发奖，但**发** +5 完成币。
2. 任何含 bot 局星/MMR 全不动（scoring=0）；friend 桌对档案完全隐身；幂等键 `tableId:gamesPlayed`。
3. 三种互不相同的掉线宽限：等待座位（唯一人类 300s，否则 60s；局末重新起算）；duel 局内 30s 判负（期间 paused，恢复顺延 deadline）；melee 局内 30s 出局（不暂停；宽限钟从第 1 轮起）。断线永不直接释放座位，只由 tick 宽限回收。
4. 广播次序：kicked 先于 release；gameOver→结算推送→sync→tableState(带 lastResult)→（match+离开者）roomClosed；broadcastStart = tableStates 再 states；推送前全簿记完成、profile 先于其派生 coinsChanged；queueStatus 重发不含已配对者；告别投递例外仅在 closed 桌。
5. 一人同时至多一桌或一队；对局中拒绝挪动且不赶人。
6. 身份：（Java 有意差异——握手鉴权）新会话顶旧会话显式 close；重连无条件补 state；握手期昵称覆盖离线改名（TS auth-nickname 语义，映射到握手属性）。
7. bot 消息在桌边界丢弃；bot id 不入归因表；人类 id 禁止 `bot:` 前缀。
8. 列表隐私：RoomListEntry 不含 roomCode/playerId/ready；仅 friend+listed+waiting+非满可列。
9. 对手机头坐标永不下发（引擎视图已保证；桌子/Hub 不得另开数据通路）。
10. 确定性：逻辑内无墙钟无全局随机；随机源/时间注入。
11. 坏输入保活：解析失败回 error 断连不断（keep-alive）；game.item → UNSUPPORTED；4KB 帧上限。
12. tick 单线程假设：桌子不得与玩家消息处理并发被 tick。多实例 Redis 端：per-table 取 `game:lock:table:{id}` 串行化；dispatchTable"归因→投递→结算→sync"保持每桌原子。
13. 优雅停机顺序：先全退门票 → 关连接（1s 硬切）→ **最后**刷档案存储（在途断线派生的结算必须先落盘）。

## 7. 有意差异总表（Java 版 vs TS）

| 项 | TS | Java | 理由 |
|---|---|---|---|
| 身份 | auth 命令 + 自签 token + ready | WS 握手 `Vpn-Token` → userId，建连即认证 | 用户决策：账号必须用平台 userId，复用鉴权链路 |
| 协议 | type 字段混命令事件、碎片桌子事件 | cmd/evt 词表 + seq/ref + table.state 全量快照 | 用户决策：Java 化协议重设计 |
| 错误码 | BAD_TOKEN 等 | 见 §0 差异映射 | 同上 |
| 状态存放 | 进程内存 | 桌子/队列/在线态进 Redis（game: 前缀）+ MySQL 落账 | 多实例 + 留存要求 |
