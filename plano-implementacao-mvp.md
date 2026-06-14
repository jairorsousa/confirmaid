# Plano de Implementação do MVP — ConfirmaID

**Versão:** 1.0  
**Data:** 14 de junho de 2026  
**Objetivo:** Levar o projeto do zero até um MVP funcional, seguro e pronto para produção em um único VPS Hostinger, usando Docker + Cloudflare Tunnel + domínio `confirmaid.com.br`.

**Restrições importantes:**
- Tudo em **um único VPS** (Hostinger).
- **100% Docker** (docker-compose).
- Ingress via **Cloudflare Tunnel** (não expor portas públicas diretamente).
- Stack: Next.js 15 (fullstack) + TypeScript + Prisma + PostgreSQL + Auth.js + Tailwind + shadcn/ui.
- Foco em MVP com análise manual.
- **Nenhuma API pública de parceiros no MVP** (acesso via painel web autenticado).

---

## Visão Geral das Fases

O plano está dividido em **10 fases sequenciais**. Cada fase tem objetivos claros, tarefas detalhadas, entregáveis e critérios de aceite.

| Fase | Nome | Foco Principal | Dificuldade Estimada |
|------|------|----------------|----------------------|
| 0 | Infraestrutura e Ambiente | VPS + Docker + Cloudflare Tunnel | Baixa |
| 1 | Projeto Base | Next.js + Prisma + Docker Compose | Baixa |
| 2 | Autenticação e Autorização | Auth.js + Papéis (USER / PARTNER / ANALYST / ADMIN) | Média |
| 3 | Modelo de Dados | Prisma Schema completo | Média |
| 4 | Armazenamento Seguro | Upload + Criptografia AES-256-GCM + Download seguro | Alta |
| 5 | Jornada do Cidadão | Cadastro → Uploads → Envio → Status + Código CID | Média-Alta |
| 6 | Painel Administrativo | Lista + Análise + Aprovar/Reprovar/Reenviar | Alta |
| 7 | Painel do Parceiro | Consulta de identidades (sem ver documentos) | Média |
| 8 | Polimento e Experiência | Estados, Feedback, Validações, Design System, Mobile | Média |
| 9 | Operação e Segurança | Backups, Logs, Rate Limit, Hardening, Retenção | Média |
| 10 | Deploy em Produção | Configuração final no VPS + Cloudflare Tunnel + Smoke tests | Média |

**Ordem recomendada:** Seguir estritamente de 0 a 10. Algumas fases podem ter tarefas paralelas (ex: documentação e testes), mas o core técnico deve ser sequencial.

---

## Fase 0 — Infraestrutura e Ambiente (Preparação)

**Objetivo:** Deixar o VPS pronto para receber a aplicação com segurança e sem expor portas desnecessárias.

### Tarefas

1. **Configuração inicial do VPS (Hostinger)**
   - Criar VPS com Ubuntu 22.04 ou 24.04 LTS (recomendado).
   - Atualizar sistema (`apt update && apt upgrade`).
   - Criar usuário não-root com sudo.
   - Configurar SSH key-only (desabilitar password login).
   - Instalar Docker + Docker Compose (oficial).
   - Instalar ferramentas básicas: `git`, `curl`, `htop`, `ufw`, `fail2ban`, `unzip`.

2. **Firewall básico**
   - UFW: permitir apenas SSH (22) e (opcionalmente) 80/443 se necessário para o tunnel.
   - Cloudflare Tunnel cuida da exposição — idealmente deixar apenas SSH exposto publicamente.

3. **Cloudflare Tunnel**
   - Instalar `cloudflared` no VPS.
   - Criar túnel no Cloudflare Dashboard (Zero Trust).
   - Configurar o túnel para rotear `confirmaid.com.br` e subdomínios (se houver) para o container Next.js (ex: porta interna 3000).
   - Configurar `cloudflared` como serviço systemd.
   - Validar que o domínio resolve via tunnel (sem necessidade de abrir porta 3000 no firewall).

