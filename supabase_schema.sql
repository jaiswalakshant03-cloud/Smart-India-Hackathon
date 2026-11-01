-- ============================================================================
-- CAPACITY CONNECT - Official PostgreSQL Schema for Supabase
-- Run this script in your Supabase Dashboard > SQL Editor
-- ============================================================================

-- 1. Profiles Table (Extends Supabase Auth users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  role TEXT CHECK (role IN ('trainee', 'trainer', 'admin')) DEFAULT 'trainee',
  designation TEXT DEFAULT 'Scientist',
  organization TEXT DEFAULT 'Capacity Connect',
  avatar_url TEXT DEFAULT '',
  aadhaar_verified BOOLEAN DEFAULT FALSE,
  aadhaar_number_masked TEXT DEFAULT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Courses Table
CREATE TABLE IF NOT EXISTS public.courses (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL,
  trainer_id TEXT NOT NULL,
  trainer_name TEXT NOT NULL,
  trainer_avatar TEXT DEFAULT '',
  category TEXT NOT NULL,
  level TEXT CHECK (level IN ('beginner', 'intermediate', 'advanced')) DEFAULT 'intermediate',
  duration_hours INTEGER DEFAULT 20,
  enrollment_count INTEGER DEFAULT 0,
  rating NUMERIC(3, 2) DEFAULT 4.8,
  thumbnail_url TEXT DEFAULT '',
  modules JSONB DEFAULT '[]'::jsonb,
  prerequisites TEXT[] DEFAULT '{}',
  skills_gained TEXT[] DEFAULT '{}',
  status TEXT CHECK (status IN ('draft', 'published', 'archived')) DEFAULT 'published',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Enrollments Table
CREATE TABLE IF NOT EXISTS public.enrollments (
  id TEXT PRIMARY KEY,
  course_id TEXT REFERENCES public.courses(id) ON DELETE CASCADE,
  trainee_id TEXT NOT NULL,
  progress_percent INTEGER DEFAULT 0,
  completed_lesson_ids TEXT[] DEFAULT '{}',
  enrolled_at TIMESTAMPTZ DEFAULT NOW(),
  last_accessed_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Assessments Table (Interactive MCQ, Google Form Link, PDF/Text Upload)
CREATE TABLE IF NOT EXISTS public.assessments (
  id TEXT PRIMARY KEY,
  course_id TEXT REFERENCES public.courses(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  subject TEXT NOT NULL,
  duration_minutes INTEGER DEFAULT 60,
  passing_percentage INTEGER DEFAULT 70,
  total_marks INTEGER DEFAULT 100,
  questions_count INTEGER DEFAULT 10,
  assessment_format TEXT CHECK (assessment_format IN ('mcq_builder', 'google_form', 'document_upload')) DEFAULT 'mcq_builder',
  questions JSONB DEFAULT '[]'::jsonb,
  negative_marking BOOLEAN DEFAULT FALSE,
  negative_marks_per_wrong NUMERIC(3, 2) DEFAULT 0.5,
  external_form_url TEXT DEFAULT NULL,
  allow_embed BOOLEAN DEFAULT TRUE,
  document_url TEXT DEFAULT NULL,
  document_name TEXT DEFAULT NULL,
  document_size TEXT DEFAULT NULL,
  document_file_type TEXT DEFAULT NULL,
  text_content TEXT DEFAULT NULL,
  instructions TEXT DEFAULT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Assessment Attempts Table
CREATE TABLE IF NOT EXISTS public.assessment_attempts (
  id TEXT PRIMARY KEY,
  assessment_id TEXT REFERENCES public.assessments(id) ON DELETE CASCADE,
  trainee_id TEXT NOT NULL,
  trainee_name TEXT NOT NULL,
  score INTEGER NOT NULL,
  max_score INTEGER NOT NULL,
  percentage INTEGER NOT NULL,
  is_passed BOOLEAN NOT NULL,
  answers JSONB DEFAULT '{}'::jsonb,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  submitted_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Certificates Table
CREATE TABLE IF NOT EXISTS public.certificates (
  id TEXT PRIMARY KEY,
  trainee_id TEXT NOT NULL,
  trainee_name TEXT NOT NULL,
  course_id TEXT REFERENCES public.courses(id) ON DELETE CASCADE,
  course_title TEXT NOT NULL,
  trainer_id TEXT NOT NULL,
  trainer_name TEXT NOT NULL,
  issue_date TIMESTAMPTZ DEFAULT NOW(),
  verification_hash TEXT NOT NULL UNIQUE,
  status TEXT CHECK (status IN ('active', 'revoked')) DEFAULT 'active',
  certificate_pdf_url TEXT DEFAULT NULL
);

-- 7. Audit Logs Table
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id TEXT PRIMARY KEY,
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  user_id TEXT NOT NULL,
  user_name TEXT NOT NULL,
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  details TEXT NOT NULL,
  ip_address TEXT DEFAULT '127.0.0.1'
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessment_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.certificates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Public Read Policies (Allows users & guests to browse courses, assessments, and verify certificates)
CREATE POLICY "Public can view published courses" ON public.courses FOR SELECT USING (status = 'published');
CREATE POLICY "Public can view assessments" ON public.assessments FOR SELECT USING (true);
CREATE POLICY "Public can verify certificates" ON public.certificates FOR SELECT USING (true);
CREATE POLICY "Users can manage own enrollments" ON public.enrollments FOR ALL USING (true);
CREATE POLICY "Users can manage own attempts" ON public.assessment_attempts FOR ALL USING (true);
CREATE POLICY "Public can view profiles" ON public.profiles FOR SELECT USING (true);
