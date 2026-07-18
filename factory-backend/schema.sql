-- =====================================================================
-- MACHINE HEALTH MONITORING SYSTEM - PRODUCTION SCHEMA (v4)
-- Engine: MySQL / MariaDB (InnoDB)
--
-- Perubahan dari v3:
-- - KOMPONEN jadi murni representasi 1 komponen fisik (id_parameter dicabut)
-- - Tambah KOMPONEN_PARAMETER: parameter apa aja yang relevan buat 1 komponen
--   + threshold override per-instance (opsional, kalau beda dari default global)
-- - Tambah SENSOR_READING: histori time-series tiap pembacaan sensor
-- - SERVICE_ALERT nyimpen referensi ke reading yang men-trigger
-- =====================================================================

CREATE DATABASE IF NOT EXISTS machine_health_monitoring;
USE machine_health_monitoring;

SET FOREIGN_KEY_CHECKS = 0;

-- ---------------------------------------------------------------------
-- 1. USER_ACCOUNT
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_account (
    id_user         INT AUTO_INCREMENT PRIMARY KEY,
    username        VARCHAR(255) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,     -- WAJIB di-hash (bcrypt/argon2) di app, jangan plaintext
    nama_lengkap    VARCHAR(255) NOT NULL,
    role_user       VARCHAR(50) NOT NULL DEFAULT 'teknisi',
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. STATION
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS station (
    id_station      INT AUTO_INCREMENT PRIMARY KEY,
    nama_station    VARCHAR(255) NOT NULL,
    lokasi_station  VARCHAR(255) NOT NULL,
    health_station  FLOAT DEFAULT 100,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. MACHINE
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS machine (
    id_mesin        INT AUTO_INCREMENT PRIMARY KEY,
    id_station      INT NOT NULL,
    nama_mesin      VARCHAR(255) NOT NULL,
    health_mesin    FLOAT DEFAULT 100,
    last_service    DATETIME,
    next_service    DATETIME,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_machine_station FOREIGN KEY (id_station)
        REFERENCES station (id_station)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 4. KOMPONEN (murni 1 komponen fisik, TIDAK terikat ke 1 parameter)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS komponen (
    id_komponen             INT AUTO_INCREMENT PRIMARY KEY,
    id_mesin                INT NOT NULL,
    nama_komponen            VARCHAR(255) NOT NULL,
    jenis_komponen            VARCHAR(255),      -- contoh: "Motor BLDC", "Baterai", "Bearing"
    lifetime                  FLOAT,
    remaining                  FLOAT,
    next_pm                    FLOAT,
    avg_health_all_parameter    FLOAT,
    last_service                 DATETIME,
    next_service                  DATETIME,
    created_at                     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_komponen_mesin FOREIGN KEY (id_mesin)
        REFERENCES machine (id_mesin)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 5. PARAMETER (master jenis parameter, katalog global: suhu, rpm, volt, dst)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS parameter (
    id_parameter    INT AUTO_INCREMENT PRIMARY KEY,
    nama_parameter  VARCHAR(255) NOT NULL UNIQUE,
    satuan          VARCHAR(50),
    nilai_min       FLOAT,          -- default global, bisa di-override per komponen
    nilai_max       FLOAT,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 6. KOMPONEN_PARAMETER (parameter apa aja yang dipantau di 1 komponen)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS komponen_parameter (
    id_komponen_parameter   INT AUTO_INCREMENT PRIMARY KEY,
    id_komponen              INT NOT NULL,
    id_parameter               INT NOT NULL,
    nilai_min_override           FLOAT,      -- NULL = pakai default dari tabel parameter
    nilai_max_override            FLOAT,
    is_active                      BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_komponenparam_komponen FOREIGN KEY (id_komponen)
        REFERENCES komponen (id_komponen)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_komponenparam_parameter FOREIGN KEY (id_parameter)
        REFERENCES parameter (id_parameter)
        ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY uq_komponen_parameter (id_komponen, id_parameter)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 7. SENSOR_READING (time-series, histori tiap pembacaan sensor)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sensor_reading (
    id_reading      BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_komponen     INT NOT NULL,
    id_parameter    INT NOT NULL,
    id_service      INT DEFAULT NULL,
    nilai           FLOAT NOT NULL,
    recorded_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_reading_komponen FOREIGN KEY (id_komponen)
        REFERENCES komponen (id_komponen)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_reading_parameter FOREIGN KEY (id_parameter)
        REFERENCES parameter (id_parameter)
        ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_reading_komponen_param_time (id_komponen, id_parameter, recorded_at)
) ENGINE=InnoDB;
-- Catatan production: kalau volume data tinggi (banyak sensor, sampling rate cepat),
-- pertimbangkan PARTITION BY RANGE(recorded_at) per bulan, atau pindahkan data lama
-- ke tabel arsip / time-series DB (InfluxDB, TimescaleDB) kalau MySQL mulai berat.

-- ---------------------------------------------------------------------
-- 8. ALERT_RULE (custom rule per parameter, bisa spesifik per komponen)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS alert_rule (
    id_rule         INT AUTO_INCREMENT PRIMARY KEY,
    id_parameter    INT NOT NULL,
    id_komponen     INT,                -- NULL = berlaku general ke semua komponen dgn parameter ini
    created_by      INT NOT NULL,
    operator        ENUM('>', '<', '>=', '<=', 'between', 'outside') NOT NULL,
    nilai_batas_1   FLOAT NOT NULL,
    nilai_batas_2   FLOAT,
    severity        ENUM('low', 'medium', 'high', 'critical') NOT NULL DEFAULT 'medium',
    pesan_custom    VARCHAR(255),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_rule_parameter FOREIGN KEY (id_parameter)
        REFERENCES parameter (id_parameter)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_rule_komponen FOREIGN KEY (id_komponen)
        REFERENCES komponen (id_komponen)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_rule_user FOREIGN KEY (created_by)
        REFERENCES user_account (id_user)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_rule_parameter_active (id_parameter, is_active)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 9. SERVICE_ALERT (kejadian alert aktual)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS service_alert (
    id_alert        INT AUTO_INCREMENT PRIMARY KEY,
    id_mesin        INT NOT NULL,
    id_komponen     INT NOT NULL,
    id_rule         INT,
    id_reading      BIGINT,             -- reading spesifik yang men-trigger alert ini
    description     VARCHAR(255),
    status          VARCHAR(50) NOT NULL DEFAULT 'open',   -- open / acknowledged / resolved
    nilai_terdeteksi FLOAT,
    severity        ENUM('low', 'medium', 'high', 'critical') NOT NULL DEFAULT 'medium',
    is_resolved     BOOLEAN NOT NULL DEFAULT FALSE,
    resolved_by     INT,
    resolved_at     DATETIME,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_alert_mesin FOREIGN KEY (id_mesin)
        REFERENCES machine (id_mesin)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_alert_komponen FOREIGN KEY (id_komponen)
        REFERENCES komponen (id_komponen)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_alert_rule FOREIGN KEY (id_rule)
        REFERENCES alert_rule (id_rule)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_alert_reading FOREIGN KEY (id_reading)
        REFERENCES sensor_reading (id_reading)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_alert_resolver FOREIGN KEY (resolved_by)
        REFERENCES user_account (id_user)
        ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_alert_mesin_status (id_mesin, status),
    INDEX idx_alert_komponen_open (id_komponen, id_rule, status)
) ENGINE=InnoDB;
-- Catatan dedup: sebelum INSERT alert baru, app HARUS cek dulu apakah masih ada
-- row dengan (id_komponen, id_rule, status='open') -- kalau ada, jangan insert baru,
-- cukup update kolom updated_at / nilai_terdeteksi di row yang sudah ada.

-- ---------------------------------------------------------------------
-- 10. SERVICE_HISTORY
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS service_history (
    id_service          INT AUTO_INCREMENT PRIMARY KEY,
    id_user              INT NOT NULL,
    id_station            INT NOT NULL,
    id_mesin                INT NOT NULL,
    id_komponen               INT,
    service_type               ENUM('preventive', 'corrective', 'calibration', 'inspection') NOT NULL,
    description                  VARCHAR(255),
    health_mesin_before            FLOAT,
    health_mesin_after               FLOAT,
    service_date                       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    next_service_date                    DATETIME,
    created_at                             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                               DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_servicehistory_user FOREIGN KEY (id_user)
        REFERENCES user_account (id_user)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_servicehistory_station FOREIGN KEY (id_station)
        REFERENCES station (id_station)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_servicehistory_mesin FOREIGN KEY (id_mesin)
        REFERENCES machine (id_mesin)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_servicehistory_komponen FOREIGN KEY (id_komponen)
        REFERENCES komponen (id_komponen)
        ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_servicehistory_mesin_date (id_mesin, service_date)
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================
-- SEED DATA CONTOH (opsional, hapus kalau tidak perlu)
-- =====================================================================

INSERT INTO user_account (username, password_hash, nama_lengkap, role_user) VALUES
('admin', '$2b$12$contohHashBcryptDisiniYaBukanPlaintext', 'Alex', 'admin'),
('teknisi01', '$2b$12$contohHashBcryptDisiniYaBukanPlaintext', 'Budi Santoso', 'teknisi');

INSERT INTO station (nama_station, lokasi_station, health_station) VALUES
('Station A', 'Gedung 1 Lantai 2', 95);

INSERT INTO machine (id_station, nama_mesin, health_mesin) VALUES
(1, 'Mesin Conveyor 1', 98);

INSERT INTO komponen (id_mesin, nama_komponen, jenis_komponen, lifetime, remaining, avg_health_all_parameter) VALUES
(1, 'Motor Kiri', 'Motor BLDC', 10000, 8200, 92);

INSERT INTO parameter (nama_parameter, satuan, nilai_min, nilai_max) VALUES
('suhu', '°C', 20, 70),
('vibrasi', 'mm/s', 0, 4.5),
('rpm', 'RPM', 0, 5000);

-- Daftarin parameter mana aja yang dipantau di komponen "Motor Kiri"
INSERT INTO komponen_parameter (id_komponen, id_parameter) VALUES
(1, 1),  -- suhu
(1, 3);  -- rpm

-- Contoh histori pembacaan sensor
INSERT INTO sensor_reading (id_komponen, id_parameter, nilai) VALUES
(1, 1, 42.5),
(1, 3, 3200);

-- Rule custom: suhu motor kiri kalau > 75 derajat, alert critical
INSERT INTO alert_rule (id_parameter, id_komponen, created_by, operator, nilai_batas_1, severity, pesan_custom, is_active) VALUES
(1, 1, 1, '>', 75, 'critical', 'Suhu motor kiri overheat, cek segera!', TRUE);
