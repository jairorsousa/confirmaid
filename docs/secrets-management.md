# Gerenciamento de Secrets — ConfirmaID

Este documento define como devemos tratar senhas, chaves e variáveis sensíveis durante todo o ciclo de vida do projeto.

---

## 1. Secrets Críticas do MVP

| Secret                        | Onde é usada                          | Como gerar                          | Criticidade |
|-------------------------------|---------------------------------------|-------------------------------------|-------------|
| `STORAGE_ENCRYPTION_KEY`      | Criptografia de documentos e selfies  | `openssl rand -hex 32`              | **MUITO ALTA** |
| `NEXTAUTH_SECRET`             | Assinatura de sessões Auth.js         | `openssl rand -base64 32`           | ALTA |
| `POSTGRES_PASSWORD`           | Banco de dados                        | Senha forte (20+ caracteres)        | ALTA |
| `DATABASE_URL`                | Conexão Prisma                        | Contém a senha do banco             | ALTA |
| Credenciais de admin inicial  | Seed de primeiro usuário ADMIN        | Definido manualmente                | ALTA |

---

## 2. Regras de Ouro

1. **Nunca** commite secrets reais no Git.
2. **Nunca** use a mesma secret em desenvolvimento e produção.
3. **Nunca** envie secrets por WhatsApp, email ou Slack sem criptografia.
4. Todo segredo deve ter um dono responsável (mesmo que temporariamente você).
5. Faça backup offline das secrets principais (STORAGE_ENCRYPTION_KEY é irrecuperável se perdida).

---

## 3. Geração de Secrets

### STORAGE_ENCRYPTION_KEY (obrigatório)

```bash
openssl rand -hex 32
```

Deve ter **exatamente 64 caracteres hex** (32 bytes).

### NEXTAUTH_SECRET

```bash
openssl rand -base64 32
```

### Senha do PostgreSQL

Use um gerador forte. Exemplos:
- Bitwarden Password Generator
- `pwgen -s 24 1`

---

## 4. Armazenamento e Distribuição

### Durante o desenvolvimento

- Arquivo `.env` local (nunca commitado).
- Cada desenvolvedor mantém suas próprias secrets de dev.

### Para o VPS de produção (Hostinger)

Métodos recomendados (escolha um e documente):

**Opção A (recomendada para início):**
- Copiar manualmente o arquivo `.env` via `scp` ou `rsync` com SSH.
- Arquivo fica em `/home/deploy/confirmaid/.env` com permissão `600`.

**Opção B (melhor no futuro):**
- Usar um gerenciador de secrets (ex: Doppler, Infisical, ou HashiCorp Vault).
- O container lê as variáveis do gerenciador no startup.

**Opção C (simples):**
- Usar Docker secrets ou variáveis de ambiente injetadas pelo orquestrador (quando evoluirmos).

---

## 5. Permissões de Arquivo

No VPS:

```bash
chmod 600 /home/deploy/confirmaid/.env
chown deploy:deploy /home/deploy/confirmaid/.env
```

A pasta `storage/private` deve ter:

```bash
chmod 700 /home/deploy/confirmaid/storage/private
```

---

## 6. Rotação de Secrets (Planejamento)

- `STORAGE_ENCRYPTION_KEY`: Muito difícil de rotacionar (exigiria re-criptografar todos os arquivos). Trate como "imutável" no MVP.
- `NEXTAUTH_SECRET`: Pode ser rotacionado com cuidado (sessões serão invalidadas).
- Senha do banco: Pode ser alterada com downtime controlado.

**Regra:** No MVP evite rotação desnecessária. Foque em não perder as secrets.

---

## 7. O que fazer se uma secret vazar

1. Imediatamente gere uma nova secret.
2. Atualize no ambiente afetado.
3. Revogue/invalide o que for possível (ex: force logout de todos via mudança de NEXTAUTH_SECRET).
4. Investigue logs de acesso (especialmente `AuditLog` e acessos a documentos).
5. Se `STORAGE_ENCRYPTION_KEY` vazou → considere todos os documentos comprometidos (mesmo criptografados).

---

## 8. Checklist de Secrets (antes de ir para produção)

- [ ] Todas as secrets geradas com comandos fortes.
- [ ] `.env` de produção diferente de desenvolvimento.
- [ ] `STORAGE_ENCRYPTION_KEY` salva em pelo menos 2 lugares seguros offline.
- [ ] `NEXTAUTH_SECRET` diferente entre ambientes.
- [ ] Senha do Postgres forte e única.
- [ ] Arquivo `.env` com permissão 600 no servidor.
- [ ] Nenhuma secret aparece em logs ou código.

---

## 9. Ferramentas Recomendadas

- Gerador: `openssl`, `pwgen`, ou gerenciador de senhas.
- Compartilhamento seguro: Bitwarden Send, 1Password, ou `gpg`.
- Gerenciador completo (futuro): Doppler, Infisical (self-hosted), ou AWS Secrets Manager.

---

*Documento de apoio — consulte antes da Fase 0 e Fase 10.*