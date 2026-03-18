-- step1 1: Create & use the database
CREATE DATABASE IF NOT EXISTS banking_analytics
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

-- step 2: verify id data base is created or not
show databases;

-- use database
use banking_analytics;

CREATE TABLE IF NOT EXISTS branches (
    branch_id        INT             NOT NULL AUTO_INCREMENT,
    branch_name      VARCHAR(100)    NOT NULL,
    city             VARCHAR(50)     NOT NULL,
    state            VARCHAR(50)     NOT NULL,
    ifsc_code        VARCHAR(15)     NOT NULL UNIQUE,
    contact_number   VARCHAR(20),
    manager_name     VARCHAR(100),
    opened_date      DATE,

    PRIMARY KEY (branch_id),
    INDEX idx_city (city)
);

CREATE TABLE IF NOT EXISTS customers (
    customer_id      INT             NOT NULL AUTO_INCREMENT,
    first_name       VARCHAR(50)     NOT NULL,
    last_name        VARCHAR(50)     NOT NULL,
    gender           ENUM('Male','Female','Other') NOT NULL,
    date_of_birth    DATE,
    age              TINYINT UNSIGNED,
    occupation       VARCHAR(50),
    monthly_income   DECIMAL(12,2),
    email            VARCHAR(100)    UNIQUE,
    phone_number     VARCHAR(20),
    address          VARCHAR(255),
    city             VARCHAR(50),
    pan_number       VARCHAR(10)     UNIQUE,
    kyc_status       ENUM('Verified','Pending','Rejected') DEFAULT 'Pending',
    branch_id        INT             NOT NULL,
    joining_date     DATE,
    credit_score     SMALLINT,      

    PRIMARY KEY (customer_id),
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id),
    INDEX idx_city        (city),
    INDEX idx_kyc         (kyc_status),
    INDEX idx_credit      (credit_score),
    INDEX idx_branch      (branch_id)
);

CREATE TABLE IF NOT EXISTS accounts (
    account_id       INT             NOT NULL AUTO_INCREMENT,
    account_number   VARCHAR(15)     NOT NULL UNIQUE,
    customer_id      INT             NOT NULL,
    account_type     ENUM('Savings','Current','Fixed Deposit','Recurring Deposit') NOT NULL,
    balance          DECIMAL(15,2)   DEFAULT 0.00,
    opening_date     DATE,
    status           ENUM('Active','Dormant','Closed') DEFAULT 'Active',
    branch_id        INT             NOT NULL,
    interest_rate    DECIMAL(5,2),

    PRIMARY KEY (account_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (branch_id)   REFERENCES branches(branch_id),
    INDEX idx_customer    (customer_id),
    INDEX idx_status      (status),
    INDEX idx_acc_type    (account_type)
);

CREATE TABLE IF NOT EXISTS loans (
    loan_id                         INT             NOT NULL AUTO_INCREMENT,
    loan_number                     VARCHAR(12)     NOT NULL UNIQUE,
    customer_id                     INT             NOT NULL,
    loan_type                       ENUM('Home Loan','Personal Loan','Car Loan',
                                         'Education Loan','Business Loan') NOT NULL,
    principal_amount                DECIMAL(15,2)   NOT NULL,
    interest_rate                   DECIMAL(5,2)    NOT NULL,
    tenure_months                   SMALLINT        NOT NULL,
    emi_amount                      DECIMAL(12,2),
    disbursed_date                  DATE,
    maturity_date                   DATE,
    loan_status                     ENUM('Active','Closed','NPA','Restructured') DEFAULT 'Active',
    outstanding_amount              DECIMAL(15,2)   DEFAULT 0.00,
    overdue_days                    INT             DEFAULT 0,
    overdue_amount                  DECIMAL(12,2)   DEFAULT 0.00,
    collateral_type                 VARCHAR(50),
    branch_id                       INT             NOT NULL,
    credit_score_at_disbursement    SMALLINT,

    PRIMARY KEY (loan_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (branch_id)   REFERENCES branches(branch_id),
    INDEX idx_loan_status     (loan_status),
    INDEX idx_loan_type       (loan_type),
    INDEX idx_overdue         (overdue_days),
    INDEX idx_loan_customer   (customer_id)
);

CREATE TABLE IF NOT EXISTS transactions (
    transaction_id          INT             NOT NULL AUTO_INCREMENT,
    transaction_ref         VARCHAR(15)     NOT NULL UNIQUE,
    account_id              INT             NOT NULL,
    account_number          VARCHAR(15)     NOT NULL,
    transaction_date        DATE            NOT NULL,
    transaction_time        TIME            NOT NULL,
    transaction_type        ENUM('Credit','Debit') NOT NULL,
    transaction_mode        ENUM('NEFT','IMPS','UPI','ATM','Cheque','RTGS','Online Transfer') NOT NULL,
    amount                  DECIMAL(15,2)   NOT NULL,
    counterparty_account    VARCHAR(15),
    description             VARCHAR(100),
    is_fraud                TINYINT(1)      DEFAULT 0,
    fraud_category          VARCHAR(50),
    status                  ENUM('Success','Failed','Pending') DEFAULT 'Success',
    branch_id               INT             NOT NULL,

    PRIMARY KEY (transaction_id),
    FOREIGN KEY (account_id)  REFERENCES accounts(account_id),
    FOREIGN KEY (branch_id)   REFERENCES branches(branch_id),
    INDEX idx_txn_date        (transaction_date),
    INDEX idx_txn_type        (transaction_type),
    INDEX idx_fraud           (is_fraud),
    INDEX idx_status          (status),
    INDEX idx_account         (account_id)
);

show tables;

-- Load data from xle file to table

-- 1. Branches
LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\branches.xls"
INTO TABLE branches
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(branch_id, branch_name, city, state, ifsc_code,
 contact_number, manager_name, opened_date);

-- set local_infile = 1 if you are loading from local file 
-- else set local_file = 0 if you are loading data from uploads file from sql server
SHOW VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 0;
SHOW VARIABLES LIKE 'secure_file_priv';
-- since we are loading data from uploads folder 

-- Customers
LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\customers.xls"
REPLACE
INTO TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Accounts
LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\accounts.xls"
REPLACE
INTO TABLE accounts
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWs;

-- Loans
LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\loans.xls"
REPLACE
INTO TABLE loans
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWs;

-- Transactions
LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\transactions.xls"
REPLACE
INTO TABLE transactions
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWs;

-- verify if data is loaded or not 
-- branches
select * from branches limit 10;
select count(*) from branches;
select max(branch_id) from branches;

-- customers
select * from customers limit 10;
select count(*) from customers;
select max(customer_id) from customers;

-- quick check
SELECT 'branches'    AS tables_1, COUNT(*) AS total_records FROM branches    UNION ALL
SELECT 'customers',               COUNT(*)          FROM customers   UNION ALL
SELECT 'accounts',                COUNT(*)          FROM accounts    UNION ALL
SELECT 'loans',                   COUNT(*)          FROM loans       UNION ALL
SELECT 'transactions',            COUNT(*)          FROM transactions;
