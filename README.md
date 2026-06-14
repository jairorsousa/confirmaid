# ConfirmaID

**Identidade verificada, simples, segura e reutilizável.**

Plataforma de verificação de identidade digital que permite que uma pessoa valide sua identidade uma única vez e utilize essa verificação em empresas parceiras através de um código único (CID-XXXXXX).

---

## Status do Projeto

- **Fase atual:** Planejamento completo / Preparação para Fase 0
- **Objetivo do MVP:** Verificação manual de identidade (documento + selfie) + consulta por parceiros via painel web
- **Arquitetura:** Monólito Next.js em VPS único (Hostinger) com Docker + Cloudflare Tunnel

---

## Documentação

Antes de começar qualquer desenvolvimento, leia os documentos na seguinte ordem:

| Documento | Descrição | Quando ler |
|-----------|-----------|------------|
| [prd-confirmaid.md](./prd-confirmaid.md) | Product Requirements Document completo | Sempre (visão e regras) |
| [design-system-confirmaid.md](./design-system-confirmaid.md) | Design System e componentes | Ao implementar telas |
| [stack-e-arquitetura-mvp.md](./stack-e-arquitetura-mvp.md) | Stack escolhida + arquitetura + estratégia de armazenamento | Antes de começar o código |
| [plano-implementacao-mvp.md](./plano-implementacao-mvp.md) | Plano detalhado fase por fase (0 a 10) até deploy | **Principal guia de execução** |
| [docs/infra.md](./docs/infra.md) | Setup do VPS Hostinger + Docker + Cloudflare Tunnel | Fase 0 |
| [docs/data-model.md](./docs/data-model.md) | Resumo do modelo de dados | Fase 3 |
| [docs/secrets-management.md](./docs/secrets-management.md) | Como gerenciar secrets com segurança | Fase 0 e produção |
| [docs/backup-strategy.md](./docs/backup-strategy.md) | Estratégia de backup e retenção | Fase 9 |
| [docs/runbook.md](./docs/runbook.md) | Runbook operacional (deploy, análise, parceiros) | Fase 10 e operação |

---

## Stack Resumida (MVP)

- **Frontend + Backend:** Next.js 15 (App Router) + TypeScript
- **UI:** Tailwind CSS + shadcn/ui + lucide-react
- **Banco:** PostgreSQL + Prisma ORM
- **Autenticação:** Auth.js (NextAuth v5) com credenciais + roles
- **Validação:** Zod
- **Armazenamento de arquivos:** Local no servidor com criptografia AES-256-GCM
- **Infra:** Docker Compose (VPS Hostinger) + Cloudflare Tunnel
- **Domínio:** confirmaid.com.br (configurado na Cloudflare)

---

## Como Começar (quando autorizado)

1. Siga estritamente o **[plano-implementacao-mvp.md](./plano-implementacao-mvp.md)**.
2. Comece pela **Fase 0** (infraestrutura).
3. Não pule a Fase 4 (armazenamento seguro) — ela é crítica.

**Atenção:** Este repositório ainda não contém o código da aplicação. Os documentos acima definem exatamente o que será construído.

---

## Comandos Úteis (após setup)

> Estes comandos serão detalhados e validados durante a execução do plano.

```bash
# Subir ambiente de desenvolvimento
docker-compose up -d db
npm run dev

# Aplicar migrations
npx prisma migrate dev

# Acessar Prisma Studio
npx prisma studio
```

---

## Segurança e Conformidade

- Todos os documentos e selfies são criptografados em repouso.
- Parceiros **não têm acesso** às imagens no MVP.
- Logs completos de auditoria são mantidos.
- LGPD será tratada em fase posterior (após MVP).

---

## Contribuição

Por enquanto este é um projeto em fase de construção controlada. Siga o plano de implementação.

---

## Licença

Privado — ConfirmaID.

---

*Última atualização: 14 de junho de 2026*