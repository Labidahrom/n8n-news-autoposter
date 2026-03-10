# News Autoposter

n8n workflow, который автоматически создаёт новостные посты для Telegram из YouTube-видео.

## Как работает

1. Принимает POST-запрос с URL YouTube-видео через webhook
2. Скачивает аудио с помощью yt-dlp
3. Транскрибирует аудио в текст через Groq Whisper API
4. Генерирует новостной пост с помощью LLM (GPT-5-mini через OpenRouter)
5. Сохраняет данные в PostgreSQL
6. Отправляет готовый пост в Telegram
7. Удаляет временный аудиофайл

При ошибке на любом этапе срабатывает Error Handler: записывает ошибку в БД, отправляет уведомление в Telegram, удаляет временные файлы.

## Структура проекта

docker-compose.yml        — Docker-стек: n8n + PostgreSQL
Dockerfile.n8n            — Кастомный образ n8n с yt-dlp, ffmpeg, curl
init.sql                  — Инициализация БД: таблицы news_posts, error_logs
.env.example              — Шаблон переменных окружения
README.md
workflows/
  news-autoposter.json    — Основной workflow
  error-handler.json      — Workflow обработки ошибок

## Требования

- Docker и Docker Compose
- API-ключ Groq (Whisper, есть бесплатные лимиты на https://groq.com/)
- API-ключ OpenRouter (https://openrouter.ai/)
- Telegram-бот (токен от @BotFather)

## Установка и запуск

1. Клонировать репозиторий:

git clone https://github.com/YOUR_USERNAME/news-autoposter.git
cd news-autoposter

2. Создать .env по образцу env.example и заполнить значения

3. Запустить контейнеры:

docker compose build --no-cache
docker compose up -d

4. Открыть n8n: http://localhost:5678

5. Импортировать workflow из папки workflows/ (меню → Import from JSON).

6. Настроить credentials в n8n: Groq API key, OpenRouter API key, Telegram bot token, PostgreSQL.

7. Опубликовать оба workflow.

### Использование

Отправить POST-запрос:

```bash
curl -X POST http://localhost:5678/webhook/news \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.youtube.com/watch?v={VIDEO_ID}", "id": "{UNIQUE_ID}"}'
```

Где:
- `{VIDEO_ID}` — ID YouTube-видео (например, `dQw4w9WgXcQ`)
- `{UNIQUE_ID}` — произвольный идентификатор, используется как имя файла (например, `news1`)

Ответ при успехе: `{"status": "ok", "message": "URL received"}`
Ответ при отсутствии url: `{"error": "Field 'url' is required"}` (HTTP 400)

## Переменные окружения

Скопировать `.env.example` в `.env` и заполнить значения:

```env
# PostgreSQL (обязательно)
POSTGRES_USER=n8n
POSTGRES_PASSWORD=your_password_here
POSTGRES_DB=n8n

# n8n (обязательно)
N8N_ENCRYPTION_KEY=your_encryption_key_here
WEBHOOK_URL=https://your-domain.com/

# Ключи ниже НЕ подтягиваются в n8n автоматически.
# Настроить вручную внутри n8n (Credentials).

# OpenRouter (n8n → Credentials → OpenRouter)
OPENAI_API_KEY=sk-your-key-here

# Groq Whisper (вставить в код узла "Request to groq whisper")
GROQ_API_KEY=gsk-your-key-here

# Telegram (n8n → Credentials → Telegram)
TELEGRAM_BOT_TOKEN=your-bot-token-here
TELEGRAM_CHAT_ID=your-chat-id-here
```

## Особенности реализации

**Hardened Docker-образ:** начиная с n8n 2.0 из образа удалён пакетный менеджер `apk`. В `Dockerfile.n8n` он копируется из чистого Alpine-образа через multi-stage build.

**child_process:** в n8n 2.0 модуль заблокирован по умолчанию. Разблокируется через переменную `NODE_FUNCTION_ALLOW_BUILTIN=child_process`.

**Whisper через Code node:** Groq Whisper API требует отправки локального аудиофайла как `multipart/form-data` — стандартный HTTP Request узел не может читать файлы с диска контейнера, поэтому используется `curl` внутри Code node.

**Retry-логика:** yt-dlp — 3 попытки с паузой 3с; Whisper — 4 попытки с backoff 5/15/30с; Telegram — 2 попытки; LLM — встроенный retry n8n.
