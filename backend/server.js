require('dotenv').config();
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const archiver = require('archiver');
const axios = require('axios');
const crypto = require('crypto');

// ==================== ASAAS CONFIG ====================
const ASAAS_TOKEN = process.env.ASAAS_TOKEN;
if (!ASAAS_TOKEN) {
    console.error('ERRO: ASAAS_TOKEN nao definido! Configure a variavel de ambiente.');
}
const ASAAS_URL = process.env.NODE_ENV === 'production'
    ? 'https://api.asaas.com/v3'
    : (process.env.ASAAS_URL || 'https://sandbox.asaas.com/api/v3');
const ASAAS_WEBHOOK_SECRET = process.env.ASAAS_WEBHOOK_SECRET;

const asaasClient = axios.create({
    baseURL: ASAAS_URL,
    headers: {
        'accept': 'application/json',
        'content-type': 'application/json',
        'access_token': ASAAS_TOKEN
    }
});

// ==================== EXPRESS ====================
const app = express();
app.use(cors());
app.use(express.json());

// ==================== STORAGE CONFIG ====================
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
    limits: { fileSize: 10 * 1024 * 1024 },
    fileFilter: (req, file, cb) => {
        const allowed = ['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'application/pdf'];
        if (allowed.includes(file.mimetype)) {
            cb(null, true);
        } else {
            cb(new Error('Apenas imagens ou PDF'));
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
        asaas_charge_id TEXT UNIQUE,
        status TEXT DEFAULT 'pending',
        customer_email TEXT DEFAULT '',
        customer_name TEXT DEFAULT '',
        customer_cpf TEXT DEFAULT '',
        receipt_path TEXT DEFAULT '',
        asaas_pix_qr TEXT DEFAULT '',
        asaas_pix_brcode TEXT DEFAULT '',
        asaas_payment_url TEXT DEFAULT '',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);
    db.run(`CREATE TABLE IF NOT EXISTS webhooks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        charge_id TEXT,
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

// ==================== PRODUCTS ====================
const PRODUCTS = {
    pc:       { name: 'PC Desktop', price: 19.90 },
    notebook: { name: 'Notebook', price: 19.90 },
    celular:  { name: 'Celular (Android)', price: 19.90 },
    combo:    { name: 'Pacote Completo', price: 49.90 }
};

// ==================== ROUTES ====================

app.get('/api/health', (req, res) => {
    res.json({ status: 'online', gateway: 'Asaas', timestamp: new Date().toISOString() });
});

app.get('/api/products', (req, res) => {
    res.json(
        Object.entries(PRODUCTS).map(([id, p]) => ({
            id, name: p.name, price: p.price
        }))
    );
});

// --- Criar pedido com Pix Asaas ---
app.post('/api/create-order', async (req, res) => {
    try {
        const { product, customer_email = '', customer_name = '', customer_cpf = '' } = req.body;

        if (!PRODUCTS[product]) {
            return res.status(400).json({ error: 'Produto invalido' });
        }

        const prod = PRODUCTS[product];

        // Salva no banco
        await dbRun(
            `INSERT INTO orders (product, product_name, price, customer_email, customer_name, customer_cpf)
             VALUES (?, ?, ?, ?, ?, ?)`,
            [product, prod.name, prod.price, customer_email, customer_name, customer_cpf]
        );

        const result = await dbGet('SELECT * FROM orders ORDER BY id DESC LIMIT 1');
        const orderId = result.id;

        // Cria cobranca Pix no Asaas
        const asaasResponse = await asaasClient.post('/payments', {
            billingType: 'PIX',
            value: prod.price,
            dueDate: new Date().toISOString().split('T')[0],
            description: `Catyami Otimizacao - ${prod.name}`,
            externalReference: String(orderId),
            customer: customer_name || 'Cliente Catyami',
            customerEmail: customer_email || `cliente${orderId}@catyami.com`
        });

        const chargeId = asaasResponse.data.id;

        // Consulta QR Code Pix
        let pixQr = '', pixBrcode = '', qrCodeBase64 = '';
        try {
            const pixInfo = await asaasClient.get(`/payments/${chargeId}/pixQrCode`);
            pixQr = pixInfo.data.payload || pixInfo.data.qrCode || '';
            pixBrcode = pixInfo.data.brCode || pixQr;

            // Se o Asaas retornar QR code em base64, usar diretamente
            if (pixInfo.data.qrCodeBase64) {
                qrCodeBase64 = `data:image/png;base64,${pixInfo.data.qrCodeBase64}`;
            }
        } catch (pixErr) {
            console.log('Erro ao obter QR Pix:', pixErr.message);
        }

        await dbRun(
            `UPDATE orders SET asaas_charge_id = ?, asaas_pix_qr = ?, asaas_pix_brcode = ?, asaas_payment_url = ? WHERE id = ?`,
            [chargeId, pixQr, pixBrcode, asaasResponse.data.invoiceUrl || '', orderId]
        );

        const paymentUrl = asaasResponse.data.invoiceUrl || '';
        console.log(`Pedido #${orderId} criado no Asaas: ${chargeId}`);

        res.json({
            success: true,
            order_id: orderId,
            asaas_charge_id: chargeId,
            pix_code: pixQr,
            pix_brcode: pixBrcode,
            qr_code_base64: qrCodeBase64,
            payment_url: paymentUrl,
            price: prod.price,
            product_name: prod.name,
            due_date: asaasResponse.data.dueDate || ''
        });

    } catch (error) {
        const errMsg = error.response?.data?.errors?.[0]?.description || error.message;
        console.log('Erro ao criar pedido:', errMsg);
        res.status(500).json({ error: 'Erro ao criar pedido: ' + errMsg });
    }
});

