package com.timeline.game.service;

import com.timeline.game.domain.Coins;
import com.timeline.game.domain.GameTypes;
import com.timeline.game.domain.Rank;
import com.timeline.game.persistence.GameMatchMapper;
import com.timeline.game.persistence.GameMatchPlayerMapper;
import com.timeline.game.persistence.GameProfileMapper;
import com.timeline.game.persistence.GameProgressMapper;
import com.timeline.game.persistence.GameShotMapper;

import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;

/**
 * 一局结算的落库实现（ts-server-spec.md §4 scoreTable 契约 + data-model.md 结算抢占）。
 *
 * 幂等的两层结构：
 * 1. 局级抢占：{@link GameMatchMapper#claimSettlement}（finished 0→1 CAS）决定"谁结"，
 *    抢不到直接 claimed=false——重放安全，星/币/MMR 永不双发（spec §6.2）；
 * 2. 币级幂等：每笔发币再走 {@link GameWalletService#grant} 的 entry_key 唯一键
 *    （game:{gameId}:{userId} / ticket-win:{gameId}:{userId}），崩溃重放半途也不重发。
 *
 * 开局先记账（recordStart）：match 行 + 座位"骨架行"（final_rank NULL）。审计靠
 * finished=0 且有骨架行的局识别崩溃未收尾的局（crash-sweep c 项），所以 recordStart
 * 必须与开局的其余动作同事务。
 *
 * playerId ↔ userId：握手鉴权后身份就是平台 userId（spec §0 有意差异），引擎结果里的
 * playerId 字符串就是它的十进制串——按 String.valueOf 对齐，不引入第二套身份表。
 *
 * 事务约定：一次 settle 的全部写入必须由调用方（Hub 的 dispatchTable 落点）包在同一
 * 事务里（外层还有 per-table 锁串行化，spec §6.12）。本类不读墙钟（spec §1），
 * 时刻全部来自 GameContext.nowMs。
 */
public final class GameSettlementService {

    private final GameMatchMapper matchMapper;
    private final GameMatchPlayerMapper matchPlayerMapper;
    private final GameProgressMapper progressMapper;
    private final GameProfileMapper profileMapper;
    private final GameWalletService walletService;
    /** game_shot 落库（可空 = 不记逐发明细：纯内存装配/单测）；写入在 settle 抢占之后、同事务。 */
    private final GameShotMapper shotMapper;
    private final ZoneId zone;

    public GameSettlementService(GameMatchMapper matchMapper,
                                 GameMatchPlayerMapper matchPlayerMapper,
                                 GameProgressMapper progressMapper,
                                 GameProfileMapper profileMapper,
                                 GameWalletService walletService,
                                 GameShotMapper shotMapper,
                                 ZoneId zone) {
        this.matchMapper = matchMapper;
        this.matchPlayerMapper = matchPlayerMapper;
        this.progressMapper = progressMapper;
        this.profileMapper = profileMapper;
        this.walletService = walletService;
        this.shotMapper = shotMapper;
        this.zone = zone;
    }

    /**
     * 结算上下文（Hub 在 gameOver 派发后构造，全部来自桌子状态，不经 DB 再读）：
     * humans = lastHumans 快照——中途离开者已被调用方剔除，不给星不记账（spec §4）；
     * withBots = kind==PRACTICE 或桌内有 bot；ticket 仅"全人类匹配桌首局"才非空
     * （bot 局永不收/发门票，spec §4 门票状态机）。
     */
    public record GameContext(String gameId, GameTypes.TableKind kind, String mode, String preset,
                              int capacity, Coins.TicketId ticket, List<Long> humans,
                              GameTypes.GameResult result, boolean withBots, long nowMs) {}

    /** 单个真人的结算摘要（Hub 推送 profile/rankChanged/coinsChanged 的数据源）。 */
    public record PlayerDelta(long userId, int deltaStar, int coinApplied, boolean coinCapped) {}

    /** 逐发炮弹（game_shot 一行的原料）：电脑发炮 byUser=null；result 用 wire 小写词 miss/body/head。 */
    public record ShotRecord(Long byUser, Long targetUser, int row, int col,
                             String result, String planeId, long atMs) {}

    public record SettleOutcome(boolean claimed, List<PlayerDelta> deltas) {}

    // ---------------------------------------------------------------- 开局记账

