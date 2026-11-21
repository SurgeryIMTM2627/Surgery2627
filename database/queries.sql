
USE hospital_surgery_db;

SELECT * FROM v_conflictos_horarios;

SELECT * FROM operating_rooms;

SELECT * FROM procedures;

SELECT * FROM operating_rooms;

SELECT * FROM surgical_operations;

SELECT * FROM professionals;

SELECT id_professional, user_code, username, professional_name
FROM professionals
WHERE user_code IN ('UE02', 'UE03');



SELECT * FROM operation_team;
SELECT * FROM operation_costs;

SELECT * FROM surgical_reports;
SELECT * FROM surgical_report_versions;

SELECT * FROM checklist;

SELECT * FROM professional_audit_log;