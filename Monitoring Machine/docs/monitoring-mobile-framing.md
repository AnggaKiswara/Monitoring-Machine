-- Migration: monitoring tables untuk manual input monitoring session
-- Dibuat: 2026-07-22

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS `monitoring_session` (
  `id_session` BIGINT NOT NULL AUTO_INCREMENT,
  `id_mesin` INT NOT NULL,
  `hm` FLOAT DEFAULT NULL,
  `rpm` FLOAT DEFAULT NULL,
  `remarks` VARCHAR(400) DEFAULT NULL,
  `recorded_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_session`),
  KEY `idx_monitoringsession_machine_time` (`id_mesin`,`recorded_at`),
  CONSTRAINT `fk_monitoringsession_machine` FOREIGN KEY (`id_mesin`) REFERENCES `machine` (`id_mesin`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `monitoring_reading` (
  `id_reading` BIGINT NOT NULL AUTO_INCREMENT,
  `id_session` BIGINT NOT NULL,
  `id_parameter` INT NOT NULL,
  `nilai` FLOAT NOT NULL,
  `status` VARCHAR(20) NOT NULL DEFAULT 'Good',
  PRIMARY KEY (`id_reading`),
  KEY `idx_monitoringreading_session_param` (`id_session`,`id_parameter`),
  CONSTRAINT `fk_monitoringreading_session` FOREIGN KEY (`id_session`) REFERENCES `monitoring_session` (`id_session`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_monitoringreading_parameter` FOREIGN KEY (`id_parameter`) REFERENCES `parameter` (`id_parameter`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;
