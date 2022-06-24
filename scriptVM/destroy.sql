SET @formation = 'Test';
SET @ip = '192.168.20.136';

SET @connectionId1 = (SELECT connection_id FROM guacamole_connection WHERE connection_name LIKE concat(@ip,' - ',@formation,' - % - 1'));
SET @connectionId2 = (SELECT connection_id FROM guacamole_connection WHERE connection_name LIKE concat(@ip,' - ',@formation,' - % - 2'));
SET @connectionIdAdmin = (SELECT connection_id FROM guacamole_connection WHERE connection_name LIKE concat(@ip,' - ',@formation,' - Admin'));

SET @entityId1 = (SELECT entity_id FROM guacamole_connection_permission WHERE connection_id = @connectionId1);
SET @entityId2 = (SELECT entity_id FROM guacamole_connection_permission WHERE connection_id = @connectionId2);

DELETE FROM guacamole_entity WHERE entity_id = @entityId1;
DELETE FROM guacamole_entity WHERE entity_id = @entityId2;

DELETE FROM guacamole_connection WHERE connection_id = @connectionId1;
DELETE FROM guacamole_connection WHERE connection_id = @connectionId2;
DELETE FROM guacamole_connection WHERE connection_id = @connectionIdAdmin;