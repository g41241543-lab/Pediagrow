const midtransClient = require('midtrans-client');
const config = require('./config');

const snap = new midtransClient.Snap({
    isProduction: config.isProduction,
    serverKey: config.serverKey,
    clientKey: config.clientKey,
});

module.exports = snap;