4. **Repositório e estrutura inicial**
   - Criar repositório Git (GitHub ou GitLab privado recomendado).
   - Clonar no VPS em `/opt/confirmaid` ou `/home/deploy/confirmaid`.
   - Criar estrutura básica de pastas para Docker.

5. **Secrets e variáveis de ambiente**
   - Criar arquivo `.env.example` com todas as variáveis necessárias (sem valores reais).
   - Gerar chaves iniciais:
     - `STORAGE_ENCRYPTION_KEY` (32 bytes hex)
     - `NEXTAUTH_SECRET`
     - Senha do banco de dados
   - Documentar onde guardar as secrets com segurança (password manager + backup offline).

6. **Docker Compose base (esqueleto)**
   - Criar `docker-compose.yml` inicial com serviços:
     - `app` (Next.js)
     - `db` (PostgreSQL)
   - Volumes para `postgres_data` e `storage_private`.
   - Network interna.

7. **Backup inicial da infra**
   - Script simples de backup do Postgres + pasta `storage/private` (ainda vazia).
   - Documentar processo de restore.

### Entregáveis da Fase 0
- VPS acessível via SSH com usuário não-root.
- Cloudflare Tunnel funcionando (domínio aponta para o VPS sem portas expostas).
- Repositório Git inicializado.
- `docker-compose.yml` básico rodando (apenas Postgres + esqueleto do app).
- `.env.example` completo.
- Documento `infra.md` ou seção no plano com comandos exatos usados.

### Critérios de Aceite
- Consegue acessar o domínio via Cloudflare Tunnel e ver um "Hello World" ou página estática.
- Nenhuma porta da aplicação exposta publicamente.
- Secrets geradas e documentadas (não commitadas).

---

## Fase 1 — Projeto Base e Ambiente de Desenvolvimento

**Objetivo:** Ter o projeto Next.js rodando localmente e dentro do Docker Compose de forma reprodutível.

### Tarefas

1. Inicializar Next.js 15 com:
   - `--yes`
   - Tailwind CSS
   - TypeScript
   - ESLint
   - App Router

2. Instalar dependências principais:
   - `@prisma/client`, `prisma`
   - `next-auth` (v5 / Auth.js)
   - `zod`
   - `react-hook-form` + `@hookform/resolvers`
   - `lucide-react`
   - `date-fns` ou `dayjs`
   - `shadcn/ui` (via CLI) — instalar componentes base (button, card, input, dialog, table, toast, etc.)

3. Configurar Prisma:
   - `prisma init`
   - Ajustar `prisma/schema.prisma` para usar PostgreSQL.
   - Criar `docker-compose.yml` com Postgres + volume persistente.

4. Estrutura de pastas conforme documento de arquitetura:
   - `app/(auth)`, `app/(citizen)`, `app/(partner)`, `app/(admin)`
   - `lib/auth`, `lib/db`, `lib/storage`, `lib/validation`
   - `components/ui` (shadcn)
   - `storage/private` (com `.gitkeep` + no `.gitignore`)

5. Configurar variáveis de ambiente:
   - `.env.local` para desenvolvimento local.
   - Docker Compose deve injetar as variáveis corretamente no container `app`.

6. Criar um script de desenvolvimento:
   - `docker-compose up -d db`
   - `npx prisma migrate dev`
   - `npm run dev` (ou dentro do container).

7. Configurar `.gitignore` corretamente (incluindo `storage/private`, `.env*`, etc.).

### Entregáveis
- Projeto Next.js rodando localmente (`http://localhost:3000`).
- Docker Compose sobe Postgres + app (mesmo que o app ainda seja vazio).
- Prisma client gerado e conectado.
- Estrutura de pastas básica criada.

### Critérios de Aceite
- `npm run dev` funciona localmente.
- `docker-compose up` sobe o banco sem erro.
- É possível rodar `npx prisma studio` apontando para o container do banco.

---

## Fase 2 — Autenticação e Autorização Base

**Objetivo:** Ter sistema de login/registro com papéis funcionando e rotas protegidas.

