-- ============================================================================
-- Migration 002: Create Course Modules Table
-- ============================================================================
-- Description: Modules belonging to a learning plan (ordered sequence)
-- Date: 2025-12-31
-- Version: 1.0
-- Author: AI Spine Learning System
-- Dependencies: Requires migration 001 (learning_plans table)
-- ============================================================================

-- ============================================================================
-- SECTION 1: MIGRATION (UP)
-- ============================================================================

-- Create course_modules table
CREATE TABLE IF NOT EXISTS course_modules (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Foreign Key to learning plan (CASCADE delete - modules are owned by plan)
    learning_plan_id UUID NOT NULL
        REFERENCES learning_plans(id) ON DELETE CASCADE,

    -- Module Sequencing
    module_number INTEGER NOT NULL
        CHECK (module_number > 0 AND module_number <= 1000),

    -- Module Content
    title VARCHAR(300) NOT NULL,
    description TEXT,
    estimated_duration_minutes INTEGER
        CHECK (estimated_duration_minutes IS NULL OR estimated_duration_minutes > 0),

    -- Audit timestamps
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- Ensure unique sequential numbering per plan
    UNIQUE(learning_plan_id, module_number)
);

-- ============================================================================
-- INDEXES for course_modules
-- ============================================================================

-- Primary query: fetch all modules for a plan, ordered by number
CREATE INDEX IF NOT EXISTS idx_course_modules_plan_ordered
    ON course_modules(learning_plan_id, module_number ASC);

-- Lookup by plan (for COUNT queries, existence checks)
CREATE INDEX IF NOT EXISTS idx_course_modules_plan
    ON course_modules(learning_plan_id);

-- Date-based queries (for analytics, recent modules)
CREATE INDEX IF NOT EXISTS idx_course_modules_created
    ON course_modules(created_at DESC);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Auto-update updated_at on row modification
DROP TRIGGER IF EXISTS course_modules_updated_at_trigger ON course_modules;
CREATE TRIGGER course_modules_updated_at_trigger
    BEFORE UPDATE ON course_modules
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- COMMENTS for Documentation
-- ============================================================================

COMMENT ON TABLE course_modules IS
    'Individual learning modules within a plan. Each module represents one unit of study with associated resources (PDF, video, quiz).';

COMMENT ON COLUMN course_modules.learning_plan_id IS
    'References the parent learning plan. CASCADE delete ensures modules are removed when plan is deleted.';

COMMENT ON COLUMN course_modules.module_number IS
    'Sequential order number (1, 2, 3...). Must be unique within a learning plan. Max 1000 modules per plan.';

COMMENT ON COLUMN course_modules.title IS
    'Module title/name (e.g., "Introduction to Python Basics")';

COMMENT ON COLUMN course_modules.description IS
    'Detailed module description, learning objectives, or overview';

COMMENT ON COLUMN course_modules.estimated_duration_minutes IS
    'Estimated time to complete this module (nullable if unknown). Used for progress planning.';

-- ============================================================================
-- SECTION 2: ROLLBACK (DOWN)
-- ============================================================================

/*
-- ROLLBACK INSTRUCTIONS
-- To undo this migration, run the following commands:

-- Drop triggers
DROP TRIGGER IF EXISTS course_modules_updated_at_trigger ON course_modules;

-- Drop indexes
DROP INDEX IF EXISTS idx_course_modules_created;
DROP INDEX IF EXISTS idx_course_modules_plan;
DROP INDEX IF EXISTS idx_course_modules_plan_ordered;

-- Drop table (CASCADE will drop dependent module_resources if exists)
DROP TABLE IF EXISTS course_modules CASCADE;

-- ROLLBACK COMPLETE
*/

-- ============================================================================
-- SECTION 3: VERIFICATION & TESTS
-- ============================================================================

