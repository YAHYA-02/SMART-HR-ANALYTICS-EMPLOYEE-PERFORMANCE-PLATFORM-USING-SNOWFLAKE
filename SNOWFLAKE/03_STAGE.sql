USE WAREHOUSE HR_ANALYTICS_WH;
USE DATABASE HR_ANALYTICS_DB;
USE SCHEMA RAW;

-- FILE FORMAT

CREATE OR REPLACE FILE FORMAT CSV_FORMAT
    TYPE                      = 'CSV'
    FIELD_DELIMITER           = ','
    RECORD_DELIMITER          = '\n'
    SKIP_HEADER               = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF                   = ('NULL','null','N/A','')
    EMPTY_FIELD_AS_NULL       = TRUE
    TRIM_SPACE                = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

CREATE OR REPLACE FILE FORMAT JSON_FORMAT
    TYPE             = 'JSON'
    NULL_IF          = ('NULL','null');


-- STAGE --

CREATE OR REPLACE STAGE HR_CSV_STAGE
    FILE_FORMAT = CSV_FORMAT;

CREATE OR REPLACE STAGE HR_JSON_STAGE
    FILE_FORMAT = JSON_FORMAT;



LIST @HR_CSV_STAGE;
LIST @HR_JSON_STAGE;


--- UPLOAD DATA ---

-- DEPARTMENT
COPY INTO RAW.DEPARTMENT (
    departmentId, departmentName, location, managerName
)
FROM (
    SELECT $1, $2, $3, $4
    FROM @HR_CSV_STAGE/departments.csv
)
FILE_FORMAT = (FORMAT_NAME = 'CSV_FORMAT')
pattern = '.*departments.*[.]csv'
ON_ERROR    = 'CONTINUE';

-- EMPLOYEE ---
COPY INTO RAW.EMPLOYEE (
    employeeId, employeeName, email, department,
    designation, employeeStatus, salary, hireDate
)
FROM (
    SELECT 
        $1, $2, $3, $4, $5, $6, $7,
        TO_DATE($8, 'DD-MM-YYYY')
    FROM @HR_CSV_STAGE/employees.csv
)
FILE_FORMAT = (FORMAT_NAME = 'CSV_FORMAT')
pattern = '.*employee.*[.]csv'
ON_ERROR    = 'CONTINUE';

-- ATTENDANCE
COPY INTO RAW.ATTENDANCE (
    attendanceId, employeeId, attendanceDate,
    attendanceStatus, workingHours
)
FROM (
    SELECT $1, $2, $3, $4, $5
    FROM @HR_CSV_STAGE/attendance.csv
)
FILE_FORMAT = (FORMAT_NAME = 'CSV_FORMAT')
PATTERN = '.*attendance.*[.]csv'
ON_ERROR    = 'CONTINUE';

-- PERFORMANCE REVIEW
COPY INTO RAW.PERFORMANCE_REVIEW (
    reviewId, employeeId, reviewPeriod,
    performanceScore, feedback
)
FROM (
    SELECT $1, $2, $3, $4, $5
    FROM @HR_CSV_STAGE/performance_review.csv
)
FILE_FORMAT = (FORMAT_NAME = 'CSV_FORMAT')
pattern = '.*performance_review.*[.]csv'
ON_ERROR    = 'CONTINUE';

-- ATTRITION ALERT
COPY INTO RAW.ATTRITION_ALERT (
    alertId, employeeId, attritionScore,
    alertReason, alertStatus
)
FROM (
    SELECT $1, $2, $3, $4, $5
    FROM @HR_CSV_STAGE/attrition_alert.csv
)
FILE_FORMAT = (FORMAT_NAME = 'CSV_FORMAT')
pattern = '.*attrition_alert.*[.]csv'
ON_ERROR    = 'CONTINUE';



-- Temp table to land raw JSON rows
CREATE OR REPLACE TEMPORARY TABLE EMPLOYEE_METADATA_TEMP (
    metadata VARIANT
);

COPY INTO EMPLOYEE_METADATA_TEMP (metadata)
FROM (
    SELECT $1
    FROM @HR_JSON_STAGE/employee_metadata.json
)
FILE_FORMAT = (FORMAT_NAME = 'JSON_FORMAT')
pattern = '.*employee_metadata.*[.]json'
ON_ERROR    = 'CONTINUE';

SELECT * FROM EMPLOYEE_METADATA_TEMP;

UPDATE RAW.EMPLOYEE e
SET    employeeMetadata = f.value
FROM   EMPLOYEE_METADATA_TEMP t,
       LATERAL FLATTEN(input => t.metadata) f
WHERE  e.employeeId = f.value:employeeId::INT;

SELECT * FROM EMPLOYEE;


SELECT 'DEPARTMENT'        AS tableName, COUNT(*) AS rowCount FROM RAW.DEPARTMENT
UNION ALL
SELECT 'EMPLOYEE',                        COUNT(*) FROM RAW.EMPLOYEE
UNION ALL
SELECT 'ATTENDANCE',                      COUNT(*) FROM RAW.ATTENDANCE
UNION ALL
SELECT 'PERFORMANCE_REVIEW',              COUNT(*) FROM RAW.PERFORMANCE_REVIEW
UNION ALL
SELECT 'ATTRITION_ALERT',                 COUNT(*) FROM RAW.ATTRITION_ALERT;

-- Verify JSON metadata loaded correctly
SELECT employeeId, employeeName,
       employeeMetadata:skills::ARRAY        AS skills,
       employeeMetadata:certifications::ARRAY AS certifications,
       employeeMetadata:yearsExperience::INT  AS experience
FROM   RAW.EMPLOYEE
WHERE  employeeMetadata IS NOT NULL
LIMIT  5;

-- Check errors
SELECT *
FROM   TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
    TABLE_NAME    => 'EMPLOYEE',
    START_TIME    => DATEADD(HOURS, -1, CURRENT_TIMESTAMP())
));