### Tarefas

1. Instalar e configurar **Auth.js v5** (NextAuth):
   - Provider de Credenciais (email + senha).
   - Hash de senha (bcrypt ou argon2).
   - Configuração de sessão (JWT ou Database Sessions — recomendar Database Sessions para revogação fácil).

2. Modelo mínimo de usuário no Prisma (pode ser expandido na Fase 3):
   - `id`, `name`, `email`, `passwordHash`, `role`, `createdAt`, `updatedAt`, `status` (active/inactive).

3. Criar páginas/rotas:
   - `/login`
   - `/cadastro` (para cidadãos)
   - `/cadastro-parceiro` (simplificado ou via admin no MVP)

4. Implementar middleware de proteção de rotas:
   - Middleware Next.js que verifica sessão + papel.
   - Rotas agrupadas por role usando route groups: `(citizen)`, `(partner)`, `(admin)`.

5. Criar helpers de autorização:
   - `requireRole(role)`
   - `getCurrentUser()`

6. Fluxo básico de registro + login para **USER** (cidadão).

7. Criar seed inicial para um usuário Admin (via script ou Prisma seed).

### Entregáveis
- Login e cadastro funcionando para cidadãos.
- Redirecionamento correto por papel após login.
- Páginas protegidas que negam acesso se o papel for incorreto.
- Seed de usuário admin.

### Critérios de Aceite
- Cidadão consegue se cadastrar e logar.
- Tentar acessar área de admin sem permissão resulta em redirect ou 403.
- Admin consegue logar e acessar área administrativa (mesmo que vazia).

---

## Fase 3 — Modelo de Dados Completo

**Objetivo:** Ter o schema do banco que suporte todo o MVP.

### Tarefas

Criar/atualizar `prisma/schema.prisma` com as entidades principais:

- `User` (com role)
- `Verification` (status, code, dates, user relation)
- `Document` (type, stored_filename, metadata, sha256, iv, auth_tag, verification)
- `Partner` (empresa + status)
- `PartnerUser` (ou usar User com role PARTNER + partnerId)
- `Consultation` (log de consultas feitas por parceiros)
- `AuditLog` (todas as ações sensíveis)
- `VerificationHistory` (para rastrear mudanças de status e reenvios)

Campos importantes:
- `verification.code` (formato `CID-XXXXXX`)
- Status enums claros (PENDING, UNDER_REVIEW, CORRECTION_REQUESTED, APPROVED, REJECTED, BLOCKED, EXPIRED, ABANDONED)
- `expires_at` na verificação
- Campos de mascaramento e consentimento

Criar migrations:
- `prisma migrate dev`
- Seeds úteis (admin + 1-2 parceiros de teste + usuários fictícios)

Documentar o modelo em `docs/data-model.md` (resumido).

### Entregáveis
- Schema Prisma completo e versionado.
- Migrations aplicadas.
- Seeds funcionais.
- Documentação leve do modelo de dados.

### Critérios de Aceite
- `prisma db push` ou migrate funciona sem erro.
- É possível criar uma verificação completa via Prisma Studio ou script.

---

## Fase 4 — Módulo de Armazenamento Seguro de Arquivos (Core Técnico)

**Objetivo:** Implementar o coração de segurança do MVP: upload e acesso controlado a documentos criptografados.

### Tarefas

1. Criar módulo em `lib/storage/`:
   - Função `encryptAndSaveFile(buffer, verificationId, type)`
   - Função `decryptAndServeFile(documentId)`
   - Função `deleteVerificationFiles(verificationId)`
   - Validação de tipo (JPG/PNG), tamanho (máx 8MB) e magic bytes.

2. Rota de upload (Server Action ou API Route):
   - Aceitar 3 tipos: `FRONT`, `BACK`, `SELFIE`.
   - Salvar criptografado + registrar metadados no banco.
   - Validação rigorosa no servidor.

