
-- Digital Ekub: Initial database schema
-- Member accounts and authentication

CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,

    role VARCHAR(20) NOT NULL DEFAULT 'member'
        CHECK (role IN ('member', 'group_leader', 'admin')),

    account_status VARCHAR(30) NOT NULL DEFAULT 'pending_verification'
        CHECK (
            account_status IN (
                'pending_verification',
                'pending_approval',
                'active',
                'rejected',
                'suspended'
            )
        ),

    verification_status VARCHAR(30) NOT NULL DEFAULT 'pending'
        CHECK (
            verification_status IN ('pending', 'verified', 'failed')
        ),

    email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    phone_verified BOOLEAN NOT NULL DEFAULT FALSE,

    reviewed_by BIGINT REFERENCES users(id),
    reviewed_at TIMESTAMPTZ,
    review_note TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_account_status ON users(account_status);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_verification_status ON users(verification_status);
