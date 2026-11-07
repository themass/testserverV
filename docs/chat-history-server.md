# 对话历史改由服务端持有

范围：`testserverV/vvv-link` 的对话链路（`ChatController` / `ChatServiceImpl` / `ChatContext` /
`BaseChatHandleProxy`）。Android 客户端的改动不在本次范围内，只在第 7 节列出待办。

## 1. 结论

- 会话与消息存 MySQL（`vpn.chat_session` / `vpn.chat_message`），服务端是唯一权威来源。
- Redis 只做「每个会话最近 N 条」的热缓存，键 `chat:{userId}:{sessionId}`，`LTRIM` 限长，读写都刷新 TTL，
  失效时从 MySQL 回填。Redis 挂了只影响延迟，不影响正确性。
- 提示词里的对话历史一律从上面的存储读，**不再读请求里上传的历史**。请求只带当轮新消息。
- 旧的 `chat_record_{userId}`（一个用户一个 list，不分会话、无 TTL、无上限、只写不读）整条链路删除。
- 不做兼容：老客户端上传的 `content` 字段不再解析；`sessionId` 改成服务端自增 id。

## 2. 数据模型

建表脚本：`vvv-link/src/main/resources/sql/2026111400_chat_history.sql`（需要手工在目标库执行一次）。
列名沿用本库约定：MyBatis 未开 `mapUnderscoreToCamelCase`，列名就是 Java 属性名的驼峰。

### vpn.chat_session

| 列 | 类型 | 说明 |
|---|---|---|
| id | BIGINT AUTO_INCREMENT | 会话 id，服务端生成 |
| userId | BIGINT | 归属用户，所有查询都带它 |
| name | VARCHAR(128) | 会话名，可由客户端改；首轮自动用消息前 20 字命名 |
| characterId | INT NULL | 会话创建时选定的 `setting_character.id` |
| roleId | VARCHAR(128) NULL | 角色目录（vvv-roles）里的角色 id |
| createdAt / updatedAt | DATETIME | updatedAt 每轮对话、改消息都会刷新，列表按它倒序 |
| deleted | TINYINT | 软删除 |

索引：`(userId, deleted, updatedAt)`。

### vpn.chat_message

| 列 | 类型 | 说明 |
|---|---|---|
| id | BIGINT AUTO_INCREMENT | 消息 id |
| sessionId | BIGINT | 所属会话 |
| userId | BIGINT | 冗余存一份，删除/改消息时用它兜底鉴权 |
| role | VARCHAR(16) | `user` / `assistant` |
| content | MEDIUMTEXT | 正文。助手空回复不落库 |
| type | INT | 0 文本 / 1 语音 / 2 图片 / 3 视频 / 4 文件（与客户端 `MessageType` 一致） |
| clientMsgId | VARCHAR(64) NULL | 客户端为当轮消息生成的 id；同 id 重发不会重复插入 |
| createdAt | DATETIME | 创建时间 |
| deleted | TINYINT | 软删除 |

索引：`(sessionId, deleted, id)`、`(sessionId, clientMsgId)`。

### 为什么保留 characterId / roleId

人设是会话属性，不是每轮参数：换会话就是换角色。存下来后，续聊不需要客户端每轮再传；
`/chat/*.json` 仍然接受这两个字段，用于「本轮指定/补齐」会话人设（见 5.1）。

### 旧数据

不迁移（已与用户确认）。旧 Redis 键 `chat_record_{userId}` 不再读写，可在上线后手工清理，
不影响新链路。

## 3. Redis 缓存

实现：`service/impl/ChatMemoryCache`。

| 项 | 取值 |
|---|---|
| 键 | `chat:{userId}:{sessionId}`（Redis list，元素是 `ChatMemoryItem` 的 JSON） |
| 长度 | `LTRIM` 到最近 60 条（`CACHE_SIZE`） |
| TTL | 7 天，每次读、写都 `EXPIRE` 刷新 |
| 命中 | `LRANGE 0 -1`，刷新 TTL |
| 未命中 | 从 MySQL 取最近 60 条回填，再返回 |
| 写 | 键存在才 `RPUSH` + `LTRIM`；键不存在就不写，留给下次读时整段回填（避免半截缓存） |
| 失效 | 删除消息、改消息、重新生成、会话删除 → `DEL` |

所有 Redis 操作都 try/catch 并打 `warn` 日志；异常一律按未命中处理，直接读 MySQL。
Redis 不可用时接口仍然正确，只是每次多一次库查询。

