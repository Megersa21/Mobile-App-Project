
-- Digital Ekub
-- Migration 001: Central Ekub foundation
-- STATUS: DRAFT ONLY. DO NOT EXECUTE WITHOUT APPROVAL.
-- Does not recreate or modify the existing users table.

BEGIN;

-- 1. Central Ekub configuration.
CREATE TABLE ekub_settings (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'ETB'
        CHECK (currency = 'ETB'),
    contribution_frequency VARCHAR(20) NOT NULL DEFAULT 'weekly'
        CHECK (contribution_frequency = 'weekly'),
    contribution_amount NUMERIC(12, 2) NOT NULL
        CHECK (contribution_amount > 0),
    status VARCHAR(20) NOT NULL DEFAULT 'setup'
        CHECK (status IN ('setup', 'active', 'paused', 'closed')),
    created_by BIGINT REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Exactly one central Ekub configuration.
CREATE UNIQUE INDEX uq_single_central_ekub
    ON ekub_settings ((TRUE));


-- 2. Membership.
CREATE TABLE ekub_memberships (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (
            status IN (
                'pending', 'active', 'suspended',
                'withdrawn', 'completed'
            )
        ),
    joined_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (
        ended_at IS NULL
        OR joined_at IS NULL
        OR ended_at >= joined_at
    ),
    UNIQUE (user_id)
);


-- 3. Rotation cycles.
CREATE TABLE rotation_cycles (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ekub_id BIGINT NOT NULL
        REFERENCES ekub_settings(id) ON DELETE RESTRICT,
    cycle_number INTEGER NOT NULL CHECK (cycle_number > 0),
    status VARCHAR(20) NOT NULL DEFAULT 'draft'
        CHECK (
            status IN (
                'draft', 'active', 'paused',
                'completed', 'cancelled'
            )
        ),
    start_date DATE NOT NULL,
    end_date DATE,
    created_by BIGINT REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (ekub_id, cycle_number),
    UNIQUE (id, ekub_id),
    CHECK (end_date IS NULL OR end_date >= start_date)
);


-- 4. Cycle members and payout rotation.
CREATE TABLE rotation_cycle_members (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    cycle_id BIGINT NOT NULL
        REFERENCES rotation_cycles(id) ON DELETE RESTRICT,

    membership_id BIGINT NOT NULL
        REFERENCES ekub_memberships(id) ON DELETE RESTRICT,

    turn_number INTEGER NOT NULL CHECK (turn_number > 0),

    status VARCHAR(20) NOT NULL DEFAULT 'scheduled'
        CHECK (
            status IN (
                'scheduled', 'eligible', 'paid',
                'deferred', 'withdrawn'
            )
        ),

    payout_received_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (cycle_id, membership_id),
    UNIQUE (cycle_id, turn_number),

    -- Supports composite foreign keys in Migration 002.
    UNIQUE (id, cycle_id)
);

COMMIT;
