-- ============================================================================
-- Migration 003: Create Module Resources Table
-- ============================================================================
-- Description: Resources (PDF, video, quiz) for each course module
-- Date: 2025-12-31
-- Version: 1.0
-- Author: AI Spine Learning System
-- Dependencies: Requires migration 002 (course_modules table)
-- ============================================================================

-- ============================================================================
-- SECTION 1: MIGRATION (UP)
-- ============================================================================

-- Create module_resources table
CREATE TABLE IF NOT EXISTS module_resources (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Foreign Key to module (CASCADE delete - resources are owned by module)
    module_id UUID NOT NULL
        REFERENCES course_modules(id) ON DELETE CASCADE,

    -- Resource Type (exactly 1 of each type per module)
    resource_type VARCHAR(20) NOT NULL
        CHECK (resource_type IN ('pdf', 'video', 'quiz')),

    -- Resource Data
    resource_url TEXT NOT NULL,
    title VARCHAR(300) NOT NULL,

    -- Flexible metadata storage (examples below)
    -- For PDF: {"pages": 10, "file_size_mb": 2.5}
    -- For video: {"duration_minutes": 15, "platform": "youtube", "thumbnail_url": "..."}
    -- For quiz: {"questions_count": 10, "passing_score": 70, "time_limit_minutes": 20}
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Audit timestamps
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- Ensure each module has at most 1 resource of each type
    UNIQUE(module_id, resource_type)
);

-- ============================================================================
-- INDEXES for module_resources
-- ============================================================================

-- Primary query: fetch all resources for a module
CREATE INDEX IF NOT EXISTS idx_module_resources_module
    ON module_resources(module_id);

-- Filter by resource type (e.g., find all PDFs)
CREATE INDEX IF NOT EXISTS idx_module_resources_type
    ON module_resources(resource_type);

-- Combined index for common query pattern
CREATE INDEX IF NOT EXISTS idx_module_resources_module_type
    ON module_resources(module_id, resource_type);

-- GIN index for JSONB metadata queries (if needed for filtering)
CREATE INDEX IF NOT EXISTS idx_module_resources_metadata
    ON module_resources USING GIN (metadata);

-- Date-based queries
CREATE INDEX IF NOT EXISTS idx_module_resources_created
    ON module_resources(created_at DESC);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Auto-update updated_at on row modification
DROP TRIGGER IF EXISTS module_resources_updated_at_trigger ON module_resources;
CREATE TRIGGER module_resources_updated_at_trigger
    BEFORE UPDATE ON module_resources
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- COMMENTS for Documentation
-- ============================================================================

COMMENT ON TABLE module_resources IS
    'Learning resources for modules. Each module can have 1 PDF + 1 video + 1 quiz (exactly 1 of each type).';

COMMENT ON COLUMN module_resources.module_id IS
    'References the parent module. CASCADE delete ensures resources are removed when module is deleted.';

COMMENT ON COLUMN module_resources.resource_type IS
    'Type of resource. Valid values: pdf, video, quiz. Only one of each type allowed per module.';

COMMENT ON COLUMN module_resources.resource_url IS
    'URL/link to the resource (can be external URL, file storage path, or embed code)';

COMMENT ON COLUMN module_resources.title IS
    'Resource title (e.g., "Introduction to Python - Lecture Video")';

COMMENT ON COLUMN module_resources.metadata IS
    'JSONB metadata for resource-specific properties (duration, file size, question count, etc.)';

-- ============================================================================
-- SECTION 2: ROLLBACK (DOWN)
-- ============================================================================

/*
-- ROLLBACK INSTRUCTIONS
-- To undo this migration, run the following commands:

-- Drop triggers
DROP TRIGGER IF EXISTS module_resources_updated_at_trigger ON module_resources;

-- Drop indexes
DROP INDEX IF EXISTS idx_module_resources_created;
DROP INDEX IF EXISTS idx_module_resources_metadata;
DROP INDEX IF EXISTS idx_module_resources_module_type;
DROP INDEX IF EXISTS idx_module_resources_type;
DROP INDEX IF EXISTS idx_module_resources_module;

-- Drop table
DROP TABLE IF EXISTS module_resources CASCADE;

-- ROLLBACK COMPLETE
*/

