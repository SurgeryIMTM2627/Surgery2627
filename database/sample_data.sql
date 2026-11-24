
-- 1. Desactivar claves ajenas y vaciar todas las tablas antes de insertar
SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE surgical_report_versions;
TRUNCATE TABLE surgical_reports;
TRUNCATE TABLE operation_team;
TRUNCATE TABLE schedule;
TRUNCATE TABLE operation_costs;
TRUNCATE TABLE operation_images;
TRUNCATE TABLE surgical_operations;
TRUNCATE TABLE procedures;
TRUNCATE TABLE operating_rooms;
TRUNCATE TABLE system_users;
TRUNCATE TABLE professionals;
TRUNCATE TABLE surgical_operations;

SET FOREIGN_KEY_CHECKS = 1;

INSERT INTO operationg 
  (room_code, room_name, room_type, room_state)
VALUES
  ('OR-URG-01', 'Urgent OR 01', 'Urgent', 'available'),
  ('OR-PROG-01', 'Programmed OR 01', 'Programmed', 'available'),
  ('OR-PROG-02', 'Programmed OR 02', 'Programmed', 'available');

-- 2. A partir de aquí, tus sentencias INSERT INTO
INSERT INTO surgical_operations (
    id_patient,
    id_episode,
    id_operating_room,
    parent_operation_id,
    procedure_code,
    procedure_name,
    diagnosis_icd10,
    priority_level,
    operation_status,
    scheduled_start,
    scheduled_end,
    room_entry_at,
    surgery_start_at,
    surgery_end_at,
    room_exit_at,
    reschedule_reason,
    surgical_report,
    created_at
) VALUES (
    101,
    201,
    1,
    NULL,
    '0DTJ4ZZ',
    'Laparoscopic appendectomy',
    'K35.80',
    'Urgent',
    'Completed',
    '2026-11-21 09:00:00',
    '2026-11-21 10:45:00',
    '2026-11-21 09:05:00',
    '2026-11-21 09:25:00',
    '2026-11-21 10:20:00',
    '2026-11-21 10:40:00',
    NULL,
    'Urgent laparoscopic appendectomy performed without intraoperative complications. Phlegmonous appendix resected, peritoneal cavity lavaged, and patient transferred to recovery in stable condition.',
    '2026-11-21 08:30:00'
);