    /**
     * 开局落账（同事务调用）：game_match 一行（finished=0）+ 每座位一行骨架行。
     * humanUserIds 按下标即 seat，null 槽位 = 电脑座位（user_id NULL、bot=1）——
     * 骨架行先占住 (match_id, seat)，结算时原位回写，crash-sweep 因此能认出"开了没结"的局。
     */
    public void recordStart(String gameId, int seasonNo, String mode, String preset, int capacity,
                            String ticket, int boardSize, int planeCount, long startedAtMs,
                            List<Long> humanUserIds) {
        int humans = 0;
        for (Long uid : humanUserIds) if (uid != null) humans++;
        matchMapper.insert(gameId, seasonNo, mode, preset == null ? "standard" : preset,
            capacity, ticket == null ? "free" : ticket, boardSize, planeCount, startedAtMs, humans);
        for (int seat = 0; seat < humanUserIds.size(); seat++) {
            Long userId = humanUserIds.get(seat);
            matchPlayerMapper.insert(gameId, seat, userId, userId == null ? 1 : 0,
                null, null, 0, 0, 0, null, null, 0);
        }
    }

    // ---------------------------------------------------------------- 结算

    /**
     * scoreTable 落库版（spec §4）：friend 桌完全不记账 → claim 抢占 → 逐发炮弹落
     * game_shot（与抢占同事务；INSERT IGNORE 挡重放）→ 逐真人
     * 段位/MMR（仅计分段）→ 战绩 → +5 完成币（人人有，bot 局也发）→ 门票胜奖 →
     * 座位行回写 → markClosed。claimed=false 时什么都没发生（重放路径）。
     */
    public SettleOutcome settle(GameContext ctx) { return settle(ctx, List.of()); }