提示词窗口 `PROMPT_WINDOW = 30`：从缓存列表里取最后 30 条拼成 `[user]...` / `[assistant]...` 文本。
缓存比窗口大，是为了给后续的会话摘要/分页留余量。

## 4. 提示词组装

`BaseChatHandleProxy#getPrompt` 只改历史来源，模板本身不动：

```
角色正文（目录角色 / characterId / settingName）
+ Requirements + NOTE
+ "# Conversation History:\n" + 服务端历史
```

历史在写入当轮用户消息之后读取，所以当前这条也在里面，和旧行为一致（旧代码也是先写 Redis 再拼）。
`getPrompt` 顺带把 `String.format` 换成字符串拼接：用户自建角色正文里出现 `%` 时原来会抛
`UnknownFormatConversionException`。

> 把历史从「拼进一条 user 消息」改成原生多轮 messages，属于另一件事（见分析文档 4.3），本次不做。

## 5. API

统一前缀 `/api/chat`。除特别说明外都走 `@UserInfo(required = true)`，未登录报 token 过期。
返回仍包在 `JsonResult` 里（`errno` / `data` / `error`）。

### 5.1 发消息：`POST /stream.json`、`POST /nostream.json`、`POST /transword.json`

请求参数（`application/x-www-form-urlencoded`，与现有客户端一致）：

| 字段 | 必填 | 说明 |
|---|---|---|
| sessionId | 否 | 会话 id。`<=0` 或省略时新建一个会话，名字取本轮消息前 20 字；新 id 在响应里返回 |
| text | 是（`regenerate=false` 时） | 当轮新消息。**不再接受 `content`（整段历史）** |
| id | 否 | 客户端消息 id。同一会话内重复提交同一个 id 视为重发：不重复插入，只清掉它之后的助手回复 |
| regenerate | 否 | `true` 表示「重新生成」：不插入用户消息，删掉最后一条用户消息之后的所有助手回复，再重新回答 |
| characterId | 否 | 会话还没有人设时用它补上 |
| roleId | 否 | 同上；优先级高于 characterId（沿用原逻辑） |
| settingName | 否 | 旧人设 switch，仅在没有 characterId/roleId 时生效 |

- 流式响应：`StreamChunk{id, sessionId, delta, done, error}`，**新增 `sessionId` 字段**（每帧都带）。
  流正常结束时的 done 帧额外带 `userMessageId`、`assistantMessageId`（回复为空时为 0）。
- 非流式响应：`Choice` 里新增 `sessionId`、`userMessageId`、`assistantMessageId`。
- 助手回复为空（模型没吐字）时不写库；流被取消/断开时，把已生成的部分写库。

### 5.2 会话

| 方法 | 路径 | 参数 | 返回 |
|---|---|---|---|
| GET/POST | `/sessions.json` | — | `InfoListVo<ChatSessionVo>`，按 `updatedAt` 倒序；用户一个会话都没有时自动建一个「新对话」 |
| POST | `/session/create.json` | `name`（可空）、`characterId`、`roleId` | `ChatSessionVo` |
| POST | `/session/rename.json` | `id`、`name` | `ChatSessionVo` |
| POST | `/session/delete.json` | `id` | 成功即 `errno=0` |

`ChatSessionVo`：`{id, name, characterId, roleId, createdAt, updatedAt, lastMessage, messageCount}`
（后两个是列表展示用的，`lastMessage` 截断到 40 字；时间都是毫秒时间戳）。
删除最后一个会话是允许的，之后 `/sessions.json` 会自动新建一个。

### 5.3 消息

| 方法 | 路径 | 参数 | 返回 |
|---|---|---|---|
| GET/POST | `/messages.json` | `sessionId`、`beforeId`（可空）、`limit`（默认 30，最大 200） | `InfoListVo<ChatMessageVo>`，`voList` 按 id 正序；`hasMore=true` 表示还有更早的 |
| POST | `/message/delete.json` | `sessionId`、`id` | 成功即 `errno=0` |
| POST | `/message/edit.json` | `sessionId`、`id`（必须是 user 消息）、`text` | 改后的 `ChatMessageVo`；该消息之后的所有消息一并删除 |

`ChatMessageVo`：`{id, sessionId, role, content, type, clientMsgId, createdAt}`（时间是毫秒时间戳）。
历史里只存文本（type=0）。图片、文件、语音附件不进历史，刷新或换设备后消失，这是确认过的预期行为。

