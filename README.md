# WKIS Accounting System - SQL/PLSQL Solution

[![License](https://img.shields.io/badge/License-Educational-blue.svg)](LICENSE)

## Overview

This project implements a double-entry accounting system for We Keep It Storage (WKIS) using Oracle SQL and PL/SQL.  The solution automates transaction processing, maintains account balances, and enforces accounting rules through robust database design and exception handling.  It addresses requirements outlined in the assignment briefs (Assignment 2 and Assignment 3).

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Database Design](#database-design)
- [Business Problem](#business-problem)
- [How It Works](#how-it-works)
- [Error Handling](#error-handling)
- [Setup & Usage](#setup--usage)
- [Testing](#testing)
- [License](#license)

## Features

- **Double-entry accounting:** Ensures every transaction is balanced (debits = credits).
- **Automated transaction posting:**  Moves transactions from a staging table (`new_transactions`) to history and detail tables, updating account balances.
- **Robust error handling:** Catches and logs invalid data (e.g., missing transaction numbers, invalid accounts, negative amounts, unbalanced transactions). Only the first error for each transaction is logged.
- **Comprehensive schema:**  Includes tables for accounts, transactions, payroll, and error logs.
- **Fully tested:** Includes clean and erroneous test datasets (`A3_test-dataset_2-Clean-and-Erroneous.sql`).  Transactions that produce errors remain in `NEW_TRANSACTIONS`.
- **Adheres to assignment guidelines:** Implemented using a single anonymous PL/SQL block, nested cursors, and avoids restricted elements (GOTOs, SAVEPOINTs, arrays, stored programs).

## Database Design

The database consists of the following key tables, designed to meet WKIS’s accounting needs:

| Table                  | Purpose                                                                |
|------------------------|------------------------------------------------------------------------|
| `account_type`         | Defines account categories (Asset, Liability, etc.)                    |
| `account`              | Stores individual accounts and balances                                |
| `transaction_history`  | Logs transaction metadata (number, date, description)                  |
| `transaction_detail`   | Records debits and credits for each transaction                        |
| `new_transactions`     | Staging table for incoming transactions                                |
| `wkis_error_log`       | Logs errors detected during processing                                  |
| `payroll_load`         | Handles payroll data                                                   |
| `payroll_processing`   | Tracks payroll processing status                                       |

Constraints are defined in [`ALL_TOGETHER.SQL`](ALL_TOGETHER.SQL).

**See [`Create Database.SQL`](ALL_TOGETHER.SQL) for the full schema, sample data, and table creation scripts.**

## Business Problem

WKIS required an automated accounting system to:

- Process transactions from a holding table (`new_transactions`).
- Insert valid transactions into history and detail tables.
- Update account balances correctly based on account and transaction type.
- Detect and log errors without halting processing for other transactions, in compliance with Assignment 3 requirements.

The system must comply with double-entry accounting principles and handle real-world data errors gracefully.

## How It Works

1. **Schema Setup:**  
   Run `ALL_TOGETHER.SQL` to create all tables, constraints, and insert initial data.  The `wkis_seq` sequence is used to generate unique transaction numbers.


2. **Transaction Processing:**  
- The PL/SQL script (`Group_group5_A3.sql`) processes each transaction from `new_transactions`:
  - Inserts transaction metadata into `transaction_history`.
  - Inserts each debit/credit entry into `transaction_detail`.
  - Updates the corresponding account balances in `account`.
  - Removes successfully processed transactions from `new_transactions` *only if no errors are encountered*.


## Error Handling

The solution detects and logs the following errors in the `WKIS_ERROR_LOG` table, adhering to Assignment 3’s guidelines:

- Missing transaction numbers (NULL transaction number)
- Debits and credits that are not equal
- Invalid account numbers (when the account number is not in the `ACCOUNT` table)
- Negative values given for a transaction amount
- Invalid transaction types (any transaction type except 'C' and 'D' is invalid)
- Unanticipated errors (system-generated messages)

Only the *first* error encountered for a given transaction is logged. Transactions with errors remain in the `NEW_TRANSACTIONS` table.

**Example PL/SQL Error Handling:**


## Setup & Usage

1. **Requirements:**
   - Oracle SQL\*Plus or a compatible environment.

2. **Steps:**
   - Clone this repository:
     ```
     git clone https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME.git
     cd YOUR_REPO_NAME
     ```
   - Run `ALL_TOGETHER.SQL` to set up the schema and insert initial data:
     ```
     sqlplus your_user/your_password@your_db < ALL_TOGETHER.SQL
     ```
   - Run `Group_group5_A3.sql` to process transactions and demonstrate error handling:
     ```
     sqlplus your_user/your_password@your_db < Group_group5_A3.sql
     ```

3. **Review Results:**
   - Check the `account` table for updated balances.
   - Check the `transaction_history` and `transaction_detail` tables for processed transactions.
   - Query the `wkis_error_log` table to identify any errors encountered during processing:
     ```
     SELECT * FROM wkis_error_log;
     ```
   - Verify that transactions with errors remain in the `NEW_TRANSACTIONS` table.

## Testing

- Clean and erroneous datasets are provided in `A3_test-dataset_2-Clean-and-Erroneous.sql`.  This dataset is used to test the error handling and transaction processing logic.
- You can add your own test data to the `new_transactions` table for further validation.  Ensure your test cases cover various error conditions.

## License

This project is for educational purposes only..

---




