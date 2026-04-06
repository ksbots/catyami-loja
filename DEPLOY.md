# DEPLOY - Catyami Otimizacao

## 1 - Subir para o GitHub (Frontend = GitHub Pages)

### No terminal, na pasta do projeto:
```bash
cd C:\Users\joilt\Desktop\catyami-loja
git add .
git commit -m "feat: loja completa com carrinho, admin, checkout"
# Crie um repositorio no GitHub com o nome: catyami-loja
git remote add origin https://github.com/SEU_USERNAME/catyami-loja.git
git push -u origin main
```

### No GitHub:
1. Va em **Settings > Pages**
2. Source: **Deploy from a branch**
3. Branch: **main** / Folder: **/(root)**
4. Clique em **Save**
5. O site fica em: `https://SEU_USERNAME.github.io/catyami-loja/`

---

## 2 - Deploy do Backend na Railway (Grátis)

1. Acesse **railway.app** e faca login com GitHub
2. Clique em **New Project > Deploy from GitHub repo**
3. Selecione o repo `catyami-loja`
4. Nas **Settings** do servico, adicione as variaveis:
   - `MP_ACCESS_TOKEN` = Seu token do MercadoPago
   - `NODE_ENV` = production
   - `PORT` = 3000
   - `FRONTEND_URL` = https://SEU_USERNAME.github.io
5. A Railway gera uma URL: `https://SEU-APP.up.railway.app`
6. O backend fica acessivel em: `https://SEU-APP.up.railway.app/api/health`

---

## 3 - Conexar Frontend com Backend

### No arquivo `index.html`, altere a linha do topo do JS:
```javascript
const API = 'https://SEU-APP.up.railway.app';
```

### No arquivo `download.html`, adicione a mesma linha no inicio do JS:
```javascript
const API = 'https://SEU-APP.up.railway.app';
```

### No arquivo `admin.html`, adicione a mesma linha no inicio do JS:
```javascript
const API = 'https://SEU-APP.up.railway.app';
```

### Depois faca commit e push:
```bash
git add .
git commit -m "update: API URL production"
git push
```

---

## URLs Finais

| Servico | URL |
|---------|-----|
| Loja | https://SEU_USERNAME.github.io/catyami-loja/ |
| Admin | https://SEU_USERNAME.github.io/catyami-loja/admin.html |
| Download | https://SEU_USERNAME.github.io/catyami-loja/download.html |
| Backend API | https://SEU-APP.up.railway.app/api/health |
| Admin API | https://SEU-APP.up.railway.app/api/admin/orders |

---

## Obter Token do MercadoPago

1. Acesse: mercado pago.com.br/developers
2. Login > Painel de Desenvolvedor > Suas Integracoes
3. Criar Applicacao > Integração de Checkout
4. Copie o **Access Token (Producao)**
5. Cole nas variaveis de ambiente da Railway como `MP_ACCESS_TOKEN`
