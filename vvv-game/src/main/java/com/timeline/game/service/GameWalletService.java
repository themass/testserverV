package com.timeline.game.service;

import com.timeline.game.domain.Coins;
import com.timeline.game.persistence.GameCoinLedgerMapper;
import com.timeline.game.persistence.GameWalletMapper;

import java.time.ZoneId;
import java.util.List;
import java.util.Locale;

/**
 * 钱包 + 流水门面（GameWalletMapper + GameCoinLedgerMapper + {@link Coins} 域纯函数）。
 *
 * 幂等的落点（data-model.md）：不在内存里判重——内存账本视图这里干脆是空的——
 * 而是先跑 {@link Coins#applyCoin}（封顶/日限/余额检查全是纯函数），applied&gt;0 才
 * INSERT IGNORE 流水行（uk (user_id, entry_key) 是唯一真相）：返回 0 行 = 并发的同 id
 * 已经入过账，钱包一个字节都不碰，直接报 applied=0。
 *
 * 事务约定：流水插入与钱包两条更新（日计数 CAS + 余额条件更新）必须由调用方包在
 * 同一事务里（外层还有 game:lock:user:{userId} 用户锁）。CAS 失败让渡时，已插入的
 * 流水行随事务回滚，下个请求带新 day_key 重试才不会被 entry_key 挡住白丢钱。
 *
 * 跨日竞态：applyCoin 用的是读档时的 day_key；写回时 CAS 失败（日切或并发覆盖）就
 * 读回新行重算一遍只为如实返回新日状态，本笔让渡（applied=0），绝不拿旧算的结果
 * 覆盖新日计数。
 */
public final class GameWalletService {

    private final GameWalletMapper walletMapper;
    private final GameCoinLedgerMapper ledgerMapper;

    public GameWalletService(GameWalletMapper walletMapper, GameCoinLedgerMapper ledgerMapper) {
        this.walletMapper = walletMapper;
        this.ledgerMapper = ledgerMapper;
    }

    /**
     * 一笔入账的结果。applied = 实际进余额的数额（0 = 幂等吞掉 / 上限截成 0 / 竞态让渡）；
     * insufficient = 余额不足以支出（流水未写、钱包未动，调用方应拒绝并提示 BALANCE_LOW）。
     */
    public record GrantResult(int applied, boolean capped, boolean insufficient,
                              int balance, Coins.DailyState daily) {}

    /** 展示壳（ProfileView 的钱包半边）：balance + 当日计数器。 */
    public record WalletSnapshot(int balance, Coins.DailyState daily) {}

    // ---------------------------------------------------------------- 建档

    /** 首见建钱包（余额/计数全 0 由 DDL 默认值给）；已有行是 no-op。 */
    public void ensureWallet(long userId, String dayKey) {
        if (walletMapper.wallet(userId) != null) return;
        try {
            walletMapper.insertInitial(userId, dayKey);
        } catch (RuntimeException race) {
            // 并发建档撞主键：别人先建好了，与本调用等价；其余 SQL 异常同样上抛由外层事务处理。
            if (walletMapper.wallet(userId) == null) throw race;
        }
    }

    // ---------------------------------------------------------------- 一笔账

    /**
     * 一笔账的持久化路径（顺序不可换，data-model.md）：
     * ① 读钱包 → ② applyCoin 纯函数（内存空账本视图，幂等交给唯一键）→
     * ③ applied&gt;0 才 INSERT IGNORE 流水（final delta + capped 标记）→
     * ④ 日计数 CAS（WHERE day_key=旧值）→ ⑤ 余额条件更新（加完不许为负）。
     * ③④⑤ 任一行数为 0 即让渡：③=同 id 赛跑、④=跨日赛跑、⑤=并发扣款掏空。
     */
    public GrantResult grant(long userId, Coins.CoinOp op, ZoneId zone) {
        GameWalletMapper.WalletRow w = walletMapper.wallet(userId);
        if (w == null) {
            ensureWallet(userId, Coins.dayKey(op.at(), zone));
            w = walletMapper.wallet(userId);
        }
        Coins.DailyState daily = toDaily(w);
        // 账本视图给空的：applyCoin 的内存判重在这里用不上也不该用——唯一键才是真相。
        Coins.CoinResult r = Coins.applyCoin(new Coins.CoinsState(w.coinBalance(), List.of()),
            daily, op, zone);

        if (r.insufficient()) {
            // 余额不足（applyCoin 对着快照判的）：流水都没写，原样返回。
            return new GrantResult(0, false, true, w.coinBalance(), daily);
        }
        if (r.applied() == 0) {
            // 日限/净增封顶截成 0：不写流水、不动钱包。
            // 注意判 ==0 而不是 <=0：applied 是有符号入账额（Coins.applyCoin 返回 delta 原值，
            // 扣费为负——门票 -50 走这里继续写账），负额的余额防线在 addBalance 的
            // coin_balance+delta>=0 条件更新里，不在这道闸门。
            return new GrantResult(0, r.capped(), false, w.coinBalance(), daily);
        }

        int inserted = ledgerMapper.insertIgnore(userId, op.id(), reasonKey(op.reason()),
            r.applied(), op.ref(), op.at(), r.capped() ? 1 : 0);
        if (inserted == 0) {
            // uk 挡住：同 id 已被并发入过账，读回现余额报 applied=0（data-model.md 语义）。
            GameWalletMapper.WalletRow again = walletMapper.wallet(userId);
            return new GrantResult(0, false, false, again.coinBalance(), toDaily(again));
        }

        Coins.DailyState nd = r.daily();
        int cas = walletMapper.casUpdateDay(userId, nd.day(), boolToInt(nd.loginDone()),
            nd.gameGrants(), nd.ticketPlays(), nd.adGrants(), nd.netGain(), w.dayKey());
        if (cas == 0) {
            // 跨日/并发赛跑：读回新行重算一遍只如实返回新日状态；本笔让渡（事务回滚流水），
            // 调用方下个请求重试。绝不拿旧 day_key 算出的结果去覆盖新日计数。
            GameWalletMapper.WalletRow fresh = walletMapper.wallet(userId);
            Coins.CoinResult rr = Coins.applyCoin(
                new Coins.CoinsState(fresh.coinBalance(), List.of()), toDaily(fresh), op, zone);
            return new GrantResult(0, false, false, fresh.coinBalance(), rr.daily());
        }
        if (walletMapper.addBalance(userId, r.applied()) == 0) {
            // 快照检查后余额被并发支出掏空：让渡，流水随事务回滚。
            return new GrantResult(0, false, true, w.coinBalance(), daily);
        }
        return new GrantResult(r.applied(), r.capped(), false, w.coinBalance() + r.applied(), nd);
    }