3. Rota segura de download/visualização:
   - `GET /api/documents/[documentId]`
   - Checagem de permissão:
     - Dono da verificação (USER)
     - ANALYST / ADMIN
     - Parceiro → **negado** (por decisão do MVP)
   - Descriptografar em memória e transmitir com headers corretos.
   - Registrar log de acesso em `AuditLog`.

4. Componente de Upload reutilizável (alinhado com Design System):
   - Drag & drop + seleção.
   - Preview da imagem antes do envio.
   - Estados: vazio, selecionado, enviando, sucesso, erro.
   - Validação de tamanho e tipo no cliente + servidor.

5. Integração com o fluxo de verificação (mesmo que parcial).

### Entregáveis
- Módulo de armazenamento criptografado funcionando.
- Upload de frente/verso/selfie salvando corretamente no disco criptografado.
- Visualização segura das imagens apenas para quem tem permissão.
- Logs de acesso registrados.

### Critérios de Aceite
- Imagem enviada não é legível diretamente no disco (está criptografada).
- Apenas o dono e admins conseguem visualizar via rota protegida.
- Tentativa de acesso por parceiro é bloqueada e logada.

---

## Fase 5 — Jornada Completa do Cidadão (User)

**Objetivo:** Permitir que um cidadão complete todo o fluxo de verificação até receber o código.

### Tarefas

1. Cadastro completo:
   - Nome, CPF, data de nascimento, email, celular, senha.
   - Aceite de termos + política de privacidade (registrar timestamp e versão).

2. Fluxo de verificação em etapas (Stepper):
   - Dados pessoais (já preenchidos no cadastro).
   - Escolha do documento (RG ou CNH).
   - Upload da frente.
   - Upload do verso.
   - Upload da selfie (com instruções visuais).
   - Revisão e confirmação de envio.

3. Após envio:
   - Status muda para `PENDING` → `UNDER_REVIEW`.
   - Página de "Em análise" com estimativa de tempo.

4. Estados posteriores visíveis para o usuário:
   - Correção solicitada (com motivo + o que precisa reenviar).
   - Aprovado → mostrar código `CID-XXXXXX` com botão copiar + validade.
   - Reprovado (com motivo).
   - Bloqueado.

5. Histórico básico de sua própria verificação.

6. Aplicar Design System + estados de loading/erro/empty.

### Entregáveis
- Fluxo end-to-end do cidadão funcionando (do cadastro até ver o código).
- Reenvio parcial funcionando quando solicitado correção.
- Status visível e claro em todas as etapas.

### Critérios de Aceite
- Usuário consegue enviar os 3 documentos e ver "Em análise".
- Quando admin solicita correção, o usuário consegue reenviar apenas o necessário.
- Ao ser aprovado, o código aparece corretamente formatado e copiável.

---

## Fase 6 — Painel Administrativo (Análise Manual)

**Objetivo:** Permitir que analistas e admins revisem, decidam e gerenciem verificações.

### Tarefas

1. Lista de verificações pendentes:
   - Tabela com: nome, CPF mascarado, tipo documento, status, data de envio, ações.
   - Filtros por status, data, busca por nome/código.

2. Tela de detalhe da verificação:
   - Dados cadastrais completos.
   - Visualização das 3 imagens (usando a rota segura da Fase 4).
   - Histórico de decisões anteriores.
   - Campo de observação interna.

3. Ações do analista:
   - Aprovar → gerar código único `CID-XXXXXX`, definir `expires_at` (12 meses), mudar status.
   - Reprovar → exigir motivo (lista predefinida + livre).
   - Solicitar correção → escolher quais partes + motivo obrigatório.
   - Bloquear (conta ou verificação) → com motivo.

4. Registro automático em `AuditLog` + `VerificationHistory`.

5. Dashboard simples (cards):
   - Pendentes hoje
   - Aprovadas hoje
   - Tempo médio de análise (básico)
   - Verificações em análise

6. Gestão básica de parceiros (cadastro, ativação, inativação) — pode ser simplificada.

### Entregáveis
- Painel admin funcional para análise completa.
- Todas as decisões registradas em histórico.
- Geração de código único na aprovação.

