const express = require('express');
const mysql = require('mysql2');
const app = express();
const PORT = 3000; 
app.use(express.json());

const connection = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'ExpenseTracker'
})

connection.connect((err) => {
    if (err) {
        console.error('Error connecting to database: ', err);
        return;
    }
    console.log('Connected to database');
})


app.get('/api', (req, res) => {
    connection.query("Select * from Transactions", (err, result) => {
        if (err) {
            console.log('Error fetching data: ', err);
            res.status(500).json({error: 'Error fetching data'});
        }
        res.json(result);
    })
})

app.post('/api', (req, res) => {
    const {
        date,
        account,
        categoryId,
        category,
        isEdited,
        merchant,
        amount,
        type,
        isExpense,
        institution,
        isPending,
        isTransfer
    } = req.body;

    const formattedDate = new Date(date).toISOString().split('T')[0];

    const sql = `
        INSERT INTO Transactions (id, date, account, categoryId, category, isEdited, merchant, amount, type, isExpense, institution, isPending, isTransfer) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    
    const id = Math.floor(Math.random() * 1000) + 100;

    const values = [
        id,
        formattedDate,
        account,
        categoryId,
        category,
        isEdited,
        merchant,
        amount,
        type,
        isExpense,
        institution,
        isPending,
        isTransfer
    ];

    connection.query(sql, values, (error, results) => {
        if (error) {
            console.error("Error inserting data: ", error);
            res.status(500).send("Failed to insert data");
            return;
        }

        console.log("Data inserted successfully:", results);
        res.status(200).send("Data inserted successfully!");
    });
});

app.put('/api', (req, res) => {

    const { id, categoryId } = req.body;
    const sql = `
        UPDATE Transactions 
        SET categoryId = ?, isEdited = 1 
        WHERE id = ?;
    `;

    connection.query(sql, [categoryId, id], (error, results) => {
        if (error) {
            console.error("Error updating data: ", error);
            res.status(500).send("Failed to update data");
            return;
        }
        console.log("Data updated successfully:", results);
        res.status(200).send("Data updated successfully!");
    })
})

app.delete('/api', (req,res) => {
    const { id } = req.body;
    const sql = 'DELETE FROM Transactions WHERE id = ?';

    connection.query(sql, [id], (error, results) => {
        if (error) {
            console.error("Error deleting data: ", error);
            res.status(500).send("Failed to delete data");
            return;
        }
        console.log("Data deleted successfully:", results);
        res.status(200).send("Data deleted successfully!");
    })
})


app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});

