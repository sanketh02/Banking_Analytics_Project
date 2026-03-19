-- Phase 4

-- 3.1  Get full customer profile by customer_id
DELIMITER $$
CREATE PROCEDURE sp_get_customer_profile(IN p_customer_id INT)
BEGIN
    SELECT * FROM vw_customer_360
    WHERE customer_id = p_customer_id;
END$$
DELIMITER ;


select * from vw_customer_360 ;

SELECT * FROM vw_customer_360
    WHERE customer_id = 700;
    
call  sp_get_customer_profile(400)  ;

-- 3.2  Get branch-wise KPI report for a given city
DELIMITER $$
CREATE PROCEDURE sp_branch_kpi_by_city(IN p_city VARCHAR(50))
BEGIN
    SELECT * FROM vw_branch_performance
    WHERE city = p_city
    ORDER BY total_deposits DESC;
END$$
DELIMITER ;


call sp_branch_kpi_by_city("pune" ) ;

-- 3.3  Insert new transaction (used for auto-refresh demo)
DELIMITER $$
CREATE PROCEDURE sp_insert_transaction(
    IN p_account_id         INT,
    IN p_transaction_type   VARCHAR(10),
    IN p_transaction_mode   VARCHAR(20),
    IN p_amount             DECIMAL(15,2),
    IN p_description        VARCHAR(100)
)
BEGIN
    DECLARE v_branch_id      INT;
    DECLARE v_account_number VARCHAR(15);
    DECLARE v_ref            VARCHAR(15);

    -- Get branch and account number
    SELECT branch_id, account_number
    INTO v_branch_id, v_account_number
    FROM accounts WHERE account_id = p_account_id;

    -- Generate unique transaction ref
    SET v_ref = CONCAT('TXN', LPAD(FLOOR(RAND() * 9999999999), 10, '0'));

    -- Insert transaction
    INSERT INTO transactions (
        transaction_ref, account_id, account_number,
        transaction_date, transaction_time,
        transaction_type, transaction_mode,
        amount, description, is_fraud, fraud_category, status, branch_id
    ) VALUES (
        v_ref, p_account_id, v_account_number,
        CURDATE(), CURTIME(),
        p_transaction_type, p_transaction_mode,
        p_amount, p_description, 0, 'None', 'Success', v_branch_id
    );

    -- Update account balance
    IF p_transaction_type = 'Credit' THEN
        UPDATE accounts SET balance = balance + p_amount
        WHERE account_id = p_account_id;
    ELSE
        UPDATE accounts SET balance = balance - p_amount
        WHERE account_id = p_account_id;
    END IF;

    SELECT 'Transaction inserted successfully' AS message,
            v_ref AS transaction_ref;
END$$
DELIMITER ;


