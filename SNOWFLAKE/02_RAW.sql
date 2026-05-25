USE WAREHOUSE HR_ANALYTICS_WH;
USE DATABASE HR_ANALYTICS_DB;

USE SCHEMA RAW;

CREATE OR REPLACE TABLE RAW.EMPLOYEE (
    employeeId       INT             NOT NULL,
    employeeName     VARCHAR(100),
    email            VARCHAR(150),
    department       VARCHAR(100),
    designation      VARCHAR(100),
    employeeStatus   VARCHAR(20),
    salary           DECIMAL(10,2),
    hireDate         DATE,
    employeeMetadata VARIANT
);

CREATE OR REPLACE TABLE RAW.DEPARTMENT (
    departmentId    INT             NOT NULL,
    departmentName  VARCHAR(100),
    location        VARCHAR(100),
    managerName     VARCHAR(100)
);

CREATE OR REPLACE TABLE RAW.ATTENDANCE (
    attendanceId     INT             NOT NULL,
    employeeId       INT,
    attendanceDate   DATE,
    attendanceStatus VARCHAR(20),
    workingHours     DECIMAL(4,2)
);

CREATE OR REPLACE TABLE RAW.PERFORMANCE_REVIEW (
    reviewId         INT             NOT NULL,
    employeeId       INT,
    reviewPeriod     VARCHAR(20),
    performanceScore DECIMAL(3,1),
    feedback         TEXT
);

CREATE OR REPLACE TABLE RAW.ATTRITION_ALERT (
    alertId         INT             NOT NULL,
    employeeId      INT             NOT NULL,
    attritionScore  DECIMAL(5,2)    NOT NULL,
    alertReason     VARCHAR(255),
    alertStatus     VARCHAR(20)
);

