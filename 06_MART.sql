USE DATABASE HR_ANALYTICS_DB;
USE WAREHOUSE HR_ANALYTICS_WH;
USE SCHEMA MART;


--VIEW 1
CREATE OR REPLACE VIEW MART.VW_EMPLOYEE_PROFILE AS
SELECT
    e.employeeId,
    e.employeeName,
    e.designation,
    e.salary,
    d.departmentName,
    d.location,
    aa.attritionScore,
    aa.alertStatus,
    
FROM RAW.EMPLOYEE e
JOIN RAW.DEPARTMENT d ON e.department = d.departmentName
LEFT JOIN (
    -- only latest alert per employee
    SELECT employeeId, attritionScore, alertStatus
    FROM RAW.ATTRITION_ALERT
    QUALIFY ROW_NUMBER() OVER (PARTITION BY employeeId ORDER BY attritionScore DESC) = 1
) aa ON e.employeeId = aa.employeeId;

--VIEW 2
CREATE OR REPLACE VIEW MART.VW_DEPARTMENT_KPI AS
SELECT 
    d.departmentName,
    COUNT(DISTINCT e.employeeId)       AS total_employees,
    ROUND(AVG(pr.performanceScore), 1) AS avg_department_score,
    ROUND(AVG(a.workingHours), 1)      AS avg_daily_hours
FROM RAW.DEPARTMENT d
LEFT JOIN RAW.EMPLOYEE e 
    ON d.departmentName = e.department
LEFT JOIN RAW.PERFORMANCE_REVIEW pr 
    ON e.employeeId = pr.employeeId
LEFT JOIN RAW.ATTENDANCE a 
    ON e.employeeId = a.employeeId
GROUP BY d.departmentName;


--VIEW 3
CREATE OR REPLACE VIEW MART.VW_EMPLOYEE_SKILLS AS
SELECT 
    e.employeeId,
    e.employeeName,
    f.value::STRING AS skill
FROM RAW.EMPLOYEE e,
LATERAL FLATTEN(input => e.employeeMetadata:skills) f
WHERE e.employeeMetadata IS NOT NULL;

--VIEW 4
CREATE OR REPLACE VIEW MART.VW_EMPLOYEE_PERFORMANCE AS
SELECT
    e.employeeId,
    e.employeeName,
    e.designation,
    e.department,
    pr.reviewPeriod,
    pr.performanceScore,
    pr.feedback,
    CASE
        WHEN pr.performanceScore >= 8 THEN 'High Performer'
        WHEN pr.performanceScore >= 5 THEN 'Average Performer'
        ELSE                               'Low Performer'
    END AS performanceCategory
FROM RAW.EMPLOYEE e
JOIN RAW.PERFORMANCE_REVIEW pr ON e.employeeId = pr.employeeId
WHERE e.employeeStatus = 'ACTIVE';

--VIEW 5
CREATE OR REPLACE VIEW MART.VW_ATTENDANCE_TRENDS AS
SELECT
    e.employeeId,
    e.employeeName,
    e.department,
    DATE_TRUNC('MONTH', a.attendanceDate)   AS attendanceMonth,
    COUNT(CASE WHEN a.attendanceStatus = 'PRESENT'  THEN 1 END) AS presentDays,
    COUNT(CASE WHEN a.attendanceStatus = 'ABSENT'   THEN 1 END) AS absentDays,
    COUNT(CASE WHEN a.attendanceStatus = 'HALF_DAY' THEN 1 END) AS halfDays,
    ROUND(AVG(a.workingHours), 1)           AS avgWorkingHours,
    ROUND(
        COUNT(CASE WHEN a.attendanceStatus = 'PRESENT' THEN 1 END) * 100.0
        / NULLIF(COUNT(*), 0), 1
    )                                       AS attendanceRatePct
FROM RAW.ATTENDANCE a
JOIN RAW.EMPLOYEE e ON a.employeeId = e.employeeId
GROUP BY
    e.employeeId,
    e.employeeName,
    e.department,
    DATE_TRUNC('MONTH', a.attendanceDate);

--VIEW 6
CREATE OR REPLACE VIEW MART.VW_ATTRITION_ANALYSIS AS
SELECT
    e.employeeId,
    e.employeeName,
    e.designation,
    e.department,
    aa.attritionScore,
    aa.alertReason,
    aa.alertStatus,
    CASE
        WHEN aa.attritionScore >= 75 THEN 'Critical Risk'
        WHEN aa.attritionScore >= 50 THEN 'High Risk'
        WHEN aa.attritionScore >= 25 THEN 'Medium Risk'
        ELSE                              'Low Risk'
    END AS riskLevel
FROM RAW.EMPLOYEE e
JOIN RAW.ATTRITION_ALERT aa ON e.employeeId = aa.employeeId;



SELECT * FROM MART.VW_ATTENDANCE_TRENDS;
SELECT * FROM MART.VW_ATTRITION_ANALYSIS;
SELECT * FROM MART.VW_EMPLOYEE_PROFILE;
SELECT * FROM MART.VW_DEPARTMENT_KPI ORDER BY avg_department_score DESC;
SELECT * FROM MART.VW_EMPLOYEE_SKILLS;
SELECT * FROM MART.VW_EMPLOYEE_PERFORMANCE;