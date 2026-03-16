-- ============================================================
-- Supabase RPC functions for atomic operations
-- Run this in the Supabase SQL Editor (Dashboard > SQL Editor)
-- ============================================================

-- 1. Atomic increment of execution counters (fixes race condition)
CREATE OR REPLACE FUNCTION increment_execution_counters(
    p_execution_id TEXT,
    p_error_count INT DEFAULT 0,
    p_stall_count INT DEFAULT 0
)
RETURNS VOID AS $$
BEGIN
    UPDATE routine_executions
    SET completed_steps = completed_steps + 1,
        error_count = error_count + p_error_count,
        stall_count = stall_count + p_stall_count
    WHERE id = p_execution_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Atomic set primary emergency contact (fixes zero-primary state)
CREATE OR REPLACE FUNCTION set_primary_emergency_contact(
    p_user_id TEXT,
    p_contact_id TEXT
)
RETURNS VOID AS $$
BEGIN
    -- Unset all primaries for this user
    UPDATE emergency_contacts
    SET is_primary = FALSE
    WHERE user_id = p_user_id;

    -- Set the chosen one
    UPDATE emergency_contacts
    SET is_primary = TRUE
    WHERE id = p_contact_id AND user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