CREATE TABLE professionals (
    id_professional INT AUTO_INCREMENT PRIMARY KEY,
    user_code VARCHAR(20) NOT NULL UNIQUE,
    username VARCHAR(50) NOT NULL UNIQUE,
    professional_name VARCHAR(150) NOT NULL,
    module_group VARCHAR(10) NOT NULL,
    profile_role VARCHAR(50) NOT NULL,
    professional_type VARCHAR(50) NOT NULL,
    job_title VARCHAR(150) NOT NULL,
    license_number VARCHAR(30) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO professionals (
    user_code,
    username,
    professional_name,
    module_group,
    profile_role,
    professional_type,
    job_title,
    license_number
) VALUES
    ('UA01', 'nsoler', 'Núria Soler Ferrer', 'A', 'operativo', 'administrativo', 'Administrativa de admisión de Urgencias', NULL),
    ('UA02', 'mguerrero', 'Marc Guerrero Roca', 'A', 'operativo', 'enfermeria', 'Enfermero de triaje', '0841327'),
    ('UA03', 'lmartin', 'Laura Martín Costa', 'A', 'clinico', 'medico', 'Médica adjunta de Urgencias', '0838214'),
    ('UA04', 'jcasals', 'Jordi Casals Pujol', 'A', 'gestion_clinica', 'medico', 'Jefe de servicio de Urgencias', '0829473'),
    ('UA05', 'sromero', 'Sílvia Romero Gil', 'A', 'administracion_economica', 'gestor', 'Responsable de control de gestión de Urgencias', NULL),
    ('UB01', 'apons', 'Anna Pons Mir', 'B', 'operativo', 'tecnico', 'Técnica en farmacia', NULL),
    ('UB02', 'dserra', 'David Serra Bosch', 'B', 'clinico', 'farmaceutico', 'Farmacéutico adjunto', '0817652'),
    ('UB03', 'cmolina', 'Cristina Molina Vela', 'B', 'clinico', 'farmaceutico', 'Farmacéutica de guardia', '0819034'),
    ('UB04', 'mriera', 'Montserrat Riera Font', 'B', 'gestion_clinica', 'farmaceutico', 'Jefa de servicio de Farmacia', '0812281'),
    ('UB05', 'xtorres', 'Xavier Torres Lladó', 'B', 'administracion_economica', 'gestor', 'Economista de consumo y compras de farmacia', NULL),
    ('UC01', 'mgimenez', 'Marta Giménez Sala', 'C', 'operativo', 'tecnico', 'Técnica de laboratorio clínico', NULL),
    ('UC02', 'pribas', 'Pau Ribas Coll', 'C', 'operativo', 'tecnico', 'Técnico de radiodiagnóstico', NULL),
    ('UC03', 'inavarro', 'Isabel Navarro Prat', 'C', 'clinico', 'medico', 'Facultativa especialista en Análisis Clínicos', '0835590'),
    ('UC04', 'amas', 'Albert Mas Oliver', 'C', 'clinico', 'medico', 'Radiólogo adjunto', '0840118'),
    ('UC05', 'ebatlle', 'Enric Batlle Rius', 'C', 'gestion_clinica', 'medico', 'Jefe de servicio de Diagnóstico por la Imagen', '0826745'),
    ('UC06', 'rdominguez', 'Rosa Domínguez León', 'C', 'administracion_economica', 'gestor', 'Analista de costes de pruebas complementarias', NULL),
    ('UD01', 'cfuster', 'Carla Fuster Martí', 'D', 'operativo', 'enfermeria', 'Enfermera de planta de Cirugía General', '0843906'),
    ('UD02', 'splanas', 'Sergi Planas Vives', 'D', 'clinico', 'medico', 'Médico adjunto de Medicina Interna', '0837761'),
    ('UD03', 'lherrero', 'Lucía Herrero Vallès', 'D', 'clinico', 'medico', 'Médica intensivista (UCI)', '0839402'),
    ('UD04', 'tcasas', 'Teresa Casas Mora', 'D', 'gestion_clinica', 'enfermeria', 'Supervisora de enfermería de hospitalización', '0824518'),
    ('UD05', 'iprats', 'Ignasi Prats Vila', 'D', 'administracion_economica', 'gestor', 'Responsable de gestión de camas y costes de hospitalización', NULL),
    ('UE01', 'elozano', 'Eva Lozano Campos', 'E', 'operativo', 'administrativo', 'Programadora quirúrgica', NULL),
    ('UE02', 'rpuig', 'Ramón Puig Vidal', 'E', 'clinico', 'medico', 'Cirujano general adjunto', '0831275'),
    ('UE03', 'ecastells', 'Elena Castells Moya', 'E', 'clinico', 'medico', 'Cirujana general adjunta', '0833648'),
    ('UE04', 'froig', 'Francesc Roig Amat', 'E', 'gestion_clinica', 'medico', 'Jefe de servicio de Cirugía General', '0821137'),
    ('UE05', 'mcortes', 'Mireia Cortés Llobet', 'E', 'administracion_economica', 'gestor', 'Responsable económica del bloque quirúrgico', NULL);

INSERT INTO operation_team (id_operation, id_professional, team_role, is_lead)
VALUES
    (1, 23, 'Surgeon', TRUE),
    (1, 24, 'Consultant', FALSE);

INSERT INTO operation_costs (
    id_operation,
    cost_concept,
    billing_unit,
    quantity,
    unit_price
) VALUES
    (1, 'operating room', 'per minute', 95.00, 14.50),
    (1, 'materials',      'fixed',       1.00, 385.00);

INSERT INTO surgical_reports (
    id_operation,
    created_at,
    current_version,
    status_r
) VALUES (
    1,
    '2026-11-21 10:25:00',
    1,
    'completed'
);

INSERT INTO surgical_report_versions (
    id_report,
    version_number,
    id_professional,
    report_date,
    report_content
) VALUES (
    1,
    1,
    23,
    '2026-11-21 10:25:00',
    'Apendicectomía laparoscópica urgente sin incidencias intraoperatorias. Apéndice flemonoso, lavado de cavidad y traslado a reanimación estable.'
);

INSERT INTO checklist (
    id_operation,
    checklist_item,
    is_completed,
    completed_by,
    completion_date
) VALUES
    (1, 'Identificación del paciente, procedimiento y sitio quirúrgico verificados', TRUE, 23, '2026-11-21 09:10:00'),
    (1, 'Profilaxis antibiótica administrada antes de la incisión', TRUE, 23, '2026-11-21 09:15:00'),
    (1, 'Recuento de gasas, agujas e instrumental correcto al finalizar', TRUE, 23, '2026-11-21 10:22:00');

    INSERT INTO professional_audit_log (
    id_professional,
    action_type,
    target_table,
    target_id,
    request_summary,
    created_at
) VALUES (
    23,
    'CREATE_OPERATION',
    'surgical_operations',
    1,
    'Registro de apendicectomía laparoscópica urgente (Caso 1, episodio 201).',
    '2026-11-21 08:30:00'
);
