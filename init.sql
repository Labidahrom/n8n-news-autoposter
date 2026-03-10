-- Таблица для новостных постов
CREATE TABLE IF NOT EXISTS news_posts (
    id SERIAL PRIMARY KEY,
    source_url TEXT NOT NULL,
    transcript TEXT,
    post_text TEXT,
    status VARCHAR(50) DEFAULT 'draft',
    created_at TIMESTAMP DEFAULT NOW()
);

-- Таблица для логов ошибок
CREATE TABLE IF NOT EXISTS error_logs (
    id SERIAL PRIMARY KEY,
    node_name VARCHAR(255),
    error_message TEXT,
    input_data JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Индексы
CREATE INDEX IF NOT EXISTS idx_news_posts_url ON news_posts(source_url);
CREATE INDEX IF NOT EXISTS idx_news_posts_status ON news_posts(status);
CREATE INDEX IF NOT EXISTS idx_error_logs_created ON error_logs(created_at);