// --- Consulta pedido ---
app.get('/api/order/:id', async (req, res) => {
    try {
        const order = await dbGet('SELECT * FROM orders WHERE id = ?', [req.params.id]);
        if (!order) {
            return res.status(404).json({ error: 'Pedido nao encontrado' });
        }

        // Consulta status atualizado no Asaas se pendente
        if (order.status === 'pending' && order.asaas_charge_id) {
            try {
                const asaasOrder = await asaasClient.get(`/payments/${order.asaas_charge_id}`);
                const asaasStatus = asaasOrder.data.status; // SCHEDULED, CONFIRMED, PENDING, RECEIVED...

                if (asaasStatus === 'RECEIVED' && order.status !== 'approved') {
                    await dbRun(
                        `UPDATE orders SET status = 'approved', updated_at = CURRENT_TIMESTAMP WHERE id = ?`,
                        [order.id]
                    );
                    order.status = 'approved';
                } else if (asaasStatus !== 'PENDING' && asaasStatus !== 'SCHEDULED' && order.status === 'pending') {
                    // Other statuses like OVERDUE
                }
            } catch (e) {
                // Ignora erro de consulta
            }
        }

        res.json(order);
    } catch (error) {
        res.status(500).json({ error: 'Erro ao consultar pedido' });
    }
});

// --- Upload comprovante ---
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
        res.status(500).json({ error: 'Erro ao enviar comprovante' });
    }
});

// --- Webhook Asaas com verificação de assinatura ---
app.post('/api/webhook', (req, res, next) => {
    const signature = req.headers['asaas-signature'];
    if (signature && ASAAS_WEBHOOK_SECRET) {
        const hmac = crypto.createHmac('sha256', ASAAS_WEBHOOK_SECRET);
        hmac.update(JSON.stringify(req.body));
        const expected = hmac.digest('hex');
        if (signature !== expected) {
            console.log('Webhook Asaas: assinatura invalida');
            return res.status(401).json({ error: 'Assinatura invalida' });
        }
    }
    next();
}, async (req, res) => {
    try {
        const body = req.body;
        console.log('Webhook Asaas recebido:', JSON.stringify(body).substring(0, 300));

        let chargeId, newStatus;

        if (body.event === 'PAYMENT_RECEIVED' || body.event === 'PAYMENT_UPDATED' || body.event === 'PAYMENT_CREATED') {
            chargeId = body.payment?.id || body.payment?.id || body.data?.id;
            newStatus = body.payment?.status || body.data?.status;
        }
        // Format 2: Direct payment object
        else if (body.id && body.billingType === 'PIX') {
            chargeId = body.id;
            newStatus = body.status;
        }
        // Format 3: Nested charge
        else if (body.charge?.id) {
            chargeId = body.charge.id;
            newStatus = body.charge.status;
        }
        // Format 4: Generic fallback
        else {
            chargeId = body?.payment?.id || body?.data?.id || body?.id;
            newStatus = body?.payment?.status || body?.data?.status || body?.status;
        }

        // Always log webhook
        await dbRun(
            `INSERT INTO webhooks (charge_id, status, payload) VALUES (?, ?, ?)`,
            [chargeId, newStatus, JSON.stringify(body)]
        );

        // If payment confirmed — APPROVE ORDER
        if (chargeId && (newStatus === 'RECEIVED' || newStatus === 'CONFIRMED')) {
            await dbRun(
                `UPDATE orders SET status = 'approved', updated_at = CURRENT_TIMESTAMP WHERE asaas_charge_id = ? AND status != 'approved'`,
                [chargeId]
            );
            console.log(` Pagamento aprovado via webhook: ${chargeId}`);
        }

        // Also handle overdue/overdue payments
        if (chargeId && (newStatus === 'OVERDUE' || newStatus === 'REFUNDED' || newStatus === 'CHARGEBACK_REQUESTED')) {
            await dbRun(
                `UPDATE orders SET status = 'rejected', updated_at = CURRENT_TIMESTAMP WHERE asaas_charge_id = ? AND status = 'pending'`,
                [chargeId]
            );
            console.log(` Pagamento ${newStatus.toLowerCase()} via webhook: ${chargeId}`);
        }

        res.status(200).json({ success: true });
    } catch (error) {
        console.log('Erro no webhook Asaas:', error.message);
        res.status(200).json({ received: true });
    }
});