/*
-- TEST SUITE for course_modules table
-- Run these queries to verify the migration was successful

-- ===== TEST 1: Table Existence =====
SELECT
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name = 'course_modules';
-- Expected: 1 row with table_name = 'course_modules'


-- ===== TEST 2: Column Structure =====
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'course_modules'
ORDER BY ordinal_position;
-- Expected: 7 columns (id, learning_plan_id, module_number, title,
--           description, estimated_duration_minutes, created_at, updated_at)


-- ===== TEST 3: Foreign Key Constraint =====
SELECT
    conname AS constraint_name,
    pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid = 'course_modules'::regclass
  AND contype = 'f';
-- Expected: 1 FK constraint to learning_plans with ON DELETE CASCADE


-- ===== TEST 4: Indexes =====
SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'course_modules'
ORDER BY indexname;
-- Expected: 4 indexes (1 PK + 1 unique constraint + 2 custom indexes)


-- ===== TEST 5: Triggers =====
SELECT
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers
WHERE event_object_table = 'course_modules';
-- Expected: 1 trigger (course_modules_updated_at_trigger)


-- ===== TEST 6: Insert Valid Modules =====
DO $$
DECLARE
    test_plan_id UUID;
BEGIN
    -- Create test learning plan
    INSERT INTO learning_plans (
        session_id, course_topic, knowledge_level, user_goals,
        total_duration_days, daily_time_available_minutes
    ) VALUES (
        gen_random_uuid(), 'Python Testing', 'Principiante', 'Learn testing', 30, 60
    ) RETURNING id INTO test_plan_id;

    -- Insert modules in sequence
    INSERT INTO course_modules (learning_plan_id, module_number, title, description, estimated_duration_minutes)
    VALUES
        (test_plan_id, 1, 'Módulo 1: Introducción', 'Conceptos básicos', 120),
        (test_plan_id, 2, 'Módulo 2: Variables', 'Tipos de datos', 90),
        (test_plan_id, 3, 'Módulo 3: Funciones', 'Definir y usar funciones', 150);

    RAISE NOTICE 'TEST PASSED: 3 modules inserted successfully';
END $$;


-- ===== TEST 7: UNIQUE Constraint - Duplicate module_number =====
DO $$
DECLARE
    test_plan_id UUID;
BEGIN
    -- Get existing test plan
    SELECT id INTO test_plan_id FROM learning_plans WHERE course_topic = 'Python Testing';

    -- Try to insert duplicate module_number
    INSERT INTO course_modules (learning_plan_id, module_number, title)
    VALUES (test_plan_id, 1, 'Duplicate Module');

    RAISE EXCEPTION 'TEST FAILED: Duplicate module_number was accepted';
EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'TEST PASSED: Duplicate module_number correctly rejected';
END $$;


-- ===== TEST 8: Constraint Validation - Invalid module_number =====
DO $$
DECLARE
    test_plan_id UUID;
BEGIN
    SELECT id INTO test_plan_id FROM learning_plans WHERE course_topic = 'Python Testing';

    -- Try invalid module_number (0)
    INSERT INTO course_modules (learning_plan_id, module_number, title)
    VALUES (test_plan_id, 0, 'Invalid Module');

    RAISE EXCEPTION 'TEST FAILED: Invalid module_number (0) was accepted';
EXCEPTION
    WHEN check_violation THEN
        RAISE NOTICE 'TEST PASSED: Invalid module_number correctly rejected';
END $$;


-- ===== TEST 9: Constraint Validation - Negative duration =====
DO $$
DECLARE
    test_plan_id UUID;
BEGIN
    SELECT id INTO test_plan_id FROM learning_plans WHERE course_topic = 'Python Testing';

    INSERT INTO course_modules (learning_plan_id, module_number, title, estimated_duration_minutes)
    VALUES (test_plan_id, 10, 'Test Module', -5);

    RAISE EXCEPTION 'TEST FAILED: Negative duration was accepted';
EXCEPTION
    WHEN check_violation THEN
        RAISE NOTICE 'TEST PASSED: Negative duration correctly rejected';
END $$;


-- ===== TEST 10: CASCADE Delete - Modules deleted when plan deleted =====
DO $$
DECLARE
    test_plan_id UUID;
    modules_before INTEGER;
    modules_after INTEGER;
BEGIN
    -- Count modules before delete
    SELECT id INTO test_plan_id FROM learning_plans WHERE course_topic = 'Python Testing';
    SELECT COUNT(*) INTO modules_before FROM course_modules WHERE learning_plan_id = test_plan_id;

    -- Delete the plan (should CASCADE to modules)
    DELETE FROM learning_plans WHERE id = test_plan_id;

    -- Count modules after delete
    SELECT COUNT(*) INTO modules_after FROM course_modules WHERE learning_plan_id = test_plan_id;

    IF modules_before > 0 AND modules_after = 0 THEN
        RAISE NOTICE 'TEST PASSED: CASCADE delete removed % modules', modules_before;
    ELSE
        RAISE EXCEPTION 'TEST FAILED: CASCADE delete did not work (before: %, after: %)',
            modules_before, modules_after;
    END IF;
END $$;


-- ===== TEST 11: Query Performance - Ordered fetch =====
DO $$
DECLARE
    test_plan_id UUID;
    prev_number INTEGER := 0;
    current_number INTEGER;
    module_record RECORD;
BEGIN
    -- Create test plan with modules
    INSERT INTO learning_plans (
        session_id, course_topic, knowledge_level, user_goals,
        total_duration_days, daily_time_available_minutes
    ) VALUES (
        gen_random_uuid(), 'Order Test', 'Intermedio', 'Test ordering', 30, 60
    ) RETURNING id INTO test_plan_id;

    -- Insert modules out of order
    INSERT INTO course_modules (learning_plan_id, module_number, title)
    VALUES
        (test_plan_id, 5, 'Module 5'),
        (test_plan_id, 1, 'Module 1'),
        (test_plan_id, 3, 'Module 3'),
        (test_plan_id, 2, 'Module 2'),
        (test_plan_id, 4, 'Module 4');

    -- Verify they come back ordered
    FOR module_record IN
        SELECT module_number FROM course_modules
        WHERE learning_plan_id = test_plan_id
        ORDER BY module_number ASC
    LOOP
        current_number := module_record.module_number;
        IF current_number <= prev_number THEN
            RAISE EXCEPTION 'TEST FAILED: Modules not in ascending order';
        END IF;
        prev_number := current_number;
    END LOOP;

    RAISE NOTICE 'TEST PASSED: Modules correctly ordered (1-5)';

    -- Cleanup
    DELETE FROM learning_plans WHERE id = test_plan_id;
END $$;


-- ===== TEST 12: Trigger - updated_at auto-update =====
DO $$
DECLARE
    test_plan_id UUID;
    test_module_id UUID;
    original_updated_at TIMESTAMP WITH TIME ZONE;
    new_updated_at TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Create test data
    INSERT INTO learning_plans (
        session_id, course_topic, knowledge_level, user_goals,
        total_duration_days, daily_time_available_minutes
    ) VALUES (
        gen_random_uuid(), 'Trigger Test', 'Avanzado', 'Test triggers', 30, 60
    ) RETURNING id INTO test_plan_id;

    INSERT INTO course_modules (learning_plan_id, module_number, title)
    VALUES (test_plan_id, 1, 'Original Title')
    RETURNING id, updated_at INTO test_module_id, original_updated_at;

    -- Wait
    PERFORM pg_sleep(0.1);

    -- Update
    UPDATE course_modules
    SET title = 'Updated Title'
    WHERE id = test_module_id
    RETURNING updated_at INTO new_updated_at;

    -- Verify
    IF new_updated_at > original_updated_at THEN
        RAISE NOTICE 'TEST PASSED: updated_at trigger working';
    ELSE
        RAISE EXCEPTION 'TEST FAILED: updated_at not updated';
    END IF;

    -- Cleanup
    DELETE FROM learning_plans WHERE id = test_plan_id;
END $$;


-- ===== TEST 13: Final Count =====
SELECT COUNT(*) as remaining_records FROM course_modules;
-- Expected: 0 (all test data cleaned up)


-- ===== ALL TESTS COMPLETE =====
SELECT 'Migration 002 - All tests passed successfully!' AS test_result;
*/
