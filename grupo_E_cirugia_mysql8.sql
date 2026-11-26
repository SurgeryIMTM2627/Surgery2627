-- ============================================================
-- GRUPO E - CIRUGIA
-- Script de creacion de tablas y datos de ejemplo (MySQL 8.0.16+)
--
-- IMPORTANTE:
-- 1) Este script NO crea comun_usuarios, pacientes, episodios ni
--    catalogos compartidos: deben existir previamente.
-- 2) Se asume que comun_usuarios.codigo_usuario es VARCHAR(6),
--    PRIMARY KEY o UNIQUE, y usa InnoDB.
-- 3) No se crean professionals, system_users, procedures ni schedule.
-- 4) Ejecutar en una base de datos de pruebas o vacia.
-- ============================================================

SET NAMES utf8mb4;

-- ============================================================
-- 1. OPERATING ROOMS
-- ============================================================

CREATE TABLE IF NOT EXISTS operating_rooms (
    id_OR INT NOT NULL AUTO_INCREMENT,
    room_code VARCHAR(50) NOT NULL,
    room_name VARCHAR(100) NOT NULL,
    room_type VARCHAR(30) NOT NULL,
    room_state VARCHAR(30) NOT NULL,
    PRIMARY KEY (id_OR),
    UNIQUE KEY uq_operating_rooms_code (room_code),
    CONSTRAINT chk_room_code CHECK (room_code IN (
        'OR-URG-01', 'OR-URG-02', 'OR-URG-03',
        'OR-PROG-01', 'OR-PROG-02', 'OR-PROG-03',
        'OR-PROG-04', 'OR-PROG-05', 'OR-HYB-01'
    )),
    CONSTRAINT chk_room_type CHECK (room_type IN ('Urgent', 'Programmed', 'Hybrid')),
    CONSTRAINT chk_room_state CHECK (room_state IN ('Available', 'Not available'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- 2. SURGICAL OPERATIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS surgical_operations (
    id_operation INT NOT NULL AUTO_INCREMENT,
    id_patient INT NOT NULL,
    id_episode INT NOT NULL,
    id_OR INT NOT NULL,
    parent_operation_id INT NULL,
    codigo_snomed VARCHAR(18) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL,
    priority_level VARCHAR(30) NOT NULL,
    operation_status VARCHAR(20) NOT NULL,
    created_at DATETIME NOT NULL,
    scheduled_start DATETIME NULL,
    scheduled_end DATETIME NULL,
    surgery_start_at DATETIME NULL,
    surgery_end_at DATETIME NULL,
    actual_room_start DATETIME NULL,
    actual_room_end DATETIME NULL,
    PRIMARY KEY (id_operation),
    KEY idx_surgical_operations_patient (id_patient),
    KEY idx_surgical_operations_episode (id_episode),
    KEY idx_surgical_operations_room (id_OR),
    KEY idx_surgical_operations_parent (parent_operation_id),
    CONSTRAINT fk_operation_room
        FOREIGN KEY (id_OR) REFERENCES operating_rooms (id_OR)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_parent_operation
        FOREIGN KEY (parent_operation_id) REFERENCES surgical_operations (id_operation)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_operation_priority CHECK (
        priority_level IN ('Life threatening', 'Urgent', 'Scheduled')
    ),
    CONSTRAINT chk_operation_status CHECK (
        operation_status IN ('Waiting', 'Scheduled', 'In_progress', 'Completed', 'Suspended', 'Cancelled')
    ),
    CONSTRAINT chk_scheduled_times CHECK (
        scheduled_end IS NULL OR scheduled_start IS NULL OR scheduled_end > scheduled_start
    ),
    CONSTRAINT chk_surgery_times CHECK (
        surgery_end_at IS NULL OR surgery_start_at IS NULL OR surgery_end_at > surgery_start_at
    ),
    CONSTRAINT chk_room_times CHECK (
        actual_room_end IS NULL OR actual_room_start IS NULL OR actual_room_end > actual_room_start
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Nota: id_patient, id_episode y codigo_snomed son referencias externas.
-- Añadir sus FOREIGN KEY cuando se conozcan los nombres y tipos exactos
-- de las tablas compartidas. El documento fuente indica que falta definir
-- la constraint de id_episode.


-- ============================================================
-- 3. OPERATION TEAM
-- ============================================================

CREATE TABLE IF NOT EXISTS operation_team (
    id_operation_team INT NOT NULL AUTO_INCREMENT,
    id_operation INT NOT NULL,
    codigo_usuario VARCHAR(6) NOT NULL,
    role_in_operation VARCHAR(100) NOT NULL,
    is_lead BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (id_operation_team),
    UNIQUE KEY uq_operation_user (id_operation, codigo_usuario),
    KEY idx_operation_team_user (codigo_usuario),
    CONSTRAINT fk_team_operation
        FOREIGN KEY (id_operation) REFERENCES surgical_operations (id_operation)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_team_user
        FOREIGN KEY (codigo_usuario) REFERENCES comun_usuarios (codigo_usuario)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- 4. OPERATION COSTS
-- ============================================================

CREATE TABLE IF NOT EXISTS operation_costs (
    id_operation_cost INT NOT NULL AUTO_INCREMENT,
    id_operation INT NOT NULL,
    cost_concept VARCHAR(100) NOT NULL,
    billing_unit VARCHAR(50) NOT NULL,
    quantity DECIMAL(10,2) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (id_operation_cost),
    KEY idx_operation_costs_operation (id_operation),
    CONSTRAINT fk_costs_operation
        FOREIGN KEY (id_operation) REFERENCES surgical_operations (id_operation)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_cost_concept CHECK (
        cost_concept IN ('Procedure', 'Operation room', 'Service', 'Materials')
    ),
    CONSTRAINT chk_billing_unit CHECK (
        billing_unit IN ('Fixed', 'Per unit', 'Per day', 'Per minute')
    ),
    CONSTRAINT chk_quantity CHECK (quantity > 0),
    CONSTRAINT chk_unit_price CHECK (unit_price > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- 5. SURGICAL COMPLICATIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS surgical_complications (
    id_complication INT NOT NULL AUTO_INCREMENT,
    id_operation INT NOT NULL,
    codigo_usuario VARCHAR(6) NOT NULL,
    readmision_episode_id INT NULL,
    complication_code VARCHAR(50) NULL,
    complication_type VARCHAR(100) NOT NULL,
    severity VARCHAR(20) NOT NULL DEFAULT 'moderate',
    detected_at DATETIME NOT NULL,
    description TEXT NULL,
    PRIMARY KEY (id_complication),
    KEY idx_complications_operation (id_operation),
    KEY idx_complications_user (codigo_usuario),
    CONSTRAINT fk_complication_operation
        FOREIGN KEY (id_operation) REFERENCES surgical_operations (id_operation)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_complication_user
        FOREIGN KEY (codigo_usuario) REFERENCES comun_usuarios (codigo_usuario)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_complication_severity CHECK (
        severity IN ('mild', 'moderate', 'severe', 'critical')
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- 6. SURGICAL REPORTS
-- ============================================================

CREATE TABLE IF NOT EXISTS surgical_reports (
    id_report INT NOT NULL AUTO_INCREMENT,
    id_operation INT NOT NULL,
    created_at DATETIME NOT NULL,
    current_version INT NOT NULL,
    status_r VARCHAR(20) NOT NULL,
    PRIMARY KEY (id_report),
    UNIQUE KEY uq_report_operation (id_operation),
    CONSTRAINT chk_report_current_version CHECK (current_version > 0),
    CONSTRAINT chk_report_status CHECK (status_r IN ('Draft', 'Signed', 'Amended')),
    CONSTRAINT fk_report_operation
        FOREIGN KEY (id_operation) REFERENCES surgical_operations (id_operation)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- 7. SURGICAL REPORT VERSIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS surgical_report_versions (
    id_report_version INT NOT NULL AUTO_INCREMENT,
    id_report INT NOT NULL,
    version_number INT NOT NULL,
    codigo_usuario VARCHAR(6) NOT NULL,
    report_date DATETIME NOT NULL,
    report_content TEXT NOT NULL,
    PRIMARY KEY (id_report_version),
    UNIQUE KEY uq_report_version (id_report, version_number),
    KEY idx_report_version_user (codigo_usuario),
    CONSTRAINT chk_version_number CHECK (version_number > 0),
    CONSTRAINT fk_report_version_report
        FOREIGN KEY (id_report) REFERENCES surgical_reports (id_report)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_report_version_user
        FOREIGN KEY (codigo_usuario) REFERENCES comun_usuarios (codigo_usuario)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- 8. OPERATION IMAGES
-- ============================================================

CREATE TABLE IF NOT EXISTS operation_images (
    id_image INT NOT NULL AUTO_INCREMENT,
    id_operation INT NOT NULL,
    id_complication INT NULL,
    codigo_usuario VARCHAR(6) NOT NULL,
    image_path VARCHAR(500) NOT NULL,
    image_date DATETIME NULL,
    upload_date DATETIME NOT NULL,
    description_images TEXT NULL,
    file_type VARCHAR(30) NOT NULL,
    PRIMARY KEY (id_image),
    KEY idx_operation_images_operation (id_operation),
    KEY idx_operation_images_complication (id_complication),
    KEY idx_operation_images_user (codigo_usuario),
    CONSTRAINT fk_image_operation
        FOREIGN KEY (id_operation) REFERENCES surgical_operations (id_operation)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_image_complication
        FOREIGN KEY (id_complication) REFERENCES surgical_complications (id_complication)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_image_user
        FOREIGN KEY (codigo_usuario) REFERENCES comun_usuarios (codigo_usuario)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- 9. CHECKLIST
-- ============================================================

CREATE TABLE IF NOT EXISTS checklist (
    id_checklist INT NOT NULL AUTO_INCREMENT,
    id_operation INT NOT NULL,
    checklist_item VARCHAR(255) NOT NULL,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    codigo_usuario VARCHAR(6) NULL,
    completion_date DATETIME NULL,
    PRIMARY KEY (id_checklist),
    KEY idx_checklist_operation (id_operation),
    KEY idx_checklist_user (codigo_usuario),
    CONSTRAINT chk_checklist_completion CHECK (
        is_completed = FALSE OR
        (codigo_usuario IS NOT NULL AND completion_date IS NOT NULL)
    ),
    CONSTRAINT fk_checklist_operation
        FOREIGN KEY (id_operation) REFERENCES surgical_operations (id_operation)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_checklist_user
        FOREIGN KEY (codigo_usuario) REFERENCES comun_usuarios (codigo_usuario)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- 10. SURGICAL INTERCONSULTATIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS sur_interconsultations (
    id_interconsultation INT NOT NULL AUTO_INCREMENT,
    id_operation INT NULL,
    requesting_user VARCHAR(6) NOT NULL,
    requested_specialty VARCHAR(150) NOT NULL,
    responding_user VARCHAR(6) NULL,
    request_date DATETIME NOT NULL,
    reason TEXT NOT NULL,
    status_ic VARCHAR(20) NOT NULL DEFAULT 'Pending',
    response_date DATETIME NULL,
    response TEXT NULL,
    PRIMARY KEY (id_interconsultation),
    KEY idx_sur_ic_operation (id_operation),
    KEY idx_sur_ic_requesting_user (requesting_user),
    KEY idx_sur_ic_responding_user (responding_user),
    CONSTRAINT chk_sur_ic_status CHECK (
        status_ic IN ('Pending', 'accepted', 'completed', 'cancelled')
    ),
    CONSTRAINT fk_sur_ic_operation
        FOREIGN KEY (id_operation) REFERENCES surgical_operations (id_operation)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_sur_ic_req_user
        FOREIGN KEY (requesting_user) REFERENCES comun_usuarios (codigo_usuario)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_sur_ic_resp_user
        FOREIGN KEY (responding_user) REFERENCES comun_usuarios (codigo_usuario)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- 11. OPERATION RESCHEDULES
-- ============================================================

CREATE TABLE IF NOT EXISTS operation_reschedules (
    id_reschedule INT NOT NULL AUTO_INCREMENT,
    id_operation INT NOT NULL,
    previous_room_id INT NOT NULL,
    new_room_id INT NOT NULL,
    previous_start DATETIME NOT NULL,
    previous_end DATETIME NOT NULL,
    new_start DATETIME NOT NULL,
    new_end DATETIME NOT NULL,
    reason_code VARCHAR(50) NOT NULL,
    reason_text TEXT NULL,
    displaced_by_operation_id INT NULL,
    decided_by VARCHAR(6) NOT NULL,
    decided_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_reschedule),
    KEY idx_reschedules_operation (id_operation),
    KEY idx_reschedules_displaced_by (displaced_by_operation_id),
    KEY idx_reschedules_prev_room (previous_room_id),
    KEY idx_reschedules_new_room (new_room_id),
    KEY idx_reschedules_decided_by (decided_by),
    CONSTRAINT chk_reschedules_reason_code CHECK (
        reason_code IN (
            'higher_priority_case',
            'patient_not_ready',
            'resource_unavailable',
            'clinical_decision',
            'other'
        )
    ),
    CONSTRAINT chk_reschedules_times CHECK (
        previous_end > previous_start AND new_end > new_start
    ),
    CONSTRAINT fk_reschedules_operation
        FOREIGN KEY (id_operation) REFERENCES surgical_operations (id_operation)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_reschedules_displaced_by
        FOREIGN KEY (displaced_by_operation_id) REFERENCES surgical_operations (id_operation)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_reschedules_prev_room
        FOREIGN KEY (previous_room_id) REFERENCES operating_rooms (id_OR)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_reschedules_new_room
        FOREIGN KEY (new_room_id) REFERENCES operating_rooms (id_OR)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_reschedules_decided_by
        FOREIGN KEY (decided_by) REFERENCES comun_usuarios (codigo_usuario)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- 12. SURGERY AUDIT LOG
-- ============================================================

CREATE TABLE IF NOT EXISTS sur_auditory_log (
    id_audit INT NOT NULL AUTO_INCREMENT,
    codigo_usuario VARCHAR(6) NOT NULL,
    action_type VARCHAR(100) NOT NULL,
    target_table VARCHAR(100) NOT NULL,
    target_id INT NULL,
    request_summary TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_audit),
    KEY idx_audit_user (codigo_usuario),
    KEY idx_audit_target (target_table, target_id),
    KEY idx_audit_created_at (created_at),
    CONSTRAINT fk_sur_audit_user
        FOREIGN KEY (codigo_usuario) REFERENCES comun_usuarios (codigo_usuario)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- DATOS DE EJEMPLO
-- Estos INSERT requieren que UE02 y UE03 existan en comun_usuarios.
-- ============================================================

INSERT INTO operating_rooms (room_code, room_name, room_type, room_state)
VALUES
    ('OR-URG-01', 'Urgent OR 01', 'Urgent', 'Available'),
    ('OR-PROG-01', 'Programmed OR 01', 'Programmed', 'Available'),
    ('OR-PROG-02', 'Programmed OR 02', 'Programmed', 'Available');


-- Ejemplo de operación. Se omite el codigo_snomed porque el código
-- del ejemplo anterior no estaba identificado como SNOMED en el documento.
INSERT INTO surgical_operations (
    id_patient,
    id_episode,
    id_OR,
    parent_operation_id,
    codigo_snomed,
    priority_level,
    operation_status,
    created_at,
    scheduled_start,
    scheduled_end,
    surgery_start_at,
    surgery_end_at,
    actual_room_start,
    actual_room_end
) VALUES (
    101,
    201,
    1,
    NULL,
    NULL,
    'Urgent',
    'Completed',
    '2026-11-21 08:30:00',
    '2026-11-21 09:00:00',
    '2026-11-21 10:45:00',
    '2026-11-21 09:25:00',
    '2026-11-21 10:20:00',
    '2026-11-21 09:05:00',
    '2026-11-21 10:40:00'
);


INSERT INTO operation_team (
    id_operation,
    codigo_usuario,
    role_in_operation,
    is_lead
) VALUES
    (1, 'UE02', 'Main surgeon', TRUE),
    (1, 'UE03', 'Assistant surgeon', FALSE);


INSERT INTO operation_costs (
    id_operation,
    cost_concept,
    billing_unit,
    quantity,
    unit_price
) VALUES
    (1, 'Operation room', 'Per minute', 95.00, 14.50),
    (1, 'Materials', 'Fixed', 1.00, 385.00);


INSERT INTO surgical_reports (
    id_operation,
    created_at,
    current_version,
    status_r
) VALUES (
    1,
    '2026-11-21 10:25:00',
    1,
    'Signed'
);


INSERT INTO surgical_report_versions (
    id_report,
    version_number,
    codigo_usuario,
    report_date,
    report_content
) VALUES (
    1,
    1,
    'UE02',
    '2026-11-21 10:25:00',
    'Apendicectomía laparoscópica urgente sin incidencias intraoperatorias. Apéndice flemonoso, lavado de cavidad y traslado a reanimación estable.'
);


INSERT INTO checklist (
    id_operation,
    checklist_item,
    is_completed,
    codigo_usuario,
    completion_date
) VALUES
    (1, 'Patient identity verified', TRUE, 'UE02', '2026-11-21 09:10:00'),
    (1, 'Antibiotic prophylaxis administered before incision', TRUE, 'UE02', '2026-11-21 09:15:00'),
    (1, 'Surgical instrument and swab count correct at completion', TRUE, 'UE02', '2026-11-21 10:22:00');


INSERT INTO sur_auditory_log (
    codigo_usuario,
    action_type,
    target_table,
    target_id,
    request_summary,
    created_at
) VALUES (
    'UE02',
    'CREATE_OPERATION',
    'surgical_operations',
    1,
    'Registro de apendicectomía laparoscópica urgente (operación 1, episodio 201).',
    '2026-11-21 08:30:00'
);

-- No se inserta ninguna fila en surgical_complications:
-- el caso de ejemplo indica que no hubo complicaciones.
