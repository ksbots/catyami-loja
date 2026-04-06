require('dotenv').config();
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const archiver = require('archiver');
const { MercadoPagoConfig, Payment } = require('mercadopago');

// ==================== INIT MERCADO PAGO ====================
const mpClient = new MercadoPagoConfig({
    accessToken: process.env.MP_ACCESS_TOKEN
});
const paymentClient = new Payment(mpClient);

// ==================== EXPRESS ====================
const app = express();
app.use(cors());
app.use(express.json());

// ==================== STORAGE CONFIG ====================
// Use /data for Railway persistent storage, or local
const dataDir = process.env.DATA_DIR || __dirname;
const uploadsDir = path.join(dataDir, 'uploads');
const dbPath = path.join(dataDir, 'database.sqlite');

if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
}

const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, uploadsDir),
    filename: (req, file, cb) => {
        const unique = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, unique + path.extname(file.originalname));
    }
});
const upload = multer({
    storage,
    limits: { fileSize: 10 * 1024 * 1024 }, // 10MB max
    fileFilter: (req, file, cb) => {
        const allowed = ['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'application/pdf'];
        if (allowed.includes(file.mimetype)) {
            cb(null, true);
        } else {
            cb(new Error('Apenas arquivos de imagem ou PDF sao aceitos'));
        }
    }
});

// ==================== DATABASE ====================
const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database(dbPath, (err) => {
    if (err) {
        console.log('Erro ao abrir banco:', err.message);
        return;
    }
    console.log('Banco de dados conectado.');
    db.run(`CREATE TABLE IF NOT EXISTS orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product TEXT NOT NULL,
        product_name TEXT NOT NULL,
        price REAL NOT NULL,
        mp_payment_id TEXT UNIQUE,
        status TEXT DEFAULT 'pending',
        customer_email TEXT DEFAULT '',
        customer_name TEXT DEFAULT '',
        receipt_path TEXT DEFAULT '',
        mp_qr_code TEXT DEFAULT '',
        qr_code_base64 TEXT DEFAULT '',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);
    db.run(`CREATE TABLE IF NOT EXISTS webhooks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        payment_id TEXT NOT NULL,
        status TEXT,
        payload TEXT,
        received_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);
});

function dbRun(sql, params = []) {
    return new Promise((resolve, reject) => {
        db.run(sql, params, function (err) {
            if (err) return reject(err);
            resolve(this);
        });
    });
}

function dbGet(sql, params = []) {
    return new Promise((resolve, reject) => {
        db.get(sql, params, (err, row) => {
            if (err) return reject(err);
            resolve(row);
        });
    });
}

function dbAll(sql, params = []) {
    return new Promise((resolve, reject) => {
        db.all(sql, params, (err, rows) => {
            if (err) return reject(err);
            resolve(rows);
        });
    });
}

// ==================== PRODUCTS CONFIG ====================
const PRODUCTS = {
    pc:       { name: 'PC Desktop', price: 19.90 },
    notebook: { name: 'Notebook', price: 19.90 },
    celular:  { name: 'Celular (Android)', price: 19.90 },
    combo:    { name: 'Pacote Completo', price: 49.90 }
};

// ==================== ROUTES ====================

// --- Health check ---
app.get('/api/health', (req, res) => {
    res.json({ status: 'online', timestamp: new Date().toISOString() });
});

// --- Lista todos os produtos ---
app.get('/api/products', (req, res) => {
    res.json(
        Object.entries(PRODUCTS).map(([id, p]) => ({
            id, name: p.name, price: p.price
        }))
    );
});

// --- Cria pedido com Pix ---
app.post('/api/create-order', async (req, res) => {
    try {
        const { product, customer_email = '', customer_name = '' } = req.body;

        if (!PRODUCTS[product]) {
            return res.status(400).json({ error: 'Produto invalido' });
        }

        const prod = PRODUCTS[product];

        // Salva pedido no banco
        await dbRun(
            `INSERT INTO orders (product, product_name, price, customer_email, customer_name)
             VALUES (?, ?, ?, ?, ?)`,
            [product, prod.name, prod.price, customer_email, customer_name]
        );

        const result = await dbGet('SELECT * FROM orders ORDER BY id DESC LIMIT 1');
        const orderId = result.id;

        // Cria pagamento no MercadoPago
        const mpPayment = await paymentClient.create({
            body: {
                transaction_amount: prod.price,
                description: `Catyami - ${prod.name}`,
                payment_method_id: 'pix',
                payer: {
                    email: customer_email || 'cliente@catyami.com',
                    first_name: customer_name || 'Cliente'
                },
                notification_url: `${process.env.FRONTEND_URL || 'http://localhost:5000'}/api/webhook`,
                external_reference: String(orderId)
            }
        });

        // Atualiza pedido com infos do MP
        const qrCode = mpPayment.point_of_interaction?.transaction_data?.qr_code || '';
        const qrCodeBase64 = mpPayment.point_of_interaction?.transaction_data?.qr_code_base64 || '';

        await dbRun(
            `UPDATE orders SET mp_payment_id = ?, mp_qr_code = ?, qr_code_base64 = ? WHERE id = ?`,
            [mpPayment.id, qrCode, qrCodeBase64, orderId]
        );

        res.json({
            success: true,
            order_id: orderId,
            mp_payment_id: mpPayment.id,
            qr_code: qrCode,
            qr_code_base64: qrCodeBase64,
            ticket_url: mpPayment.point_of_interaction?.transaction_data?.ticket_url || '',
            price: prod.price,
            product_name: prod.name
        });

    } catch (error) {
        console.log('Erro ao criar pedido:', error.message);
        res.status(500).json({ error: 'Erro ao criar pedido. Tente novamente.' });
    }
});

// --- Consulta status de um pedido ---
app.get('/api/order/:id', async (req, res) => {
    try {
        const order = await dbGet('SELECT * FROM orders WHERE id = ?', [req.params.id]);
        if (!order) {
            return res.status(404).json({ error: 'Pedido nao encontrado' });
        }

        // Se ainda pendente, consulta status atualizado no MP
        if (order.status === 'pending' && order.mp_payment_id) {
            try {
                const mpStatus = await paymentClient.get({ url: '/' + order.mp_payment_id });
                if (mpStatus.status === 'approved' && order.status !== 'approved') {
                    await dbRun(
                        `UPDATE orders SET status = 'approved', updated_at = CURRENT_TIMESTAMP WHERE id = ?`,
                        [order.id]
                    );
                    order.status = 'approved';
                }
            } catch (e) {
                // ignora se nao conseguir consultar MP
            }
        }

        res.json(order);
    } catch (error) {
        res.status(500).json({ error: 'Erro ao consultar pedido' });
    }
});

// --- Upload de comprovante ---
app.post('/api/order/:id/receipt', upload.single('receipt'), async (req, res) => {
    try {
        const order = await dbGet('SELECT * FROM orders WHERE id = ?', [req.params.id]);
        if (!order) {
            return res.status(404).json({ error: 'Pedido nao encontrado' });
        }

        const receiptPath = req.file ? req.file.filename : '';

        await dbRun(
            `UPDATE orders SET receipt_path = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?`,
            [receiptPath, req.params.id]
        );

        res.json({ success: true, receipt: receiptPath, message: 'Comprovante enviado!' });
    } catch (error) {
        console.log('Erro ao salvar comprovante:', error.message);
        res.status(500).json({ error: 'Erro ao enviar comprovante' });
    }
});

// --- Webhook do MercadoPago ---
app.post('/api/webhook', async (req, res) => {
    try {
        const { data, topic } = req.body;

        // MercadoPago envia como query ou body dependendo do metodo
        const paymentId = data?.id || req.query['data.id'];
        if (!paymentId) {
            return res.status(200).json({ received: true });
        }

        // Salva no log de webhooks
        await dbRun(
            `INSERT INTO webhooks (payment_id, status, payload) VALUES (?, ?, ?)`,
            [paymentId, 'unknown', JSON.stringify(req.body)]
        );

        // Consulta pagamento no MP
        const mpPayment = await paymentClient.get({ url: '/' + paymentId });
        const mpStatus = mpPayment.status; // 'approved', 'pending', 'rejected'
        const externalRef = mpPayment.external_reference;

        if (mpStatus === 'approved' && externalRef) {
            await dbRun(
                `UPDATE orders SET status = 'approved', updated_at = CURRENT_TIMESTAMP WHERE mp_payment_id = ? AND status != 'approved'`,
                [paymentId]
            );
        }

        res.status(200).json({ received: true });
    } catch (error) {
        console.log('Erro no webhook:', error.message);
        res.status(200).json({ received: true });
    }
});

// ==================== PRODUCT FOLDER MAPPING ====================
const FOLDER_NAMES = {
    pc: 'PC Desktop',
    notebook: 'Notebook',
    celular: 'Celular (Android)',
    combo: 'Pacote Completo'
};

// --- Download de produto (apos pagamento aprovado) ---
app.get('/api/download/:orderId/:product', async (req, res) => {
    try {
        const { orderId, product } = req.params;

        // Verifica se o pedido existe e esta aprovado
        const order = await dbGet('SELECT * FROM orders WHERE id = ?', [orderId]);
        if (!order) {
            return res.status(404).json({ error: 'Pedido nao encontrado' });
        }

        // Aceita download se o pedido foi aprovado OU se e um dos produtos do combo
        if (order.status !== 'approved' && order.status !== 'confirmed') {
            return res.status(403).json({ error: 'Pagamento ainda nao confirmado' });
        }

        // Determina quais pastas incluir no ZIP
        let foldersToZip = [];
        const productsDir = path.join(__dirname, 'products');

        if (product === 'combo') {
            foldersToZip = ['PC Desktop', 'Notebook', 'Celular (Android)'];
        } else if (FOLDER_NAMES[product]) {
            foldersToZip = [FOLDER_NAMES[product]];
        }

        if (foldersToZip.length === 0) {
            return res.status(400).json({ error: 'Produto invalido' });
        }

        // Cria o ZIP e faz stream
        const zipName = `Catyami_Otimizacao_${product}_${Date.now()}.zip`;
        res.setHeader('Content-Disposition', `attachment; filename="${zipName}"`);
        res.setHeader('Content-Type', 'application/zip');

        const archive = archiver('zip', { zlib: { level: 6 } });

        archive.on('error', (err) => {
            console.log('Erro ao criar ZIP:', err);
            if (!res.headersSent) {
                res.status(500).json({ error: 'Erro ao gerar ZIP' });
            }
        });

        archive.pipe(res);

        // Adiciona cada pasta de produto ao ZIP
        for (const folder of foldersToZip) {
            const folderPath = path.join(productsDir, folder);
            if (fs.existsSync(folderPath)) {
                archive.directory(folderPath, folder);
            }
        }

        // Adiciona arquivo README
        const readme = `=== CATYAMI OTIMIZACAO ===
Produto: ${product === 'combo' ? 'Pacote Completo (PC + Notebook + Celular)' : FOLDER_NAMES[product] || product}
Pedido: #${orderId}
Data: ${new Date().toLocaleString('pt-BR')}

INSTRUCOES:
1. Extraia todos os arquivos
2. Execute os scripts .bat como ADMINISTRADOR
3. Siga a ordem numerica dos arquivos (01, 02, 03...)
4. Para .reg, de duplo clique e confirme
5. Reinicie o dispositivo ao final

PARA MENOR PING/JOGOS:
- PC: Execute 08_otimizar_ping.bat ou 09_Catyami_NetBooster.bat
- Notebook: Execute 06_otimizar_wifi.bat e 09_otimizar_ping.bat
- Android: Abra 01_guia_otimizacao.html para instrucoes de DNS

Suporte: Catyami Otimizacao

Boa otimizacao!
`;
        archive.append(Buffer.from(readme), { name: 'README_Catyami.txt' });

        await archive.finalize();

        // Loga o download
        await dbRun(
            `UPDATE orders SET status = 'confirmed', updated_at = CURRENT_TIMESTAMP WHERE id = ? AND status != 'confirmed'`,
            [orderId]
        );

        console.log(`Download enviado: ${zipName} para pedido #${orderId}`);
    } catch (error) {
        console.log('Erro no download:', error.message);
        if (!res.headersSent) {
            res.status(500).json({ error: 'Erro ao gerar download' });
        }
    }
});

// --- Lista todos os pedidos (admin) ---
app.get('/api/admin/orders', async (req, res) => {
    try {
        const orders = await dbAll(
            `SELECT id, product_name, price, status, customer_name, customer_email, receipt_path, created_at
             FROM orders ORDER BY id DESC`
        );
        res.json(orders);
    } catch (error) {
        res.status(500).json({ error: 'Erro ao listar pedidos' });
    }
});

// --- Aprovar pedido manualmente ---
app.post('/api/admin/order/:id/approve', async (req, res) => {
    try {
        await dbRun(`UPDATE orders SET status = 'approved', updated_at = CURRENT_TIMESTAMP WHERE id = ?`, [req.params.id]);
        res.json({ success: true, message: 'Pedido aprovado' });
    } catch (error) {
        res.status(500).json({ error: 'Erro ao aprovar pedido' });
    }
});

// --- Rejeitar pedido ---
app.post('/api/admin/order/:id/reject', async (req, res) => {
    try {
        await dbRun(`UPDATE orders SET status = 'rejected', updated_at = CURRENT_TIMESTAMP WHERE id = ?`, [req.params.id]);
        res.json({ success: true, message: 'Pedido rejeitado' });
    } catch (error) {
        res.status(500).json({ error: 'Erro ao rejeitar pedido' });
    }
});

// --- Servir comprovante de upload ---
app.get('/api/receipt/:filename', (req, res) => {
    const filePath = path.join(uploadsDir, req.params.filename);
    if (fs.existsSync(filePath)) {
        res.sendFile(filePath);
    } else {
        res.status(404).json({ error: 'Comprovante nao encontrado' });
    }
});

// ==================== SERVE FRONTEND ====================
const frontendPath = path.join(__dirname, '..');
app.use(express.static(frontendPath));

// Fallback para o index.html
app.get('*', (req, res) => {
    res.sendFile(path.join(frontendPath, 'index.html'));
});

// ==================== START ====================
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`\n  Catyami Backend rodando em http://localhost:${PORT}`);
    console.log(`  Frontend: http://localhost:${PORT}`);
    console.log(`  Admin Painel: http://localhost:${PORT}/api/admin/orders\n`);
});
