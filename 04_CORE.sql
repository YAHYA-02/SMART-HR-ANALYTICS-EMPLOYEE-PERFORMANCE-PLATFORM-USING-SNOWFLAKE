USE WAREHOUSE HR_ANALYTICS_WH;
USE DATABASE HR_ANALYTICS_DB;
USE SCHEMA CORE;


-- DIMENSION: EMPLOYEE
CREATE OR REPLACE TABLE CORE.DIM_EMPLOYEE (
    employeeKey     INT             NOT NULL,        
    employeeId      INT,
    employeeName    VARCHAR(100),
    email           VARCHAR(150),
    designation     VARCHAR(100),
    employeeStatus  VARCHAR(20),
    salary          DECIMAL(10,2),
    hireDate        DATE,
    CONSTRAINT pk_dim_employee PRIMARY KEY (employeeKey)
);

-- DIMENSION: DEPARTMENT
CREATE OR REPLACE TABLE CORE.DIM_DEPARTMENT (
    departmentKey   INT             NOT NULL,        
    departmentId    INT,
    departmentName  VARCHAR(100),
    location        VARCHAR(100),
    managerName     VARCHAR(100),
    CONSTRAINT pk_dim_department PRIMARY KEY (departmentKey)
);

-- FACT ATTENDANCE
CREATE OR REPLACE TABLE CORE.FACT_ATTENDANCE (
    attendanceKey    INT NOT NULL,
    attendanceId     INT,
    employeeKey      INT,
    departmentKey    INT,
    dateKey          INT,
    attendanceStatus VARCHAR(20),
    workingHours     DECIMAL(4,2),
    CONSTRAINT pk_fact_attendance   PRIMARY KEY (attendanceKey),
    CONSTRAINT fk_fact_emp          FOREIGN KEY (employeeKey)   REFERENCES CORE.DIM_EMPLOYEE(employeeKey),
    CONSTRAINT fk_fact_dept         FOREIGN KEY (departmentKey) REFERENCES CORE.DIM_DEPARTMENT(departmentKey),
    CONSTRAINT fk_fact_date         FOREIGN KEY (dateKey)       REFERENCES CORE.DIM_DATE(dateKey)
);

-- FACT: PERFORMANCE
CREATE OR REPLACE TABLE CORE.FACT_PERFORMANCE (
    reviewKey        INT NOT NULL,
    reviewId         INT,
    employeeKey      INT,
    departmentKey    INT,
    reviewPeriod     VARCHAR(20),
    performanceScore DECIMAL(3,1),
    feedback         TEXT,
    CONSTRAINT pk_fact_perf   PRIMARY KEY (reviewKey),
    CONSTRAINT fk_perf_emp    FOREIGN KEY (employeeKey)   REFERENCES CORE.DIM_EMPLOYEE(employeeKey),
    CONSTRAINT fk_perf_dept   FOREIGN KEY (departmentKey) REFERENCES CORE.DIM_DEPARTMENT(departmentKey)
);

-- LOAD INTO CORE 

INSERT INTO CORE.DIM_DEPARTMENT (
    departmentKey, departmentId, departmentName, location, managerName
)
SELECT
    ROW_NUMBER() OVER (ORDER BY departmentId) AS departmentKey,
    departmentId,
    departmentName,
    location,
    managerName
FROM RAW.DEPARTMENT;

-- Verify
SELECT * FROM CORE.DIM_DEPARTMENT;


INSERT INTO CORE.DIM_EMPLOYEE (
    employeeKey, employeeId, employeeName, email,
    designation, employeeStatus, salary, hireDate
)
SELECT
    ROW_NUMBER() OVER (ORDER BY employeeId) AS employeeKey,
    employeeId,
    employeeName,
    email,
    designation,
    employeeStatus,
    salary,
    hireDate
FROM RAW.EMPLOYEE;

-- Verify
SELECT * FROM CORE.DIM_EMPLOYEE;


-- Verify
SELECT * FROM CORE.DIM_DATE 
WHERE fullDate BETWEEN '2025-01-01' AND '2025-01-07';


INSERT INTO CORE.FACT_ATTENDANCE (
    attendanceKey, attendanceId, employeeKey, departmentKey,
    dateKey, attendanceStatus, workingHours
)
SELECT
    ROW_NUMBER() OVER (ORDER BY a.attendanceId) AS attendanceKey,
    a.attendanceId,
    de.employeeKey,
    dd.departmentKey,
    TO_NUMBER(TO_CHAR(a.attendanceDate, 'YYYYMMDD')) AS dateKey,
    a.attendanceStatus,
    a.workingHours
FROM RAW.ATTENDANCE a
JOIN RAW.EMPLOYEE    re ON a.employeeId      = re.employeeId
JOIN CORE.DIM_EMPLOYEE de ON re.employeeId  = de.employeeId
JOIN CORE.DIM_DEPARTMENT dd ON re.department = dd.departmentName;

-- Verify
SELECT * FROM CORE.FACT_ATTENDANCE;



INSERT INTO CORE.FACT_PERFORMANCE (
    reviewKey, reviewId, employeeKey, departmentKey,
    reviewPeriod, performanceScore, feedback
)
SELECT
    ROW_NUMBER() OVER (ORDER BY pr.reviewId)    AS reviewKey,
    pr.reviewId,
    de.employeeKey,
    dd.departmentKey,
    pr.reviewPeriod,
    pr.performanceScore,
    pr.feedback
FROM RAW.PERFORMANCE_REVIEW pr
JOIN RAW.EMPLOYEE      re ON pr.employeeId     = re.employeeId
JOIN CORE.DIM_EMPLOYEE de ON re.employeeId     = de.employeeId
JOIN CORE.DIM_DEPARTMENT dd ON re.department   = dd.departmentName;

-- Verify
SELECT MAX(PERFORMANCESCORE) FROM FACT_PERFORMANCE;