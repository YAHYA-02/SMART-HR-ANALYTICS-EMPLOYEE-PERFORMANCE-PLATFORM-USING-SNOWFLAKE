USE WAREHOUSE HR_ANALYTICS_WH;
USE DATABASE HR_ANALYTICS_DB;
USE SCHEMA RAW;


CREATE OR REPLACE PIPE PIPE_EMPLOYEE
    AUTO_INGEST = FALSE
AS
COPY INTO RAW.EMPLOYEE (
    employeeId, employeeName, email, department,
    designation, employeeStatus, salary, hireDate
)
FROM (
    SELECT $1, $2, $3, $4, $5, $6, $7,
           TO_DATE($8, 'DD-MM-YYYY')
    FROM @HR_CSV_STAGE
)
FILE_FORMAT = (FORMAT_NAME = 'CSV_FORMAT')
PATTERN     = '.*employee.*\.csv';  


CREATE OR REPLACE PIPE RAW.PIPE_ATTENDANCE
    AUTO_INGEST = FALSE
    
AS
COPY INTO RAW.ATTENDANCE (
    attendanceId, employeeId, attendanceDate,
    attendanceStatus, workingHours
)
FROM (
    SELECT $1, $2, $3, $4, $5
    FROM @HR_CSV_STAGE
)
FILE_FORMAT = (FORMAT_NAME = 'CSV_FORMAT')
PATTERN     = '.*attendance.*\.csv';



CREATE OR REPLACE PIPE PIPE_PERFORMANCE
    AUTO_INGEST = FALSE
    
AS
COPY INTO RAW.PERFORMANCE_REVIEW (
    reviewId, employeeId, reviewPeriod,
    performanceScore, feedback
)
FROM (
    SELECT $1, $2, $3, $4, $5
    FROM @HR_CSV_STAGE
)
FILE_FORMAT = (FORMAT_NAME = 'CSV_FORMAT')
PATTERN     = '.*performance.*\.csv';



CREATE OR REPLACE PIPE PIPE_ATTRITION
    AUTO_INGEST = FALSE
AS
COPY INTO RAW.ATTRITION_ALERT (
    alertId, employeeId, attritionScore,
    alertReason, alertStatus
)
FROM (
    SELECT $1, $2, $3, $4, $5
    FROM @HR_CSV_STAGE
)
FILE_FORMAT = (FORMAT_NAME = 'CSV_FORMAT')
PATTERN     = '.*attrition.*\.csv';



CREATE OR REPLACE PIPE PIPE_EMPLOYEE_METADATA
    AUTO_INGEST = FALSE
AS
COPY INTO EMPLOYEE_METADATA_TEMP (metadata)
FROM (
    SELECT $1
    FROM @HR_JSON_STAGE
)
FILE_FORMAT = (FORMAT_NAME = 'JSON_FORMAT')
PATTERN     = '.*employee.*\.json';



ALTER PIPE PIPE_EMPLOYEE REFRESH;
ALTER PIPE PIPE_ATTENDANCE REFRESH;
ALTER PIPE PIPE_PERFORMANCE REFRESH;
ALTER PIPE PIPE_ATTRITION REFRESH;
ALTER PIPE PIPE_EMPLOYEE_METADATA REFRESH;

-- Check pipe load history
SELECT SYSTEM$PIPE_STATUS('PIPE_EMPLOYEE');
SELECT SYSTEM$PIPE_STATUS('PIPE_ATTENDANCE');