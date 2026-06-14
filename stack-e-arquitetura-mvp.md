# Stack e Arquitetura — ConfirmaID (MVP)

**Data:** 14 de junho de 2026  
**Versão:** 1.0  
**Objetivo:** Definir a stack tecnológica e a arquitetura para o MVP do ConfirmaID, com foco em simplicidade, segurança razoável e velocidade de desenvolvimento.

---

## 1. Decisão de Stack Recomendada

### Stack Principal (Recomendada para o MVP)

| Camada              | Tecnologia                          | Justificativa |
|---------------------|-------------------------------------|-------------|
| **Framework**       | Next.js 15 (App Router) + TypeScript | Fullstack em um único projeto. Excelente DX, deploy simples, Server Components, Server Actions e API Routes nativos. |
| **UI / Estilização**| Tailwind CSS + shadcn/ui + lucide-react | Perfeitamente alinhado com o Design System já definido. shadcn/ui oferece componentes de alta qualidade e customizáveis. |
| **Banco de Dados**  | PostgreSQL + Prisma ORM             | PostgreSQL é robusto, tem JSON, full-text search e boa performance. Prisma oferece excelente DX, type-safety e migrations. |
| **Autenticação**    | Auth.js (NextAuth v5)               | Suporte nativo a credenciais (email/senha), sessions, JWT, roles e callbacks. Baixo custo para MVP. |
| **Validação**       | Zod                                 | Schema validation em runtime + inferência de tipos. Essencial para segurança de inputs. |
| **Uploads**         | API Routes + validação nativa + `crypto` | Controle total sobre o fluxo de arquivos (ver seção de armazenamento). |
| **Admin UI**        | shadcn/ui + TanStack Table (ou simples) | Rápido de montar tabelas, filtros e ações. |
| **Testes (MVP)**    | Vitest + Playwright (básico)        | Testes unitários leves + alguns E2E críticos. |
| **Deploy**          | VPS simples (Hetzner / DigitalOcean) com Docker + Nginx ou Vercel (inicial) | Controle total do servidor (necessário para armazenamento local seguro). |

### Por que Next.js Fullstack para este MVP?

- Um único repositório e deploy.
- Não precisamos de um backend separado no começo.
- Server Actions reduzem drasticamente a quantidade de endpoints que precisamos escrever.
- Fácil adicionar API pública de parceiros no futuro (quando sairmos do MVP).
- Ótimo ecossistema de componentes (combina perfeitamente com o design system).

---

## 2. Alternativas Avaliadas

| Stack | Prós | Contras | Quando considerar |
|-------|------|---------|-------------------|
| **Next.js 15 Fullstack (Recomendada)** | DX excelente, deploy simples, um só projeto, type-safety forte, fácil escalar depois | Monólito pode crescer demais se não modularizarmos | MVP atual + produtos SaaS B2B/B2C |
| **Supabase (Auth + Postgres + Storage) + Next.js** | Velocidade absurda de desenvolvimento, Storage gerenciado, Auth pronto, Row Level Security | Menos controle sobre armazenamento de arquivos sensíveis (embora seja possível), vendor lock-in parcial | Quando quiser velocidade máxima e aceitar Storage gerenciado |
| **Laravel 11 + Inertia.js + React** | PHP maduro, ótima para equipes que já conhecem Laravel, Blade + React híbrido | Menos "moderno" que Next.js, deploy um pouco mais pesado | Se a equipe for mais forte em PHP/Laravel |
| **NestJS + Next.js separado** | Arquitetura muito limpa (Domain-Driven), escalável | Overkill para MVP, dois projetos, complexidade maior | Quando o produto já tiver escala certa ou time backend forte |
| **Fastify + React + Prisma** | Performance alta no backend | Menos ferramentas prontas que Next.js, mais boilerplate | Se performance de API for crítica desde o dia 1 |

**Decisão final para o MVP:** Next.js 15 Fullstack + Prisma + PostgreSQL + Auth.js.

---

## 3. Arquitetura de Alto Nível (MVP)

