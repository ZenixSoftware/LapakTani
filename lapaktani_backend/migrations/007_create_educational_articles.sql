-- Migration: 007_create_educational_articles.sql
-- US-18: Edukasi Pertanian & Badge Resmi PPL

CREATE TABLE IF NOT EXISTS educational_articles (
    id VARCHAR(100) PRIMARY KEY,
    author_id VARCHAR(36) NOT NULL,
    title VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    commodity VARCHAR(100) NOT NULL,
    summary TEXT NOT NULL,
    content LONGTEXT NOT NULL,
    steps_json JSON NULL,
    image_url VARCHAR(500) NULL,
    read_time_minutes INT DEFAULT 5,
    likes_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_articles_author FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE INDEX idx_articles_commodity ON educational_articles(commodity);
CREATE INDEX idx_articles_category ON educational_articles(category);
CREATE INDEX idx_articles_created ON educational_articles(created_at DESC);
