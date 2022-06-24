--Série de variable sql (2 connexions et 2 utilisateurs pour une VM sont créée à chaque exécution)
SET @vmAdmin = "20.03 - Test admin - fthaumur";
SET @vmName1 = "20.03 - Test1 - fthaumur";
SET @vmName2 = "20.03 - Test2 - fthaumur";
SET @ip = "192.168.20.103";
SET @identifierAdmin = "Administrateur";
SET @identifierForm1 = "Formation1";--Utilisateurs de la VM
SET @identifierForm2 = "Formation2";
SET @passForm1 = "NextForm1-@44";--Mot de passe des utilisateurs de la VM
SET @passForm2 = "NextForm2-@44";
SET @idForamteur = "fthaumur";
SET @identifierGuaForm1 = "Form1User1";--Utilisateurs guacamole
SET @identifierGuaForm2 = "Form1User2";
SET @passGuaForm1 = "NextForm1@-44!";--Mot de passe des utilisateurs guacamole avant hashage 
SET @passGuaForm2 = "NextForm2@-44!";
SET @createOn = "2022-02-01 10:52:00.000";--date de création du mot de passe
SET @startHour = "08:00:00";--Heure où l'utilisteur peux commencé à accéder à son compte
SET @endHour = "19:00:00";--Heure où l'utilisateur ne peux plus accéder à son compte
SET @startDate = "2022-02-01";--Date où le compte est utilisable
SET @endDate = "2022-02-20";--Date où le compte n'est plus utilisable

--Paramètre d'affichage de la VM
SET @protocol = "rdp";
SET @numConnection = "2";
SET @numConnectionPerUser = "1";
SET @port = "3389";
SET @security = "nla";
SET @ignoreCertificate = "true";
SET @keyboard = "fr-fr-azerty";
SET @timeZone = 'Europe/Paris';
SET @width = "1920";
SET @height = "1080";
SET @color = "32";
SET @resize = "display-update";

--Paramètre des comptes guacamole
SET @passwordSalt = (UNHEX(SHA2(UUID(), 256)));--Aucune idée de ce que c'est en réalité
SET @passwordGua1Encrypt = (UNHEX(SHA2(CONCAT(@passForm1, HEX(@passwordSalt)), 256)));--Méthode de hashage du mot de passe (merci stackoverflow :) )
SET @passwordGua2Encrypt = (UNHEX(SHA2(CONCAT(@passForm2, HEX(@passwordSalt)), 256)));
SET @role = 'APPRENANT'; --Groupe et rôle de l'utilisateur
SET @timeZone = 'Europe/Paris';
SET @organization = 'Next';

--Création des connexion
INSERT INTO `guacamole_connection` (`connection_name`, `protocol`, `max_connections`, `max_connections_per_user`) VALUES 
(@vmAdmin, @protocol, @numConnection, @numConnectionPerUser),
(@vmName1, @protocol, @numConnection, @numConnectionPerUser),
(@vmName2, @protocol, @numConnection, @numConnectionPerUser);
 
--récupération des ids des connexions en fonction du nom
SET @connectionIdAdmin = (SELECT `connection_id` FROM `guacamole_connection` WHERE `connection_name` = @vmAdmin);
SET @connectionId1 = (SELECT `connection_id` FROM `guacamole_connection` WHERE `connection_name` = @vmName1);
SET @connectionId2 = (SELECT `connection_id` FROM `guacamole_connection` WHERE `connection_name` = @vmName2);

--Création des paramètres des connexion aux VMs
INSERT INTO `guacamole_connection_parameter` (`connection_id`, `parameter_name`, `parameter_value`) VALUES 
(@connectionIdAdmin, 'hostname', @ip), 
(@connectionIdAdmin, 'port', @port), 
(@connectionIdAdmin, 'username', @identifierForm1), 
(@connectionIdAdmin, 'password', @passForm1), 
(@connectionIdAdmin, 'timezone', @timeZone), 
(@connectionIdAdmin, 'ignore-cert', @ignoreCertificate), 
(@connectionIdAdmin, 'security', @security), 
(@connectionIdAdmin, 'server-layout', @keyboard), 
(@connectionIdAdmin, 'width', @width), 
(@connectionIdAdmin, 'height', @height), 
(@connectionIdAdmin, 'resize-method', @resize), 
(@connectionIdAdmin, 'color-depth', @color),

