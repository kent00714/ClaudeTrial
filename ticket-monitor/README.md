# 票務釋票監測（Ticket Release Monitor）

定時檢查台灣各大售票網站，一旦「選購一空」變成「立即訂購」，或剩餘張數增加（釋票／加釋），就立刻推播通知。

第一個驗證目標：**金智媛 2026 亞洲見面會《WONEDERLAND》台北場**（2026/11/08 18:00，Legacy TERA，拓元售票）。

> 這是**只讀的監測工具**：不登入、不排隊、不自動購票、不繞過驗證碼，只負責通知你，購票仍由你本人手動完成。請遵守各售票網站的使用條款，別把檢查間隔設得太短。

## 支援的網站

| 網站 | 方式 | 能偵測的內容 |
|------|------|--------------|
| 拓元 tixCraft | 專屬解析器 | 用關鍵字找活動、每個場次的狀態；`check_areas = true` 時再加上各區剩餘張數 |
| KKTIX | 專屬解析器 | 搜尋活動，以及每種票的庫存（`register_info` JSON；格式如果變了，會改用整頁文字判斷） |
| ibon、年代、遠大、OPENTIX、udn、FamiTicket | 通用掃描 | 在首頁／列表頁用關鍵字找連結；狀態依關鍵字判斷，也可以設定頁面內容一變就通知 |

通用掃描屬於盡力而為。用 JavaScript 動態載入的網站（例如遠大、OPENTIX）純 HTML 可能抓不到內容，之後可以為它們另寫 API 解析器。

## 快速開始

```bash
cd ticket-monitor
pip install -r requirements.txt

# 1) 先確認各站找得到活動
python -m ticket_monitor --discover-only

# 2) 持續監測（預設每 120 秒＋隨機 0–30 秒）
export NTFY_TOPIC=my-secret-kjw-topic     # 手機裝 ntfy App 訂閱同一個 topic
python -m ticket_monitor

# 或只跑一次（給 cron 用）
python -m ticket_monitor --once
```

## 通知管道（環境變數）

| 管道 | 環境變數 |
|------|----------|
| 終端機 | 一律啟用 |
| ntfy（最簡單，免帳號） | `NTFY_TOPIC`、選填 `NTFY_SERVER` |
| Telegram | `TELEGRAM_BOT_TOKEN`、`TELEGRAM_CHAT_ID` |
| Discord | `DISCORD_WEBHOOK_URL` |

## 會通知的事件

- **釋票**：場次或票區從售完、未開賣變成可購買
- **加釋**：剩餘張數增加（拓元開啟 `check_areas`，或 KKTIX）
- **發現新活動**：關鍵字在任一網站找到新的活動（例如加場）
- **頁面變動**：只限設了 `notify_on_change = true` 的 watch

第一次執行只會建立基準，並送出一則「監測已啟動」摘要（列出目前可購買的項目），不會把每個項目都當成新釋票。

## 設定

請看 `config.toml`。常用設定：

- `interval_seconds`：檢查間隔，程式強制最低 30 秒
- `min_host_interval_seconds`：同一網站兩次請求至少間隔幾秒
- `[[targets]]`：一個追蹤目標，包含 `keywords`（中文、英文、韓文都可以）和 `providers`
- `[[targets.watch]]`：直接釘選某個活動代碼或網址。就算該活動從列表頁下架，也會繼續監測

## 部署建議

- **最即時**：放在台灣的常駐電腦、NAS 或樹莓派上執行 `python -m ticket_monitor`。釋票通常幾分鐘內就被搶完。
- **免主機**：`.github/workflows/ticket-monitor.yml` 每 5 分鐘跑一次，狀態用 Actions cache 保存。在 repo 的 Settings → Secrets 設好通知用的環境變數即可。注意：GitHub 排程經常延遲，runner 也不在台灣，部分售票網站可能會擋海外 IP，所以只適合當備援。

## 測試

```bash
python -m unittest discover -s tests -t .
```

測試用的 HTML 在 `tests/fixtures/`，是**依照網站結構手寫的模擬資料**，不是真實網站的內容。真實網站改版時，需要用 `--discover-only` 和 `-v` 實際跑一次來確認。
