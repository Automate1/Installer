-- Script was generated by Devart dbForge Studio Beta for MySQL, Version 6.0.113.0
-- Product Home Page: http://www.devart.com/dbforge/mysql/studio
-- Script date 1/6/2014 10:16:32 PM
-- Server version: 5.5.23
-- Run this script against osae_043 to synchronize it with osae_044
-- Please backup your target database before running this script

--
-- Disable foreign keys
--
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;

SET NAMES 'utf8';
USE osae;


--
-- Alter table "osae_event_log"
--
ALTER TABLE osae_event_log
  ADD INDEX IDX_osae_event_log_log_time (log_time);

DELIMITER $$

--
-- Alter procedure "osae_sp_object_property_set"
--
DROP PROCEDURE osae_sp_object_property_set$$
CREATE PROCEDURE osae_sp_object_property_set(IN pname varchar(200), IN pproperty varchar(200), IN pvalue varchar(4000), IN pfromobject varchar(200), IN pdebuginfo varchar(2000))
BEGIN
DECLARE vObjectID INT DEFAULT 0;
DECLARE vObjectCount INT DEFAULT 0;
DECLARE vObjectTypeID INT DEFAULT 0;
DECLARE vPropertyID INT DEFAULT 0;
DECLARE vPropertyValue VARCHAR(4000);
DECLARE vPropertyCount INT DEFAULT 0;
DECLARE vEventCount INT;
DECLARE vDebugTrace VARCHAR(2000) DEFAULT '';
    SET vDebugTrace = CONCAT(pdebuginfo,' -> osae_sp_object_property_set');
    SELECT COUNT(object_id) INTO vObjectCount FROM osae_object WHERE UPPER(object_name)=UPPER(pname); 
    IF vObjectCount > 0 THEN  
        SELECT object_id,object_type_id INTO vObjectID,vObjectTypeID FROM osae_object WHERE UPPER(object_name)=UPPER(pname);
        SELECT COUNT(property_id) INTO vPropertyCount FROM osae_v_object_property WHERE UPPER(object_name)=UPPER(pname) AND UPPER(property_name)=UPPER(pproperty) AND (property_value IS NULL OR property_value != pvalue);        
        IF vPropertyCount > 0 THEN
            SELECT property_id,COALESCE(property_value,'') INTO vPropertyID, vPropertyValue FROM osae_v_object_property WHERE UPPER(object_name)=UPPER(pname) AND UPPER(property_name)=UPPER(pproperty) AND (property_value IS NULL OR property_value != pvalue);
            UPDATE osae_object_property SET property_value=pvalue WHERE object_id=vObjectID AND object_type_property_id=vPropertyID;
            UPDATE osae_object SET last_updated=NOW() WHERE object_id=vObjectID;            
            SELECT COUNT(event_id) INTO vEventCount FROM osae_object_type_event WHERE object_type_id=vObjectTypeID AND UPPER(event_name)=UPPER(pproperty);
            IF vEventCount > 0 THEN  
                CALL osae_sp_event_log_add(pname,pproperty,pfromobject,vDebugTrace,pvalue,NULL);
            END IF;
        END IF;
    END IF; 
END
$$