(@connectionId1, 'hostname', @ip), 
(@connectionId1, 'port', @port), 
(@connectionId1, 'username', @identifierForm1), 
(@connectionId1, 'password', @passForm1), 
(@connectionId1, 'timezone', @timeZone), 
(@connectionId1, 'ignore-cert', @ignoreCertificate), 
(@connectionId1, 'security', @security), 
(@connectionId1, 'server-layout', @keyboard), 
(@connectionId1, 'width', @width), 
(@connectionId1, 'height', @height), 
(@connectionId1, 'resize-method', @resize), 
(@connectionId1, 'color-depth', @color),

(@connectionId2, 'hostname', @ip), 
(@connectionId2, 'port', @port), 
(@connectionId2, 'username', @identifierForm1), 
(@connectionId2, 'password', @passForm1), 
(@connectionId2, 'timezone', @timeZone), 
(@connectionId2, 'ignore-cert', @ignoreCertificate),
(@connectionId2, 'security', @security), 
(@connectionId2, 'server-layout', @keyboard), 
(@connectionId2, 'width', @width), 
(@connectionId2, 'height', @height), 
(@connectionId2, 'resize-method', @resize), 
(@connectionId2, 'color-depth', @color);

--Récupération de l'ID du groupe (sécurité via le type pour évité de prendre l'id d'un utilisateur qui aurais le même nom qu'un groupe)
SET @roleId = (SELECT `entity_id` FROM `guacamole_entity` WHERE name = @role AND type = 'USER_GROUP');

--Création des entity id et des utilisateurs
INSERT INTO `guacamole_entity` (name, type) VALUES 
(@identifierGuaForm1, 'USER'),
(@identifierGuaForm2, 'USER');

--récupération des entity ids en fonction des nom d'utilisateur (sécurité via le type pour évité de prendre l'id d'un groupe qui aurais le même nom qu'un utilisateur)
SET @adminEntityId = (SELECT `entity_id` FROM `guacamole_entity` WHERE name = @idForamteur AND type = 'USER');
SET @userEntityId1 = (SELECT `entity_id` FROM `guacamole_entity` WHERE name = @identifierGuaForm1 AND type = 'USER');
SET @userEntityId2 = (SELECT `entity_id` FROM `guacamole_entity` WHERE name = @identifierGuaForm2 AND type = 'USER');

--Création des paramètres utilisateurs
INSERT INTO `guacamole_user` (`entity_id`, `password_hash`, `password_salt`, `password_date`, `access_window_start`, `access_window_end`, `valid_from`, `valid_until`, `timezone`, `organization`, `organizational_role`) VALUES 
(@userEntityId1, @passwordGua1Encrypt, @passwordSalt, @createOn, @startHour, @endHour, @startDate, @endDate, @timeZone, @organization, @role),
(@userEntityId2, @passwordGua2Encrypt, @passwordSalt, @createOn, @startHour, @endHour, @startDate, @endDate, @timeZone, @organization, @role);

--Récupération des ids utilisateurs
SET @AdminId = (SELECT `user_id` FROM `guacamole_user` WHERE `entity_id` = @adminEntityId);
SET @userId1 = (SELECT `user_id` FROM `guacamole_user` WHERE `entity_id` = @userEntityId1);
SET @userId2 = (SELECT `user_id` FROM `guacamole_user` WHERE `entity_id` = @userEntityId2);

--Création des permitions au compte guacamole
INSERT INTO `guacamole_user_permission` (`entity_id`, `affected_user_id`, `permission`) VALUES 
(@userEntityId1, @userId1, 'READ'), 
(@userEntityId1, @userId1, 'UPDATE'),
(@userEntityId2, @userId2, 'READ'), 
(@userEntityId2, @userId2, 'UPDATE');

--Récupération des id de groupe en fonction de son nom (oui j'ai fait une jointure :) )
SET @groupId = (SELECT g.user_group_id FROM `guacamole_user_group` g JOIN `guacamole_entity` e ON e.`entity_id` = g.`entity_id` WHERE e.name = @role);

--ajout des utilisateur dans le groupe
INSERT INTO `guacamole_user_group_member` (`user_group_id`, `member_entity_id`) VALUES 
(@groupId, @userEntityId1),
(@groupId, @userEntityId2);

--ajout des permissions sur les VMs
INSERT INTO `guacamole_connection_permission` (`entity_id`, `connection_id`, `permission`) VALUES 
(@adminEntityId, @connectionIdAdmin, 'READ'),
(@userEntityId1, @connectionId1, 'READ'),
(@userEntityId2, @connectionId2, 'READ');