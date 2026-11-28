const express = require('express');
const crypto = require('crypto');
const snap = require('./midtransClient');
const config = require('./config');

const router = express.Router();

// Buat transaksi (dipanggil dari app Flutter)
router.post('/create-transaction', async (req, res) => {
    try {
        const { orderId, amount, customerName, customerEmail } = req.body;

        if (!orderId || !amount) {
            return res.status(400).json({ message: 'orderId dan amount wajib diisi' });
        }

        const transaction = await snap.createTransaction({
            transaction_details: { order_id: orderId, gross_amount: amount },
            customer_details: { first_name: customerName, email: customerEmail },
        });

        res.json({ token: transaction.token, redirect_url: transaction.redirect_url });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// Cek status transaksi
router.get('/status/:orderId', async (req, res) => {
    try {
        const status = await snap.transaction.status(req.params.orderId);
        res.json(status);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// Webhook dari Midtrans
router.post('/notification', (req, res) => {
    const { order_id, status_code, gross_amount, signature_key, transaction_status } = req.body;

    const expected = crypto
        .createHash('sha512')
        .update(order_id + status_code + gross_amount + config.serverKey)
        .digest('hex');

    if (expected !== signature_key) {
        return res.status(403).json({ message: 'Invalid signature' });
    }

    console.log(`Order ${order_id} -> ${transaction_status}`);
    // TODO: update status pembayaran di database
    res.status(200).json({ message: 'OK' });
});

module.exports = router;