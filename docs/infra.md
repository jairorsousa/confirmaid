# Infraestrutura — ConfirmaID (VPS Hostinger + Docker + Cloudflare Tunnel)

**Objetivo desta fase:** Deixar o servidor pronto para rodar a aplicação de forma segura, com exposição apenas via Cloudflare Tunnel.

**Ambiente alvo:**
- VPS Hostinger (Ubuntu 22.04 ou 24.04 LTS recomendado)
- Docker + Docker Compose
- Cloudflare Tunnel (cloudflared)
- Domínio: `confirmaid.com.br` (já configurado na Cloudflare)

---

## 1. Preparação Inicial do VPS

### 1.1 Acesso e usuário seguro

```bash
# Conecte via SSH como root (ou usuário inicial fornecido pela Hostinger)
ssh root@SEU_IP

# Crie um usuário dedicado para deploy
adduser deploy
usermod -aG sudo deploy

# Configure chave SSH para o novo usuário (recomendado)
# Copie sua chave pública para ~/.ssh/authorized_keys do usuário deploy

# Desabilite login por senha (após testar com chave)
sudo nano /etc/ssh/sshd_config
# Altere:
# PasswordAuthentication no
# PermitRootLogin no

sudo systemctl restart ssh
```

### 1.2 Atualização e ferramentas básicas

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
    curl \
    git \
    htop \
    ufw \
    fail2ban \
    unzip \
    ca-certificates \
    gnupg \
    lsb-release
```

### 1.3 Firewall (UFW)

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Apenas SSH (ajuste a porta se você usa porta customizada)
sudo ufw allow 22/tcp

# Cloudflare Tunnel cuida de HTTP/HTTPS — NÃO abra 80/443 publicamente
sudo ufw --force enable

sudo ufw status
```

### 1.4 Fail2Ban (proteção contra brute force)

```bash
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

---

## 2. Instalação do Docker

```bash
# Instalar Docker oficial
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Adicionar usuário deploy ao grupo docker
sudo usermod -aG docker deploy

# Instalar Docker Compose (plugin)
sudo apt install -y docker-compose-plugin

# Testar
docker --version
docker compose version
```

**Importante:** Faça logout e login novamente no usuário `deploy` para aplicar o grupo docker.

---

## 3. Cloudflare Tunnel

### 3.1 Criar o túnel no dashboard

1. Acesse o [Cloudflare Zero Trust Dashboard](https://dash.cloudflare.com)
2. Vá em **Access > Tunnels**
3. Clique em **Create a tunnel**
4. Escolha **Cloudflare Tunnel**
5. Dê um nome (ex: `confirmaid-vps`)
6. Selecione o sistema operacional **Linux**
7. Copie o comando de instalação que o Cloudflare mostra (contém o token)

### 3.2 Instalar e configurar no VPS

Como usuário `deploy`:

```bash
# Instalar cloudflared
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o cloudflared.deb
sudo dpkg -i cloudflared.deb

# Validar instalação
cloudflared --version
```

Execute o comando que o Cloudflare forneceu (exemplo):

```bash
cloudflared tunnel run --token SEU_TOKEN_AQUI
```

Teste se funciona. Depois configure como serviço.

### 3.3 Configurar como serviço systemd (recomendado)

Crie o arquivo de serviço:

```bash
sudo nano /etc/systemd/system/cloudflared.service
```

Conteúdo:

```ini
[Unit]
Description=Cloudflare Tunnel
After=network.target

[Service]
Type=simple
User=deploy
ExecStart=/usr/bin/cloudflared tunnel run --token SEU_TOKEN_AQUI
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

Ative o serviço:

```bash
sudo systemctl daemon-reload
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
sudo systemctl status cloudflared
```

### 3.4 Configurar o túnel no Cloudflare

No dashboard do túnel criado:

- **Public Hostname**:
  - Subdomain: `@` (ou `www` se preferir)
  - Domain: `confirmaid.com.br`
  - Service: `http://localhost:3000` (ou a porta interna que o container vai expor)
  - Path: (deixe vazio)
  - Additional application settings → **HTTP Host Header**: `confirmaid.com.br`

- Adicione também `www.confirmaid.com.br` apontando para o mesmo serviço (ou crie redirect no Cloudflare).

Teste acessando `https://confirmaid.com.br` — deve chegar no seu servidor mesmo sem portas 80/443 abertas no UFW.

---

## 4. Estrutura de Diretórios no VPS

Recomendação:

```bash
/home/deploy/confirmaid/
├── docker-compose.yml
├── docker-compose.prod.yml
├── .env
├── .env.example
├── storage/
│   └── private/          # NUNCA commitar
├── backups/
└── app/                  # (onde o código será clonado)
```

Crie as pastas:

```bash
mkdir -p /home/deploy/confirmaid/{storage/private,backups}
chmod 700 /home/deploy/confirmaid/storage/private
```

---

## 5. Repositório

```bash
cd /home/deploy/confirmaid
git clone SEU_REPO_GIT app
cd app
```

Ou trabalhe diretamente no diretório do repositório.

---

## 6. Docker Compose no Servidor

Veja o arquivo `docker-compose.yml` (template) na raiz do projeto.

No VPS você vai usar versões específicas para produção (veja `docker-compose.prod.yml` quando for criado na Fase 9/10).

---

## 7. Backup da Infraestrutura

- Faça snapshots do VPS na Hostinger periodicamente (especialmente antes de grandes mudanças).
- Mantenha um backup offline das secrets (veja `docs/secrets-management.md`).

---

## 8. Checklist de Fase 0

- [ ] Usuário `deploy` criado + SSH key-only
- [ ] UFW ativo (só porta 22)
- [ ] Fail2Ban rodando
- [ ] Docker instalado e usuário no grupo
- [ ] Cloudflare Tunnel instalado como serviço e funcionando
- [ ] Domínio `https://confirmaid.com.br` respondendo via Tunnel
- [ ] Pasta `storage/private` criada com permissão 700
- [ ] Repositório clonado
- [ ] `.env.example` copiado e preenchido (ainda com placeholders)

---

## Notas Importantes

- **Nunca** exponha a porta 3000 diretamente no firewall.
- O Cloudflare Tunnel é a única forma de entrada para a aplicação.
- Mantenha o `cloudflared` sempre atualizado.
- Use snapshots da Hostinger como backup de último recurso do sistema inteiro.

---

*Documento de referência para Fase 0 do plano de implementação.*