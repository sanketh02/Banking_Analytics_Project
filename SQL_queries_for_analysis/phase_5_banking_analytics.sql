-- phase 5

-- 4.1  AFTER INSERT on transactions
-- → Auto-flag fraud if amount > 1,00,000 via UPI/ATM
DELIMITER $$
CREATE TRIGGER IF NOT EXISTS trg_flag_large_fraud
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    IF NEW.amount > 100000
       AND NEW.transaction_mode IN ('UPI', 'ATM')
       AND NEW.is_fraud = 0 THEN

        UPDATE transactions
        SET    is_fraud       = 1,
               fraud_category = 'High Value Suspicious'
        WHERE  transaction_id = NEW.transaction_id;
    END IF;
END$$
DELIMITER ;

-- 4.2  AFTER INSERT on transactions
-- → Auto update account balance (safety net)
DELIMITER $$
CREATE TRIGGER IF NOT EXISTS trg_update_balance_on_txn
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    IF NEW.status = 'Success' THEN
        IF NEW.transaction_type = 'Credit' THEN
            UPDATE accounts
            SET balance = balance + NEW.amount
            WHERE account_id = NEW.account_id;
        ELSEIF NEW.transaction_type = 'Debit' THEN
            UPDATE accounts
            SET balance = balance - NEW.amount
            WHERE account_id = NEW.account_id;
        END IF;
    END IF;
END$$
DELIMITER ;

-- 4.3  AFTER UPDATE on loans
-- → Auto update customer credit score when loan goes NPA

DELIMITER $$
CREATE TRIGGER IF NOT EXISTS trg_credit_score_on_npa
AFTER UPDATE ON loans
FOR EACH ROW
BEGIN
    IF NEW.loan_status = 'NPA' AND OLD.loan_status != 'NPA' THEN
        UPDATE customers
        SET credit_score = GREATEST(300, credit_score - 80)
        WHERE customer_id = NEW.customer_id;
    END IF;
END$$
DELIMITER ;

SHOW FULL TABLES WHERE Table_type = 'VIEW';
SHOW TRIGGERS;