-- ============================================================================
-- SECTION 3: VERIFICATION & TESTS
-- ============================================================================

/*
-- TEST SUITE for module_resources table
-- Run these queries to verify the migration was successful

-- ===== TEST 1: Table Existence =====
SELECT
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name = 'module_resources';
-- Expected: 1 row with table_name = 'module_resources'


-- ===== TEST 2: Column Structure =====
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'module_resources'
ORDER BY ordinal_position;
-- Expected: 7 columns (id, module_id, resource_type, resource_url,
--           title, metadata, created_at, updated_at)


-- ===== TEST 3: Foreign Key Constraint =====
SELECT
    conname AS constraint_name,
    pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid = 'module_resources'::regclass
  AND contype = 'f';
-- Expected: 1 FK constraint to course_modules with ON DELETE CASCADE


-- ===== TEST 4: Indexes =====
SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'module_resources'
ORDER BY indexname;
-- Expected: 6 indexes (1 PK + 1 unique constraint + 4 custom indexes)


-- ===== TEST 5: Triggers =====
SELECT
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers
WHERE event_object_table = 'module_resources';
-- Expected: 1 trigger (module_resources_updated_at_trigger)


-- ===== TEST 6: Insert Complete Resource Set =====
DO $$
DECLARE
    test_plan_id UUID;
    test_module_id UUID;
BEGIN
    -- Create test plan
    INSERT INTO learning_plans (
        session_id, course_topic, knowledge_level, user_goals,
        total_duration_days, daily_time_available_minutes
    ) VALUES (
        gen_random_uuid(), 'Resources Test', 'Intermedio', 'Test resources', 30, 60
    ) RETURNING id INTO test_plan_id;

    -- Create test module
    INSERT INTO course_modules (learning_plan_id, module_number, title)
    VALUES (test_plan_id, 1, 'Test Module')
    RETURNING id INTO test_module_id;

    -- Insert all 3 resource types
    INSERT INTO module_resources (module_id, resource_type, resource_url, title, metadata)
    VALUES
        (test_module_id, 'pdf', 'https://example.com/module1.pdf', 'Lecture Notes PDF',
         '{"pages": 25, "file_size_mb": 3.2}'::jsonb),
        (test_module_id, 'video', 'https://youtube.com/watch?v=abc123', 'Video Tutorial',
         '{"duration_minutes": 45, "platform": "youtube", "thumbnail_url": "https://img.youtube.com/..."}'::jsonb),
        (test_module_id, 'quiz', 'https://forms.google.com/quiz123', 'Module Quiz',
         '{"questions_count": 15, "passing_score": 80, "time_limit_minutes": 30}'::jsonb);

    RAISE NOTICE 'TEST PASSED: All 3 resource types inserted successfully';
END $$;


-- ===== TEST 7: UNIQUE Constraint - Duplicate resource_type =====
DO $$
DECLARE
    test_module_id UUID;
BEGIN
    -- Get existing test module
    SELECT m.id INTO test_module_id
    FROM course_modules m
    JOIN learning_plans p ON m.learning_plan_id = p.id
    WHERE p.course_topic = 'Resources Test';

    -- Try to insert duplicate PDF
    INSERT INTO module_resources (module_id, resource_type, resource_url, title)
    VALUES (test_module_id, 'pdf', 'https://duplicate.pdf', 'Duplicate PDF');

    RAISE EXCEPTION 'TEST FAILED: Duplicate resource_type was accepted';
EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'TEST PASSED: Duplicate resource_type correctly rejected';
END $$;


-- ===== TEST 8: Constraint Validation - Invalid resource_type =====
DO $$
DECLARE
    test_module_id UUID;
BEGIN
    SELECT m.id INTO test_module_id
    FROM course_modules m
    JOIN learning_plans p ON m.learning_plan_id = p.id
    WHERE p.course_topic = 'Resources Test';

    -- Try invalid resource type
    INSERT INTO module_resources (module_id, resource_type, resource_url, title)
    VALUES (test_module_id, 'audio', 'https://test.mp3', 'Audio File');

    RAISE EXCEPTION 'TEST FAILED: Invalid resource_type was accepted';
EXCEPTION
    WHEN check_violation THEN
        RAISE NOTICE 'TEST PASSED: Invalid resource_type correctly rejected';
END $$;


-- ===== TEST 9: JSONB Metadata Query =====
DO $$
DECLARE
    video_count INTEGER;
    long_video_count INTEGER;
BEGIN
    -- Count all videos
    SELECT COUNT(*) INTO video_count
    FROM module_resources
    WHERE resource_type = 'video';

    -- Count videos longer than 30 minutes using JSONB query
    SELECT COUNT(*) INTO long_video_count
    FROM module_resources
    WHERE resource_type = 'video'
      AND (metadata->>'duration_minutes')::INTEGER > 30;

    RAISE NOTICE 'TEST PASSED: JSONB queries work (total videos: %, long videos: %)',
        video_count, long_video_count;
END $$;


-- ===== TEST 10: CASCADE Delete - Resources deleted when module deleted =====
DO $$
DECLARE
    test_plan_id UUID;
    test_module_id UUID;
    resources_before INTEGER;
    resources_after INTEGER;
BEGIN
    -- Get test module
    SELECT p.id, m.id INTO test_plan_id, test_module_id
    FROM learning_plans p
    JOIN course_modules m ON m.learning_plan_id = p.id
    WHERE p.course_topic = 'Resources Test';

    -- Count resources before delete
    SELECT COUNT(*) INTO resources_before
    FROM module_resources
    WHERE module_id = test_module_id;

    -- Delete the module (should CASCADE to resources)
    DELETE FROM course_modules WHERE id = test_module_id;

    -- Count resources after delete
    SELECT COUNT(*) INTO resources_after
    FROM module_resources
    WHERE module_id = test_module_id;

    IF resources_before > 0 AND resources_after = 0 THEN
        RAISE NOTICE 'TEST PASSED: CASCADE delete removed % resources', resources_before;
    ELSE
        RAISE EXCEPTION 'TEST FAILED: CASCADE delete failed (before: %, after: %)',
            resources_before, resources_after;
    END IF;

    -- Cleanup plan
    DELETE FROM learning_plans WHERE id = test_plan_id;
END $$;


-- ===== TEST 11: Full CASCADE - Plan deletion cascades to modules and resources =====
DO $$
DECLARE
    test_plan_id UUID;
    modules_count INTEGER;
    resources_count INTEGER;
BEGIN
    -- Create complete structure
    INSERT INTO learning_plans (
        session_id, course_topic, knowledge_level, user_goals,
        total_duration_days, daily_time_available_minutes
    ) VALUES (
        gen_random_uuid(), 'Full Cascade Test', 'Avanzado', 'Test full cascade', 30, 60
    ) RETURNING id INTO test_plan_id;

    -- Create 3 modules with resources
    FOR i IN 1..3 LOOP
        INSERT INTO course_modules (learning_plan_id, module_number, title)
        VALUES (test_plan_id, i, 'Module ' || i);

        INSERT INTO module_resources (module_id, resource_type, resource_url, title)
        SELECT id, 'pdf', 'https://test' || i || '.pdf', 'PDF ' || i
        FROM course_modules WHERE learning_plan_id = test_plan_id AND module_number = i;
    END LOOP;

    -- Verify data created
    SELECT COUNT(*) INTO modules_count FROM course_modules WHERE learning_plan_id = test_plan_id;
    SELECT COUNT(*) INTO resources_count
    FROM module_resources r
    JOIN course_modules m ON r.module_id = m.id
    WHERE m.learning_plan_id = test_plan_id;

    -- Delete the plan
    DELETE FROM learning_plans WHERE id = test_plan_id;

    -- Verify everything deleted
    IF (SELECT COUNT(*) FROM course_modules WHERE learning_plan_id = test_plan_id) = 0
       AND (SELECT COUNT(*) FROM module_resources r
            JOIN course_modules m ON r.module_id = m.id
            WHERE m.learning_plan_id = test_plan_id) = 0 THEN
        RAISE NOTICE 'TEST PASSED: Full CASCADE deleted % modules and % resources',
            modules_count, resources_count;
    ELSE
        RAISE EXCEPTION 'TEST FAILED: Full CASCADE did not delete everything';
    END IF;
END $$;


-- ===== TEST 12: Trigger - updated_at auto-update =====
DO $$
DECLARE
    test_plan_id UUID;
    test_module_id UUID;
    test_resource_id UUID;
    original_updated_at TIMESTAMP WITH TIME ZONE;
    new_updated_at TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Create test data
    INSERT INTO learning_plans (
        session_id, course_topic, knowledge_level, user_goals,
        total_duration_days, daily_time_available_minutes
    ) VALUES (
        gen_random_uuid(), 'Trigger Test', 'Principiante', 'Test triggers', 30, 60
    ) RETURNING id INTO test_plan_id;

    INSERT INTO course_modules (learning_plan_id, module_number, title)
    VALUES (test_plan_id, 1, 'Test Module')
    RETURNING id INTO test_module_id;

    INSERT INTO module_resources (module_id, resource_type, resource_url, title)
    VALUES (test_module_id, 'pdf', 'https://original.pdf', 'Original')
    RETURNING id, updated_at INTO test_resource_id, original_updated_at;

    -- Wait
    PERFORM pg_sleep(0.1);

    -- Update
    UPDATE module_resources
    SET resource_url = 'https://updated.pdf'
    WHERE id = test_resource_id
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


-- ===== TEST 13: Complete Module Structure Query =====
DO $$
DECLARE
    test_plan_id UUID;
    test_module_id UUID;
    result_count INTEGER;
BEGIN
    -- Create complete structure
    INSERT INTO learning_plans (
        session_id, course_topic, knowledge_level, user_goals,
        total_duration_days, daily_time_available_minutes
    ) VALUES (
        gen_random_uuid(), 'Query Test', 'Intermedio', 'Test queries', 30, 60
    ) RETURNING id INTO test_plan_id;

    INSERT INTO course_modules (learning_plan_id, module_number, title)
    VALUES (test_plan_id, 1, 'Complete Module')
    RETURNING id INTO test_module_id;

    INSERT INTO module_resources (module_id, resource_type, resource_url, title, metadata)
    VALUES
        (test_module_id, 'pdf', 'https://test.pdf', 'PDF', '{"pages": 10}'::jsonb),
        (test_module_id, 'video', 'https://test.mp4', 'Video', '{"duration_minutes": 20}'::jsonb),
        (test_module_id, 'quiz', 'https://test.quiz', 'Quiz', '{"questions_count": 5}'::jsonb);

    -- Query complete structure
    SELECT COUNT(*) INTO result_count
    FROM learning_plans lp
    JOIN course_modules cm ON cm.learning_plan_id = lp.id
    JOIN module_resources mr ON mr.module_id = cm.id
    WHERE lp.id = test_plan_id;

    IF result_count = 3 THEN
        RAISE NOTICE 'TEST PASSED: Complete structure query returned 3 resources';
    ELSE
        RAISE EXCEPTION 'TEST FAILED: Expected 3 resources, got %', result_count;
    END IF;

    -- Cleanup
    DELETE FROM learning_plans WHERE id = test_plan_id;
END $$;


-- ===== TEST 14: Final Count =====
SELECT COUNT(*) as remaining_records FROM module_resources;
-- Expected: 0 (all test data cleaned up)


-- ===== ALL TESTS COMPLETE =====
SELECT 'Migration 003 - All tests passed successfully!' AS test_result;
SELECT 'Learning System Schema - Complete!' AS final_status;
*/