--
-- Alter procedure "osae_sp_process_recurring"
--
DROP PROCEDURE osae_sp_process_recurring$$
CREATE PROCEDURE osae_sp_process_recurring()
BEGIN
DECLARE iRECURRINGID INT;
DECLARE vOBJECTNAME VARCHAR(400) DEFAULT '';
DECLARE vMETHODNAME VARCHAR(400) DEFAULT '';
DECLARE vPARAM1 VARCHAR(200);
DECLARE vPARAM2 VARCHAR(200);
DECLARE vSCRIPTNAME VARCHAR(200);
DECLARE iSCRIPTID INT;
DECLARE cINTERVAL CHAR(1);
DECLARE cSUNDAY CHAR(1);
DECLARE cMONDAY CHAR(1);
DECLARE cTUESDAY CHAR(1);
DECLARE cWEDNESDAY CHAR(1);
DECLARE cTHURSDAY CHAR(1);
DECLARE cFRIDAY CHAR(1);
DECLARE cSATURDAY CHAR(1);
DECLARE dRECURRINGDATE DATE;
DECLARE iRECURRINGMINUTES INT;
DECLARE dRECURRINGDAY INT;
DECLARE dRECURRINGTIME TIME;
DECLARE dCURDATE DATE;
DECLARE dCURDATETIME DATETIME;
DECLARE dCURDAYOFWEEK INT DEFAULT 0;
DECLARE dCURDAYOFMONTH INT DEFAULT 1;
DECLARE dCURDAY INT DEFAULT 1;
DECLARE iMATCHES INT DEFAULT 0;
DECLARE iDATEDIFF INT DEFAULT 0;
DECLARE done INT DEFAULT 0;  
DECLARE cur1 CURSOR FOR SELECT recurring_id,interval_unit,recurring_time,recurring_minutes,recurring_date,recurring_day,object_name,method_name,parameter_1,parameter_2,script_id, script_name, sunday,monday,tuesday,wednesday,thursday,friday,saturday FROM osae_v_schedule_recurring WHERE COALESCE(active,1)=1;
DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;
    OPEN cur1; 
    Loop_Tag: LOOP
        IF done THEN
            Leave Loop_Tag;
        END IF;
        FETCH cur1 INTO iRECURRINGID,cINTERVAL,dRECURRINGTIME,iRECURRINGMINUTES,dRECURRINGDATE,dRECURRINGDAY,vOBJECTNAME,vMETHODNAME,vPARAM1,vPARAM2,iSCRIPTID,vSCRIPTNAME,cSUNDAY,cMONDAY,cTUESDAY,cWEDNESDAY,cTHURSDAY,cFRIDAY,cSATURDAY;
        CALL osae_sp_debug_log_add(CONCAT('ID=',iRECURRINGID,', Interval=',cINTERVAL,' Time=',dRECURRINGTIME,' Date=',dRECURRINGDATE),'sp_process_recurring'); 
        IF NOT done THEN
            IF cINTERVAL = 'Y' THEN
                SET dCURDATE = CURDATE();
                CALL osae_sp_debug_log_add(CONCAT('--IF ',dRECURRINGDATE,' < ',dCURDATE,' THEN'),'SYSTEM'); 
                IF dRECURRINGDATE < dCURDATE THEN
                    SET iDATEDIFF = DATEDIFF(dCURDATE,dRECURRINGDATE) / 365; 
                    CALL osae_sp_debug_log_add(CONCAT('sp_process_recurring: DateDiff=',iDATEDIFF),'SYSTEM'); 
                    SET dRECURRINGDATE = DATE_ADD(dRECURRINGDATE,INTERVAL iDATEDIFF YEAR);
                    IF dRECURRINGDATE < dCURDATE THEN 
                        SET dRECURRINGDATE = DATE_ADD(dRECURRINGDATE,INTERVAL 1 YEAR);                   
                    END IF;                                     
                END IF;
                CALL osae_sp_debug_log_add(CONCAT(dRECURRINGDATE,' ',TIME(dRECURRINGTIME)),'SYSTEM'); 
                SELECT COUNT(schedule_ID) INTO iMATCHES FROM osae_schedule_queue WHERE recurring_id=iRECURRINGID;      
                IF iMATCHES = 0 THEN
                    CALL osae_sp_schedule_queue_add (CONCAT(dRECURRINGDATE,' ',TIME(dRECURRINGTIME)),vOBJECTNAME,vMETHODNAME,vPARAM1,vPARAM2,vSCRIPTNAME,iRECURRINGID);
                END IF;
              ELSEIF cINTERVAL = 'T' THEN   
                SET dCURDATETIME = NOW();             
                SET dCURDATE = CURDATE();
                IF dCURDATETIME > ADDTIME(NOW(),SEC_TO_TIME(iRECURRINGMINUTES * 60)) THEN
                    SET dCURDAYOFWEEK = dCURDAYOFWEEK + 1;
                    If dCURDAYOFWEEK > 7 THEN
			SET dCURDAYOFWEEK = 1;
		    END IF;
                    SET dCURDATE=DATE_ADD(CURDATE(),INTERVAL 1 DAY);
                END IF; 
                CALL osae_sp_debug_log_add(CONCAT(dRECURRINGDATE,' ',TIME(dRECURRINGTIME)),'SYSTEM'); 
                SELECT COUNT(schedule_ID) INTO iMATCHES FROM osae_schedule_queue WHERE recurring_id=iRECURRINGID;      
                IF iMATCHES = 0 THEN
                    CALL osae_sp_schedule_queue_add (ADDTIME(NOW(),SEC_TO_TIME(iRECURRINGMINUTES * 60)),vOBJECTNAME,vMETHODNAME,vPARAM1,vPARAM2,vSCRIPTNAME,iRECURRINGID);
               END IF;               
            ELSEIF cINTERVAL = 'M' THEN                
                SET dCURDATE = CURDATE();
                SET dRECURRINGDATE = CONCAT(YEAR(NOW()),'-',MONTH(NOW()),'-' ,dRECURRINGDAY);                
                IF dRECURRINGDATE < dCURDATE THEN
                    CALL osae_sp_debug_log_add(CONCAT('sp_process_recurring: DateDiff=',iDATEDIFF),'SYSTEM');                
                    SET dRECURRINGDATE = DATE_ADD(dRECURRINGDATE,INTERVAL 1 MONTH);
                    IF dRECURRINGDATE < dCURDATE THEN 
                        SET dRECURRINGDATE = DATE_ADD(dRECURRINGDATE,INTERVAL 1 MONTH);                   
                    END IF;                                     
                END IF;
                CALL osae_sp_debug_log_add(CONCAT(dRECURRINGDATE,' ',TIME(dRECURRINGTIME)),'SYSTEM'); 
                SELECT COUNT(schedule_ID) INTO iMATCHES FROM osae_schedule_queue WHERE recurring_id=iRECURRINGID;      
                IF iMATCHES = 0 THEN
                    CALL osae_sp_schedule_queue_add (CONCAT(dRECURRINGDATE,' ',TIME(dRECURRINGTIME)),vOBJECTNAME,vMETHODNAME,vPARAM1,vPARAM2,vSCRIPTNAME,iRECURRINGID);
                END IF;               
            ELSEIF cINTERVAL = 'D' THEN                
                SET dCURDATETIME = NOW();
                SET dCURDATE = CURDATE();
                SET dCURDAYOFWEEK = DAYOFWEEK(NOW()); 
                SET dCURDAYOFMONTH = DAYOFMONTH(NOW());
  
                IF dCURDATETIME > CONCAT(dCURDATE,' ',dRECURRINGTIME) THEN
                    SET dCURDAYOFWEEK = dCURDAYOFWEEK + 1;
                    If dCURDAYOFWEEK > 7 THEN
			SET dCURDAYOFWEEK = 1;
		    END IF;
                    SET dCURDATE=DATE_ADD(CURDATE(),INTERVAL 1 DAY);
                END IF; 
                CALL osae_sp_debug_log_add(CONCAT('IF ',dCURDATETIME,' > ',dCURDATE,' ',dRECURRINGTIME,' Then Write new queue'),'SYSTEM');              
                IF dCURDAYOFWEEK = 1 AND cSUNDAY = 1 THEN
                    SELECT COUNT(schedule_ID) INTO iMATCHES FROM osae_schedule_queue WHERE recurring_id=iRECURRINGID;      
                    IF iMATCHES = 0 THEN
                        CALL osae_sp_schedule_queue_add (CONCAT(dCURDATE,' ',TIME(dRECURRINGTIME)),vOBJECTNAME,vMETHODNAME,vPARAM1,vPARAM2,vSCRIPTNAME,iRECURRINGID);
                    END IF; 
                END IF; 
                IF dCURDAYOFWEEK = 2 AND cMONDAY = 1 THEN                
                    SELECT COUNT(schedule_ID) INTO iMATCHES FROM osae_schedule_queue WHERE recurring_id=iRECURRINGID;      
                    IF iMATCHES = 0 THEN
                        CALL osae_sp_schedule_queue_add (CONCAT(dCURDATE,' ',TIME(dRECURRINGTIME)),vOBJECTNAME,vMETHODNAME,vPARAM1,vPARAM2,vSCRIPTNAME,iRECURRINGID);          
                    END IF; 
                END IF; 
                IF dCURDAYOFWEEK = 3 AND cTUESDAY = 1 THEN                
                    SELECT COUNT(schedule_ID) INTO iMATCHES FROM osae_schedule_queue WHERE recurring_id=iRECURRINGID;      
                    IF iMATCHES = 0 THEN
                        CALL osae_sp_schedule_queue_add (CONCAT(dCURDATE,' ',TIME(dRECURRINGTIME)),vOBJECTNAME,vMETHODNAME,vPARAM1,vPARAM2,vSCRIPTNAME,iRECURRINGID);
                    END IF; 
                END IF;                 
                IF dCURDAYOFWEEK = 4 AND cWEDNESDAY = 1 THEN                
                    SELECT COUNT(schedule_ID) INTO iMATCHES FROM osae_schedule_queue WHERE recurring_id=iRECURRINGID;      
                    IF iMATCHES = 0 THEN
                        CALL osae_sp_schedule_queue_add (CONCAT(dCURDATE,' ',TIME(dRECURRINGTIME)),vOBJECTNAME,vMETHODNAME,vPARAM1,vPARAM2,vSCRIPTNAME,iRECURRINGID);   
                    END IF; 
                END IF;  
                IF dCURDAYOFWEEK = 5 AND cTHURSDAY = 1 THEN                
                    SELECT COUNT(schedule_ID) INTO iMATCHES FROM osae_schedule_queue WHERE recurring_id=iRECURRINGID;      
                    IF iMATCHES = 0 THEN
                        CALL osae_sp_schedule_queue_add (CONCAT(dCURDATE,' ',TIME(dRECURRINGTIME)),vOBJECTNAME,vMETHODNAME,vPARAM1,vPARAM2,vSCRIPTNAME,iRECURRINGID);                    
                    END IF; 
                END IF;
                IF dCURDAYOFWEEK = 6 AND cFRIDAY = 1 THEN                
                    SELECT COUNT(schedule_ID) INTO iMATCHES FROM osae_schedule_queue WHERE recurring_id=iRECURRINGID;      
                    IF iMATCHES = 0 THEN
                        CALL osae_sp_schedule_queue_add (CONCAT(dCURDATE,' ',TIME(dRECURRINGTIME)),vOBJECTNAME,vMETHODNAME,vPARAM1,vPARAM2,vSCRIPTNAME,iRECURRINGID);                    
                    END IF; 
                END IF;
                IF dCURDAYOFWEEK = 7 AND cSATURDAY = 1 THEN                
                    SELECT COUNT(schedule_ID) INTO iMATCHES FROM osae_schedule_queue WHERE recurring_id=iRECURRINGID;      
                    IF iMATCHES = 0 THEN
                        CALL osae_sp_schedule_queue_add (CONCAT(dCURDATE,' ',TIME(dRECURRINGTIME)),vOBJECTNAME,vMETHODNAME,vPARAM1,vPARAM2,vSCRIPTNAME,iRECURRINGID);                    
                   END IF; 
                END IF;                                                                           
            END IF;         
        END IF;
     END LOOP;
    CLOSE cur1;   
