
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