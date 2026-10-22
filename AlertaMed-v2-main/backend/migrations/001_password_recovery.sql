
-- AlertaMed
-- Migração 001: Recuperação de senha
-- Pré-requisito: tabela users já criada.

BEGIN;

-- Controle de invalidação de tokens JWT.
ALTER TABLE users
ADD COLUMN IF NOT EXISTS
tokens_valid_after BIGINT NOT NULL DEFAULT 0;

-- Armazenamento dos códigos de recuperação.
CREATE TABLE IF NOT EXISTS password_reset_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL UNIQUE
        REFERENCES users(id) ON DELETE CASCADE,

    code_hash TEXT NOT NULL,

    expires_at TIMESTAMPTZ NOT NULL,

    attempts INTEGER NOT NULL DEFAULT 0
        CHECK (attempts >= 0),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMIT;