### Critérios de Aceite
- Admin consegue aprovar uma verificação e o cidadão vê o código imediatamente.
- Solicitação de correção funciona corretamente no lado do cidadão.
- Histórico de decisões está visível no detalhe.

---

## Fase 7 — Painel do Parceiro

**Objetivo:** Parceiros conseguem consultar identidades de forma segura.

### Tarefas

1. Cadastro e aprovação de parceiros (feito pelo admin).

2. Login de parceiro (papel `PARTNER`).

3. Tela principal de consulta:
   - Campo de busca: Código ConfirmaID, E-mail ou CPF.
   - Botão "Consultar".

4. Resultado da consulta (conforme decisão do PRD):
   - Se verificado: Nome, CPF mascarado, Código, Data de verificação, Validade.
   - Se não verificado / em análise / expirado / bloqueado: status claro.

5. Histórico de consultas realizadas pelo parceiro (tabela simples).

6. **Importante:** Garantir que em nenhuma hipótese o parceiro veja imagens ou dados sensíveis desnecessários.

### Entregáveis
- Parceiro consegue fazer consultas com sucesso.
- Histórico de consultas registrado.
- Parceiro inativo não consegue consultar.

### Critérios de Aceite
- Consulta por código retorna os dados corretos (sem imagens).
- Consulta por CPF retorna apenas dados mascarados.
- Todo acesso fica registrado em `Consultation` + `AuditLog`.

---

## Fase 8 — Polimento, Experiência e Design System

**Objetivo:** Elevar a qualidade para um nível profissional usando o Design System.

### Tarefas

1. Implementar todos os estados de componentes definidos no Design System atualizado:
   - Botões (loading, disabled, etc.)
   - Upload com todos os estados
   - Toasts / Alerts / Banners
   - Empty states e error states
   - Loading skeletons

2. Aplicar padrões mobile e instruções visuais de upload.

3. Validação completa de formulários com Zod (cliente + servidor).

4. Mensagens de erro e sucesso amigáveis e específicas.

5. Acessibilidade básica:
   - Labels corretos
   - Foco visível
   - Contraste
   - Navegação por teclado nas principais telas

6. Componente de Stepper visual para o fluxo do cidadão.

7. Página de revisão antes do envio final.

8. Notificações in-app básicas (ex: "Você tem uma correção solicitada").

### Entregáveis
- Aplicação visualmente consistente com o Design System.
- Boa experiência em celular (principal fluxo).
- Feedback claro em todas as ações.

### Critérios de Aceite
- Um usuário novo consegue completar o fluxo sem ficar confuso.
- Não existem estados "quebrados" ou sem feedback.

---

## Fase 9 — Operação, Segurança e Preparação para Produção

**Objetivo:** Deixar o sistema operável e minimamente seguro para produção.

### Tarefas

1. **Backups**
   - Script ou serviço que faz dump do Postgres + compactação da pasta `storage/private`.
   - Agendamento via cron no host ou dentro de um container auxiliar.
   - Testar restore pelo menos uma vez.

2. **Logs e Auditoria**
   - Garantir que `AuditLog` e `Consultation` estão sendo preenchidos em todos os pontos críticos.
   - Logs do Next.js sendo capturados (stdout).

3. **Segurança**
   - Rate limiting básico em login e consultas de parceiro (ex: usando `rate-limiter-flexible` ou middleware simples).
   - Validação rigorosa de todos os uploads (tamanho, tipo, magic bytes).
   - Headers de segurança básicos.
   - Remover qualquer console.log de produção.
   - Revisar todas as checagens de autorização.

4. **Retenção de dados**
   - Job simples (pode ser um script rodado por cron) que marca como expirado e deleta arquivos antigos conforme política definida no PRD (12 meses aprovados, 6 meses reprovados).

5. **Variáveis de produção**
   - Documentar todas as variáveis necessárias para produção.
   - Gerar novas chaves fortes para produção.

