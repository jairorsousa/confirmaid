# Fase 0 — Execution Guide (Implementação Interativa)

**Data:** 14 de junho de 2026  
**Objetivo:** Executar a Fase 0 completa: preparar o VPS Hostinger com Docker + Cloudflare Tunnel + estrutura básica.

Este guia é **interativo**. Siga os passos na ordem. Eu (Grok) vou te ajudar em tempo real.  
Quando precisar rodar um comando no VPS, me diga o output ou cole aqui.

---

## Pré-requisitos (faça isso primeiro no seu Mac)

1. Abra o terminal local (você já está no projeto `/Users/jairo/PhpstormProjects/confirmaid`).

2. Gere suas secrets reais (não use as de exemplo):

```bash
bash scripts/generate-secrets.sh
```

   Guarde os valores gerados em um gerenciador de senhas (Bitwarden/1Password).  
   **Nunca** compartilhe as secrets reais aqui se não for seguro.

3. Atualize seu `.env` local (crie a partir do exemplo se ainda não tiver):

```bash
cp .env.example .env
# Depois edite .env e coloque valores reais (apenas para desenvolvimento local)
```

---

## Passo 1: Conectar no VPS pela primeira vez

Você precisa do IP do seu VPS na Hostinger e a senha/root access inicial.

Me confirme:
- Qual é o IP ou hostname do VPS?
- O usuário inicial é `root` ou outro?

Quando você estiver logado pela primeira vez, rode o script preparado:

**No seu Mac (local):**

```bash
# Torne o script executável
chmod +x scripts/vps-phase0-setup.sh

# Copie o script para o VPS (substitua pelo IP real)
scp scripts/vps-phase0-setup.sh root@SEU_VPS_IP:/root/
```

Depois SSH:

```bash
ssh root@SEU_VPS_IP
```

---

## Passo 2: Executar o script base no VPS

Dentro do VPS como root:

```bash
bash /root/vps-phase0-setup.sh
```

O script vai:
- Atualizar o sistema
- Instalar Docker + Docker Compose
- Instalar cloudflared
- Configurar UFW (só porta 22)
- Instalar Fail2Ban
- Criar estrutura básica de pastas

**Depois que o script terminar**, cole aqui o output final para eu revisar.

---

## Passo 3: Criar usuário 'deploy' (não-root)

Execute estes comandos no VPS:

```bash
# Criar usuário
adduser deploy

# Adicionar aos grupos necessários
usermod -aG sudo deploy
usermod -aG docker deploy

# Verificar
id deploy
```

Recomendado: Configure login por chave SSH para o usuário `deploy` (mais seguro que senha).

---

## Passo 4: Configurar Cloudflare Tunnel (o mais importante)

### 4.1 No Cloudflare Dashboard (faça isso no navegador)

1. Acesse https://dash.cloudflare.com
2. Vá em **Zero Trust** → **Networks** → **Tunnels**
3. Clique em **Create a tunnel**
4. Nome: `confirmaid-prod` (ou similar)
5. Escolha Linux
6. Copie o comando completo que o Cloudflare mostra (contém o token)

### 4.2 No VPS, instale e configure o serviço

O script da Fase 0 já instalou o `cloudflared`.

Crie o serviço:

```bash
sudo nano /etc/systemd/system/cloudflared.service
```

Cole algo como:

```ini
[Unit]
Description=Cloudflare Tunnel for ConfirmaID
After=network.target

[Service]
Type=simple
User=deploy
ExecStart=/usr/bin/cloudflared tunnel run --token SEU_TOKEN_COMPLETO_AQUI
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

Salve e ative:

```bash
sudo systemctl daemon-reload
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
sudo systemctl status cloudflared
```

### 4.3 Configure o Public Hostname no Cloudflare

No dashboard do túnel:
- Public Hostname: `confirmaid.com.br` (ou `www`)
- Service type: `HTTP`
- URL: `http://localhost:3000`
- HTTP Host Header: `confirmaid.com.br`

Teste no navegador: https://confirmaid.com.br  
Deve dar erro de conexão (porque a app ainda não existe) — mas o tunnel deve estar resolvendo.

**Me confirme quando o domínio estiver respondendo via Tunnel.**

---

## Passo 5: Estrutura de diretórios e permissões

Como usuário `deploy`:

```bash
su - deploy

cd /home/deploy/confirmaid

# Criar estrutura
mkdir -p storage/private backups app

# Permissões críticas para arquivos sensíveis
chmod 700 storage/private
chmod 600 .env 2>/dev/null || true
```

---

## Passo 6: Clonar o repositório no VPS

Opção A (recomendada):

```bash
cd /home/deploy/confirmaid
git clone https://github.com/SEU_USUARIO/confirmaid.git app
cd app
```

Opção B: Copiar os arquivos atuais do seu Mac via scp/rsync (útil enquanto o projeto é pequeno).

---

## Passo 7: Criar o arquivo .env no VPS

```bash
cd /home/deploy/confirmaid/app

# Copie o template
cp .env.example .env

# Edite com suas secrets reais (use nano ou vim)
nano .env
```

Preencha pelo menos:
- `POSTGRES_PASSWORD`
- `NEXTAUTH_SECRET`
- `STORAGE_ENCRYPTION_KEY`
- `NEXT_PUBLIC_APP_URL=https://confirmaid.com.br`
- `DATABASE_URL` (ajuste conforme o docker-compose)

**Lembrete:** Use valores **diferentes** dos de desenvolvimento local.

---

## Passo 8: Validar Docker e estrutura

```bash
docker --version
docker compose version

# Testar docker sem sudo (deve funcionar porque adicionamos ao grupo)
docker ps
```

Testar subir só o banco (para validar):

```bash
docker compose up -d db
docker compose ps
docker compose logs db
```

Depois pare:

```bash
docker compose down
```

---

## Passo 9: Backup inicial e documentação

- Tire um snapshot do VPS no painel da Hostinger (importante).
- Salve as secrets em local seguro + backup físico.
- Atualize este documento com qualquer comando extra que você rodou.

---

## Checklist Final da Fase 0

- [ ] Sistema atualizado + pacotes básicos instalados
- [ ] Docker + Docker Compose instalados
- [ ] Usuário `deploy` criado com grupos sudo + docker
- [ ] UFW ativo (só porta 22)
- [ ] Fail2Ban rodando
- [ ] Cloudflared instalado e rodando como serviço
- [ ] Domínio `https://confirmaid.com.br` resolve via Tunnel (mesmo que retorne erro de app)
- [ ] Estrutura de pastas `storage/private` com permissão 700
- [ ] `.env` criado no VPS com secrets fortes
- [ ] Repositório clonado em `/home/deploy/confirmaid/app`
- [ ] Snapshot do VPS tirado na Hostinger
- [ ] Secrets salvas com segurança

---

## Depois da Fase 0

Quando tudo acima estiver verde, me avise:

> "Fase 0 concluída"

Aí partimos para **Fase 1** (inicialização do projeto Next.js 15 + Prisma + estrutura).

---

**Estamos prontos para começar?**

Me responda com:
1. O IP do seu VPS (ou confirme que você já está logado)
2. Se você quer que eu gere um comando `scp` personalizado agora
3. Se quer que eu ajuste algum script antes de você rodar

Vamos executar a Fase 0 juntos passo a passo.