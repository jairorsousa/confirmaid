# Runbook Operacional — ConfirmaID (MVP)

Este documento reúne procedimentos operacionais comuns após o deploy em produção.

**Público-alvo:** Administradores e pessoas que operam a plataforma.

---

## 1. Acesso ao Servidor

```bash
ssh deploy@SEU_IP_VPS
cd /home/deploy/confirmaid/app
```

Ver status dos containers:

```bash
docker compose ps
docker compose logs -f app
```

---

## 2. Deploy / Atualização de Código

### Deploy normal

```bash
cd /home/deploy/confirmaid/app

# Baixar última versão
git pull origin main

# Build e restart
docker compose -f docker-compose.prod.yml up -d --build

# Ver logs
docker compose -f docker-compose.prod.yml logs -f app
```

### Aplicar migrations em produção

```bash
docker compose -f docker-compose.prod.yml exec app npx prisma migrate deploy
```

**Nunca rode `prisma migrate dev` em produção.**

---

## 3. Procedimentos de Análise (para ANALYST / ADMIN)

### Visualizar verificações pendentes

- Acessar área administrativa (`/admin` ou caminho definido).
- Filtrar por status `PENDING` ou `UNDER_REVIEW`.

### Analisar uma verificação

1. Abrir o detalhe da verificação.
2. Visualizar os 3 documentos (frente, verso, selfie) — as imagens são descriptografadas em tempo real pela aplicação.
3. Comparar dados do formulário com o documento.
4. Usar o checklist de análise (ver PRD seção 19).

### Tomar decisão

- **Aprovar**: O sistema gera automaticamente o código `CID-XXXXXX` e define validade de 12 meses.
- **Reprovar**: Preencher motivo obrigatório.
- **Solicitar correção**: Selecionar quais documentos precisam ser reenviados + motivo.
- **Bloquear**: Usar apenas em casos de suspeita forte. Sempre justificar.

Todas as ações são registradas em `AuditLog`.

---

## 4. Adicionar um Novo Parceiro

1. Logar como ADMIN.
2. Ir na área de gestão de parceiros.
3. Preencher:
   - Razão social, CNPJ, responsável, email de contato.
4. Criar o parceiro com status `ACTIVE`.
5. Informar ao parceiro as credenciais de acesso (email + senha temporária).
6. Recomendar que ele troque a senha no primeiro login.

**Importante:** Parceiros inativos não conseguem realizar consultas.

---

## 5. Consultar Histórico de Ações (Auditoria)

- Acessar logs de auditoria (quando implementado na interface ou via Prisma Studio / query direta no banco).
- Campos úteis: `action`, `actorUserId`, `entityId`, `createdAt`, `details`.

Exemplos de queries úteis (para debug):

```sql
-- Últimas 50 ações de administradores
SELECT * FROM "AuditLog" 
WHERE "actorUserId" IS NOT NULL 
ORDER BY "createdAt" DESC 
LIMIT 50;

-- Todas as consultas feitas por um parceiro específico
SELECT * FROM "Consultation" 
WHERE "partnerId" = 'xxx' 
ORDER BY "createdAt" DESC;
```

---

## 6. Problemas Comuns e Soluções

### Usuário não consegue fazer upload

- Verificar tamanho do arquivo (máx 8MB).
- Verificar se o tipo é JPG ou PNG.
- Verificar logs do container `app`.

### Imagens não aparecem no painel admin

- Confirmar que o usuário tem papel ANALYST ou ADMIN.
- Verificar se o arquivo existe no disco e está criptografado corretamente.
- Checar logs da rota de download de documentos.

### Parceiro não consegue consultar

- Verificar se o parceiro está com `status = ACTIVE`.
- Verificar se ele está logado com papel `PARTNER`.
- Consultar a tabela `Consultation` para ver se a requisição chegou.

### Aplicação não sobe após deploy

```bash
docker compose -f docker-compose.prod.yml logs --tail=100 app
```

Possíveis causas:
- Variáveis de ambiente faltando ou erradas.
- Migration pendente.
- Problema de conexão com o banco.

---

## 7. Manutenção de Rotina

- **Diário**: Verificar se há verificações pendentes há mais de 24h úteis.
- **Semanal**: Revisar backups (ver `docs/backup-strategy.md`).
- **Mensal**: Testar restore de um backup antigo.
- **A cada 3 meses**: Revisar se há usuários/parceiros inativos que podem ser limpos.

---

## 8. Parada de Emergência

Se precisar parar tudo rapidamente:

```bash
docker compose -f docker-compose.prod.yml down
```

Para subir novamente:

```bash
docker compose -f docker-compose.prod.yml up -d
```

---

## 9. Contatos e Responsabilidades (preencher quando em produção)

- Responsável técnico principal:
- Responsável por análise de verificações:
- Responsável por parceiros:
- Contato de emergência do VPS / Hostinger:

---

## 10. Links Úteis

- Plano de implementação: [plano-implementacao-mvp.md](../plano-implementacao-mvp.md)
- PRD: [prd-confirmaid.md](../prd-confirmaid.md)
- Infraestrutura: [infra.md](./infra.md)

---

*Este runbook deve ser atualizado conforme o sistema for evoluindo (Fase 10 e operação contínua).*