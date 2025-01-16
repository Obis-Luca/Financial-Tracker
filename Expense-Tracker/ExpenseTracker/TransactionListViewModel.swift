
import Foundation
import Combine
import Collections
import SQLite3

typealias TransactionGroup = OrderedDictionary<String, [Transaction]>
typealias TransactionPrefixSum = [(String, Double)]

final class TransactionListViewModel: ObservableObject {
    // ObservableObject is part of the Combine framework that turns any object into a publisher and will notify its subscribers of its state changes, so they can refresh their views.
    @Published private var showAlert = false
    @Published private var alertMessage = ""
    
    @Published var transactions: [Transaction] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        getTransactions()
    }
    
    func getTransactions() {
        guard let url = URL(string: "http://localhost:3000/api") else {
            print("Invalid URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching transactions: \(error)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                // Decode data manually with custom mapping
                if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    var fetchedTransactions: [Transaction] = []
                    
                    
                    for json in jsonArray {
                        let id = json["id"] as? Int ?? 0
                        let date = json["date"] as? String ?? ""
                        let institution = json["institution"] as? String ?? ""
                        let account = json["account"] as? String ?? ""
                        let merchant = json["merchant"] as? String ?? ""
                        let amount = json["amount"] as? Double ?? 0.0
                        let type = json["type"] as? String ?? ""
                        let categoryId = json["categoryId"] as? Int ?? 0
                        let category = json["category"] as? String ?? ""
                        
                        // Convert 0 and 1 to Bool
                        let isPending = (json["isPending"] as? Int ?? 0) == 1
                        let isTransfer = (json["isTransfer"] as? Int ?? 0) == 1
                        let isExpense = (json["isExpense"] as? Int ?? 0) == 1
                        let isEdited = (json["isEdited"] as? Int ?? 0) == 1
                        
                        // Create Transaction object
                        let transaction = Transaction(
                            id: id,
                            date: date,
                            institution: institution,
                            account: account,
                            merchant: merchant,
                            amount: amount,
                            type: type,
                            categoryId: categoryId,
                            category: category,
                            isPending: isPending,
                            isTransfer: isTransfer,
                            isExpense: isExpense,
                            isEdited: isEdited
                        )
                        
                        fetchedTransactions.append(transaction)
                    }
                    
                    DispatchQueue.main.async {
                        self.transactions = fetchedTransactions
                        self.transactions.sort { $0.date > $1.date }
                    }
                    
                }
            } catch {
                print("Error decoding transactions: \(error)")
            }
        }
        
        task.resume()
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
            transactions[index] = updatedTransaction
            
            // Prepare the API request
            let url = URL(string: "http://localhost:3000/api")! // Replace with your actual server URL
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let requestBody: [String: Any] = [
                "id": transaction.id,
                "categoryId": category.id
            ]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            } catch {
                print("Error serializing JSON: \(error.localizedDescription)")
                return
            }
            
            // Make the API call
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error making API call: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid response from server")
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    print("Transaction category updated successfully via API.")
                } else {
                    if let data = data,
                       let errorMessage = String(data: data, encoding: .utf8) {
                        print("Error response from server: \(errorMessage)")
                    } else {
                        print("Unexpected response code: \(httpResponse.statusCode)")
                    }
                }
            }
            
            task.resume()
        }
    }
    func deleteTransaction(at offsets: IndexSet) {
        objectWillChange.send()
        
        for offset in offsets {
            let transactionToDelete = transactions[offset]
            
            // Prepare the API request
            let url = URL(string: "http://localhost:3000/api")! // Replace with your actual server URL
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let requestBody: [String: Any] = [
                "id": transactionToDelete.id
            ]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            } catch {
                print("Error serializing JSON: \(error.localizedDescription)")
                return
            }
            
            // Make the API call
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error making API call: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid response from server")
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    DispatchQueue.main.async {
                        // Remove from the array on success
                        self.transactions.remove(at: offset)
                        print("Transaction deleted successfully via API.")
                    }
                } else {
                    if let data = data,
                       let errorMessage = String(data: data, encoding: .utf8) {
                        print("Error response from server: \(errorMessage)")
                    } else {
                        print("Unexpected response code: \(httpResponse.statusCode)")
                    }
                }
            }
            
            task.resume()
        }
    }
    
    func addTransaction(transaction: TransactionDTO) {
        // Step 1: Validate the fields
        guard !transaction.merchant.isEmpty else {
            alertMessage = "Merchant cannot be empty."
            showAlert = true
            return
        }
        
        guard transaction.amount > 0 else {
            alertMessage = "Amount must be greater than zero."
            showAlert = true
            return
        }
        
        // Step 2: Create the URL
        guard let url = URL(string: "http://localhost:3000/api") else {
            print("Invalid URL")
            return
        }
        
        // Step 3: Prepare the URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Step 4: Encode the TransactionDTO object into JSON
        do {
            let jsonData = try JSONEncoder().encode(transaction)
            request.httpBody = jsonData
        } catch {
            print("Failed to encode transaction: \(error.localizedDescription)")
            return
        }
        
        // Step 5: Perform the POST request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to make POST request: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("Transaction added successfully!")
                
                // Convert TransactionDTO to Transaction
                let newTransaction = Transaction(
                    id: Int.random(in: 1000...9999), // Generate a temporary ID for the transaction
                    date: transaction.date,
                    institution: transaction.institution,
                    account: transaction.account,
                    merchant: transaction.merchant,
                    amount: transaction.amount,
                    type: transaction.type,
                    categoryId: transaction.categoryId,
                    category: transaction.category,
                    isPending: transaction.isPending,
                    isTransfer: transaction.isTransfer,
                    isExpense: transaction.isExpense,
                    isEdited: transaction.isEdited
                )
                
                DispatchQueue.main.async {
                    // Add the new transaction to the list
                    self.transactions.append(newTransaction)
                    self.transactions.sort { $0.date > $1.date }
                }
            } else {
                print("Failed to add transaction.")
            }
        }
        
        task.resume() // Start the task
    }
}
