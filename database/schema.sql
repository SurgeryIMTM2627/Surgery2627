-- 1. Desactivar comprobación de claves ajenas para permitir el borrado
USE hospital_surgery_db

SET FOREIGN_KEY_CHECKS = 0;

-- 2. Borrar todas las tablas en orden
DROP TABLE IF EXISTS professionals;
DROP TABLE IF EXISTS system_users;
DROP TABLE IF EXISTS operating_rooms;
DROP TABLE IF EXISTS procedures;
DROP TABLE IF EXISTS surgical_report_versions;
DROP TABLE IF EXISTS surgical_reports;
DROP TABLE IF EXISTS operation_team;
DROP TABLE IF EXISTS schedule;
DROP TABLE IF EXISTS operation_costs;
DROP TABLE IF EXISTS operation_images;
DROP TABLE IF EXISTS surgical_operations;
DROP TABLE IF EXISTS surgical_complications;
DROP TABLE IF EXISTS checklist;
DROP TABLE IF EXISTS interconsultations;
DROP TABLE IF EXISTS professional_audit_log;

-- 3. Volver a activar las restricciones
SET FOREIGN_KEY_CHECKS = 1;
CREATE TABLE operating_rooms (
    id_operating_room INT AUTO_INCREMENT PRIMARY KEY,
    room_code VARCHAR(50) NOT NULL UNIQUE,
        CHECK (room_code IN ('OR-URG-01', 'OR-URG-02', 'OR-URG-03', 'OR-PROG-01', 'OR-PROG-02', 'OR-PROG-03', 'OR-PROG-04', 'OR-PROG-05', 'OR-HYB-01')),
    room_name VARCHAR(100) NOT NULL,
    room_type VARCHAR(30) NOT NULL
        CHECK (room_type IN ('urgent', 'programmed', 'hybrid')),
    room_state VARCHAR(30) NOT NULL
        CHECK (room_state IN ('available', 'not available'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE surgical_operations (
    id_operation INT AUTO_INCREMENT PRIMARY KEY,
    id_patient INT NOT NULL,
    id_episode INT NOT NULL,
    id_operating_room INT NOT NULL,
    parent_operation_id INT NULL,
    procedure_code VARCHAR(30) NULL,
    procedure_name VARCHAR(255) NOT NULL,
    diagnosis_icd10 VARCHAR(20) NULL,
    priority_level ENUM('Life_threatening', 'Urgent', 'Scheduled') NOT NULL DEFAULT 'Urgent',
    operation_status ENUM('Scheduled', 'In_progress', 'Completed', 'Rescheduled', 'Cancelled') NOT NULL DEFAULT 'Scheduled',
    scheduled_start DATETIME NULL,
    scheduled_end DATETIME NULL,
    room_entry_at DATETIME NULL,
    surgery_start_at DATETIME NULL,
    surgery_end_at DATETIME NULL,
    room_exit_at DATETIME NULL,
    reschedule_reason TEXT NULL,
    surgical_report TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_operations_patient (id_patient),
    INDEX idx_operations_episode (id_episode),

    CONSTRAINT fk_operations_room
        FOREIGN KEY (id_operating_room) REFERENCES operating_rooms(id_operating_room)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_operations_parent
        FOREIGN KEY (parent_operation_id) REFERENCES surgical_operations(id_operation)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT chk_operations_real_times
        CHECK (
            (room_entry_at IS NULL OR room_exit_at IS NULL OR room_exit_at >= room_entry_at)
            AND (surgery_start_at IS NULL OR surgery_end_at IS NULL OR surgery_end_at >= surgery_start_at)
        )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE operation_team (
    id_operation_team INT AUTO_INCREMENT PRIMARY KEY,
    id_operation INT NOT NULL,
    id_professional INT NOT NULL,
    team_role ENUM('Surgeon', 'Anaesthetist', 'Scrub_nurse', 'Circulating_nurse', 'Nursing_assistant', 'Consultant') NOT NULL,
    is_lead BOOLEAN NOT NULL DEFAULT FALSE,

    CONSTRAINT fk_team_operation
        FOREIGN KEY (id_operation) REFERENCES surgical_operations(id_operation)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_team_professional
        FOREIGN KEY (id_professional) REFERENCES professionals(id_professional)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT uq_operation_professional_role
        UNIQUE (id_operation, id_professional, team_role)
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
    readmission_episode_id INT NULL,
    id_professional INT NULL,
    complication_code VARCHAR(20) NULL,
    complication_type VARCHAR(150) NOT NULL,
    severity ENUM('Mild', 'Moderate', 'Severe', 'Critical') NOT NULL DEFAULT 'Moderate',
    detected_at DATETIME NOT NULL,
    description TEXT NULL,

    CONSTRAINT fk_complications_operation
        FOREIGN KEY (id_operation) REFERENCES surgical_operations(id_operation)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_complications_professional
        FOREIGN KEY (id_professional) REFERENCES professionals(id_professional)
        ON DELETE SET NULL ON UPDATE CASCADE
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
    id_episode INT NOT NULL,
    id_operation INT NULL,
    requesting_professional INT NOT NULL,
    requesting_specialty VARCHAR(150) NOT NULL, -- ej. 'Urgencias', 'Medicina Interna', 'Cirugía General'
    requested_specialty VARCHAR(150) NOT NULL,  -- ej. 'Urología', 'Otorrinolaringología', 'Neurocirugía', 'Cirugía General'
    responding_professional INT NULL,
    request_date DATETIME NOT NULL,
    reason TEXT NOT NULL,
    status_ic VARCHAR(20) NOT NULL DEFAULT 'Pending',
    response_date DATETIME NULL,
    response TEXT NULL,

    CONSTRAINT fk_interconsultations_operation
        FOREIGN KEY (id_operation) REFERENCES surgical_operations(id_operation),

    CONSTRAINT fk_interconsultations_req_prof
        FOREIGN KEY (requesting_professional) REFERENCES professionals(id_professional),

    CONSTRAINT fk_interconsultations_resp_prof
        FOREIGN KEY (responding_professional) REFERENCES professionals(id_professional),

    CONSTRAINT chk_interconsultations_status
        CHECK (status_ic IN ('Pending', 'accepted', 'completed', 'cancelled'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

