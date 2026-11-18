
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

SET FOREIGN_KEY_CHECKS = 1;

-- 2. A partir de aquí, tus sentencias INSERT INTO
INSERT INTO professionals (
    id_professional,
    professional_name,
    professional_type,
    professional_category,
    professional_email,
    professional_phone
)
VALUES 
(1, 'Alex Morgan', 'surgery', 'Specialist', 'alex.morgan@example.com', '+34111111111'),
(2, 'Taylor Smith', 'surgery', 'Consultant', 'taylor.smith@example.com', '+34222222222'),
(3, 'Jordan Lee', 'anaesthesia', 'Specialist', 'jordan.lee@example.com', '+34333333333'),
(4, 'Casey Brown', 'nursing', 'Resident', 'casey.brown@example.com', '+34444444444'),
(5, 'Riley Davis', 'nursing', 'Specialist', 'riley.davis@example.com', '+34555555555');

-- (añade aquí el resto de tus INSERT INTO para las demás tablas: system_users, operating_rooms, etc.)
 
INSERT INTO operating_rooms (
    id_room,
    room_code,
    room_name,
    room_location,
    room_type,
    room_state
)
VALUES
    (1, 'OR-01', 'Emergency Operating Room', 'Floor 2 - East Wing', 'urgent', 'available'),
    (2, 'OR-02', 'General Surgery Room', 'Floor 2 - West Wing', 'programmed', 'available'),
    (3, 'OR-03', 'Hybrid Operating Room', 'Floor 3 - East Wing', 'hybrid', 'available');

INSERT INTO system_users (
    id_user,
    username,
    password_hash,
    user_email,
    user_role,
    id_professional
)
VALUES
    (1, 'alex_morgan', 'demo_hash_001', 'alex.morgan@example.com', 'surgeon', 1),
    (2, 'taylor_smith', 'demo_hash_002', 'taylor.smith@example.com', 'head of surgery', 2),
    (3, 'finance_admin', 'demo_hash_003', 'finance@example.com', 'financial administrator', NULL),
    (4, 'scheduler_user', 'demo_hash_004', 'scheduler@example.com', 'scheduler', NULL);

INSERT INTO procedures (
    id_procedure,
    procedure_code,
    procedure_name
)
VALUES
    -- ICD-10-PCS coding examples (pending final codes from the teacher)
    (1, '0DTJ0ZZ', 'Resection of Appendix, Open Approach'),
    (2, '0DTJ4ZZ', 'Resection of Appendix, Percutaneous Endoscopic Approach');

-- Placeholder patient_id and episode_id values pending confirmation from Group A
INSERT INTO surgical_operations (
    id_operation,
    patient_id,
    episode_id,
    id_room,
    id_procedure,
    actual_surgery_start,
    actual_surgery_end,
    actual_room_start,
    actual_room_end,
    status_so
)
VALUES 
(1, '1001', '5001', 1, 2, '2026-11-10 09:00:00', '2026-11-10 10:00:00', '2026-11-10 08:30:00', '2026-11-10 10:30:00', 'completed'),
(2, '1002', '5002', 2, 2, NULL, NULL, NULL, NULL, 'scheduled'),
(3, '1003', '5003', 2, 1, NULL, NULL, NULL, NULL, 'scheduled');


INSERT INTO schedule (
    id_schedule,
    id_operation,
    id_room,
    scheduled_surgery_start,
    scheduled_surgery_end,
    scheduled_room_start,
    scheduled_room_end,
    status_s,
    rescheduled_from
)
VALUES
    (1, 1, 1,
     '2026-11-10 09:00:00',
     '2026-11-10 10:00:00',
     '2026-11-10 08:30:00',
     '2026-11-10 10:30:00',
     'completed',
     NULL),

    (2, 2, 2,
     '2026-11-17 09:00:00',
     '2026-11-17 10:00:00',
     '2026-11-17 08:30:00',
     '2026-11-17 10:30:00',
     'confirmed',
     NULL),

    (3, 3, 2,
     '2026-11-17 09:30:00',
     '2026-11-17 10:30:00',
     '2026-11-17 09:00:00',
     '2026-11-17 11:00:00',
     'scheduled',
     NULL);

INSERT INTO operation_team (
    id_operation_team,
    id_operation,
    id_professional,
    role_in_operation
)
VALUES
    (1, 1, 1, 'surgeon'),
    (2, 1, 3, 'anaesthesiologist'),
    (3, 1, 4, 'nurse'),
    (4, 2, 2, 'surgeon'),
    (5, 2, 3, 'anaesthesiologist'),
    (6, 3, 1, 'surgeon'),
    (7, 3, 5, 'nurse');

INSERT INTO operation_costs (
    id_operation_cost,
    id_operation,
    cost_concept,
    billing_unit,
    quantity,
    unit_price
)
VALUES
    (1, 1, 'procedure', 'fixed', 1.00, 850.00),
    (2, 1, 'operating room', 'per minute', 120.00, 8.50),
    (3, 1, 'anaesthesia', 'fixed', 1.00, 250.00),
    (4, 1, 'materials', 'fixed', 1.00, 180.00),
    (5, 2, 'procedure', 'fixed', 1.00, 850.00),
    (6, 3, 'procedure', 'fixed', 1.00, 850.00);

INSERT INTO surgical_complications (
    id_complication,
    id_operation,
    complication_type,
    detection_date,
    description,
    severity,
    status_sc
)
VALUES
    (1, 1,
     'Postoperative infection',
     '2026-11-16 09:00:00',
     'Fictional example of an infection detected six days after surgery.',
     'moderate',
     'under treatment');

INSERT INTO surgical_reports (
    id_report,
    id_operation,
    created_at,
    status_r
)
VALUES
    (1, 1, '2026-11-10 11:00:00', 'approved');

INSERT INTO surgical_report_versions (
    id_report_version,
    id_report,
    version_number,
    id_professional,
    report_date,
    report_content
)
VALUES
    (1, 1, 1, 1,
     '2026-11-10 11:00:00',
     'Initial fictional surgical report: appendectomy completed successfully.'),

    (2, 1, 2, 2,
     '2026-11-10 12:00:00',
     'Updated fictional surgical report with additional clinical documentation.');

INSERT INTO operation_images (
    id_image,
    id_operation,
    id_complication,
    id_professional,
    image_path,
    image_date,
    upload_date,
    description,
    file_type
)
VALUES
    (1, 1, 1, 4,
     'test_images/operation_1_day_6_01.jpg',
     '2026-11-16 09:00:00',
     '2026-11-16 09:15:00',
     'Fictional postoperative image reference 1.',
     'jpg'),

    (2, 1, 1, 4,
     'test_images/operation_1_day_6_02.png',
     '2026-11-16 09:05:00',
     '2026-11-16 09:20:00',
     'Fictional postoperative image reference 2.',
     'png');
