const express = require('express');
const cors = require('cors');
const config = require('./config');
const routes = require('./routes');

const app = express();
app.use(cors());
app.use(express.json());

app.get('/', (req, res) => res.json({ message: 'Midtrans backend jalan' }));
app.use('/midtrans', routes);

app.listen(config.port, () => {
    console.log(`Server jalan di http://localhost:${config.port}`);
});