```
┌─────────────────────────────────────────────────────────────┐
│                        Usuário (Browser)                     │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                      Next.js App (VPS / Vercel)              │
│  ┌──────────────────┐   ┌───────────────────────────────┐  │
│  │   App Router     │   │   Server Actions / API Routes │  │
│  │   (React + TS)   │◄──┤   (Auth, Upload, Consultas)   │  │
│  └──────────────────┘   └───────────────────────────────┘  │
│                              │                              │
│                              ▼                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Prisma + PostgreSQL                    │   │
│  │  (Users, Verifications, Documents, Partners, Logs)  │   │
│  └─────────────────────────────────────────────────────┘   │
│                              │                              │
│                              ▼                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │         storage/private/verifications/{id}/         │   │
│  │         (Arquivos criptografados AES-256-GCM)       │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

**Características da arquitetura:**
- Monólito modular (separação por domínio dentro da pasta `app` e `lib`).
- Toda lógica sensível (upload, criptografia, decisão de análise) fica no servidor.
- Arquivos nunca são servidos estaticamente.
- Acesso a arquivos sempre passa por checagem de autorização.

---

## 4. Estrutura de Pastas Recomendada

```
confirmaid/
├── app/
│   ├── (auth)/                  # rotas de login, cadastro, etc
│   ├── (citizen)/               # área do usuário final
│   ├── (partner)/               # área do parceiro
│   ├── (admin)/                 # área administrativa (análise)
│   ├── api/                     # API routes (quando necessário)
│   ├── layout.tsx
│   └── page.tsx
├── components/
│   ├── ui/                      # shadcn/ui + componentes base
│   ├── forms/
│   ├── verification/
│   └── admin/
├── lib/
│   ├── auth/                    # helpers do Auth.js + roles
│   ├── db/                      # prisma client + queries
│   ├── storage/                 # funções de salvar/ler/criptografar arquivos
│   ├── validation/              # schemas Zod
│   └── utils/
├── prisma/
│   ├── schema.prisma
│   └── migrations/
├── storage/
│   └── private/                 # NUNCA commitar. Ignorado no .gitignore
│       └── verifications/
├── public/                      # apenas assets estáticos não-sensíveis (logo, etc)
├── .env.example
├── docker-compose.yml           # Postgres + app (opcional)
└── package.json
```

**Regras importantes:**
- `storage/private/` deve estar no `.gitignore`.
- Nunca colocar lógica de negócio em componentes de cliente quando ela envolve dados sensíveis.
- Toda rota que lida com documentos deve ter middleware de autorização.

---

## 5. Estratégia de Armazenamento de Arquivos (MVP)

### Requisitos do MVP
- Simplicidade de operação.
- Segurança razoável (arquivos não expostos publicamente).
- Capacidade de auditoria (saber exatamente o que foi enviado).
- Fácil de migrar para S3 + KMS no futuro.

### Decisão Técnica

**Local no servidor com criptografia em repouso (AES-256-GCM).**

**Estrutura no disco:**
```
storage/private/verifications/
  vrf_cld9k2m3p8x4q7v/
    front-7f3a9b2e1c4d.enc
    back-9e2c4f7a1b3d.enc
    selfie-1d8e6c2f9a4b.enc
