import SwiftUI

struct TransactionList: View {
    @EnvironmentObject var transactionListVM: TransactionListViewModel
    @State private var showingAddTransaction = false
    @State private var showDeleteConfirmation = false
    @State private var deleteOffsets: IndexSet? = nil
    
    var body: some View {
        VStack {
            Button(action: {
                showingAddTransaction.toggle()
            }) {
                Text("Add Transaction")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding()
            List {
                // MARK: Transaction Groups
                ForEach(Array(transactionListVM.groupTransactionsByMonth()), id: \.key) { month, transactions in
                    Section {
                        // MARK: Transaction List
                        ForEach(transactions) { transaction in
                            ZStack {
                                TransactionRow(transaction: transaction)
                                NavigationLink("") {
                                    TransactionView(transaction: transaction)
                                }
                                .opacity(0)
                            }
                        }
                        .onDelete(perform: confirmDeleteTransaction)
                    } header: {
                        // MARK: Transaction Month
                        Text(month)
                    }
                    .listSectionSeparator(.hidden)
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Transactions")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView(showingAddTransaction: $showingAddTransaction)
        }
        .alert("Confirm Delete", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                performDeleteTransaction()
            }
        } message: {
            Text("Are you sure you want to delete this transaction?")
        }
    }
    
    private func confirmDeleteTransaction(at offsets: IndexSet) {
        deleteOffsets = offsets
        showDeleteConfirmation = true
    }
    
    private func performDeleteTransaction() {
        if let offsets = deleteOffsets {
            transactionListVM.deleteTransaction(at: offsets)
            deleteOffsets = nil
        }
    }
}

struct TransactionList_Previews: PreviewProvider {
    static let transactionListVM: TransactionListViewModel = {
        let transactionListVM = TransactionListViewModel()
        transactionListVM.transactions = transactionListPreviewData
        return transactionListVM
    }()

    static var previews: some View {
        Group {
            NavigationView {
                TransactionList()
            }
            NavigationView {
                TransactionList()
                    .preferredColorScheme(.dark)
            }
        }
        .environmentObject(transactionListVM)
    }
}
