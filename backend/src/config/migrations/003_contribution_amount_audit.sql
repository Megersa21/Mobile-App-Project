
-- Sagni Digital Ekub
-- Migration 003: Contribution Amount Change Audit
--
-- STATUS: DRAFT ONLY. DO NOT EXECUTE WITHOUT APPROVAL.
-- Depends on Migration 001 and Migration 002 being reviewed
-- and applied in the correct order.

BEGIN;

CREATE TABLE contribution_amount_change_audits (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    ekub_id BIGINT NOT NULL
        REFERENCES ekub_settings(id) ON DELETE RESTRICT,

    previous_amount NUMERIC(12, 2) NOT NULL
        CHECK (previous_amount > 0),

    new_amount NUMERIC(12, 2) NOT NULL
        CHECK (new_amount > 0),

    effective_cycle_id BIGINT NOT NULL,

    effective_round_number INTEGER NOT NULL
        CHECK (effective_round_number > 0),

    changed_by_user_id BIGINT NOT NULL
        REFERENCES users(id) ON DELETE RESTRICT,

    reason TEXT NOT NULL
        CHECK (LENGTH(TRIM(reason)) > 0),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_amount_audit_cycle
    FOREIGN KEY (effective_cycle_id, ekub_id)
    REFERENCES rotation_cycles (id, ekub_id)
    ON DELETE RESTRICT,

CONSTRAINT fk_amount_audit_effective_round
    FOREIGN KEY (effective_cycle_id, effective_round_number)
    REFERENCES contribution_rounds (cycle_id, round_number)
    ON DELETE RESTRICT,

    CONSTRAINT chk_amount_actually_changed
        CHECK (previous_amount <> new_amount)
);

CREATE INDEX idx_amount_change_audits_ekub_date
    ON contribution_amount_change_audits (ekub_id, created_at DESC);

CREATE INDEX idx_amount_change_audits_effective_round
    ON contribution_amount_change_audits
        (effective_cycle_id, effective_round_number);

CREATE INDEX idx_amount_change_audits_admin
    ON contribution_amount_change_audits (changed_by_user_id);

COMMIT;
