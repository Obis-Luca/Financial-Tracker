//
//  Db.swift
//  ExpenseTracker
//
//  Created by Luca Obis on 21.12.2024.
//

import SQLite3
import Foundation

var db: OpaquePointer?

func createDatabase() {
    // Locate the Documents directory for the app
    let fileURL = try! FileManager.default
        .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        .appendingPathComponent("ExpenseTracker.sqlite")

    // Open (or create) the database
    if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
        print("Error opening or creating the database")
    } else {
        print("Database created/opened successfully at \(fileURL.path)")
    }
}

func dropTables()
{
    let dropTransactions = "DROP Table Transactions";
    let dropCategories = "DROP Table Category";
    
    executeQuery(dropTransactions);
    executeQuery(dropCategories);
}

func createTables() {
    let createCategoryTableQuery = """
    
    CREATE TABLE IF NOT EXISTS Category (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL DEFAULT '',
        mainCategoryId INTEGER,
        FOREIGN KEY (mainCategoryId) REFERENCES Category(id) ON DELETE SET NULL ON UPDATE CASCADE
    );
    """

    let createTransactionTableQuery = """
    
    CREATE TABLE IF NOT EXISTS Transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        institution TEXT,
        account TEXT,
        merchant TEXT,
        amount REAL,
        type TEXT,
        categoryId INTEGER,
        category TEXT,
        isPending INTEGER DEFAULT 0,
        isTransfer INTEGER DEFAULT 0,
        isExpense INTEGER DEFAULT 0,
        isEdited INTEGER DEFAULT 0,
        FOREIGN KEY (categoryId) REFERENCES Category(id)
    );
    """

    executeQuery(createCategoryTableQuery)
    executeQuery(createTransactionTableQuery)
    
}

func insertCategoryData() {
    let insertCategoryQuery = """
    
    INSERT INTO Category (id, name) VALUES
    (101, 'Public Transportation'),
    (102, 'Taxi'),
    (201, 'Mobile Phone'),
    (301, 'Movies & DVDs'),
    (401, 'Bank Fee'),
    (402, 'Finance Charge'),
    (501, 'Groceries'),
    (502, 'Restaurants'),
    (601, 'Rent'),
    (602, 'Home Supplies'),
    (701, 'Paycheque'),
    (801, 'Software'),  
    (901, 'Credit Card Payment');
    """

    executeQuery(insertCategoryQuery)
}

