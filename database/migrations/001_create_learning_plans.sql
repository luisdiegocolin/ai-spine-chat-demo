-- ============================================================================
-- Migration 001: Create Learning Plans Table
-- ============================================================================
-- Description: Core table for storing personalized learning plan configurations
-- Date: 2025-12-31
-- Version: 1.0
-- Author: AI Spine Learning System
-- ============================================================================

-- ============================================================================
-- SECTION 1: MIGRATION (UP)
-- ============================================================================

-- Create shared trigger function for updated_at if not exists
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create learning_plans table
CREATE TABLE IF NOT EXISTS learning_plans (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Session Identification (no user FK - each session is isolated)
    session_id UUID NOT NULL,

    -- Course Configuration
    course_topic VARCHAR(500) NOT NULL,
    knowledge_level VARCHAR(20) NOT NULL
        CHECK (knowledge_level IN ('Principiante', 'Intermedio', 'Avanzado')),
    user_goals TEXT NOT NULL,
    total_duration_days INTEGER NOT NULL
        CHECK (total_duration_days > 0 AND total_duration_days <= 365),
    daily_time_available_minutes INTEGER NOT NULL
        CHECK (daily_time_available_minutes > 0 AND daily_time_available_minutes <= 1440),
    learning_style VARCHAR(50) NOT NULL DEFAULT 'Multimodal'
        CHECK (learning_style IN ('Visual', 'Auditivo', 'Lectura/Escritura', 'Práctico', 'Multimodal')),

    -- Status tracking
    status VARCHAR(20) NOT NULL DEFAULT 'active'
        CHECK (status IN ('draft', 'active', 'completed', 'archived')),

    -- Audit timestamps
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- INDEXES for learning_plans
-- ============================================================================

-- Primary query pattern: fetch by session_id
CREATE INDEX IF NOT EXISTS idx_learning_plans_session
    ON learning_plans(session_id);

-- Filter by status
CREATE INDEX IF NOT EXISTS idx_learning_plans_status
    ON learning_plans(status, created_at DESC);

-- Partial index for active plans only (most common query)
CREATE INDEX IF NOT EXISTS idx_learning_plans_active_session
    ON learning_plans(session_id, created_at DESC)
    WHERE status = 'active';

-- Date range queries for cleanup
CREATE INDEX IF NOT EXISTS idx_learning_plans_created
    ON learning_plans(created_at DESC);

-- ============================================================================
-- CONSTRAINTS
-- ============================================================================

-- Only one active plan per session at a time
CREATE UNIQUE INDEX IF NOT EXISTS idx_learning_plans_unique_active_session
    ON learning_plans(session_id)
    WHERE status = 'active';

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Auto-update updated_at on row modification
DROP TRIGGER IF EXISTS learning_plans_updated_at_trigger ON learning_plans;
CREATE TRIGGER learning_plans_updated_at_trigger
    BEFORE UPDATE ON learning_plans
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- COMMENTS for Documentation
-- ============================================================================

COMMENT ON TABLE learning_plans IS
    'Personalized learning plan configurations. Each session_id represents an isolated user conversation.';

COMMENT ON COLUMN learning_plans.session_id IS
    'UUID from frontend localStorage. Each new chat session = new isolated user.';

COMMENT ON COLUMN learning_plans.knowledge_level IS
    'User''s current knowledge level. Valid values: Principiante, Intermedio, Avanzado';

COMMENT ON COLUMN learning_plans.learning_style IS
    'Preferred learning method. Defaults to Multimodal if not specified.';

COMMENT ON COLUMN learning_plans.status IS
    'Plan lifecycle status. Active = currently in use, Draft = being created, Completed = finished, Archived = old/inactive';

COMMENT ON COLUMN learning_plans.total_duration_days IS
    'Total days for the learning plan (max 365 days = 1 year)';

COMMENT ON COLUMN learning_plans.daily_time_available_minutes IS
    'Daily study time in minutes (max 1440 = 24 hours)';

-- ============================================================================
-- SECTION 2: ROLLBACK (DOWN)
-- ============================================================================

/*
-- ROLLBACK INSTRUCTIONS
-- To undo this migration, run the following commands:

-- Drop triggers
DROP TRIGGER IF EXISTS learning_plans_updated_at_trigger ON learning_plans;

-- Drop indexes
DROP INDEX IF EXISTS idx_learning_plans_unique_active_session;
DROP INDEX IF EXISTS idx_learning_plans_created;
DROP INDEX IF EXISTS idx_learning_plans_active_session;
DROP INDEX IF EXISTS idx_learning_plans_status;
DROP INDEX IF EXISTS idx_learning_plans_session;

-- Drop table
DROP TABLE IF EXISTS learning_plans CASCADE;

-- Note: The shared update_updated_at_column() function is intentionally NOT dropped
-- as it may be used by other tables (modules, resources)

-- ROLLBACK COMPLETE
*/

-- ============================================================================
-- SECTION 3: VERIFICATION & TESTS
-- ============================================================================

/*
-- TEST SUITE for learning_plans table
-- Run these queries to verify the migration was successful

-- ===== TEST 1: Table Existence =====
SELECT
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name = 'learning_plans';
-- Expected: 1 row with table_name = 'learning_plans'


-- ===== TEST 2: Column Structure =====
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'learning_plans'
ORDER BY ordinal_position;
-- Expected: 10 columns (id, session_id, course_topic, knowledge_level, user_goals,
--           total_duration_days, daily_time_available_minutes, learning_style, status,
--           created_at, updated_at)


-- ===== TEST 3: Indexes =====
SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'learning_plans'
ORDER BY indexname;
-- Expected: 6 indexes (1 PK + 5 custom indexes)


-- ===== TEST 4: Constraints =====
SELECT
    conname AS constraint_name,
    contype AS constraint_type,
    pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid = 'learning_plans'::regclass
ORDER BY conname;
-- Expected: Multiple CHECK constraints + PRIMARY KEY + UNIQUE constraint


-- ===== TEST 5: Triggers =====
SELECT
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'learning_plans';
-- Expected: 1 trigger (learning_plans_updated_at_trigger)


-- ===== TEST 6: Insert Valid Data =====
INSERT INTO learning_plans (
    session_id,
    course_topic,
    knowledge_level,
    user_goals,
    total_duration_days,
    daily_time_available_minutes,
    learning_style,
    status
) VALUES (
    gen_random_uuid(),
    'Python para Data Science',
    'Principiante',
    'Conseguir empleo junior como Data Analyst',
    90,
    60,
    'Práctico',
    'active'
);
-- Expected: INSERT successful


-- ===== TEST 7: Constraint Validation - Invalid knowledge_level =====
DO $$
BEGIN
    INSERT INTO learning_plans (
        session_id,
        course_topic,
        knowledge_level,
        user_goals,
        total_duration_days,
        daily_time_available_minutes
    ) VALUES (
        gen_random_uuid(),
        'Test Course',
        'Expert', -- INVALID: not in CHECK constraint
        'Test goals',
        30,
        45
    );
    RAISE EXCEPTION 'TEST FAILED: Invalid knowledge_level was accepted';
EXCEPTION
    WHEN check_violation THEN
        RAISE NOTICE 'TEST PASSED: Invalid knowledge_level correctly rejected';
END $$;


-- ===== TEST 8: Constraint Validation - Invalid duration =====
DO $$
BEGIN
    INSERT INTO learning_plans (
        session_id,
        course_topic,
        knowledge_level,
        user_goals,
        total_duration_days,
        daily_time_available_minutes
    ) VALUES (
        gen_random_uuid(),
        'Test Course',
        'Intermedio',
        'Test goals',
        0, -- INVALID: must be > 0
        45
    );
    RAISE EXCEPTION 'TEST FAILED: Invalid duration was accepted';
EXCEPTION
    WHEN check_violation THEN
        RAISE NOTICE 'TEST PASSED: Invalid duration correctly rejected';
END $$;


-- ===== TEST 9: UNIQUE Constraint - Only one active plan per session =====
DO $$
DECLARE
    test_session_id UUID := gen_random_uuid();
BEGIN
    -- Insert first active plan
    INSERT INTO learning_plans (
        session_id, course_topic, knowledge_level, user_goals,
        total_duration_days, daily_time_available_minutes, status
    ) VALUES (
        test_session_id, 'Course 1', 'Principiante', 'Goal 1', 30, 60, 'active'
    );

    -- Try to insert second active plan for same session (should fail)
    INSERT INTO learning_plans (
        session_id, course_topic, knowledge_level, user_goals,
        total_duration_days, daily_time_available_minutes, status
    ) VALUES (
        test_session_id, 'Course 2', 'Intermedio', 'Goal 2', 45, 90, 'active'
    );

    RAISE EXCEPTION 'TEST FAILED: Duplicate active plan was accepted';
EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'TEST PASSED: Duplicate active plan correctly rejected';
END $$;


-- ===== TEST 10: Trigger - updated_at auto-update =====
DO $$
DECLARE
    test_plan_id UUID;
    original_updated_at TIMESTAMP WITH TIME ZONE;
    new_updated_at TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Insert test record
    INSERT INTO learning_plans (
        session_id, course_topic, knowledge_level, user_goals,
        total_duration_days, daily_time_available_minutes
    ) VALUES (
        gen_random_uuid(), 'Trigger Test', 'Avanzado', 'Test goals', 30, 45
    ) RETURNING id, updated_at INTO test_plan_id, original_updated_at;

    -- Wait a moment
    PERFORM pg_sleep(0.1);

    -- Update the record
    UPDATE learning_plans
    SET course_topic = 'Trigger Test Updated'
    WHERE id = test_plan_id
    RETURNING updated_at INTO new_updated_at;

    -- Check if updated_at changed
    IF new_updated_at > original_updated_at THEN
        RAISE NOTICE 'TEST PASSED: updated_at trigger working correctly';
    ELSE
        RAISE EXCEPTION 'TEST FAILED: updated_at was not updated';
    END IF;

    -- Cleanup
    DELETE FROM learning_plans WHERE id = test_plan_id;
END $$;


-- ===== TEST 11: Cleanup test data =====
DELETE FROM learning_plans
WHERE course_topic IN ('Python para Data Science', 'Test Course', 'Trigger Test', 'Course 1', 'Course 2');
-- Expected: All test records deleted


-- ===== TEST 12: Final Count =====
SELECT COUNT(*) as remaining_records FROM learning_plans;
-- Expected: 0 (all test data cleaned up)


-- ===== ALL TESTS COMPLETE =====
SELECT 'Migration 001 - All tests passed successfully!' AS test_result;
*/
