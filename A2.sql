-- Assignment 2: Develop and Test a Coded Solution 

SET SERVEROUTPUT ON;
DECLARE
  -- Record to hold account's current balance and type
  TYPE acc_info_rec IS RECORD (
    account_balance ACCOUNT.ACCOUNT_BALANCE%TYPE,
    account_type_code ACCOUNT.ACCOUNT_TYPE_CODE%TYPE
  );

  -- Cursor to fetch distinct transactions from NEW_TRANSACTIONS
  CURSOR transactions_cursor IS
    SELECT DISTINCT Transaction_no, Transaction_date, Description
    FROM NEW_TRANSACTIONS;
  
  -- Nested cursor to fetch transaction details for each transaction
  CURSOR transaction_details_cursor(p_transaction_no NEW_TRANSACTIONS.TRANSACTION_NO%TYPE) IS
    SELECT Account_no, Transaction_type, Transaction_amount
    FROM NEW_TRANSACTIONS
    WHERE Transaction_no = p_transaction_no;
  
  v_acc_info acc_info_rec;

BEGIN
  -- Loop through each unique transaction (As we are assuming that every transction number is unique)
  FOR v_transaction IN transactions_cursor LOOP
    -- Insert transaction history
    INSERT INTO TRANSACTION_HISTORY(Transaction_no, Transaction_date, Description)
    VALUES (v_transaction.Transaction_no, v_transaction.Transaction_date, v_transaction.Description);

    -- Loop through each detail of the current transaction
    FOR v_detail IN transaction_details_cursor(v_transaction.Transaction_no) LOOP
            -- Fetch account balance and type
      SELECT Account_balance, Account_type_code INTO v_acc_info FROM ACCOUNT
      WHERE Account_no = v_detail.Account_no;
      -- As per the instructions provided we can assume that the accounting equation for each transaction holds true. For this program we do not have to validate the accounting equation.
      -- Determine how to adjust the account balance based on account type and transaction type
       
      IF v_detail.Transaction_type = 'D' THEN
        IF v_acc_info.Account_type_code IN ('A', 'EX') THEN -- Assets and Expenses increase on Debit
          v_acc_info.account_balance := v_acc_info.account_balance + v_detail.Transaction_amount;
        ELSE -- Liabilities, Owner's Equity, and Revenue decrease on Debit
          v_acc_info.account_balance := v_acc_info.account_balance - v_detail.Transaction_amount;
        END IF;
      ELSIF v_detail.Transaction_type = 'C' THEN
        IF v_acc_info.Account_type_code IN ('L', 'OE', 'RE') THEN -- Liabilities, Owner's Equity, and Revenue increase on Credit
          v_acc_info.account_balance := v_acc_info.account_balance + v_detail.Transaction_amount;
        ELSE -- Assets and Expenses decrease on Credit
          v_acc_info.account_balance := v_acc_info.account_balance - v_detail.Transaction_amount;
        END IF;
      END IF;

      
      -- Update the account balance
      UPDATE ACCOUNT SET Account_balance = v_acc_info.account_balance
      WHERE Account_no = v_detail.Account_no;
      
      -- Insert into transaction detail
      INSERT INTO TRANSACTION_DETAIL(Account_no, Transaction_no, Transaction_type, Transaction_amount)
      VALUES (v_detail.Account_no, v_transaction.Transaction_no, v_detail.Transaction_type, v_detail.Transaction_amount);
    END LOOP;

    -- Remove processed transaction from NEW_TRANSACTIONS
    DELETE FROM NEW_TRANSACTIONS WHERE Transaction_no = v_transaction.Transaction_no;
  END LOOP;

  COMMIT;
END;
/
