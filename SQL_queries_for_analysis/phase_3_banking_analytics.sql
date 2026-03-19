-- phase 3
use banking_analytics;

select * from transactions;

-- Monthly Transactions Summary -> Line chart in Power binlog
CREATE OR REPLACE VIEW vw_montly_transactions AS
SELECT
      date_format(transaction_date, '%Y-%m')  as txn_months,transaction_type,
      count(*)                                as total_transaxtions,
      sum(amount)                             as total_amount,
      avg(amount)                             as avg_amount,
      sum(case when is_fraud = 1 then 1 else 0 end) as fraud_count,
      sum(case when status = 'Failed' then 1 else 0 end) as failed_count
FROM transactions
GROUP BY txn_months, transaction_type
ORDER BY txn_months;

select * from vw_montly_transactions;

-- 2.2  Branch Performance KPIs  → Map / Bar chart in Power BI
CREATE OR REPLACE VIEW vw_branch_performance AS
SELECT
    b.branch_id,
    b.branch_name,
    b.city,
    COUNT(DISTINCT c.customer_id)               AS total_customers,
    COUNT(DISTINCT a.account_id)                AS total_accounts,
    COALESCE(SUM(a.balance), 0)                 AS total_deposits,
    COUNT(DISTINCT l.loan_id)                   AS total_loans,
    COALESCE(SUM(l.principal_amount), 0)        AS total_loan_amount,
    COUNT(DISTINCT CASE WHEN l.loan_status = 'NPA'
          THEN l.loan_id END)                   AS npa_loans,
    COALESCE(SUM(CASE WHEN l.loan_status = 'NPA'
          THEN l.outstanding_amount END), 0)    AS npa_amount
FROM branches b
LEFT JOIN customers   c ON b.branch_id = c.branch_id
LEFT JOIN accounts    a ON b.branch_id = a.branch_id AND a.status = 'Active'
LEFT JOIN loans       l ON b.branch_id = l.branch_id
GROUP BY b.branch_id, b.branch_name, b.city;

select * from vw_branch_performance ;

-- 2.3  NPA / Loan Default Analysis  → KPI card + table

CREATE OR REPLACE VIEW vw_npa_analysis AS
SELECT
    l.loan_id,
    l.loan_number,
    CONCAT(c.first_name, ' ', c.last_name)  AS customer_name,
    c.credit_score,
    c.monthly_income,
    l.loan_type,
    l.principal_amount,
    l.outstanding_amount,
    l.overdue_days,
    l.overdue_amount,
    l.loan_status,
    b.branch_name,
    b.city,
    CASE
        WHEN l.overdue_days BETWEEN 91  AND 180 THEN 'Sub-Standard'
        WHEN l.overdue_days BETWEEN 181 AND 365 THEN 'Doubtful'
        WHEN l.overdue_days > 365               THEN 'Loss Asset'
        ELSE 'Standard'
    END AS npa_classification
FROM loans l
JOIN customers c ON l.customer_id = c.customer_id
JOIN branches  b ON l.branch_id   = b.branch_id
WHERE l.loan_status IN ('NPA', 'Restructured');

select * from vw_npa_analysis;

-- 2.4  Fraud Transaction Analysis  → KPI card + table

CREATE OR REPLACE VIEW vw_fraud_analysis AS
SELECT
    t.transaction_id,
    t.transaction_ref,
    t.transaction_date,
    t.transaction_mode,
    t.amount,
    t.fraud_category,
    t.status,
    a.account_number,
    a.account_type,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.city,
    b.branch_name
FROM transactions t
JOIN accounts  a ON t.account_id  = a.account_id
JOIN customers c ON a.customer_id = c.customer_id
JOIN branches  b ON t.branch_id   = b.branch_id
WHERE t.is_fraud = 1;

-- 2.5  Customer 360 View  → Slicer/filter in Power BI
CREATE OR REPLACE VIEW vw_customer_360 AS
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name)  AS customer_name,
    c.gender,
    c.age,
    c.occupation,
    c.monthly_income,
    c.credit_score,
    c.kyc_status,
    c.city,
    b.branch_name,
    COUNT(DISTINCT a.account_id)            AS total_accounts,
    COALESCE(SUM(a.balance), 0)             AS total_balance,
    COUNT(DISTINCT l.loan_id)               AS total_loans,
    COALESCE(SUM(l.outstanding_amount), 0)  AS total_outstanding,
    COUNT(DISTINCT t.transaction_id)        AS total_transactions,
    MAX(t.transaction_date)                 AS last_transaction_date
FROM customers c
JOIN branches  b ON c.branch_id   = b.branch_id
LEFT JOIN accounts    a ON c.customer_id = a.customer_id
LEFT JOIN loans       l ON c.customer_id = l.customer_id
LEFT JOIN transactions t ON a.account_id = t.account_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.gender,
         c.age, c.occupation, c.monthly_income, c.credit_score,
         c.kyc_status, c.city, b.branch_name;
         
-- 2.6  KPI Summary View  → All KPI cards in Power BI
CREATE OR REPLACE VIEW vw_kpi_summary AS
SELECT
    -- Customer KPIs
    (SELECT COUNT(*)  FROM customers)                                           AS total_customers,
    (SELECT COUNT(*)  FROM customers WHERE kyc_status = 'Verified')             AS verified_customers,

    -- Account KPIs
    (SELECT COUNT(*)  FROM accounts  WHERE status = 'Active')                   AS active_accounts,
    (SELECT COALESCE(SUM(balance),0) FROM accounts WHERE status = 'Active')     AS total_deposits,

    -- Loan KPIs
    (SELECT COUNT(*)  FROM loans)                                               AS total_loans,
    (SELECT COALESCE(SUM(principal_amount),0) FROM loans)                       AS total_loan_disbursed,
    (SELECT COUNT(*)  FROM loans WHERE loan_status = 'NPA')                     AS npa_count,
    (SELECT ROUND(COUNT(*) * 100.0 /
        NULLIF((SELECT COUNT(*) FROM loans), 0), 2)
     FROM loans WHERE loan_status = 'NPA')                                      AS npa_ratio_pct,

    -- Transaction KPIs
    (SELECT COUNT(*)  FROM transactions WHERE status  = 'Success')              AS successful_transactions,
    (SELECT COALESCE(SUM(amount),0) FROM transactions WHERE transaction_type = 'Credit'
        AND status = 'Success')                                                 AS total_credits,
    (SELECT COALESCE(SUM(amount),0) FROM transactions WHERE transaction_type = 'Debit'
        AND status = 'Success')                                                 AS total_debits,

    -- Fraud KPIs
    (SELECT COUNT(*) FROM transactions WHERE is_fraud = 1)                      AS fraud_transactions,
    (SELECT ROUND(COUNT(*) * 100.0 /
        NULLIF((SELECT COUNT(*) FROM transactions), 0), 2)
     FROM transactions WHERE is_fraud = 1)                                      AS fraud_rate_pct,
    (SELECT COALESCE(SUM(amount),0) FROM transactions WHERE is_fraud = 1)       AS fraud_amount;