// --- Webhook GET (Asaas verification) ---
app.get('/api/webhook', (req, res) => {
    res.status(200).json({ received: true });
});

// --- Download do produto (apos pagamento) ---
const FOLDER_NAMES = {
    pc: 'PC Desktop',
    notebook: 'Notebook',
    celular: 'Celular (Android)',
    combo: 'Pacote Completo'
};

app.get('/api/download/:orderId/:product', async (req, res) => {
    try {
        const { orderId, product } = req.params;

        const order = await dbGet('SELECT * FROM orders WHERE id = ?', [orderId]);
        if (!order) {
            return res.status(404).json({ error: 'Pedido nao encontrado' });
        }

        if (order.status !== 'approved' && order.status !== 'confirmed') {
            return res.status(403).json({ error: 'Pagamento nao confirmado' });
        }

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

        const zipName = `Catyami_Otimizacao_${product}_${Date.now()}.zip`;
        res.setHeader('Content-Disposition', `attachment; filename="${zipName}"`);
        res.setHeader('Content-Type', 'application/zip');

        const archive = archiver('zip', { zlib: { level: 6 } });

        archive.on('error', function(err) {
            if (!res.headersSent) {
                res.status(500).json({ error: 'Erro ao gerar ZIP' });
            }
        });

        archive.pipe(res);

        for (const folder of foldersToZip) {
            const folderPath = path.join(productsDir, folder);
            if (fs.existsSync(folderPath)) {
                archive.directory(folderPath, folder);
            }
        }

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

Boa otimizacao!
`;
        archive.append(Buffer.from(readme), { name: 'README_Catyami.txt' });

        await archive.finalize();

        await dbRun(
            `UPDATE orders SET status = 'confirmed', updated_at = CURRENT_TIMESTAMP WHERE id = ? AND status != 'confirmed'`,
            [orderId]
        );

        console.log(`Download: ${zipName} para pedido #${orderId}`);
    } catch (error) {
        console.log('Erro no download:', error.message);
        if (!res.headersSent) {
            res.status(500).json({ error: 'Erro ao gerar download' });
        }
    }
});

// --- Admin: aprovar manualmente ---
app.post('/api/admin/order/:id/approve', async (req, res) => {
    try {
        await dbRun(`UPDATE orders SET status = 'approved', updated_at = CURRENT_TIMESTAMP WHERE id = ?`, [req.params.id]);
        res.json({ success: true });
    } catch (error) {
        res.status(500).json({ error: 'Erro ao aprovar' });
    }
});

// --- Admin: rejeitar ---
app.post('/api/admin/order/:id/reject', async (req, res) => {
    try {
        await dbRun(`UPDATE orders SET status = 'rejected', updated_at = CURRENT_TIMESTAMP WHERE id = ?`, [req.params.id]);
        res.json({ success: true });
    } catch (error) {
        res.status(500).json({ error: 'Erro ao rejeitar' });
    }
});

// --- Servir comprovante ---
app.get('/api/receipt/:filename', (req, res) => {
    const filePath = path.join(uploadsDir, req.params.filename);
    if (fs.existsSync(filePath)) {
        res.sendFile(filePath);
    } else {
        res.status(404).json({ error: 'Comprovante nao encontrado' });
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
    console.log('\n  ==============================================');
    console.log('  CATYAMI OTIMIZACAO - BACKEND RODANDO');
    console.log('  ==============================================');
    console.log(`  Frontend: http://localhost:${PORT}`);
    console.log(`  Admin: http://localhost:${PORT}/admin.html`);
    console.log(`  Gateway: Asaas (PIX)`);
    console.log(`  Porta: ${PORT}`);
    console.log('  ==============================================\n');
});
