# Estratégia de Backup e Retenção — ConfirmaID

Este documento define como faremos backup dos dados e como aplicaremos a política de retenção de arquivos sensíveis.

---

## 1. O que precisa ser protegido

| Item                    | Criticidade | Frequência de backup | Retenção |
|-------------------------|-------------|----------------------|----------|
| Banco de dados (PostgreSQL) | Alta       | Diário               | 30 dias |
| Pasta `storage/private` (arquivos criptografados) | **MUITO ALTA** | Diário | Conforme política de retenção de documentos |
| Secrets (`.env`)        | Alta        | Sempre que mudar     | Versões anteriores |
| Configuração do VPS / Docker | Média    | Quando mudar         | Últimas 5 versões |

---

## 2. Política de Retenção de Documentos (MVP)

Definida no PRD e nas decisões de implementação:

- **Verificações APROVADAS**: manter documentos por **12 meses** após a data de aprovação.
- **Verificações REPROVADAS ou BLOQUEADAS**: manter por **6 meses** após a decisão.
- Após o prazo: deletar fisicamente os arquivos do disco + marcar como `purged` no banco de dados.

**Importante:** O backup de `storage/private` deve respeitar essa mesma janela de retenção.

---

## 3. Estratégia de Backup no VPS

### 3.1 Banco de Dados

Script recomendado (`scripts/backup-db.sh` — será criado na Fase 9):

```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/home/deploy/confirmaid/backups"
mkdir -p $BACKUP_DIR

docker exec confirmaid-db pg_dump -U confirmaid confirmaid | gzip > "$BACKUP_DIR/db_$DATE.sql.gz"

# Manter apenas últimos 30 dias
find $BACKUP_DIR -name "db_*.sql.gz" -mtime +30 -delete
```

Agendar via cron (como usuário deploy):

```bash
crontab -e
# Exemplo: todo dia às 03:00
0 3 * * * /home/deploy/confirmaid/scripts/backup-db.sh
```

### 3.2 Arquivos (storage/private)

```bash
#!/bin/bash
DATE=$(date +%Y%m%d)
BACKUP_DIR="/home/deploy/confirmaid/backups"
ARCHIVE_NAME="files_$DATE.tar.gz"

tar -czf "$BACKUP_DIR/$ARCHIVE_NAME" -C /home/deploy/confirmaid/storage private

# Opcional: criptografar o backup com gpg (recomendado)
# gpg --symmetric --cipher-algo AES256 "$BACKUP_DIR/$ARCHIVE_NAME"

# Manter backups de arquivos por 35 dias (margem sobre a retenção)
find $BACKUP_DIR -name "files_*.tar.gz" -mtime +35 -delete
```

### 3.3 Backup das Secrets

- Manter cópia do `.env` de produção em gerenciador de senhas + backup físico seguro (pendrive criptografado ou cofre).
- Nunca versionar o `.env` real no Git.

---

## 4. Restore

### Restaurar banco

```bash
gunzip < backups/db_20260614_030000.sql.gz | docker exec -i confirmaid-db psql -U confirmaid -d confirmaid
```

### Restaurar arquivos

```bash
tar -xzf backups/files_20260614.tar.gz -C /home/deploy/confirmaid/storage/
```

**Sempre teste o restore periodicamente** (pelo menos uma vez antes de ir para produção e depois a cada 3 meses).

---

## 5. Backup Externo (Recomendado para Produção)

Opções simples para MVP:

- Copiar os backups periodicamente para outro local (outro VPS pequeno, Hetzner Storage Box, ou até Google Drive / Dropbox criptografado).
- Usar `rclone` para enviar para um bucket S3 compatível (Backblaze B2, Wasabi, etc.) com criptografia client-side.

Exemplo futuro com rclone:

```bash
rclone copy /home/deploy/confirmaid/backups remote:confirmaid-backups --transfers 4
```

---

## 6. Retenção de Dados no Banco (além dos arquivos)

Além de deletar os arquivos físicos, devemos:

- Manter o registro da verificação no banco (para histórico e auditoria).
- Marcar os documentos como `purged = true`.
- Não deletar usuários ou verificações completas (apenas os arquivos binários).

Job de limpeza (será implementado na Fase 9):

- Rodar diariamente.
- Procurar verificações cuja data de expiração/retention já passou.
- Deletar fisicamente os arquivos + atualizar o registro.

---

## 7. Snapshot do VPS (Hostinger)

Além dos backups lógicos acima:

- Use os snapshots automáticos da Hostinger como backup de desastre (sistema inteiro).
- Recomendação: tirar snapshot manual antes de qualquer deploy grande ou mudança de estrutura.

---

## 8. Checklist de Backup (antes de produção)

- [ ] Script de backup do banco funcionando e agendado.
- [ ] Script de backup dos arquivos funcionando e agendado.
- [ ] Restore do banco testado com sucesso pelo menos 1 vez.
- [ ] Restore de arquivos testado com sucesso.
- [ ] Backups sendo enviados para local externo (ou processo manual definido).
- [ ] Secrets com backup offline seguro.
- [ ] Documentado quem é responsável por restaurar em caso de emergência.

---

## 9. Recuperação de Desastre (alto nível)

1. Provisionar novo VPS (ou restaurar snapshot).
2. Restaurar secrets.
3. Restaurar banco de dados.
4. Restaurar pasta `storage/private`.
5. Subir aplicação via Docker Compose.
6. Validar Cloudflare Tunnel.
7. Executar testes de smoke.

---

*Documento de apoio — Fase 9 do plano de implementação.*