END
$$

--
-- Alter procedure "osae_sp_schedule_queue_add"
--
DROP PROCEDURE osae_sp_schedule_queue_add$$
CREATE PROCEDURE osae_sp_schedule_queue_add(IN pscheduleddate DATETIME, IN pobject VARCHAR(400), IN pmethod VARCHAR(400), IN pparameter1 VARCHAR(2000), IN pparameter2 VARCHAR(2000), IN pscript VARCHAR(200), IN precurringid INT(10))
BEGIN
DECLARE vObjectID INT DEFAULT NULL;
DECLARE vMethodID INT DEFAULT NULL;
DECLARE vScriptID INT DEFAULT NULL;
DECLARE vRecurringID INT DEFAULT NULL;
    SELECT script_id INTO vScriptID FROM osae_script WHERE UPPER(script_name)=UPPER(pscript);
    SELECT object_id, method_id INTO vObjectID, vMethodID FROM osae_v_object_method WHERE object_name = pobject AND (UPPER(method_name)=UPPER(pmethod) OR UPPER(method_label)=UPPER(pmethod));
    IF precurringid > 0 THEN
        SET vRecurringID = precurringid;
    END IF;
    INSERT INTO osae_schedule_queue (queue_datetime,object_id,method_id,parameter_1,parameter_2,script_id,recurring_id) VALUES(pscheduleddate,vObjectID,vMethodID,pparameter1,pparameter2,vScriptID,vRecurringID);
END
$$

CREATE TABLE osae_log (
  ID INT(11) NOT NULL AUTO_INCREMENT,
  Date DATETIME NOT NULL,
  Thread VARCHAR(255) NOT NULL,
  Level VARCHAR(255) NOT NULL,
  Logger VARCHAR(255) NOT NULL,
  Message VARCHAR(4000) NOT NULL,
  Exception VARCHAR(4000) DEFAULT NULL,
  PRIMARY KEY (ID)
)
ENGINE = INNODB
CHARACTER SET latin1
COLLATE latin1_swedish_ci
$$

DELIMITER ;

--
-- Enable foreign keys
--
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;


-- Set DB version 
CALL osae_sp_object_property_set('SYSTEM', 'DB Version', '0.4.4', '', '');