func insertTransactionData() {
    let insertTransactionQuery = """
    
    INSERT INTO Transactions (
        id, date, institution, account, merchant, amount, type, categoryId, category, isPending, isTransfer, isExpense, isEdited
    ) VALUES
        (25, '02/16/2022', 'Desjardins', 'Visa Desjardins', 'STM', 6.50, 'debit', 101, 'Public Transportation', 1, 0, 1, 0),
        (24, '02/16/2022', 'Desjardins', 'Visa Desjardins', 'Copper Branch', 23.86, 'debit', 502, 'Restaurants', 0, 0, 1, 0),
        (23, '02/15/2022', 'Desjardins', 'Personal chequing account', 'Payroll', 2000.00, 'credit', 701, 'Paycheque', 0, 0, 0, 0),
        (22, '02/14/2022', 'Desjardins', 'Visa Desjardins', 'Interest Charges', 74.92, 'debit', 402, 'Finance Charge', 0, 0, 1, 0),
        (21, '02/04/2022', 'Desjardins', 'Visa Desjardins', 'Uber.com', 10.35, 'debit', 102, 'Taxi', 0, 0, 1, 0),
        (20, '02/03/2022', 'Desjardins', 'Visa Desjardins', 'Payment', 1000.00, 'credit', 901, 'Credit Card Payment', 0, 1, 0, 0),
        (19, '02/03/2022', 'Desjardins', 'Personal chequing account', 'Bill payment - Desjardins Visa Or Modulo', 1000.00, 'debit', 901, 'Credit Card Payment', 0, 1, 0, 0),
        (18, '02/02/2022', 'Desjardins', 'Visa Desjardins', 'Telus Mobility', 61.46, 'debit', 201, 'Mobile Phone', 0, 0, 1, 0),
        (17, '02/01/2022', 'Desjardins', 'Visa Desjardins', 'Amazon', 14.69, 'debit', 602, 'Home Supplies', 0, 0, 1, 0),
        (16, '02/01/2022', 'Desjardins', 'Personal chequing account', 'Rent', 800.00, 'debit', 601, 'Rent', 0, 0, 1, 0),
        (15, '01/31/2022', 'Desjardins', 'Personal chequing account', 'Costco', 135.28, 'debit', 501, 'Groceries', 0, 0, 1, 0),
        (14, '01/31/2022', 'Desjardins', 'Personal chequing account', 'Payroll', 2000.00, 'credit', 701, 'Paycheque', 0, 0, 0, 0),
        (13, '01/31/2022', 'Desjardins', 'Personal chequing account', 'Fixed service charges', 7.95, 'debit', 401, 'Bank Fee', 0, 0, 1, 0),
        (12, '01/25/2022', 'Desjardins', 'Visa Desjardins', 'Uber.com', 11.60, 'debit', 102, 'Taxi', 0, 0, 1, 0),
        (11, '01/24/2022', 'Desjardins', 'Visa Desjardins', 'Apple', 11.49, 'debit', 801, 'Software', 0, 0, 1, 0),
        (10, '01/24/2022', 'Desjardins', 'Visa Desjardins', 'Netflix', 16.49, 'debit', 301, 'Movies & DVDs', 0, 0, 1, 0),
        (9, '01/21/2022', 'Desjardins', 'Visa Desjardins', 'IGA', 50.46, 'debit', 501, 'Groceries', 0, 0, 1, 0),
        (8, '01/17/2022', 'Desjardins', 'Visa Desjardins', 'Interest Charges', 76.23, 'debit', 402, 'Finance Charge', 0, 0, 1, 0),
        (7, '01/14/2022', 'Desjardins', 'Personal chequing account', 'Payroll', 2000.00, 'credit', 701, 'Paycheque', 0, 0, 0, 0),
        (6, '01/07/2022', 'Desjardins', 'Visa Desjardins', 'Payment', 1000.00, 'credit', 901, 'Credit Card Payment', 0, 1, 0, 0),
        (5, '01/07/2022', 'Desjardins', 'Personal chequing account', 'Bill payment - Desjardins Visa Or Modulo', 1000.00, 'debit', 901, 'Credit Card Payment', 0, 1, 0, 0),
        (4, '01/04/2022', 'Desjardins', 'Visa Desjardins', 'Telus Mobility', 61.46, 'debit', 201, 'Mobile Phone', 0, 0, 1, 0),
        (3, '01/04/2022', 'Desjardins', 'Visa Desjardins', 'Apple', 4.59, 'debit', 801, 'Software', 0, 0, 1, 0),
        (2, '01/03/2022', 'Desjardins', 'Visa Desjardins', 'Uber Eats', 59.96, 'debit', 502, 'Restaurants', 0, 0, 1, 0),
        (1, '01/01/2022', 'Desjardins', 'Personal chequing account', 'Rent', 800.00, 'debit', 601, 'Rent', 0, 0, 1, 0);
    """
    executeQuery(insertTransactionQuery)
}

func executeQuery(_ query: String) {
    var statement: OpaquePointer?
    if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
        if sqlite3_step(statement) == SQLITE_DONE {
            print("Query executed successfully")
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db)!)
            print("Error executing query: \(errorMessage)")
        }
    } else {
        let errorMessage = String(cString: sqlite3_errmsg(db)!)
        print("Error preparing query: \(errorMessage)")
    }
    sqlite3_finalize(statement)
}