「重新生成」不单独开接口：客户端调 `/stream.json` 带 `regenerate=true`，
服务端先删掉最后一条用户消息之后的助手回复，再重新回答，少一次往返、也不会出现
「删了但没重生成」的中间态断言。

重新生成的语义按「最后一条用户消息」定位，而不是「最后一条消息」，所以连续点两次重新生成也是安全的。

## 6. 顺带修掉的问题

| 问题 | 位置 | 改法 |
|---|---|---|
| `replace(...)` 返回值被丢弃，去 `[assistant]` 前缀无效 | `BaseChatHandleProxy#chatWithGptBase` | 接收返回值并 `setContent` |
| `choice` 判空不完整，handler 返回 null 时 NPE | 同上 | `choice == null || choice.getMessage() == null` 时抛异常，交给 `ChatContext` 重试 |
| `Optional.ofNullable(list).orElse(null).stream()` 等于没判空 | `#history` | 整段删除，历史改由 `ChatHistoryService` 提供 |
| `CacheRedisUtil` 空的 `catch` | 已删除 | 新缓存类所有异常都打 `warn` 并降级读库 |
| 流式取消时不写助手记录 | `#streamOpenAiCompatible` | `finally` 里判断是否正常结束，未结束则用已生成的部分回调 `onCancel` |
| 空助手回复写入历史 | `chatWithGptBase` / `appendAssistant` | 空白内容一律不落库 |
| 用户自建角色正文含 `%` 时格式化异常 | `#getPrompt` | `String.format` 改拼接 |

## 7. Android 客户端待改（不在本次范围）

1. **发送**：不再拼 `content`（`[{role, content}]` 数组）上传；只发 `sessionId`、`text`、`id`、
   `characterId`/`roleId`。服务端不再解析 `content`。
2. **会话 id**：`sessionId` 改用服务端返回值。首轮可以传 0，从 `StreamChunk.sessionId`
   （或 `Choice.sessionId`）拿到新 id 后存 SP；`/sessions.json` 返回的 `id` 同理。
3. **会话列表**：`/sessions.json` 改为真实数据，字段换成 `ChatSessionVo`（`id/name/characterId/roleId/
   createdAt/updatedAt/lastMessage/messageCount`），旧的 `setting`/`type` 不再返回。
   新建/改名/删除分别调 `/session/create.json`、`/session/rename.json`、`/session/delete.json`，
   本地不再自己生成会话（`ChatSessionLog.id` 由服务端下发）。
4. **历史**：`loadHistory` 改成拉 `/messages.json`（`beforeId` 往前翻页），本地 Room/greenDAO
   只做离线缓存，不再是权威来源；服务端返回的 `id` 用作 `chatId`。
5. **删除单条**：调 `/message/delete.json`，成功后再删本地行。
6. **编辑用户消息**：调 `/message/edit.json`，服务端会把这条之后的消息一起删掉，客户端要同步丢弃
   本地对应的后续消息。
7. **重新生成**：先本地去掉最后一条助手气泡，再调 `/stream.json` 带 `regenerate=true`
   （不要带 `text`）。
8. **离线/多端**：换设备登录后直接拉 `/sessions.json` + `/messages.json` 即可续聊；不再需要上传历史。
9. `StreamChunk` 新增 `sessionId` 字段，老客户端会忽略它（Jackson 已关闭 `FAIL_ON_UNKNOWN_PROPERTIES`）。

## 8. 没有做的事 / 没有验证的

- 没有连真实 MySQL / Redis 跑过：表结构与 SQL 是静态检查，接口只在编译层面验证。
- 没有迁移旧数据（已确认不需要）。
- 没有做会话摘要、长期记忆、原生多轮 messages 组装；这些是分析文档 4.3 的后续步骤。
- 没有限制单会话消息总量，也没有清理策略；需要时按 `createdAt` 归档。

## 9. 已确认的决定

- 消息 id：流结束的 done 帧与非流式 `Choice` 都带 `userMessageId`、`assistantMessageId`，客户端拿到后直接写进本地气泡，编辑/删除使用正式 id。`/messages.json` 只作兜底。
- 附件（图片、文件、语音）不进历史，换设备或刷新后消失，是预期行为。
- 非文本消息：服务端历史只存 type=0 文本。type 1–4 仅为预留，格式沿用客户端 `ChatLogMapper` 的 JSON 结构（语音：`content`/`org`/`time`；图片：`images` + `caption`；文件：`files`）。
- 请求字段 `charater` 已删除（无人读取）。
- 允许删除最后一个会话，`/sessions.json` 会自动恢复一个。
