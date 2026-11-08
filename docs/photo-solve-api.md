# 拍照解题：接口设计（草案，端上先保持 mock）

状态：只设计，不实现。端上继续用 `MockPhotoSolveRepository`，端到端流程先在手机上走通，后端按这里实现。

## 1. 端上流程（已有，保留）

首页 → 拍照 → 裁剪（自动框 + 手动微调，角度校正）→ 质量检查（不清晰弹窗）→ 识别中 → 结果。

## 2. 接口

### POST /api/photosolve/solve.json（需登录）

请求（multipart/form-data）：

| 字段 | 必填 | 说明 |
|---|---|---|
| images | 是 | 一张或多张图片，字段名可重复（`images=...` 多次），每张 JPEG 或 WebP，长边不超过 2048px，单张不超过 5MB，最多 6 张（上限在配置里） |
| text | 否 | 用户补充的文字，例如「第二问不清楚，是求面积」「这是选择题」。可以只有图片，也可以只有文字（没有图片时服务端可以直接解题） |
| imageRoles | 否 | 与 images 一一对应的角色，如 `question`（题目）、`figure`（题图）、`answer_sheet`（作答），默认 `question` |
| clientRequestId | 是 | 客户端生成的 UUID，用于幂等，重试不会重复扣额度 |
| model | 否 | 客户端不指定模型，由服务端按配置选择；只有内部调试时可以传，需要白名单（见下面「模型可替换」） |
| subject | 否 | 学科提示，如 math、physics，不传则自动判断 |
| grade | 否 | 年级提示 |
| quality | 否 | 客户端的质量评分（0–1），仅用于日志 |

响应（成功）：

```json
{
  "code": 0,
  "data": {
    "requestId": "string",
    "subject": "math",
    "question": {
      "text": "题干（纯文本，公式用 LaTeX，行内用 $...$）",
      "hasImageInside": false
    },
    "answer": {
      "finalAnswer": "x = 2",
      "latex": "x=2"
    },
    "steps": [
      { "index": 1, "text": "第一步说明", "latex": "2x-1=3" }
    ],
    "confidence": 0.92,
    "createdAt": 1731000000000
  }
}
```

响应（失败，`code` 非 0，`data` 为空，`message` 是给用户看的话）：

| code | 含义 | 客户端处理 |
|---|---|---|
| 40001 | 图片不清晰 | 弹窗：建议重拍，附带"仍然提交"按钮 |
| 40002 | 不是题目 | 弹窗：未识别到题目，请重新框选 |
| 40003 | 图片过大或格式不支持 | 直接在客户端压缩后重试 |
| 42901 | 额度用完 | 提示额度，给出升级入口（产品决定） |
| 50001 | 模型服务失败 | 可重试，保留图片 |

## 3. 其他接口

- `GET /api/photosolve/history.json?page=&size=`：历史记录列表，每条带缩略图 URL 和题干摘要。
- `GET /api/photosolve/{requestId}.json`：单条详情，同上面的 `data`。
- `POST /api/photosolve/{requestId}/feedback.json`：用户反馈（答案错误、步骤不清楚），字段 `type`、`comment`。

## 4. 服务端实现要点

- **鉴权和额度**：和聊天接口共用登录态；额度按 `clientRequestId` 去重后扣减。
- **图片存储**：原图存对象存储，保留 30 天后删除（隐私）；数据库只存 URL 和元数据。
- **模型**：调用能看图的大模型，模型名和厂商是你要定的；服务端保持 API Key 不下发客户端。
- **超时**：同步接口最长 30 秒；超时返回 50001，客户端可重试。
- **审核**：返回前过一遍内容审核，违规内容返回 40002 或单独的审核码。

## 5. 客户端对接（端上需要做的，等服务端确定后）

- 实现 `PhotoSolveRepository` 的真实版本，在 `Application.onCreate` 里调用 `PhotoSolveRepositories.install(...)`。
- 把上面的错误码映射到 UI：40001 弹重拍弹窗，40002 弹框选提示，其他走通用错误。
- 结果页展示 `steps` 和 `latex`（需要公式渲染，见下）。

## 6. 扩展性设计（模型可替换、多图加文字）

### 6.1 模型可替换
- 服务端定义一个统一接口 `SolveProvider`：输入是「图片列表 + 文字 + 角色」，输出是统一的结果结构（见第 2 节的 `data`）。
- 每个模型厂商实现一个 provider（例如 `GeminiSolveProvider`、`OpenAiSolveProvider`、`QwenSolveProvider`），互不影响。
- 当前用哪个模型由服务端配置决定（`photosolve.provider`、`photosolve.fallback`），**换模型只改配置，不改接口，不发版**。
- 失败自动切换到 fallback 模型；响应里带 `providerUsed`，方便排查和对比效果。
- 客户端不感知模型，只在结果里看到 `providerUsed`（可选展示）。

### 6.2 多图加文字
- 请求是「图片数组 + 文字 + 角色」，三种组合都合法：
  - 单图：`images=[q]`
  - 多图：`images=[q1,q2,...]`，例如整页题目被拍成两张
  - 图加文字：`images=[q], text="第二问"`
  - 纯文字：`text="..."`，不传图片
- 多图时服务端按顺序理解为同一道题或多道题，由模型判断；返回 `questions[]` 数组（一道题一个元素），单题时长度为 1。

### 6.3 统一的返回结构（为扩展留空间）

```json
{
  "code": 0,
  "data": {
    "requestId": "string",
    "providerUsed": "gemini-2.5-flash",
    "questions": [
      {
        "index": 1,
        "subject": "math",
        "question": { "text": "...", "latex": "..." },
        "answer": { "finalAnswer": "...", "latex": "..." },
        "steps": [ { "index": 1, "text": "...", "latex": "..." } ],
        "confidence": 0.9
      }
    ],
    "extensions": {}
  }
}
```

- `extensions` 是给未来功能留的空位（例如题目标签、知识点、相似题），客户端忽略未知字段。
- 所有字段都允许增加，不允许删除或改名（向后兼容）。

### 6.4 版本
- 路径带版本：`/api/photosolve/v1/solve.json`，以后有破坏性变更再开 `v2`。

## 7. 注意事项（需要你定）
- 上传到第三方模型的图片是否需要用户明确同意（隐私说明）。
- 不同模型对图片大小和数量的限制不同，服务端要按当前 provider 的限制预先压缩或拒绝。
- 费用：每个 provider 的单价不同，额度要按 provider 分别计量。
