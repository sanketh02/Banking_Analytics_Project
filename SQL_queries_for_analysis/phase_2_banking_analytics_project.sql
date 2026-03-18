-- banking_analysis_phase 2

use banking_analytics;

select * from customers limit 5;

-- 1.1  Standardize text columns (trim spaces, fix casing)
update customers set 
first_name = CONCAT(UPPER(LEFT(TRIM(first_name),1)), LOWER(SUBSTRING(TRIM(first_name),2))),
last_name  = CONCAT(UPPER(LEFT(TRIM(last_name),1)), LOWER(SUBSTRING(TRIM(last_name),2))),
city       = CONCAT(UPPER(LEFT(TRIM(city),1)), LOWER(SUBSTRING(TRIM(city),2))),
occupation = TRIM(occupation);

select * from branches limit 5;
UPDATE branches SET
branch_name  = TRIM(branch_name),
city         = CONCAT(UPPER(LEFT(TRIM(city),1)), LOWER(SUBSTRING(TRIM(city),2)));

-- 1.2  Fix NULL emails — replace with a placeholder
-- check if there is null values or not in email
select * from customers 
where email is null or email = '';

UPDATE customers
set email = concat('first_name','customer_id','@gmail.com')
where email is NULL or email = '';

-- 1.3  Fix invalid credit scores (must be 300–900)

