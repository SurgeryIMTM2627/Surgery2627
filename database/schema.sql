CREATE TABLE professionals (
    id_professional INT AUTO_INCREMENT PRIMARY KEY,
    professional_name VARCHAR(150) NOT NULL,
    professional_type VARCHAR(30) NOT NULL
        CHECK (professional_type IN ('surgery', 'anaesthesia', 'nursing')),
    professional_category VARCHAR(30) NOT NULL
        CHECK (professional_category IN ('Resident', 'Specialist', 'Consultant')),
    professional_email VARCHAR(255) UNIQUE,
    professional_phone VARCHAR(25)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE operating_rooms (
    id_room INT AUTO_INCREMENT PRIMARY KEY,
    room_code VARCHAR(50) NOT NULL UNIQUE,
    room_name VARCHAR(100) NOT NULL,
    room_location VARCHAR(150) NOT NULL,
    room_type VARCHAR(30) NOT NULL
        CHECK (room_type IN ('urgent', 'programmed', 'hybrid')),
    room_state VARCHAR(30) NOT NULL
        CHECK (room_state IN ('available', 'occupied', 'blocked', 'maintenance'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE system_users (
    id_user INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    user_email VARCHAR(255) NOT NULL UNIQUE,
    user_role VARCHAR(50) NOT NULL
        CHECK (user_role IN (
            'surgeon',
            'head of surgery',
            'financial administrator',
            'scheduler'
        )),
    id_professional INT UNIQUE,
    CONSTRAINT fk_system_users_professional
        FOREIGN KEY (id_professional)
        REFERENCES professionals(id_professional)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE procedures (
    id_procedure INT AUTO_INCREMENT PRIMARY KEY,
    procedure_code VARCHAR(50) NOT NULL UNIQUE,
    procedure_name VARCHAR(200) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;-- TEST GITHUB SYNC
