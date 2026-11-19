-- 1. Desactivar comprobación de claves ajenas para permitir el borrado
USE hospital_surgery_db

SET FOREIGN_KEY_CHECKS = 0;

-- 2. Borrar todas las tablas en orden
DROP TABLE IF EXISTS surgical_report_versions;
DROP TABLE IF EXISTS surgical_reports;
DROP TABLE IF EXISTS operation_team;
DROP TABLE IF EXISTS schedule;
DROP TABLE IF EXISTS operation_costs;
DROP TABLE IF EXISTS operation_images;
DROP TABLE IF EXISTS surgical_operations;
DROP TABLE IF EXISTS procedures;
DROP TABLE IF EXISTS surgical_complications;

DROP TABLE IF EXISTS operating_rooms;
DROP TABLE IF EXISTS system_users;
DROP TABLE IF EXISTS professionals;

-- 3. Volver a activar las restricciones
SET FOREIGN_KEY_CHECKS = 1;
CREATE TABLE professionals (
    id_professional INT AUTO_INCREMENT PRIMARY KEY,
    professional_name VARCHAR(150) NOT NULL,
    professional_type VARCHAR(30) NOT NULL,
    professional_category VARCHAR(30) NOT NULL,
    professional_email VARCHAR(255) UNIQUE,
    professional_phone VARCHAR(25),

    CONSTRAINT chk_professional_type CHECK (
        professional_type IN ('surgery', 'anaesthesia', 'nursing')
    ),

    CONSTRAINT chk_professional_category CHECK (
        professional_category IN ('Resident', 'Specialist', 'Consultant')
    )
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE surgical_operations (
    id_operation INT AUTO_INCREMENT PRIMARY KEY,

    patient_id VARCHAR(50) NOT NULL,
    episode_id VARCHAR(50) NOT NULL,

    id_room INT,
    id_procedure INT,

    actual_surgery_start DATETIME,
    actual_surgery_end DATETIME,

    actual_room_start DATETIME,
    actual_room_end DATETIME,

    status_so VARCHAR(30) NOT NULL,

    CONSTRAINT fk_surgical_ops_room
        FOREIGN KEY (id_room)
        REFERENCES operating_rooms(id_room)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT fk_surgical_ops_procedure
        FOREIGN KEY (id_procedure)
        REFERENCES procedures(id_procedure)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT chk_status_so CHECK (
        status_so IN ('scheduled', 'in_progress', 'completed', 'cancelled')
    ),

    CONSTRAINT chk_surgery_times CHECK (
        actual_surgery_start IS NULL
        OR actual_surgery_end IS NULL
        OR actual_surgery_end > actual_surgery_start
    ),

    CONSTRAINT chk_room_times CHECK (
        actual_room_start IS NULL
        OR actual_room_end IS NULL
        OR actual_room_end > actual_room_start
    ),

    CONSTRAINT chk_completed_times CHECK (
        status_so != 'completed'
        OR (
            actual_surgery_start IS NOT NULL
            AND actual_surgery_end IS NOT NULL
            AND actual_room_start IS NOT NULL
            AND actual_room_end IS NOT NULL
        )
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE schedule (
    id_schedule INT AUTO_INCREMENT PRIMARY KEY,

    id_operation INT NOT NULL,
    id_room INT NOT NULL,

    scheduled_surgery_start DATETIME NOT NULL,
    scheduled_surgery_end DATETIME NOT NULL,

    scheduled_room_start DATETIME NOT NULL,
    scheduled_room_end DATETIME NOT NULL,

    status_s VARCHAR(30) NOT NULL,
    rescheduled_from INT NULL,

    CONSTRAINT chk_status_s CHECK (
        status_s IN ('scheduled', 'confirmed', 'cancelled', 'rescheduled', 'completed')
    ),

    CONSTRAINT fk_schedule_operation
        FOREIGN KEY (id_operation)
        REFERENCES surgical_operations(id_operation)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_schedule_room
        FOREIGN KEY (id_room)
        REFERENCES operating_rooms(id_room)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_schedule_rescheduled_from
        FOREIGN KEY (rescheduled_from)
        REFERENCES schedule(id_schedule)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT chk_scheduled_surgery_times CHECK (
        scheduled_surgery_end > scheduled_surgery_start
    ),

    CONSTRAINT chk_scheduled_room_times CHECK (
        scheduled_room_end > scheduled_room_start
    ),

    CONSTRAINT chk_scheduled_room_vs_surgery CHECK (
        scheduled_room_start <= scheduled_surgery_start
        AND scheduled_room_end >= scheduled_surgery_end
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE operation_team (
    id_operation_team INT AUTO_INCREMENT PRIMARY KEY,

    id_operation INT NOT NULL,
    id_professional INT NOT NULL,

    role_in_operation VARCHAR(30) NOT NULL,

    CONSTRAINT chk_role_in_operation CHECK (
        role_in_operation IN (
            'surgeon',
            'assistant_surgeon',
            'anaesthesiologist',
            'nurse'
        )
    ),

    CONSTRAINT fk_op_team_operation
        FOREIGN KEY (id_operation)
        REFERENCES surgical_operations(id_operation)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_op_team_professional
        FOREIGN KEY (id_professional)
        REFERENCES professionals(id_professional)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE operation_costs (
    id_operation_cost INT AUTO_INCREMENT PRIMARY KEY,

    id_operation INT NOT NULL,

    cost_concept VARCHAR(30) NOT NULL
        CHECK (cost_concept IN (
            'procedure',
            'operating room',
            'anaesthesia',
            'materials',
            'service'
        )),

    billing_unit VARCHAR(20) NOT NULL
        CHECK (billing_unit IN (
            'fixed',
            'per minute',
            'per day'
        )),

    quantity DECIMAL(10, 2) NOT NULL
        CHECK (quantity > 0),

    unit_price DECIMAL(10, 2) NOT NULL
        CHECK (unit_price >= 0),

    CONSTRAINT fk_op_costs_operation
        FOREIGN KEY (id_operation)
        REFERENCES surgical_operations(id_operation)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 

CREATE TABLE surgical_complications (
    id_complication INT AUTO_INCREMENT PRIMARY KEY,

    id_operation INT NOT NULL,

    complication_type VARCHAR(100) NOT NULL,
    detection_date DATETIME NOT NULL,
    description TEXT,

    severity VARCHAR(20)
        CHECK (severity IN (
            'mild',
            'moderate',
            'severe',
            'critical'
        )),

    status_sc VARCHAR(30) NOT NULL
        CHECK (status_sc IN (
            'active',
            'under treatment',
            'resolved'
        )),

    CONSTRAINT fk_complications_operation
        FOREIGN KEY (id_operation)
        REFERENCES surgical_operations(id_operation)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE surgical_reports (
    id_report INT AUTO_INCREMENT PRIMARY KEY,
    id_operation INT NOT NULL UNIQUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    current_version INT,
    status_r VARCHAR(30) NOT NULL,

    CONSTRAINT chk_status_r CHECK (
        status_r IN ('draft', 'completed', 'approved')
    ),

    CONSTRAINT chk_report_version CHECK (
        current_version IS NULL
        OR current_version >= 1
    ),

    CONSTRAINT fk_reports_operation
        FOREIGN KEY (id_operation)
        REFERENCES surgical_operations(id_operation)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE surgical_report_versions (
    id_report_version INT AUTO_INCREMENT PRIMARY KEY,
    id_report INT NOT NULL,
    version_number INT NOT NULL,
    id_professional INT NOT NULL,
    report_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    report_content TEXT,

    CONSTRAINT fk_report_versions_report
        FOREIGN KEY (id_report)
        REFERENCES surgical_reports(id_report)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_report_versions_professional
        FOREIGN KEY (id_professional)
        REFERENCES professionals(id_professional)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE operation_images (
    id_image INT AUTO_INCREMENT PRIMARY KEY,

    id_operation INT NOT NULL,
    id_complication INT,
    id_professional INT NOT NULL,

    image_path VARCHAR(500) NOT NULL,
    image_date DATETIME NOT NULL,
    upload_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    description TEXT,

    file_type VARCHAR(10) NOT NULL
        CHECK (file_type IN (
            'jpg',
            'jpeg',
            'png'
        )),

    CONSTRAINT fk_op_images_operation
        FOREIGN KEY (id_operation)
        REFERENCES surgical_operations(id_operation)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_op_images_complication
        FOREIGN KEY (id_complication)
        REFERENCES surgical_complications(id_complication)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT fk_op_images_professional
        FOREIGN KEY (id_professional)
        REFERENCES professionals(id_professional)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE checklist (
    id_checklist INT AUTO_INCREMENT PRIMARY KEY,
    id_operation INT NOT NULL,
    checklist_item VARCHAR(255) NOT NULL,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    completed_by INT NULL,
    completion_date DATETIME NULL,

    CONSTRAINT fk_checklist_operation
        FOREIGN KEY (id_operation) REFERENCES surgical_operations(id_operation),

    CONSTRAINT fk_checklist_completed_by
        FOREIGN KEY (completed_by) REFERENCES professionals(id_professional),

    CONSTRAINT chk_checklist_completed_fields
        CHECK (
            is_completed = FALSE
            OR (completed_by IS NOT NULL AND completion_date IS NOT NULL)
        )
        
);
CREATE TABLE professional_audit_log (
    id_audit INT AUTO_INCREMENT PRIMARY KEY,
    id_professional INT NOT NULL,
    action_type VARCHAR(100) NOT NULL,
    target_table VARCHAR(100) NOT NULL,
    target_id INT NULL,
    request_summary TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_audit_professional
        FOREIGN KEY (id_professional) REFERENCES professionals(id_professional)
);

CREATE TABLE interconsultations (
    id_interconsultation INT AUTO_INCREMENT PRIMARY KEY,
    id_operation INT NULL,
    requesting_professional INT NOT NULL,
    requested_specialty VARCHAR(150) NOT NULL,
    request_date DATETIME NOT NULL,
    reason TEXT NOT NULL,
    status_ic VARCHAR(20) NOT NULL DEFAULT 'Pending',
    response_date DATETIME NULL,
    response TEXT NULL,

    CONSTRAINT fk_interconsultations_operation
        FOREIGN KEY (id_operation) REFERENCES surgical_operations(id_operation),

    CONSTRAINT fk_interconsultations_professional
        FOREIGN KEY (requesting_professional) REFERENCES professionals(id_professional),

    CONSTRAINT chk_interconsultations_status
        CHECK (status_ic IN ('Pending', 'accepted', 'completed', 'cancelled'))
);