```

**Regras de nomenclatura:**
- Nunca usar o nome original do arquivo do usuário.
- Nome = `{type}-{uuid-v4}.enc`
- Extensão `.enc` deixa explícito que está criptografado.

**Metadados armazenados no banco (tabela `documents`):**
- `id`
- `verification_id`
- `type` (FRONT, BACK, SELFIE)
- `stored_filename`
- `original_filename_hash` (SHA256 do nome original — útil para auditoria)
- `mime_type`
- `size_bytes`
- `sha256` (hash do conteúdo original)
- `iv` (vetor de inicialização — 12 bytes para GCM)
- `auth_tag` (tag de autenticação GCM)
- `uploaded_at`

**Fluxo de upload:**
1. Usuário seleciona arquivo.
2. Validação no cliente (tipo e tamanho) + no servidor (obrigatório).
3. Servidor lê o buffer.
4. Calcula SHA256 do conteúdo original.
5. Gera IV aleatório.
6. Criptografa com `crypto.createCipheriv('aes-256-gcm', key, iv)`.
7. Salva o arquivo `.enc` no disco.
8. Salva registro no banco com IV + authTag + metadados.
9. Descarta o buffer original da memória.

**Chave de criptografia:**
- Armazenada em variável de ambiente (`STORAGE_ENCRYPTION_KEY`).
- Deve ter exatamente 32 bytes (256 bits).
- Recomendação: gerar com `openssl rand -hex 32`.
- **Nunca** versionar essa chave.

**Servindo os arquivos:**
- Somente através de rota autenticada: `GET /api/documents/[documentId]`
- A rota:
  1. Verifica se o usuário está autenticado.
  2. Verifica permissão (ver seção de papéis).
  3. Lê o registro do banco.
  4. Lê o arquivo `.enc`.
  5. Descriptografa usando IV + authTag.
  6. Retorna o arquivo com `Content-Disposition: inline` ou `attachment`.
  7. Registra log de acesso (quem acessou, quando, qual documento).

**Permissões de visualização de documentos (decisão do MVP):**

| Papel          | Pode ver documentos? | Observação |
|----------------|----------------------|----------|
| Cidadão (dono) | Sim (apenas os seus) | Para revisar o que enviou |
| Admin / Analyst| Sim                  | Necessário para análise |
| Parceiro       | **Não**              | Ver apenas status + dados mascarados |

Esta decisão mantém o princípio original do produto: o parceiro não precisa (e não deve) receber os documentos completos.

**Se um parceiro precisar do documento em casos excepcionais:**
- Ele abre uma "solicitação de visualização".
- O admin aprova manualmente.
- Gera um link temporário (expira em 15 minutos) com log completo.
- Isso fica registrado em auditoria.

**Política de retenção (MVP):**
- Verificações aprovadas: documentos mantidos por **12 meses** após a data de aprovação.
- Verificações reprovadas / bloqueadas: mantidos por **6 meses**.
- Após o período: deletar fisicamente os arquivos + marcar como `purged` no banco.

---

## 6. Modelo de Autenticação e Papéis (MVP)

### Papéis

| Papel     | Descrição                                      | Acesso principal                     |
|-----------|------------------------------------------------|--------------------------------------|
| `USER`    | Cidadão que está verificando sua identidade    | Área do usuário, enviar documentos   |
| `PARTNER` | Funcionário de empresa parceira                | Painel de consulta de identidades    |
| `ANALYST` | Analista interno que aprova/reprova            | Painel administrativo de verificações |
| `ADMIN`   | Administrador com poderes elevados             | Tudo + gestão de usuários/parceiros  |

### Autenticação

- **Email + Senha** (principal no MVP).
- Senha com mínimo de 8 caracteres + força básica.
- Hash com bcrypt (ou argon2 se disponível).
- Sessão via Auth.js (JWT ou database sessions — database sessions são mais fáceis para revogar).
- Login com magic link pode ser adicionado depois.

### Autorização

- Middleware em rotas e Server Actions.
- Cada página/ação verifica o papel do usuário.
- Parceiros só conseguem consultar identidades se estiverem com status `ACTIVE`.

**Observação importante:**  
No MVP os parceiros **não terão API pública**. Eles vão acessar via interface web da plataforma (painel de parceiro). Isso simplifica bastante a segurança no primeiro momento.

---

## 7. Considerações de Segurança para o MVP

- Todos os inputs validados com Zod (nunca confiar no cliente).
- Rate limiting básico nas rotas de login e consulta de parceiro (ex: 5 tentativas por minuto).
- Arquivos validados por MIME type + magic bytes + tamanho máximo (ex: 8MB por imagem).
- Nunca confiar em nomes de arquivo enviados pelo usuário.
- Logs de todas as ações sensíveis (aprovação, reprovação, visualização de documento, consulta de parceiro).
- `.env` nunca commitado.
- Pasta `storage/private` protegida por permissão do sistema de arquivos (600/640).
- Headers de segurança básicos (Helmet ou equivalentes via Next).
- Backup diário da pasta de storage + dump do banco (script simples).

**O que não vamos fazer no MVP (mas documentar como dívida técnica):**
- Criptografia de chave por usuário (KMS por tenant)
- WAF avançado
- Deteção automática de deepfake
- MFA obrigatório
- Auditoria imutável (WORM)

---

## 8. Deploy e Infraestrutura Inicial

**Opção recomendada para MVP:**
- VPS pequeno (2 vCPU / 4GB) na Hetzner ou DigitalOcean.
- Docker Compose com:
  - App Next.js (standalone build)
  - PostgreSQL
  - (opcional) Nginx como reverse proxy
- Domínio + SSL via Let's Encrypt.
- Backups: script simples que faz dump do Postgres + tar da pasta `storage/private` + envia para storage externo (ou email).

**Alternativa mais simples no começo:**
- Hospedar no Vercel (fácil) + usar Postgres gerenciado (Neon ou Supabase Postgres).
- **Problema:** A pasta `storage/private` não funciona bem em serverless (Vercel tem filesystem efêmero).
- **Solução intermediária:** Usar volume persistente ou migrar cedo para VPS se escolhermos armazenamento local.

**Recomendação prática:**
Começar em VPS desde o primeiro dia para não ter dor de cabeça com armazenamento de arquivos.

---

## 9. Riscos e Dívidas Técnicas

| Risco | Mitigação no MVP | Plano futuro |
|-------|------------------|--------------|
| Vazamento de documentos por falha de permissão | Checagem dupla de autorização em toda rota de documento + logs | Auditoria automatizada + testes de penetração |
| Crescimento do monólito | Manter domínios bem separados (lib/ + app/ por área) | Avaliar split quando atingir 10k+ verificações/mês |
| Chave de criptografia em uma única máquina | Chave no .env + backup seguro da chave | Migrar para KMS (AWS/GCP) ou Vault |
| Performance de listagens admin | Paginação + filtros obrigatórios + índices no banco | Introduzir cache ou views materializadas |

---

## 10. Próximos Passos Imediatos

1. Definir o modelo de dados completo (`prisma/schema.prisma`).
2. Configurar o projeto Next.js + Prisma + Auth.js.
3. Implementar o módulo de armazenamento seguro de arquivos (primeiro sem cripto, depois com).
4. Criar os papéis e middleware de autorização.
5. Implementar o fluxo de cadastro + verificação do cidadão.
6. Implementar o painel básico do admin (lista + visualização de documentos).
7. Implementar o painel de parceiro (consulta simples).

---

**Documento vivo.**  
Conforme o projeto evoluir, este documento deve ser atualizado com novas decisões de arquitetura.

---

*Decisões tomadas em 14/06/2026 para o MVP do ConfirmaID. Foco em simplicidade com segurança mínima aceitável para um produto que lida com dados de identidade.*