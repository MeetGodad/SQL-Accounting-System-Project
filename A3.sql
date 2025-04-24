-- Assignment 3: Develop and Test a Coded Solution in PL/SQL with Exception Handlers 
-- We will try to provide each guideline given beside our usage in {} braces.
 
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

  -- Variables for transaction balance checks
  v_total_debits NUMBER := 0;
  v_total_credits NUMBER := 0;

  v_acc_info acc_info_rec;
  -- Exception declarations
  e_invalid_trans_type EXCEPTION;
  e_invalid_account EXCEPTION;
  e_negative_amount EXCEPTION;
  e_missing_transaction_no EXCEPTION;
  e_imbalanced_transaction EXCEPTION;

  -- Error logging flag
  -- Will explain below why we used it!
  error_logged BOOLEAN;

BEGIN
  -- {An error in one transaction should not prevent the processing of other transactions (i.e., don’t leave the main looping structure when an error occurs).}
  -- Loop through each unique transaction
  FOR v_transaction IN transactions_cursor LOOP
    error_logged := FALSE; -- Reset error logged flag at the start of each transaction

    BEGIN
      -- Check for NULL transaction number (Our first error listed in document)
      IF v_transaction.Transaction_no IS NULL THEN
        RAISE e_missing_transaction_no;
      END IF;

      -- Initialize balances for each transaction 
      v_total_debits := 0;
      v_total_credits := 0;

      -- Insert transaction history
      INSERT INTO TRANSACTION_HISTORY(Transaction_no, Transaction_date, Description)
      VALUES (v_transaction.Transaction_no, v_transaction.Transaction_date, v_transaction.Description);

      -- Loop through each detail of the current transaction
      FOR v_detail IN transaction_details_cursor(v_transaction.Transaction_no) LOOP
        BEGIN
          -- Validate transaction type (5th error listed )
          IF v_detail.Transaction_type NOT IN ('C', 'D') THEN
            RAISE e_invalid_trans_type;
          END IF;

          -- Check for negative amounts (4th error listed)
          IF v_detail.Transaction_amount < 0 THEN
            RAISE e_negative_amount;
          END IF;

          BEGIN
            -- Fetch account balance and type
            SELECT Account_balance, Account_type_code INTO v_acc_info FROM ACCOUNT
            WHERE Account_no = v_detail.Account_no;

            -- Adjust the account balance based on the transaction type
            -- As per the feedback provided for assignment 2 we have altered our code accordingly.
            IF v_detail.Transaction_type = 'D' THEN
              v_acc_info.account_balance := v_acc_info.account_balance + v_detail.Transaction_amount;
              v_total_debits := v_total_debits + v_detail.Transaction_amount;
            ELSE
              v_acc_info.account_balance := v_acc_info.account_balance - v_detail.Transaction_amount;
              v_total_credits := v_total_credits + v_detail.Transaction_amount;
            END IF;

            -- Update the account balance
            UPDATE ACCOUNT SET Account_balance = v_acc_info.account_balance
            WHERE Account_no = v_detail.Account_no;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              RAISE e_invalid_account;
          END;

          -- Insert into transaction detail
          INSERT INTO TRANSACTION_DETAIL(Account_no, Transaction_no, Transaction_type, Transaction_amount)
          VALUES (v_detail.Account_no, v_transaction.Transaction_no, v_detail.Transaction_type, v_detail.Transaction_amount);

        EXCEPTION
          WHEN e_invalid_trans_type OR e_negative_amount THEN
            IF NOT error_logged THEN
              INSERT INTO WKIS_ERROR_LOG (Transaction_no, error_msg)
              VALUES (v_transaction.Transaction_no, 'Invalid transaction type or negative amount for transaction number: ' || TO_CHAR(v_transaction.Transaction_no));
              error_logged := TRUE;  -- Set flag after logging error
              --{Only the first error in a transaction should be recorded in the error log table (i.e., a specific transaction number should only appear once in the error log table). }
            END IF;
          WHEN e_invalid_account THEN
            IF NOT error_logged THEN
              INSERT INTO WKIS_ERROR_LOG (Transaction_no, error_msg)
              VALUES (v_transaction.Transaction_no, 'Invalid account number: ' || TO_CHAR(v_detail.Account_no));
              error_logged := TRUE;  -- Set flag after logging error
            END IF;
        END;
      END LOOP;

      -- Check if debits and credits are not equal
      IF v_total_debits != v_total_credits THEN
        RAISE e_imbalanced_transaction;
      END IF;

      -- Remove processed transaction from NEW_TRANSACTIONS
      DELETE FROM NEW_TRANSACTIONS WHERE Transaction_no = v_transaction.Transaction_no;

    EXCEPTION
      WHEN e_missing_transaction_no THEN
        IF NOT error_logged THEN
          INSERT INTO WKIS_ERROR_LOG (Transaction_no, error_msg)
          VALUES (NULL, 'Missing transaction number');
          error_logged := TRUE;
        END IF;
      WHEN e_imbalanced_transaction THEN
        IF NOT error_logged THEN
          INSERT INTO WKIS_ERROR_LOG (Transaction_no, error_msg)
          VALUES (v_transaction.Transaction_no, 'Imbalanced transaction: Debits and Credits not equal for transaction number: ' || TO_CHAR(v_transaction.Transaction_no));
          error_logged := TRUE;
        END IF;
    END;
  END LOOP;

  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    -- Handle unexpected errors
    DBMS_OUTPUT.PUT_LINE('Unexpected error: ' || SQLERRM);
    ROLLBACK;
END;
/