6. **Docker Compose de produção**
   - `docker-compose.prod.yml` ou profiles.
   - Build otimizado do Next.js (standalone output).
   - Healthcheck no container da aplicação.
   - Restart policies.

### Entregáveis
- Estratégia de backup testada.
- Job de retenção básico.
- Rate limiting aplicado nas rotas sensíveis.
- Documentação de "como rodar em produção".

### Critérios de Aceite
- É possível restaurar o banco + arquivos a partir de um backup.
- Tentativas excessivas de login são limitadas.
- Não é possível acessar arquivos diretamente pelo disco sem descriptografar via aplicação.

---

## Fase 10 — Deploy em Produção e Go-Live

**Objetivo:** Colocar o MVP no ar de forma controlada e validado.

### Tarefas

1. **Preparação final no VPS**
   - Clonar o repositório na versão estável da branch `main`.
   - Configurar `.env` de produção (todas as secrets corretas e diferentes das de dev).
   - Subir com `docker-compose up -d --build`.

2. **Cloudflare Tunnel em produção**
   - Garantir que o túnel está roteando o domínio corretamente para o container.
   - Configurar regras de segurança no Cloudflare (WAF básico, bot fight mode, etc.).
   - Forçar HTTPS.

3. **Migrações em produção**
   - Rodar `npx prisma migrate deploy` dentro do container.
   - Seed inicial de admin (se necessário).

4. **Testes de smoke (manuais obrigatórios)**
   - Cidadão: cadastro completo → envio de documentos → visualização de status.
   - Admin: login → aprovação de uma verificação → cidadão vê o código.
   - Parceiro: login → consulta bem-sucedida → histórico registrado.
   - Reenvio: solicitar correção → cidadão reenvia → admin aprova.
   - Segurança: tentar acessar documento como parceiro (deve falhar).
   - Backup: fazer backup e validar integridade.

5. **Checklist pós-deploy**
   - Monitorar logs por erros.
   - Verificar que Cloudflare Tunnel está estável.
   - Testar em celular real.
   - Verificar que arquivos estão sendo criptografados corretamente no disco de produção.
   - Confirmar que backups estão sendo gerados.

6. **Documentação final**
   - Atualizar `README.md` com instruções de deploy, rollback e operação.
   - Criar runbook básico de "como analisar uma verificação" e "como adicionar um novo parceiro".

### Entregáveis
- Aplicação rodando em `https://confirmaid.com.br` (ou o domínio configurado) via Cloudflare Tunnel.
- Fluxo completo validado em produção.
- Backups funcionando.
- Documentação operacional básica.

### Critérios de Aceite
- Um fluxo completo de verificação pode ser executado de ponta a ponta em produção.
- Não existem erros críticos em logs.
- É possível recuperar o sistema a partir de backup se necessário.

---

## Resumo de Entregáveis Finais do MVP

Ao final da Fase 10, o sistema deve permitir:

- Cidadãos se cadastrarem e completarem verificação com documento + selfie.
- Análise manual por administradores.
- Geração de código `CID-XXXXXX` único e válido por 12 meses.
- Parceiros consultarem status via painel web (sem ver documentos).
- Todo acesso sensível registrado em logs/auditoria.
- Arquivos armazenados com criptografia no servidor.
- Sistema rodando de forma estável atrás de Cloudflare Tunnel no VPS Hostinger.

---

## Dicas de Execução do Plano

- **Não pule fases.** Especialmente Fase 4 (armazenamento) antes da 5 e 6.
- Mantenha o Design System em mente desde a Fase 5.
- Escreva testes manuais simples por fase (pode ser uma checklist no próprio plano).
- Após cada fase importante, faça commit + tag (ex: `phase-4-done`).
- Atualize este plano com o que foi feito de diferente (lições aprendidas).

---

**Este é um plano vivo.**  
Conforme o desenvolvimento avançar, atualize este documento com o status real de cada fase, decisões tomadas e ajustes de escopo.

---

*Plano criado em 14/06/2026 com base na stack, arquitetura e decisões de MVP definidas anteriormente para o projeto ConfirmaID.*