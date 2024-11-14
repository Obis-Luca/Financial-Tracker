import SwiftUI

struct AddTransactionView: View {
    @EnvironmentObject var transactionListVM: TransactionListViewModel
    @Binding var showingAddTransaction: Bool
    @State private var merchant: String = ""
    @State private var amount: String = ""
    @State private var category: Category = .shopping
    @State private var isExpense: Bool = true
    @State private var transactionDate = Date() // New date picker state variable

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Transaction Details")) {
                    TextField("Merchant", text: $merchant)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    DatePicker("Date", selection: $transactionDate, displayedComponents: .date) // Date Picker
                    Picker("Category", selection: $category) {
                        ForEach(Category.all, id: \.id) { category in
                            Text(category.name).tag(category)
                        }
                    }
                    Toggle(isOn: $isExpense) {
                        Text("Expense")
                    }
                }
                
                Section {
                    Button(action: {
                        addTransaction()
                    }) {
                        Text("Add Transaction")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .disabled(merchant.isEmpty || amount.isEmpty)
                }
            }
            .navigationTitle("Add Transaction")
            .navigationBarItems(trailing: Button("Cancel") {
                showingAddTransaction = false
            })
        }
    }
    
    private func addTransaction() {
        guard let amount = Double(amount) else { return }

        let newTransaction = Transaction(
            id: Int.random(in: 1000...9999),
            date: transactionDate.formatted(), // Using selected date
            institution: "Bank",
            account: "Checking",
            merchant: merchant,
            amount: amount,
            type: isExpense ? TransactionType.debit.rawValue : TransactionType.credit.rawValue,
            categoryId: category.id,
            category: category.name,
            isPending: false,
            isTransfer: false,
            isExpense: isExpense,
            isEdited: false
        )
        
        transactionListVM.addTransaction(transaction: newTransaction)
        showingAddTransaction = false
    }
}