    /** shots = Hub 本局缓冲的逐发明细（回放/反作弊，V002）；空表或 shotMapper 装配为 null 则不记。 */
    public SettleOutcome settle(GameContext ctx, List<ShotRecord> shots) {
        // friend 桌对档案完全隐身（spec §6.2）：调用方本来就不会给它记 match 行，这里是防御性双保险。
        if (ctx.kind() == GameTypes.TableKind.FRIEND) return new SettleOutcome(false, List.of());
        if (matchMapper.claimSettlement(ctx.gameId()) == 0) return new SettleOutcome(false, List.of());

        // 逐发明细（回放/反作弊）：抢占成功后、同事务落库；(match_id, seq) 全局发炮序。
        if (shotMapper != null) {
            int seq = 0;
            for (ShotRecord s : shots) {
                shotMapper.insert(ctx.gameId(), seq++, s.byUser(), s.targetUser(),
                    s.row(), s.col(), s.result(), s.planeId(), s.atMs());
            }
        }

        GameMatchMapper.MatchRow match = matchMapper.match(ctx.gameId());
        List<Long> humans = ctx.humans();

        // 档案兜底建档 + 刷活跃（结算即活跃证据；TS get() 顺手 touch 的等价物）。
        List<GameProgressMapper.ProgressRow> rows = new ArrayList<>(humans.size());
        for (long uid : humans) {
            profileMapper.touchSeen(uid);
            GameProgressMapper.ProgressRow p = progressMapper.progress(uid);
            if (p == null) {
                progressMapper.insertInitial(uid, match.seasonNo());
                p = progressMapper.progress(uid);
            }
            rows.add(p);
        }

        // 对手机头分：其他真人 MMR 均值，四舍五入；独狼参照自己 → Elo 增量天然 0 偏（spec §4）。
        int[] opponentMmr = new int[humans.size()];
        for (int i = 0; i < humans.size(); i++) {
            int sum = 0, n = 0;
            for (int j = 0; j < humans.size(); j++) {
                if (j != i) { sum += rows.get(j).mmr(); n++; }
            }
            opponentMmr[i] = n == 0 ? rows.get(i).mmr() : (int) Math.round(sum / (double) n);
        }

        List<PlayerDelta> deltas = new ArrayList<>(humans.size());
        for (int i = 0; i < humans.size(); i++) {
            long uid = humans.get(i);
            GameProgressMapper.ProgressRow p = rows.get(i);
            // 结果缺失的兜底：名次记最差、0 命中（防御性——lastHumans 与 ranking 正常必对齐）。
            GameTypes.RankEntry entry = entryOf(ctx.result(), uid);
            int rank = entry == null ? Integer.MAX_VALUE : entry.rank();
            Integer eliminatedRound = entry == null ? null : entry.eliminatedRound();
            int hits = entry == null ? 0 : entry.hits();
            boolean win = rank == 1;

            int deltaStar;
            int mmrAfter;
            boolean scoring = !ctx.withBots();
            if (scoring) {
                Rank.RankApply apply = Rank.applyOutcome(
                    new Rank.RankState(p.tier(), p.stars(), p.mmr(), p.lossStreak()),
                    win ? Rank.Outcome.WIN : Rank.Outcome.LOSS, opponentMmr[i]);
                deltaStar = apply.delta();
                mmrAfter = apply.state().mmr();
                int bestTier = p.bestTier(), bestStars = p.bestStars();
                // 历史最高按"先段后星"取新值（TS record() 同款比较式）。
                if (apply.state().tier() > bestTier
                    || (apply.state().tier() == bestTier && apply.state().stars() > bestStars)) {
                    bestTier = apply.state().tier();
                    bestStars = apply.state().stars();
                }
                progressMapper.updateProgress(uid,
                    apply.state().tier(), apply.state().stars(), mmrAfter, apply.state().lossStreak(),
                    p.wins() + (win ? 1 : 0), p.losses() + (win ? 0 : 1), p.totalHits() + hits,
                    bestTier, bestStars,
                    win ? p.streak() + 1 : 0, p.scoringGames() + 1);
            } else {
                // 人机/练习局：星与 MMR 全冻结（spec §6.2）。战绩口径以 TS 为准（profile.ts
                // record() 185-200 行）：totalHits 每局都进，wins/losses/streak/scoringGames
                // 只在 apply!==null（计分段）里动——电脑局只涨总命中，不涨胜负与连胜。
                deltaStar = 0;
                mmrAfter = p.mmr();
                progressMapper.updateProgress(uid, p.tier(), p.stars(), p.mmr(), p.lossStreak(),
                    p.wins(), p.losses(), p.totalHits() + hits,
                    p.bestTier(), p.bestStars(), p.streak(), p.scoringGames());
            }

            // 完成币：人人 +5，bot 局也发（spec §4/§6.1）；日上限与净增封顶在 applyCoin 内。
            GameWalletService.GrantResult coin = walletService.grant(uid, new Coins.CoinOp(
                Coins.CoinReason.GAME, "game:" + ctx.gameId() + ":" + uid, ctx.gameId(),
                ctx.nowMs(), Coins.GAME_GRANT), zone);

            // 门票胜奖：仅全人类匹配桌首局（ticket 由调用方保证只在那种局传入）；败者门票归公。
            if (ctx.ticket() != null && win) {
                int reward = Coins.TICKETS.get(ctx.ticket()).reward();
                if (reward > 0) {
                    walletService.grant(uid, new Coins.CoinOp(Coins.CoinReason.TICKET_WIN,
                        "ticket-win:" + ctx.gameId() + ":" + uid, ctx.gameId(), ctx.nowMs(), reward), zone);
                }
            }

            matchPlayerMapper.updateResult(ctx.gameId(), uid, rank == Integer.MAX_VALUE ? null : rank,
                eliminatedRound, hits, win ? 1 : 0, deltaStar, p.mmr(), mmrAfter, scoring ? 1 : 0);
            deltas.add(new PlayerDelta(uid, deltaStar, coin.applied(), coin.capped()));
        }

        matchMapper.markClosed(ctx.gameId(), "finished", ctx.nowMs(),
            (int) Math.max(0, ctx.nowMs() - match.startedAtMs()));
        return new SettleOutcome(true, List.copyOf(deltas));
    }

    // ---------------------------------------------------------------- 门票退款

    /**
     * 弃权/离队/补位退款（spec §4 门票状态机）：全额退 fee，
     * entry_key = ticket-refund:{ref} 与扣费天然配对；TICKET_REFUND 在 Coins 内
     * 原生豁免净增上限（还回的是自己的钱）。applied==0 时 Hub 不推送（spec §4）。
     */
    public GameWalletService.GrantResult refundTicket(long userId, Coins.TicketId ticket,
                                                      String matchIdOrRef, long nowMs) {
        int fee = Coins.TICKETS.get(ticket).fee();
        return walletService.grant(userId, new Coins.CoinOp(Coins.CoinReason.TICKET_REFUND,
            "ticket-refund:" + matchIdOrRef, matchIdOrRef, nowMs, fee), zone);
    }

    // ---------------------------------------------------------------- 内部

    private static GameTypes.RankEntry entryOf(GameTypes.GameResult result, long userId) {
        if (result == null) return null;
        String playerId = String.valueOf(userId);
        for (GameTypes.RankEntry e : result.ranking()) {
            if (e.playerId().equals(playerId)) return e;
        }
        return null;
    }
}
