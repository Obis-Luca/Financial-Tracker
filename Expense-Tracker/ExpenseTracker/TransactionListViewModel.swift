
import Foundation
import Combine
import Collections
import SQLite3

typealias TransactionGroup = OrderedDictionary<String, [Transaction]>
typealias TransactionPrefixSum = [(String, Double)]

final class TransactionListViewModel: ObservableObject {
    // ObservableObject is part of the Combine framework that turns any object into a publisher and will notify its subscribers of its state changes, so they can refresh their views.
    
    @Published var transactions: [Transaction] = []
    
    private var cancellables = Set<AnyCancellable>()    
    
    init() {
        createDatabase()
//        dropTables()
//        createTables()
//        insertCategoryData()
//        insertTransactionData()
        
        getTransactions()
    }
    
    func getTransactions() {
        var queryStatement: OpaquePointer? = nil
        let query = "SELECT * FROM Transactions;"
        
              
        if sqlite3_prepare_v2(db, query, -1, &queryStatement, nil) == SQLITE_OK {
            
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                
                // Extract each column from the query result
                let id = sqlite3_column_int(queryStatement, 0)
                let date = String(cString: sqlite3_column_text(queryStatement, 1))
                let institution = String(cString: sqlite3_column_text(queryStatement, 2))
                let account = String(cString: sqlite3_column_text(queryStatement, 3))
                let merchant = String(cString: sqlite3_column_text(queryStatement, 4))
                let amount = sqlite3_column_double(queryStatement, 5)
                let type = String(cString: sqlite3_column_text(queryStatement, 6))
                let categoryId = sqlite3_column_int(queryStatement, 7)
                let category = String(cString: sqlite3_column_text(queryStatement, 8))
                let isPending = sqlite3_column_int(queryStatement, 9) != 0
                let isTransfer = sqlite3_column_int(queryStatement, 10) != 0
                let isExpense = sqlite3_column_int(queryStatement, 11) != 0
                let isEdited = sqlite3_column_int(queryStatement, 12) != 0
                
                // Create a Transaction object and append it to the array
                let transaction = Transaction(
                    id: Int(id),
                    date: date,
                    institution: institution,
                    account: account,
                    merchant: merchant,
                    amount: amount,
                    type: type,
                    categoryId: Int(categoryId),
                    category: category,
                    isPending: isPending,
                    isTransfer: isTransfer,
                    isExpense: isExpense,
                    isEdited: isEdited
                )
                
                transactions.append(transaction)
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("Error preparing query: \(errorMessage)")
        }

        sqlite3_finalize(queryStatement)
    }
    
    func groupTransactionsByMonth() -> TransactionGroup {
        guard !transactions.isEmpty else { return [:] }
        
        let groupedTransactions = TransactionGroup(grouping: transactions) { $0.month }
        
        return groupedTransactions
    }
    
    func accumulateTransactions() -> TransactionPrefixSum {
        print("accumulateTransactions")
        guard !transactions.isEmpty else { return [] }
        
        let today = "02/17/2022".dateParsed() // Date()
        let dateInterval = Calendar.current.dateInterval(of: .month, for: today)!
        print("dateInterval", dateInterval)
        
        var sum: Double = .zero
        var cumulativeSum = TransactionPrefixSum()
        
        for date in stride(from: dateInterval.start, to: today, by: 60 * 60 * 24) {
            let dailyExpenses = transactions.filter { $0.dateParsed == date && $0.isExpense }
            let dailyTotal = dailyExpenses.reduce(0) { $0 - $1.signedAmount }
            
            sum += dailyTotal
            sum = sum.roundedTo2Digits()
            cumulativeSum.append((date.formatted(), sum))
            
            print(date.formatted(), "dailyTotal:", dailyTotal, "sum:", sum)
        }
        
        return cumulativeSum
    }
    
    func updateCategory(transaction: Transaction, category: Category) {
        guard transaction.categoryId != category.id else { return }
        
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            var updatedTransaction = transactions[index]
            updatedTransaction.categoryId = category.id
            updatedTransaction.isEdited = true
            transactions[index] = updatedTransaction
            
            // Update in the database
            let query = """
            UPDATE Transactions 
            SET categoryId = ?, isEdited = 1 
            WHERE id = ?;
            """
            var statement: OpaquePointer? = nil
            if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_int(statement, 1, Int32(category.id))
                sqlite3_bind_int(statement, 2, Int32(transaction.id))
                
                if sqlite3_step(statement) == SQLITE_DONE {
                    print("Transaction category updated successfully.")
                } else {
                    print("Error updating transaction category: \(String(cString: sqlite3_errmsg(db)!))")
                }
            } else {
                print("Error preparing update statement: \(String(cString: sqlite3_errmsg(db)!))")
            }
            sqlite3_finalize(statement)
        }
    }
    func deleteTransaction(at offsets: IndexSet) {
        objectWillChange.send()
        
        for offset in offsets {
            let transactionToDelete = transactions[offset]
            
            // Delete from database
            let query = """
            DELETE FROM Transactions 
            WHERE id = ?;
            """
            var statement: OpaquePointer? = nil
            if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_int(statement, 1, Int32(transactionToDelete.id))
                
                if sqlite3_step(statement) == SQLITE_DONE {
                    print("Transaction deleted successfully.")
                } else {
                    print("Error deleting transaction: \(String(cString: sqlite3_errmsg(db)!))")
                }
            } else {
                print("Error preparing delete statement: \(String(cString: sqlite3_errmsg(db)!))")
            }
            sqlite3_finalize(statement)
            
            // Remove from array
            transactions.remove(at: offset)
        }
    }
    
    func addTransaction(transaction: Transaction) {
        let query = """
        INSERT INTO Transactions 
        (id, institution, account, merchant, amount, date, categoryId, category, isPending, isTransfer, isExpense, type, isEdited) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        print(transaction.institution, transaction.account, transaction.merchant)

        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            // Bind values to the prepared statement
            sqlite3_bind_int(statement, 1, Int32(transaction.id)) // id
            sqlite3_bind_text(statement, 2, transaction.institution, -1, nil) // institution
            sqlite3_bind_text(statement, 3, transaction.account, -1, nil) // account
            sqlite3_bind_text(statement, 4, transaction.merchant, -1, nil) // merchant
            sqlite3_bind_double(statement, 5, transaction.amount) // amount
            sqlite3_bind_text(statement, 6, transaction.date, -1, nil) // date
            sqlite3_bind_int(statement, 7, Int32(transaction.categoryId)) // categoryId
            sqlite3_bind_text(statement, 8, transaction.category, -1, nil) // category
            sqlite3_bind_int(statement, 9, transaction.isPending ? 1 : 0) // isPending
            sqlite3_bind_int(statement, 10, transaction.isTransfer ? 1 : 0) // isTransfer
            sqlite3_bind_int(statement, 11, transaction.isExpense ? 1 : 0) // isExpense
            sqlite3_bind_text(statement, 12, transaction.type, -1, nil) // type
            sqlite3_bind_int(statement, 13, transaction.isEdited ? 1 : 0) // isEdited
            
            // Execute the statement
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Transaction added successfully to the database.")
            } else {
                print("Error adding transaction to the database: \(String(cString: sqlite3_errmsg(db)!))")
            }
        } else {
            print("Error preparing insert statement: \(String(cString: sqlite3_errmsg(db)!))")
        }
        sqlite3_finalize(statement)
        
        objectWillChange.send()
        transactions.append(transaction)
        transactions.sort { $0.dateParsed > $1.dateParsed }
    }
}
