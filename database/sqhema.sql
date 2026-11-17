-- Database creation for Surgery Module
CREATE DATABASE IF NOT EXISTS surgery_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE surgery_db;

-- 1. MASTER TABLES

CREATE TABLE professionals (
    id_professional INT AUTO_INCREMENT PRIMARY KEY,
    professional_name VARCHAR(100) NOT NULL,
    professional_type ENUM('surgery', 'anaesthesia', 'nursing') NOT NULL,
    professional_category ENUM('Resident', 'Specialist', 'Consultant') NOT NULL,
    professional_email VARCHAR(100) UNIQUE,
    professional_phone VARCHAR(20)
) ENGINE=InnoDB;

CREATE TABLE operating_rooms (
    id_room INT AUTO_INCREMENT PRIMARY KEY,
    room_code VARCHAR(50) NOT NULL UNIQUE,
    room_name VARCHAR(100) NOT NULL,
    room_location VARCHAR(150) NOT NULL,
    room_type ENUM('urgent', 'programmed', 'hybrid') NOT NULL,
    room_state ENUM('available', 'occupied', 'blocked', 'maintenance') NOT NULL
) ENGINE=InnoDB;

CREATE TABLE system_users (
    id_user INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    user_email VARCHAR(100) NOT NULL UNIQUE,
    user_role ENUM(
        'surgeon',
        'head of surgery',
        'financial administrator',
        'scheduler'
    ) NOT NULL,
    id_professional INT UNIQUE,
    FOREIGN KEY (id_professional)
        REFERENCES professionals(id_professional)
        ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE procedures (
    id_procedure INT AUTO_INCREMENT PRIMARY KEY,
    procedure_code VARCHAR(50) NOT NULL UNIQUE,
    procedure_name VARCHAR(200) NOT NULL
) ENGINE=InnoDB;