    // ---------------------------------------------------------------- 读与配额

    /** 余额（ProfileView 快速路径）；没建过档 = 0。 */
    public int balance(long userId) {
        GameWalletMapper.WalletRow w = walletMapper.wallet(userId);
        return w == null ? 0 : w.coinBalance();
    }

    /**
     * 余额 + 当日计数器（跨日的旧行按存储值原样返回，不主动翻页——翻不翻页归发账路径管）。
     * 没建过档时返回全新日计数，其中日期键取此刻（本类唯一碰墙钟的地方，且只是展示兜底；
     * spec §1 的禁墙钟令针对 Table/Matchmaking/Hub 的逻辑时间）。
     */
    public WalletSnapshot snapshot(long userId, ZoneId zone) {
        GameWalletMapper.WalletRow w = walletMapper.wallet(userId);
        if (w == null) return new WalletSnapshot(0, Coins.initialDaily(System.currentTimeMillis(), zone));
        return new WalletSnapshot(w.coinBalance(), toDaily(w));
    }

    /** 门票配额判定（先按 now 翻日：昨天满 20 不挡今天）；没建过档 = 拒。 */
    public boolean canPlayTicket(long userId, long nowMs, ZoneId zone) {
        GameWalletMapper.WalletRow w = walletMapper.wallet(userId);
        if (w == null) return false;
        return Coins.canPlayTicket(Coins.rollDaily(toDaily(w), nowMs, zone));
    }

    /**
     * 门票开局计数（真开了人才局才调，补位退款不计数，TS countTicketPlay 语义）。
     * 配额上限归调用方（Hub 开局前用 canPlayTicket 判），这里只管带 CAS 地 +1。
     * 返回 false = 跨日/并发让渡（重试次数封顶一次），调用方下个请求再来。
     */
    public boolean bumpTicketPlays(long userId, long nowMs, ZoneId zone) {
        GameWalletMapper.WalletRow w = walletMapper.wallet(userId);
        for (int attempt = 0; attempt < 2 && w != null; attempt++) {
            Coins.DailyState nd = Coins.bumpTicketPlays(toDaily(w), nowMs, zone);
            int cas = walletMapper.casUpdateDay(userId, nd.day(), boolToInt(nd.loginDone()),
                nd.gameGrants(), nd.ticketPlays(), nd.adGrants(), nd.netGain(), w.dayKey());
            if (cas == 1) return true;
            w = walletMapper.wallet(userId); // 读回新行，带新 day_key 重算再来一遍
        }
        return false;
    }

    // ---------------------------------------------------------------- 内部

    private static Coins.DailyState toDaily(GameWalletMapper.WalletRow w) {
        return new Coins.DailyState(w.dayKey(), w.loginDone() != 0, w.gameGrants(),
            w.ticketPlays(), w.adGrants(), w.netGain());
    }

    /** CoinReason → 流水 reason 列词表（data-model.md：login/game/ticket-fee/…，kebab 小写）。 */
    private static String reasonKey(Coins.CoinReason reason) {
        return reason.name().toLowerCase(Locale.ROOT).replace('_', '-');
    }

    private static int boolToInt(boolean b) { return b ? 1 : 0; }
}
