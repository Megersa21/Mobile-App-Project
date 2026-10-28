
-- Sagni Digital Ekub
-- Migration 002: Weekly Contributions, Payments and Penalties
-- STATUS: DRAFT. DO NOT EXECUTE WITHOUT EXPLICIT APPROVAL.
-- Depends on Migration 001.
-- Does not modify or recreate users.
--
-- IMPORTANT:
-- Cross-row financial invariants require transactional backend
-- enforcement and further database-level safeguards before production.

BEGIN;

-- 1. Contribution rounds
CREATE TABLE contribution_rounds (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cycle_id BIGINT NOT NULL
        REFERENCES rotation_cycles(id) ON DELETE RESTRICT,
    round_number INTEGER NOT NULL CHECK (round_number > 0),
    due_date DATE NOT NULL,
    contribution_amount NUMERIC(12, 2) NOT NULL
        CHECK (contribution_amount > 0),
    status VARCHAR(20) NOT NULL DEFAULT 'scheduled'
        CHECK (status IN ('scheduled', 'open', 'closed', 'cancelled')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (cycle_id, round_number),
    UNIQUE (id, cycle_id)
);

CREATE INDEX idx_contribution_rounds_due_date
    ON contribution_rounds (due_date);

CREATE INDEX idx_contribution_rounds_cycle_status
    ON contribution_rounds (cycle_id, status);

-- 2. Contribution obligations
CREATE TABLE contribution_obligations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    round_id BIGINT NOT NULL,
    cycle_id BIGINT NOT NULL,
    cycle_member_id BIGINT NOT NULL,
    amount_due NUMERIC(12, 2) NOT NULL CHECK (amount_due > 0),
    amount_paid NUMERIC(12, 2) NOT NULL DEFAULT 0
        CHECK (amount_paid >= 0 AND amount_paid <= amount_due),
    due_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'unpaid'
        CHECK (status IN ('unpaid', 'paid', 'waived')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_obligation_round_cycle
        FOREIGN KEY (round_id, cycle_id)
        REFERENCES contribution_rounds (id, cycle_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_obligation_member_cycle
        FOREIGN KEY (cycle_member_id, cycle_id)
        REFERENCES rotation_cycle_members (id, cycle_id)
        ON DELETE RESTRICT,

    UNIQUE (round_id, cycle_member_id),
    UNIQUE (id, cycle_member_id),

    CHECK (
        (status = 'unpaid' AND amount_paid = 0)
        OR (status = 'paid' AND amount_paid = amount_due)
        OR (status = 'waived' AND amount_paid = 0)
    )
);

CREATE INDEX idx_obligations_member_status_due
    ON contribution_obligations (cycle_member_id, status, due_date);

CREATE INDEX idx_obligations_round
    ON contribution_obligations (round_id);

-- 3. Contribution payments
CREATE TABLE contribution_payments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cycle_member_id BIGINT NOT NULL
        REFERENCES rotation_cycle_members(id) ON DELETE RESTRICT,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    currency CHAR(3) NOT NULL DEFAULT 'ETB' CHECK (currency = 'ETB'),
    provider_reference VARCHAR(255) UNIQUE,
    idempotency_key VARCHAR(255) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'confirmed', 'failed', 'reversed')),
    confirmed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (id, cycle_member_id),

    CONSTRAINT chk_payment_confirmation_timestamp
        CHECK (
            (status IN ('confirmed', 'reversed') AND confirmed_at IS NOT NULL)
            OR (status IN ('pending', 'failed') AND confirmed_at IS NULL)
        )
);

CREATE INDEX idx_contribution_payments_member_status
    ON contribution_payments (cycle_member_id, status);

CREATE INDEX idx_contribution_payments_confirmed_at
    ON contribution_payments (confirmed_at)
    WHERE status IN ('confirmed', 'reversed');

