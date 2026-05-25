USE DATABASE HR_ANALYTICS_DB;
USE WAREHOUSE HR_ANALYTICS_WH;
USE SCHEMA RAW;

-- STREAM --
SHOW STREAMS;

CREATE OR REPLACE STREAM STM_EMPLOYEE
    ON TABLE RAW.EMPLOYEE;

CREATE OR REPLACE STREAM STM_ATTENDANCE
    ON TABLE RAW.ATTENDANCE;

CREATE OR REPLACE STREAM STM_PERFORMANCE
    ON TABLE RAW.PERFORMANCE_REVIEW;

CREATE OR REPLACE STREAM STM_ATTRITION
    ON TABLE RAW.ATTRITION_ALERT;


-- TO LOAD INTO DIM_EMPLOYEE 

CREATE OR REPLACE TASK TSK_LOAD_EMPLOYEE
       WAREHOUSE = HR_ANALYTICS_WH
       SCHEDULE = '60 MINUTE'

AS
INSERT INTO CORE.DIM_EMPLOYEE(
    EMPLOYEEKEY, EMPLOYEEID, EMPLOYEENAME, EMAIL,
    DESIGNATION, EMPLOYEESTATUS, SALARY, HIREDATE
)
SELECT 
    EMPLOYEEKEY, EMPLOYEEID, EMPLOYEENAME, EMAIL,
    DESIGNATION, EMPLOYEESTATUS,SALARY, HIREDATE
FROM STM_EMPLOYEE
WHERE METADATA$ACTION = 'INSERT';

SHOW TASKS;


-- TO LOAD INTO FACT_ATTENDANCE -- 
CREATE OR REPLACE TASK TSK_LOAD_ATTENDANCE
    WAREHOUSE = HR_ANALYTICS_WH
    SCHEDULE  = '60 MINUTE'
AS
INSERT INTO CORE.FACT_ATTENDANCE (
    attendanceKey, attendanceId, employeeKey, departmentKey,
    dateKey, attendanceStatus, workingHours
)
SELECT
    S.ATTENDANCEKEY,
    s.attendanceId,
    de.employeeKey,
    dd.departmentKey,
    TO_NUMBER(TO_CHAR(s.attendanceDate, 'YYYYMMDD')),
    s.attendanceStatus,
    s.workingHours
FROM STM_ATTENDANCE s
JOIN CORE.DIM_EMPLOYEE   de ON s.employeeId    = de.employeeId
JOIN RAW.EMPLOYEE        re ON s.employeeId    = re.employeeId
JOIN CORE.DIM_DEPARTMENT dd ON re.department   = dd.departmentName
WHERE s.METADATA$ACTION = 'INSERT';


-- Task 3: New performance reviews → FACT_PERFORMANCE
CREATE OR REPLACE TASK TSK_LOAD_PERFORMANCE
    WAREHOUSE = HR_ANALYTICS_WH
    SCHEDULE  = '60 MINUTE'
AS
INSERT INTO CORE.FACT_PERFORMANCE (
    reviewKey, reviewId, employeeKey, departmentKey,
    reviewPeriod, performanceScore, feedback
)
SELECT
    S.REVIEWKEY,
    s.reviewId,
    de.employeeKey,
    dd.departmentKey,
    s.reviewPeriod,
    s.performanceScore,
    s.feedback
FROM STM_PERFORMANCE s
JOIN CORE.DIM_EMPLOYEE   de ON s.employeeId  = de.employeeId
JOIN RAW.EMPLOYEE        re ON s.employeeId  = re.employeeId
JOIN CORE.DIM_DEPARTMENT dd ON re.department = dd.departmentName
WHERE s.METADATA$ACTION = 'INSERT';


-- DYNAMIC TABLE -- 

CREATE OR REPLACE DYNAMIC TABLE MART.DT_DEPT_PERFORMANCE
    TARGET_LAG = '1 hour'
    WAREHOUSE  = HR_ANALYTICS_WH
AS
SELECT
    d.departmentName,
    COUNT(DISTINCT e.employeeId)        AS totalEmployees,
    ROUND(AVG(pr.performanceScore), 2)  AS avgScore,
    COUNT(CASE WHEN pr.performanceScore < 5 THEN 1 END) AS low_Performers,
    COUNT(CASE WHEN PR.PERFORMANCESCORE >= 8 THEN 1 END ) AS TOP_PERFORMERS
FROM RAW.DEPARTMENT d
LEFT JOIN RAW.EMPLOYEE e  ON d.departmentName = e.department
LEFT JOIN RAW.PERFORMANCE_REVIEW pr ON e.employeeId = pr.employeeId
GROUP BY d.departmentName;


CREATE OR REPLACE DYNAMIC TABLE MART.DT_ATTRITION_RISK
    TARGET_LAG = '1 hour'
    WAREHOUSE  = HR_ANALYTICS_WH
AS
SELECT
    e.employeeId,
    e.employeeName,
    e.department,
    aa.attritionScore,
    aa.alertReason,
    CASE
        WHEN aa.attritionScore >= 75 THEN 'Critical Risk'
        WHEN aa.attritionScore >= 50 THEN 'High Risk'
        ELSE                              'Medium Risk'
    END AS riskLevel
FROM RAW.EMPLOYEE e
JOIN RAW.ATTRITION_ALERT aa ON e.employeeId = aa.employeeId;

SELECT * FROM MART.DT_ATTRITION_RISK;

-- TO START TASKS -- 

-- ALTER TASK RAW.TSK_LOAD_EMPLOYEE    RESUME;
-- ALTER TASK RAW.TSK_LOAD_ATTENDANCE  RESUME;
-- ALTER TASK RAW.TSK_LOAD_PERFORMANCE RESUME;

-- ENSURE SCHEMA --

SHOW STREAMS IN SCHEMA RAW;
SHOW TASKS IN SCHEMA RAW;
SHOW DYNAMIC TABLES IN SCHEMA MART;
