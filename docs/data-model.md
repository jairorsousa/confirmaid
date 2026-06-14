# Modelo de Dados — ConfirmaID (MVP)

Este documento resume as entidades principais que serão implementadas no `prisma/schema.prisma`.

**Atenção:** Este é um resumo para planejamento. O schema definitivo será criado e versionado durante a Fase 3.

---

## Entidades Principais

### 1. User

Representa qualquer pessoa que acessa a plataforma.

| Campo            | Tipo              | Observações |
|------------------|-------------------|-----------|
| id               | String (cuid)     | PK |
| name             | String            | Nome completo |
| email            | String            | Único |
| cpf              | String            | Único, armazenado sem formatação |
| birthDate        | DateTime          | Data de nascimento |
| phone            | String?           | Celular |
| passwordHash     | String            | Hash bcrypt/argon2 |
| role             | UserRole (enum)   | USER, PARTNER, ANALYST, ADMIN |
| status           | UserStatus (enum) | ACTIVE, INACTIVE, BLOCKED |
| partnerId        | String?           | Relacionamento com Partner (para role PARTNER) |
| createdAt        | DateTime          | |
| updatedAt        | DateTime          | |

**Enums relacionados:**
- `UserRole`: USER | PARTNER | ANALYST | ADMIN
- `UserStatus`: ACTIVE | INACTIVE | BLOCKED

---

### 2. Verification

Uma verificação de identidade de um usuário.

| Campo             | Tipo                | Observações |
|-------------------|---------------------|-----------|
| id                | String (cuid)       | PK |
| userId            | String              | FK → User |
| documentType      | DocumentType        | RG ou CNH |
| status            | VerificationStatus  | Ver enum abaixo |
| code              | String?             | Código único "CID-XXXXXX" (só após aprovação) |
| submittedAt       | DateTime?           | Quando o usuário enviou todos os documentos |
| reviewedAt        | DateTime?           | Data da decisão |
| expiresAt         | DateTime?           | 12 meses após aprovação (decisão MVP) |
| reviewedById      | String?             | FK → User (quem aprovou/reprovou) |
| rejectionReason   | String?             | Motivo da reprovação |
| correctionReason  | String?             | Motivo da solicitação de correção |
| createdAt         | DateTime            | |
| updatedAt         | DateTime            | |

**Enum VerificationStatus:**
- PENDING
- UNDER_REVIEW
- CORRECTION_REQUESTED
- APPROVED
- REJECTED
- BLOCKED
- EXPIRED
- ABANDONED

---

### 3. Document

Representa cada imagem enviada (frente, verso, selfie).

| Campo               | Tipo           | Observações |
|---------------------|----------------|-----------|
| id                  | String         | PK |
| verificationId      | String         | FK → Verification |
| type                | DocumentType   | FRONT \| BACK \| SELFIE |
| storedFilename      | String         | Nome opaco no disco (ex: front-uuid.enc) |
| originalFilenameHash| String         | SHA256 do nome original (para auditoria) |
| mimeType            | String         | image/jpeg ou image/png |
| sizeBytes           | Int            | |
| sha256              | String         | Hash do conteúdo original |
| iv                  | String         | Vetor de inicialização (base64) |
| authTag             | String         | GCM auth tag (base64) |
| uploadedAt          | DateTime       | |

**Enum DocumentType:** FRONT | BACK | SELFIE

---

### 4. Partner

Empresa parceira que pode consultar identidades.

| Campo          | Tipo     | Observações |
|----------------|----------|-----------|
| id             | String   | PK |
| legalName      | String   | Razão social |
| tradeName      | String?  | Nome fantasia |
| cnpj           | String   | Único |
| contactName    | String   | |
| contactEmail   | String   | |
| contactPhone   | String?  | |
| status         | PartnerStatus | ACTIVE \| INACTIVE |
| createdAt      | DateTime | |
| updatedAt      | DateTime | |

---

### 5. Consultation (Histórico de Consultas)

Registro de toda consulta feita por um parceiro.

| Campo             | Tipo      | Observações |
|-------------------|-----------|-----------|
| id                | String    | PK |
| partnerId         | String    | FK → Partner |
| userId            | String?   | FK → User (se encontrado) |
| verificationId    | String?   | FK → Verification |
| queryType         | String    | "code" \| "email" \| "cpf" |
| queryValueHash    | String    | Hash do valor consultado (para auditoria) |
| resultStatus      | String    | "approved" \| "not_found" \| "under_review" \| "expired" \| "blocked" |
| createdAt         | DateTime  | |

---

### 6. AuditLog

Registro de todas as ações sensíveis (aprovações, bloqueios, acessos a documentos, etc.).

| Campo        | Tipo      | Observações |
|--------------|-----------|-----------|
| id           | String    | PK |
| actorUserId  | String?   | Quem executou a ação (pode ser null em alguns casos) |
| action       | String    | Ex: "VERIFICATION_APPROVED", "DOCUMENT_VIEWED", "PARTNER_CONSULTED" |
| entityType   | String    | "Verification", "User", "Document", etc. |
| entityId     | String    | |
| details      | Json?     | Informações adicionais (motivo, status anterior, etc.) |
| ipAddress    | String?   | |
| userAgent    | String?   | |
| createdAt    | DateTime  | |

---

### 7. VerificationHistory (Opcional mas recomendado)

Rastreia mudanças de status ao longo do tempo (útil para reenvios).

| Campo             | Tipo     | Observações |
|-------------------|----------|-----------|
| id                | String   | PK |
| verificationId    | String   | FK |
| previousStatus    | String?  | |
| newStatus         | String   | |
| changedById       | String?  | FK → User |
| reason            | String?  | |
| createdAt         | DateTime | |

---

## Relacionamentos Principais

- `User` 1 — N `Verification`
- `Verification` 1 — N `Document`
- `User` (como analista) N — `Verification` (reviewedBy)
- `Partner` 1 — N `Consultation`
- `User` (cidadão) 1 — N `Consultation` (quando encontrado)
- `Verification` 1 — N `Consultation`
- `User` (qualquer papel) 1 — N `AuditLog` (como actor)

---

## Regras Importantes de Negócio (refletidas no modelo)

- Um usuário (CPF) só pode ter uma conta ativa.
- Código (`code`) só é gerado quando `status = APPROVED`.
- `expiresAt` é preenchido na aprovação (12 meses).
- Parceiros só conseguem ver dados limitados (nunca imagens).
- Todo acesso a `Document` deve gerar entrada em `AuditLog`.

---

## Próximos Passos

Durante a **Fase 3**:
1. Criar o `prisma/schema.prisma` real com esses conceitos.
2. Definir indexes úteis (ex: busca por code, cpf, email).
3. Criar as primeiras migrations.
4. Seeds para admin + parceiros de teste.

---

*Documento de apoio ao plano de implementação — Fase 3.*