-- 4. Contribution payment allocations
CREATE TABLE contribution_payment_allocations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    payment_id BIGINT NOT NULL,
    cycle_member_id BIGINT NOT NULL,
    obligation_id BIGINT NOT NULL,
    amount_allocated NUMERIC(12, 2) NOT NULL
        CHECK (amount_allocated > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_contribution_allocation_payment
        FOREIGN KEY (payment_id, cycle_member_id)
        REFERENCES contribution_payments (id, cycle_member_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_contribution_allocation_obligation
        FOREIGN KEY (obligation_id, cycle_member_id)
        REFERENCES contribution_obligations (id, cycle_member_id)
        ON DELETE RESTRICT,

    UNIQUE (payment_id, obligation_id)
);

CREATE INDEX idx_contribution_allocations_obligation
    ON contribution_payment_allocations (obligation_id);

CREATE INDEX idx_contribution_allocations_payment
    ON contribution_payment_allocations (payment_id);

-- 5. Late payment penalties
CREATE TABLE late_payment_penalties (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    obligation_id BIGINT NOT NULL UNIQUE
        REFERENCES contribution_obligations(id) ON DELETE RESTRICT,
    penalty_rate NUMERIC(5, 2) NOT NULL DEFAULT 10.00
        CHECK (penalty_rate = 10.00),
    calculation_base NUMERIC(12, 2) NOT NULL
        CHECK (calculation_base > 0),
    penalty_amount NUMERIC(12, 2) NOT NULL
        CHECK (penalty_amount >= 0),
    paid_amount NUMERIC(12, 2) NOT NULL DEFAULT 0
        CHECK (paid_amount >= 0 AND paid_amount <= penalty_amount),
    status VARCHAR(20) NOT NULL DEFAULT 'assessed'
        CHECK (status IN ('assessed', 'paid', 'waived')),
    policy_version VARCHAR(50) NOT NULL DEFAULT '10-percent-v1',
    notes TEXT,
    assessed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (id, obligation_id),

    CHECK (
        (status = 'assessed' AND paid_amount = 0)
        OR (status = 'paid' AND paid_amount = penalty_amount)
        OR (status = 'waived' AND paid_amount = 0)
    )
);

CREATE INDEX idx_late_penalties_status
    ON late_payment_penalties (status);

-- 6. Penalty payment allocations
CREATE TABLE penalty_payment_allocations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    payment_id BIGINT NOT NULL,
    cycle_member_id BIGINT NOT NULL,
    penalty_id BIGINT NOT NULL,
    obligation_id BIGINT NOT NULL,
    amount_allocated NUMERIC(12, 2) NOT NULL
        CHECK (amount_allocated > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_penalty_allocation_payment
        FOREIGN KEY (payment_id, cycle_member_id)
        REFERENCES contribution_payments (id, cycle_member_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_penalty_allocation_penalty
        FOREIGN KEY (penalty_id, obligation_id)
        REFERENCES late_payment_penalties (id, obligation_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_penalty_allocation_obligation_member
        FOREIGN KEY (obligation_id, cycle_member_id)
        REFERENCES contribution_obligations (id, cycle_member_id)
        ON DELETE RESTRICT,

    UNIQUE (payment_id, penalty_id)
);

CREATE INDEX idx_penalty_allocations_penalty
    ON penalty_payment_allocations (penalty_id);

CREATE INDEX idx_penalty_allocations_payment
    ON penalty_payment_allocations (payment_id);

-- 7. Payment reversals
CREATE TABLE payment_reversals (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    payment_id BIGINT NOT NULL UNIQUE
        REFERENCES contribution_payments(id) ON DELETE RESTRICT,
    reversal_reference VARCHAR(255) NOT NULL UNIQUE,
    reason TEXT NOT NULL CHECK (LENGTH(TRIM(reason)) > 0),
    reversed_by_user_id BIGINT NOT NULL
        REFERENCES users(id) ON DELETE RESTRICT,
    reversed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payment_reversals_reversed_at
    ON payment_reversals (reversed_at);

-- 8. Reversed contribution allocation details
CREATE TABLE payment_reversal_contribution_allocations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    reversal_id BIGINT NOT NULL
        REFERENCES payment_reversals(id) ON DELETE RESTRICT,
    allocation_id BIGINT NOT NULL
        REFERENCES contribution_payment_allocations(id) ON DELETE RESTRICT,
    amount_reversed NUMERIC(12, 2) NOT NULL
        CHECK (amount_reversed > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (reversal_id, allocation_id)
);

CREATE INDEX idx_reversal_contribution_allocation
    ON payment_reversal_contribution_allocations (allocation_id);

-- 9. Reversed penalty allocation details
CREATE TABLE payment_reversal_penalty_allocations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    reversal_id BIGINT NOT NULL
        REFERENCES payment_reversals(id) ON DELETE RESTRICT,
    allocation_id BIGINT NOT NULL
        REFERENCES penalty_payment_allocations(id) ON DELETE RESTRICT,
    amount_reversed NUMERIC(12, 2) NOT NULL
        CHECK (amount_reversed > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (reversal_id, allocation_id)
);

CREATE INDEX idx_reversal_penalty_allocation
    ON payment_reversal_penalty_allocations (allocation_id);

-- 10. Penalty waiver audit
CREATE TABLE penalty_waiver_audits (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    penalty_id BIGINT NOT NULL UNIQUE
        REFERENCES late_payment_penalties(id) ON DELETE RESTRICT,
    waived_by_user_id BIGINT NOT NULL
        REFERENCES users(id) ON DELETE RESTRICT,
    reason TEXT NOT NULL CHECK (LENGTH(TRIM(reason)) > 0),
    waived_amount NUMERIC(12, 2) NOT NULL CHECK (waived_amount > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_penalty_waiver_admin
    ON penalty_waiver_audits (waived_by_user_id);

-- 11. Financial correction audit
CREATE TABLE financial_correction_audits (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    payment_id BIGINT
        REFERENCES contribution_payments(id) ON DELETE RESTRICT,
    correction_type VARCHAR(50) NOT NULL,
    reason TEXT NOT NULL CHECK (LENGTH(TRIM(reason)) > 0),
    before_data JSONB NOT NULL,
    after_data JSONB NOT NULL,
    corrected_by_user_id BIGINT NOT NULL
        REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_financial_corrections_payment
    ON financial_correction_audits (payment_id);

CREATE INDEX idx_financial_corrections_admin
    ON financial_correction_audits (corrected_by_user_id);

COMMIT;
