USE hospital_surgery_db

SELECT TABLE_NAME AS name
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'hospital_surgery_db'
  AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

SELECT 
    so.id_operation,
    so.patient_id,
    so.episode_id,
    r.room_name,
    p.procedure_name,
    so.status_so,
    so.actual_surgery_start,
    so.actual_surgery_end
FROM surgical_operations so
LEFT JOIN operating_rooms r ON so.id_room = r.id_room
LEFT JOIN procedures p ON so.id_procedure = p.id_procedure
ORDER BY so.id_operation DESC;

-- Consulta para detectar solapamientos de operaciones en el mismo quirófano
SELECT
    s1.id_schedule AS operation_1,
    s2.id_schedule AS operation_2,
    s1.id_room AS operating_room,
    s1.scheduled_room_start AS start_1,
    s1.scheduled_room_end AS end_1,
    s2.scheduled_room_start AS start_2,
    s2.scheduled_room_end AS end_2
FROM schedule s1
JOIN schedule s2
    ON s1.id_room = s2.id_room 
    AND s1.id_schedule < s2.id_schedule
    AND s1.status_s IN ('scheduled', 'confirmed')
    AND s2.status_s IN ('scheduled', 'confirmed')
    AND s1.scheduled_room_start < s2.scheduled_room_end
    AND s2.scheduled_room_start < s1.scheduled_room_end;

    -- Consulta para verificar las operaciones enlazadas con quirófanos y procedimientos
SELECT
    so.id_operation,
    so.patient_id,
    r.room_name,
    p.procedure_name
FROM surgical_operations so
LEFT JOIN operating_rooms r
    ON so.id_room = r.id_room
LEFT JOIN procedures p
    ON so.id_procedure = p.id_procedure;

USE hospital_surgery_db;

-- Creamos una vista para los conflictos de horarios
CREATE OR REPLACE VIEW v_conflictos_horarios AS
SELECT
    s1.id_schedule AS operation_1,
    s2.id_schedule AS operation_2,
    s1.id_room AS operating_room,
    s1.scheduled_room_start AS start_1,
    s1.scheduled_room_end AS end_1,
    s2.scheduled_room_start AS start_2,
    s2.scheduled_room_end AS end_2
FROM schedule s1
JOIN schedule s2
    ON s1.id_room = s2.id_room 
    AND s1.id_schedule < s2.id_schedule
    AND s1.status_s IN ('scheduled', 'confirmed')
    AND s2.status_s IN ('scheduled', 'confirmed')
    AND s1.scheduled_room_start < s2.scheduled_room_end
    AND s2.scheduled_room_start < s1.scheduled_room_end;

SELECT * FROM v_conflictos_horarios;
