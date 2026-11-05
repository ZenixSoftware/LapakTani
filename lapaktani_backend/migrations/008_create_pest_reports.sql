-- Migration: 008_create_pest_reports.sql
-- US-19: Pelaporan & Peringatan Dini Serangan Hama (Pest Alert System)

CREATE TABLE IF NOT EXISTS pest_reports (
    id VARCHAR(100) PRIMARY KEY,
    reporter_user_id VARCHAR(36) NOT NULL,
    farmer_group_id VARCHAR(100) NULL,
    farmer_group_name VARCHAR(150) NOT NULL,
    village_id INT DEFAULT 1,
    village_name VARCHAR(150) DEFAULT 'Desa Lembang',
    commodity_name VARCHAR(100) NOT NULL,
    pest_name VARCHAR(150) NOT NULL,
    severity_level ENUM('LOW', 'MEDIUM', 'HIGH', 'CRITICAL') DEFAULT 'MEDIUM',
    severity_label VARCHAR(50) DEFAULT 'Sedang',
    attack_area_hectares DECIMAL(8,2) DEFAULT 0.00,
    affected_area VARCHAR(100) NOT NULL,
    location_address TEXT NULL,
    latitude DECIMAL(10,8) NULL,
    longitude DECIMAL(11,8) NULL,
    photo_url VARCHAR(500) NULL,
    description TEXT NOT NULL,
    handling_recommendation TEXT NULL,
    verified_by_penyuluh_id VARCHAR(36) NULL,
    status ENUM('SUBMITTED', 'VERIFIED_PPL', 'EARLY_WARNING_ISSUED', 'RESOLVED') DEFAULT 'SUBMITTED',
    legacy_status ENUM('active', 'contained', 'resolved') DEFAULT 'active',
    emergency_alert BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_pest_reporter FOREIGN KEY (reporter_user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_pest_severity (severity_level),
    INDEX idx_pest_status (status),
    INDEX idx_pest_emergency (emergency_alert),
    INDEX idx_pest_group (farmer_group_id),
    INDEX idx_pest_created (created_at DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS pest_early_warnings (
    id VARCHAR(100) PRIMARY KEY,
    pest_report_id VARCHAR(100) NOT NULL,
    warning_title VARCHAR(255) NOT NULL,
    warning_message TEXT NOT NULL,
    affected_radius_km INT DEFAULT 5,
    recommended_action TEXT NOT NULL,
    issued_by_user_id VARCHAR(36) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_warning_report FOREIGN KEY (pest_report_id) REFERENCES pest_reports(id) ON DELETE CASCADE,
    CONSTRAINT fk_warning_issuer FOREIGN KEY (issued_by_user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_warning_created (created_at DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
