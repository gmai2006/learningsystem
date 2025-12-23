--
-- PostgreSQL database dump
--

\restrict SsmlKxm0NWOqApxV8veQEHbHaO6BD4LEar9UdYqTDgfgmjcvSYMa8KN1xt2Zb0q

-- Dumped from database version 16.11 (Ubuntu 16.11-1.pgdg24.04+1)
-- Dumped by pg_dump version 16.11 (Ubuntu 16.11-1.pgdg24.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: eam; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA eam;


ALTER SCHEMA eam OWNER TO postgres;

--
-- Name: learningsystem; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA learningsystem;


ALTER SCHEMA learningsystem OWNER TO postgres;

--
-- Name: pharmacy; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA pharmacy;


ALTER SCHEMA pharmacy OWNER TO postgres;

--
-- Name: pharmacy3; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA pharmacy3;


ALTER SCHEMA pharmacy3 OWNER TO postgres;

--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: learning_type; Type: TYPE; Schema: learningsystem; Owner: postgres
--

CREATE TYPE learningsystem.learning_type AS ENUM (
    'INTERNSHIP',
    'PRACTICUM',
    'CLINICAL',
    'CO_OP',
    'STUDENT_EMPLOYMENT',
    'RESEARCH',
    'FIELD_WORK',
    'FELLOWSHIP',
    'STUDY_ABROAD',
    'VOLUNTEERISM',
    'COMMUNITY_PROJECT',
    'SERVICE_LEARNING',
    'CLASSROOM_SIMULATION',
    'LAB_WORK',
    'ARTS_PERFORMANCE',
    'APPRENTICESHIP'
);


ALTER TYPE learningsystem.learning_type OWNER TO postgres;

--
-- Name: user_role; Type: TYPE; Schema: learningsystem; Owner: postgres
--

CREATE TYPE learningsystem.user_role AS ENUM (
    'STUDENT',
    'FACULTY',
    'STAFF',
    'EMPLOYER'
);


ALTER TYPE learningsystem.user_role OWNER TO postgres;

--
-- Name: create_audit_partitions(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_audit_partitions() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    start_month DATE := date_trunc('month', now())::date;
    next_month DATE := start_month + INTERVAL '1 month';
BEGIN
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS access_logs_%s
        PARTITION OF access_logs
        FOR VALUES FROM (%L) TO (%L);
    ', to_char(start_month, 'YYYYMM'), start_month, next_month);

    EXECUTE format('
        CREATE TABLE IF NOT EXISTS pdmp_queries_%s
        PARTITION OF pdmp_queries
        FOR VALUES FROM (%L) TO (%L);
    ', to_char(start_month, 'YYYYMM'), start_month, next_month);
END;
$$;


ALTER FUNCTION public.create_audit_partitions() OWNER TO postgres;

--
-- Name: deactivate_inactive_stations(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.deactivate_inactive_stations(p_days_inactive integer DEFAULT 60) RETURNS TABLE(station_id character varying, deactivation_date timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    UPDATE device_fingerprints
    SET is_active = FALSE
    WHERE is_active = TRUE
    AND CURRENT_TIMESTAMP - last_seen > (p_days_inactive || ' days')::INTERVAL
    RETURNING station_id, CURRENT_TIMESTAMP;
END;
$$;


ALTER FUNCTION public.deactivate_inactive_stations(p_days_inactive integer) OWNER TO postgres;

--
-- Name: enforce_audit_retention(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.enforce_audit_retention() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM access_logs WHERE accessed_at < now() - INTERVAL '6 years';
    DELETE FROM pdmp_queries WHERE created_at < now() - INTERVAL '6 years';
END;
$$;


ALTER FUNCTION public.enforce_audit_retention() OWNER TO postgres;

--
-- Name: find_station_by_fingerprint(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.find_station_by_fingerprint(p_fingerprint_hash character varying) RETURNS TABLE(station_id character varying, department character varying, location character varying, last_seen timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        df.station_id,
        df.department,
        df.location,
        df.last_seen
    FROM device_fingerprints df
    WHERE df.fingerprint_hash = p_fingerprint_hash
    AND df.is_active = TRUE;
END;
$$;


ALTER FUNCTION public.find_station_by_fingerprint(p_fingerprint_hash character varying) OWNER TO postgres;

--
-- Name: get_fingerprint_statistics(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_fingerprint_statistics() RETURNS TABLE(total_devices integer, active_devices integer, inactive_devices integer, total_changes integer, avg_access_count numeric, last_registration timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM device_fingerprints)::INTEGER,
        (SELECT COUNT(*) FROM device_fingerprints WHERE is_active = TRUE)::INTEGER,
        (SELECT COUNT(*) FROM device_fingerprints WHERE is_active = FALSE)::INTEGER,
        (SELECT COUNT(*) FROM fingerprint_history)::INTEGER,
        (SELECT AVG(access_count) FROM device_fingerprints)::NUMERIC,
        (SELECT MAX(assigned_date) FROM device_fingerprints)::TIMESTAMP;
END;
$$;


ALTER FUNCTION public.get_fingerprint_statistics() OWNER TO postgres;

--
-- Name: log_efax_access(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.log_efax_access() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO access_logs (
        user_id,
        patient_id,
        entity_type,
        entity_id,
        action,
        access_reason,
        access_context
    ) VALUES (
        NEW.user_id,
        NEW.patient_id,
        'efax_job',
        NEW.id,
        CASE WHEN NEW.direction = 'outbound' THEN 'FAX_SEND' ELSE 'FAX_RECEIVE' END,
        'prescription_transmission',
        jsonb_build_object('fax_number', NEW.fax_number, 'status', NEW.status)
    );
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.log_efax_access() OWNER TO postgres;

--
-- Name: log_prescription_workflow_change(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.log_prescription_workflow_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (OLD.workflow_status IS DISTINCT FROM NEW.workflow_status) THEN
        INSERT INTO prescription_workflow_logs (
            prescription_id,
            from_status,
            to_status,
            queue_name,
            changed_by,
            change_reason
        )
        VALUES (
            NEW.id,
            OLD.workflow_status,
            NEW.workflow_status,
            NEW.queue_name,
            NEW.assigned_to,
            'auto transition via update'
        );
        NEW.last_status_update := now();
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.log_prescription_workflow_change() OWNER TO postgres;

--
-- Name: update_device_access(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_device_access(p_station_id character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE device_fingerprints
    SET 
        last_seen = CURRENT_TIMESTAMP,
        access_count = access_count + 1
    WHERE station_id = p_station_id;
END;
$$;


ALTER FUNCTION public.update_device_access(p_station_id character varying) OWNER TO postgres;

--
-- Name: update_stations_timestamp(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_stations_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_date = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_stations_timestamp() OWNER TO postgres;

--
-- Name: update_timestamp(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_timestamp() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: asset_meters; Type: TABLE; Schema: eam; Owner: postgres
--

CREATE TABLE eam.asset_meters (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    asset_id uuid NOT NULL,
    name text NOT NULL,
    unit text NOT NULL,
    last_reading numeric(14,2),
    last_reading_date timestamp with time zone
);


ALTER TABLE eam.asset_meters OWNER TO postgres;

--
-- Name: asset_types; Type: TABLE; Schema: eam; Owner: postgres
--

CREATE TABLE eam.asset_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text
);


ALTER TABLE eam.asset_types OWNER TO postgres;

--
-- Name: assets; Type: TABLE; Schema: eam; Owner: postgres
--

CREATE TABLE eam.assets (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    asset_type_id uuid,
    parent_id uuid,
    site_id uuid,
    geo public.geography(Point,4326),
    status text DEFAULT 'active'::text,
    acquisition_date date,
    cost numeric(14,2),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT assets_status_check CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text, 'retired'::text, 'under_maintenance'::text])))
);


ALTER TABLE eam.assets OWNER TO postgres;

--
-- Name: audit_log; Type: TABLE; Schema: eam; Owner: postgres
--

CREATE TABLE eam.audit_log (
    id bigint NOT NULL,
    entity text NOT NULL,
    entity_id uuid NOT NULL,
    action text NOT NULL,
    changed_by text,
    changed_at timestamp with time zone DEFAULT now(),
    diff jsonb,
    CONSTRAINT audit_log_action_check CHECK ((action = ANY (ARRAY['insert'::text, 'update'::text, 'delete'::text])))
);


ALTER TABLE eam.audit_log OWNER TO postgres;

--
-- Name: audit_log_id_seq; Type: SEQUENCE; Schema: eam; Owner: postgres
--

CREATE SEQUENCE eam.audit_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE eam.audit_log_id_seq OWNER TO postgres;

--
-- Name: audit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: eam; Owner: postgres
--

ALTER SEQUENCE eam.audit_log_id_seq OWNED BY eam.audit_log.id;


--
-- Name: inventory_transactions; Type: TABLE; Schema: eam; Owner: postgres
--

CREATE TABLE eam.inventory_transactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    part_id uuid,
    location_id uuid,
    quantity numeric(12,3) NOT NULL,
    transaction_type text,
    reference_id uuid,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT inventory_transactions_transaction_type_check CHECK ((transaction_type = ANY (ARRAY['receipt'::text, 'issue'::text, 'adjustment'::text])))
);


ALTER TABLE eam.inventory_transactions OWNER TO postgres;

--
-- Name: maintenance_plans; Type: TABLE; Schema: eam; Owner: postgres
--

CREATE TABLE eam.maintenance_plans (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    asset_id uuid,
    description text,
    frequency_days integer,
    next_due_date date,
    last_completed date
);


ALTER TABLE eam.maintenance_plans OWNER TO postgres;

--
-- Name: maintenance_triggers; Type: TABLE; Schema: eam; Owner: postgres
--

CREATE TABLE eam.maintenance_triggers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    plan_id uuid,
    meter_id uuid,
    threshold numeric(14,2)
);


ALTER TABLE eam.maintenance_triggers OWNER TO postgres;

--
-- Name: meter_readings; Type: TABLE; Schema: eam; Owner: postgres
--

CREATE TABLE eam.meter_readings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    meter_id uuid NOT NULL,
    reading_value numeric(14,2) NOT NULL,
    reading_date timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE eam.meter_readings OWNER TO postgres;

--
-- Name: outbox_events; Type: TABLE; Schema: eam; Owner: postgres
--

CREATE TABLE eam.outbox_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    aggregate_type text NOT NULL,
    aggregate_id uuid NOT NULL,
    event_type text NOT NULL,
    payload jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE eam.outbox_events OWNER TO postgres;

--
-- Name: parts; Type: TABLE; Schema: eam; Owner: postgres
--

CREATE TABLE eam.parts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    sku text NOT NULL,
    description text NOT NULL,
    uom text DEFAULT 'EA'::text,
    cost numeric(10,2),
    safety_stock integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE eam.parts OWNER TO postgres;

--
-- Name: stock_locations; Type: TABLE; Schema: eam; Owner: postgres
--

CREATE TABLE eam.stock_locations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text
);


ALTER TABLE eam.stock_locations OWNER TO postgres;

--
-- Name: technicians; Type: TABLE; Schema: eam; Owner: postgres
--

CREATE TABLE eam.technicians (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    first_name text,
    last_name text,
    email text,
    phone text,
    active boolean DEFAULT true
);


ALTER TABLE eam.technicians OWNER TO postgres;

--
-- Name: vendors; Type: TABLE; Schema: eam; Owner: postgres
--

CREATE TABLE eam.vendors (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    contact_info jsonb
);


ALTER TABLE eam.vendors OWNER TO postgres;

--
-- Name: work_order_labor; Type: TABLE; Schema: eam; Owner: postgres
--

CREATE TABLE eam.work_order_labor (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    work_order_id uuid,
    technician_id uuid,
    hours_worked numeric(6,2),
    cost_per_hour numeric(10,2),
    total_cost numeric(12,2) GENERATED ALWAYS AS ((hours_worked * cost_per_hour)) STORED
);


ALTER TABLE eam.work_order_labor OWNER TO postgres;

--
-- Name: work_order_parts; Type: TABLE; Schema: eam; Owner: postgres
--

CREATE TABLE eam.work_order_parts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    work_order_id uuid,
    part_id uuid,
    qty_planned numeric(12,3),
    qty_used numeric(12,3)
);


ALTER TABLE eam.work_order_parts OWNER TO postgres;

--
-- Name: work_order_tasks; Type: TABLE; Schema: eam; Owner: postgres
--

CREATE TABLE eam.work_order_tasks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    work_order_id uuid,
    sequence integer NOT NULL,
    description text NOT NULL,
    status text DEFAULT 'pending'::text,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    CONSTRAINT work_order_tasks_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'in_progress'::text, 'done'::text])))
);


ALTER TABLE eam.work_order_tasks OWNER TO postgres;

--
-- Name: work_orders; Type: TABLE; Schema: eam; Owner: postgres
--

CREATE TABLE eam.work_orders (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    asset_id uuid,
    type text NOT NULL,
    priority integer DEFAULT 3,
    status text DEFAULT 'requested'::text,
    description text,
    requested_by uuid,
    assigned_to uuid,
    sla_due_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    completed_at timestamp with time zone,
    CONSTRAINT work_orders_priority_check CHECK (((priority >= 1) AND (priority <= 5))),
    CONSTRAINT work_orders_status_check CHECK ((status = ANY (ARRAY['requested'::text, 'approved'::text, 'assigned'::text, 'in_progress'::text, 'done'::text, 'canceled'::text]))),
    CONSTRAINT work_orders_type_check CHECK ((type = ANY (ARRAY['corrective'::text, 'preventive'::text, 'inspection'::text, 'safety'::text])))
);


ALTER TABLE eam.work_orders OWNER TO postgres;

--
-- Name: applied_learning_experiences; Type: TABLE; Schema: learningsystem; Owner: postgres
--

CREATE TABLE learningsystem.applied_learning_experiences (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    student_id uuid NOT NULL,
    faculty_advisor_id uuid,
    type learningsystem.learning_type NOT NULL,
    title character varying(255) NOT NULL,
    organization_name character varying(255),
    status character varying(50) DEFAULT 'DRAFT'::character varying,
    start_date date,
    end_date date,
    canvas_course_id character varying(50),
    type_specific_data jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_verified boolean DEFAULT false,
    verified_at timestamp with time zone
);


ALTER TABLE learningsystem.applied_learning_experiences OWNER TO postgres;

--
-- Name: audit_logs; Type: TABLE; Schema: learningsystem; Owner: postgres
--

CREATE TABLE learningsystem.audit_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    actor_id uuid,
    actor_name character varying(255) NOT NULL,
    action character varying(255) NOT NULL,
    target_type character varying(50) NOT NULL,
    target_id uuid,
    details text,
    ip_address character varying(45),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE learningsystem.audit_logs OWNER TO postgres;

--
-- Name: employer_profiles; Type: TABLE; Schema: learningsystem; Owner: postgres
--

CREATE TABLE learningsystem.employer_profiles (
    user_id uuid NOT NULL,
    company_name character varying(255) NOT NULL,
    website_url character varying(255),
    industry character varying(100),
    description text,
    is_approved boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE learningsystem.employer_profiles OWNER TO postgres;

--
-- Name: event_registrations; Type: TABLE; Schema: learningsystem; Owner: postgres
--

CREATE TABLE learningsystem.event_registrations (
    event_id uuid NOT NULL,
    user_id uuid NOT NULL,
    payment_status character varying(50),
    checked_in boolean DEFAULT false
);


ALTER TABLE learningsystem.event_registrations OWNER TO postgres;

--
-- Name: events; Type: TABLE; Schema: learningsystem; Owner: postgres
--

CREATE TABLE learningsystem.events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organizer_id uuid,
    title character varying(255),
    type character varying(50),
    location character varying(255),
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    requires_fee boolean DEFAULT false,
    fee_amount numeric(10,2),
    touchnet_payment_code character varying(100)
);


ALTER TABLE learningsystem.events OWNER TO postgres;

--
-- Name: job_postings; Type: TABLE; Schema: learningsystem; Owner: postgres
--

CREATE TABLE learningsystem.job_postings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    employer_id uuid NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    location character varying(255),
    funding_source character varying(50) DEFAULT 'NON_WORK_STUDY'::character varying,
    is_on_campus boolean DEFAULT false,
    deadline date,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE learningsystem.job_postings OWNER TO postgres;

--
-- Name: student_profiles; Type: TABLE; Schema: learningsystem; Owner: postgres
--

CREATE TABLE learningsystem.student_profiles (
    user_id uuid NOT NULL,
    major character varying(255),
    gpa numeric(3,2),
    work_study_eligible boolean DEFAULT false,
    graduation_year integer,
    resume_url text,
    portfolio_url text
);


ALTER TABLE learningsystem.student_profiles OWNER TO postgres;

--
-- Name: system_configs; Type: TABLE; Schema: learningsystem; Owner: postgres
--

CREATE TABLE learningsystem.system_configs (
    config_key character varying(100) NOT NULL,
    config_value text NOT NULL,
    description text,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_by uuid
);


ALTER TABLE learningsystem.system_configs OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: learningsystem; Owner: postgres
--

CREATE TABLE learningsystem.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    okta_id character varying(255),
    banner_id character varying(50),
    email character varying(255) NOT NULL,
    first_name character varying(100),
    last_name character varying(100),
    role learningsystem.user_role NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE learningsystem.users OWNER TO postgres;

--
-- Name: volunteer_logs; Type: TABLE; Schema: learningsystem; Owner: postgres
--

CREATE TABLE learningsystem.volunteer_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    student_id uuid,
    experience_id uuid,
    date_logged date NOT NULL,
    hours_worked numeric(5,2),
    impact_type character varying(50),
    donation_amount numeric(10,2),
    site_supervisor_email character varying(255),
    is_verified boolean DEFAULT false
);


ALTER TABLE learningsystem.volunteer_logs OWNER TO postgres;

--
-- Name: workflows; Type: TABLE; Schema: learningsystem; Owner: postgres
--

CREATE TABLE learningsystem.workflows (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    experience_id uuid NOT NULL,
    step_order integer NOT NULL,
    approver_email character varying(255) NOT NULL,
    approver_name character varying(255),
    auth_token character varying(255),
    token_expiry timestamp without time zone,
    status character varying(50) DEFAULT 'PENDING'::character varying,
    comments text,
    action_date timestamp without time zone
);


ALTER TABLE learningsystem.workflows OWNER TO postgres;

--
-- Name: auth_logs; Type: TABLE; Schema: pharmacy; Owner: postgres
--

CREATE TABLE pharmacy.auth_logs (
    id bigint NOT NULL,
    user_id uuid,
    username text NOT NULL,
    event_type text NOT NULL,
    status text NOT NULL,
    ip_address text,
    user_agent text,
    metadata jsonb,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT auth_logs_event_type_check CHECK ((event_type = ANY (ARRAY['login'::text, 'logout'::text]))),
    CONSTRAINT auth_logs_status_check CHECK ((status = ANY (ARRAY['success'::text, 'failure'::text])))
);


ALTER TABLE pharmacy.auth_logs OWNER TO postgres;

--
-- Name: auth_logs_id_seq; Type: SEQUENCE; Schema: pharmacy; Owner: postgres
--

CREATE SEQUENCE pharmacy.auth_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE pharmacy.auth_logs_id_seq OWNER TO postgres;

--
-- Name: auth_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: pharmacy; Owner: postgres
--

ALTER SEQUENCE pharmacy.auth_logs_id_seq OWNED BY pharmacy.auth_logs.id;


--
-- Name: device_fingerprints; Type: TABLE; Schema: pharmacy; Owner: postgres
--

CREATE TABLE pharmacy.device_fingerprints (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    station_id bigint NOT NULL,
    fingerprint_hash character varying(128) NOT NULL,
    browser_user_agent text,
    screen_resolution character varying(50),
    timezone character varying(50),
    language character varying(20),
    canvas_fingerprint text,
    webgl_fingerprint text,
    department character varying(50) NOT NULL,
    location character varying(100),
    is_active boolean DEFAULT true,
    assigned_date timestamp with time zone DEFAULT now(),
    last_seen timestamp with time zone DEFAULT now(),
    access_count integer DEFAULT 1
);


ALTER TABLE pharmacy.device_fingerprints OWNER TO postgres;

--
-- Name: insurance_plans; Type: TABLE; Schema: pharmacy; Owner: postgres
--

CREATE TABLE pharmacy.insurance_plans (
    id uuid NOT NULL,
    plan_name text NOT NULL,
    payer_name text,
    payer_id text,
    bin text,
    pcn text,
    group_number text,
    phone_number text,
    notes text,
    active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE pharmacy.insurance_plans OWNER TO postgres;

--
-- Name: inventory_items; Type: TABLE; Schema: pharmacy; Owner: postgres
--

CREATE TABLE pharmacy.inventory_items (
    id uuid NOT NULL,
    ndc text,
    name text NOT NULL,
    strength text,
    form text,
    pack_size integer,
    dea_schedule text,
    is_controlled boolean DEFAULT false,
    on_hand integer DEFAULT 0,
    reorder_threshold integer,
    reorder_quantity integer,
    reorder_rule_id integer,
    manufacturer text,
    attributes jsonb,
    active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE pharmacy.inventory_items OWNER TO postgres;

--
-- Name: patient_insurances; Type: TABLE; Schema: pharmacy; Owner: postgres
--

CREATE TABLE pharmacy.patient_insurances (
    id uuid NOT NULL,
    patient_id uuid NOT NULL,
    insurance_plan_id uuid NOT NULL,
    member_id text,
    rx_group text,
    coverage_start date,
    coverage_end date,
    is_primary boolean DEFAULT false,
    is_secondary boolean DEFAULT false,
    is_tertiary boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE pharmacy.patient_insurances OWNER TO postgres;

--
-- Name: patients; Type: TABLE; Schema: pharmacy; Owner: postgres
--

CREATE TABLE pharmacy.patients (
    id uuid NOT NULL,
    mrn text,
    first_name text NOT NULL,
    last_name text NOT NULL,
    dob date,
    gender text,
    contact jsonb DEFAULT '{}'::jsonb,
    sensitive_data bytea,
    encrypted_at timestamp with time zone,
    is_student_record boolean DEFAULT false,
    preferred_language text,
    accessibility_preferences jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    updated_by uuid,
    CONSTRAINT patients_accessibility_preferences_check CHECK ((jsonb_typeof(accessibility_preferences) = 'object'::text)),
    CONSTRAINT patients_contact_check CHECK ((jsonb_typeof(contact) = 'object'::text)),
    CONSTRAINT patients_gender_check CHECK ((gender = ANY (ARRAY['male'::text, 'female'::text, 'other'::text, 'unknown'::text])))
);


ALTER TABLE pharmacy.patients OWNER TO postgres;

--
-- Name: prescribers; Type: TABLE; Schema: pharmacy; Owner: postgres
--

CREATE TABLE pharmacy.prescribers (
    id uuid NOT NULL,
    npi text NOT NULL,
    dea_number text,
    state_license_number text,
    upin text,
    taxonomy_code text,
    first_name text NOT NULL,
    last_name text NOT NULL,
    middle_name text,
    suffix text,
    clinic_name text,
    clinic_contact jsonb DEFAULT '{}'::jsonb,
    contact jsonb DEFAULT '{}'::jsonb,
    epcs_enabled boolean DEFAULT false,
    erx_identifier text,
    ncpdp_provider_id text,
    active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT prescribers_clinic_contact_check CHECK ((jsonb_typeof(clinic_contact) = 'object'::text)),
    CONSTRAINT prescribers_contact_check CHECK ((jsonb_typeof(contact) = 'object'::text))
);


ALTER TABLE pharmacy.prescribers OWNER TO postgres;

--
-- Name: prescription_queue; Type: TABLE; Schema: pharmacy; Owner: postgres
--

CREATE TABLE pharmacy.prescription_queue (
    id uuid NOT NULL,
    prescription_id uuid NOT NULL,
    workflow_step text NOT NULL,
    workflow_status text NOT NULL,
    assigned_to uuid,
    assigned_at timestamp with time zone,
    queue_name text NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE pharmacy.prescription_queue OWNER TO postgres;

--
-- Name: prescription_workflow_events; Type: TABLE; Schema: pharmacy; Owner: postgres
--

CREATE TABLE pharmacy.prescription_workflow_events (
    id uuid NOT NULL,
    prescription_id uuid NOT NULL,
    previous_step text,
    previous_status text,
    new_step text,
    new_status text,
    changed_by uuid,
    changed_at timestamp with time zone DEFAULT now(),
    note text
);


ALTER TABLE pharmacy.prescription_workflow_events OWNER TO postgres;

--
-- Name: prescriptions; Type: TABLE; Schema: pharmacy; Owner: postgres
--

CREATE TABLE pharmacy.prescriptions (
    id uuid NOT NULL,
    patient_id uuid NOT NULL,
    prescriber_id uuid NOT NULL,
    drug_id uuid NOT NULL,
    quantity numeric(10,2),
    days_supply integer,
    refills integer,
    sig text,
    written_date date,
    received_date timestamp with time zone DEFAULT now(),
    current_step text NOT NULL,
    current_status text NOT NULL,
    priority text DEFAULT 'NORMAL'::text,
    source text,
    note text,
    intake_completed_at timestamp with time zone,
    pharmacist_assigned_at timestamp with time zone,
    pharmacist_reviewed_at timestamp with time zone,
    patient_info_requested_at timestamp with time zone,
    provider_info_requested_at timestamp with time zone,
    denial_recorded_at timestamp with time zone,
    fill_queue_assigned_at timestamp with time zone,
    filling_started_at timestamp with time zone,
    special_order_created_at timestamp with time zone,
    fill_completed_at timestamp with time zone,
    qa_started_at timestamp with time zone,
    qa_failed_at timestamp with time zone,
    ready_for_pickup_at timestamp with time zone,
    picked_up_at timestamp with time zone,
    delivery_dispatched_at timestamp with time zone,
    delivery_confirmed_at timestamp with time zone,
    completed_at timestamp with time zone,
    cancelled_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE pharmacy.prescriptions OWNER TO postgres;

--
-- Name: reorder_rules; Type: TABLE; Schema: pharmacy; Owner: postgres
--

CREATE TABLE pharmacy.reorder_rules (
    id integer NOT NULL,
    rule_name text NOT NULL,
    description text,
    min_on_hand integer,
    max_stock_level integer,
    reorder_quantity integer,
    lead_time_days integer,
    seasonal boolean DEFAULT false,
    is_controlled boolean DEFAULT false,
    active boolean DEFAULT true
);


ALTER TABLE pharmacy.reorder_rules OWNER TO postgres;

--
-- Name: reorder_rules_id_seq; Type: SEQUENCE; Schema: pharmacy; Owner: postgres
--

CREATE SEQUENCE pharmacy.reorder_rules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE pharmacy.reorder_rules_id_seq OWNER TO postgres;

--
-- Name: reorder_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: pharmacy; Owner: postgres
--

ALTER SEQUENCE pharmacy.reorder_rules_id_seq OWNED BY pharmacy.reorder_rules.id;


--
-- Name: roles; Type: TABLE; Schema: pharmacy; Owner: postgres
--

CREATE TABLE pharmacy.roles (
    id integer NOT NULL,
    role_name text NOT NULL,
    display_name text NOT NULL,
    description text,
    active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE pharmacy.roles OWNER TO postgres;

--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: pharmacy; Owner: postgres
--

CREATE SEQUENCE pharmacy.roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE pharmacy.roles_id_seq OWNER TO postgres;

--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: pharmacy; Owner: postgres
--

ALTER SEQUENCE pharmacy.roles_id_seq OWNED BY pharmacy.roles.id;


--
-- Name: stations; Type: TABLE; Schema: pharmacy; Owner: postgres
--

CREATE TABLE pharmacy.stations (
    id bigint NOT NULL,
    station_prefix character varying(10) NOT NULL,
    department character varying(50) NOT NULL,
    location character varying(100),
    starting_number integer DEFAULT 1 NOT NULL,
    current_number integer DEFAULT 1 NOT NULL,
    max_stations integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT stations_check CHECK ((current_number >= starting_number)),
    CONSTRAINT stations_max_stations_check CHECK (((max_stations IS NULL) OR (max_stations >= 1))),
    CONSTRAINT stations_starting_number_check CHECK ((starting_number >= 1))
);


ALTER TABLE pharmacy.stations OWNER TO postgres;

--
-- Name: stations_id_seq; Type: SEQUENCE; Schema: pharmacy; Owner: postgres
--

CREATE SEQUENCE pharmacy.stations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE pharmacy.stations_id_seq OWNER TO postgres;

--
-- Name: stations_id_seq; Type: SEQUENCE OWNED BY; Schema: pharmacy; Owner: postgres
--

ALTER SEQUENCE pharmacy.stations_id_seq OWNED BY pharmacy.stations.id;


--
-- Name: user_roles; Type: TABLE; Schema: pharmacy; Owner: postgres
--

CREATE TABLE pharmacy.user_roles (
    user_id uuid NOT NULL,
    role_id integer NOT NULL,
    assigned_at timestamp with time zone DEFAULT now()
);


ALTER TABLE pharmacy.user_roles OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: pharmacy; Owner: postgres
--

CREATE TABLE pharmacy.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    username text NOT NULL,
    display_name text,
    email text NOT NULL,
    active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE pharmacy.users OWNER TO postgres;

--
-- Name: v_patient_insurance_summary; Type: VIEW; Schema: pharmacy; Owner: postgres
--

CREATE VIEW pharmacy.v_patient_insurance_summary AS
 SELECT pi.id AS patient_insurance_id,
    pi.patient_id,
    p.first_name,
    p.last_name,
    p.dob,
    p.gender,
    ip.id AS insurance_plan_id,
    ip.plan_name,
    ip.payer_name,
    ip.payer_id,
    ip.bin,
    ip.pcn,
    ip.group_number,
    ip.phone_number,
    ip.notes,
    ip.active,
    pi.member_id,
    pi.rx_group,
    pi.coverage_start,
    pi.coverage_end,
    pi.is_primary,
    pi.is_secondary,
    pi.is_tertiary,
    pi.created_at AS patient_insurance_created_at,
    pi.updated_at AS patient_insurance_updated_at
   FROM ((pharmacy.patient_insurances pi
     JOIN pharmacy.patients p ON ((p.id = pi.patient_id)))
     JOIN pharmacy.insurance_plans ip ON ((ip.id = pi.insurance_plan_id)));


ALTER VIEW pharmacy.v_patient_insurance_summary OWNER TO postgres;

--
-- Name: v_users_with_roles; Type: VIEW; Schema: pharmacy; Owner: postgres
--

CREATE VIEW pharmacy.v_users_with_roles AS
 SELECT u.id AS user_id,
    u.username,
    u.display_name,
    u.email,
    u.active AS user_active,
    u.created_at AS user_created_at,
    u.updated_at AS user_updated_at,
    COALESCE(json_agg(json_build_object('role_id', r.id, 'role_name', r.role_name) ORDER BY r.role_name) FILTER (WHERE (r.id IS NOT NULL)), '[]'::json) AS roles
   FROM ((pharmacy.users u
     LEFT JOIN pharmacy.user_roles ur ON ((ur.user_id = u.id)))
     LEFT JOIN pharmacy.roles r ON ((r.id = ur.role_id)))
  GROUP BY u.id, u.username, u.display_name, u.email, u.active, u.created_at, u.updated_at
  ORDER BY u.username;


ALTER VIEW pharmacy.v_users_with_roles OWNER TO postgres;

--
-- Name: workflow_statuses; Type: TABLE; Schema: pharmacy; Owner: postgres
--

CREATE TABLE pharmacy.workflow_statuses (
    status_code text NOT NULL,
    description text,
    is_terminal boolean DEFAULT false
);


ALTER TABLE pharmacy.workflow_statuses OWNER TO postgres;

--
-- Name: workflow_steps; Type: TABLE; Schema: pharmacy; Owner: postgres
--

CREATE TABLE pharmacy.workflow_steps (
    step_code text NOT NULL,
    step_name text NOT NULL,
    description text,
    default_status text NOT NULL,
    allowed_roles text[],
    sla_minutes integer,
    sort_order integer NOT NULL,
    is_terminal boolean DEFAULT false,
    is_active boolean DEFAULT true
);


ALTER TABLE pharmacy.workflow_steps OWNER TO postgres;

--
-- Name: workflow_transitions; Type: TABLE; Schema: pharmacy; Owner: postgres
--

CREATE TABLE pharmacy.workflow_transitions (
    id integer NOT NULL,
    from_step text,
    to_step text,
    allowed_roles text[]
);


ALTER TABLE pharmacy.workflow_transitions OWNER TO postgres;

--
-- Name: workflow_transitions_id_seq; Type: SEQUENCE; Schema: pharmacy; Owner: postgres
--

CREATE SEQUENCE pharmacy.workflow_transitions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE pharmacy.workflow_transitions_id_seq OWNER TO postgres;

--
-- Name: workflow_transitions_id_seq; Type: SEQUENCE OWNED BY; Schema: pharmacy; Owner: postgres
--

ALTER SEQUENCE pharmacy.workflow_transitions_id_seq OWNED BY pharmacy.workflow_transitions.id;


--
-- Name: access_logs; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.access_logs (
    id bigint NOT NULL,
    user_id uuid,
    patient_id uuid,
    entity_type text NOT NULL,
    entity_id uuid,
    action text NOT NULL,
    access_reason text,
    access_context jsonb,
    ip_address text,
    user_agent text,
    accessed_at timestamp with time zone DEFAULT now()
);


ALTER TABLE pharmacy3.access_logs OWNER TO postgres;

--
-- Name: access_logs_id_seq; Type: SEQUENCE; Schema: pharmacy3; Owner: postgres
--

CREATE SEQUENCE pharmacy3.access_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE pharmacy3.access_logs_id_seq OWNER TO postgres;

--
-- Name: access_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: pharmacy3; Owner: postgres
--

ALTER SEQUENCE pharmacy3.access_logs_id_seq OWNED BY pharmacy3.access_logs.id;


--
-- Name: auth_logs; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.auth_logs (
    id bigint NOT NULL,
    user_id uuid,
    username text NOT NULL,
    event_type text NOT NULL,
    status text NOT NULL,
    ip_address text,
    user_agent text,
    metadata jsonb,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT auth_logs_event_type_check CHECK ((event_type = ANY (ARRAY['login'::text, 'logout'::text]))),
    CONSTRAINT auth_logs_status_check CHECK ((status = ANY (ARRAY['success'::text, 'failure'::text])))
);


ALTER TABLE pharmacy3.auth_logs OWNER TO postgres;

--
-- Name: auth_logs_id_seq; Type: SEQUENCE; Schema: pharmacy3; Owner: postgres
--

CREATE SEQUENCE pharmacy3.auth_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE pharmacy3.auth_logs_id_seq OWNER TO postgres;

--
-- Name: auth_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: pharmacy3; Owner: postgres
--

ALTER SEQUENCE pharmacy3.auth_logs_id_seq OWNED BY pharmacy3.auth_logs.id;


--
-- Name: claim_transactions; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.claim_transactions (
    id uuid NOT NULL,
    claim_id uuid NOT NULL,
    transaction_code text NOT NULL,
    status text NOT NULL,
    reject_codes text[],
    request_json jsonb,
    response_json jsonb,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE pharmacy3.claim_transactions OWNER TO postgres;

--
-- Name: claims; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.claims (
    id uuid NOT NULL,
    patient_id uuid NOT NULL,
    patient_insurance_id uuid NOT NULL,
    prescription_id uuid NOT NULL,
    bin text NOT NULL,
    pcn text,
    group_id text,
    payer_id text,
    transaction_code text NOT NULL,
    claim_number text,
    claim_status text NOT NULL,
    submitted_uac numeric(10,2),
    submitted_ingredient_cost numeric(10,2),
    submitted_dispensing_fee numeric(10,2),
    submitted_qty numeric(10,2),
    submitted_days_supply integer,
    plan_paid_amount numeric(10,2),
    patient_pay_amount numeric(10,2),
    total_amount numeric(10,2),
    reject_codes text[],
    request_json jsonb,
    response_json jsonb,
    submitted_at timestamp with time zone DEFAULT now(),
    processed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE pharmacy3.claims OWNER TO postgres;

--
-- Name: device_fingerprints; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.device_fingerprints (
    id uuid,
    station_id bigint,
    fingerprint_hash character varying(128),
    browser_user_agent text,
    screen_resolution character varying(50),
    timezone character varying(50),
    language character varying(20),
    canvas_fingerprint text,
    webgl_fingerprint text,
    department character varying(50),
    location character varying(100),
    is_active boolean,
    assigned_date timestamp with time zone,
    last_seen timestamp with time zone,
    access_count integer
);


ALTER TABLE pharmacy3.device_fingerprints OWNER TO postgres;

--
-- Name: documents; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.documents (
    id uuid NOT NULL,
    filename text NOT NULL,
    content_type text NOT NULL,
    file_size bigint NOT NULL,
    storage_type text DEFAULT 'database'::text NOT NULL,
    file_bytes bytea,
    storage_path text,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_by uuid,
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT documents_metadata_check CHECK ((jsonb_typeof(metadata) = 'object'::text)),
    CONSTRAINT documents_storage_type_check CHECK ((storage_type = ANY (ARRAY['database'::text, 's3'::text, 'azure_blob'::text])))
);


ALTER TABLE pharmacy3.documents OWNER TO postgres;

--
-- Name: efax_incoming; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.efax_incoming (
    id uuid NOT NULL,
    from_fax_number text NOT NULL,
    from_name text,
    received_at timestamp with time zone DEFAULT now(),
    total_pages integer,
    file_path text NOT NULL,
    checksum text,
    linked_patient_id uuid,
    linked_prescription_id uuid,
    processed_by uuid,
    metadata jsonb
);


ALTER TABLE pharmacy3.efax_incoming OWNER TO postgres;

--
-- Name: efax_jobs; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.efax_jobs (
    id uuid NOT NULL,
    patient_id uuid,
    prescription_id uuid,
    user_id uuid,
    recipient_id uuid,
    document_id uuid,
    claim_id uuid,
    direction text NOT NULL,
    subject text,
    fax_number text NOT NULL,
    provider_name text,
    status text DEFAULT 'queued'::text NOT NULL,
    priority text DEFAULT 'normal'::text,
    total_pages integer DEFAULT 0,
    retry_count integer DEFAULT 0,
    error_message text,
    created_at timestamp with time zone DEFAULT now(),
    queued_at timestamp with time zone,
    preparing_at timestamp with time zone,
    sending_started_at timestamp with time zone,
    sent_at timestamp with time zone,
    received_at timestamp with time zone,
    failed_at timestamp with time zone,
    completed_at timestamp with time zone,
    metadata jsonb,
    CONSTRAINT efax_jobs_direction_check CHECK ((direction = ANY (ARRAY['outbound'::text, 'inbound'::text]))),
    CONSTRAINT efax_jobs_priority_check CHECK ((priority = ANY (ARRAY['low'::text, 'normal'::text, 'high'::text]))),
    CONSTRAINT efax_jobs_status_check CHECK ((status = ANY (ARRAY['queued'::text, 'preparing'::text, 'sending'::text, 'sent'::text, 'failed'::text, 'received'::text])))
);


ALTER TABLE pharmacy3.efax_jobs OWNER TO postgres;

--
-- Name: efax_recipients; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.efax_recipients (
    id uuid NOT NULL,
    name text NOT NULL,
    organization text,
    fax_number text NOT NULL,
    email text,
    contact_type text,
    is_verified boolean DEFAULT false,
    last_verified_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT efax_recipients_contact_type_check CHECK ((contact_type = ANY (ARRAY['prescriber'::text, 'payer'::text, 'facility'::text, 'lab'::text, 'other'::text])))
);


ALTER TABLE pharmacy3.efax_recipients OWNER TO postgres;

--
-- Name: efax_status_logs; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.efax_status_logs (
    id bigint NOT NULL,
    efax_job_id uuid NOT NULL,
    status text NOT NULL,
    message text,
    provider_code text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT efax_status_logs_status_check CHECK ((status = ANY (ARRAY['queued'::text, 'sending'::text, 'sent'::text, 'failed'::text, 'received'::text, 'rejected'::text])))
);


ALTER TABLE pharmacy3.efax_status_logs OWNER TO postgres;

--
-- Name: efax_status_logs_id_seq; Type: SEQUENCE; Schema: pharmacy3; Owner: postgres
--

CREATE SEQUENCE pharmacy3.efax_status_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE pharmacy3.efax_status_logs_id_seq OWNER TO postgres;

--
-- Name: efax_status_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: pharmacy3; Owner: postgres
--

ALTER SEQUENCE pharmacy3.efax_status_logs_id_seq OWNED BY pharmacy3.efax_status_logs.id;


--
-- Name: insurance_companies; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.insurance_companies (
    id uuid NOT NULL,
    payer_name text NOT NULL,
    payer_id text,
    phone_number text,
    website text,
    notes text,
    active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE pharmacy3.insurance_companies OWNER TO postgres;

--
-- Name: insurance_plans; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.insurance_plans (
    id uuid NOT NULL,
    company_id uuid NOT NULL,
    plan_name text NOT NULL,
    bin text,
    pcn text,
    group_number text,
    notes text,
    active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE pharmacy3.insurance_plans OWNER TO postgres;

--
-- Name: inventory_items; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.inventory_items (
    id uuid NOT NULL,
    ndc text,
    name text NOT NULL,
    strength text,
    form text,
    pack_size integer,
    dea_schedule text,
    is_controlled boolean DEFAULT false,
    on_hand integer DEFAULT 0,
    reorder_threshold integer,
    reorder_quantity integer,
    reorder_rule_id integer,
    manufacturer text,
    attributes jsonb,
    active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE pharmacy3.inventory_items OWNER TO postgres;

--
-- Name: patient_insurances; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.patient_insurances (
    id uuid NOT NULL,
    patient_id uuid NOT NULL,
    insurance_plan_id uuid NOT NULL,
    member_id text,
    rx_group text,
    relationship text,
    cardholder_name text,
    cardholder_dob date,
    coverage_start date,
    coverage_end date,
    override_bin text,
    override_pcn text,
    override_group_number text,
    member_metadata jsonb,
    is_primary boolean DEFAULT false,
    is_secondary boolean DEFAULT false,
    is_tertiary boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE pharmacy3.patient_insurances OWNER TO postgres;

--
-- Name: patients; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.patients (
    id uuid NOT NULL,
    mrn text,
    first_name text NOT NULL,
    last_name text NOT NULL,
    dob date,
    gender text,
    contact jsonb DEFAULT '{}'::jsonb,
    sensitive_data bytea,
    encrypted_at timestamp with time zone,
    is_student_record boolean DEFAULT false,
    preferred_language text,
    accessibility_preferences jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    updated_by uuid,
    CONSTRAINT patients_accessibility_preferences_check CHECK ((jsonb_typeof(accessibility_preferences) = 'object'::text)),
    CONSTRAINT patients_contact_check CHECK ((jsonb_typeof(contact) = 'object'::text)),
    CONSTRAINT patients_gender_check CHECK ((gender = ANY (ARRAY['male'::text, 'female'::text, 'other'::text, 'unknown'::text])))
);


ALTER TABLE pharmacy3.patients OWNER TO postgres;

--
-- Name: pharmacist_note_addendums; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.pharmacist_note_addendums (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    pharmacist_note_id uuid NOT NULL,
    actor_user_id uuid NOT NULL,
    addendum_text text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE pharmacy3.pharmacist_note_addendums OWNER TO postgres;

--
-- Name: pharmacist_notes; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.pharmacist_notes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    prescription_id uuid NOT NULL,
    actor_user_id uuid NOT NULL,
    note_type text NOT NULL,
    note_json jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    station_id text,
    active boolean DEFAULT true,
    CONSTRAINT pharmacist_notes_note_type_check CHECK ((note_type = ANY (ARRAY['CLINICAL_REVIEW'::text, 'DUR_INTERVENTION'::text, 'INSURANCE_ISSUE'::text, 'PRESCRIBER_CONTACT'::text, 'PATIENT_CONTACT'::text, 'PDMP_REVIEW'::text, 'CONTROLLED_SUBSTANCE_CHECK'::text, 'COUNSELING'::text, 'DOCUMENTATION_ONLY'::text, 'PRESCRIPTION_CANCELLATION'::text, 'OTHER'::text])))
);


ALTER TABLE pharmacy3.pharmacist_notes OWNER TO postgres;

--
-- Name: pharmacy_types; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.pharmacy_types (
    id integer NOT NULL,
    taxonomy_code character varying(10) NOT NULL,
    pharmacy_type_name character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE pharmacy3.pharmacy_types OWNER TO postgres;

--
-- Name: pharmacy_types_id_seq; Type: SEQUENCE; Schema: pharmacy3; Owner: postgres
--

CREATE SEQUENCE pharmacy3.pharmacy_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE pharmacy3.pharmacy_types_id_seq OWNER TO postgres;

--
-- Name: pharmacy_types_id_seq; Type: SEQUENCE OWNED BY; Schema: pharmacy3; Owner: postgres
--

ALTER SEQUENCE pharmacy3.pharmacy_types_id_seq OWNED BY pharmacy3.pharmacy_types.id;


--
-- Name: prescribers; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.prescribers (
    id uuid NOT NULL,
    npi text NOT NULL,
    dea_number text,
    state_license_number text,
    upin text,
    taxonomy_code text,
    first_name text NOT NULL,
    last_name text NOT NULL,
    middle_name text,
    suffix text,
    clinic_name text,
    clinic_contact jsonb DEFAULT '{}'::jsonb,
    contact jsonb DEFAULT '{}'::jsonb,
    epcs_enabled boolean DEFAULT false,
    erx_identifier text,
    ncpdp_provider_id text,
    active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT prescribers_clinic_contact_check CHECK ((jsonb_typeof(clinic_contact) = 'object'::text)),
    CONSTRAINT prescribers_contact_check CHECK ((jsonb_typeof(contact) = 'object'::text))
);


ALTER TABLE pharmacy3.prescribers OWNER TO postgres;

--
-- Name: prescription_items; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.prescription_items (
    id uuid NOT NULL,
    prescription_id uuid NOT NULL,
    inventory_item_id uuid NOT NULL,
    ndc_dispensed text,
    quantity numeric(10,2) NOT NULL,
    days_supply integer,
    sig text,
    daw_code text,
    refills_allowed integer DEFAULT 0,
    refills_used integer DEFAULT 0,
    workflow_step text DEFAULT 'INTAKE'::text NOT NULL,
    workflow_status text DEFAULT 'NEW'::text NOT NULL,
    reviewed_at timestamp with time zone,
    filled_at timestamp with time zone,
    verified_at timestamp with time zone,
    ready_for_pickup_at timestamp with time zone,
    picked_up_at timestamp with time zone,
    lot_number text,
    expiration_date date,
    ingredient_cost numeric(10,2),
    dispensing_fee numeric(10,2),
    total_price numeric(10,2),
    copay numeric(10,2),
    insurance_paid numeric(10,2),
    patient_pay numeric(10,2),
    diagnosis_code text,
    prior_auth_required boolean DEFAULT false,
    prior_auth_status text,
    prior_auth_number text,
    label_options jsonb,
    status text DEFAULT 'active'::text,
    cancel_reason text,
    cancelled_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE pharmacy3.prescription_items OWNER TO postgres;

--
-- Name: prescription_queue; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.prescription_queue (
    id uuid NOT NULL,
    prescription_id uuid NOT NULL,
    workflow_step text NOT NULL,
    workflow_status text NOT NULL,
    assigned_to uuid,
    assigned_at timestamp with time zone,
    queue_name text NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE pharmacy3.prescription_queue OWNER TO postgres;

--
-- Name: prescription_workflow_events; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.prescription_workflow_events (
    id uuid NOT NULL,
    prescription_id uuid NOT NULL,
    previous_step text,
    previous_status text,
    new_step text,
    new_status text,
    changed_by uuid,
    changed_at timestamp with time zone DEFAULT now(),
    note text,
    metadata jsonb
);


ALTER TABLE pharmacy3.prescription_workflow_events OWNER TO postgres;

--
-- Name: prescriptions; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.prescriptions (
    id uuid NOT NULL,
    patient_id uuid NOT NULL,
    prescriber_id uuid,
    written_date date,
    received_date timestamp with time zone DEFAULT now(),
    current_step text NOT NULL,
    current_status text NOT NULL,
    priority text DEFAULT 'NORMAL'::text,
    source text,
    note text,
    intake_completed_at timestamp with time zone,
    pharmacist_assigned_at timestamp with time zone,
    pharmacist_reviewed_at timestamp with time zone,
    patient_info_requested_at timestamp with time zone,
    provider_info_requested_at timestamp with time zone,
    denial_recorded_at timestamp with time zone,
    fill_queue_assigned_at timestamp with time zone,
    filling_started_at timestamp with time zone,
    special_order_created_at timestamp with time zone,
    fill_completed_at timestamp with time zone,
    qa_started_at timestamp with time zone,
    qa_failed_at timestamp with time zone,
    ready_for_pickup_at timestamp with time zone,
    picked_up_at timestamp with time zone,
    delivery_dispatched_at timestamp with time zone,
    delivery_confirmed_at timestamp with time zone,
    completed_at timestamp with time zone,
    cancelled_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE pharmacy3.prescriptions OWNER TO postgres;

--
-- Name: reorder_rules; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.reorder_rules (
    id integer NOT NULL,
    rule_name text NOT NULL,
    description text,
    min_on_hand integer,
    max_stock_level integer,
    reorder_quantity integer,
    lead_time_days integer,
    seasonal boolean DEFAULT false,
    is_controlled boolean DEFAULT false,
    active boolean DEFAULT true
);


ALTER TABLE pharmacy3.reorder_rules OWNER TO postgres;

--
-- Name: reorder_rules_id_seq; Type: SEQUENCE; Schema: pharmacy3; Owner: postgres
--

CREATE SEQUENCE pharmacy3.reorder_rules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE pharmacy3.reorder_rules_id_seq OWNER TO postgres;

--
-- Name: reorder_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: pharmacy3; Owner: postgres
--

ALTER SEQUENCE pharmacy3.reorder_rules_id_seq OWNED BY pharmacy3.reorder_rules.id;


--
-- Name: roles; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.roles (
    id integer,
    role_name text,
    display_name text,
    description text,
    active boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE pharmacy3.roles OWNER TO postgres;

--
-- Name: stations; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.stations (
    id bigint NOT NULL,
    station_prefix character varying(10) NOT NULL,
    department character varying(50) NOT NULL,
    location character varying(100),
    starting_number integer DEFAULT 1 NOT NULL,
    current_number integer DEFAULT 1 NOT NULL,
    max_stations integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT stations_check CHECK ((current_number >= starting_number)),
    CONSTRAINT stations_max_stations_check CHECK (((max_stations IS NULL) OR (max_stations >= 1))),
    CONSTRAINT stations_starting_number_check CHECK ((starting_number >= 1))
);


ALTER TABLE pharmacy3.stations OWNER TO postgres;

--
-- Name: stations_id_seq; Type: SEQUENCE; Schema: pharmacy3; Owner: postgres
--

CREATE SEQUENCE pharmacy3.stations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE pharmacy3.stations_id_seq OWNER TO postgres;

--
-- Name: stations_id_seq; Type: SEQUENCE OWNED BY; Schema: pharmacy3; Owner: postgres
--

ALTER SEQUENCE pharmacy3.stations_id_seq OWNED BY pharmacy3.stations.id;


--
-- Name: user_roles; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.user_roles (
    user_id uuid,
    role_id integer,
    assigned_at timestamp with time zone
);


ALTER TABLE pharmacy3.user_roles OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.users (
    id uuid,
    username text,
    display_name text,
    email text,
    active boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE pharmacy3.users OWNER TO postgres;

--
-- Name: v_claim_activity; Type: VIEW; Schema: pharmacy3; Owner: postgres
--

CREATE VIEW pharmacy3.v_claim_activity AS
 WITH latest_tx AS (
         SELECT ct.id,
            ct.claim_id,
            ct.transaction_code,
            ct.status,
            ct.reject_codes,
            ct.request_json,
            ct.response_json,
            ct.created_at,
            row_number() OVER (PARTITION BY ct.claim_id ORDER BY ct.created_at DESC) AS rn
           FROM pharmacy3.claim_transactions ct
        )
 SELECT c.id AS claim_id,
    c.patient_id,
    c.patient_insurance_id,
    c.prescription_id,
    c.bin,
    c.pcn,
    c.group_id,
    c.payer_id,
    c.transaction_code AS initial_transaction_code,
    c.claim_number,
    c.claim_status,
    c.submitted_uac,
    c.submitted_ingredient_cost,
    c.submitted_dispensing_fee,
    c.submitted_qty,
    c.submitted_days_supply,
    c.plan_paid_amount,
    c.patient_pay_amount,
    c.total_amount,
    c.reject_codes AS claim_reject_codes,
    c.request_json AS claim_request_json,
    c.response_json AS claim_response_json,
    c.submitted_at,
    c.processed_at,
    c.created_at AS claim_created_at,
    c.updated_at AS claim_updated_at,
    tx.transaction_code AS last_transaction_code,
    tx.status AS last_transaction_status,
    tx.reject_codes AS last_reject_codes,
    tx.request_json AS last_request_json,
    tx.response_json AS last_response_json,
    tx.created_at AS last_transaction_at
   FROM (pharmacy3.claims c
     LEFT JOIN latest_tx tx ON (((tx.claim_id = c.id) AND (tx.rn = 1))));


ALTER VIEW pharmacy3.v_claim_activity OWNER TO postgres;

--
-- Name: v_insurance_plans_summary; Type: VIEW; Schema: pharmacy3; Owner: postgres
--

CREATE VIEW pharmacy3.v_insurance_plans_summary AS
 SELECT p.id AS plan_id,
    p.plan_name,
    p.group_number,
    p.active AS plan_active,
    c.id AS company_id,
    c.payer_name AS company_name,
    c.payer_id AS company_payer_id,
    c.phone_number AS company_phone,
    c.active AS company_active
   FROM (pharmacy3.insurance_plans p
     JOIN pharmacy3.insurance_companies c ON ((p.company_id = c.id)));


ALTER VIEW pharmacy3.v_insurance_plans_summary OWNER TO postgres;

--
-- Name: v_patient_insurances_summary; Type: VIEW; Schema: pharmacy3; Owner: postgres
--

CREATE VIEW pharmacy3.v_patient_insurances_summary AS
 WITH ins AS (
         SELECT pi.patient_id,
            jsonb_build_object('isPrimary', pi.is_primary, 'isSecondary', pi.is_secondary, 'isTertiary', pi.is_tertiary, 'planId', vip.plan_id, 'planName', vip.plan_name, 'groupNumber', vip.group_number, 'planActive', vip.plan_active, 'companyId', vip.company_id, 'companyName', vip.company_name, 'companyPayerId', vip.company_payer_id, 'companyPhone', vip.company_phone) AS insurance_json
           FROM (pharmacy3.patient_insurances pi
             JOIN pharmacy3.v_insurance_plans_summary vip ON ((pi.insurance_plan_id = vip.plan_id)))
        )
 SELECT p.id AS patient_id,
    p.mrn,
    p.first_name,
    p.last_name,
    p.dob,
    p.gender,
    p.contact,
    COALESCE(jsonb_agg(ins.insurance_json ORDER BY (ins.insurance_json ->> 'planName'::text)), '[]'::jsonb) AS insurances
   FROM (pharmacy3.patients p
     LEFT JOIN ins ON ((p.id = ins.patient_id)))
  GROUP BY p.id, p.mrn, p.first_name, p.last_name, p.dob, p.gender, p.contact;


ALTER VIEW pharmacy3.v_patient_insurances_summary OWNER TO postgres;

--
-- Name: workflow_steps; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.workflow_steps (
    step_code text,
    step_name text,
    description text,
    default_status text,
    allowed_roles text[],
    sla_minutes integer,
    sort_order integer,
    is_terminal boolean,
    is_active boolean,
    queue_name text
);


ALTER TABLE pharmacy3.workflow_steps OWNER TO postgres;

--
-- Name: v_prescription_items_summary; Type: VIEW; Schema: pharmacy3; Owner: postgres
--

CREATE VIEW pharmacy3.v_prescription_items_summary AS
 WITH items AS (
         SELECT i.prescription_id,
            jsonb_build_object('itemId', i.id, 'inventoryItemId', i.inventory_item_id, 'quantity', i.quantity, 'daysSupply', i.days_supply, 'sig', i.sig, 'dawCode', i.daw_code, 'refillsAllowed', i.refills_allowed, 'refillsUsed', i.refills_used, 'lotNumber', i.lot_number, 'expirationDate', i.expiration_date, 'totalPrice', i.total_price, 'copay', i.copay, 'insurancePaid', i.insurance_paid, 'patientPay', i.patient_pay, 'name', inv.name, 'strength', inv.strength, 'packSize', inv.pack_size, 'isControlled', inv.is_controlled) AS item_json
           FROM (pharmacy3.prescription_items i
             JOIN pharmacy3.inventory_items inv ON ((i.inventory_item_id = inv.id)))
        )
 SELECT p.id AS prescription_id,
    p.patient_id,
    p.prescriber_id,
    p.written_date,
    p.received_date,
    p.current_step,
    p.current_status,
    p.priority,
    p.source,
    p.note,
    q.queue_name,
    p.created_at AS prescription_created_at,
    p.updated_at AS prescription_updated_at,
    COALESCE(jsonb_agg(items.item_json ORDER BY (items.item_json ->> 'itemId'::text)), '[]'::jsonb) AS items
   FROM ((pharmacy3.prescriptions p
     LEFT JOIN items ON ((p.id = items.prescription_id)))
     LEFT JOIN pharmacy3.workflow_steps q ON ((p.current_step = q.step_code)))
  GROUP BY p.id, p.patient_id, p.prescriber_id, p.written_date, p.received_date, p.current_step, q.queue_name, p.current_status, p.priority, p.source, p.note, p.created_at, p.updated_at;


ALTER VIEW pharmacy3.v_prescription_items_summary OWNER TO postgres;

--
-- Name: v_prescription_patient_insurance_prescribers_summary; Type: VIEW; Schema: pharmacy3; Owner: postgres
--

CREATE VIEW pharmacy3.v_prescription_patient_insurance_prescribers_summary AS
 SELECT vpi.prescription_id,
    vpi.patient_id,
    vpi.prescriber_id,
    vpi.current_step,
    vpi.current_status,
    vpi.priority,
    vpi.source,
    vpi.note,
    vpi.items,
    vpi.queue_name,
    vpat.mrn,
    vpat.first_name,
    vpat.last_name,
    vpat.insurances,
    vpat.dob,
    pr.first_name AS prescriber_first_name,
    pr.last_name AS prescriber_last_name,
    pr.clinic_name
   FROM ((pharmacy3.v_prescription_items_summary vpi
     LEFT JOIN pharmacy3.v_patient_insurances_summary vpat ON ((vpi.patient_id = vpat.patient_id)))
     LEFT JOIN pharmacy3.prescribers pr ON ((vpi.prescriber_id = pr.id)));


ALTER VIEW pharmacy3.v_prescription_patient_insurance_prescribers_summary OWNER TO postgres;

--
-- Name: v_claims_dashboard_summary; Type: VIEW; Schema: pharmacy3; Owner: postgres
--

CREATE VIEW pharmacy3.v_claims_dashboard_summary AS
 WITH latest_tx AS (
         SELECT ct.id,
            ct.claim_id,
            ct.transaction_code,
            ct.status,
            ct.reject_codes,
            ct.request_json,
            ct.response_json,
            ct.created_at,
            row_number() OVER (PARTITION BY ct.claim_id ORDER BY ct.created_at DESC) AS rn
           FROM pharmacy3.claim_transactions ct
        )
 SELECT base.prescription_id,
    base.patient_id,
    base.prescriber_id,
    c.id AS claim_id,
    c.claim_number,
    base.mrn AS patient_mrn,
    base.first_name AS patient_first_name,
    base.last_name AS patient_last_name,
    base.dob AS patient_dob,
    base.prescriber_first_name,
    base.prescriber_last_name,
    base.clinic_name,
    base.insurances,
    base.current_step,
    base.current_status,
    base.priority,
    base.source,
    base.queue_name,
    c.bin,
    c.pcn,
    c.group_id,
    c.payer_id,
    c.submitted_uac,
    c.submitted_ingredient_cost,
    c.submitted_dispensing_fee,
    c.submitted_qty,
    c.submitted_days_supply,
    c.plan_paid_amount,
    c.patient_pay_amount,
    c.total_amount,
    c.claim_status AS claim_master_status,
    c.reject_codes AS claim_master_rejects,
    c.submitted_at AS claim_submitted_at,
    c.processed_at AS claim_processed_at,
    tx.transaction_code AS last_transaction_code,
    tx.status AS last_transaction_status,
    tx.reject_codes AS last_reject_codes,
    tx.created_at AS last_transaction_at,
        CASE
            WHEN (tx.status = 'rejected'::text) THEN 'REQUIRES_ATTENTION'::text
            WHEN (tx.status = 'paid'::text) THEN 'PAID'::text
            WHEN (tx.status = 'submitted'::text) THEN 'PENDING'::text
            WHEN (tx.status = 'reversed'::text) THEN 'REVERSED'::text
            ELSE 'UNKNOWN'::text
        END AS dashboard_state,
        CASE
            WHEN (tx.reject_codes && ARRAY['75'::text]) THEN 'PA_REQUIRED'::text
            WHEN (tx.reject_codes && ARRAY['79'::text]) THEN 'REFILL_TOO_SOON'::text
            WHEN (tx.reject_codes && ARRAY['88'::text]) THEN 'DUR_REVIEW'::text
            WHEN (tx.status = 'submitted'::text) THEN 'AWAITING_PAYER'::text
            WHEN (tx.status = 'paid'::text) THEN 'OK_TO_FILL'::text
            ELSE 'GENERAL_REVIEW'::text
        END AS recommended_queue,
    c.request_json AS claim_request,
    c.response_json AS claim_response,
    tx.request_json AS last_tx_request,
    tx.response_json AS last_tx_response
   FROM ((pharmacy3.v_prescription_patient_insurance_prescribers_summary base
     LEFT JOIN pharmacy3.claims c ON ((c.prescription_id = base.prescription_id)))
     LEFT JOIN latest_tx tx ON (((tx.claim_id = c.id) AND (tx.rn = 1))));


ALTER VIEW pharmacy3.v_claims_dashboard_summary OWNER TO postgres;

--
-- Name: v_insurance_companies_with_plans; Type: VIEW; Schema: pharmacy3; Owner: postgres
--

CREATE VIEW pharmacy3.v_insurance_companies_with_plans AS
 SELECT ic.id,
    ic.payer_name,
    ic.payer_id,
    ic.phone_number,
    ic.website,
    ic.notes,
    ic.active,
    ic.created_at,
    ic.updated_at,
    jsonb_agg(jsonb_build_object('id', ip.id, 'planName', ip.plan_name, 'bin', ip.bin, 'pcn', ip.pcn, 'groupNumber', ip.group_number, 'notes', ip.notes, 'active', ip.active, 'createdAt', ip.created_at, 'updatedAt', ip.updated_at) ORDER BY ip.plan_name) AS insurance_plans
   FROM (pharmacy3.insurance_companies ic
     LEFT JOIN pharmacy3.insurance_plans ip ON ((ic.id = ip.company_id)))
  GROUP BY ic.id, ic.payer_name, ic.payer_id, ic.phone_number, ic.website, ic.notes, ic.active, ic.created_at, ic.updated_at
  ORDER BY ic.payer_name;


ALTER VIEW pharmacy3.v_insurance_companies_with_plans OWNER TO postgres;

--
-- Name: v_insurance_plans; Type: VIEW; Schema: pharmacy3; Owner: postgres
--

CREATE VIEW pharmacy3.v_insurance_plans AS
 SELECT p.id AS plan_id,
    p.plan_name,
    p.bin,
    p.pcn,
    p.group_number,
    p.notes AS plan_notes,
    p.active AS plan_active,
    p.created_at AS plan_created_at,
    p.updated_at AS plan_updated_at,
    c.id AS company_id,
    c.payer_name AS company_name,
    c.payer_id AS company_payer_id,
    c.phone_number AS company_phone,
    c.website AS company_website,
    c.notes AS company_notes,
    c.active AS company_active,
    c.created_at AS company_created_at,
    c.updated_at AS company_updated_at
   FROM (pharmacy3.insurance_plans p
     JOIN pharmacy3.insurance_companies c ON ((p.company_id = c.id)));


ALTER VIEW pharmacy3.v_insurance_plans OWNER TO postgres;

--
-- Name: v_patient_insurances; Type: VIEW; Schema: pharmacy3; Owner: postgres
--

CREATE VIEW pharmacy3.v_patient_insurances AS
 WITH ins AS (
         SELECT pi.patient_id,
            jsonb_build_object('patientInsuranceId', pi.id, 'memberId', pi.member_id, 'rxGroup', pi.rx_group, 'relationship', pi.relationship, 'cardholderName', pi.cardholder_name, 'cardholderDob', pi.cardholder_dob, 'coverageStart', pi.coverage_start, 'coverageEnd', pi.coverage_end, 'overrideBin', pi.override_bin, 'overridePcn', pi.override_pcn, 'overrideGroupNumber', pi.override_group_number, 'memberMetadata', pi.member_metadata, 'isPrimary', pi.is_primary, 'isSecondary', pi.is_secondary, 'isTertiary', pi.is_tertiary, 'createdAt', pi.created_at, 'updatedAt', pi.updated_at, 'planId', vip.plan_id, 'planName', vip.plan_name, 'bin', vip.bin, 'pcn', vip.pcn, 'groupNumber', vip.group_number, 'planNotes', vip.plan_notes, 'planActive', vip.plan_active, 'planCreatedAt', vip.plan_created_at, 'planUpdatedAt', vip.plan_updated_at, 'companyId', vip.company_id, 'companyName', vip.company_name, 'companyPayerId', vip.company_payer_id, 'companyPhone', vip.company_phone, 'companyWebsite', vip.company_website, 'companyNotes', vip.company_notes, 'companyActive', vip.company_active, 'companyCreatedAt', vip.company_created_at, 'companyUpdatedAt', vip.company_updated_at) AS insurance_json
           FROM (pharmacy3.patient_insurances pi
             JOIN pharmacy3.v_insurance_plans vip ON ((pi.insurance_plan_id = vip.plan_id)))
        )
 SELECT p.id AS patient_id,
    p.mrn,
    p.first_name,
    p.last_name,
    p.dob,
    p.gender,
    p.contact,
    p.sensitive_data,
    p.encrypted_at,
    p.is_student_record,
    p.preferred_language,
    p.accessibility_preferences,
    p.created_at AS patient_created_at,
    p.updated_at AS patient_updated_at,
    p.updated_by,
    COALESCE(jsonb_agg(ins.insurance_json ORDER BY (ins.insurance_json ->> 'planName'::text)), '[]'::jsonb) AS insurances
   FROM (pharmacy3.patients p
     LEFT JOIN ins ON ((p.id = ins.patient_id)))
  GROUP BY p.id, p.mrn, p.first_name, p.last_name, p.dob, p.gender, p.contact, p.sensitive_data, p.encrypted_at, p.is_student_record, p.preferred_language, p.accessibility_preferences, p.created_at, p.updated_at, p.updated_by;


ALTER VIEW pharmacy3.v_patient_insurances OWNER TO postgres;

--
-- Name: v_prescription_items; Type: VIEW; Schema: pharmacy3; Owner: postgres
--

CREATE VIEW pharmacy3.v_prescription_items AS
 WITH items AS (
         SELECT i.prescription_id,
            jsonb_build_object('itemId', i.id, 'inventoryItemId', i.inventory_item_id, 'ndcDispensed', i.ndc_dispensed, 'quantity', i.quantity, 'daysSupply', i.days_supply, 'sig', i.sig, 'dawCode', i.daw_code, 'refillsAllowed', i.refills_allowed, 'refillsUsed', i.refills_used, 'workflowStep', i.workflow_step, 'workflowStatus', i.workflow_status, 'reviewedAt', i.reviewed_at, 'filledAt', i.filled_at, 'verifiedAt', i.verified_at, 'readyForPickupAt', i.ready_for_pickup_at, 'pickedUpAt', i.picked_up_at, 'lotNumber', i.lot_number, 'expirationDate', i.expiration_date, 'ingredientCost', i.ingredient_cost, 'dispensingFee', i.dispensing_fee, 'totalPrice', i.total_price, 'copay', i.copay, 'insurancePaid', i.insurance_paid, 'patientPay', i.patient_pay, 'diagnosisCode', i.diagnosis_code, 'priorAuthRequired', i.prior_auth_required, 'priorAuthStatus', i.prior_auth_status, 'priorAuthNumber', i.prior_auth_number, 'labelOptions', i.label_options, 'status', i.status, 'cancelReason', i.cancel_reason, 'cancelledAt', i.cancelled_at, 'createdAt', i.created_at) AS item_json
           FROM pharmacy3.prescription_items i
        )
 SELECT p.id AS prescription_id,
    p.patient_id,
    p.prescriber_id,
    p.written_date,
    p.received_date,
    p.current_step,
    p.current_status,
    p.priority,
    p.source,
    p.note,
    p.intake_completed_at,
    p.pharmacist_assigned_at,
    p.pharmacist_reviewed_at,
    p.patient_info_requested_at,
    p.provider_info_requested_at,
    p.denial_recorded_at,
    p.fill_queue_assigned_at,
    p.filling_started_at,
    p.special_order_created_at,
    p.fill_completed_at,
    p.qa_started_at,
    p.qa_failed_at,
    p.ready_for_pickup_at,
    p.picked_up_at,
    p.delivery_dispatched_at,
    p.delivery_confirmed_at,
    p.completed_at,
    p.cancelled_at,
    p.created_at AS prescription_created_at,
    p.updated_at AS prescription_updated_at,
    COALESCE(jsonb_agg(items.item_json ORDER BY (items.item_json ->> 'itemId'::text)), '[]'::jsonb) AS items
   FROM (pharmacy3.prescriptions p
     LEFT JOIN items ON ((p.id = items.prescription_id)))
  GROUP BY p.id, p.patient_id, p.prescriber_id, p.written_date, p.received_date, p.current_step, p.current_status, p.priority, p.source, p.note, p.intake_completed_at, p.pharmacist_assigned_at, p.pharmacist_reviewed_at, p.patient_info_requested_at, p.provider_info_requested_at, p.denial_recorded_at, p.fill_queue_assigned_at, p.filling_started_at, p.special_order_created_at, p.fill_completed_at, p.qa_started_at, p.qa_failed_at, p.ready_for_pickup_at, p.picked_up_at, p.delivery_dispatched_at, p.delivery_confirmed_at, p.completed_at, p.cancelled_at, p.created_at, p.updated_at;


ALTER VIEW pharmacy3.v_prescription_items OWNER TO postgres;

--
-- Name: v_prescription_patient_insurance_prescribers; Type: VIEW; Schema: pharmacy3; Owner: postgres
--

CREATE VIEW pharmacy3.v_prescription_patient_insurance_prescribers AS
 SELECT vpi.prescription_id,
    vpi.patient_id,
    vpi.prescriber_id,
    vpi.written_date,
    vpi.received_date,
    vpi.current_step,
    vpi.current_status,
    vpi.priority,
    vpi.source,
    vpi.note,
    vpi.intake_completed_at,
    vpi.pharmacist_assigned_at,
    vpi.pharmacist_reviewed_at,
    vpi.patient_info_requested_at,
    vpi.provider_info_requested_at,
    vpi.denial_recorded_at,
    vpi.fill_queue_assigned_at,
    vpi.filling_started_at,
    vpi.special_order_created_at,
    vpi.fill_completed_at,
    vpi.qa_started_at,
    vpi.qa_failed_at,
    vpi.ready_for_pickup_at,
    vpi.picked_up_at,
    vpi.delivery_dispatched_at,
    vpi.delivery_confirmed_at,
    vpi.completed_at,
    vpi.cancelled_at,
    vpi.prescription_created_at,
    vpi.prescription_updated_at,
    vpi.items,
    vpat.mrn,
    vpat.first_name,
    vpat.last_name,
    vpat.dob,
    vpat.gender,
    vpat.contact,
    vpat.sensitive_data,
    vpat.encrypted_at,
    vpat.is_student_record,
    vpat.preferred_language,
    vpat.accessibility_preferences,
    vpat.patient_created_at,
    vpat.patient_updated_at,
    vpat.updated_by,
    vpat.insurances,
    pr.npi,
    pr.dea_number,
    pr.state_license_number,
    pr.upin,
    pr.taxonomy_code,
    pr.first_name AS prescriber_first_name,
    pr.last_name AS prescriber_last_name,
    pr.middle_name AS prescriber_middle_name,
    pr.suffix AS prescriber_suffix,
    pr.clinic_name,
    pr.clinic_contact,
    pr.contact AS prescriber_contact,
    pr.epcs_enabled,
    pr.erx_identifier,
    pr.ncpdp_provider_id,
    pr.active AS prescriber_active,
    pr.created_at AS prescriber_created_at,
    pr.updated_at AS prescriber_updated_at
   FROM ((pharmacy3.v_prescription_items vpi
     LEFT JOIN pharmacy3.v_patient_insurances vpat ON ((vpi.patient_id = vpat.patient_id)))
     LEFT JOIN pharmacy3.prescribers pr ON ((vpi.prescriber_id = pr.id)));


ALTER VIEW pharmacy3.v_prescription_patient_insurance_prescribers OWNER TO postgres;

--
-- Name: v_users_with_roles; Type: VIEW; Schema: pharmacy3; Owner: postgres
--

CREATE VIEW pharmacy3.v_users_with_roles AS
 SELECT u.id AS user_id,
    u.username,
    u.display_name,
    u.email,
    u.active AS user_active,
    u.created_at AS user_created_at,
    u.updated_at AS user_updated_at,
    COALESCE(json_agg(json_build_object('roleId', r.id, 'roleName', r.role_name) ORDER BY r.role_name) FILTER (WHERE (r.id IS NOT NULL)), '[]'::json) AS roles
   FROM ((pharmacy3.users u
     LEFT JOIN pharmacy3.user_roles ur ON ((ur.user_id = u.id)))
     LEFT JOIN pharmacy3.roles r ON ((r.id = ur.role_id)))
  GROUP BY u.id, u.username, u.display_name, u.email, u.active, u.created_at, u.updated_at
  ORDER BY u.username;


ALTER VIEW pharmacy3.v_users_with_roles OWNER TO postgres;

--
-- Name: workflow_transitions; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.workflow_transitions (
    id integer NOT NULL,
    from_step text,
    to_step text,
    result_status text
);


ALTER TABLE pharmacy3.workflow_transitions OWNER TO postgres;

--
-- Name: v_workflow_transitions; Type: VIEW; Schema: pharmacy3; Owner: postgres
--

CREATE VIEW pharmacy3.v_workflow_transitions AS
 SELECT from_step,
    COALESCE(jsonb_agg(to_step), '[]'::jsonb) AS to_steps
   FROM pharmacy3.workflow_transitions wt
  GROUP BY from_step
  ORDER BY from_step;


ALTER VIEW pharmacy3.v_workflow_transitions OWNER TO postgres;

--
-- Name: workflow_statuses; Type: TABLE; Schema: pharmacy3; Owner: postgres
--

CREATE TABLE pharmacy3.workflow_statuses (
    status_code text,
    description text,
    is_terminal boolean
);


ALTER TABLE pharmacy3.workflow_statuses OWNER TO postgres;

--
-- Name: workflow_transitions_id_seq; Type: SEQUENCE; Schema: pharmacy3; Owner: postgres
--

CREATE SEQUENCE pharmacy3.workflow_transitions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE pharmacy3.workflow_transitions_id_seq OWNER TO postgres;

--
-- Name: workflow_transitions_id_seq; Type: SEQUENCE OWNED BY; Schema: pharmacy3; Owner: postgres
--

ALTER SEQUENCE pharmacy3.workflow_transitions_id_seq OWNED BY pharmacy3.workflow_transitions.id;


--
-- Name: access_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.access_logs (
    id bigint NOT NULL,
    user_id uuid,
    patient_id uuid,
    entity_type text NOT NULL,
    entity_id uuid,
    action text NOT NULL,
    access_reason text,
    access_context jsonb,
    ip_address text,
    user_agent text,
    accessed_at timestamp with time zone DEFAULT now()
)
WITH (autovacuum_enabled='true', toast.autovacuum_enabled='true');


ALTER TABLE public.access_logs OWNER TO postgres;

--
-- Name: access_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.access_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.access_logs_id_seq OWNER TO postgres;

--
-- Name: access_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.access_logs_id_seq OWNED BY public.access_logs.id;


--
-- Name: alert_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.alert_logs (
    id bigint NOT NULL,
    alert_rule_id integer,
    prescription_id uuid,
    patient_id uuid,
    triggered_by uuid,
    context jsonb,
    action_taken text,
    override_reason text,
    created_at timestamp with time zone DEFAULT now(),
    suggested_alternatives jsonb,
    pharmacist_action text,
    resolved_at timestamp with time zone
);


ALTER TABLE public.alert_logs OWNER TO postgres;

--
-- Name: alert_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.alert_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.alert_logs_id_seq OWNER TO postgres;

--
-- Name: alert_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.alert_logs_id_seq OWNED BY public.alert_logs.id;


--
-- Name: alert_rules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.alert_rules (
    id integer NOT NULL,
    name text NOT NULL,
    description text,
    rule_json jsonb NOT NULL,
    severity text,
    active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.alert_rules OWNER TO postgres;

--
-- Name: alert_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.alert_rules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.alert_rules_id_seq OWNER TO postgres;

--
-- Name: alert_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.alert_rules_id_seq OWNED BY public.alert_rules.id;


--
-- Name: auth_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_logs (
    id bigint NOT NULL,
    user_id uuid,
    username text,
    event_type text,
    status text,
    ip_address text,
    user_agent text,
    metadata jsonb,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT auth_logs_event_type_check CHECK ((event_type = ANY (ARRAY['login'::text, 'logout'::text]))),
    CONSTRAINT auth_logs_status_check CHECK ((status = ANY (ARRAY['success'::text, 'failure'::text])))
);


ALTER TABLE public.auth_logs OWNER TO postgres;

--
-- Name: auth_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.auth_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.auth_logs_id_seq OWNER TO postgres;

--
-- Name: auth_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.auth_logs_id_seq OWNED BY public.auth_logs.id;


--
-- Name: awp_reclaims; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.awp_reclaims (
    id bigint NOT NULL,
    prescription_id uuid,
    amount numeric(12,2),
    processed_at timestamp with time zone DEFAULT now(),
    notes text
);


ALTER TABLE public.awp_reclaims OWNER TO postgres;

--
-- Name: awp_reclaims_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.awp_reclaims_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.awp_reclaims_id_seq OWNER TO postgres;

--
-- Name: awp_reclaims_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.awp_reclaims_id_seq OWNED BY public.awp_reclaims.id;


--
-- Name: barcode_labels; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.barcode_labels (
    id uuid NOT NULL,
    prescription_item_id uuid,
    barcode text NOT NULL,
    label_type text,
    generated_at timestamp with time zone DEFAULT now(),
    printed_by uuid,
    print_payload jsonb
);


ALTER TABLE public.barcode_labels OWNER TO postgres;

--
-- Name: claims; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.claims (
    id uuid NOT NULL,
    prescription_id uuid,
    payer_name text,
    claim_status text,
    submitted_at timestamp with time zone,
    response jsonb,
    fiscal_fields jsonb
);


ALTER TABLE public.claims OWNER TO postgres;

--
-- Name: consent_records; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.consent_records (
    id uuid NOT NULL,
    patient_id uuid,
    consent_type text,
    granted boolean,
    source text,
    recorded_by uuid,
    recorded_at timestamp with time zone DEFAULT now(),
    metadata jsonb
);


ALTER TABLE public.consent_records OWNER TO postgres;

--
-- Name: device_fingerprints; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.device_fingerprints (
    id uuid NOT NULL,
    station_id integer NOT NULL,
    fingerprint_hash character varying(64) NOT NULL,
    browser_user_agent text,
    screen_resolution character varying(50),
    timezone character varying(50),
    language character varying(20),
    canvas_fingerprint text,
    webgl_fingerprint character varying(255),
    department character varying(50) NOT NULL,
    location character varying(100),
    assigned_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_seen timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_active boolean DEFAULT true,
    access_count integer DEFAULT 1
);


ALTER TABLE public.device_fingerprints OWNER TO postgres;

--
-- Name: device_fingerprints_station_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.device_fingerprints_station_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.device_fingerprints_station_id_seq OWNER TO postgres;

--
-- Name: device_fingerprints_station_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.device_fingerprints_station_id_seq OWNED BY public.device_fingerprints.station_id;


--
-- Name: dir_fees; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dir_fees (
    id bigint NOT NULL,
    claim_id uuid NOT NULL,
    amount numeric(12,2) NOT NULL,
    reason text,
    recorded_at timestamp with time zone DEFAULT now() NOT NULL,
    reconciliation_period text,
    payer_name text,
    metadata jsonb,
    CONSTRAINT dir_fees_amount_check CHECK ((amount >= (0)::numeric))
);


ALTER TABLE public.dir_fees OWNER TO postgres;

--
-- Name: dir_fees_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dir_fees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.dir_fees_id_seq OWNER TO postgres;

--
-- Name: dir_fees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.dir_fees_id_seq OWNED BY public.dir_fees.id;


--
-- Name: dscsa_serials; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dscsa_serials (
    id uuid NOT NULL,
    batch_id uuid,
    serial_number text NOT NULL,
    status text DEFAULT 'in_stock'::text NOT NULL,
    trace_metadata jsonb,
    last_updated timestamp with time zone DEFAULT now()
);


ALTER TABLE public.dscsa_serials OWNER TO postgres;

--
-- Name: efax_attachments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.efax_attachments (
    id uuid NOT NULL,
    efax_job_id uuid NOT NULL,
    file_name text NOT NULL,
    file_type text NOT NULL,
    file_size_bytes bigint,
    encrypted_path text NOT NULL,
    checksum text,
    page_number integer,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT efax_attachments_file_type_check CHECK ((file_type = ANY (ARRAY['pdf'::text, 'tiff'::text, 'jpg'::text, 'png'::text])))
);


ALTER TABLE public.efax_attachments OWNER TO postgres;

--
-- Name: efax_incoming; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.efax_incoming (
    id uuid NOT NULL,
    from_fax_number text NOT NULL,
    from_name text,
    received_at timestamp with time zone DEFAULT now(),
    total_pages integer,
    file_path text NOT NULL,
    checksum text,
    linked_patient_id uuid,
    linked_prescription_id uuid,
    processed_by uuid,
    metadata jsonb
);


ALTER TABLE public.efax_incoming OWNER TO postgres;

--
-- Name: efax_jobs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.efax_jobs (
    id uuid NOT NULL,
    patient_id uuid,
    prescription_id uuid,
    user_id uuid,
    recipient_id uuid,
    direction text NOT NULL,
    subject text,
    fax_number text NOT NULL,
    provider_name text,
    status text DEFAULT 'queued'::text,
    total_pages integer DEFAULT 0,
    priority text DEFAULT 'normal'::text,
    created_at timestamp with time zone DEFAULT now(),
    sent_at timestamp with time zone,
    completed_at timestamp with time zone,
    error_message text,
    retry_count integer DEFAULT 0,
    metadata jsonb,
    claim_id uuid,
    CONSTRAINT efax_jobs_direction_check CHECK ((direction = ANY (ARRAY['outbound'::text, 'inbound'::text]))),
    CONSTRAINT efax_jobs_priority_check CHECK ((priority = ANY (ARRAY['low'::text, 'normal'::text, 'high'::text]))),
    CONSTRAINT efax_jobs_status_check CHECK ((status = ANY (ARRAY['queued'::text, 'sending'::text, 'sent'::text, 'failed'::text, 'received'::text])))
);


ALTER TABLE public.efax_jobs OWNER TO postgres;

--
-- Name: efax_recipients; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.efax_recipients (
    id uuid NOT NULL,
    name text NOT NULL,
    organization text,
    fax_number text NOT NULL,
    email text,
    contact_type text,
    is_verified boolean DEFAULT false,
    last_verified_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT efax_recipients_contact_type_check CHECK ((contact_type = ANY (ARRAY['prescriber'::text, 'payer'::text, 'facility'::text, 'lab'::text, 'other'::text])))
);


ALTER TABLE public.efax_recipients OWNER TO postgres;

--
-- Name: efax_status_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.efax_status_logs (
    id bigint NOT NULL,
    efax_job_id uuid NOT NULL,
    status text NOT NULL,
    message text,
    provider_code text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT efax_status_logs_status_check CHECK ((status = ANY (ARRAY['queued'::text, 'sending'::text, 'sent'::text, 'failed'::text, 'received'::text, 'rejected'::text])))
);


ALTER TABLE public.efax_status_logs OWNER TO postgres;

--
-- Name: efax_status_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.efax_status_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.efax_status_logs_id_seq OWNER TO postgres;

--
-- Name: efax_status_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.efax_status_logs_id_seq OWNED BY public.efax_status_logs.id;


--
-- Name: encryption_keys_meta; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.encryption_keys_meta (
    id integer NOT NULL,
    key_id text,
    purpose text,
    created_at timestamp with time zone DEFAULT now(),
    rotated_at timestamp with time zone,
    metadata jsonb
);


ALTER TABLE public.encryption_keys_meta OWNER TO postgres;

--
-- Name: encryption_keys_meta_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.encryption_keys_meta_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.encryption_keys_meta_id_seq OWNER TO postgres;

--
-- Name: encryption_keys_meta_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.encryption_keys_meta_id_seq OWNED BY public.encryption_keys_meta.id;


--
-- Name: fingerprint_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fingerprint_history (
    id uuid NOT NULL,
    station_id integer NOT NULL,
    old_fingerprint_hash character varying(64),
    new_fingerprint_hash character varying(64) NOT NULL,
    change_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    reason character varying(255),
    similarity_percentage numeric(5,2),
    browser_user_agent text,
    screen_resolution character varying(50),
    timezone character varying(50),
    notes text,
    verified_by character varying(100)
);


ALTER TABLE public.fingerprint_history OWNER TO postgres;

--
-- Name: fingerprint_history_station_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fingerprint_history_station_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fingerprint_history_station_id_seq OWNER TO postgres;

--
-- Name: fingerprint_history_station_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fingerprint_history_station_id_seq OWNED BY public.fingerprint_history.station_id;


--
-- Name: insurance_companies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.insurance_companies (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    type text,
    payer_id text,
    contact_number text,
    fax_number text,
    email text,
    address text,
    city text,
    state text,
    zip text,
    website text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT insurance_companies_type_check CHECK ((type = ANY (ARRAY['private'::text, 'medicare'::text, 'medicaid'::text, 'university'::text, 'other'::text])))
);


ALTER TABLE public.insurance_companies OWNER TO postgres;

--
-- Name: integration_events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.integration_events (
    id uuid NOT NULL,
    integration_id integer,
    event_type text,
    external_id text,
    payload jsonb,
    processed_at timestamp with time zone,
    status text
);


ALTER TABLE public.integration_events OWNER TO postgres;

--
-- Name: integrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.integrations (
    id integer NOT NULL,
    name text NOT NULL,
    type text,
    config jsonb,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.integrations OWNER TO postgres;

--
-- Name: integrations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.integrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.integrations_id_seq OWNER TO postgres;

--
-- Name: integrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.integrations_id_seq OWNED BY public.integrations.id;


--
-- Name: inventory_batches; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inventory_batches (
    id uuid NOT NULL,
    inventory_item_id uuid,
    lot_number text,
    expiry_date date,
    quantity_on_hand integer DEFAULT 0 NOT NULL,
    location text,
    wholesaler_id integer,
    created_at timestamp with time zone DEFAULT now(),
    last_order timestamp with time zone
);


ALTER TABLE public.inventory_batches OWNER TO postgres;

--
-- Name: inventory_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inventory_items (
    id uuid NOT NULL,
    ndc text,
    sku text,
    name text NOT NULL,
    strength text,
    form text,
    pack_size integer,
    reorder_rule_id integer,
    attributes jsonb,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.inventory_items OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    username public.citext NOT NULL,
    display_name text,
    email public.citext NOT NULL,
    role_id integer,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    last_login_at timestamp with time zone
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: v_user_access_summary_monthly; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_user_access_summary_monthly AS
 SELECT u.id AS user_id,
    u.username,
    date_trunc('month'::text, a.accessed_at) AS month,
    count(*) AS total_accesses,
    count(DISTINCT a.patient_id) AS distinct_patients_accessed,
    jsonb_object_agg(a.action, a.cnt) FILTER (WHERE (a.cnt IS NOT NULL)) AS action_breakdown,
    jsonb_object_agg(a.access_reason, a.reason_cnt) FILTER (WHERE (a.reason_cnt IS NOT NULL)) AS reason_breakdown
   FROM (( SELECT access_logs.user_id,
            access_logs.accessed_at,
            access_logs.action,
            access_logs.access_reason,
            access_logs.patient_id,
            count(*) AS cnt,
            count(*) AS reason_cnt
           FROM public.access_logs
          GROUP BY access_logs.user_id, access_logs.accessed_at, access_logs.action, access_logs.access_reason, access_logs.patient_id) a
     JOIN public.users u ON ((u.id = a.user_id)))
  GROUP BY u.id, u.username, (date_trunc('month'::text, a.accessed_at));


ALTER VIEW public.v_user_access_summary_monthly OWNER TO postgres;

--
-- Name: mv_user_access_summary_monthly; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW public.mv_user_access_summary_monthly AS
 SELECT user_id,
    username,
    month,
    total_accesses,
    distinct_patients_accessed,
    action_breakdown,
    reason_breakdown
   FROM public.v_user_access_summary_monthly
  WITH NO DATA;


ALTER MATERIALIZED VIEW public.mv_user_access_summary_monthly OWNER TO postgres;

--
-- Name: patient_aliases; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.patient_aliases (
    id integer NOT NULL,
    patient_id uuid,
    alias_type text,
    alias_value text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.patient_aliases OWNER TO postgres;

--
-- Name: patient_aliases_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.patient_aliases_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.patient_aliases_id_seq OWNER TO postgres;

--
-- Name: patient_aliases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.patient_aliases_id_seq OWNED BY public.patient_aliases.id;


--
-- Name: patient_insurances; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.patient_insurances (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    patient_id uuid NOT NULL,
    insurance_company_id uuid NOT NULL,
    member_id text NOT NULL,
    group_number text,
    plan_name text,
    effective_date date,
    expiration_date date,
    coverage_type text,
    copay_fixed numeric(10,2),
    copay_percent numeric(5,2),
    deductible numeric(10,2),
    out_of_pocket_max numeric(10,2),
    status text DEFAULT 'active'::text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT patient_insurances_coverage_type_check CHECK ((coverage_type = ANY (ARRAY['primary'::text, 'secondary'::text, 'tertiary'::text]))),
    CONSTRAINT patient_insurances_status_check CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text])))
);


ALTER TABLE public.patient_insurances OWNER TO postgres;

--
-- Name: patients; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.patients (
    id uuid NOT NULL,
    mrn text,
    first_name text NOT NULL,
    last_name text NOT NULL,
    dob date,
    gender text,
    contact jsonb,
    sensitive_data bytea,
    is_student_record boolean DEFAULT false,
    preferred_language text,
    accessibility_preferences jsonb,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.patients OWNER TO postgres;

--
-- Name: payments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payments (
    id uuid NOT NULL,
    pos_transaction_id uuid,
    payment_method text,
    amount numeric(12,2),
    payment_meta jsonb
);


ALTER TABLE public.payments OWNER TO postgres;

--
-- Name: pdmp_queries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pdmp_queries (
    id uuid NOT NULL,
    patient_id uuid NOT NULL,
    user_id uuid NOT NULL,
    prescription_id uuid,
    state text NOT NULL,
    query_reason text NOT NULL,
    status text DEFAULT 'pending'::text,
    response_code text,
    response_payload jsonb,
    transmitted_at timestamp with time zone DEFAULT now(),
    completed_at timestamp with time zone,
    error_message text,
    created_at timestamp with time zone DEFAULT now()
)
WITH (autovacuum_enabled='true', toast.autovacuum_enabled='true');


ALTER TABLE public.pdmp_queries OWNER TO postgres;

--
-- Name: pharmacists; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pharmacists (
    id uuid NOT NULL,
    user_id uuid,
    license_number text,
    license_state text,
    active boolean DEFAULT true
);


ALTER TABLE public.pharmacists OWNER TO postgres;

--
-- Name: pos_signatures; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pos_signatures (
    id uuid NOT NULL,
    pos_transaction_id uuid,
    station_id text,
    signature_data bytea,
    signed_by uuid,
    signed_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.pos_signatures OWNER TO postgres;

--
-- Name: pos_transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pos_transactions (
    id uuid NOT NULL,
    prescription_id uuid,
    patient_id uuid,
    station_id text,
    total_amount numeric(12,2) NOT NULL,
    status text DEFAULT 'pending'::text,
    created_at timestamp with time zone DEFAULT now(),
    metadata jsonb
);


ALTER TABLE public.pos_transactions OWNER TO postgres;

--
-- Name: prescription_audit; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.prescription_audit (
    id bigint NOT NULL,
    prescription_id uuid,
    user_id uuid,
    action text NOT NULL,
    diff jsonb,
    reason text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.prescription_audit OWNER TO postgres;

--
-- Name: prescription_audit_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.prescription_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.prescription_audit_id_seq OWNER TO postgres;

--
-- Name: prescription_audit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.prescription_audit_id_seq OWNED BY public.prescription_audit.id;


--
-- Name: prescription_claims; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.prescription_claims (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    prescription_id uuid NOT NULL,
    patient_insurance_id uuid,
    claim_number text,
    claim_status text,
    claim_date timestamp with time zone DEFAULT now(),
    billed_amount numeric(10,2),
    reimbursed_amount numeric(10,2),
    patient_responsibility numeric(10,2),
    rejection_code text,
    rejection_reason text,
    prior_authorization_number text,
    adjudication_data jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.prescription_claims OWNER TO postgres;

--
-- Name: prescription_copays; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.prescription_copays (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    prescription_id uuid NOT NULL,
    patient_id uuid NOT NULL,
    insurance_company_id uuid,
    claim_id uuid,
    copay_amount numeric(10,2) NOT NULL,
    copay_status text DEFAULT 'unpaid'::text,
    payment_method text,
    payment_reference text,
    paid_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT prescription_copays_copay_status_check CHECK ((copay_status = ANY (ARRAY['unpaid'::text, 'paid'::text, 'waived'::text, 'billed'::text]))),
    CONSTRAINT prescription_copays_payment_method_check CHECK ((payment_method = ANY (ARRAY['cash'::text, 'card'::text, 'insurance'::text, 'copay assistance'::text, 'other'::text])))
);


ALTER TABLE public.prescription_copays OWNER TO postgres;

--
-- Name: prescription_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.prescription_items (
    id uuid NOT NULL,
    prescription_id uuid,
    inventory_item_id uuid,
    quantity integer NOT NULL,
    days_supply integer,
    sig text,
    refills_allowed integer DEFAULT 0,
    is_controlled boolean DEFAULT false,
    label_options jsonb,
    status text DEFAULT 'active'::text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.prescription_items OWNER TO postgres;

--
-- Name: prescription_transfers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.prescription_transfers (
    id uuid NOT NULL,
    prescription_id uuid,
    transfer_type text,
    provider text,
    external_id text,
    payload jsonb,
    transmitted_at timestamp with time zone,
    status text,
    signed boolean DEFAULT false
);


ALTER TABLE public.prescription_transfers OWNER TO postgres;

--
-- Name: prescription_workflow_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.prescription_workflow_logs (
    id bigint NOT NULL,
    prescription_id uuid NOT NULL,
    from_status text,
    to_status text NOT NULL,
    queue_name text,
    changed_by uuid,
    change_reason text,
    changed_at timestamp with time zone DEFAULT now(),
    metadata jsonb
);


ALTER TABLE public.prescription_workflow_logs OWNER TO postgres;

--
-- Name: prescription_workflow_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.prescription_workflow_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.prescription_workflow_logs_id_seq OWNER TO postgres;

--
-- Name: prescription_workflow_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.prescription_workflow_logs_id_seq OWNED BY public.prescription_workflow_logs.id;


--
-- Name: prescriptions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.prescriptions (
    id uuid NOT NULL,
    patient_id uuid,
    prescriber_name text,
    prescriber_dea text,
    issue_date timestamp with time zone DEFAULT now(),
    status text DEFAULT 'pending'::text NOT NULL,
    workflow_step_id integer NOT NULL,
    priority text DEFAULT 'normal'::text,
    notes text,
    metadata jsonb,
    created_at timestamp with time zone DEFAULT now(),
    queue_name text,
    assigned_to uuid,
    last_status_update timestamp with time zone DEFAULT now(),
    estimated_ready_time timestamp with time zone,
    pickup_time timestamp with time zone,
    completion_time timestamp with time zone,
    CONSTRAINT prescriptions_priority_check CHECK ((priority = ANY (ARRAY['low'::text, 'normal'::text, 'high'::text, 'urgent'::text])))
);


ALTER TABLE public.prescriptions OWNER TO postgres;

--
-- Name: profit_audit_warnings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profit_audit_warnings (
    id bigint NOT NULL,
    related_object_type text,
    related_object_id uuid,
    warning_code text,
    description text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.profit_audit_warnings OWNER TO postgres;

--
-- Name: profit_audit_warnings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.profit_audit_warnings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.profit_audit_warnings_id_seq OWNER TO postgres;

--
-- Name: profit_audit_warnings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.profit_audit_warnings_id_seq OWNED BY public.profit_audit_warnings.id;


--
-- Name: purchase_orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.purchase_orders (
    id uuid NOT NULL,
    wholesaler_id integer,
    created_by uuid,
    status text DEFAULT 'open'::text,
    ordered_at timestamp with time zone DEFAULT now(),
    expected_arrival date,
    payload jsonb
);


ALTER TABLE public.purchase_orders OWNER TO postgres;

--
-- Name: queues; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.queues (
    id integer NOT NULL,
    name text NOT NULL,
    description text,
    config jsonb
);


ALTER TABLE public.queues OWNER TO postgres;

--
-- Name: queues_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.queues_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.queues_id_seq OWNER TO postgres;

--
-- Name: queues_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.queues_id_seq OWNED BY public.queues.id;


--
-- Name: reorder_rules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reorder_rules (
    id integer NOT NULL,
    inventory_item_id uuid,
    min_level integer NOT NULL,
    max_level integer NOT NULL,
    preferred_wholesalers integer[]
);


ALTER TABLE public.reorder_rules OWNER TO postgres;

--
-- Name: reorder_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.reorder_rules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reorder_rules_id_seq OWNER TO postgres;

--
-- Name: reorder_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.reorder_rules_id_seq OWNED BY public.reorder_rules.id;


--
-- Name: reports; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reports (
    id uuid NOT NULL,
    owner_id uuid,
    name text NOT NULL,
    description text,
    filters jsonb,
    schedule jsonb,
    last_run timestamp with time zone
);


ALTER TABLE public.reports OWNER TO postgres;

--
-- Name: role_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.role_permissions (
    id integer NOT NULL,
    role_id integer NOT NULL,
    permission_key text NOT NULL,
    granted_by uuid,
    granted_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.role_permissions OWNER TO postgres;

--
-- Name: role_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.role_permissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.role_permissions_id_seq OWNER TO postgres;

--
-- Name: role_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.role_permissions_id_seq OWNED BY public.role_permissions.id;


--
-- Name: role_permissions_role_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.role_permissions_role_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.role_permissions_role_id_seq OWNER TO postgres;

--
-- Name: role_permissions_role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.role_permissions_role_id_seq OWNED BY public.role_permissions.role_id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    id integer NOT NULL,
    name text NOT NULL,
    description text
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.roles_id_seq OWNER TO postgres;

--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: stations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.stations (
    id integer NOT NULL,
    station_prefix character varying(10) NOT NULL,
    department character varying(50) NOT NULL,
    location character varying(100),
    starting_number integer DEFAULT 1,
    current_number integer DEFAULT 1,
    max_stations integer,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.stations OWNER TO postgres;

--
-- Name: stations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.stations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.stations_id_seq OWNER TO postgres;

--
-- Name: stations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.stations_id_seq OWNED BY public.stations.id;


--
-- Name: task_routing; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.task_routing (
    id integer NOT NULL,
    queue_id integer,
    rule_order integer DEFAULT 0,
    rule jsonb
);


ALTER TABLE public.task_routing OWNER TO postgres;

--
-- Name: task_routing_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.task_routing_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.task_routing_id_seq OWNER TO postgres;

--
-- Name: task_routing_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.task_routing_id_seq OWNED BY public.task_routing.id;


--
-- Name: tasks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tasks (
    id uuid NOT NULL,
    object_type text NOT NULL,
    object_id uuid NOT NULL,
    workflow_id integer,
    step_id integer,
    queue_id integer,
    assignee uuid,
    status text DEFAULT 'open'::text,
    payload jsonb,
    priority integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    due_at timestamp with time zone
);


ALTER TABLE public.tasks OWNER TO postgres;

--
-- Name: user_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_permissions (
    id integer NOT NULL,
    user_id uuid,
    permission_key text NOT NULL,
    granted boolean DEFAULT true NOT NULL,
    granted_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.user_permissions OWNER TO postgres;

--
-- Name: user_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_permissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_permissions_id_seq OWNER TO postgres;

--
-- Name: user_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_permissions_id_seq OWNED BY public.user_permissions.id;


--
-- Name: user_sso; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_sso (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    provider text NOT NULL,
    external_id text NOT NULL,
    metadata jsonb
);


ALTER TABLE public.user_sso OWNER TO postgres;

--
-- Name: v_alert_log_details; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_alert_log_details AS
 SELECT al.id AS alert_log_id,
    al.created_at AS alert_created_at,
    ar.id AS alert_rule_id,
    ar.name AS rule_name,
    ar.description AS rule_description,
    ar.rule_json,
    ar.severity AS rule_severity,
    ar.active AS rule_active,
    p.id AS patient_id,
    p.mrn AS patient_mrn,
    p.first_name AS patient_first_name,
    p.last_name AS patient_last_name,
    p.dob AS patient_dob,
    p.gender AS patient_gender,
    pr.id AS prescription_id,
    pr.prescriber_name,
    pr.issue_date AS prescription_issue_date,
    pr.status AS prescription_status,
    pr.priority AS prescription_priority,
    pr.metadata AS prescription_metadata,
    pr.queue_name,
    pr.assigned_to,
    al.triggered_by AS triggered_by_user_id,
    al.context,
    al.action_taken,
    al.override_reason,
    al.suggested_alternatives,
    al.pharmacist_action,
    al.resolved_at
   FROM (((public.alert_logs al
     LEFT JOIN public.alert_rules ar ON ((al.alert_rule_id = ar.id)))
     LEFT JOIN public.patients p ON ((al.patient_id = p.id)))
     LEFT JOIN public.prescriptions pr ON ((al.prescription_id = pr.id)));


ALTER VIEW public.v_alert_log_details OWNER TO postgres;

--
-- Name: v_claim_processing; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_claim_processing AS
 SELECT c.id AS claim_id,
    pc.id AS prescription_claim_id,
    c.prescription_id,
    p.id AS patient_id,
    p.mrn,
    p.first_name,
    p.last_name,
    concat(p.first_name, ' ', p.last_name) AS patient_name,
    p.dob,
    p.gender,
    pc.patient_insurance_id,
    pc.claim_number,
    c.payer_name,
    COALESCE(pc.claim_status, c.claim_status) AS claim_status,
    pc.prior_authorization_number,
    pc.rejection_code,
    pc.rejection_reason,
        CASE
            WHEN (pc.rejection_code IS NOT NULL) THEN true
            ELSE false
        END AS has_rejection,
    pc.billed_amount,
    pc.reimbursed_amount,
    pc.patient_responsibility,
    COALESCE(pc.billed_amount, (0)::numeric) AS billed_amount_safe,
    COALESCE(pc.reimbursed_amount, (0)::numeric) AS reimbursed_amount_safe,
    COALESCE(pc.patient_responsibility, (0)::numeric) AS patient_responsibility_safe,
    (COALESCE(pc.billed_amount, (0)::numeric) - COALESCE(pc.reimbursed_amount, (0)::numeric)) AS write_off_amount,
        CASE
            WHEN ((pc.billed_amount IS NOT NULL) AND (pc.billed_amount > (0)::numeric)) THEN round(((COALESCE(pc.reimbursed_amount, (0)::numeric) / pc.billed_amount) * (100)::numeric), 2)
            ELSE NULL::numeric
        END AS reimbursement_rate_percentage,
        CASE
            WHEN ((pc.billed_amount IS NOT NULL) AND (pc.billed_amount > (0)::numeric)) THEN round((((COALESCE(pc.billed_amount, (0)::numeric) - COALESCE(pc.reimbursed_amount, (0)::numeric)) / pc.billed_amount) * (100)::numeric), 2)
            ELSE NULL::numeric
        END AS write_off_percentage,
    c.response AS claim_payer_response,
    pc.adjudication_data,
    c.fiscal_fields AS claim_fiscal_fields,
    c.submitted_at AS claim_submitted_at,
    pc.claim_date,
    pc.created_at AS prescription_claim_created_at,
    pc.updated_at AS prescription_claim_updated_at,
        CASE
            WHEN (c.submitted_at IS NOT NULL) THEN (EXTRACT(day FROM (now() - c.submitted_at)))::integer
            ELSE (EXTRACT(day FROM (now() - pc.claim_date)))::integer
        END AS days_in_processing,
        CASE
            WHEN (COALESCE(pc.claim_status, c.claim_status) = 'approved'::text) THEN 'APPROVED'::text
            WHEN (COALESCE(pc.claim_status, c.claim_status) = 'rejected'::text) THEN 'REJECTED'::text
            WHEN (COALESCE(pc.claim_status, c.claim_status) = 'pending'::text) THEN 'PENDING'::text
            WHEN (COALESCE(pc.claim_status, c.claim_status) = 'submitted'::text) THEN 'SUBMITTED'::text
            WHEN (COALESCE(pc.claim_status, c.claim_status) = 'reversed'::text) THEN 'REVERSED'::text
            ELSE 'UNKNOWN'::text
        END AS claim_outcome,
        CASE
            WHEN (COALESCE(pc.claim_status, c.claim_status) = 'rejected'::text) THEN 'HIGH'::text
            WHEN ((COALESCE(pc.claim_status, c.claim_status) = 'pending'::text) AND (EXTRACT(day FROM (now() - COALESCE(c.submitted_at, pc.claim_date))) > (30)::numeric)) THEN 'HIGH'::text
            WHEN (COALESCE(pc.claim_status, c.claim_status) = 'pending'::text) THEN 'MEDIUM'::text
            WHEN (COALESCE(pc.claim_status, c.claim_status) = 'approved'::text) THEN 'LOW'::text
            ELSE 'MEDIUM'::text
        END AS processing_priority,
        CASE
            WHEN (COALESCE(pc.claim_status, c.claim_status) = 'rejected'::text) THEN 'APPEAL_OR_RESUBMIT'::text
            WHEN ((COALESCE(pc.claim_status, c.claim_status) = 'pending'::text) AND (EXTRACT(day FROM (now() - COALESCE(c.submitted_at, pc.claim_date))) > (30)::numeric)) THEN 'FOLLOW_UP'::text
            WHEN ((pc.prior_authorization_number IS NULL) AND (COALESCE(pc.claim_status, c.claim_status) = ANY (ARRAY['pending'::text, 'submitted'::text]))) THEN 'OBTAIN_AUTH'::text
            WHEN ((COALESCE(pc.claim_status, c.claim_status) = 'approved'::text) AND (pc.patient_responsibility IS NOT NULL) AND (pc.patient_responsibility > (0)::numeric)) THEN 'COLLECT_COPAY'::text
            ELSE 'MONITOR'::text
        END AS recommended_action,
    (p.contact ->> 'phone'::text) AS patient_phone,
    (p.contact ->> 'email'::text) AS patient_email,
    (p.contact ->> 'preferred_contact_method'::text) AS preferred_contact_method,
    p.preferred_language,
    p.accessibility_preferences
   FROM (((public.prescription_claims pc
     LEFT JOIN public.claims c ON ((pc.prescription_id = c.prescription_id)))
     LEFT JOIN public.prescriptions pr ON ((pc.prescription_id = pr.id)))
     LEFT JOIN public.patients p ON ((pr.patient_id = p.id)))
  ORDER BY
        CASE
            WHEN (COALESCE(pc.claim_status, c.claim_status) = 'rejected'::text) THEN 1
            WHEN ((COALESCE(pc.claim_status, c.claim_status) = 'pending'::text) AND (EXTRACT(day FROM (now() - COALESCE(c.submitted_at, pc.claim_date))) > (30)::numeric)) THEN 2
            ELSE 3
        END, COALESCE(c.submitted_at, pc.claim_date) DESC NULLS LAST;


ALTER VIEW public.v_claim_processing OWNER TO postgres;

--
-- Name: v_claims_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_claims_summary AS
 SELECT COALESCE(pc.claim_status, c.claim_status) AS claim_status,
    count(*) AS total_claims,
    count(
        CASE
            WHEN (pc.claim_status = 'approved'::text) THEN 1
            ELSE NULL::integer
        END) AS approved_count,
    count(
        CASE
            WHEN (pc.claim_status = 'rejected'::text) THEN 1
            ELSE NULL::integer
        END) AS rejected_count,
    count(
        CASE
            WHEN (pc.claim_status = 'pending'::text) THEN 1
            ELSE NULL::integer
        END) AS pending_count,
    sum(pc.billed_amount) AS total_billed,
    sum(pc.reimbursed_amount) AS total_reimbursed,
    sum(pc.patient_responsibility) AS total_patient_responsibility,
    sum((COALESCE(pc.billed_amount, (0)::numeric) - COALESCE(pc.reimbursed_amount, (0)::numeric))) AS total_write_off,
    round(avg(pc.billed_amount), 2) AS avg_billed_amount,
    round(avg(pc.reimbursed_amount), 2) AS avg_reimbursed_amount,
        CASE
            WHEN (avg(pc.billed_amount) > (0)::numeric) THEN round(((avg(COALESCE(pc.reimbursed_amount, (0)::numeric)) / avg(pc.billed_amount)) * (100)::numeric), 2)
            ELSE NULL::numeric
        END AS avg_reimbursement_percentage,
    c.payer_name,
    count(DISTINCT c.payer_name) AS unique_payers
   FROM (public.prescription_claims pc
     LEFT JOIN public.claims c ON ((pc.prescription_id = c.prescription_id)))
  GROUP BY COALESCE(pc.claim_status, c.claim_status), c.payer_name
  ORDER BY (count(*)) DESC, COALESCE(pc.claim_status, c.claim_status);


ALTER VIEW public.v_claims_summary OWNER TO postgres;

--
-- Name: v_daily_transaction_report; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_daily_transaction_report AS
 SELECT pt.station_id,
    date(pt.created_at) AS transaction_date,
    pt.status,
    count(DISTINCT pt.id) AS transaction_count,
    sum(pt.total_amount) AS total_transaction_amount,
    count(DISTINCT p.id) AS total_payments,
    sum(p.amount) AS total_paid_amount,
    (sum(pt.total_amount) - sum(COALESCE(p.amount, (0)::numeric))) AS total_due_amount,
    round(((sum(COALESCE(p.amount, (0)::numeric)) / NULLIF(sum(pt.total_amount), (0)::numeric)) * (100)::numeric), 2) AS payment_percentage,
    count(DISTINCT
        CASE
            WHEN (pt.status = 'completed'::text) THEN pt.id
            ELSE NULL::uuid
        END) AS completed_transactions,
    count(DISTINCT
        CASE
            WHEN (pt.status = 'pending'::text) THEN pt.id
            ELSE NULL::uuid
        END) AS pending_transactions,
    count(DISTINCT
        CASE
            WHEN (pt.status = 'refunded'::text) THEN pt.id
            ELSE NULL::uuid
        END) AS refunded_transactions
   FROM (public.pos_transactions pt
     LEFT JOIN public.payments p ON ((pt.id = p.pos_transaction_id)))
  GROUP BY pt.station_id, (date(pt.created_at)), pt.status
  ORDER BY (date(pt.created_at)) DESC, pt.station_id;


ALTER VIEW public.v_daily_transaction_report OWNER TO postgres;

--
-- Name: v_dir_fee_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_dir_fee_summary AS
 SELECT df.id AS dir_fee_id,
    df.claim_id,
    df.amount AS dir_fee_amount,
    df.reason AS dir_fee_reason,
    df.recorded_at AS dir_fee_recorded_at,
    df.reconciliation_period,
    df.payer_name AS dir_fee_payer_name,
    df.metadata AS dir_fee_metadata,
    c.payer_name AS claim_payer_name,
    c.claim_status,
    c.submitted_at AS claim_submitted_at,
    c.fiscal_fields AS claim_fiscal_fields,
    c.prescription_id,
        CASE
            WHEN (c.fiscal_fields ? 'reimbursement_amount'::text) THEN ((c.fiscal_fields ->> 'reimbursement_amount'::text))::numeric
            ELSE NULL::numeric
        END AS claim_reimbursement_amount,
        CASE
            WHEN (c.fiscal_fields ? 'plan_paid'::text) THEN ((c.fiscal_fields ->> 'plan_paid'::text))::numeric
            ELSE NULL::numeric
        END AS claim_plan_paid,
        CASE
            WHEN (c.fiscal_fields ? 'patient_paid'::text) THEN ((c.fiscal_fields ->> 'patient_paid'::text))::numeric
            ELSE NULL::numeric
        END AS claim_patient_paid,
        CASE
            WHEN (c.fiscal_fields ? 'reimbursement_amount'::text) THEN (((c.fiscal_fields ->> 'reimbursement_amount'::text))::numeric - df.amount)
            ELSE NULL::numeric
        END AS net_reimbursement_after_dir_fee
   FROM (public.dir_fees df
     LEFT JOIN public.claims c ON ((df.claim_id = c.id)))
  ORDER BY df.recorded_at DESC;


ALTER VIEW public.v_dir_fee_summary OWNER TO postgres;

--
-- Name: v_efax_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_efax_summary AS
 SELECT e.id AS efax_job_id,
    e.direction,
    e.status,
    e.patient_id,
    e.prescription_id,
    e.user_id,
    e.fax_number,
    e.subject,
    e.total_pages,
    e.created_at,
    e.sent_at,
    e.completed_at,
    count(a.id) AS attachments_count,
    count(sl.id) FILTER (WHERE (sl.status = 'failed'::text)) AS failures,
    max(sl.created_at) AS last_status_update
   FROM ((public.efax_jobs e
     LEFT JOIN public.efax_attachments a ON ((a.efax_job_id = e.id)))
     LEFT JOIN public.efax_status_logs sl ON ((sl.efax_job_id = e.id)))
  GROUP BY e.id, e.direction, e.status, e.patient_id, e.prescription_id, e.user_id, e.fax_number, e.subject, e.total_pages, e.created_at, e.sent_at, e.completed_at;


ALTER VIEW public.v_efax_summary OWNER TO postgres;

--
-- Name: v_insurance_compliance_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_insurance_compliance_summary AS
 SELECT i.name AS insurance_company,
    count(DISTINCT pi.patient_id) AS patients_covered,
    count(DISTINCT c.id) AS claims_processed,
    sum(c.billed_amount) AS total_billed,
    sum(c.reimbursed_amount) AS total_reimbursed,
    sum(cp.copay_amount) FILTER (WHERE (cp.copay_status = 'paid'::text)) AS total_copays_collected,
    sum(cp.copay_amount) FILTER (WHERE (cp.copay_status = 'unpaid'::text)) AS total_copays_pending,
    count(DISTINCT
        CASE
            WHEN (c.claim_status = 'rejected'::text) THEN c.id
            ELSE NULL::uuid
        END) AS rejected_claims,
    count(DISTINCT
        CASE
            WHEN (c.claim_status = 'approved'::text) THEN c.id
            ELSE NULL::uuid
        END) AS approved_claims
   FROM (((public.insurance_companies i
     LEFT JOIN public.patient_insurances pi ON ((pi.insurance_company_id = i.id)))
     LEFT JOIN public.prescription_claims c ON ((c.patient_insurance_id = pi.id)))
     LEFT JOIN public.prescription_copays cp ON ((cp.claim_id = c.id)))
  GROUP BY i.name;


ALTER VIEW public.v_insurance_compliance_summary OWNER TO postgres;

--
-- Name: v_inventory_overview; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_inventory_overview AS
 SELECT ii.id AS item_id,
    ii.ndc,
    ii.sku,
    ii.name,
    ii.strength,
    ii.form,
    ii.pack_size,
    ii.attributes,
    ib.id AS batch_id,
    ib.lot_number,
    ib.expiry_date,
    ib.quantity_on_hand,
    ib.location,
    ib.wholesaler_id,
    ib.last_order,
    rr.min_level,
    rr.max_level,
    rr.preferred_wholesalers,
    (ib.quantity_on_hand < rr.min_level) AS needs_reorder,
    (rr.max_level - ib.quantity_on_hand) AS reorder_quantity,
        CASE
            WHEN (ib.expiry_date IS NOT NULL) THEN (ib.expiry_date - CURRENT_DATE)
            ELSE NULL::integer
        END AS days_until_expiry,
        CASE
            WHEN ((ib.expiry_date IS NOT NULL) AND ((ib.expiry_date - CURRENT_DATE) < 30)) THEN 'URGENT'::text
            WHEN ((ib.expiry_date IS NOT NULL) AND ((ib.expiry_date - CURRENT_DATE) < 90)) THEN 'WARNING'::text
            WHEN (ib.expiry_date IS NOT NULL) THEN 'OK'::text
            ELSE 'NO_EXPIRY'::text
        END AS expiry_status,
    (CURRENT_DATE - date(ib.last_order)) AS days_since_last_order,
        CASE
            WHEN (ib.last_order IS NULL) THEN 'NEVER_ORDERED'::text
            WHEN ((CURRENT_DATE - date(ib.last_order)) < 7) THEN 'RECENTLY_ORDERED'::text
            WHEN ((CURRENT_DATE - date(ib.last_order)) < 30) THEN 'ORDERED_THIS_MONTH'::text
            WHEN ((CURRENT_DATE - date(ib.last_order)) < 90) THEN 'ORDERED_THIS_QUARTER'::text
            ELSE 'LONG_TIME_AGO'::text
        END AS order_frequency_status,
    ii.created_at AS item_created_at,
    ib.created_at AS batch_created_at
   FROM ((public.inventory_batches ib
     LEFT JOIN public.inventory_items ii ON ((ib.inventory_item_id = ii.id)))
     LEFT JOIN public.reorder_rules rr ON ((ii.id = rr.inventory_item_id)))
  ORDER BY ii.name, ib.lot_number;


ALTER VIEW public.v_inventory_overview OWNER TO postgres;

--
-- Name: v_inventory_reorder_candidates_base; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_inventory_reorder_candidates_base AS
 SELECT i.id AS inventory_item_id,
    i.name AS item_name,
    i.ndc,
    r.min_level,
    r.max_level,
    COALESCE(sum(b.quantity_on_hand), (0)::bigint) AS total_on_hand,
    GREATEST((r.min_level - COALESCE(sum(b.quantity_on_hand), (0)::bigint)), (0)::bigint) AS shortage_units,
    GREATEST((r.max_level - COALESCE(sum(b.quantity_on_hand), (0)::bigint)), (0)::bigint) AS suggested_order_qty,
    r.preferred_wholesalers[1] AS primary_wholesaler_id
   FROM ((public.inventory_items i
     JOIN public.reorder_rules r ON ((r.inventory_item_id = i.id)))
     LEFT JOIN public.inventory_batches b ON ((b.inventory_item_id = i.id)))
  GROUP BY i.id, i.name, i.ndc, r.min_level, r.max_level, r.preferred_wholesalers
 HAVING ((COALESCE(sum(b.quantity_on_hand), (0)::bigint) < r.min_level) AND (GREATEST((r.max_level - COALESCE(sum(b.quantity_on_hand), (0)::bigint)), (0)::bigint) > 0));


ALTER VIEW public.v_inventory_reorder_candidates_base OWNER TO postgres;

--
-- Name: v_inventory_reorder_candidates; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_inventory_reorder_candidates AS
 SELECT inventory_item_id,
    item_name,
    ndc,
    min_level,
    max_level,
    total_on_hand,
    shortage_units,
    suggested_order_qty,
    primary_wholesaler_id
   FROM public.v_inventory_reorder_candidates_base c
  WHERE (NOT (EXISTS ( SELECT 1
           FROM public.purchase_orders po
          WHERE ((po.wholesaler_id = c.primary_wholesaler_id) AND (po.status = ANY (ARRAY['open'::text, 'submitted'::text])) AND (po.payload @> jsonb_build_object('lines', jsonb_build_array(jsonb_build_object('inventory_item_id', (c.inventory_item_id)::text))))))));


ALTER VIEW public.v_inventory_reorder_candidates OWNER TO postgres;

--
-- Name: v_outstanding_payments; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_outstanding_payments AS
 SELECT pt.id AS transaction_id,
    pt.prescription_id,
    pt.patient_id,
    pt.station_id,
    pt.status,
    pt.total_amount,
    COALESCE(sum(p.amount), (0)::numeric) AS total_paid,
    (pt.total_amount - COALESCE(sum(p.amount), (0)::numeric)) AS amount_due,
    round((((pt.total_amount - COALESCE(sum(p.amount), (0)::numeric)) / NULLIF(pt.total_amount, (0)::numeric)) * (100)::numeric), 2) AS percentage_due,
    pt.created_at,
    (CURRENT_DATE - (pt.created_at)::date) AS days_outstanding,
        CASE
            WHEN ((CURRENT_DATE - (pt.created_at)::date) > 90) THEN 'OVERDUE_90_DAYS'::text
            WHEN ((CURRENT_DATE - (pt.created_at)::date) > 60) THEN 'OVERDUE_60_DAYS'::text
            WHEN ((CURRENT_DATE - (pt.created_at)::date) > 30) THEN 'OVERDUE_30_DAYS'::text
            WHEN ((CURRENT_DATE - (pt.created_at)::date) > 7) THEN 'OVERDUE_7_DAYS'::text
            ELSE 'CURRENT'::text
        END AS aging_bucket,
    string_agg(DISTINCT p.payment_method, ', '::text ORDER BY p.payment_method) AS payments_received,
    count(DISTINCT p.id) AS payment_count
   FROM (public.pos_transactions pt
     LEFT JOIN public.payments p ON ((pt.id = p.pos_transaction_id)))
  WHERE (pt.status <> 'refunded'::text)
  GROUP BY pt.id, pt.prescription_id, pt.patient_id, pt.station_id, pt.status, pt.total_amount, pt.created_at
 HAVING ((pt.total_amount - COALESCE(sum(p.amount), (0)::numeric)) > (0)::numeric)
  ORDER BY (CURRENT_DATE - (pt.created_at)::date) DESC, (pt.total_amount - COALESCE(sum(p.amount), (0)::numeric)) DESC;


ALTER VIEW public.v_outstanding_payments OWNER TO postgres;

--
-- Name: v_patient_access_audit; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_patient_access_audit AS
 SELECT p.id AS patient_id,
    p.mrn,
    p.is_student_record,
    u.username AS accessed_by,
    a.action,
    a.access_reason,
    count(*) AS access_count,
    min(a.accessed_at) AS first_access,
    max(a.accessed_at) AS last_access
   FROM ((public.access_logs a
     JOIN public.patients p ON ((p.id = a.patient_id)))
     JOIN public.users u ON ((u.id = a.user_id)))
  GROUP BY p.id, p.mrn, p.is_student_record, u.username, a.action, a.access_reason;


ALTER VIEW public.v_patient_access_audit OWNER TO postgres;

--
-- Name: v_patient_insurance_details; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_patient_insurance_details AS
 SELECT p.id AS patient_id,
    p.mrn,
    p.first_name,
    p.last_name,
    p.dob,
    p.gender,
    p.preferred_language,
    p.is_student_record,
    p.contact,
    p.accessibility_preferences,
    pi.id AS patient_insurance_id,
    pi.member_id,
    pi.group_number,
    pi.plan_name,
    pi.coverage_type,
    pi.copay_fixed,
    pi.copay_percent,
    pi.deductible,
    pi.out_of_pocket_max,
    pi.status AS insurance_status,
    pi.effective_date,
    pi.expiration_date,
    ic.id AS insurance_company_id,
    ic.name AS insurance_company_name,
    ic.type AS insurance_company_type,
    ic.payer_id,
    ic.contact_number AS insurance_contact_number,
    ic.fax_number AS insurance_fax_number,
    ic.email AS insurance_email,
    ic.address AS insurance_address,
    ic.city AS insurance_city,
    ic.state AS insurance_state,
    ic.zip AS insurance_zip,
    ic.website AS insurance_website,
    GREATEST(p.created_at, pi.created_at, ic.created_at) AS record_created_at,
    LEAST(COALESCE(pi.expiration_date, CURRENT_DATE), CURRENT_DATE) AS record_valid_until
   FROM ((public.patients p
     LEFT JOIN public.patient_insurances pi ON ((p.id = pi.patient_id)))
     LEFT JOIN public.insurance_companies ic ON ((pi.insurance_company_id = ic.id)));


ALTER VIEW public.v_patient_insurance_details OWNER TO postgres;

--
-- Name: v_payment_methods_breakdown; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_payment_methods_breakdown AS
 SELECT pt.id AS transaction_id,
    pt.status AS transaction_status,
    pt.total_amount,
    p.payment_method,
    count(p.id) AS payment_count,
    sum(p.amount) AS method_total,
    round(((sum(p.amount) / NULLIF(pt.total_amount, (0)::numeric)) * (100)::numeric), 2) AS percentage_of_total,
    (array_agg(p.id ORDER BY p.id) FILTER (WHERE (p.id IS NOT NULL)))[1] AS first_payment_id,
    (array_agg(p.id ORDER BY p.id DESC) FILTER (WHERE (p.id IS NOT NULL)))[1] AS last_payment_id,
    min(((p.payment_meta ->> 'timestamp'::text))::timestamp with time zone) AS first_payment_time,
    max(((p.payment_meta ->> 'timestamp'::text))::timestamp with time zone) AS last_payment_time
   FROM (public.pos_transactions pt
     LEFT JOIN public.payments p ON ((pt.id = p.pos_transaction_id)))
  WHERE (p.id IS NOT NULL)
  GROUP BY pt.id, pt.status, pt.total_amount, p.payment_method
  ORDER BY pt.id DESC, (sum(p.amount)) DESC;


ALTER VIEW public.v_payment_methods_breakdown OWNER TO postgres;

--
-- Name: v_payment_transactions; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_payment_transactions AS
 SELECT pt.id AS transaction_id,
    pt.prescription_id,
    pt.patient_id,
    pt.station_id,
    pt.status AS transaction_status,
    pt.total_amount AS transaction_total,
    pt.created_at AS transaction_created_at,
    pt.metadata AS transaction_metadata,
    p.id AS payment_id,
    p.payment_method,
    p.amount AS payment_amount,
    p.payment_meta,
    COALESCE(p.amount, (0)::numeric) AS amount_paid,
    (pt.total_amount - COALESCE(p.amount, (0)::numeric)) AS amount_remaining,
        CASE
            WHEN (COALESCE(p.amount, (0)::numeric) >= pt.total_amount) THEN 'PAID'::text
            WHEN (COALESCE(p.amount, (0)::numeric) > (0)::numeric) THEN 'PARTIAL'::text
            ELSE 'UNPAID'::text
        END AS payment_status,
    count(p.id) OVER (PARTITION BY pt.id) AS payment_count,
    sum(COALESCE(p.amount, (0)::numeric)) OVER (PARTITION BY pt.id) AS total_paid,
    row_number() OVER (PARTITION BY pt.id ORDER BY p.id) AS payment_sequence
   FROM (public.pos_transactions pt
     LEFT JOIN public.payments p ON ((pt.id = p.pos_transaction_id)))
  ORDER BY pt.created_at DESC, p.id;


ALTER VIEW public.v_payment_transactions OWNER TO postgres;

--
-- Name: v_pdmp_query_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_pdmp_query_summary AS
 SELECT u.id AS user_id,
    u.username,
    date_trunc('month'::text, q.created_at) AS month,
    count(*) AS total_queries,
    count(*) FILTER (WHERE (q.status = 'success'::text)) AS successful_queries,
    count(*) FILTER (WHERE (q.status = 'failed'::text)) AS failed_queries,
    round(avg(EXTRACT(epoch FROM (q.completed_at - q.transmitted_at))), 2) AS avg_latency_seconds,
    jsonb_object_agg(q.query_reason, q.reason_cnt) FILTER (WHERE (q.reason_cnt IS NOT NULL)) AS reasons
   FROM (( SELECT pdmp_queries.user_id,
            pdmp_queries.created_at,
            pdmp_queries.status,
            pdmp_queries.transmitted_at,
            pdmp_queries.completed_at,
            pdmp_queries.query_reason,
            count(*) AS reason_cnt
           FROM public.pdmp_queries
          GROUP BY pdmp_queries.user_id, pdmp_queries.created_at, pdmp_queries.status, pdmp_queries.transmitted_at, pdmp_queries.completed_at, pdmp_queries.query_reason) q
     JOIN public.users u ON ((u.id = q.user_id)))
  GROUP BY u.id, u.username, (date_trunc('month'::text, q.created_at));


ALTER VIEW public.v_pdmp_query_summary OWNER TO postgres;

--
-- Name: v_prescription_claims_combined; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_prescription_claims_combined AS
 SELECT c.id AS claim_id,
    pc.id AS prescription_claim_id,
    c.prescription_id,
    pc.patient_insurance_id,
    pc.claim_number,
    pc.prior_authorization_number,
    c.payer_name,
    COALESCE(pc.claim_status, c.claim_status) AS claim_status,
    pc.rejection_code,
    pc.rejection_reason,
    pc.billed_amount,
    pc.reimbursed_amount,
    pc.patient_responsibility,
    (COALESCE(pc.billed_amount, (0)::numeric) - COALESCE(pc.reimbursed_amount, (0)::numeric)) AS write_off_amount,
        CASE
            WHEN ((pc.billed_amount IS NOT NULL) AND (pc.billed_amount > (0)::numeric)) THEN round(((COALESCE(pc.reimbursed_amount, (0)::numeric) / pc.billed_amount) * (100)::numeric), 2)
            ELSE NULL::numeric
        END AS reimbursement_percentage,
    c.response AS claim_response,
    pc.adjudication_data AS prescription_claim_adjudication,
    c.fiscal_fields AS claim_fiscal_fields,
    c.submitted_at AS claim_submitted_at,
    pc.claim_date AS prescription_claim_date,
    pc.created_at AS prescription_claim_created_at,
    pc.updated_at AS prescription_claim_updated_at,
        CASE
            WHEN (COALESCE(pc.claim_status, c.claim_status) = 'approved'::text) THEN 'SUCCESS'::text
            WHEN (COALESCE(pc.claim_status, c.claim_status) = 'rejected'::text) THEN 'FAILED'::text
            WHEN (COALESCE(pc.claim_status, c.claim_status) = 'pending'::text) THEN 'PENDING'::text
            WHEN (COALESCE(pc.claim_status, c.claim_status) = 'submitted'::text) THEN 'SUBMITTED'::text
            WHEN (COALESCE(pc.claim_status, c.claim_status) = 'reversed'::text) THEN 'REVERSED'::text
            ELSE 'UNKNOWN'::text
        END AS claim_outcome,
        CASE
            WHEN (c.submitted_at IS NOT NULL) THEN (now() - c.submitted_at)
            ELSE NULL::interval
        END AS time_since_submission,
        CASE
            WHEN (c.submitted_at IS NOT NULL) THEN (EXTRACT(day FROM (now() - c.submitted_at)))::integer
            ELSE NULL::integer
        END AS days_since_submission
   FROM (public.claims c
     FULL JOIN public.prescription_claims pc ON ((c.prescription_id = pc.prescription_id)))
  ORDER BY COALESCE(c.submitted_at, pc.claim_date) DESC NULLS LAST, c.id;


ALTER VIEW public.v_prescription_claims_combined OWNER TO postgres;

--
-- Name: v_prescription_claims_full; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_prescription_claims_full AS
 SELECT c.id AS claim_id,
    pc.id AS prescription_claim_id,
    pc.prescription_id,
    pc.patient_insurance_id,
    pc.claim_number,
    pc.prior_authorization_number,
    c.payer_name,
    COALESCE(pc.claim_status, c.claim_status) AS claim_status,
    pc.rejection_code,
    pc.rejection_reason,
    pc.billed_amount,
    pc.reimbursed_amount,
    pc.patient_responsibility,
    (COALESCE(pc.billed_amount, (0)::numeric) - COALESCE(pc.reimbursed_amount, (0)::numeric)) AS write_off_amount,
        CASE
            WHEN ((pc.billed_amount IS NOT NULL) AND (pc.billed_amount > (0)::numeric)) THEN round(((COALESCE(pc.reimbursed_amount, (0)::numeric) / pc.billed_amount) * (100)::numeric), 2)
            ELSE NULL::numeric
        END AS reimbursement_percentage,
    c.response AS claim_response,
    pc.adjudication_data,
    c.fiscal_fields,
    c.submitted_at,
    pc.claim_date,
    pc.created_at,
    pc.updated_at,
        CASE
            WHEN (COALESCE(pc.claim_status, c.claim_status) = 'approved'::text) THEN 'SUCCESS'::text
            WHEN (COALESCE(pc.claim_status, c.claim_status) = 'rejected'::text) THEN 'FAILED'::text
            WHEN (COALESCE(pc.claim_status, c.claim_status) = 'pending'::text) THEN 'PENDING'::text
            WHEN (COALESCE(pc.claim_status, c.claim_status) = 'submitted'::text) THEN 'SUBMITTED'::text
            WHEN (COALESCE(pc.claim_status, c.claim_status) = 'reversed'::text) THEN 'REVERSED'::text
            ELSE 'UNKNOWN'::text
        END AS claim_outcome,
        CASE
            WHEN (COALESCE(c.submitted_at, pc.claim_date) IS NOT NULL) THEN (EXTRACT(day FROM (now() - COALESCE(c.submitted_at, pc.claim_date))))::integer
            ELSE NULL::integer
        END AS days_since_submission
   FROM (public.prescription_claims pc
     LEFT JOIN public.claims c ON ((pc.prescription_id = c.prescription_id)))
  ORDER BY COALESCE(c.submitted_at, pc.claim_date) DESC NULLS LAST;


ALTER VIEW public.v_prescription_claims_full OWNER TO postgres;

--
-- Name: v_prescription_payment_dir_fee_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_prescription_payment_dir_fee_summary AS
 WITH payment_totals AS (
         SELECT pt.prescription_id,
            sum(p.amount) AS total_payments
           FROM (public.pos_transactions pt
             JOIN public.payments p ON ((p.pos_transaction_id = pt.id)))
          GROUP BY pt.prescription_id
        ), dir_fee_totals AS (
         SELECT vdfs.prescription_id,
            sum(vdfs.dir_fee_amount) AS total_dir_fees
           FROM public.v_dir_fee_summary vdfs
          GROUP BY vdfs.prescription_id
        ), pos_totals AS (
         SELECT pt.prescription_id,
            sum(pt.total_amount) AS total_pos_amount,
            min(pt.created_at) AS pos_created_at
           FROM public.pos_transactions pt
          GROUP BY pt.prescription_id
        )
 SELECT ptot.prescription_id,
    ptot.total_pos_amount,
    ptot.pos_created_at,
    COALESCE(pay.total_payments, (0)::numeric) AS total_payments,
    COALESCE(df.total_dir_fees, (0)::numeric) AS total_dir_fees,
    (COALESCE(pay.total_payments, (0)::numeric) - COALESCE(df.total_dir_fees, (0)::numeric)) AS net_after_dir_fees
   FROM ((pos_totals ptot
     LEFT JOIN payment_totals pay ON ((pay.prescription_id = ptot.prescription_id)))
     LEFT JOIN dir_fee_totals df ON ((df.prescription_id = ptot.prescription_id)))
  ORDER BY ptot.pos_created_at DESC;


ALTER VIEW public.v_prescription_payment_dir_fee_summary OWNER TO postgres;

--
-- Name: workflow_steps; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow_steps (
    id integer NOT NULL,
    workflow_id integer,
    step_key text,
    display_name text,
    config jsonb,
    queue_name text
);


ALTER TABLE public.workflow_steps OWNER TO postgres;

--
-- Name: v_prescription_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_prescription_summary AS
 SELECT p.id AS prescription_id,
    p.issue_date,
    p.status,
    p.priority,
    p.workflow_step_id,
    workflow.display_name AS workflow_descr,
    p.notes AS description,
    p.prescriber_name,
    p.assigned_to,
    p.queue_name,
    i.name AS drug_name,
    i.strength AS drug_strength,
    i.form AS drug_form,
    pt.first_name,
    pt.last_name,
    pt.mrn AS patient_mrn,
    pt.dob AS patient_dob,
    pt.gender AS patient_gender,
    p.created_at,
    pt.copay_fixed,
    pt.insurance_company_name
   FROM ((((public.prescriptions p
     JOIN public.prescription_items item ON ((p.id = item.prescription_id)))
     JOIN public.workflow_steps workflow ON ((p.workflow_step_id = workflow.id)))
     LEFT JOIN public.v_patient_insurance_details pt ON ((p.patient_id = pt.patient_id)))
     LEFT JOIN public.inventory_items i ON ((item.inventory_item_id = i.id)))
  WHERE (pt.insurance_status = 'active'::text);


ALTER VIEW public.v_prescription_summary OWNER TO postgres;

--
-- Name: v_transaction_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_transaction_summary AS
 SELECT pt.id AS transaction_id,
    pt.prescription_id,
    pt.patient_id,
    pat.first_name AS patient_first_name,
    pat.last_name AS patient_last_name,
    ((pat.first_name || ' '::text) || pat.last_name) AS patient_full_name,
    pat.mrn AS patient_mrn,
    pres.prescriber_name,
    pres.drug_name,
    pt.station_id,
    pt.status,
    pt.total_amount,
    pt.created_at,
    count(DISTINCT p.id) AS total_payments,
    sum(COALESCE(p.amount, (0)::numeric)) AS total_paid,
    (pt.total_amount - COALESCE(sum(p.amount), (0)::numeric)) AS balance_due,
    round(((COALESCE(sum(p.amount), (0)::numeric) / NULLIF(pt.total_amount, (0)::numeric)) * (100)::numeric), 2) AS payment_percentage,
        CASE
            WHEN (pt.status = 'refunded'::text) THEN 'REFUNDED'::text
            WHEN (COALESCE(sum(p.amount), (0)::numeric) >= pt.total_amount) THEN 'PAID'::text
            WHEN (COALESCE(sum(p.amount), (0)::numeric) > (0)::numeric) THEN 'PARTIAL'::text
            ELSE 'UNPAID'::text
        END AS payment_status,
    string_agg(DISTINCT p.payment_method, ', '::text ORDER BY p.payment_method) AS payment_methods_used
   FROM (((public.pos_transactions pt
     LEFT JOIN public.payments p ON ((pt.id = p.pos_transaction_id)))
     LEFT JOIN public.patients pat ON ((pt.patient_id = pat.id)))
     LEFT JOIN public.v_prescription_summary pres ON ((pt.prescription_id = pres.prescription_id)))
  GROUP BY pt.id, pt.prescription_id, pt.patient_id, pat.first_name, pat.last_name, pat.mrn, pres.prescriber_name, pres.drug_name, pt.station_id, pt.status, pt.total_amount, pt.created_at
  ORDER BY pt.created_at DESC;


ALTER VIEW public.v_transaction_summary OWNER TO postgres;

--
-- Name: v_transaction_with_payment_details; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_transaction_with_payment_details AS
 SELECT pt.id,
    pt.prescription_id,
    pt.patient_id,
    pt.station_id,
    pt.status,
    pt.total_amount,
    pt.created_at,
    pt.metadata,
    jsonb_agg(jsonb_build_object('payment_id', p.id, 'payment_method', p.payment_method, 'amount', p.amount, 'payment_meta', p.payment_meta) ORDER BY p.id) FILTER (WHERE (p.id IS NOT NULL)) AS payments_array,
    count(DISTINCT p.id) AS payment_count,
    sum(COALESCE(p.amount, (0)::numeric)) AS total_paid,
    (pt.total_amount - COALESCE(sum(p.amount), (0)::numeric)) AS remaining_balance
   FROM (public.pos_transactions pt
     LEFT JOIN public.payments p ON ((pt.id = p.pos_transaction_id)))
  GROUP BY pt.id, pt.prescription_id, pt.patient_id, pt.station_id, pt.status, pt.total_amount, pt.created_at, pt.metadata
  ORDER BY pt.created_at DESC;


ALTER VIEW public.v_transaction_with_payment_details OWNER TO postgres;

--
-- Name: wholesalers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.wholesalers (
    id integer NOT NULL,
    name text NOT NULL,
    contact jsonb,
    trading_partner_id text
);


ALTER TABLE public.wholesalers OWNER TO postgres;

--
-- Name: wholesalers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.wholesalers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.wholesalers_id_seq OWNER TO postgres;

--
-- Name: wholesalers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.wholesalers_id_seq OWNED BY public.wholesalers.id;


--
-- Name: workflow_steps_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.workflow_steps_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.workflow_steps_id_seq OWNER TO postgres;

--
-- Name: workflow_steps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.workflow_steps_id_seq OWNED BY public.workflow_steps.id;


--
-- Name: workflows; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflows (
    id integer NOT NULL,
    name text NOT NULL,
    description text,
    config jsonb,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.workflows OWNER TO postgres;

--
-- Name: workflows_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.workflows_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.workflows_id_seq OWNER TO postgres;

--
-- Name: workflows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.workflows_id_seq OWNED BY public.workflows.id;


--
-- Name: audit_log id; Type: DEFAULT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.audit_log ALTER COLUMN id SET DEFAULT nextval('eam.audit_log_id_seq'::regclass);


--
-- Name: auth_logs id; Type: DEFAULT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.auth_logs ALTER COLUMN id SET DEFAULT nextval('pharmacy.auth_logs_id_seq'::regclass);


--
-- Name: reorder_rules id; Type: DEFAULT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.reorder_rules ALTER COLUMN id SET DEFAULT nextval('pharmacy.reorder_rules_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.roles ALTER COLUMN id SET DEFAULT nextval('pharmacy.roles_id_seq'::regclass);


--
-- Name: stations id; Type: DEFAULT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.stations ALTER COLUMN id SET DEFAULT nextval('pharmacy.stations_id_seq'::regclass);


--
-- Name: workflow_transitions id; Type: DEFAULT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.workflow_transitions ALTER COLUMN id SET DEFAULT nextval('pharmacy.workflow_transitions_id_seq'::regclass);


--
-- Name: access_logs id; Type: DEFAULT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.access_logs ALTER COLUMN id SET DEFAULT nextval('pharmacy3.access_logs_id_seq'::regclass);


--
-- Name: auth_logs id; Type: DEFAULT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.auth_logs ALTER COLUMN id SET DEFAULT nextval('pharmacy3.auth_logs_id_seq'::regclass);


--
-- Name: efax_status_logs id; Type: DEFAULT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.efax_status_logs ALTER COLUMN id SET DEFAULT nextval('pharmacy3.efax_status_logs_id_seq'::regclass);


--
-- Name: pharmacy_types id; Type: DEFAULT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.pharmacy_types ALTER COLUMN id SET DEFAULT nextval('pharmacy3.pharmacy_types_id_seq'::regclass);


--
-- Name: reorder_rules id; Type: DEFAULT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.reorder_rules ALTER COLUMN id SET DEFAULT nextval('pharmacy3.reorder_rules_id_seq'::regclass);


--
-- Name: stations id; Type: DEFAULT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.stations ALTER COLUMN id SET DEFAULT nextval('pharmacy3.stations_id_seq'::regclass);


--
-- Name: workflow_transitions id; Type: DEFAULT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.workflow_transitions ALTER COLUMN id SET DEFAULT nextval('pharmacy3.workflow_transitions_id_seq'::regclass);


--
-- Name: access_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.access_logs ALTER COLUMN id SET DEFAULT nextval('public.access_logs_id_seq'::regclass);


--
-- Name: alert_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_logs ALTER COLUMN id SET DEFAULT nextval('public.alert_logs_id_seq'::regclass);


--
-- Name: alert_rules id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_rules ALTER COLUMN id SET DEFAULT nextval('public.alert_rules_id_seq'::regclass);


--
-- Name: auth_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_logs ALTER COLUMN id SET DEFAULT nextval('public.auth_logs_id_seq'::regclass);


--
-- Name: awp_reclaims id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.awp_reclaims ALTER COLUMN id SET DEFAULT nextval('public.awp_reclaims_id_seq'::regclass);


--
-- Name: device_fingerprints station_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_fingerprints ALTER COLUMN station_id SET DEFAULT nextval('public.device_fingerprints_station_id_seq'::regclass);


--
-- Name: dir_fees id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dir_fees ALTER COLUMN id SET DEFAULT nextval('public.dir_fees_id_seq'::regclass);


--
-- Name: efax_status_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.efax_status_logs ALTER COLUMN id SET DEFAULT nextval('public.efax_status_logs_id_seq'::regclass);


--
-- Name: encryption_keys_meta id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.encryption_keys_meta ALTER COLUMN id SET DEFAULT nextval('public.encryption_keys_meta_id_seq'::regclass);


--
-- Name: fingerprint_history station_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fingerprint_history ALTER COLUMN station_id SET DEFAULT nextval('public.fingerprint_history_station_id_seq'::regclass);


--
-- Name: integrations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.integrations ALTER COLUMN id SET DEFAULT nextval('public.integrations_id_seq'::regclass);


--
-- Name: patient_aliases id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_aliases ALTER COLUMN id SET DEFAULT nextval('public.patient_aliases_id_seq'::regclass);


--
-- Name: prescription_audit id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prescription_audit ALTER COLUMN id SET DEFAULT nextval('public.prescription_audit_id_seq'::regclass);


--
-- Name: prescription_workflow_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prescription_workflow_logs ALTER COLUMN id SET DEFAULT nextval('public.prescription_workflow_logs_id_seq'::regclass);


--
-- Name: profit_audit_warnings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profit_audit_warnings ALTER COLUMN id SET DEFAULT nextval('public.profit_audit_warnings_id_seq'::regclass);


--
-- Name: queues id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.queues ALTER COLUMN id SET DEFAULT nextval('public.queues_id_seq'::regclass);


--
-- Name: reorder_rules id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reorder_rules ALTER COLUMN id SET DEFAULT nextval('public.reorder_rules_id_seq'::regclass);


--
-- Name: role_permissions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_permissions ALTER COLUMN id SET DEFAULT nextval('public.role_permissions_id_seq'::regclass);


--
-- Name: role_permissions role_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_permissions ALTER COLUMN role_id SET DEFAULT nextval('public.role_permissions_role_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: stations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stations ALTER COLUMN id SET DEFAULT nextval('public.stations_id_seq'::regclass);


--
-- Name: task_routing id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_routing ALTER COLUMN id SET DEFAULT nextval('public.task_routing_id_seq'::regclass);


--
-- Name: user_permissions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_permissions ALTER COLUMN id SET DEFAULT nextval('public.user_permissions_id_seq'::regclass);


--
-- Name: wholesalers id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wholesalers ALTER COLUMN id SET DEFAULT nextval('public.wholesalers_id_seq'::regclass);


--
-- Name: workflow_steps id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_steps ALTER COLUMN id SET DEFAULT nextval('public.workflow_steps_id_seq'::regclass);


--
-- Name: workflows id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflows ALTER COLUMN id SET DEFAULT nextval('public.workflows_id_seq'::regclass);


--
-- Data for Name: asset_meters; Type: TABLE DATA; Schema: eam; Owner: postgres
--

COPY eam.asset_meters (id, asset_id, name, unit, last_reading, last_reading_date) FROM stdin;
\.


--
-- Data for Name: asset_types; Type: TABLE DATA; Schema: eam; Owner: postgres
--

COPY eam.asset_types (id, name, description) FROM stdin;
\.


--
-- Data for Name: assets; Type: TABLE DATA; Schema: eam; Owner: postgres
--

COPY eam.assets (id, code, name, description, asset_type_id, parent_id, site_id, geo, status, acquisition_date, cost, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: audit_log; Type: TABLE DATA; Schema: eam; Owner: postgres
--

COPY eam.audit_log (id, entity, entity_id, action, changed_by, changed_at, diff) FROM stdin;
\.


--
-- Data for Name: inventory_transactions; Type: TABLE DATA; Schema: eam; Owner: postgres
--

COPY eam.inventory_transactions (id, part_id, location_id, quantity, transaction_type, reference_id, created_at) FROM stdin;
\.


--
-- Data for Name: maintenance_plans; Type: TABLE DATA; Schema: eam; Owner: postgres
--

COPY eam.maintenance_plans (id, asset_id, description, frequency_days, next_due_date, last_completed) FROM stdin;
\.


--
-- Data for Name: maintenance_triggers; Type: TABLE DATA; Schema: eam; Owner: postgres
--

COPY eam.maintenance_triggers (id, plan_id, meter_id, threshold) FROM stdin;
\.


--
-- Data for Name: meter_readings; Type: TABLE DATA; Schema: eam; Owner: postgres
--

COPY eam.meter_readings (id, meter_id, reading_value, reading_date) FROM stdin;
\.


--
-- Data for Name: outbox_events; Type: TABLE DATA; Schema: eam; Owner: postgres
--

COPY eam.outbox_events (id, aggregate_type, aggregate_id, event_type, payload, created_at) FROM stdin;
\.


--
-- Data for Name: parts; Type: TABLE DATA; Schema: eam; Owner: postgres
--

COPY eam.parts (id, sku, description, uom, cost, safety_stock, created_at) FROM stdin;
\.


--
-- Data for Name: stock_locations; Type: TABLE DATA; Schema: eam; Owner: postgres
--

COPY eam.stock_locations (id, name, description) FROM stdin;
\.


--
-- Data for Name: technicians; Type: TABLE DATA; Schema: eam; Owner: postgres
--

COPY eam.technicians (id, first_name, last_name, email, phone, active) FROM stdin;
\.


--
-- Data for Name: vendors; Type: TABLE DATA; Schema: eam; Owner: postgres
--

COPY eam.vendors (id, name, contact_info) FROM stdin;
\.


--
-- Data for Name: work_order_labor; Type: TABLE DATA; Schema: eam; Owner: postgres
--

COPY eam.work_order_labor (id, work_order_id, technician_id, hours_worked, cost_per_hour) FROM stdin;
\.


--
-- Data for Name: work_order_parts; Type: TABLE DATA; Schema: eam; Owner: postgres
--

COPY eam.work_order_parts (id, work_order_id, part_id, qty_planned, qty_used) FROM stdin;
\.


--
-- Data for Name: work_order_tasks; Type: TABLE DATA; Schema: eam; Owner: postgres
--

COPY eam.work_order_tasks (id, work_order_id, sequence, description, status, started_at, finished_at) FROM stdin;
\.


--
-- Data for Name: work_orders; Type: TABLE DATA; Schema: eam; Owner: postgres
--

COPY eam.work_orders (id, asset_id, type, priority, status, description, requested_by, assigned_to, sla_due_at, created_at, updated_at, completed_at) FROM stdin;
\.


--
-- Data for Name: applied_learning_experiences; Type: TABLE DATA; Schema: learningsystem; Owner: postgres
--

COPY learningsystem.applied_learning_experiences (id, student_id, faculty_advisor_id, type, title, organization_name, status, start_date, end_date, canvas_course_id, type_specific_data, created_at, updated_at, is_verified, verified_at) FROM stdin;
9aef11ae-9ed1-4b4a-b56c-e45542a0f360	ae1d6b0c-c7a7-4973-ab72-2c596ac60f98	\N	CO_OP	Engineering Cooperative Program	Boeing	PENDING	\N	\N	\N	{"term": "Spring 2026", "is_paid": true, "department": "Aerospace Design"}	2025-12-21 15:48:04.240662	2025-12-21 15:48:04.240662	f	\N
f08a19a3-ff19-48c1-8d3e-f1f96dce0334	483ab23e-8436-4a85-a4c0-e722948fdf2a	\N	STUDENT_EMPLOYMENT	IT Help Desk Assistant	EWU IT Services	COMPLETED	\N	\N	\N	{"supervisor": "Bill Gates", "hours_per_week": 15}	2025-12-21 15:48:04.240662	2025-12-21 15:48:04.240662	f	\N
1441779a-4b11-4249-aca8-f835263ad2c6	ae1d6b0c-c7a7-4973-ab72-2c596ac60f98	\N	RESEARCH	Soil Nutrient Analysis Research	EWU Environmental Lab	APPROVED	\N	\N	\N	{"lab_id": "S-201", "grant_number": "NSF-8892", "is_published": false}	2025-12-21 15:48:04.240662	2025-12-21 15:48:04.240662	f	\N
89fc8d21-f1af-42ce-8744-ecd067e599a1	483ab23e-8436-4a85-a4c0-e722948fdf2a	\N	FIELD_WORK	Geological Surveying	Turnbull Wildlife Refuge	PENDING	\N	\N	\N	{"permit_id": "TW-002", "equipment_used": "GPS, Soil Probe"}	2025-12-21 15:48:04.240662	2025-12-21 15:48:04.240662	f	\N
5cff6647-54e0-4f90-a1d0-e34b9c8e46de	483ab23e-8436-4a85-a4c0-e722948fdf2a	\N	FELLOWSHIP	Graduate Leadership Fellowship	EWU Foundation	APPROVED	\N	\N	\N	{"cohort_name": "Leaders 2025", "award_amount": 5000}	2025-12-21 15:48:04.240662	2025-12-21 15:48:04.240662	f	\N
ac3c9bc8-99de-4dde-b223-803997528c45	483ab23e-8436-4a85-a4c0-e722948fdf2a	\N	STUDY_ABROAD	History of Art in Florence	University of Florence	APPROVED	\N	\N	\N	{"country": "Italy", "credits_transferable": true, "language_of_instruction": "Italian"}	2025-12-21 15:48:04.240662	2025-12-21 15:48:04.240662	f	\N
a2d0d8da-fd65-405c-80b5-e2dedd5ed53b	483ab23e-8436-4a85-a4c0-e722948fdf2a	\N	VOLUNTEERISM	Weekend Food Bank Support	Second Harvest	COMPLETED	\N	\N	\N	{"impact_area": "Food Insecurity", "total_hours": 50}	2025-12-21 15:48:04.240662	2025-12-21 15:48:04.240662	f	\N
148342ef-d1be-4c6e-b4e7-5a0209cdc0af	483ab23e-8436-4a85-a4c0-e722948fdf2a	\N	COMMUNITY_PROJECT	Mural Restoration	City of Cheney	PENDING	\N	\N	\N	{"location": "1st Street", "community_partner": "Downtown Arts"}	2025-12-21 15:48:04.240662	2025-12-21 15:48:04.240662	f	\N
a14bb904-5929-4946-b259-a75f8123300d	483ab23e-8436-4a85-a4c0-e722948fdf2a	\N	SERVICE_LEARNING	Literacy Outreach	Spokane Public Library	APPROVED	\N	\N	\N	{"is_mandatory": true, "canvas_course_id": "ENGL-101"}	2025-12-21 15:48:04.240662	2025-12-21 15:48:04.240662	f	\N
b7294dfe-b9d6-47da-ac5f-317e01c0961b	ae1d6b0c-c7a7-4973-ab72-2c596ac60f98	\N	CLASSROOM_SIMULATION	Mock Trial - Criminal Law	EWU Law Society	COMPLETED	\N	\N	\N	{"case_topic": "Property Law", "role_played": "Prosecutor"}	2025-12-21 15:48:04.240662	2025-12-21 15:48:04.240662	f	\N
2e1c4e78-7c1e-4c2c-aada-e82ee9d24097	ae1d6b0c-c7a7-4973-ab72-2c596ac60f98	\N	LAB_WORK	Advanced Circuit Testing	Engineering Lab 4	APPROVED	\N	\N	\N	{"bench_number": 12, "safety_certified": true}	2025-12-21 15:48:04.240662	2025-12-21 15:48:04.240662	f	\N
fe50040f-f83e-4d9a-866f-4e6870f8afac	ae1d6b0c-c7a7-4973-ab72-2c596ac60f98	\N	ARTS_PERFORMANCE	Senior Jazz Ensemble	EWU Recital Hall	COMPLETED	\N	\N	\N	{"instrument": "Tenor Sax", "repertoire": "Coltrane Basics"}	2025-12-21 15:48:04.240662	2025-12-21 15:48:04.240662	f	\N
e2d199a6-4c46-43db-8d75-2f19e167e529	483ab23e-8436-4a85-a4c0-e722948fdf2a	\N	APPRENTICESHIP	Master HVAC Training	McKinstry	PENDING	\N	\N	\N	{"phase": "Level 1 Induction", "journeyman_license": "A-9923"}	2025-12-21 15:48:04.240662	2025-12-21 15:48:04.240662	f	\N
7b2e936d-1fed-4af4-a758-a0d384c34be0	483ab23e-8436-4a85-a4c0-e722948fdf2a	675c67ef-48d9-452a-b137-d1dc35fb0e3a	INTERNSHIP	Junior Software Developer	F5 Networks	APPROVED	2026-01-05	2026-05-15	\N	{"department": "Cloud Services", "mentor_name": "Jane Doe", "credit_hours": 4}	2025-12-18 11:19:48.269346	2025-12-21 11:19:48.269346	t	2025-12-21 18:28:26.957613-08
7ae1cb1b-f5cf-4e73-bbe0-33b1898e610b	ae1d6b0c-c7a7-4973-ab72-2c596ac60f98	675c67ef-48d9-452a-b137-d1dc35fb0e3a	RESEARCH	Biochemical Soil Analysis	EWU Biology Lab	APPROVED	2025-09-01	2025-12-15	\N	{"lab_number": "S-304", "grant_funded": true, "publication_target": "Nature Journal"}	2025-12-06 11:19:48.269346	2025-12-21 11:19:48.269346	t	2025-12-21 18:29:26.86975-08
fb90e33f-ed36-4bc2-8a0a-bbf798bfb5fb	483ab23e-8436-4a85-a4c0-e722948fdf2a	675c67ef-48d9-452a-b137-d1dc35fb0e3a	SERVICE_LEARNING	Youth Literacy Tutor	Spokane Public Schools	COMPLETED	\N	\N	CANV-10293	{"hours_completed": 40, "community_partner_contact": "John Smith"}	2025-10-22 11:19:48.269346	2025-12-21 11:19:48.269346	t	2025-12-21 18:31:50.80603-08
87e8d10b-2ca0-49a0-b1e3-9943ee8957c8	ae1d6b0c-c7a7-4973-ab72-2c596ac60f98	\N	INTERNSHIP	Cybersecurity Analyst Intern	F5 Networks	APPROVED	\N	\N	\N	{"mentor": "Jane Smith", "stipend": 2000, "credit_hours": 5}	2025-12-21 15:48:04.240662	2025-12-21 15:48:04.240662	t	2025-12-21 18:32:42.69349-08
856b358f-b784-479e-b869-343f823a098a	ae1d6b0c-c7a7-4973-ab72-2c596ac60f98	\N	PRACTICUM	K-12 Teaching Practicum	Cheney School District	APPROVED	\N	\N	\N	{"classroom_grade": "4th", "observation_hours": 40}	2025-12-21 15:48:04.240662	2025-12-21 15:48:04.240662	t	2025-12-21 18:34:44.676042-08
a65dc8b3-c8be-4315-a600-ce0133f653a7	483ab23e-8436-4a85-a4c0-e722948fdf2a	\N	CLINICAL	Nursing Rotation - ICU	Providence Sacred Heart	APPROVED	\N	\N	\N	{"unit": "Critical Care", "total_shifts": 12, "clinical_instructor": "Dr. Miller"}	2025-12-21 15:48:04.240662	2025-12-21 15:48:04.240662	t	2025-12-21 18:35:25.207501-08
\.


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: learningsystem; Owner: postgres
--

COPY learningsystem.audit_logs (id, actor_id, actor_name, action, target_type, target_id, details, ip_address, created_at) FROM stdin;
45d895bb-3fa1-427e-bb57-73ceeec3bd7f	753d7730-5d88-45a3-a5a7-bf7c3cfa643e	Sam Snyder	POSTED_NEW_JOB	JOB	dcf33849-24c3-41b9-a535-91eb64ddccc6	Posted: Cloud Engineering Intern	192.168.1.45	2025-12-19 20:57:07.84759
a0d7ed63-72c2-4b72-b7db-52f9a4025633	ae1d6b0c-c7a7-4973-ab72-2c596ac60f98	Alice Eagle	SUBMITTED_EXPERIENCE	LEARNING	b9ab7ca9-4c93-41a4-9de7-e71fce86498d	Submitted: Summer Research Project	172.16.254.1	2025-12-19 20:44:07.84759
626d568b-664b-4e59-9afa-5237869ce414	\N	System Sync Service	BANNER_REFRESH_COMPLETE	SYSTEM	\N	Successfully synchronized 452 student academic records.	127.0.0.1	2025-12-19 19:59:07.84759
db61597b-443f-4988-ade3-bca02a378789	\N	Staff Administrator	USER_ROLE_UPDATED	USER	\N	Updated permissions for partner: Spokane Tech	10.0.0.5	2025-12-19 17:59:07.84759
c24cd561-96d2-4eaf-8299-d685cb3f7332	2f90e7e2-8f64-408e-a9a4-972878ac280f	Paul Mai	EXPERIENCE_VERIFIED	INTERNSHIP	\N	Approve learning experience for ID: 7b2e936d-1fed-4af4-a758-a0d384c34be0	127.0.0.1	2025-12-21 18:28:27.025862
999722ae-2f5d-47f0-a9ab-4869157397bb	2f90e7e2-8f64-408e-a9a4-972878ac280f	Paul Mai	EXPERIENCE_VERIFIED	RESEARCH	\N	Approve learning experience for ID: 7ae1cb1b-f5cf-4e73-bbe0-33b1898e610b	127.0.0.1	2025-12-21 18:28:52.276146
f5bd98f9-f431-4b99-ac3d-77b2669483fe	2f90e7e2-8f64-408e-a9a4-972878ac280f	Paul Mai	EXPERIENCE_VERIFIED	RESEARCH	\N	Approve learning experience for ID: 7ae1cb1b-f5cf-4e73-bbe0-33b1898e610b	127.0.0.1	2025-12-21 18:29:26.886953
2206e421-86ee-4c6a-bc09-8bf1f7b6eb3f	2f90e7e2-8f64-408e-a9a4-972878ac280f	Paul Mai	EXPERIENCE_VERIFIED	SERVICE_LEARNING	\N	Approve learning experience for ID: fb90e33f-ed36-4bc2-8a0a-bbf798bfb5fb	127.0.0.1	2025-12-21 18:31:28.008731
a6433d8f-aab2-427d-91c3-a7a0c221da8a	2f90e7e2-8f64-408e-a9a4-972878ac280f	Paul Mai	EXPERIENCE_VERIFIED	SERVICE_LEARNING	\N	Approve learning experience for ID: fb90e33f-ed36-4bc2-8a0a-bbf798bfb5fb	127.0.0.1	2025-12-21 18:31:50.829429
deb6dffb-5bbf-4464-bc93-e44afa99cba1	2f90e7e2-8f64-408e-a9a4-972878ac280f	Paul Mai	EXPERIENCE_VERIFIED	INTERNSHIP	\N	Approve learning experience for ID: 87e8d10b-2ca0-49a0-b1e3-9943ee8957c8	127.0.0.1	2025-12-21 18:32:42.720961
bb3d3ecd-e2d1-428b-8470-5bbfb4424d9b	2f90e7e2-8f64-408e-a9a4-972878ac280f	Paul Mai	EXPERIENCE_VERIFIED	PRACTICUM	\N	Approve learning experience for ID: 856b358f-b784-479e-b869-343f823a098a	127.0.0.1	2025-12-21 18:34:44.698831
086416fe-2d10-4df0-b82f-1d14068b0042	2f90e7e2-8f64-408e-a9a4-972878ac280f	Paul Mai	EXPERIENCE_VERIFIED	CLINICAL	\N	Approve learning experience for ID: a65dc8b3-c8be-4315-a600-ce0133f653a7	127.0.0.1	2025-12-21 18:35:25.21414
\.


--
-- Data for Name: employer_profiles; Type: TABLE DATA; Schema: learningsystem; Owner: postgres
--

COPY learningsystem.employer_profiles (user_id, company_name, website_url, industry, description, is_approved, created_at) FROM stdin;
753d7730-5d88-45a3-a5a7-bf7c3cfa643e	Spokane Tech Solutions	https://spokanetech.com	Information Technology	A leading provider of cloud-native enterprise solutions in the Inland Northwest.	t	2025-12-19 11:19:47.651444
\.


--
-- Data for Name: event_registrations; Type: TABLE DATA; Schema: learningsystem; Owner: postgres
--

COPY learningsystem.event_registrations (event_id, user_id, payment_status, checked_in) FROM stdin;
\.


--
-- Data for Name: events; Type: TABLE DATA; Schema: learningsystem; Owner: postgres
--

COPY learningsystem.events (id, organizer_id, title, type, location, start_time, end_time, requires_fee, fee_amount, touchnet_payment_code) FROM stdin;
\.


--
-- Data for Name: job_postings; Type: TABLE DATA; Schema: learningsystem; Owner: postgres
--

COPY learningsystem.job_postings (id, employer_id, title, description, location, funding_source, is_on_campus, deadline, is_active, created_at) FROM stdin;
b8855033-7313-436b-8b76-cb6af9348932	753d7730-5d88-45a3-a5a7-bf7c3cfa643e	Student IT Support Technician	Assist campus departments with software troubleshooting and hardware setup. Must be FWS eligible.	EWU Cheney - JFK Library	WORK_STUDY	t	2026-01-15	t	2025-12-19 11:27:32.299869
2e753f8b-4f55-44a6-a238-c7f2f422f052	753d7730-5d88-45a3-a5a7-bf7c3cfa643e	Software Engineering Intern	Join our cloud solutions team for a 12-week summer internship. Proficiency in Java or React preferred.	Downtown Spokane / Remote	NON_WORK_STUDY	f	2026-03-01	t	2025-12-19 11:27:32.299869
\.


--
-- Data for Name: student_profiles; Type: TABLE DATA; Schema: learningsystem; Owner: postgres
--

COPY learningsystem.student_profiles (user_id, major, gpa, work_study_eligible, graduation_year, resume_url, portfolio_url) FROM stdin;
ae1d6b0c-c7a7-4973-ab72-2c596ac60f98	Computer Science	3.85	t	2026	https://storage.ewu.edu/resumes/aeagle_resume.pdf	https://portfolios.ewu.edu/aeagle
\.


--
-- Data for Name: system_configs; Type: TABLE DATA; Schema: learningsystem; Owner: postgres
--

COPY learningsystem.system_configs (config_key, config_value, description, updated_at, updated_by) FROM stdin;
CURRENT_SEMESTER	Spring 2026	The active academic term for reporting.	2025-12-19 21:32:53.405038	\N
JOB_APPROVAL_REQUIRED	TRUE	Global toggle for vetting employer postings.	2025-12-19 21:32:53.405038	\N
FWS_CHECK_ENABLED	TRUE	Enforce Federal Work Study eligibility via Banner sync.	2025-12-19 21:32:53.405038	\N
EXPERIENCE_DEADLINE	2026-05-15	Final date for students to submit learning logs.	2025-12-19 21:32:53.405038	\N
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: learningsystem; Owner: postgres
--

COPY learningsystem.users (id, okta_id, banner_id, email, first_name, last_name, role, is_active, created_at) FROM stdin;
ae1d6b0c-c7a7-4973-ab72-2c596ac60f98	okta_001_student	800123456	aeagle@ewu.edu	Alice	Eagle	STUDENT	t	2025-12-18 22:48:05.239713
675c67ef-48d9-452a-b137-d1dc35fb0e3a	okta_003_faculty	800555000	fpro@ewu.edu	Felicia	Professor	FACULTY	t	2025-12-18 22:48:05.239713
753d7730-5d88-45a3-a5a7-bf7c3cfa643e	okta_004_employer	\N	recruiting@spokanetech.com	Sam	Snyder	EMPLOYER	t	2025-12-18 22:48:05.239713
2f90e7e2-8f64-408e-a9a4-972878ac280f	okta_002_staff	800987654	paul.mai@datascience9.com	Paul	Mai	STAFF	t	2025-12-18 22:48:05.239713
483ab23e-8436-4a85-a4c0-e722948fdf2a	\N	\N	test@datascience9.com	test	test	STUDENT	t	2025-12-20 22:06:53.393091
\.


--
-- Data for Name: volunteer_logs; Type: TABLE DATA; Schema: learningsystem; Owner: postgres
--

COPY learningsystem.volunteer_logs (id, student_id, experience_id, date_logged, hours_worked, impact_type, donation_amount, site_supervisor_email, is_verified) FROM stdin;
\.


--
-- Data for Name: workflows; Type: TABLE DATA; Schema: learningsystem; Owner: postgres
--

COPY learningsystem.workflows (id, experience_id, step_order, approver_email, approver_name, auth_token, token_expiry, status, comments, action_date) FROM stdin;
\.


--
-- Data for Name: auth_logs; Type: TABLE DATA; Schema: pharmacy; Owner: postgres
--

COPY pharmacy.auth_logs (id, user_id, username, event_type, status, ip_address, user_agent, metadata, created_at) FROM stdin;
147	11111111-2222-3333-4444-555555555555	testuser	logout	success	127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-25 19:34:09.378157-08
148	11111111-2222-3333-4444-555555555555	testuser	login	success	127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-25 19:34:09.885237-08
149	11111111-2222-3333-4444-555555555555	testuser	login	success	127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-25 19:34:09.885974-08
\.


--
-- Data for Name: device_fingerprints; Type: TABLE DATA; Schema: pharmacy; Owner: postgres
--

COPY pharmacy.device_fingerprints (id, station_id, fingerprint_hash, browser_user_agent, screen_resolution, timezone, language, canvas_fingerprint, webgl_fingerprint, department, location, is_active, assigned_date, last_seen, access_count) FROM stdin;
c03fd766-b82a-40e0-9498-2d6f88d0aa0b	1	271994726381bc6b83b31cccd06c79d4e59d6047c5f11b6d307ad94e44af1553	webkit	1920x1080	America/Los_Angeles	en-US	data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAASwAAACWCAYAAABkW7XSAAAQAElEQVR4AeyaCUBUZdfH/3dmYFgFQVnEfSlNxRJ329zD3BVNCxeEmUHarCxt+dyyXtNeLTcQtbfd1NK0UktTUQH3PcMFEwUBF/Z1YO537iBoIvs2y7neZ5777Of8ztw/z72jDHwwASbABIyEAAuWkQSqOs0UVRDNMVUnQ56rbgiwYNUNd16VCTCBShBgwaoENGMdwnYzAWMnUH7BUoU8D1VIurE7zPYzASZgvATKL1jG6yNbXksEtsETf8OtllYrWCYDSqzCMwUF/jR5AhUWLNVRdFcdwSaTJ8MOVpjAx/BGFFwrPK4qAw6gNULxVFWmMM2xJurVPcEKWu5Mj3wiAla/SPkZSpl0vQfTVjS5z3ftgfAXhsXEdHyO2lOpfQ1e+VxZ1K4KeZfqDlFbBqW9lLrf13acyu9ROg918Db4fmVL1yJdj6G0g65v0djfMXVNa7reSSlKX9ascimaQx08iup3UUqndJrafYvapAtVyAyqv0wpldLXNJcTzT2YrrPgt9Ze6qJPPhssqS6T2obqyw9+qIKPUtsb1GcrJWm+s5R3pPW+pPwIJal8z7fS7ApY/Sn1/x/Nt5RyyfZoyt8sWrKAQyjVnaeUTGk9Mb+3TfEPdaV1f6f6NEqb4R/qRbkIzSoPSIff2kY09zaqS6F0g1IoJn9hJTVR/VAqX6ZcQ2k3Xd+mfNFutMUAvA53LEIgXoQIAYXHcvTBI5gPGyyHF97DH2hX2IQueBefoR+GYxp64208jg9Q2N4NsxCBlhhBbWNdR+GOHYodF+GCkQiEKxajOT7CFEzCVTjjN3SANZYjDQVmg45cKCDZIO3aShr3KzriObyKE2gChXw5tjZrQCOB0nyAqoKx1c/IH4ZC4J5g6WS6u0a9SrkPpbaQ6ZKgtVhL14WnRWpywz7u7hfDIIh9KXkj22qqvlEdPJjyIIjCNCjyWtF1FKVtmD27cI08Ko+ndg2Nmwp5fj6VQeXxcLsxhNZpR/Wdqf5XyHS+cI9rT2WR2mfo+01b4UbXX1JagVzLxtS2ktKXdOM+oW9XB4+j/F1qV1Mu1bnTXN8jRL2dykmw0L5IecHpmCwJVQ7uOP1WUPHgp6DTzyPT+VNLW0o3KIVT3RqsVnelfAOVl1GCXlxEoWS7ZDqJqw/13U1j+1M+gNIisrsD5YB11mzKm1IaQvP2ptwDeYoQygtOef4qunAgXzpRPovYfEo5UBgvRd5vNO4m1XeifDS1dSRfl1AOKktre1DuiBBNPxrjQ9dvrcCz2I7PcRZz8COe0AsG6NhM1/PxPD7FRlzFLExCBIbgZVxHfWoFZBCxBP0obcBBfEJS8SfGIwCS4B3Gx6iHbGzBSoxt8ROSbFHsmIlRcEQmTmI+IrAQ1tDS7C/AG+dohUx8i24oPLbBE0pqH4yzKGnc8ziDxdiEJ3ANl51eRmbjWyjLB0Aof2zBh6ERKBSTIrscHOND1Sr1IrVG3eaFsf+HgQNXDfCLVC5xd7vgSJ1s23fYu9BSmZ0a4K9p6P3csuzhIxa+QY+I0x/z3B0GUeiDNQHH1FOC+kyZNB0DBgQ3HN9neei0Y2hHY6XzoEqlGqPyD+zvH+i/vIvXNthYpX6lHjp3szrQr13vXj/kDB/2CTQBga9pBs11HdA/xG7ggJBxmmNYMHHUTC3dlD0RqtqsenlKB1WAphmtnz58yOLP1EcwgNb2owW+pfZdAf5qr4m+b97x8ZnjpDoin2Ftnbbeo1FUoPoofqJHWhvqN5r6r1e9M1amPoYf1YfQk+oePLeQne+pA9TD+/ZZY9O/X2iuShMwPvAwWg4btrhx797fP05zrQyYPN25VLsKZr2gUmncqf+bKpV6YM8eGzPGjFywXH0EY0h8P4JONnXyeHWsSqMaMHrU/BxiPkh9GLN8wtwakp2SuM6f6jstWaNW+471mWvv1flX9H92XauJ++0PWFmntYMyJ5BsTddoVAMnjJ+Z3a/fmgDVMbxuY5WhoOUtJ016M5xitNbP71WHbt02w7PfD4hsq0NGgww82XUT9vS5hT0dgGA8jQDsx1CcRlzzNDg9/SfGDFiKJb0ccLUBzUTnCJzEkV63cKI5IPc6hTY9tmNdb4ui9vM9Y5HgAOx4HPi1M/51xKMeFNDB2jYFxzunoEvf7zDmmRXY7SniJZu9+NGlGYIHALkK4Ed0xgs4CmILywF/wsI1odi4XZ5Avk0u7Fxi8QutddsO2DwoGX71duBhPgQeg9ddg8oV2/u+t3eHcVbXBIoJlqUiK0pvVD6GXIjquWT/gQnIyHCUd+/+0zCqz2zW9Ew8RMgFAT3DI8YdiYzwOQcZnvBsFzYMgvim2/+9FXfhUo/vNm+ZqQoL80Vult2dPBHvCwUbuBgaJ+2snsxMd1x95mw/KCy18TQvfTHxdPih0dG790zdIIpoIVpiduShMWF/7Aq4THsU0apexmi6sQdbvbb43JXozmFbt86YuWu3yv7atfYXafwr9evfeITyCyQKfWRyjLK0SF9o73xjOARd/VGjFljGxrb1zMmxE/JyrQdBEIdCnv+NXECPf650Grh6XXA4VCEipcU0B1DwkSiAPBUw8MiR0eF79vgdp3KyTsDCq9faRRw8OF4m6BAuk+UGQCcr0S5310vS9iSeQIs0Wy8hHycjIn0Sww5O2EbLTOzU/ZfukOlWHj41IfHE8cFLtu94pR8x1YoyOCuROZP60O2LC3JLBIk62Jw62W9G1IWeaNTs3HhtntIGoswSOcrsv849ezM83Gf2lp9nPXPihLc8M8PB89m+67xpfJpSmZ4DAU5yiyzl4cMj0eWULU41A840BVKO9oDdwU6Ipgfv2y7ZWIDBcHebgTdadsNbUe9g075puB3XCr+RICisM+GOFMIHnKbx3c7LERk5Bs1irCCJB62FdhEesKAIHz/pjSHHQyAghPZNs6QmvI/f6F8H+D76DMLy2qFReGuMPiRQKIAO7fZiV+KTyM2zwlkPOaQd1kuI1Nv1mC4BvyU++9Bxye2uIT3RAz3pW+CcDkTu9MN/Un0e6oOOvoe2NskWAMoV23wRaurLpwERkD1oi04QLPV1In45fnJwXFZWPVy72nG3rV1Sc4VFjqhvA6x0SqxISW2YlZDYIlUQce7Klcel9zK9k1NdJzg4xLZOTm/glJNji0ORI3+lG72eQ71EJX3T86TxVI767uvFp3NybKSiPtEcv4s6uZie5pxNN3YCLXQija6lOrqOvh7Xbhh1fF+bazNHzJd5xc9bJGi1yjPHTzz/F93ccU71ryupHTS2H/Xfv6YHjq3rjLg8GZbZ2SX9QmvvvxDVQ5ac1sCX+t1EcOBBnYhe9RxufSaKAv2thicUefcLFnWTpsPhtDSn7Px8hUjzRlNlwqlT3pcplxr/Tkpyl974lmiXi+sVZ31f6UOGuJDuiJAuExNaJtN8KXduNfqWyrl3khr3b996n3tmRv0xqWkNdFT3q0KhbUk5lJa5dOPDSybDD1GXeyWmpzshM83hkNRGRqSpNer27dvv3fKo60Zl5tK3hTsL5wp21inLHB3jJL/03YivPPkKfpIKjncKQvxoHI0meEKuAg6ZFFS7ZCzGJgQ3WYQPrx9GfMJC5OROx//+2Q2XFKCexxVpuD41vwnYZRZ8fRreUSCbZMBSSZPoW4EAHMBpzIOUvsNafa03zuIaZmKA5UloRQVezJ6GV7Mnos85YOKxTDyFi4iNexS73OujIdLQG5cR7QY8mZCCGHHWQ8c5H2uln/v+j5J8oO/GxebNT9Ur7Ev8S40t9fOgxKcBESj4xt1nUE6W/aNSUSbgOuVNKcG2XuxfUk6PH6Q10pccuWs6IkGqu5u0eVpL+puLFRM0M465ulwbMm70/A3PDVqBfgPWzJP6yGR5+rHSNX1Rbkr5/Slfh2QUHgIkYaNbpLAC2pxsm6YkOtvzV07b1PqRo22mRihDaf72Y8fO8aOb0UOpzEqk3m3pznYV8xBHL6dd6WX1/HXBITdDvLADovDV6bP9WpMAdqnvHPsL7cQsIKKLs2Psenq3dEYVoH5d7RcUqj6KbZ06/d6Q5tKfNPc9uwCtIEORXTIFcnO1Vg1Ks0sm0xUxpt3V/XPRYFsFLSIJ2vtDBn9y09IuQzNs+CcfensvsyFYb1gosmmvAjg3iG5L/eRaLcVEJ9OL0O2kFlEWihxSCME+LrYtPYBB4dQSP/ofkm/3i1D+IQqYJwg6ua1tMk0FUDl741jk0jyQ6fRVsMmRSgVJrgNc5ck4jcZIswaOtwBWDAI+GaTEskEC4umFgIVtWkFn+rR9YCxVQS6XwiZdQS84HUGPh56x2DkoUT9XSE8bfeOw6BR0bHAG7/RagMOtgWsSAWqZiEj8ea0vLjlYYazNfuQTuasNAIs4+qD2ksZRU9HZArdK9AEC2tnYJlkWdi4rtvQXqqhv4RjO65aA7MHlc7XW07Ky7R3PX+jRhNoW0Df9jyYtz2fQ9f0nac79RUAmz6ObB10V6QjKzKrXLSxsgvaPXeqcn7e+s/TfPQFBgP5GRAUOuhmyyJb2EyOsR2jzFOP37J3U/M89U85t2DDnFwAxzg2u/0n5S8nJbk0SbrV0pbtyBZX7kBhpKQfyFD/QzqRVfHxr16d7fxNLdZ1pc5Ea3BVn6RoQMFemw2tSunChRxLKechlebml2VXaNHJ5rpbETqTxXUn85ibEt265/8CLCTt2vKxLTW64QpDRQ6Ao/JGS6vqeVmtlfeF8f+nx8mVpThIvWFunJdFz6dlzfz09nXarspDVIaPWrFkVu+6Lz2NCumDot98unJeR4VgsVtL4h6W++Bsb4YXLaIiuF+V4amdjLNn5IQbudEHQTiDhVI+HDSuqa4A03IADckDbrbu13elRbVw44BMuYNnpIHwEbzSlB7JJe0kEz3vBhURyJ8ntro7AOBzFmczWiEp+BN09IhFDOqXUAlPuvFbiOG3HC7gNW2TTmrlQQIMwlOSDxOTIkRE37pp2N+PMmAgUEyxLy8xld257dIqO7vor3Ux59IvTVHrX4yI5lZ1Vr8Qvv6vrlV3UZ1zU370/pvc7fW/Etgukx6glSsu09ZmZ9ZyorUqnq0v0cZrA/uSxIT+dODHYO/qfzp+TuM6zsMhW3b7t0fextvvotsD8azEdul+J9lpKfbVk+5ip4XCi3dSk2b5Ts6huS2JCixg31+gmAtBb1OEg1enP1V0Qs6oboqVEj8F5+spyfNRzuHmFupVoF7WVeMppz+TokPC9tU3qVzH/ePru2+/bLCnVZYgoCmGnzvbfIuoEGT2marKz7cS4G236nr/UfRdEQRJiuDSIaQI62jQ79kJGWv30hMSWA23tkqMoZvnItQyaHg5rV7dLRY8/1LXMswuuYhE2ISLrMbxsNxTT4YMQfINHkYBkW0AgNUcphwr78TZG4zCao/CwJ+oNaGPmkibiu4zvqa0FWtm9CwVWYWvS0/g46jT6nwEu06OfjALYSwAADFFJREFUPbIxAichj2uIbJdkXHYF2sQDPyKkxHE2brFogiRMpn+3YYuROIGSfNCEw4P+wFDowYeREigmWLbWGac8PP7e5+29bI2/SqP2DwzKleXD194ueVfeilfs/uVniGYK7WB8pbpGHn+fp2vbtm0Pfjagf8girPW/qpmsXj5ixCcf0A2ZOHb0fH/6aX2h1Fef/jclm/oL0ye/e0Jflj5CNE9T3QLpUp9Wq+dSua90bWObkkLXzXr12qjq0mXrOp9+mp2+ozTb/aa89h9np9jdogBHal/U0XPXqJ49N25VqdRLVX5BgsIS0wB0nLtygyS2j8XdeGQZ9fWgQg+dHLuprfi5Wt2N5vq0qCFU9QFCVQOLyiGaMGqXHudgocjOousS7eradfM2apdefhcNp3IrYqF/sdOjx8ZvfH3fsm3W9PS2cT6zP8TKoHSy/f2nen2/SCYT5b4jpiXkrwrq0bzZmY9HjlzwtbvbRVtLZWZ+Q5eYntKET/b+Pj7hw4V9mjY+G/LShHe+pbFzZk+akpdhAc3woYvcaC0HqV9RWq0WeuFyUfFP/BezIW1SC6qCsBfLr+2Dn+sWrGy0BM/LTuEmyd5P3YDtNgvxDnai8GiCJIhQoxnu6Kuk/waRitcwMPciMqyATKW+uujDE9fxM+ntvM4LENlKg4vC++iOK/pHQknY8iHDX3DHmBuxSLEFol2BtrQXLm1cg6w8HMAn+DknFE4WKdBSVPwtHu4D/ZCzUB0UNIqYlCu2RYbzhcEQKCZYhZbRDf0zCdUr8lyspDodFPiM8jJPmYD1ooje0rsgnQXm0buRL2UybKPXJrP8I+FZ5gRldCCbttGfSGvpfY21M75APsIgYgOl/gGH8SLtlPaIOtomiFDRVJ+RH3lno3otQ/2kpVS2o93TKkGHwzRH/NrOuEp11XKWZVdpi5DN0uP0Jgh4VeJGvgy1ycNHNOZ8qrb1OXng8m1XYzqsS091dunS9ecFfZ9dlwgZfqN20FsuchEgEZ4jisgnv5bG2yFYEKBzt4Z+Nyb1q0hqHQ/0vAAcaQWs7QscaAs8S28xnehXuPLM04moRrYBpMe8B/sLZO1zJ4FEktEv+hS8J7vSEOh2TonXMRbpUCIgLwLN6Y2kA1EpXLOkcdILe9Ah/Qhgmw2sIXtv2wMP80Gnw8qVHXGNuvNppARKFCwSmkuru2EavbAeTc/+M4I7gb5CAN1ch1Z3xZgCfws+qf2/q72wSCqt8kIktUtjhlI+dWU3xAd3xjoaN5J+uTtNfV+nOX+Q+kppbgfkUt3Q0O6gW0SqAag8g/p/V1ACQrvia6qbKZWl+eh6CqWh1GdsSHdEhHRDGK31Qmg3fCv1oXwDladK7atXrl0Rvm/SP1TvA51sxOwQdT7d7I2hwx9UV+pJa7we0pXE724vmu/LYC+8d7cI8vU0rTNcKpdlF40LJTs/kPoWJho7lXzbLpVpna9ovaFSovr3l/RCFl2/+/PmmZ3z8y0ct29/5dJ36z96btsvb+7esfPlHkI+8kmgdGt7Qb+9Idtu0bg5NGYczeVP+WcSW2luajtEaax0XZikd1KNkgpLwMjDgPS+qbBGEp2X9gOqXQVtLe/7iWVsBNDl3iYN0u5Imk8SGGm8JwmWNG7YUalUPDVMBYYcA/zoraM0bmSYFdokfY6N8MIWrIKCnJP+42k72l3hvuPBcRPDAPe7PljnAmMigcDfgUZ6IsCDPtD3QnptoJ+R+JQ7tvoB/GEQBO4J1qppSaDHhee9F5wzCMuqy4h1U9Mkvyi5+foEXL5xFIG0G7Fyy4BeKKprmRqbZ63/HbL9KfoV822VWr1i8nj15EB/tYJ8eI52ZLTvqbGVa21i6d2VCDXiMQNtFdex7zHoH+3a816o1mJgLAvdEyxjsbiSdqqOwsbGGevpUamnPB8L5vZBXiWnqpNhefYIhgh7pT025sswHzqk6JSQHnNhKkcuvX8K7UfvrlwA7xMA7fJNxTX2o5oIFBOsdU8ijbbLQ6Vfy6ppDYOYhh6JMiW/KL1kjL6ta4s08uEtsl96FH6RHi8/XtMR9z2o1TjmGl/AMg/6/z7htweQHv9qfEFewOgIFBMso/OADa4wAWE1BHNMFQbFAwyOAAuWwYWEDWICTKAkAixYJZHheiZgxgQM1XUWLEONDNvFBJhAMQIsWMWQcAUTYAKGSoAFy1Ajw3YxASZQjAALVjEkVa/gGZgAE6gZAixYNcOVZ2UCTKAGCLBg1QBUnpIJMIGaIcCCVTNceVZzIcB+1ioBFqxaxc2LMQEmUBUCLFhVocdjmQATqFUCLFi1ipsXYwJMoCoE6lawqmI5j2UCTMDsCLBgmV3I2WEmYLwEWLCMN3ZsORMwOwIsWGYX8rpymNdlAlUnwIJVdYY8AxNgArVEgAWrlkDzMkyACVSdAAtW1RnyDEyACfybQI2VWLBqDC1PzASYQHUTYMGqbqI8HxNgAjVGgAWrxtDyxEyACVQ3ARas6iZa9fl4BibABEogwIJVAhiuZgJMwPAIsGAZXkzYIibABEogwIJVAhiuZgK1QYDXqBgBFqyK8eLeTIAJ1CEBFqw6hM9LMwEmUDECLFgV48W9mQATqEMCRi1YdciNl2YCTKAOCLBg1QF0XpIJMIHKEWDBqhw3HsUEmEAdEGDBqgPovGQlCPAQJkAEWLAIAp9MgAkYBwEWLOOIE1vJBJgAEWDBIgh8MgEmYEgESraFBatkNtzCBJiAgRFgwTKwgLA5TIAJlEyABatkNtzCBJiAgRFgwTKwgFTdHJ6BCZguARYs040te8YETI4AC5bJhZQdYgKmS4AFy3Rjy56ZPgGz85AFy+xCzg4zAeMlwIJlvLFjy5mA2RFgwTK7kLPDTMB4CZizYBlv1NhyJmCmBFiwzDTw7DYTMEYCLFjGGDW2mQmYKQEWLDMNvLm5zf6aBgEWLNOII3vBBMyCAAuWWYSZnWQCpkGABcs04sheMAGzIFAuwTILEuwkE2ACBk+ABcvgQ8QGMgEmUEiABauQBOdMgAkYPAEWLIMPUS0byMsxAQMmwIJlwMFh05gAE/g3ARasf/PgEhNgAgZMgAXLgIPDpjGBmiVgfLOzYBlfzNhiJmC2BFiwzDb07DgTMD4CLFjGFzO2mAmYLQEWrEqHngcyASZQ2wRYsGqbOK/HBJhApQmwYFUaHQ9kAkygtgmwYNU2cV7PGAmwzQZCgAXLQALBZjABJlA2ARasshlxDybABAyEAAuWgQSCzWACTKBsArUhWGVbwT2YABNgAuUgwIJVDkjchQkwAcMgwIJlGHFgK5gAEygHARasckDiLuUnwD2ZQE0SYMGqSbo8NxNgAtVKgAWrWnHyZEyACdQkARasmqTLczMBUyZQB76xYNUBdF6SCTCByhFgwaocNx7FBJhAHRBgwaoD6LwkE2AClSPAglU5blUfxTMwASZQYQIsWBVGxgOYABOoKwIsWHVFntdlAkygwgRYsCqMjAcwgYoS4P7VRYAFq7pI8jxMgAnUOAEWrBpHzAswASZQXQRYsKqLJM/DBJhAjRMwAsGqcQa8ABNgAkZCgAXLSALFZjIBJgCwYPG3gAkwAaMhwIJlNKEyC0PZSSZQKgEWrFLxcCMTYAKGRIAFy5CiwbYwASZQKgEWrFLxcCMTYAI1RaAy87JgVYYaj2ECTKBOCLBg1Ql2XpQJMIHKEGDBqgw1HsMEmECdEGDBqhPsVV+UZ2AC5kiABcsco84+MwEjJcCCZaSBY7OZgDkSYMEyx6izz8ZFgK0tIsCCVYSCL5gAEzB0AixYhh4hto8JMIEiAixYRSj4ggkwAUMnYPqCZegRYPuYABMoNwEWrHKj4o5MgAnUNQEWrLqOAK/PBJhAuQmwYJUbFXc0fAJsoakTYMEy9Qizf0zAhAiwYJlQMNkVJmDqBFiwTD3C7B8TMCEC9wmWCXnFrjABJmCSBFiwTDKs7BQTME0CLFimGVf2igmYJAEWLJMMa5lOcQcmYJQEWLCMMmxsNBMwTwIsWOYZd/aaCRglARYsowwbG80Eyk/AlHqyYJlSNNkXJmDiBFiwTDzA7B4TMCUCLFimFE32hQmYOAEWrDICzM1MgAkYDgEWLMOJBVvCBJhAGQRYsMoAxM1MgAkYDgEWLMOJBVtS1wR4fYMnwIJl8CFiA5kAEygkwIJVSIJzJsAEDJ4AC5bBh4gNZAJMoJDA/wMAAP//hPVvjQAAAAZJREFUAwDAEzbDVT6aPgAAAABJRU5ErkJggg==	Google Inc. (Intel)|ANGLE (Intel, Mesa Intel(R) UHD Graphics 630 (CFL GT2), OpenGL 4.6)	test	test	t	2025-11-25 22:35:38.35338-08	2025-11-25 22:35:38.35338-08	1
\.


--
-- Data for Name: insurance_plans; Type: TABLE DATA; Schema: pharmacy; Owner: postgres
--

COPY pharmacy.insurance_plans (id, plan_name, payer_name, payer_id, bin, pcn, group_number, phone_number, notes, active, created_at, updated_at) FROM stdin;
7f3f4392-25f8-4169-a9d3-ed93c46d2dde	Kaiser Bronze Essential	Kaiser Permanente	KP44321	999888	KSRX	BRZ1000	1-800-813-2000	Common plan used in Washington state for individual marketplace enrollees.	t	2025-11-26 17:26:43.133749-08	2025-11-26 17:26:43.133749-08
02ea9fe6-9d1c-4035-896a-f31cff5668e7	Humana Classic PDP	Humana	HUM33445	015581	HUMRX	HMCL2025	1-800-281-6918	Deactivated for 2025; kept for audit and historical patient references.	f	2025-11-26 17:26:43.133749-08	2025-11-26 17:26:43.133749-08
63f37428-a7dd-4e63-890d-8eeed90c7056	test	test	1111	111	test	1234	4257706899	test	t	2025-11-26 19:30:12.930188-08	2025-11-26 19:30:12.930188-08
33227d99-7e36-416a-8361-ac65e28d91da	Cigna Preferred Rx Plus	Cigna Health	CIG55678	017010	MEDDPRIM	RXPLS2025	1-800-997-1654		t	\N	2025-11-26 20:06:04.110181-08
\.


--
-- Data for Name: inventory_items; Type: TABLE DATA; Schema: pharmacy; Owner: postgres
--

COPY pharmacy.inventory_items (id, ndc, name, strength, form, pack_size, dea_schedule, is_controlled, on_hand, reorder_threshold, reorder_quantity, reorder_rule_id, manufacturer, attributes, active, created_at, updated_at) FROM stdin;
1e557ff4-ecb3-4104-a0e5-a23c378ca245	00093-7424-56	Amoxicillin	500 mg	Capsule	100	\N	f	45	20	80	1	Teva Pharmaceuticals	{"storage": "room_temp", "category": "antibiotic"}	t	2025-11-26 23:52:54.669836-08	2025-11-26 23:52:54.669836-08
c9680ab0-1f71-4222-8722-b80ce3382337	00406-2028-01	Oxycodone	5 mg	Tablet	100	CII	t	12	5	15	2	Mallinckrodt	{"opioid": true, "risk_level": "high"}	t	2025-11-26 23:52:54.669836-08	2025-11-26 23:52:54.669836-08
137cb68e-82ba-40e5-840d-8e59a1df3f62	50580-488-10	Ibuprofen	200 mg	Tablet	500	\N	f	150	30	100	3	Perrigo	{"otc": true, "seasonal_demand": "winter"}	t	2025-11-26 23:52:54.669836-08	2025-11-26 23:52:54.669836-08
0f6a63c4-3e41-456f-afb9-110a944130d0	00054-0123-25	Levothyroxine	50 mcg	Tablet	90	\N	f	28	10	20	4	Sandoz	{"storage": "room_temp", "chronic_med": true}	t	2025-11-26 23:52:54.669836-08	2025-11-26 23:52:54.669836-08
112ade70-2121-4ac0-9303-afc6514f3151	00002-8215-01	Humira	40 mg/0.8 mL	Injection	2	\N	f	1	1	2	5	AbbVie	{"category": "biologic", "refrigerated": true}	t	2025-11-26 23:52:54.669836-08	2025-11-26 23:52:54.669836-08
\.


--
-- Data for Name: patient_insurances; Type: TABLE DATA; Schema: pharmacy; Owner: postgres
--

COPY pharmacy.patient_insurances (id, patient_id, insurance_plan_id, member_id, rx_group, coverage_start, coverage_end, is_primary, is_secondary, is_tertiary, created_at, updated_at) FROM stdin;
1f892453-f0ac-441a-85e6-d3d5dc14f24e	cd4503e0-f600-4c42-8d3d-ecc4d04a29ed	33227d99-7e36-416a-8361-ac65e28d91da	1111	\N	\N	\N	t	f	f	2025-11-26 20:11:17.831056-08	2025-11-26 20:11:17.831056-08
\.


--
-- Data for Name: patients; Type: TABLE DATA; Schema: pharmacy; Owner: postgres
--

COPY pharmacy.patients (id, mrn, first_name, last_name, dob, gender, contact, sensitive_data, encrypted_at, is_student_record, preferred_language, accessibility_preferences, created_at, updated_at, updated_by) FROM stdin;
cd4503e0-f600-4c42-8d3d-ecc4d04a29ed	MRN001	James	Anderson	2025-10-15	male	\N	\N	\N	f	\N	\N	\N	2025-11-26 20:11:17.768914-08	\N
\.


--
-- Data for Name: prescribers; Type: TABLE DATA; Schema: pharmacy; Owner: postgres
--

COPY pharmacy.prescribers (id, npi, dea_number, state_license_number, upin, taxonomy_code, first_name, last_name, middle_name, suffix, clinic_name, clinic_contact, contact, epcs_enabled, erx_identifier, ncpdp_provider_id, active, created_at, updated_at) FROM stdin;
5de8a70a-79de-401c-97f3-8a9ada0f342f	1234	1235		\N		James	Rodriguez			Everett	{}	{}	f	\N	\N	t	2025-11-26 20:27:42.588986-08	2025-11-26 20:27:42.588986-08
f85f3e82-6b68-41c0-90ae-af2101a0f2c9	1212121	343434		\N		David	Mai			Everett	{}	{}	f	\N	\N	t	2025-11-26 23:55:47.414822-08	2025-11-26 23:55:47.414822-08
ef15a799-ca27-4307-9e16-a533ba87de3a	43434	3434		\N		Sarah	Chen			Seattle	{}	{}	f	\N	\N	t	2025-11-26 23:56:02.93384-08	2025-11-26 23:56:02.93384-08
\.


--
-- Data for Name: prescription_queue; Type: TABLE DATA; Schema: pharmacy; Owner: postgres
--

COPY pharmacy.prescription_queue (id, prescription_id, workflow_step, workflow_status, assigned_to, assigned_at, queue_name, is_active, created_at) FROM stdin;
ff001998-3cf7-45da-a422-36a608a686ab	8ea527cd-9d69-496b-b335-f887d9c1ddfd	PATIENT_PICKUP	COMPLETED	\N	\N	PICKUP	f	2025-11-27 00:36:04.908606-08
bfc5954e-d98d-419c-9baf-920f678d7571	bf5683d5-c65b-4d8a-a854-cd2f1c715000	QA_VERIFICATION	QA_VERIFICATION	\N	\N	QA	t	2025-11-27 00:37:45.466449-08
c11f2c01-c4b9-4775-a80b-eb49306509dc	6d81101a-90e7-499e-a565-341da8620707	INTAKE	PENDING	\N	\N	INTAKE	t	2025-11-27 00:43:04.445701-08
e85da236-165d-4fb7-a5c2-da992444bd52	b8635e04-b3a6-488e-85e0-218d9ee13006	PHARMACIST_REVIEW	DENIED	\N	\N	PHARMACIST_REVIEW	f	2025-11-27 00:43:27.430404-08
\.


--
-- Data for Name: prescription_workflow_events; Type: TABLE DATA; Schema: pharmacy; Owner: postgres
--

COPY pharmacy.prescription_workflow_events (id, prescription_id, previous_step, previous_status, new_step, new_status, changed_by, changed_at, note) FROM stdin;
\.


--
-- Data for Name: prescriptions; Type: TABLE DATA; Schema: pharmacy; Owner: postgres
--

COPY pharmacy.prescriptions (id, patient_id, prescriber_id, drug_id, quantity, days_supply, refills, sig, written_date, received_date, current_step, current_status, priority, source, note, intake_completed_at, pharmacist_assigned_at, pharmacist_reviewed_at, patient_info_requested_at, provider_info_requested_at, denial_recorded_at, fill_queue_assigned_at, filling_started_at, special_order_created_at, fill_completed_at, qa_started_at, qa_failed_at, ready_for_pickup_at, picked_up_at, delivery_dispatched_at, delivery_confirmed_at, completed_at, cancelled_at, created_at, updated_at) FROM stdin;
b8635e04-b3a6-488e-85e0-218d9ee13006	cd4503e0-f600-4c42-8d3d-ecc4d04a29ed	f85f3e82-6b68-41c0-90ae-af2101a0f2c9	1e557ff4-ecb3-4104-a0e5-a23c378ca245	30.00	30	2	Take 1 tablet by mouth once daily	2025-01-15	2025-11-27 00:01:45.092199-08	PATIENT_PICKUP	COMPLETED	NORMAL	eRx	Completed chronic med refill	2025-11-24 00:01:45.092199-08	2025-11-24 04:01:45.092199-08	2025-11-24 06:01:45.092199-08	\N	\N	\N	2025-11-24 12:01:45.092199-08	2025-11-24 14:01:45.092199-08	\N	2025-11-24 16:01:45.092199-08	2025-11-24 17:01:45.092199-08	\N	2025-11-24 18:01:45.092199-08	2025-11-24 23:01:45.092199-08	\N	\N	2025-11-25 00:01:45.092199-08	\N	2025-11-27 00:01:45.092199-08	2025-11-27 00:01:45.092199-08
6d81101a-90e7-499e-a565-341da8620707	cd4503e0-f600-4c42-8d3d-ecc4d04a29ed	ef15a799-ca27-4307-9e16-a533ba87de3a	1e557ff4-ecb3-4104-a0e5-a23c378ca245	20.00	10	0	Take 2 capsules every 6 hours as needed	2025-02-02	2025-11-27 00:04:25.190174-08	QA_VERIFICATION	QA_VERIFICATION	STAT	fax	Urgent pain medication review	2025-11-26 00:04:25.190174-08	2025-11-26 04:04:25.190174-08	2025-11-26 06:04:25.190174-08	\N	\N	\N	2025-11-26 08:04:25.190174-08	2025-11-26 09:04:25.190174-08	\N	2025-11-26 11:04:25.190174-08	2025-11-26 12:04:25.190174-08	\N	\N	\N	\N	\N	\N	\N	2025-11-27 00:04:25.190174-08	2025-11-27 00:04:25.190174-08
bf5683d5-c65b-4d8a-a854-cd2f1c715000	cd4503e0-f600-4c42-8d3d-ecc4d04a29ed	f85f3e82-6b68-41c0-90ae-af2101a0f2c9	137cb68e-82ba-40e5-840d-8e59a1df3f62	90.00	90	3	Take 1 tablet each morning	2025-02-10	2025-11-27 00:05:39.791381-08	INTAKE_RECEIVED	NEW	NORMAL	walk-in	New-start maintenance medication	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2025-11-27 00:05:39.791381-08	2025-11-27 00:05:39.791381-08
8ea527cd-9d69-496b-b335-f887d9c1ddfd	cd4503e0-f600-4c42-8d3d-ecc4d04a29ed	ef15a799-ca27-4307-9e16-a533ba87de3a	c9680ab0-1f71-4222-8722-b80ce3382337	15.00	5	0	Take 1 tablet twice a day	2025-01-29	2025-11-27 00:06:47.88877-08	PHARMACIST_REVIEW	DENIED	ASAP	phone	Drug interaction detected	2025-11-25 00:06:47.88877-08	2025-11-25 04:06:47.88877-08	2025-11-25 06:06:47.88877-08	\N	\N	2025-11-25 06:06:47.88877-08	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2025-11-27 00:06:47.88877-08	2025-11-27 00:06:47.88877-08
\.


--
-- Data for Name: reorder_rules; Type: TABLE DATA; Schema: pharmacy; Owner: postgres
--

COPY pharmacy.reorder_rules (id, rule_name, description, min_on_hand, max_stock_level, reorder_quantity, lead_time_days, seasonal, is_controlled, active) FROM stdin;
1	Fast Movers	High-volume drugs; keep stock high to avoid outages	20	100	80	3	f	f	t
2	Controlled CII Rule	Strict limit for Schedule II medications; keep minimal on-hand	5	20	15	7	f	t	t
3	OTC Seasonal Boost	Increase stock during flu/cold season (Nov–Mar)	15	120	100	4	t	f	t
4	Slow Movers	Low-demand medications; reorder small quantities	3	15	12	5	f	f	t
5	Specialty High-Cost	Keep minimal inventory of expensive specialty drugs	1	5	4	10	f	f	t
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: pharmacy; Owner: postgres
--

COPY pharmacy.roles (id, role_name, display_name, description, active, created_at, updated_at) FROM stdin;
1	ADMIN	Administrator	Full system access, manage users, roles, and workflow configuration	t	2025-11-24 01:07:28.51938-08	2025-11-24 01:07:28.51938-08
2	SYSTEM	System Account	System-level role used for automated processes and background tasks	t	2025-11-24 01:07:28.51938-08	2025-11-24 01:07:28.51938-08
3	PHARMACIST	Pharmacist	Can verify prescriptions, approve clinical checks, and perform final verification	t	2025-11-24 01:07:28.51938-08	2025-11-24 01:07:28.51938-08
4	CLINICAL_PHARMACIST	Clinical Pharmacist	Performs clinical reviews, DUR checks, interaction checks, and counselling	t	2025-11-24 01:07:28.51938-08	2025-11-24 01:07:28.51938-08
5	TECH	Pharmacy Technician	Supports prescription processing, data entry, and order fulfillment	t	2025-11-24 01:07:28.51938-08	2025-11-24 01:07:28.51938-08
6	INTAKE_TECH	Intake Technician	Handles new prescription intake, scanning, and demographic verification	t	2025-11-24 01:07:28.51938-08	2025-11-24 01:07:28.51938-08
7	CALL_CENTER	Call Center Agent	Handles patient communication, refill requests, and status inquiries	t	2025-11-24 01:07:28.51938-08	2025-11-24 01:07:28.51938-08
8	DELIVERY_TECH	Delivery Technician	Handles delivery routing, handoff, and signature capture	t	2025-11-24 01:07:28.51938-08	2025-11-24 01:07:28.51938-08
9	SUPERVISOR	Pharmacy Supervisor	Manages workflow escalations and oversees technician work	t	2025-11-24 01:07:28.51938-08	2025-11-24 01:07:28.51938-08
10	AUDITOR	Auditor	Has read-only access to prescriptions, logs, and user activity	t	2025-11-24 01:07:28.51938-08	2025-11-24 01:07:28.51938-08
\.


--
-- Data for Name: stations; Type: TABLE DATA; Schema: pharmacy; Owner: postgres
--

COPY pharmacy.stations (id, station_prefix, department, location, starting_number, current_number, max_stations, created_at, updated_at) FROM stdin;
1	RX	test	local	1	1	\N	2025-11-25 21:19:59.319419-08	2025-11-25 21:19:59.319419-08
2	RX	test	test	1	1	\N	2025-11-25 21:20:54.188642-08	2025-11-25 21:20:54.188642-08
\.


--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: pharmacy; Owner: postgres
--

COPY pharmacy.user_roles (user_id, role_id, assigned_at) FROM stdin;
11111111-2222-3333-4444-555555555555	1	2025-11-24 23:38:39.334478-08
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: pharmacy; Owner: postgres
--

COPY pharmacy.users (id, username, display_name, email, active, created_at, updated_at) FROM stdin;
11111111-2222-3333-4444-555555555555	testuser	Test User	paul.mai@datascience9.com	t	2025-11-24 00:39:01.004205-08	2025-11-24 00:39:01.004205-08
\.


--
-- Data for Name: workflow_statuses; Type: TABLE DATA; Schema: pharmacy; Owner: postgres
--

COPY pharmacy.workflow_statuses (status_code, description, is_terminal) FROM stdin;
NEW	Prescription newly entered	f
INTAKE_REVIEW	Intake completeness review in progress	f
READY_FOR_PHARMACIST	Waiting for pharmacist clinical review	f
PHARMACIST_REVIEW	Pharmacist performing clinical review	f
NEEDS_PATIENT_INFO	Waiting for patient clarification	f
NEEDS_PROVIDER_INFO	Waiting for provider clarification	f
DENIED	Prescription denied by pharmacist	t
READY_FOR_FILL	Waiting for technician filling	f
FILLING	Technician is filling the prescription	f
NEED_SPECIAL_ORDER	No stock available; special order required	f
FILLED	Prescription filled and ready for QA	f
QA_VERIFICATION	Pharmacist performing QA verification	f
QA_FAILED	QA verification failed; returned to filling	f
READY_FOR_PICKUP	Prescription bagged and ready for pickup	f
PICKED_UP	Patient picked up prescription	t
READY_FOR_DELIVERY	Ready for delivery dispatch	f
DELIVERED	Delivered to patient	t
COMPLETED	Prescription fully completed and archived	t
CANCELLED	Prescription cancelled	t
\.


--
-- Data for Name: workflow_steps; Type: TABLE DATA; Schema: pharmacy; Owner: postgres
--

COPY pharmacy.workflow_steps (step_code, step_name, description, default_status, allowed_roles, sla_minutes, sort_order, is_terminal, is_active) FROM stdin;
INTAKE_RECEIVED	Intake Received	Prescription entered into system	NEW	\N	5	1	f	t
INTAKE_VALIDATION	Intake Validation	Completeness review by tech	INTAKE_REVIEW	\N	10	2	f	t
PHARMACIST_ASSIGNMENT	Pharmacist Assignment	Waiting for pharmacist	READY_FOR_PHARMACIST	\N	10	3	f	t
PHARMACIST_REVIEW	Pharmacist Review	Clinical checking	PHARMACIST_REVIEW	\N	15	4	f	t
INFO_REQUIRED_PATIENT	Patient Information Needed	Need clarification from patient	NEEDS_PATIENT_INFO	\N	1440	5	f	t
INFO_REQUIRED_PROVIDER	Provider Information Needed	Need clarification from prescriber	NEEDS_PROVIDER_INFO	\N	1440	6	f	t
PHARMACIST_DENIAL	Therapy Denied	Pharmacist denied therapy	DENIED	\N	0	7	f	t
FILL_QUEUE_ASSIGNMENT	Fill Queue Assignment	Waiting for fill	READY_FOR_FILL	\N	10	8	f	t
PRESCRIPTION_FILLING	Prescription Filling	Tech filling prescription	FILLING	\N	20	9	f	t
SPECIAL_ORDER	Special Order Required	Out of stock, ordering drug	NEED_SPECIAL_ORDER	\N	1440	10	f	t
FILL_COMPLETED	Fill Completed	Ready for QA check	FILLED	\N	5	11	f	t
QA_VERIFICATION	QA Verification	Pharmacist verifying fill	QA_VERIFICATION	\N	10	12	f	t
QA_FAILED	QA Failed	Returned to filling	QA_FAILED	\N	5	13	f	t
READY_FOR_PICKUP	Ready for Pickup	Bagged and waiting	READY_FOR_PICKUP	\N	1440	14	f	t
PATIENT_PICKUP	Patient Pickup	Patient picked up prescription	PICKED_UP	\N	0	15	f	t
DELIVERY_DISPATCH	Delivery Dispatch	Prepared for delivery route	READY_FOR_DELIVERY	\N	60	16	f	t
DELIVERY_CONFIRMED	Delivery Confirmed	Delivered successfully	DELIVERED	\N	0	17	f	t
PRESCRIPTION_COMPLETED	Archived	Prescription workflow closed	COMPLETED	\N	0	18	f	t
CANCELLED	Cancelled	Prescription cancelled	CANCELLED	\N	0	19	f	t
\.


--
-- Data for Name: workflow_transitions; Type: TABLE DATA; Schema: pharmacy; Owner: postgres
--

COPY pharmacy.workflow_transitions (id, from_step, to_step, allowed_roles) FROM stdin;
1	INTAKE_RECEIVED	INTAKE_VALIDATION	{TECH,PHARMACY,ADMIN}
2	INTAKE_VALIDATION	PHARMACIST_ASSIGNMENT	{TECH,PHARMACY,ADMIN}
3	INTAKE_VALIDATION	INFO_REQUIRED_PATIENT	{TECH,PHARMACY}
4	INTAKE_VALIDATION	INFO_REQUIRED_PROVIDER	{TECH,PHARMACY}
5	PHARMACIST_ASSIGNMENT	PHARMACIST_REVIEW	{PHARMACIST,ADMIN}
6	PHARMACIST_REVIEW	INFO_REQUIRED_PATIENT	{PHARMACIST}
7	PHARMACIST_REVIEW	INFO_REQUIRED_PROVIDER	{PHARMACIST}
8	PHARMACIST_REVIEW	PHARMACIST_DENIAL	{PHARMACIST,ADMIN}
9	PHARMACIST_REVIEW	FILL_QUEUE_ASSIGNMENT	{PHARMACIST,ADMIN}
10	FILL_QUEUE_ASSIGNMENT	PRESCRIPTION_FILLING	{TECH,PHARMACY}
11	PRESCRIPTION_FILLING	SPECIAL_ORDER	{TECH,PHARMACY}
12	PRESCRIPTION_FILLING	FILL_COMPLETED	{TECH,PHARMACY}
13	FILL_COMPLETED	QA_VERIFICATION	{PHARMACIST,ADMIN}
14	QA_VERIFICATION	QA_FAILED	{PHARMACIST,ADMIN}
15	QA_FAILED	PRESCRIPTION_FILLING	{TECH,PHARMACY}
16	QA_VERIFICATION	READY_FOR_PICKUP	{PHARMACIST,ADMIN}
17	READY_FOR_PICKUP	PATIENT_PICKUP	{TECH,PHARMACY,CASHIER,ADMIN}
18	PATIENT_PICKUP	PRESCRIPTION_COMPLETED	{SYSTEM,ADMIN}
19	READY_FOR_PICKUP	DELIVERY_DISPATCH	{TECH,PHARMACY,ADMIN}
20	DELIVERY_DISPATCH	DELIVERY_CONFIRMED	{DELIVERY,ADMIN}
21	DELIVERY_CONFIRMED	PRESCRIPTION_COMPLETED	{SYSTEM,ADMIN}
22	INTAKE_RECEIVED	CANCELLED	{PHARMACIST,ADMIN}
23	INTAKE_VALIDATION	CANCELLED	{PHARMACIST,ADMIN}
24	PHARMACIST_REVIEW	CANCELLED	{PHARMACIST,ADMIN}
25	PRESCRIPTION_FILLING	CANCELLED	{PHARMACIST,ADMIN}
26	SPECIAL_ORDER	CANCELLED	{PHARMACIST,ADMIN}
27	READY_FOR_PICKUP	CANCELLED	{PHARMACIST,ADMIN}
\.


--
-- Data for Name: access_logs; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.access_logs (id, user_id, patient_id, entity_type, entity_id, action, access_reason, access_context, ip_address, user_agent, accessed_at) FROM stdin;
\.


--
-- Data for Name: auth_logs; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.auth_logs (id, user_id, username, event_type, status, ip_address, user_agent, metadata, created_at) FROM stdin;
147	11111111-2222-3333-4444-555555555555	testuser	logout	success	127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-25 19:34:09.378157-08
148	11111111-2222-3333-4444-555555555555	testuser	login	success	127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-25 19:34:09.885237-08
149	11111111-2222-3333-4444-555555555555	testuser	login	success	127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-25 19:34:09.885974-08
1	11111111-2222-3333-4444-555555555555	testuser	logout	success	127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	{"eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-12-02 23:56:14.89572-08
2	11111111-2222-3333-4444-555555555555	testuser	login	success	127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	{"eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-12-02 23:56:15.603584-08
3	11111111-2222-3333-4444-555555555555	testuser	logout	success	127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	{"eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-12-04 21:23:42.065942-08
4	11111111-2222-3333-4444-555555555555	testuser	login	success	127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	{"eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-12-04 21:23:42.798672-08
5	11111111-2222-3333-4444-555555555555	testuser	login	success	127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	{"eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-12-16 14:04:18.082841-08
6	11111111-2222-3333-4444-555555555555	testuser	login	success	127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	{"eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-12-16 15:40:04.30549-08
7	11111111-2222-3333-4444-555555555555	testuser	login	success	127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	{"eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-12-16 15:59:12.494954-08
8	11111111-2222-3333-4444-555555555555	testuser	login	success	127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	{"eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-12-16 16:04:16.423676-08
9	11111111-2222-3333-4444-555555555555	testuser	login	success	127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	{"eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-12-16 17:06:17.426263-08
10	11111111-2222-3333-4444-555555555555	testuser	logout	success	127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	{"eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-12-16 23:57:48.644447-08
11	11111111-2222-3333-4444-555555555555	testuser	login	success	127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	{"eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-12-16 23:57:51.508317-08
12	11111111-2222-3333-4444-555555555555	testuser	login	success	127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	{"eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-12-16 23:57:53.443696-08
\.


--
-- Data for Name: claim_transactions; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.claim_transactions (id, claim_id, transaction_code, status, reject_codes, request_json, response_json, created_at) FROM stdin;
80f60e80-a822-44a5-ade9-0fac74dc0444	4dc396f7-4f3e-49d1-9e9b-320e51e03d70	B1	paid	\N	{"ndc": "00179012330", "qty": 90, "action": "submit"}	{"status": "approved", "plan_paid": 60.00, "patient_pay": 12.50}	2025-12-12 20:19:20.508701-08
1715b432-ff5a-448d-8379-40d3498d6117	54d2fff2-cdfb-4e52-99a2-3d72f76b9fb0	B1	paid	\N	{"ndc": "00179012330", "qty": 90, "action": "submit"}	{"status": "approved", "plan_paid": 60.00, "patient_pay": 12.50}	2025-12-12 20:25:33.930301-08
1137d7f5-903a-432b-98ac-d0b83ec87f9c	c45144e8-b25f-4027-9baf-8401da16b79f	B1	rejected	{79,75}	{"ndc": "00054027225", "qty": 30, "action": "submit"}	{"message": "Refill too soon / PA required", "rejects": ["79", "75"]}	2025-12-12 19:26:01.159939-08
4a0d2d5c-c4be-44ab-871a-702565d79b9a	99a6c742-65e0-4874-ae5c-bc07079ded49	B2	reversed	\N	{"action": "reverse", "reason": "returned medication"}	{"status": "reversed"}	2025-12-12 18:26:27.065473-08
b467ac64-7f3a-4f8e-b9b8-1c0a89e7601f	c45144e8-b25f-4027-9baf-8401da16b79f	B3	paid	\N	{"ndc": "00378301501", "qty": 15, "action": "rebill"}	{"status": "paid", "plan_paid": 32.00, "patient_pay": 8.00}	2025-12-12 20:56:47.997877-08
\.


--
-- Data for Name: claims; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.claims (id, patient_id, patient_insurance_id, prescription_id, bin, pcn, group_id, payer_id, transaction_code, claim_number, claim_status, submitted_uac, submitted_ingredient_cost, submitted_dispensing_fee, submitted_qty, submitted_days_supply, plan_paid_amount, patient_pay_amount, total_amount, reject_codes, request_json, response_json, submitted_at, processed_at, created_at, updated_at) FROM stdin;
31e62573-cc19-44f5-a6ef-d0e697cba842	750e8400-e29b-41d4-a716-446655440003	850e8400-e29b-41d4-a716-446655440004	b8635e04-b3a6-488e-85e0-218d9ee13006	610502	RX	12345	CAREMARK	B1	CLM-d80a4c8d	submitted	55.00	48.00	7.00	30.00	30	\N	\N	\N	\N	{"ndc": "00093015001", "qty": 30}	\N	2025-12-12 21:13:11.658175-08	\N	2025-12-12 21:13:11.658175-08	2025-12-12 21:13:11.658175-08
4dc396f7-4f3e-49d1-9e9b-320e51e03d70	750e8400-e29b-41d4-a716-446655440002	850e8400-e29b-41d4-a716-446655440001	8ea527cd-9d69-496b-b335-f887d9c1ddfd	004336	ADV	GRP01	OPTUM	B1	CLM-82375484	paid	72.50	65.00	7.50	90.00	90	60.00	12.50	72.50	\N	{"ndc": "00179012330", "qty": 90}	{"paid": 60.00, "status": "approved"}	2025-12-10 21:14:11.808716-08	2025-12-11 21:14:11.808716-08	2025-12-12 21:14:11.808716-08	2025-12-12 21:14:11.808716-08
c45144e8-b25f-4027-9baf-8401da16b79f	750e8400-e29b-41d4-a716-446655440003	850e8400-e29b-41d4-a716-446655440003	b8635e04-b3a6-488e-85e0-218d9ee13006	015581	NCPDP	PHS01	EXPRESS	B1	CLM-595b9387	rejected	110.00	100.00	10.00	30.00	30	0.00	0.00	0.00	{79,75}	{"ndc": "00054027225"}	{"message": "Refill too soon", "rejects": ["79", "75"]}	2025-12-09 21:15:59.319131-08	2025-12-09 21:15:59.319131-08	2025-12-12 21:15:59.319131-08	2025-12-12 21:15:59.319131-08
99a6c742-65e0-4874-ae5c-bc07079ded49	750e8400-e29b-41d4-a716-446655440003	850e8400-e29b-41d4-a716-446655440001	8ea527cd-9d69-496b-b335-f887d9c1ddfd	012833	CLAIM	RX01	HUMANA	B2	CLM-bf842ee1	reversed	85.00	75.00	10.00	60.00	30	0.00	0.00	0.00	\N	{"reason": "patient returned medication", "transaction": "reverse"}	{"status": "reversed"}	2025-12-07 21:16:28.429765-08	2025-12-08 21:16:28.429765-08	2025-12-12 21:16:28.429765-08	2025-12-12 21:16:28.429765-08
54d2fff2-cdfb-4e52-99a2-3d72f76b9fb0	750e8400-e29b-41d4-a716-446655440002	850e8400-e29b-41d4-a716-446655440001	6d81101a-90e7-499e-a565-341da8620707	017010	MEDD	AET01	AETNA	B3	CLM-46930b54	paid	40.00	35.00	5.00	15.00	15	32.00	8.00	40.00	\N	{"ndc": "00378301501", "rebill": true}	{"status": "paid", "plan_paid": 32.00}	2025-12-11 21:16:56.005496-08	2025-12-12 21:16:56.005496-08	2025-12-12 21:16:56.005496-08	2025-12-12 21:16:56.005496-08
\.


--
-- Data for Name: device_fingerprints; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.device_fingerprints (id, station_id, fingerprint_hash, browser_user_agent, screen_resolution, timezone, language, canvas_fingerprint, webgl_fingerprint, department, location, is_active, assigned_date, last_seen, access_count) FROM stdin;
965edb24-6030-451f-8ffa-15465a810a3c	1	be3c26f1ff9697730773e3787a34d0187e3da0d367e3f7e3e9f6f1195bf2339d	webkit	1920x1080	America/Los_Angeles	en-US	data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAASwAAACWCAYAAABkW7XSAAAQAElEQVR4AeyaCUBUZdfH/3dmYFgFQVnEfSlNxRJ329zD3BVNCxeEmUHarCxt+dyyXtNeLTcQtbfd1NK0UktTUQH3PcMFEwUBF/Z1YO537iBoIvs2y7neZ5777Of8ztw/z72jDHwwASbABIyEAAuWkQSqOs0UVRDNMVUnQ56rbgiwYNUNd16VCTCBShBgwaoENGMdwnYzAWMnUH7BUoU8D1VIurE7zPYzASZgvATKL1jG6yNbXksEtsETf8OtllYrWCYDSqzCMwUF/jR5AhUWLNVRdFcdwSaTJ8MOVpjAx/BGFFwrPK4qAw6gNULxVFWmMM2xJurVPcEKWu5Mj3wiAla/SPkZSpl0vQfTVjS5z3ftgfAXhsXEdHyO2lOpfQ1e+VxZ1K4KeZfqDlFbBqW9lLrf13acyu9ROg918Db4fmVL1yJdj6G0g65v0djfMXVNa7reSSlKX9ascimaQx08iup3UUqndJrafYvapAtVyAyqv0wpldLXNJcTzT2YrrPgt9Ze6qJPPhssqS6T2obqyw9+qIKPUtsb1GcrJWm+s5R3pPW+pPwIJal8z7fS7ApY/Sn1/x/Nt5RyyfZoyt8sWrKAQyjVnaeUTGk9Mb+3TfEPdaV1f6f6NEqb4R/qRbkIzSoPSIff2kY09zaqS6F0g1IoJn9hJTVR/VAqX6ZcQ2k3Xd+mfNFutMUAvA53LEIgXoQIAYXHcvTBI5gPGyyHF97DH2hX2IQueBefoR+GYxp64208jg9Q2N4NsxCBlhhBbWNdR+GOHYodF+GCkQiEKxajOT7CFEzCVTjjN3SANZYjDQVmg45cKCDZIO3aShr3KzriObyKE2gChXw5tjZrQCOB0nyAqoKx1c/IH4ZC4J5g6WS6u0a9SrkPpbaQ6ZKgtVhL14WnRWpywz7u7hfDIIh9KXkj22qqvlEdPJjyIIjCNCjyWtF1FKVtmD27cI08Ko+ndg2Nmwp5fj6VQeXxcLsxhNZpR/Wdqf5XyHS+cI9rT2WR2mfo+01b4UbXX1JagVzLxtS2ktKXdOM+oW9XB4+j/F1qV1Mu1bnTXN8jRL2dykmw0L5IecHpmCwJVQ7uOP1WUPHgp6DTzyPT+VNLW0o3KIVT3RqsVnelfAOVl1GCXlxEoWS7ZDqJqw/13U1j+1M+gNIisrsD5YB11mzKm1IaQvP2ptwDeYoQygtOef4qunAgXzpRPovYfEo5UBgvRd5vNO4m1XeifDS1dSRfl1AOKktre1DuiBBNPxrjQ9dvrcCz2I7PcRZz8COe0AsG6NhM1/PxPD7FRlzFLExCBIbgZVxHfWoFZBCxBP0obcBBfEJS8SfGIwCS4B3Gx6iHbGzBSoxt8ROSbFHsmIlRcEQmTmI+IrAQ1tDS7C/AG+dohUx8i24oPLbBE0pqH4yzKGnc8ziDxdiEJ3ANl51eRmbjWyjLB0Aof2zBh6ERKBSTIrscHOND1Sr1IrVG3eaFsf+HgQNXDfCLVC5xd7vgSJ1s23fYu9BSmZ0a4K9p6P3csuzhIxa+QY+I0x/z3B0GUeiDNQHH1FOC+kyZNB0DBgQ3HN9neei0Y2hHY6XzoEqlGqPyD+zvH+i/vIvXNthYpX6lHjp3szrQr13vXj/kDB/2CTQBga9pBs11HdA/xG7ggJBxmmNYMHHUTC3dlD0RqtqsenlKB1WAphmtnz58yOLP1EcwgNb2owW+pfZdAf5qr4m+b97x8ZnjpDoin2Ftnbbeo1FUoPoofqJHWhvqN5r6r1e9M1amPoYf1YfQk+oePLeQne+pA9TD+/ZZY9O/X2iuShMwPvAwWg4btrhx797fP05zrQyYPN25VLsKZr2gUmncqf+bKpV6YM8eGzPGjFywXH0EY0h8P4JONnXyeHWsSqMaMHrU/BxiPkh9GLN8wtwakp2SuM6f6jstWaNW+471mWvv1flX9H92XauJ++0PWFmntYMyJ5BsTddoVAMnjJ+Z3a/fmgDVMbxuY5WhoOUtJ016M5xitNbP71WHbt02w7PfD4hsq0NGgww82XUT9vS5hT0dgGA8jQDsx1CcRlzzNDg9/SfGDFiKJb0ccLUBzUTnCJzEkV63cKI5IPc6hTY9tmNdb4ui9vM9Y5HgAOx4HPi1M/51xKMeFNDB2jYFxzunoEvf7zDmmRXY7SniJZu9+NGlGYIHALkK4Ed0xgs4CmILywF/wsI1odi4XZ5Avk0u7Fxi8QutddsO2DwoGX71duBhPgQeg9ddg8oV2/u+t3eHcVbXBIoJlqUiK0pvVD6GXIjquWT/gQnIyHCUd+/+0zCqz2zW9Ew8RMgFAT3DI8YdiYzwOQcZnvBsFzYMgvim2/+9FXfhUo/vNm+ZqQoL80Vult2dPBHvCwUbuBgaJ+2snsxMd1x95mw/KCy18TQvfTHxdPih0dG790zdIIpoIVpiduShMWF/7Aq4THsU0apexmi6sQdbvbb43JXozmFbt86YuWu3yv7atfYXafwr9evfeITyCyQKfWRyjLK0SF9o73xjOARd/VGjFljGxrb1zMmxE/JyrQdBEIdCnv+NXECPf650Grh6XXA4VCEipcU0B1DwkSiAPBUw8MiR0eF79vgdp3KyTsDCq9faRRw8OF4m6BAuk+UGQCcr0S5310vS9iSeQIs0Wy8hHycjIn0Sww5O2EbLTOzU/ZfukOlWHj41IfHE8cFLtu94pR8x1YoyOCuROZP60O2LC3JLBIk62Jw62W9G1IWeaNTs3HhtntIGoswSOcrsv849ezM83Gf2lp9nPXPihLc8M8PB89m+67xpfJpSmZ4DAU5yiyzl4cMj0eWULU41A840BVKO9oDdwU6Ipgfv2y7ZWIDBcHebgTdadsNbUe9g075puB3XCr+RICisM+GOFMIHnKbx3c7LERk5Bs1irCCJB62FdhEesKAIHz/pjSHHQyAghPZNs6QmvI/f6F8H+D76DMLy2qFReGuMPiRQKIAO7fZiV+KTyM2zwlkPOaQd1kuI1Nv1mC4BvyU++9Bxye2uIT3RAz3pW+CcDkTu9MN/Un0e6oOOvoe2NskWAMoV23wRaurLpwERkD1oi04QLPV1In45fnJwXFZWPVy72nG3rV1Sc4VFjqhvA6x0SqxISW2YlZDYIlUQce7Klcel9zK9k1NdJzg4xLZOTm/glJNji0ORI3+lG72eQ71EJX3T86TxVI767uvFp3NybKSiPtEcv4s6uZie5pxNN3YCLXQija6lOrqOvh7Xbhh1fF+bazNHzJd5xc9bJGi1yjPHTzz/F93ccU71ryupHTS2H/Xfv6YHjq3rjLg8GZbZ2SX9QmvvvxDVQ5ac1sCX+t1EcOBBnYhe9RxufSaKAv2thicUefcLFnWTpsPhtDSn7Px8hUjzRlNlwqlT3pcplxr/Tkpyl974lmiXi+sVZ31f6UOGuJDuiJAuExNaJtN8KXduNfqWyrl3khr3b996n3tmRv0xqWkNdFT3q0KhbUk5lJa5dOPDSybDD1GXeyWmpzshM83hkNRGRqSpNer27dvv3fKo60Zl5tK3hTsL5wp21inLHB3jJL/03YivPPkKfpIKjncKQvxoHI0meEKuAg6ZFFS7ZCzGJgQ3WYQPrx9GfMJC5OROx//+2Q2XFKCexxVpuD41vwnYZRZ8fRreUSCbZMBSSZPoW4EAHMBpzIOUvsNafa03zuIaZmKA5UloRQVezJ6GV7Mnos85YOKxTDyFi4iNexS73OujIdLQG5cR7QY8mZCCGHHWQ8c5H2uln/v+j5J8oO/GxebNT9Ur7Ev8S40t9fOgxKcBESj4xt1nUE6W/aNSUSbgOuVNKcG2XuxfUk6PH6Q10pccuWs6IkGqu5u0eVpL+puLFRM0M465ulwbMm70/A3PDVqBfgPWzJP6yGR5+rHSNX1Rbkr5/Slfh2QUHgIkYaNbpLAC2pxsm6YkOtvzV07b1PqRo22mRihDaf72Y8fO8aOb0UOpzEqk3m3pznYV8xBHL6dd6WX1/HXBITdDvLADovDV6bP9WpMAdqnvHPsL7cQsIKKLs2Psenq3dEYVoH5d7RcUqj6KbZ06/d6Q5tKfNPc9uwCtIEORXTIFcnO1Vg1Ks0sm0xUxpt3V/XPRYFsFLSIJ2vtDBn9y09IuQzNs+CcfensvsyFYb1gosmmvAjg3iG5L/eRaLcVEJ9OL0O2kFlEWihxSCME+LrYtPYBB4dQSP/ofkm/3i1D+IQqYJwg6ua1tMk0FUDl741jk0jyQ6fRVsMmRSgVJrgNc5ck4jcZIswaOtwBWDAI+GaTEskEC4umFgIVtWkFn+rR9YCxVQS6XwiZdQS84HUGPh56x2DkoUT9XSE8bfeOw6BR0bHAG7/RagMOtgWsSAWqZiEj8ea0vLjlYYazNfuQTuasNAIs4+qD2ksZRU9HZArdK9AEC2tnYJlkWdi4rtvQXqqhv4RjO65aA7MHlc7XW07Ky7R3PX+jRhNoW0Df9jyYtz2fQ9f0nac79RUAmz6ObB10V6QjKzKrXLSxsgvaPXeqcn7e+s/TfPQFBgP5GRAUOuhmyyJb2EyOsR2jzFOP37J3U/M89U85t2DDnFwAxzg2u/0n5S8nJbk0SbrV0pbtyBZX7kBhpKQfyFD/QzqRVfHxr16d7fxNLdZ1pc5Ea3BVn6RoQMFemw2tSunChRxLKechlebml2VXaNHJ5rpbETqTxXUn85ibEt265/8CLCTt2vKxLTW64QpDRQ6Ao/JGS6vqeVmtlfeF8f+nx8mVpThIvWFunJdFz6dlzfz09nXarspDVIaPWrFkVu+6Lz2NCumDot98unJeR4VgsVtL4h6W++Bsb4YXLaIiuF+V4amdjLNn5IQbudEHQTiDhVI+HDSuqa4A03IADckDbrbu13elRbVw44BMuYNnpIHwEbzSlB7JJe0kEz3vBhURyJ8ntro7AOBzFmczWiEp+BN09IhFDOqXUAlPuvFbiOG3HC7gNW2TTmrlQQIMwlOSDxOTIkRE37pp2N+PMmAgUEyxLy8xld257dIqO7vor3Ux59IvTVHrX4yI5lZ1Vr8Qvv6vrlV3UZ1zU370/pvc7fW/Etgukx6glSsu09ZmZ9ZyorUqnq0v0cZrA/uSxIT+dODHYO/qfzp+TuM6zsMhW3b7t0fextvvotsD8azEdul+J9lpKfbVk+5ip4XCi3dSk2b5Ts6huS2JCixg31+gmAtBb1OEg1enP1V0Qs6oboqVEj8F5+spyfNRzuHmFupVoF7WVeMppz+TokPC9tU3qVzH/ePru2+/bLCnVZYgoCmGnzvbfIuoEGT2marKz7cS4G236nr/UfRdEQRJiuDSIaQI62jQ79kJGWv30hMSWA23tkqMoZvnItQyaHg5rV7dLRY8/1LXMswuuYhE2ISLrMbxsNxTT4YMQfINHkYBkW0AgNUcphwr78TZG4zCao/CwJ+oNaGPmkibiu4zvqa0FWtm9CwVWYWvS0/g46jT6nwEu06OfjALYSwAADFFJREFUPbIxAichj2uIbJdkXHYF2sQDPyKkxHE2brFogiRMpn+3YYuROIGSfNCEw4P+wFDowYeREigmWLbWGac8PP7e5+29bI2/SqP2DwzKleXD194ueVfeilfs/uVniGYK7WB8pbpGHn+fp2vbtm0Pfjagf8girPW/qpmsXj5ixCcf0A2ZOHb0fH/6aX2h1Fef/jclm/oL0ye/e0Jflj5CNE9T3QLpUp9Wq+dSua90bWObkkLXzXr12qjq0mXrOp9+mp2+ozTb/aa89h9np9jdogBHal/U0XPXqJ49N25VqdRLVX5BgsIS0wB0nLtygyS2j8XdeGQZ9fWgQg+dHLuprfi5Wt2N5vq0qCFU9QFCVQOLyiGaMGqXHudgocjOousS7eradfM2apdefhcNp3IrYqF/sdOjx8ZvfH3fsm3W9PS2cT6zP8TKoHSy/f2nen2/SCYT5b4jpiXkrwrq0bzZmY9HjlzwtbvbRVtLZWZ+Q5eYntKET/b+Pj7hw4V9mjY+G/LShHe+pbFzZk+akpdhAc3woYvcaC0HqV9RWq0WeuFyUfFP/BezIW1SC6qCsBfLr+2Dn+sWrGy0BM/LTuEmyd5P3YDtNgvxDnai8GiCJIhQoxnu6Kuk/waRitcwMPciMqyATKW+uujDE9fxM+ntvM4LENlKg4vC++iOK/pHQknY8iHDX3DHmBuxSLEFol2BtrQXLm1cg6w8HMAn+DknFE4WKdBSVPwtHu4D/ZCzUB0UNIqYlCu2RYbzhcEQKCZYhZbRDf0zCdUr8lyspDodFPiM8jJPmYD1ooje0rsgnQXm0buRL2UybKPXJrP8I+FZ5gRldCCbttGfSGvpfY21M75APsIgYgOl/gGH8SLtlPaIOtomiFDRVJ+RH3lno3otQ/2kpVS2o93TKkGHwzRH/NrOuEp11XKWZVdpi5DN0uP0Jgh4VeJGvgy1ycNHNOZ8qrb1OXng8m1XYzqsS091dunS9ecFfZ9dlwgZfqN20FsuchEgEZ4jisgnv5bG2yFYEKBzt4Z+Nyb1q0hqHQ/0vAAcaQWs7QscaAs8S28xnehXuPLM04moRrYBpMe8B/sLZO1zJ4FEktEv+hS8J7vSEOh2TonXMRbpUCIgLwLN6Y2kA1EpXLOkcdILe9Ah/Qhgmw2sIXtv2wMP80Gnw8qVHXGNuvNppARKFCwSmkuru2EavbAeTc/+M4I7gb5CAN1ch1Z3xZgCfws+qf2/q72wSCqt8kIktUtjhlI+dWU3xAd3xjoaN5J+uTtNfV+nOX+Q+kppbgfkUt3Q0O6gW0SqAag8g/p/V1ACQrvia6qbKZWl+eh6CqWh1GdsSHdEhHRDGK31Qmg3fCv1oXwDladK7atXrl0Rvm/SP1TvA51sxOwQdT7d7I2hwx9UV+pJa7we0pXE724vmu/LYC+8d7cI8vU0rTNcKpdlF40LJTs/kPoWJho7lXzbLpVpna9ovaFSovr3l/RCFl2/+/PmmZ3z8y0ct29/5dJ36z96btsvb+7esfPlHkI+8kmgdGt7Qb+9Idtu0bg5NGYczeVP+WcSW2luajtEaax0XZikd1KNkgpLwMjDgPS+qbBGEp2X9gOqXQVtLe/7iWVsBNDl3iYN0u5Imk8SGGm8JwmWNG7YUalUPDVMBYYcA/zoraM0bmSYFdokfY6N8MIWrIKCnJP+42k72l3hvuPBcRPDAPe7PljnAmMigcDfgUZ6IsCDPtD3QnptoJ+R+JQ7tvoB/GEQBO4J1qppSaDHhee9F5wzCMuqy4h1U9Mkvyi5+foEXL5xFIG0G7Fyy4BeKKprmRqbZ63/HbL9KfoV822VWr1i8nj15EB/tYJ8eI52ZLTvqbGVa21i6d2VCDXiMQNtFdex7zHoH+3a816o1mJgLAvdEyxjsbiSdqqOwsbGGevpUamnPB8L5vZBXiWnqpNhefYIhgh7pT025sswHzqk6JSQHnNhKkcuvX8K7UfvrlwA7xMA7fJNxTX2o5oIFBOsdU8ijbbLQ6Vfy6ppDYOYhh6JMiW/KL1kjL6ta4s08uEtsl96FH6RHi8/XtMR9z2o1TjmGl/AMg/6/z7htweQHv9qfEFewOgIFBMso/OADa4wAWE1BHNMFQbFAwyOAAuWwYWEDWICTKAkAixYJZHheiZgxgQM1XUWLEONDNvFBJhAMQIsWMWQcAUTYAKGSoAFy1Ajw3YxASZQjAALVjEkVa/gGZgAE6gZAixYNcOVZ2UCTKAGCLBg1QBUnpIJMIGaIcCCVTNceVZzIcB+1ioBFqxaxc2LMQEmUBUCLFhVocdjmQATqFUCLFi1ipsXYwJMoCoE6lawqmI5j2UCTMDsCLBgmV3I2WEmYLwEWLCMN3ZsORMwOwIsWGYX8rpymNdlAlUnwIJVdYY8AxNgArVEgAWrlkDzMkyACVSdAAtW1RnyDEyACfybQI2VWLBqDC1PzASYQHUTYMGqbqI8HxNgAjVGgAWrxtDyxEyACVQ3ARas6iZa9fl4BibABEogwIJVAhiuZgJMwPAIsGAZXkzYIibABEogwIJVAhiuZgK1QYDXqBgBFqyK8eLeTIAJ1CEBFqw6hM9LMwEmUDECLFgV48W9mQATqEMCRi1YdciNl2YCTKAOCLBg1QF0XpIJMIHKEWDBqhw3HsUEmEAdEGDBqgPovGQlCPAQJkAEWLAIAp9MgAkYBwEWLOOIE1vJBJgAEWDBIgh8MgEmYEgESraFBatkNtzCBJiAgRFgwTKwgLA5TIAJlEyABatkNtzCBJiAgRFgwTKwgFTdHJ6BCZguARYs040te8YETI4AC5bJhZQdYgKmS4AFy3Rjy56ZPgGz85AFy+xCzg4zAeMlwIJlvLFjy5mA2RFgwTK7kLPDTMB4CZizYBlv1NhyJmCmBFiwzDTw7DYTMEYCLFjGGDW2mQmYKQEWLDMNvLm5zf6aBgEWLNOII3vBBMyCAAuWWYSZnWQCpkGABcs04sheMAGzIFAuwTILEuwkE2ACBk+ABcvgQ8QGMgEmUEiABauQBOdMgAkYPAEWLIMPUS0byMsxAQMmwIJlwMFh05gAE/g3ARasf/PgEhNgAgZMgAXLgIPDpjGBmiVgfLOzYBlfzNhiJmC2BFiwzDb07DgTMD4CLFjGFzO2mAmYLQEWrEqHngcyASZQ2wRYsGqbOK/HBJhApQmwYFUaHQ9kAkygtgmwYNU2cV7PGAmwzQZCgAXLQALBZjABJlA2ARasshlxDybABAyEAAuWgQSCzWACTKBsArUhWGVbwT2YABNgAuUgwIJVDkjchQkwAcMgwIJlGHFgK5gAEygHARasckDiLuUnwD2ZQE0SYMGqSbo8NxNgAtVKgAWrWnHyZEyACdQkARasmqTLczMBUyZQB76xYNUBdF6SCTCByhFgwaocNx7FBJhAHRBgwaoD6LwkE2AClSPAglU5blUfxTMwASZQYQIsWBVGxgOYABOoKwIsWHVFntdlAkygwgRYsCqMjAcwgYoS4P7VRYAFq7pI8jxMgAnUOAEWrBpHzAswASZQXQRYsKqLJM/DBJhAjRMwAsGqcQa8ABNgAkZCgAXLSALFZjIBJgCwYPG3gAkwAaMhwIJlNKEyC0PZSSZQKgEWrFLxcCMTYAKGRIAFy5CiwbYwASZQKgEWrFLxcCMTYAI1RaAy87JgVYYaj2ECTKBOCLBg1Ql2XpQJMIHKEGDBqgw1HsMEmECdEGDBqhPsVV+UZ2AC5kiABcsco84+MwEjJcCCZaSBY7OZgDkSYMEyx6izz8ZFgK0tIsCCVYSCL5gAEzB0AixYhh4hto8JMIEiAixYRSj4ggkwAUMnYPqCZegRYPuYABMoNwEWrHKj4o5MgAnUNQEWrLqOAK/PBJhAuQmwYJUbFXc0fAJsoakTYMEy9Qizf0zAhAiwYJlQMNkVJmDqBFiwTD3C7B8TMCEC9wmWCXnFrjABJmCSBFiwTDKs7BQTME0CLFimGVf2igmYJAEWLJMMa5lOcQcmYJQEWLCMMmxsNBMwTwIsWOYZd/aaCRglARYsowwbG80Eyk/AlHqyYJlSNNkXJmDiBFiwTDzA7B4TMCUCLFimFE32hQmYOAEWrDICzM1MgAkYDgEWLMOJBVvCBJhAGQRYsMoAxM1MgAkYDgEWLMOJBVtS1wR4fYMnwIJl8CFiA5kAEygkwIJVSIJzJsAEDJ4AC5bBh4gNZAJMoJDA/wMAAP//hPVvjQAAAAZJREFUAwDAEzbDVT6aPgAAAABJRU5ErkJggg==	Google Inc. (Intel)|ANGLE (Intel, Mesa Intel(R) UHD Graphics 630 (CFL GT2), OpenGL 4.6)	Test22	WSU	t	2025-12-16 23:36:53.209257-08	2025-12-16 23:36:53.209257-08	1
\.


--
-- Data for Name: documents; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.documents (id, filename, content_type, file_size, storage_type, file_bytes, storage_path, metadata, created_by, created_at, updated_by, updated_at) FROM stdin;
\.


--
-- Data for Name: efax_incoming; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.efax_incoming (id, from_fax_number, from_name, received_at, total_pages, file_path, checksum, linked_patient_id, linked_prescription_id, processed_by, metadata) FROM stdin;
\.


--
-- Data for Name: efax_jobs; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.efax_jobs (id, patient_id, prescription_id, user_id, recipient_id, document_id, claim_id, direction, subject, fax_number, provider_name, status, priority, total_pages, retry_count, error_message, created_at, queued_at, preparing_at, sending_started_at, sent_at, received_at, failed_at, completed_at, metadata) FROM stdin;
\.


--
-- Data for Name: efax_recipients; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.efax_recipients (id, name, organization, fax_number, email, contact_type, is_verified, last_verified_at, created_at) FROM stdin;
\.


--
-- Data for Name: efax_status_logs; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.efax_status_logs (id, efax_job_id, status, message, provider_code, created_at) FROM stdin;
\.


--
-- Data for Name: insurance_companies; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.insurance_companies (id, payer_name, payer_id, phone_number, website, notes, active, created_at, updated_at) FROM stdin;
550e8400-e29b-41d4-a716-446655440001	CVS/Caremark	00479	1-866-389-5822	https://www.caremark.com	Major PBM	t	2025-11-28 13:35:47.597166-08	2025-11-28 13:35:47.597166-08
550e8400-e29b-41d4-a716-446655440002	United Healthcare	61616	1-800-624-8822	https://www.unitedhealthcare.com	National health insurer	t	2025-11-28 13:35:47.597166-08	2025-11-28 13:35:47.597166-08
550e8400-e29b-41d4-a716-446655440003	Aetna	12456	1-800-367-2596	https://www.aetna.com	Subsidiary of CVS Health	t	2025-11-28 13:35:47.597166-08	2025-11-28 13:35:47.597166-08
\.


--
-- Data for Name: insurance_plans; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.insurance_plans (id, company_id, plan_name, bin, pcn, group_number, notes, active, created_at, updated_at) FROM stdin;
650e8400-e29b-41d4-a716-446655440001	550e8400-e29b-41d4-a716-446655440001	CVS Preferred Plus	610049	CVSPPP	GRP123456	Standard PPO plan	t	2025-11-28 13:35:47.597166-08	2025-11-28 13:35:47.597166-08
650e8400-e29b-41d4-a716-446655440002	550e8400-e29b-41d4-a716-446655440001	CVS Medicare Advantage	610049	CVSMAD	MCARE789	Medicare Advantage plan	t	2025-11-28 13:35:47.597166-08	2025-11-28 13:35:47.597166-08
650e8400-e29b-41d4-a716-446655440003	550e8400-e29b-41d4-a716-446655440002	UnitedHealth Choice Plus	616165	UHC123	UHCGRP001	HMO plan	t	2025-11-28 13:35:47.597166-08	2025-11-28 13:35:47.597166-08
650e8400-e29b-41d4-a716-446655440004	550e8400-e29b-41d4-a716-446655440003	Aetna Open Access	012456	AETNA01	AETGRP555	Open Access HMO	t	2025-11-28 13:35:47.597166-08	2025-11-28 13:35:47.597166-08
\.


--
-- Data for Name: inventory_items; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.inventory_items (id, ndc, name, strength, form, pack_size, dea_schedule, is_controlled, on_hand, reorder_threshold, reorder_quantity, reorder_rule_id, manufacturer, attributes, active, created_at, updated_at) FROM stdin;
1e557ff4-ecb3-4104-a0e5-a23c378ca245	00093-7424-56	Amoxicillin	500 mg	Capsule	100	\N	f	45	20	80	1	Teva Pharmaceuticals	{"storage": "room_temp", "category": "antibiotic"}	t	2025-11-26 23:52:54.669836-08	2025-11-26 23:52:54.669836-08
c9680ab0-1f71-4222-8722-b80ce3382337	00406-2028-01	Oxycodone	5 mg	Tablet	100	CII	t	12	5	15	2	Mallinckrodt	{"opioid": true, "risk_level": "high"}	t	2025-11-26 23:52:54.669836-08	2025-11-26 23:52:54.669836-08
137cb68e-82ba-40e5-840d-8e59a1df3f62	50580-488-10	Ibuprofen	200 mg	Tablet	500	\N	f	150	30	100	3	Perrigo	{"otc": true, "seasonal_demand": "winter"}	t	2025-11-26 23:52:54.669836-08	2025-11-26 23:52:54.669836-08
0f6a63c4-3e41-456f-afb9-110a944130d0	00054-0123-25	Levothyroxine	50 mcg	Tablet	90	\N	f	28	10	20	4	Sandoz	{"storage": "room_temp", "chronic_med": true}	t	2025-11-26 23:52:54.669836-08	2025-11-26 23:52:54.669836-08
112ade70-2121-4ac0-9303-afc6514f3151	00002-8215-01	Humira	40 mg/0.8 mL	Injection	2	\N	f	1	1	2	5	AbbVie	{"category": "biologic", "refrigerated": true}	t	2025-11-26 23:52:54.669836-08	2025-11-26 23:52:54.669836-08
\.


--
-- Data for Name: patient_insurances; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.patient_insurances (id, patient_id, insurance_plan_id, member_id, rx_group, relationship, cardholder_name, cardholder_dob, coverage_start, coverage_end, override_bin, override_pcn, override_group_number, member_metadata, is_primary, is_secondary, is_tertiary, created_at, updated_at) FROM stdin;
850e8400-e29b-41d4-a716-446655440001	750e8400-e29b-41d4-a716-446655440001	650e8400-e29b-41d4-a716-446655440001	CVS123456789	CVSPPP	self	John Smith	1975-03-15	2024-01-01	2025-12-31	\N	\N	\N	\N	t	f	f	2025-11-28 13:35:47.597166-08	2025-11-28 13:35:47.597166-08
850e8400-e29b-41d4-a716-446655440002	750e8400-e29b-41d4-a716-446655440002	650e8400-e29b-41d4-a716-446655440003	UHC987654321	UHCGRP001	self	Maria Garcia	1988-07-22	2023-06-01	2025-05-31	\N	\N	\N	\N	t	f	f	2025-11-28 13:35:47.597166-08	2025-11-28 13:35:47.597166-08
850e8400-e29b-41d4-a716-446655440003	750e8400-e29b-41d4-a716-446655440003	650e8400-e29b-41d4-a716-446655440004	AET555111222	AETGRP555	self	Robert Johnson	1962-11-08	2024-01-01	2026-12-31	\N	\N	\N	\N	t	f	f	2025-11-28 13:35:47.597166-08	2025-11-28 13:35:47.597166-08
850e8400-e29b-41d4-a716-446655440004	750e8400-e29b-41d4-a716-446655440001	650e8400-e29b-41d4-a716-446655440003	CVS999888777	UHCGRP001	spouse	Jane Smith	1976-05-20	2024-02-01	2025-01-31	\N	\N	\N	\N	f	t	f	2025-11-28 13:35:47.597166-08	2025-11-28 13:35:47.597166-08
\.


--
-- Data for Name: patients; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.patients (id, mrn, first_name, last_name, dob, gender, contact, sensitive_data, encrypted_at, is_student_record, preferred_language, accessibility_preferences, created_at, updated_at, updated_by) FROM stdin;
750e8400-e29b-41d4-a716-446655440001	MRN000001	John	Smith	1975-03-15	male	{"email": "john.smith@email.com", "phone": "555-0101"}	\N	\N	f	en	{}	2025-11-28 13:35:47.597166-08	2025-11-28 13:35:47.597166-08	\N
750e8400-e29b-41d4-a716-446655440002	MRN000002	Maria	Garcia	1988-07-22	female	{"email": "maria.garcia@email.com", "phone": "555-0102"}	\N	\N	f	es	{}	2025-11-28 13:35:47.597166-08	2025-11-28 13:35:47.597166-08	\N
750e8400-e29b-41d4-a716-446655440003	MRN000003	Robert	Johnson	1962-11-08	male	{"email": "r.johnson@email.com", "phone": "555-0103"}	\N	\N	f	en	{}	2025-11-28 13:35:47.597166-08	2025-11-28 13:35:47.597166-08	\N
\.


--
-- Data for Name: pharmacist_note_addendums; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.pharmacist_note_addendums (id, pharmacist_note_id, actor_user_id, addendum_text, created_at) FROM stdin;
\.


--
-- Data for Name: pharmacist_notes; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.pharmacist_notes (id, prescription_id, actor_user_id, note_type, note_json, created_at, updated_at, station_id, active) FROM stdin;
21420ec5-0439-46e2-b8d5-6a4a5dffca3a	b8635e04-b3a6-488e-85e0-218d9ee13006	11111111-2222-3333-4444-555555555555	PRESCRIPTION_CANCELLATION	{"findings": "", "freeText": "test", "insurance": "", "assessment": "", "disposition": "", "intervention": "", "communication": ""}	2025-12-17 00:39:05.956019-08	\N	965edb24-6030-451f-8ffa-15465a810a3c	t
35ba05aa-0e40-455a-b6fe-485ad7730750	b8635e04-b3a6-488e-85e0-218d9ee13006	11111111-2222-3333-4444-555555555555	PRESCRIPTION_CANCELLATION	{"findings": "", "freeText": "test", "insurance": "", "assessment": "", "disposition": "", "intervention": "", "communication": ""}	2025-12-17 00:46:24.352216-08	\N	965edb24-6030-451f-8ffa-15465a810a3c	t
4dc27f31-8ccd-4892-bd61-ad1fa35dc23f	b8635e04-b3a6-488e-85e0-218d9ee13006	11111111-2222-3333-4444-555555555555	PRESCRIPTION_CANCELLATION	{"findings": "", "freeText": "test", "insurance": "", "assessment": "", "disposition": "", "intervention": "", "communication": ""}	2025-12-17 00:47:39.592957-08	\N	965edb24-6030-451f-8ffa-15465a810a3c	t
f09ad0f3-b1b8-4d92-9fce-79a38c0a1d34	b8635e04-b3a6-488e-85e0-218d9ee13006	11111111-2222-3333-4444-555555555555	PRESCRIPTION_CANCELLATION	{"findings": "", "freeText": "test", "insurance": "", "assessment": "", "disposition": "", "intervention": "", "communication": ""}	2025-12-17 00:48:09.006341-08	\N	965edb24-6030-451f-8ffa-15465a810a3c	t
522a31d4-d002-43b6-99c6-e6ba9d065bf3	b8635e04-b3a6-488e-85e0-218d9ee13006	11111111-2222-3333-4444-555555555555	PRESCRIPTION_CANCELLATION	{"findings": "", "freeText": "test", "insurance": "", "assessment": "", "disposition": "", "intervention": "", "communication": ""}	2025-12-17 00:52:08.71382-08	\N	965edb24-6030-451f-8ffa-15465a810a3c	t
982a47b8-c636-458c-aeb7-d5acb56f23ab	b8635e04-b3a6-488e-85e0-218d9ee13006	11111111-2222-3333-4444-555555555555	PRESCRIPTION_CANCELLATION	{"findings": "", "freeText": "test", "insurance": "", "assessment": "", "disposition": "", "intervention": "", "communication": ""}	2025-12-17 20:22:12.490379-08	\N	965edb24-6030-451f-8ffa-15465a810a3c	t
e3466f08-814b-4900-befc-0a6d30f59338	8ea527cd-9d69-496b-b335-f887d9c1ddfd	11111111-2222-3333-4444-555555555555	PDMP_REVIEW	{"findings": "test", "freeText": "test", "insurance": "test", "assessment": "test", "disposition": "test", "intervention": "test", "communication": "test"}	2025-12-17 21:26:32.219698-08	\N	965edb24-6030-451f-8ffa-15465a810a3c	t
66220fb9-0e71-4a9b-a597-6040d43abfac	8ea527cd-9d69-496b-b335-f887d9c1ddfd	11111111-2222-3333-4444-555555555555	DUR_INTERVENTION	{"findings": "sdfsdfsd", "freeText": "test", "insurance": "test", "assessment": "sdfsd", "disposition": "test", "intervention": "test", "communication": "test"}	2025-12-17 21:29:38.683442-08	\N	965edb24-6030-451f-8ffa-15465a810a3c	t
\.


--
-- Data for Name: pharmacy_types; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.pharmacy_types (id, taxonomy_code, pharmacy_type_name, created_at, updated_at) FROM stdin;
1	3336C0002X	Clinic Pharmacy	2025-11-28 11:03:19.638279	2025-11-28 11:03:19.638279
2	3336C0003X	Community/Retail Pharmacy	2025-11-28 11:03:19.638279	2025-11-28 11:03:19.638279
3	3336C0004X	Compounding Pharmacy	2025-11-28 11:03:19.638279	2025-11-28 11:03:19.638279
4	3336H0001X	Home Infusion Therapy Pharmacy	2025-11-28 11:03:19.638279	2025-11-28 11:03:19.638279
5	3336I0012X	Institutional Pharmacy	2025-11-28 11:03:19.638279	2025-11-28 11:03:19.638279
6	3336L0003X	Long Term Care Pharmacy	2025-11-28 11:03:19.638279	2025-11-28 11:03:19.638279
7	3336N0007X	Nuclear Pharmacy	2025-11-28 11:03:19.638279	2025-11-28 11:03:19.638279
8	3336S0011X	Specialty Pharmacy	2025-11-28 11:03:19.638279	2025-11-28 11:03:19.638279
9	1835C0206X	Pharmacist - Cardiology	2025-11-28 11:03:19.638279	2025-11-28 11:03:19.638279
10	1835C0207X	Pharmacist - Compounded Sterile Preparations	2025-11-28 11:03:19.638279	2025-11-28 11:03:19.638279
11	1835E0208X	Pharmacist - Emergency Medicine	2025-11-28 11:03:19.638279	2025-11-28 11:03:19.638279
12	1835I0206X	Pharmacist - Infectious Diseases	2025-11-28 11:03:19.638279	2025-11-28 11:03:19.638279
13	1835S0206X	Pharmacist - Solid Organ Transplant	2025-11-28 11:03:19.638279	2025-11-28 11:03:19.638279
\.


--
-- Data for Name: prescribers; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.prescribers (id, npi, dea_number, state_license_number, upin, taxonomy_code, first_name, last_name, middle_name, suffix, clinic_name, clinic_contact, contact, epcs_enabled, erx_identifier, ncpdp_provider_id, active, created_at, updated_at) FROM stdin;
5de8a70a-79de-401c-97f3-8a9ada0f342f	1234	1235		\N		James	Rodriguez			Everett	{}	{}	f	\N	\N	t	2025-11-26 20:27:42.588986-08	2025-11-26 20:27:42.588986-08
f85f3e82-6b68-41c0-90ae-af2101a0f2c9	1212121	343434		\N		David	Mai			Everett	{}	{}	f	\N	\N	t	2025-11-26 23:55:47.414822-08	2025-11-26 23:55:47.414822-08
ef15a799-ca27-4307-9e16-a533ba87de3a	43434	3434		\N		Sarah	Chen			Seattle	{}	{}	f	\N	\N	t	2025-11-26 23:56:02.93384-08	2025-11-26 23:56:02.93384-08
\.


--
-- Data for Name: prescription_items; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.prescription_items (id, prescription_id, inventory_item_id, ndc_dispensed, quantity, days_supply, sig, daw_code, refills_allowed, refills_used, workflow_step, workflow_status, reviewed_at, filled_at, verified_at, ready_for_pickup_at, picked_up_at, lot_number, expiration_date, ingredient_cost, dispensing_fee, total_price, copay, insurance_paid, patient_pay, diagnosis_code, prior_auth_required, prior_auth_status, prior_auth_number, label_options, status, cancel_reason, cancelled_at, created_at) FROM stdin;
c2038707-0990-49dc-bb27-1f9dab6fb24f	b8635e04-b3a6-488e-85e0-218d9ee13006	c9680ab0-1f71-4222-8722-b80ce3382337	00406-0123-01	12.00	3	Take 1 tablet by mouth every 6 hours as needed for pain	1	0	0	READY	COMPLETED	2025-11-30 09:46:19.118598-08	2025-11-30 09:51:19.118598-08	2025-11-30 09:56:19.118598-08	2025-11-30 10:06:19.118598-08	\N	LOT-HC123456	2027-05-30	15.25	1.25	16.50	5.00	11.50	5.00	M54.5	t	\N	\N	\N	active	\N	\N	2025-11-30 10:06:19.118598-08
0ed4e6de-4c15-492f-a0db-8a95122bd9b1	6d81101a-90e7-499e-a565-341da8620707	112ade70-2121-4ac0-9303-afc6514f3151	00093-7424-01	90.00	90	Take 1 tablet by mouth daily	0	0	0	CANCELLED	CANCELLED	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	10.00	25.00	12.00	\N	f	\N	\N	\N	cancelled	Patient changed pharmacies	2025-11-30 10:07:42.482374-08	2025-11-30 10:07:42.482374-08
7afafb7f-8795-443f-8b0b-560245b4e551	8ea527cd-9d69-496b-b335-f887d9c1ddfd	0f6a63c4-3e41-456f-afb9-110a944130d0	68180-519-01	30.00	30	Take 1 tablet by mouth daily	0	3	0	REVIEW	IN_PROGRESS	2025-11-30 10:05:38.030749-08	\N	\N	\N	\N	\N	\N	\N	\N	\N	7.00	125.00	1.25	I10	f	\N	\N	\N	active	\N	\N	2025-11-30 10:05:38.030749-08
c3b4b07d-2ef8-4ef9-9c76-e39583f7e4aa	6d81101a-90e7-499e-a565-341da8620707	137cb68e-82ba-40e5-840d-8e59a1df3f62	67877-510-01	60.00	30	Take 1 tablet by mouth twice daily with meals	0	5	0	FILL	IN_PROGRESS	2025-11-30 09:37:03.697347-08	2025-11-30 09:57:03.697347-08	\N	\N	\N	\N	\N	\N	\N	\N	15.00	56.00	0.25	E11.9	f	\N	\N	\N	active	\N	\N	2025-11-30 10:07:03.697347-08
c753e2c3-6548-476f-be51-1251a1246f04	bf5683d5-c65b-4d8a-a854-cd2f1c715000	1e557ff4-ecb3-4104-a0e5-a23c378ca245	00093-4171-01	20.00	10	Take 1 capsule by mouth twice daily for 10 days	0	1	0	INTAKE	NEW	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0.25	77.00	0.35	J02.9	f	\N	\N	\N	active	\N	\N	2025-11-30 10:04:13.874409-08
\.


--
-- Data for Name: prescription_queue; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.prescription_queue (id, prescription_id, workflow_step, workflow_status, assigned_to, assigned_at, queue_name, is_active, created_at) FROM stdin;
bfc5954e-d98d-419c-9baf-920f678d7571	bf5683d5-c65b-4d8a-a854-cd2f1c715000	QA_CHECK	QA_VERIFICATION	\N	\N	QA	t	2025-11-27 00:37:45.466449-08
ff001998-3cf7-45da-a422-36a608a686ab	8ea527cd-9d69-496b-b335-f887d9c1ddfd	PHARMACIST_REVIEW	IN_REVIEW	\N	\N	PHARMACIST_REVIEW	t	2025-11-27 00:36:04.908606-08
c11f2c01-c4b9-4775-a80b-eb49306509dc	6d81101a-90e7-499e-a565-341da8620707	INTAKE_RECEIVED	PENDING	\N	\N	DELIVERY	t	2025-11-27 00:43:04.445701-08
\.


--
-- Data for Name: prescription_workflow_events; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.prescription_workflow_events (id, prescription_id, previous_step, previous_status, new_step, new_status, changed_by, changed_at, note, metadata) FROM stdin;
a8afdc07-f56a-4c6f-9326-87705e7d7da4	8ea527cd-9d69-496b-b335-f887d9c1ddfd	PHARMACIST_REVIEW	IN_REVIEW	NEEDS_PATIENT_INFO	ON_HOLD	11111111-2222-3333-4444-555555555555	2025-12-12 01:12:16.595086-08	update 8ea527cd-9d69-496b-b335-f887d9c1ddfd from PHARMACIST_REVIEW to NEEDS_PATIENT_INFO	\N
74968801-f3e2-4228-9c7c-28f9d0269db2	6d81101a-90e7-499e-a565-341da8620707	PICKUP_READY	AWAITING_PICKUP	READY_FOR_DELIVERY	DELIVERY_READY	11111111-2222-3333-4444-555555555555	2025-12-12 08:15:04.241741-08	update 6d81101a-90e7-499e-a565-341da8620707 from PICKUP_READY to READY_FOR_DELIVERY	\N
62b4be27-c720-467c-acdc-40af5567b5f5	8ea527cd-9d69-496b-b335-f887d9c1ddfd	INTAKE_RECEIVED	NEW	PHARMACIST_REVIEW	IN_REVIEW	11111111-2222-3333-4444-555555555555	2025-12-12 09:15:50.992619-08	update 8ea527cd-9d69-496b-b335-f887d9c1ddfd from INTAKE_RECEIVED to PHARMACIST_REVIEW	\N
72b85daa-5b36-4251-8405-702489724ba8	8ea527cd-9d69-496b-b335-f887d9c1ddfd	PHARMACIST_REVIEW	IN_REVIEW	NEEDS_PATIENT_INFO	ON_HOLD	11111111-2222-3333-4444-555555555555	2025-12-13 13:44:56.450104-08	update 8ea527cd-9d69-496b-b335-f887d9c1ddfd from PHARMACIST_REVIEW to NEEDS_PATIENT_INFO	\N
deb61b0d-a8ee-4d87-b313-8067eaf9446e	b8635e04-b3a6-488e-85e0-218d9ee13006	PICKUP_READY	AWAITING_PICKUP	CANCELLED	CANCELLED	11111111-2222-3333-4444-555555555555	2025-12-17 20:22:12.591056-08	update b8635e04-b3a6-488e-85e0-218d9ee13006 from PICKUP_READY to CANCELLED	\N
\.


--
-- Data for Name: prescriptions; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.prescriptions (id, patient_id, prescriber_id, written_date, received_date, current_step, current_status, priority, source, note, intake_completed_at, pharmacist_assigned_at, pharmacist_reviewed_at, patient_info_requested_at, provider_info_requested_at, denial_recorded_at, fill_queue_assigned_at, filling_started_at, special_order_created_at, fill_completed_at, qa_started_at, qa_failed_at, ready_for_pickup_at, picked_up_at, delivery_dispatched_at, delivery_confirmed_at, completed_at, cancelled_at, created_at, updated_at) FROM stdin;
6d81101a-90e7-499e-a565-341da8620707	750e8400-e29b-41d4-a716-446655440001	ef15a799-ca27-4307-9e16-a533ba87de3a	2025-02-02	2025-11-27 00:04:25.190174-08	READY_FOR_DELIVERY	DELIVERY_READY	STAT	fax	Urgent pain medication review	2025-11-26 00:04:25.190174-08	2025-11-26 04:04:25.190174-08	2025-11-26 06:04:25.190174-08	\N	\N	\N	2025-11-26 08:04:25.190174-08	2025-11-26 09:04:25.190174-08	\N	2025-11-26 11:04:25.190174-08	2025-11-26 12:04:25.190174-08	\N	\N	\N	\N	\N	\N	\N	2025-11-27 00:04:25.190174-08	2025-11-27 00:04:25.190174-08
8ea527cd-9d69-496b-b335-f887d9c1ddfd	750e8400-e29b-41d4-a716-446655440002	ef15a799-ca27-4307-9e16-a533ba87de3a	2025-01-29	2025-11-27 00:06:47.88877-08	NEEDS_PATIENT_INFO	ON_HOLD	ASAP	phone	Drug interaction detected	2025-11-25 00:06:47.88877-08	2025-11-25 04:06:47.88877-08	2025-11-25 06:06:47.88877-08	\N	\N	2025-11-25 06:06:47.88877-08	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2025-11-27 00:06:47.88877-08	2025-11-27 00:06:47.88877-08
bf5683d5-c65b-4d8a-a854-cd2f1c715000	750e8400-e29b-41d4-a716-446655440003	f85f3e82-6b68-41c0-90ae-af2101a0f2c9	2025-02-10	2025-11-27 00:05:39.791381-08	FILL	READY_FOR_FILL	NORMAL	walk-in	New-start maintenance medication	2025-11-24 00:01:45.092199-08	2025-11-24 04:01:45.092199-08	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2025-11-27 00:05:39.791381-08	2025-11-27 00:05:39.791381-08
b8635e04-b3a6-488e-85e0-218d9ee13006	750e8400-e29b-41d4-a716-446655440002	f85f3e82-6b68-41c0-90ae-af2101a0f2c9	2025-01-15	2025-11-27 00:01:45.092199-08	FILL	READY_FOR_FILL	NORMAL	eRx	Completed chronic med refill	2025-11-24 00:01:45.092199-08	2025-11-24 04:01:45.092199-08	2025-11-24 06:01:45.092199-08	\N	\N	\N	2025-11-24 12:01:45.092199-08	2025-11-24 14:01:45.092199-08	\N	2025-11-24 16:01:45.092199-08	2025-11-24 17:01:45.092199-08	\N	2025-11-24 18:01:45.092199-08	2025-11-24 23:01:45.092199-08	\N	\N	2025-11-25 00:01:45.092199-08	2025-12-17 20:22:12.582452-08	2025-11-27 00:01:45.092199-08	2025-11-27 00:01:45.092199-08
\.


--
-- Data for Name: reorder_rules; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.reorder_rules (id, rule_name, description, min_on_hand, max_stock_level, reorder_quantity, lead_time_days, seasonal, is_controlled, active) FROM stdin;
1	Fast Movers	High-volume drugs; keep stock high to avoid outages	20	100	80	3	f	f	t
2	Controlled CII Rule	Strict limit for Schedule II medications; keep minimal on-hand	5	20	15	7	f	t	t
3	OTC Seasonal Boost	Increase stock during flu/cold season (Nov–Mar)	15	120	100	4	t	f	t
4	Slow Movers	Low-demand medications; reorder small quantities	3	15	12	5	f	f	t
5	Specialty High-Cost	Keep minimal inventory of expensive specialty drugs	1	5	4	10	f	f	t
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.roles (id, role_name, display_name, description, active, created_at, updated_at) FROM stdin;
1	ADMIN	Administrator	Full system access, manage users, roles, and workflow configuration	t	2025-11-24 01:07:28.51938-08	2025-11-24 01:07:28.51938-08
2	SYSTEM	System Account	System-level role used for automated processes and background tasks	t	2025-11-24 01:07:28.51938-08	2025-11-24 01:07:28.51938-08
3	PHARMACIST	Pharmacist	Can verify prescriptions, approve clinical checks, and perform final verification	t	2025-11-24 01:07:28.51938-08	2025-11-24 01:07:28.51938-08
4	CLINICAL_PHARMACIST	Clinical Pharmacist	Performs clinical reviews, DUR checks, interaction checks, and counselling	t	2025-11-24 01:07:28.51938-08	2025-11-24 01:07:28.51938-08
5	TECH	Pharmacy Technician	Supports prescription processing, data entry, and order fulfillment	t	2025-11-24 01:07:28.51938-08	2025-11-24 01:07:28.51938-08
6	INTAKE_TECH	Intake Technician	Handles new prescription intake, scanning, and demographic verification	t	2025-11-24 01:07:28.51938-08	2025-11-24 01:07:28.51938-08
7	CALL_CENTER	Call Center Agent	Handles patient communication, refill requests, and status inquiries	t	2025-11-24 01:07:28.51938-08	2025-11-24 01:07:28.51938-08
8	DELIVERY_TECH	Delivery Technician	Handles delivery routing, handoff, and signature capture	t	2025-11-24 01:07:28.51938-08	2025-11-24 01:07:28.51938-08
9	SUPERVISOR	Pharmacy Supervisor	Manages workflow escalations and oversees technician work	t	2025-11-24 01:07:28.51938-08	2025-11-24 01:07:28.51938-08
10	AUDITOR	Auditor	Has read-only access to prescriptions, logs, and user activity	t	2025-11-24 01:07:28.51938-08	2025-11-24 01:07:28.51938-08
\.


--
-- Data for Name: stations; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.stations (id, station_prefix, department, location, starting_number, current_number, max_stations, created_at, updated_at) FROM stdin;
2	RX00	Test3	WSU	1	1	\N	2025-11-27 23:28:39.196284-08	2025-11-27 23:28:39.196284-08
1	RX00	Test22	WSU	1	1	\N	2025-11-27 23:28:20.327429-08	2025-12-05 21:04:18.005278-08
\.


--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.user_roles (user_id, role_id, assigned_at) FROM stdin;
11111111-2222-3333-4444-555555555555	2	2025-11-28 02:18:23.839698-08
11111111-2222-3333-4444-555555555555	1	2025-12-13 22:48:10.837938-08
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.users (id, username, display_name, email, active, created_at, updated_at) FROM stdin;
11111111-2222-3333-4444-555555555555	testuser	Test User2	paul.mai@datascience9.com	t	\N	2025-11-28 02:18:23.840116-08
\.


--
-- Data for Name: workflow_statuses; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.workflow_statuses (status_code, description, is_terminal) FROM stdin;
NEW	Prescription newly entered	f
INTAKE_REVIEW	Intake completeness review in progress	f
READY_FOR_PHARMACIST	Waiting for pharmacist clinical review	f
PHARMACIST_REVIEW	Pharmacist performing clinical review	f
NEEDS_PATIENT_INFO	Waiting for patient clarification	f
NEEDS_PROVIDER_INFO	Waiting for provider clarification	f
DENIED	Prescription denied by pharmacist	t
READY_FOR_FILL	Waiting for technician filling	f
FILLING	Technician is filling the prescription	f
NEED_SPECIAL_ORDER	No stock available; special order required	f
FILLED	Prescription filled and ready for QA	f
QA_VERIFICATION	Pharmacist performing QA verification	f
QA_FAILED	QA verification failed; returned to filling	f
READY_FOR_PICKUP	Prescription bagged and ready for pickup	f
PICKED_UP	Patient picked up prescription	t
READY_FOR_DELIVERY	Ready for delivery dispatch	f
DELIVERED	Delivered to patient	t
COMPLETED	Prescription fully completed and archived	t
CANCELLED	Prescription cancelled	t
ON_HOLD	Waiting for required documentations	f
\.


--
-- Data for Name: workflow_steps; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.workflow_steps (step_code, step_name, description, default_status, allowed_roles, sla_minutes, sort_order, is_terminal, is_active, queue_name) FROM stdin;
INTAKE_RECEIVED	Intake Received	Prescription received and awaiting intake processing.	NEW	{TECH,SUPERVISOR,ADMIN,SYSTEM}	15	1	f	t	INTAKE
PHARMACIST_REVIEW	Pharmacist Review	Clinical review by pharmacist for appropriateness, interactions, allergies.	IN_REVIEW	{PHARMACIST,SUPERVISOR,ADMIN,SYSTEM}	20	2	f	t	PHARMACIST_REVIEW
FILL	Fill Queue	Prescription being filled by pharmacy technicians.	READY_FOR_FILL	{TECH,SUPERVISOR,ADMIN,SYSTEM}	30	3	f	t	FILL
QA_CHECK	Quality Assurance Check	Final QA check by the pharmacist before dispensing.	QA_REQUIRED	{PHARMACIST,SUPERVISOR,ADMIN,SYSTEM}	15	4	f	t	QA
PICKUP_READY	Ready for Pickup	Prescription is packaged and ready for patient pickup.	AWAITING_PICKUP	{TECH,SUPERVISOR,ADMIN,SYSTEM}	\N	5	f	t	PICKUP
DENIAL	Denied	Prescription cannot proceed due to regulatory or clinical denial.	DENIED	{PHARMACIST,SUPERVISOR}	0	5	t	t	PHARMACIST_REVIEW
READY_FOR_DELIVERY	Delivered	Prescription to be delivered to patient or designated location.	DELIVERY_READY	{TECH,PHARMACIST,SYSTEM}	0	12	t	t	DELIVERY
NEEDS_PROVIDER_INFO	Provider Information Required	Pending clarification or information from prescriber.	ON_HOLD	{SYSTEM,ADMIN,TECH,PHARMACIST}	1440	4	f	t	PHARMACIST_REVIEW
NEEDS_PATIENT_INFO	Patient Information Required	Waiting for additional information from patient to proceed.	ON_HOLD	{SYSTEM,ADMIN,TECH,PHARMACIST}	1440	3	f	t	PHARMACIST_REVIEW
NEED_SPECIAL_ORDER	Special Order	Medication must be ordered due to non-stock or out-of-stock status.	ORDER_PENDING	{SYSTEM,ADMIN,TECH,PHARMACIST}	2880	7	f	t	FILL
CANCELLED	Cancelled	Prescription cancelled or voided.	CANCELLED	{SYSTEM,ADMIN}	\N	7	t	f	CANCELLED
COMPLETED	Completed	Prescription has been dispensed to the patient.	COMPLETED	{SYSTEM,ADMIN}	\N	6	t	f	COMPLETED
\.


--
-- Data for Name: workflow_transitions; Type: TABLE DATA; Schema: pharmacy3; Owner: postgres
--

COPY pharmacy3.workflow_transitions (id, from_step, to_step, result_status) FROM stdin;
43	INTAKE_RECEIVED	PHARMACIST_REVIEW	PHARMACIST_REVIEW
44	INTAKE_RECEIVED	CANCELLED	CANCELLED
45	PHARMACIST_REVIEW	FILL	READY_FOR_FILL
46	PHARMACIST_REVIEW	NEEDS_PATIENT_INFO	NEEDS_PATIENT_INFO
47	PHARMACIST_REVIEW	NEEDS_PROVIDER_INFO	NEEDS_PROVIDER_INFO
48	PHARMACIST_REVIEW	CANCELLED	DENIED
49	FILL	QA_CHECK	QA_CHECK
50	FILL	NEED_SPECIAL_ORDER	NEED_SPECIAL_ORDER
51	QA_CHECK	PICKUP_READY	READY_FOR_PICKUP
52	QA_CHECK	FILL	QA_FAILED
54	PICKUP_READY	READY_FOR_DELIVERY	READY_FOR_DELIVERY
55	READY_FOR_DELIVERY	COMPLETED	DELIVERED
56	PICKUP_READY	CANCELLED	CANCELLED
57	NEEDS_PATIENT_INFO	PHARMACIST_REVIEW	PHARMACIST_REVIEW
58	NEEDS_PROVIDER_INFO	PHARMACIST_REVIEW	PHARMACIST_REVIEW
\.


--
-- Data for Name: access_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.access_logs (id, user_id, patient_id, entity_type, entity_id, action, access_reason, access_context, ip_address, user_agent, accessed_at) FROM stdin;
1	550e8400-e29b-41d4-a716-446655440008	770e8400-e29b-41d4-a716-446655440001	prescription	dd0e8400-e29b-41d4-a716-446655440001	READ	Patient arrived for prescription pickup	{"device": "desktop", "source": "pos_system", "action_type": "view_prescription", "duration_ms": 245}	192.168.1.100	Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/91.0	2025-11-13 01:30:15.123456-08
2	550e8400-e29b-41d4-a716-446655440011	770e8400-e29b-41d4-a716-446655440002	patient	770e8400-e29b-41d4-a716-446655440002	READ	Verification of patient demographics for transaction	{"source": "transaction_system", "action_type": "view_patient_info", "duration_ms": 156, "fields_accessed": ["name", "mrn", "dob", "contact"]}	192.168.1.101	Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/91.0	2025-11-13 02:15:45.456789-08
3	550e8400-e29b-41d4-a716-446655440009	770e8400-e29b-41d4-a716-446655440003	prescription	dd0e8400-e29b-41d4-a716-446655440002	UPDATE	Pharmacist reviewing and updating prescription status	{"source": "pharmacy_system", "changes": ["status", "notes"], "new_status": "reviewed", "action_type": "update_prescription_status", "duration_ms": 342, "previous_status": "pending"}	192.168.1.102	Mozilla/5.0 (X11; Linux x86_64) Chrome/91.0	2025-11-13 03:02:30.789012-08
4	550e8400-e29b-41d4-a716-446655440008	770e8400-e29b-41d4-a716-446655440004	payment	ffe9017c-edbf-474b-b961-0dd8b5199001	READ	Processing transaction payment	{"amount": 125.50, "source": "pos_system", "action_type": "view_payment_details", "duration_ms": 198, "payment_method": "card"}	192.168.1.100	Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/91.0	2025-11-13 03:45:22.234567-08
5	550e8400-e29b-41d4-a716-446655440010	770e8400-e29b-41d4-a716-446655440005	patient	770e8400-e29b-41d4-a716-446655440005	READ	Manager performing audit of patient records	{"source": "admin_system", "audit_type": "compliance_check", "action_type": "audit_patient_records", "duration_ms": 523, "records_reviewed": 1}	192.168.1.105	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/91.0	2025-11-13 06:20:10.56789-08
6	550e8400-e29b-41d4-a716-446655440011	770e8400-e29b-41d4-a716-446655440006	prescription	dd0e8400-e29b-41d4-a716-446655440003	DELETE	Voiding prescription per prescriber request	{"source": "pharmacy_system", "action_type": "void_prescription", "approved_by": "550e8400-e29b-41d4-a716-446655440010", "duration_ms": 267, "void_reason": "prescriber_request"}	192.168.1.102	Mozilla/5.0 (X11; Linux x86_64) Chrome/91.0	2025-11-13 07:33:45.890123-08
7	550e8400-e29b-41d4-a716-446655440008	770e8400-e29b-41d4-a716-446655440007	alert	ffe9017c-edbf-474b-b961-0dd8b5199015	READ	Pharmacist reviewing clinical alert for patient medication	{"source": "alert_system", "severity": "high", "alert_type": "drug_interaction", "action_type": "view_clinical_alert", "duration_ms": 412}	192.168.1.103	Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/91.0	2025-11-13 08:12:05.123456-08
8	550e8400-e29b-41d4-a716-446655440009	\N	user	550e8400-e29b-41d4-a716-446655440008	READ	Manager reviewing user activity logs	{"source": "admin_system", "user_role": "pharmacist", "action_type": "view_user_profile", "duration_ms": 189, "fields_accessed": ["name", "email", "role", "last_login"]}	192.168.1.105	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/91.0	2025-11-13 09:25:30.456789-08
9	550e8400-e29b-41d4-a716-446655440008	770e8400-e29b-41d4-a716-446655440008	patient	770e8400-e29b-41d4-a716-446655440008	UPDATE	Updating patient contact information	{"source": "transaction_system", "action_type": "update_patient_contact", "duration_ms": 234, "fields_updated": ["phone", "email", "address"], "record_version": 2}	192.168.1.100	Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/91.0	2025-11-13 10:40:15.789012-08
10	550e8400-e29b-41d4-a716-446655440011	770e8400-e29b-41d4-a716-446655440009	prescription	dd0e8400-e29b-41d4-a716-446655440004	READ	Pharmacist counseling patient on medication	{"source": "pharmacy_system", "medication": "Lisinopril 10mg", "action_type": "view_prescription_for_counseling", "duration_ms": 867, "consultation_type": "patient_counseling"}	192.168.1.104	Mozilla/5.0 (iPad; CPU OS 14_7_1 like Mac OS X) AppleWebKit/605.1.15	2025-11-13 11:15:45.234567-08
11	550e8400-e29b-41d4-a716-446655440009	770e8400-e29b-41d4-a716-446655440003	prescription	dd0e8400-e29b-41d4-a716-446655440002	UPDATE	Routine access in pharmacy workflow	{"device": "desktop", "source": "pos_system", "action_type": "pharmacy_operation", "duration_ms": 255}	192.168.1.106	Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/91.0	2025-11-16 01:55:25.646824-08
12	550e8400-e29b-41d4-a716-446655440008	770e8400-e29b-41d4-a716-446655440009	payment	ffe9017c-edbf-474b-b961-0dd8b5199015	UPDATE	Routine access in pharmacy workflow	{"device": "desktop", "source": "pos_system", "action_type": "pharmacy_operation", "duration_ms": 18}	192.168.1.107	Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/91.0	2025-11-16 11:23:52.113739-08
13	550e8400-e29b-41d4-a716-446655440011	770e8400-e29b-41d4-a716-446655440005	payment	dd0e8400-e29b-41d4-a716-446655440002	READ	Routine access in pharmacy workflow	{"device": "tablet", "source": "pos_system", "action_type": "pharmacy_operation", "duration_ms": 44}	192.168.1.104	Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/91.0	2025-11-16 09:44:55.677442-08
14	550e8400-e29b-41d4-a716-446655440009	770e8400-e29b-41d4-a716-446655440006	alert	dd0e8400-e29b-41d4-a716-446655440002	UPDATE	Routine access in pharmacy workflow	{"device": "tablet", "source": "pos_system", "action_type": "pharmacy_operation", "duration_ms": 333}	192.168.1.109	Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/91.0	2025-11-16 15:16:43.387856-08
15	550e8400-e29b-41d4-a716-446655440008	770e8400-e29b-41d4-a716-446655440003	alert	dd0e8400-e29b-41d4-a716-446655440002	UPDATE	Routine access in pharmacy workflow	{"device": "desktop", "source": "pos_system", "action_type": "pharmacy_operation", "duration_ms": 955}	192.168.1.101	Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/91.0	2025-11-15 19:33:08.895449-08
16	550e8400-e29b-41d4-a716-446655440011	770e8400-e29b-41d4-a716-446655440009	patient	dd0e8400-e29b-41d4-a716-446655440002	UPDATE	Routine access in pharmacy workflow	{"device": "tablet", "source": "pos_system", "action_type": "pharmacy_operation", "duration_ms": 562}	192.168.1.107	Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/91.0	2025-11-16 16:49:42.212196-08
17	550e8400-e29b-41d4-a716-446655440009	770e8400-e29b-41d4-a716-446655440002	prescription	dd0e8400-e29b-41d4-a716-446655440002	UPDATE	Routine access in pharmacy workflow	{"device": "tablet", "source": "pos_system", "action_type": "pharmacy_operation", "duration_ms": 278}	192.168.1.100	Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/91.0	2025-11-16 08:07:04.292395-08
18	550e8400-e29b-41d4-a716-446655440009	770e8400-e29b-41d4-a716-446655440005	alert	dd0e8400-e29b-41d4-a716-446655440002	DELETE	Routine access in pharmacy workflow	{"device": "tablet", "source": "pos_system", "action_type": "pharmacy_operation", "duration_ms": 552}	192.168.1.106	Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/91.0	2025-11-16 07:50:22.370289-08
19	550e8400-e29b-41d4-a716-446655440011	770e8400-e29b-41d4-a716-446655440008	prescription	ffe9017c-edbf-474b-b961-0dd8b5199015	DELETE	Routine access in pharmacy workflow	{"device": "tablet", "source": "pos_system", "action_type": "pharmacy_operation", "duration_ms": 596}	192.168.1.105	Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/91.0	2025-11-16 00:04:43.470704-08
20	550e8400-e29b-41d4-a716-446655440008	770e8400-e29b-41d4-a716-446655440005	alert	dd0e8400-e29b-41d4-a716-446655440002	UPDATE	Routine access in pharmacy workflow	{"device": "tablet", "source": "pos_system", "action_type": "pharmacy_operation", "duration_ms": 398}	192.168.1.106	Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/91.0	2025-11-16 09:31:45.336146-08
21	550e8400-e29b-41d4-a716-446655440009	770e8400-e29b-41d4-a716-446655440002	payment	dd0e8400-e29b-41d4-a716-446655440001	UPDATE	Routine access in pharmacy workflow	{"device": "tablet", "source": "pos_system", "action_type": "pharmacy_operation", "duration_ms": 526}	192.168.1.101	Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/91.0	2025-11-16 08:28:45.663686-08
22	550e8400-e29b-41d4-a716-446655440009	770e8400-e29b-41d4-a716-446655440006	alert	dd0e8400-e29b-41d4-a716-446655440001	UPDATE	Routine access in pharmacy workflow	{"device": "tablet", "source": "pos_system", "action_type": "pharmacy_operation", "duration_ms": 903}	192.168.1.105	Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/91.0	2025-11-16 12:20:27.219276-08
23	550e8400-e29b-41d4-a716-446655440009	770e8400-e29b-41d4-a716-446655440009	payment	ffe9017c-edbf-474b-b961-0dd8b5199015	READ	Routine access in pharmacy workflow	{"device": "desktop", "source": "pos_system", "action_type": "pharmacy_operation", "duration_ms": 249}	192.168.1.107	Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/91.0	2025-11-16 11:21:03.313926-08
24	550e8400-e29b-41d4-a716-446655440009	770e8400-e29b-41d4-a716-446655440007	payment	ffe9017c-edbf-474b-b961-0dd8b5199015	READ	Routine access in pharmacy workflow	{"device": "tablet", "source": "pos_system", "action_type": "pharmacy_operation", "duration_ms": 229}	192.168.1.110	Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/91.0	2025-11-15 22:12:00.540692-08
25	550e8400-e29b-41d4-a716-446655440009	770e8400-e29b-41d4-a716-446655440008	alert	ffe9017c-edbf-474b-b961-0dd8b5199015	UPDATE	Routine access in pharmacy workflow	{"device": "tablet", "source": "pos_system", "action_type": "pharmacy_operation", "duration_ms": 132}	192.168.1.101	Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/91.0	2025-11-16 05:14:55.314919-08
26	550e8400-e29b-41d4-a716-446655440008	770e8400-e29b-41d4-a716-446655440009	patient	ffe9017c-edbf-474b-b961-0dd8b5199015	UPDATE	Routine access in pharmacy workflow	{"device": "tablet", "source": "pos_system", "action_type": "pharmacy_operation", "duration_ms": 378}	192.168.1.103	Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/91.0	2025-11-16 07:45:25.85962-08
27	550e8400-e29b-41d4-a716-446655440011	770e8400-e29b-41d4-a716-446655440006	prescription	dd0e8400-e29b-41d4-a716-446655440002	READ	Routine access in pharmacy workflow	{"device": "desktop", "source": "pos_system", "action_type": "pharmacy_operation", "duration_ms": 744}	192.168.1.103	Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/91.0	2025-11-15 18:58:48.547652-08
28	550e8400-e29b-41d4-a716-446655440008	770e8400-e29b-41d4-a716-446655440007	alert	dd0e8400-e29b-41d4-a716-446655440002	UPDATE	Routine access in pharmacy workflow	{"device": "desktop", "source": "pos_system", "action_type": "pharmacy_operation", "duration_ms": 837}	192.168.1.108	Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/91.0	2025-11-16 09:03:12.693633-08
29	550e8400-e29b-41d4-a716-446655440011	770e8400-e29b-41d4-a716-446655440003	payment	ffe9017c-edbf-474b-b961-0dd8b5199015	READ	Routine access in pharmacy workflow	{"device": "tablet", "source": "pos_system", "action_type": "pharmacy_operation", "duration_ms": 511}	192.168.1.110	Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/91.0	2025-11-16 15:52:17.325776-08
30	550e8400-e29b-41d4-a716-446655440009	770e8400-e29b-41d4-a716-446655440004	alert	ffe9017c-edbf-474b-b961-0dd8b5199015	READ	Routine access in pharmacy workflow	{"device": "tablet", "source": "pos_system", "action_type": "pharmacy_operation", "duration_ms": 34}	192.168.1.105	Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/91.0	2025-11-16 17:52:02.336662-08
\.


--
-- Data for Name: alert_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alert_logs (id, alert_rule_id, prescription_id, patient_id, triggered_by, context, action_taken, override_reason, created_at, suggested_alternatives, pharmacist_action, resolved_at) FROM stdin;
43	7	dd0e8400-e29b-41d4-a716-446655440002	770e8400-e29b-41d4-a716-446655440005	550e8400-e29b-41d4-a716-446655440011	{"notes": "Auto-generated alert event", "severity": "low", "trigger_source": "system"}	notified	\N	2025-11-11 22:07:39.490175-08	\N	Reviewed and accepted	\N
44	5	dd0e8400-e29b-41d4-a716-446655440002	770e8400-e29b-41d4-a716-446655440005	550e8400-e29b-41d4-a716-446655440011	{"notes": "Auto-generated alert event", "severity": "low", "trigger_source": "system"}	notified	Clinician override: not clinically significant	2025-11-06 22:07:39.490175-08	\N	Reviewed and overridden	\N
45	4	dd0e8400-e29b-41d4-a716-446655440002	770e8400-e29b-41d4-a716-446655440005	550e8400-e29b-41d4-a716-446655440011	{"notes": "Auto-generated alert event", "severity": "medium", "trigger_source": "pharmacist"}	overrode	Clinician override: not clinically significant	2025-11-05 22:07:39.490175-08	\N	Reviewed and overridden	\N
46	3	dd0e8400-e29b-41d4-a716-446655440002	770e8400-e29b-41d4-a716-446655440005	550e8400-e29b-41d4-a716-446655440011	{"notes": "Auto-generated alert event", "severity": "medium", "trigger_source": "pharmacist"}	overrode	Clinician override: not clinically significant	2025-11-04 22:07:39.490175-08	\N	Reviewed and overridden	\N
47	1	dd0e8400-e29b-41d4-a716-446655440002	770e8400-e29b-41d4-a716-446655440005	550e8400-e29b-41d4-a716-446655440011	{"notes": "Auto-generated alert event", "severity": "medium", "trigger_source": "pharmacist"}	overrode	Clinician override: not clinically significant	2025-11-03 22:07:39.490175-08	[{"reason": "better interaction profile", "drug_name": "Azithromycin"}, {"reason": "symptomatic relief option", "drug_name": "Acetaminophen"}]	Escalated to prescriber	\N
48	10	dd0e8400-e29b-41d4-a716-446655440002	770e8400-e29b-41d4-a716-446655440005	550e8400-e29b-41d4-a716-446655440011	{"notes": "Auto-generated alert event", "severity": "medium", "trigger_source": "pharmacist"}	overrode	Clinician override: not clinically significant	2025-11-01 22:07:39.490175-07	[{"reason": "better interaction profile", "drug_name": "Azithromycin"}, {"reason": "symptomatic relief option", "drug_name": "Acetaminophen"}]	Escalated to prescriber	\N
49	6	dd0e8400-e29b-41d4-a716-446655440002	770e8400-e29b-41d4-a716-446655440005	550e8400-e29b-41d4-a716-446655440011	{"notes": "Auto-generated alert event", "severity": "medium", "trigger_source": "pharmacist"}	overrode	System recommended override	2025-10-31 22:07:39.490175-07	[{"reason": "allergy-safe", "drug_name": "Cefdinir"}, {"reason": "symptomatic relief option", "drug_name": "Acetaminophen"}]	Escalated to prescriber	2025-11-10 22:07:39.490175-08
50	2	dd0e8400-e29b-41d4-a716-446655440002	770e8400-e29b-41d4-a716-446655440005	550e8400-e29b-41d4-a716-446655440011	{"notes": "Auto-generated alert event", "severity": "high", "trigger_source": "external_api"}	ignored	System recommended override	2025-10-26 22:07:39.490175-07	[{"reason": "allergy-safe", "drug_name": "Cefdinir"}, {"reason": "symptomatic relief option", "drug_name": "Naproxen"}]	Left note for next shift	2025-11-09 22:07:39.490175-08
51	9	dd0e8400-e29b-41d4-a716-446655440002	770e8400-e29b-41d4-a716-446655440005	550e8400-e29b-41d4-a716-446655440011	{"notes": "Auto-generated alert event", "severity": "high", "trigger_source": "external_api"}	ignored	Patient-specific exception documented	2025-10-23 22:07:39.490175-07	[{"reason": "formulary preferred", "drug_name": "Doxycycline"}, {"reason": "symptomatic relief option", "drug_name": "Naproxen"}]	Left note for next shift	2025-11-08 22:07:39.490175-08
52	8	dd0e8400-e29b-41d4-a716-446655440002	770e8400-e29b-41d4-a716-446655440005	550e8400-e29b-41d4-a716-446655440011	{"notes": "Auto-generated alert event", "severity": "high", "trigger_source": "external_api"}	ignored	Patient-specific exception documented	2025-10-18 22:07:39.490175-07	[{"reason": "formulary preferred", "drug_name": "Doxycycline"}, {"reason": "symptomatic relief option", "drug_name": "Naproxen"}]	Pending patient follow-up	2025-11-06 22:07:39.490175-08
\.


--
-- Data for Name: alert_rules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alert_rules (id, name, description, rule_json, severity, active, created_at) FROM stdin;
1	High MME Dose Alert	Triggers when total morphine milligram equivalents exceed safe limits.	{"type": "mme_threshold", "threshold": 50, "clinical_recommendation": "MME exceeds 50/day. Evaluate opioid risk factors, calculate total MME, and consider tapering or co-prescribing naloxone."}	high	t	2025-11-15 17:13:50.824622-08
2	Duplicate Opioid Therapy	Multiple active opioid prescriptions detected in the patient profile.	{"type": "duplicate_therapy", "class": "opioid", "clinical_recommendation": "Avoid duplicate opioid therapy. Verify prescriber intent and check PDMP before dispensing."}	medium	t	2025-11-15 17:13:50.824622-08
3	Opioid + Benzodiazepine Interaction	Concurrent use of opioids and benzodiazepines increases overdose risk.	{"type": "drug_interaction", "interaction": "opioid_benzodiazepine", "clinical_recommendation": "Avoid co-prescribing opioids and benzodiazepines when possible. Contact prescriber to confirm therapeutic intent."}	high	t	2025-11-15 17:13:50.824622-08
4	Renal Dose Adjustment Required	Medication requires dose adjustment for renal impairment.	{"type": "renal_adjustment", "egfr_threshold": 30, "clinical_recommendation": "Dose requires adjustment for eGFR < 30. Reduce dose or select an alternative medication."}	medium	t	2025-11-15 17:13:50.824622-08
5	Allergy – Ingredient Match	Medication contains an ingredient the patient is allergic to.	{"type": "allergy_check", "clinical_recommendation": "Medication contains a documented allergen. Confirm allergy details and consider alternative therapy."}	urgent	t	2025-11-15 17:13:50.824622-08
6	Maximum Daily Dose Exceeded	Prescribed daily dose exceeds clinical safety recommendations.	{"type": "max_daily_dose", "clinical_recommendation": "Prescribed dose exceeds recommended maximum. Adjust the dose or consult clinical guidelines."}	high	t	2025-11-15 17:13:50.824622-08
7	Beers Criteria – High-Risk in Elderly	Medication is potentially inappropriate for older adults based on Beers Criteria.	{"type": "beers_criteria", "age_threshold": 65, "clinical_recommendation": "Medication is high-risk for patients aged 65+. Use a safer alternative when possible."}	medium	t	2025-11-15 17:13:50.824622-08
8	Drug–Disease Contraindication	Medication is contraindicated for one of the patient’s active conditions.	{"type": "disease_contraindication", "clinical_recommendation": "Medication is contraindicated for patient’s condition. Reassess therapy or verify necessity with prescriber."}	urgent	t	2025-11-15 17:13:50.824622-08
9	Duplicate Therapy – NSAIDs	Patient is prescribed more than one NSAID simultaneously.	{"type": "duplicate_therapy", "class": "NSAID", "clinical_recommendation": "Avoid concurrent NSAID therapy. Limit to a single NSAID to reduce GI and renal risk."}	medium	t	2025-11-15 17:13:50.824622-08
10	Pregnancy Contraindicated Medication	Medication should not be used during pregnancy.	{"type": "pregnancy_contraindicated", "clinical_recommendation": "Medication is unsafe during pregnancy. Recommend alternative therapy and counsel patient."}	urgent	t	2025-11-15 17:13:50.824622-08
\.


--
-- Data for Name: auth_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_logs (id, user_id, username, event_type, status, ip_address, user_agent, metadata, created_at) FROM stdin;
1	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:23:38.076366-08
2	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:23:38.076366-08
3	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:23:38.076366-08
4	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:23:38.080481-08
5	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:25:11.821914-08
6	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:25:16.636871-08
7	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:25:16.640599-08
8	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:25:16.640597-08
9	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:37:09.321295-08
10	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:37:09.415685-08
11	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:37:09.420054-08
12	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:37:09.428296-08
13	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:37:09.429371-08
14	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:37:09.448424-08
15	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:37:09.463913-08
16	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:37:09.465511-08
17	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:37:35.828317-08
18	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:37:35.832874-08
19	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:37:35.945347-08
20	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:37:35.95192-08
21	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:37:36.2647-08
22	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:37:36.274646-08
23	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:37:36.276051-08
24	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:37:36.280422-08
25	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:39:40.939079-08
26	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:39:40.943971-08
27	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:39:40.949593-08
28	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:39:40.969701-08
29	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:39:41.348628-08
32	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:39:41.367068-08
34	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:43:27.179222-08
38	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:43:27.490825-08
43	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:44:08.437038-08
47	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:44:09.47302-08
30	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:39:41.355079-08
33	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:43:27.174489-08
39	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:43:27.495896-08
41	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:44:08.431219-08
48	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:44:09.474183-08
31	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:39:41.3598-08
35	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:43:27.187023-08
36	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:43:27.282328-08
37	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:43:27.486136-08
44	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:44:08.44079-08
46	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:44:09.463096-08
40	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:43:27.497311-08
42	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:44:08.432668-08
45	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-19 23:44:09.461395-08
49	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 00:45:04.262378-08
50	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 00:45:04.268766-08
51	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 00:45:04.275922-08
52	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 00:45:04.280201-08
53	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 00:54:11.320495-08
54	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 00:54:11.323916-08
55	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 00:54:11.328927-08
56	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 00:54:11.332001-08
57	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 01:05:09.359064-08
58	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 01:05:09.359064-08
59	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 01:05:09.36849-08
60	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 01:05:09.373998-08
61	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 01:05:30.323928-08
62	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 01:05:30.327063-08
63	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 01:05:30.334381-08
64	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 01:05:30.334381-08
66	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 10:28:02.728428-08
65	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 10:28:02.728428-08
67	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 10:28:02.728474-08
68	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 10:28:02.728489-08
69	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 10:35:00.365695-08
70	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 10:35:00.370208-08
71	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 10:35:00.378284-08
72	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 10:35:00.388667-08
73	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 10:35:32.052951-08
76	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 10:35:32.132591-08
77	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 10:41:35.16063-08
79	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 10:41:57.669024-08
81	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 10:43:23.860904-08
82	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 10:43:23.864774-08
74	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 10:35:32.056614-08
75	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 10:35:32.130881-08
78	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 10:41:35.167663-08
80	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 10:41:57.673661-08
83	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 13:34:50.740489-08
84	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 13:34:50.740489-08
85	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 13:35:25.37047-08
86	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 13:35:25.377413-08
87	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 13:52:32.971637-08
88	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 13:52:32.98692-08
89	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 14:00:11.722042-08
90	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 14:00:11.726169-08
91	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 14:01:10.505778-08
92	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 14:01:10.508155-08
93	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 14:01:24.355788-08
94	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 14:01:24.360234-08
95	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 14:01:28.132572-08
96	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 14:01:28.136481-08
97	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 14:02:59.488294-08
98	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 14:02:59.492051-08
99	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 14:04:39.096128-08
100	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 14:04:39.100018-08
101	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 14:21:40.987673-08
102	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 14:21:40.990163-08
103	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 14:22:05.288007-08
104	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 14:22:05.294293-08
105	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 14:22:09.27969-08
106	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 14:22:09.285093-08
107	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 14:23:26.300394-08
108	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 14:23:26.309235-08
109	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 14:23:30.265249-08
110	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 14:23:30.268294-08
111	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 15:26:08.428-08
112	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 15:26:08.428001-08
113	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 15:34:39.706029-08
114	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 15:34:39.706029-08
115	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 15:35:27.792633-08
116	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 15:35:27.799252-08
117	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 15:44:05.497131-08
118	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 15:44:05.500577-08
119	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 15:44:29.594362-08
120	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 15:44:29.597705-08
121	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 15:44:32.542159-08
122	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 15:44:32.544782-08
123	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 15:44:34.488758-08
124	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 15:44:34.493738-08
125	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 15:45:46.9157-08
126	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 15:45:46.921575-08
127	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 15:48:52.058641-08
128	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 15:48:52.060515-08
129	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 15:51:03.867105-08
130	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 15:51:03.873046-08
131	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 16:07:42.279024-08
132	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 16:07:42.280928-08
133	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 16:08:17.086022-08
134	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 16:08:17.092112-08
135	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 16:09:07.94076-08
136	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 16:09:07.953502-08
137	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 18:03:16.551856-08
138	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 18:03:16.546195-08
139	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 21:16:07.644983-08
140	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-20 21:16:07.645174-08
142	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:43:21.345523-08
141	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:43:21.345482-08
143	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:46:33.421901-08
144	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:46:33.425318-08
145	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:47:14.807449-08
146	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:47:14.810218-08
147	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:47:31.312881-08
148	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:47:31.326664-08
149	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:47:36.439202-08
150	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:47:36.443305-08
151	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:48:06.729643-08
152	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:48:06.734061-08
153	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:50:23.107902-08
154	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:50:23.116167-08
155	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:51:10.357374-08
156	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:51:10.362311-08
157	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:52:04.820357-08
158	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:52:04.827934-08
159	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:53:10.46999-08
160	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:53:10.471144-08
161	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:53:11.731406-08
162	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:53:11.732131-08
163	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:54:57.526577-08
164	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:54:57.528818-08
166	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:55:01.735395-08
167	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:57:27.937301-08
170	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:57:38.196339-08
171	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:59:37.376535-08
165	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:55:01.731873-08
168	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:57:27.943501-08
169	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:57:38.194717-08
172	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 09:59:37.380294-08
173	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 10:01:22.993232-08
174	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 10:01:23.043864-08
175	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 10:01:43.952467-08
176	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 10:01:43.952467-08
177	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 10:01:48.815147-08
178	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 10:01:48.867753-08
179	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 10:08:41.401256-08
180	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 10:08:41.417879-08
181	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 10:11:01.993664-08
182	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 10:11:02.048077-08
183	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 10:27:02.798687-08
184	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 10:27:02.822539-08
185	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 10:28:42.327835-08
186	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 10:28:42.354647-08
187	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 10:30:19.98828-08
188	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 10:30:20.017892-08
189	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 10:32:22.729869-08
190	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 10:32:22.786382-08
191	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 10:33:35.780742-08
192	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 10:33:35.82661-08
193	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 10:36:24.921416-08
194	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 10:36:24.922514-08
195	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 10:37:16.186874-08
196	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 10:37:16.188418-08
197	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 10:57:50.796411-08
198	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 10:57:50.836681-08
199	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 11:25:43.798008-08
202	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 11:26:46.108531-08
206	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 11:27:25.302465-08
207	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 11:42:28.139653-08
210	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 11:48:41.110295-08
200	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 11:25:43.827629-08
201	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 11:26:46.107237-08
203	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 11:26:50.053936-08
204	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 11:26:50.054444-08
205	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 11:27:25.300873-08
208	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 11:42:28.145646-08
209	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 11:48:41.106187-08
211	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 12:27:35.03843-08
212	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 12:27:35.100368-08
213	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 12:29:03.985895-08
214	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 12:29:04.03244-08
215	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 12:30:42.432235-08
216	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 12:30:42.434379-08
217	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 12:31:10.113483-08
218	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 12:31:10.114894-08
219	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 12:32:03.831145-08
220	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 12:32:03.833523-08
221	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 12:32:49.543674-08
222	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 12:32:49.545672-08
223	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 12:33:39.346865-08
224	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 12:33:39.348788-08
225	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 12:35:11.046206-08
226	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 12:35:11.08061-08
227	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 12:35:27.968102-08
228	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 12:35:28.00159-08
229	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 12:35:43.575173-08
230	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 12:35:43.617423-08
231	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 12:50:32.115244-08
232	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 12:50:32.148505-08
233	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 12:51:25.960386-08
234	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 12:51:26.019595-08
235	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 12:57:09.963933-08
238	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 12:57:25.765793-08
239	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 13:01:20.735227-08
240	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 13:01:20.79372-08
236	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 12:57:10.000806-08
237	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 12:57:25.737659-08
241	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 13:02:27.538487-08
242	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 13:02:27.616689-08
243	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 13:02:33.345009-08
244	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 13:02:33.404591-08
245	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 13:03:53.318452-08
246	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 13:03:53.365937-08
247	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 13:05:44.509502-08
248	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 13:05:44.540495-08
249	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 13:06:33.950033-08
250	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 13:06:33.982115-08
251	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 13:06:40.830056-08
252	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 13:06:40.860567-08
253	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 13:09:31.499761-08
254	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 13:09:31.5714-08
255	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 13:09:41.526174-08
256	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 13:09:41.527709-08
257	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 13:10:56.752953-08
258	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 13:10:56.754749-08
259	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:07:45.50983-08
260	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:07:45.525628-08
261	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:08:06.217096-08
262	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:08:06.271757-08
263	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:09:04.09955-08
264	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:09:04.103063-08
265	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:10:44.464832-08
266	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:10:44.472335-08
268	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:10:45.711155-08
269	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:10:49.459848-08
272	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:11:05.90787-08
275	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:13:59.524746-08
277	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:15:14.699485-08
278	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:15:14.749084-08
279	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:15:46.883281-08
284	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:16:20.360528-08
285	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:16:30.135691-08
287	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:16:46.528688-08
290	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:17:24.163133-08
291	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:18:25.555249-08
267	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:10:45.694938-08
270	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:10:49.468779-08
271	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:11:05.905403-08
273	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:11:24.175008-08
274	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:11:24.224372-08
276	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:13:59.524357-08
280	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:15:46.885385-08
281	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:16:02.387306-08
282	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:16:02.453399-08
283	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:16:20.359643-08
286	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:16:30.136754-08
288	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:16:46.530249-08
289	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:17:24.161294-08
292	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 14:18:25.556753-08
293	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:28:45.35552-08
294	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:28:45.395301-08
295	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:29:15.586785-08
296	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:29:15.612077-08
297	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:30:44.094407-08
298	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:30:44.120034-08
299	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:32:36.220447-08
300	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:32:36.257074-08
301	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:36:08.651799-08
302	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:36:08.68576-08
303	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:37:41.797295-08
304	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:37:41.830917-08
305	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:40:53.58867-08
306	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:40:53.624065-08
308	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:43:52.279136-08
309	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:45:14.633755-08
310	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:45:14.694825-08
311	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:46:04.168354-08
316	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:47:34.000824-08
307	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:43:52.210689-08
312	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:46:04.169381-08
313	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:47:17.021864-08
314	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:47:17.068191-08
315	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:47:34.000209-08
318	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:55:46.529144-08
317	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:55:46.528681-08
319	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:55:58.694174-08
320	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:55:58.695456-08
321	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:56:01.456905-08
322	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:56:01.45798-08
323	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:56:18.546881-08
324	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:56:18.547949-08
325	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:56:31.70452-08
326	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:56:31.706559-08
327	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:58:00.864295-08
328	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:58:00.866643-08
329	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:58:32.862552-08
330	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 15:58:32.864163-08
331	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 16:00:26.527667-08
332	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 16:00:26.528744-08
333	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 16:00:51.284237-08
334	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 16:00:51.325809-08
335	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 16:04:15.589766-08
336	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 16:04:15.647852-08
337	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 16:06:18.331753-08
338	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 16:06:18.332771-08
339	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 16:07:37.636316-08
341	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 16:08:02.090876-08
343	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 16:08:32.371523-08
346	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 16:08:43.972512-08
347	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 16:10:17.007626-08
350	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 16:13:45.737669-08
351	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 16:14:48.338282-08
354	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 16:18:18.665659-08
355	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 16:18:24.164913-08
356	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 16:18:24.189389-08
340	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 16:07:37.637156-08
342	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 16:08:02.090525-08
344	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 16:08:32.373132-08
345	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 16:08:43.96875-08
348	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 16:10:17.04416-08
349	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 16:13:45.709476-08
352	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 16:14:48.371632-08
353	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 16:18:18.639524-08
357	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 16:20:15.726968-08
358	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 16:20:15.753283-08
359	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 16:20:26.167846-08
360	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 16:20:26.196768-08
361	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 19:18:47.96022-08
362	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 19:18:48.027846-08
363	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 19:20:02.261076-08
364	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 19:20:02.311539-08
365	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 19:20:39.77053-08
366	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 19:20:39.907433-08
367	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 19:21:36.884836-08
368	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 19:21:37.01158-08
369	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 19:54:22.921531-08
370	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 19:54:22.920588-08
371	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 19:55:12.819666-08
372	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 19:55:12.820989-08
373	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 19:56:39.022586-08
374	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 19:56:39.023697-08
375	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 19:56:48.922712-08
376	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 19:56:48.924162-08
377	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 20:01:59.18511-08
378	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 20:01:59.232881-08
379	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 20:02:45.313276-08
380	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 20:02:45.315158-08
381	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 20:06:51.924944-08
383	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 20:09:28.758439-08
386	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 20:10:02.763175-08
387	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 20:10:09.233085-08
389	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 20:12:18.926515-08
393	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 20:14:11.78841-08
394	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 20:14:11.846686-08
395	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 20:17:29.441413-08
398	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 20:19:03.983552-08
382	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 20:06:51.924337-08
384	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 20:09:28.759363-08
385	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 20:10:02.762537-08
388	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 20:10:09.234452-08
390	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 20:12:18.983038-08
391	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 20:12:23.501938-08
392	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 20:12:23.542199-08
396	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 20:17:29.443033-08
397	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 20:19:03.981773-08
400	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 20:44:44.622328-08
399	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 20:44:44.621679-08
401	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 20:45:20.982109-08
402	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 20:45:20.983724-08
403	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 20:59:07.89076-08
404	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 20:59:07.89076-08
405	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 21:00:39.419818-08
406	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 21:00:39.420904-08
407	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 21:52:21.29764-08
408	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 21:52:21.406301-08
409	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 21:53:31.571991-08
410	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 21:53:31.605933-08
411	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 22:50:12.226804-08
412	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 22:50:12.300875-08
413	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 22:57:56.340856-08
414	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-21 22:57:56.341371-08
415	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-23 04:50:59.176875-08
416	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-23 04:50:59.213102-08
417	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-23 04:55:33.341006-08
418	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-23 04:55:33.342772-08
419	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-23 05:13:41.685256-08
420	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-23 05:13:41.685256-08
421	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-23 08:17:19.431953-08
422	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-23 08:17:19.43203-08
423	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-23 23:22:07.67622-08
424	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-23 23:22:07.678554-08
426	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-23 23:22:14.074093-08
425	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-23 23:22:14.074093-08
427	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-23 23:26:52.826881-08
428	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-25 00:37:26.156924-08
429	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-25 00:37:26.218517-08
430	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-25 00:38:26.739296-08
431	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-25 00:38:26.808485-08
433	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-25 19:53:41.576247-08
432	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-25 19:53:41.576252-08
434	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-25 20:46:53.693003-08
435	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-25 20:46:53.788275-08
436	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-27 00:52:01.23801-08
437	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-27 00:52:01.262931-08
438	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-27 00:53:53.836097-08
439	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-27 00:53:53.921509-08
440	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-27 01:15:33.469366-08
441	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-27 01:15:33.476536-08
442	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-27 22:28:49.400762-08
443	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-27 22:28:49.448652-08
444	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-30 01:05:58.596787-08
445	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-30 01:05:58.644314-08
446	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-30 15:00:15.740592-08
447	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-11-30 15:00:15.804994-08
448	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-12-02 17:33:11.444552-08
449	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-12-02 17:33:11.493843-08
450	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-12-02 22:54:15.79533-08
451	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-12-02 22:54:15.771684-08
452	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-12-09 23:04:01.755079-08
453	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-12-09 23:04:01.813388-08
454	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-12-10 00:31:34.235928-08
455	85ed3940-0383-4976-8e2e-edf71e148e99	Paul	login	success	192.168.1.200	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	{"os": "iOS", "eror": "none", "reason": "success", "browser": "webkit", "device_type": "Linux"}	2025-12-10 00:31:34.289458-08
\.


--
-- Data for Name: awp_reclaims; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.awp_reclaims (id, prescription_id, amount, processed_at, notes) FROM stdin;
\.


--
-- Data for Name: barcode_labels; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.barcode_labels (id, prescription_item_id, barcode, label_type, generated_at, printed_by, print_payload) FROM stdin;
\.


--
-- Data for Name: claims; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.claims (id, prescription_id, payer_name, claim_status, submitted_at, response, fiscal_fields) FROM stdin;
c58b857b-ec5f-4ffe-99bd-f3e83834dce3	dd0e8400-e29b-41d4-a716-446655440001	BlueCross BlueShield	approved	2025-11-10 01:25:19.097023-08	{"message": "Claim processed successfully", "claim_id": "CLM001001", "status_code": "00", "processing_date": "2024-11-09"}	{"copay": 25.00, "coinsurance": 0.10, "billed_amount": 125.50, "allowed_amount": 100.40, "patient_responsibility": 25.10}
e2ecf711-9c35-42c4-aed1-0525f8bc62ff	dd0e8400-e29b-41d4-a716-446655440002	United Healthcare	approved	2025-11-09 01:25:19.097023-08	{"message": "Claim approved with prior authorization", "claim_id": "CLM002001", "pa_number": "PA002001", "status_code": "00"}	{"copay": 30.00, "coinsurance": 20.15, "billed_amount": 250.75, "allowed_amount": 200.60, "patient_responsibility": 50.15}
62519aa9-991a-44a4-8d6b-7998a52e5349	dd0e8400-e29b-41d4-a716-446655440003	Aetna	rejected	2025-11-11 01:25:19.097023-08	{"message": "Drug not covered under formulary", "claim_id": "CLM003001", "status_code": "16", "rejection_reason": "NOTCOVERED"}	{"billed_amount": 180.00, "allowed_amount": 0.00, "rejection_note": "Patient may appeal denial", "patient_responsibility": 180.00}
840a5608-70a2-4180-aaab-1cf0a5ed3ab9	dd0e8400-e29b-41d4-a716-446655440004	Cigna	pending	2025-11-07 01:25:19.097023-08	{"message": "Claim submitted - awaiting payer response", "claim_id": "CLM004001", "status_code": null}	{"billed_amount": 95.25, "allowed_amount": null, "submission_date": "2024-11-07", "patient_responsibility": null}
7df21487-472e-42e7-b318-fff79585ff19	dd0e8400-e29b-41d4-a716-446655440005	Humana	approved	2025-11-08 01:25:19.097023-08	{"message": "Claim processed successfully", "claim_id": "CLM005001", "status_code": "00", "secondary_coverage": true}	{"copay": 15.00, "coinsurance": 53.00, "billed_amount": 340.00, "allowed_amount": 272.00, "patient_responsibility": 68.00}
dad51837-4f6a-48ff-88ae-ab5d9384855a	dd0e8400-e29b-41d4-a716-446655440006	Kaiser Permanente	approved	2025-11-10 01:25:19.097023-08	{"message": "Claim approved - HMO covered", "claim_id": "CLM006001", "plan_type": "HMO", "status_code": "00"}	{"copay": 30.00, "coinsurance": 1.10, "billed_amount": 155.50, "allowed_amount": 124.40, "patient_responsibility": 31.10}
fdf8130d-e6a3-479a-9d4a-4324ab23ce65	dd0e8400-e29b-41d4-a716-446655440007	Medicare	approved	2025-11-06 01:25:19.097023-08	{"part_d": true, "message": "Medicare claim processed", "claim_id": "CLM007001", "status_code": "00"}	{"copay": 5.00, "donut_hole": false, "coinsurance": 12.60, "billed_amount": 87.99, "allowed_amount": 70.39, "patient_responsibility": 17.60}
4dc1fd82-ec34-4879-b6af-63cfc996834a	dd0e8400-e29b-41d4-a716-446655440008	Medicaid	approved	2025-11-11 01:25:19.097023-08	{"message": "Medicaid claim approved", "claim_id": "CLM008001", "status_code": "00", "state_program": "CA"}	{"copay": 0.00, "coinsurance": 0.00, "billed_amount": 210.00, "allowed_amount": 210.00, "patient_responsibility": 0.00}
e10945fd-bdef-41e7-bd04-0367e2701e36	dd0e8400-e29b-41d4-a716-446655440009	Harvard University Health Plan	rejected	2025-11-09 01:25:19.097023-08	{"message": "Duplicate therapy detected", "claim_id": "CLM009001", "status_code": "75", "duplicate_rx": "RX123456789"}	{"billed_amount": 320.50, "allowed_amount": 0.00, "duplicate_note": "Patient has active prescription for same drug", "patient_responsibility": 320.50}
6a43f92e-a2f2-448a-933d-9fbc4456f40a	dd0e8400-e29b-41d4-a716-446655440010	Stanford University Health Plan	approved	2025-11-10 01:25:19.097023-08	{"message": "University plan claim approved", "claim_id": "CLM010001", "status_code": "00"}	{"copay": 15.00, "coinsurance": 14.15, "billed_amount": 145.75, "allowed_amount": 116.60, "patient_responsibility": 29.15}
bacdcba7-803b-4574-88d2-be9352dc7589	dd0e8400-e29b-41d4-a716-446655440011	Anthem Blue Cross	approved	2025-11-07 01:25:19.097023-08	{"message": "Claim approved for PPO member", "claim_id": "CLM011001", "status_code": "00"}	{"copay": 25.00, "coinsurance": 28.06, "billed_amount": 265.30, "allowed_amount": 212.24, "deductible_applied": 0.00, "patient_responsibility": 53.06}
674c7ce6-e42c-4e01-832e-42e5e33019d5	dd0e8400-e29b-41d4-a716-446655440012	Molina Healthcare	reversed	2025-10-31 01:25:19.097023-07	{"message": "Claim reversed - coverage terminated", "claim_id": "CLM012001", "status_code": "99", "reversal_date": "2024-11-02"}	{"billed_amount": 175.00, "allowed_amount": 0.00, "reversal_reason": "Member ineligible on service date", "patient_responsibility": 175.00}
f48c2f90-1f68-453a-8bc3-8ee708db3f41	dd0e8400-e29b-41d4-a716-446655440013	WellCare Health Plans	pending	2025-11-10 01:25:19.097023-08	{"message": "Claim submitted - awaiting payer processing", "claim_id": "CLM013001", "status_code": null}	{"billed_amount": 295.50, "allowed_amount": null, "submission_date": "2024-11-08", "patient_responsibility": null}
3c032719-c47b-4421-999d-2a883d60b05e	dd0e8400-e29b-41d4-a716-446655440014	CVS Health Insurance	approved	2025-11-06 01:25:19.097023-08	{"message": "Claim approved by CVS plan", "claim_id": "CLM014001", "status_code": "00"}	{"copay": 30.00, "coinsurance": 7.00, "billed_amount": 185.00, "allowed_amount": 148.00, "patient_responsibility": 37.00}
387a26ee-0c01-4801-a2b1-179d9f8c1a96	dd0e8400-e29b-41d4-a716-446655440015	Centene Corporation	approved	2025-11-09 01:25:19.097023-08	{"message": "Medicaid claim approved by Centene", "claim_id": "CLM015001", "status_code": "00"}	{"copay": 0.00, "coinsurance": 0.00, "billed_amount": 220.75, "allowed_amount": 220.75, "patient_responsibility": 0.00}
33a661bb-c3b7-490c-a374-639040e41ccb	dd0e8400-e29b-41d4-a716-446655440016	Oscar Health	approved	2025-11-08 01:25:19.097023-08	{"message": "Marketplace plan claim approved", "claim_id": "CLM016001", "status_code": "00"}	{"copay": 35.00, "coinsurance": 27.05, "billed_amount": 310.25, "allowed_amount": 248.20, "deductible_applied": 0.00, "patient_responsibility": 62.05}
3fc686b2-ef0d-44b3-a085-7fac2ab1e70c	dd0e8400-e29b-41d4-a716-446655440017	Bright Health Group	pending	2025-11-11 01:25:19.097023-08	{"message": "Claim submitted - awaiting adjudication", "claim_id": "CLM017001", "status_code": null}	{"billed_amount": 135.50, "allowed_amount": null, "submission_date": "2024-11-10", "patient_responsibility": null}
4f7490d7-3f2b-4ecd-b9ef-2786f92fa882	dd0e8400-e29b-41d4-a716-446655440018	Elevance Health	approved	2025-11-07 01:25:19.097023-08	{"message": "Claim approved for secondary coverage", "claim_id": "CLM018001", "status_code": "00"}	{"copay": 20.00, "coinsurance": 35.00, "primary_paid": 100.00, "billed_amount": 275.00, "allowed_amount": 220.00, "patient_responsibility": 55.00}
2cba8c52-64fe-40ae-ba9f-b58bfd076381	dd0e8400-e29b-41d4-a716-446655440019	UCLA Health Insurance	approved	2025-11-05 01:25:19.097023-08	{"message": "University health plan claim approved", "claim_id": "CLM019001", "status_code": "00"}	{"copay": 10.00, "coinsurance": 23.10, "billed_amount": 165.50, "allowed_amount": 132.40, "patient_responsibility": 33.10}
50f5fb3b-765d-4d19-8215-f83cf8c456dc	dd0e8400-e29b-41d4-a716-446655440020	Johns Hopkins Health Plan	pending	2025-11-12 01:25:19.097023-08	{"message": "Claim submitted for processing", "claim_id": "CLM020001", "status_code": null}	{"billed_amount": 245.75, "allowed_amount": null, "submission_date": "2024-11-11", "patient_responsibility": null}
\.


--
-- Data for Name: consent_records; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.consent_records (id, patient_id, consent_type, granted, source, recorded_by, recorded_at, metadata) FROM stdin;
\.


--
-- Data for Name: device_fingerprints; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.device_fingerprints (id, station_id, fingerprint_hash, browser_user_agent, screen_resolution, timezone, language, canvas_fingerprint, webgl_fingerprint, department, location, assigned_date, last_seen, is_active, access_count) FROM stdin;
b021749e-51b9-4429-97a6-e8077f1487c1	1	ae820970f0e5a8207db2eb7b2e8a3ebb2e40dd729e8d0981ac74c28399554e9c	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	1920x1080	America/Los_Angeles	US	\N	\N	Pharmacy	Main Counter	2025-11-19 20:30:58.792525	2025-11-19 20:30:58.792535	t	1
c069b58c-a674-4c92-84d7-b8f4b4ce18b5	1	271994726381bc6b83b31cccd06c79d4e59d6047c5f11b6d307ad94e44af1553	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	1920x1080	America/Los_Angeles	US	\N	\N	Pharmacy	Main Counter	2025-11-25 00:36:48.653627	2025-11-25 00:36:48.653646	t	1
\.


--
-- Data for Name: dir_fees; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dir_fees (id, claim_id, amount, reason, recorded_at, reconciliation_period, payer_name, metadata) FROM stdin;
31	4dc1fd82-ec34-4879-b6af-63cfc996834a	1.81	Performance adjustment	2025-11-18 00:06:54.290206-08	2025-Q1	OptumRx	{"source": "PBM-feed", "raw_score": 1.65, "recoup_batch": 1082}
32	bacdcba7-803b-4574-88d2-be9352dc7589	7.74	Performance adjustment	2025-11-10 00:06:54.290206-08	2025-Q1	OptumRx	{"source": "PBM-feed", "raw_score": 13.76, "recoup_batch": 1688}
33	fdf8130d-e6a3-479a-9d4a-4324ab23ce65	7.76	Performance adjustment	2025-11-10 00:06:54.290206-08	2025-Q1	OptumRx	{"source": "PBM-feed", "raw_score": 13.79, "recoup_batch": 1689}
34	dad51837-4f6a-48ff-88ae-ab5d9384855a	10.94	Network fee	2025-11-06 00:06:54.290206-08	2025-Q2	CVS Caremark	{"source": "PBM-feed", "raw_score": 20.28, "recoup_batch": 2014}
35	6a43f92e-a2f2-448a-933d-9fbc4456f40a	14.24	Network fee	2025-11-02 00:06:54.290206-07	2025-Q2	CVS Caremark	{"source": "PBM-feed", "raw_score": 27.02, "recoup_batch": 2351}
36	2cba8c52-64fe-40ae-ba9f-b58bfd076381	16.82	Network fee	2025-10-30 00:06:54.290206-07	2025-Q3	CVS Caremark	{"source": "PBM-feed", "raw_score": 32.29, "recoup_batch": 2614}
37	3c032719-c47b-4421-999d-2a883d60b05e	16.83	Network fee	2025-10-30 00:06:54.290206-07	2025-Q3	CVS Caremark	{"source": "PBM-feed", "raw_score": 32.30, "recoup_batch": 2614}
38	f48c2f90-1f68-453a-8bc3-8ee708db3f41	17.61	Medication adherence penalty	2025-10-29 00:06:54.290206-07	2025-Q3	CVS Caremark	{"source": "PBM-feed", "raw_score": 33.89, "recoup_batch": 2694}
39	62519aa9-991a-44a4-8d6b-7998a52e5349	18.06	Medication adherence penalty	2025-10-29 00:06:54.290206-07	2025-Q3	CVS Caremark	{"source": "PBM-feed", "raw_score": 34.82, "recoup_batch": 2740}
40	e2ecf711-9c35-42c4-aed1-0525f8bc62ff	23.33	Medication adherence penalty	2025-10-22 00:06:54.290206-07	2025-Q4	Express Scripts	{"source": "PBM-feed", "raw_score": 45.57, "recoup_batch": 3278}
41	3fc686b2-ef0d-44b3-a085-7fac2ab1e70c	25.34	Medication adherence penalty	2025-10-20 00:06:54.290206-07	2025-Q4	Express Scripts	{"source": "PBM-feed", "raw_score": 49.67, "recoup_batch": 3483}
42	840a5608-70a2-4180-aaab-1cf0a5ed3ab9	30.14	Star rating adjustment	2025-10-14 00:06:54.290206-07	2025-01	Express Scripts	{"source": "PBM-feed", "raw_score": 59.47, "recoup_batch": 3973}
43	387a26ee-0c01-4801-a2b1-179d9f8c1a96	31.41	Star rating adjustment	2025-10-12 00:06:54.290206-07	2025-01	Humana	{"source": "PBM-feed", "raw_score": 62.06, "recoup_batch": 4102}
44	674c7ce6-e42c-4e01-832e-42e5e33019d5	33.20	Star rating adjustment	2025-10-10 00:06:54.290206-07	2025-01	Humana	{"source": "PBM-feed", "raw_score": 65.71, "recoup_batch": 4285}
45	c58b857b-ec5f-4ffe-99bd-f3e83834dce3	40.77	Generic effective rate true-up	2025-10-01 00:06:54.290206-07	2025-02	Prime Therapeutics	{"source": "PBM-feed", "raw_score": 81.17, "recoup_batch": 5058}
46	7df21487-472e-42e7-b318-fff79585ff19	42.28	Direct remuneration recoupment	2025-09-29 00:06:54.290206-07	2025-02	Prime Therapeutics	{"source": "PBM-feed", "raw_score": 84.25, "recoup_batch": 5212}
47	4f7490d7-3f2b-4ecd-b9ef-2786f92fa882	44.24	Direct remuneration recoupment	2025-09-27 00:06:54.290206-07	2025-03	Prime Therapeutics	{"source": "PBM-feed", "raw_score": 88.24, "recoup_batch": 5412}
48	50f5fb3b-765d-4d19-8215-f83cf8c456dc	44.84	Direct remuneration recoupment	2025-09-26 00:06:54.290206-07	2025-03	Prime Therapeutics	{"source": "PBM-feed", "raw_score": 89.46, "recoup_batch": 5473}
49	e10945fd-bdef-41e7-bd04-0367e2701e36	47.95	Direct remuneration recoupment	2025-09-22 00:06:54.290206-07	2025-03	Prime Therapeutics	{"source": "PBM-feed", "raw_score": 95.81, "recoup_batch": 5790}
50	33a661bb-c3b7-490c-a374-639040e41ccb	49.90	Direct remuneration recoupment	2025-09-20 00:06:54.290206-07	2025-03	Prime Therapeutics	{"source": "PBM-feed", "raw_score": 99.79, "recoup_batch": 5989}
\.


--
-- Data for Name: dscsa_serials; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dscsa_serials (id, batch_id, serial_number, status, trace_metadata, last_updated) FROM stdin;
660e8400-e29b-41d4-a716-446655440001	550e8400-e29b-41d4-a716-446655440001	SN-2024-001-000001	in_stock	{"events": ["received"], "trading_partner": "wholesaler_1"}	2025-11-12 21:39:17.083328-08
660e8400-e29b-41d4-a716-446655440002	550e8400-e29b-41d4-a716-446655440001	SN-2024-001-000002	in_stock	{"events": ["received"], "trading_partner": "wholesaler_1"}	2025-11-12 21:39:17.083328-08
660e8400-e29b-41d4-a716-446655440003	550e8400-e29b-41d4-a716-446655440001	SN-2024-001-000003	shipped	{"events": ["received", "shipped"], "trading_partner": "retailer_5"}	2025-11-12 21:39:17.083328-08
660e8400-e29b-41d4-a716-446655440004	550e8400-e29b-41d4-a716-446655440002	SN-2024-002-000001	in_stock	{"events": ["received"], "trading_partner": "wholesaler_2"}	2025-11-12 21:39:17.083328-08
660e8400-e29b-41d4-a716-446655440005	550e8400-e29b-41d4-a716-446655440002	SN-2024-002-000002	verified	{"events": ["received", "verified"], "trading_partner": "wholesaler_2"}	2025-11-12 21:39:17.083328-08
660e8400-e29b-41d4-a716-446655440006	550e8400-e29b-41d4-a716-446655440003	SN-2024-003-000001	in_stock	{"events": ["received"], "trading_partner": "wholesaler_1"}	2025-11-12 21:39:17.083328-08
660e8400-e29b-41d4-a716-446655440007	550e8400-e29b-41d4-a716-446655440003	SN-2024-003-000002	in_stock	{"events": ["received"], "trading_partner": "wholesaler_1"}	2025-11-12 21:39:17.083328-08
660e8400-e29b-41d4-a716-446655440008	550e8400-e29b-41d4-a716-446655440004	SN-2024-004-000001	shipped	{"events": ["received", "shipped"], "trading_partner": "pharmacy_10"}	2025-11-12 21:39:17.083328-08
660e8400-e29b-41d4-a716-446655440009	550e8400-e29b-41d4-a716-446655440004	SN-2024-004-000002	in_stock	{"events": ["received"], "trading_partner": "wholesaler_3"}	2025-11-12 21:39:17.083328-08
660e8400-e29b-41d4-a716-446655440010	550e8400-e29b-41d4-a716-446655440005	SN-2024-005-000001	verified	{"events": ["received", "verified"], "trading_partner": "wholesaler_2"}	2025-11-12 21:39:17.083328-08
660e8400-e29b-41d4-a716-446655440011	550e8400-e29b-41d4-a716-446655440006	SN-2024-006-000001	in_stock	{"events": ["received"], "trading_partner": "wholesaler_1"}	2025-11-12 21:39:17.083328-08
660e8400-e29b-41d4-a716-446655440012	550e8400-e29b-41d4-a716-446655440006	SN-2024-006-000002	shipped	{"events": ["received", "shipped"], "trading_partner": "retailer_3"}	2025-11-12 21:39:17.083328-08
660e8400-e29b-41d4-a716-446655440013	550e8400-e29b-41d4-a716-446655440007	SN-2024-007-000001	in_stock	{"events": ["received"], "trading_partner": "wholesaler_2"}	2025-11-12 21:39:17.083328-08
660e8400-e29b-41d4-a716-446655440014	550e8400-e29b-41d4-a716-446655440008	SN-2024-008-000001	verified	{"events": ["received", "verified"], "trading_partner": "wholesaler_3"}	2025-11-12 21:39:17.083328-08
660e8400-e29b-41d4-a716-446655440015	550e8400-e29b-41d4-a716-446655440008	SN-2024-008-000002	in_stock	{"events": ["received"], "trading_partner": "wholesaler_3"}	2025-11-12 21:39:17.083328-08
660e8400-e29b-41d4-a716-446655440016	550e8400-e29b-41d4-a716-446655440009	SN-2024-009-000001	in_stock	{"events": ["received"], "trading_partner": "wholesaler_1"}	2025-11-12 21:39:17.083328-08
660e8400-e29b-41d4-a716-446655440017	550e8400-e29b-41d4-a716-446655440010	SN-2024-010-000001	shipped	{"events": ["received", "shipped"], "trading_partner": "pharmacy_8"}	2025-11-12 21:39:17.083328-08
660e8400-e29b-41d4-a716-446655440018	550e8400-e29b-41d4-a716-446655440011	SN-2024-011-000001	in_stock	{"events": ["received"], "trading_partner": "wholesaler_2"}	2025-11-12 21:39:17.083328-08
660e8400-e29b-41d4-a716-446655440019	550e8400-e29b-41d4-a716-446655440012	SN-2024-012-000001	verified	{"events": ["received", "verified"], "trading_partner": "wholesaler_1"}	2025-11-12 21:39:17.083328-08
660e8400-e29b-41d4-a716-446655440020	550e8400-e29b-41d4-a716-446655440013	SN-2024-013-000001	in_stock	{"events": ["received"], "trading_partner": "wholesaler_3"}	2025-11-12 21:39:17.083328-08
\.


--
-- Data for Name: efax_attachments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.efax_attachments (id, efax_job_id, file_name, file_type, file_size_bytes, encrypted_path, checksum, page_number, created_at) FROM stdin;
\.


--
-- Data for Name: efax_incoming; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.efax_incoming (id, from_fax_number, from_name, received_at, total_pages, file_path, checksum, linked_patient_id, linked_prescription_id, processed_by, metadata) FROM stdin;
\.


--
-- Data for Name: efax_jobs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.efax_jobs (id, patient_id, prescription_id, user_id, recipient_id, direction, subject, fax_number, provider_name, status, total_pages, priority, created_at, sent_at, completed_at, error_message, retry_count, metadata, claim_id) FROM stdin;
\.


--
-- Data for Name: efax_recipients; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.efax_recipients (id, name, organization, fax_number, email, contact_type, is_verified, last_verified_at, created_at) FROM stdin;
\.


--
-- Data for Name: efax_status_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.efax_status_logs (id, efax_job_id, status, message, provider_code, created_at) FROM stdin;
\.


--
-- Data for Name: encryption_keys_meta; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.encryption_keys_meta (id, key_id, purpose, created_at, rotated_at, metadata) FROM stdin;
\.


--
-- Data for Name: fingerprint_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fingerprint_history (id, station_id, old_fingerprint_hash, new_fingerprint_hash, change_date, reason, similarity_percentage, browser_user_agent, screen_resolution, timezone, notes, verified_by) FROM stdin;
\.


--
-- Data for Name: insurance_companies; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.insurance_companies (id, name, type, payer_id, contact_number, fax_number, email, address, city, state, zip, website, created_at, updated_at) FROM stdin;
dc0f2790-c152-4948-93f1-04fe12c9e8ae	BlueCross BlueShield	private	BCBS001	1-800-676-2583	1-215-245-1234	support@bcbs.com	1901 Market Street	Philadelphia	PA	19103	https://www.bcbs.com	2025-11-11 20:58:55.153432-08	2025-11-11 20:58:55.153432-08
5b0b325d-20bf-40f4-ae1d-cd03336e87a1	United Healthcare	private	UH002	1-888-830-2503	1-952-936-1234	care@unitedhealthcare.com	9900 Bren Road East	Minnetonka	MN	55343	https://www.unitedhealthcare.com	2025-11-11 20:58:55.153432-08	2025-11-11 20:58:55.153432-08
c3040c83-a8b0-4a8b-9ec7-cc7f71587bca	Aetna	private	AETNA003	1-800-328-2623	1-860-273-5678	customer.service@aetna.com	151 Farmington Avenue	Hartford	CT	06156	https://www.aetna.com	2025-11-11 20:58:55.153432-08	2025-11-11 20:58:55.153432-08
766ccc66-460a-4c63-8396-0f55713d9c19	Cigna	private	CIGNA004	1-800-244-6224	1-860-226-5000	support@cigna.com	900 Cottage Grove Road	Bloomfield	CT	06002	https://www.cigna.com	2025-11-11 20:58:55.153432-08	2025-11-11 20:58:55.153432-08
a5c95636-5ddc-49c1-bc45-4d96529ea61f	Humana	private	HUMANA005	1-800-448-6262	1-502-580-1234	care@humana.com	500 West Main Street	Louisville	KY	40202	https://www.humana.com	2025-11-11 20:58:55.153432-08	2025-11-11 20:58:55.153432-08
ec92e4e6-8d5f-4fe2-82d6-cd78ad3fa842	Kaiser Permanente	private	KP006	1-800-464-4000	1-510-271-6161	memberservices@kp.org	1 Kaiser Plaza	Oakland	CA	94612	https://www.kp.org	2025-11-11 20:58:55.153432-08	2025-11-11 20:58:55.153432-08
28c88ff4-68c8-40f1-80bb-63cf18f9fb6d	Medicare	medicare	MCRE007	1-800-772-1213	1-410-786-0727	info@cms.hhs.gov	7500 Security Boulevard	Baltimore	MD	21244	https://www.medicare.gov	2025-11-11 20:58:55.153432-08	2025-11-11 20:58:55.153432-08
620e99ae-4d87-4f34-9e3a-671eb3f0a6e5	Medicaid	medicaid	MCD008	1-877-267-2323	1-410-786-0729	info@cms.hhs.gov	7500 Security Boulevard	Baltimore	MD	21244	https://www.medicaid.gov	2025-11-11 20:58:55.153432-08	2025-11-11 20:58:55.153432-08
81f8d6fd-746a-42d9-8fe2-fc4b837d3802	Harvard University Health Plan	university	HUHP009	1-617-495-2000	1-617-495-0606	benefits@harvard.edu	Harvard Health Services	Cambridge	MA	02138	https://www.harvard.edu/health	2025-11-11 20:58:55.153432-08	2025-11-11 20:58:55.153432-08
edb67b7c-6634-4e4c-aa4b-d76d7bc57d81	Stanford University Health Plan	university	SUHP010	1-650-723-1000	1-650-725-7331	health@stanford.edu	Stanford Health	Palo Alto	CA	94305	https://www.stanford.edu/health	2025-11-11 20:58:55.153432-08	2025-11-11 20:58:55.153432-08
a30e07fb-a9d2-4aa6-ae2c-77b46c6dfda0	Anthem Blue Cross	private	ABC011	1-800-235-1003	1-317-488-6000	support@anthem.com	120 Monument Circle	Indianapolis	IN	46204	https://www.anthem.com	2025-11-11 20:58:55.153432-08	2025-11-11 20:58:55.153432-08
d8197f0b-12fc-4806-94bf-faac78c8b440	Molina Healthcare	other	MHCP012	1-888-562-5442	1-562-226-4000	care@molinahealthcare.com	200 Oceangate	Long Beach	CA	90802	https://www.molinahealthcare.com	2025-11-11 20:58:55.153432-08	2025-11-11 20:58:55.153432-08
62539581-71cd-4564-83b0-de35b1ce4e81	WellCare Health Plans	other	WCP013	1-888-925-3247	1-813-290-6200	support@wellcare.com	2901 North Rocky Point Drive	Tampa	FL	33607	https://www.wellcare.com	2025-11-11 20:58:55.153432-08	2025-11-11 20:58:55.153432-08
f7a29654-15ce-4b6e-8710-921d03970d50	CVS Health Insurance	private	CVS014	1-800-713-1895	1-401-770-3000	support@cvshealth.com	1 CVS Drive	Woonsocket	RI	02895	https://www.cvshealth.com/insurance	2025-11-11 20:58:55.153432-08	2025-11-11 20:58:55.153432-08
e70460ff-e525-4846-bbfa-525d9d8ee9bd	Centene Corporation	medicaid	CENT015	1-855-256-5834	1-314-725-4477	care@centene.com	7700 Forsyth Boulevard	St. Louis	MO	63105	https://www.centene.com	2025-11-11 20:58:55.153432-08	2025-11-11 20:58:55.153432-08
778e34d0-9da2-4101-ba5d-194adbb9b377	Oscar Health	private	OSCAR016	1-855-672-7627	1-646-839-1600	support@hioscar.com	32 East 31st Street	New York	NY	10016	https://www.oscar.com	2025-11-11 20:58:55.153432-08	2025-11-11 20:58:55.153432-08
ee46f287-e07e-4026-b80f-c8345ae461e3	Bright Health Group	private	BHG017	1-844-839-2846	1-866-241-1222	support@brighthealthgroup.com	4620 West 77th Street	Minneapolis	MN	55435	https://www.brighthealthgroup.com	2025-11-11 20:58:55.153432-08	2025-11-11 20:58:55.153432-08
e1d0952d-2d73-426b-831c-20bd48d42f08	Elevance Health	private	ELEV018	1-800-552-3453	1-317-488-6400	support@elevancehealth.com	120 Monument Circle	Indianapolis	IN	46204	https://www.elevancehealth.com	2025-11-11 20:58:55.153432-08	2025-11-11 20:58:55.153432-08
82de06a9-2d36-4ef2-9ad7-79e0d9724f16	UCLA Health Insurance	university	UCLAHI019	1-310-794-1000	1-310-825-3246	health@ucla.edu	757 Westwood Boulevard	Los Angeles	CA	90095	https://www.uclahealth.org	2025-11-11 20:58:55.153432-08	2025-11-11 20:58:55.153432-08
4c79257a-3075-4870-bc23-a11f1ef7f921	Johns Hopkins Health Plan	university	JHHP020	1-410-955-5000	1-410-955-3027	health@jh.edu	733 North Broadway	Baltimore	MD	21205	https://www.hopkinsmedicine.org	2025-11-11 20:58:55.153432-08	2025-11-11 20:58:55.153432-08
\.


--
-- Data for Name: integration_events; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.integration_events (id, integration_id, event_type, external_id, payload, processed_at, status) FROM stdin;
10101010-1010-4010-8010-101010101010	1	new_prescription_received	SUR-20240115-001	{"sig": "Take 1 tablet by mouth once daily", "quantity": 30, "medication": "Lisinopril 10mg", "prescriber": "Dr. Sarah Johnson", "date_written": "2024-01-15", "patient_name": "James Anderson", "prescriber_dea": "DJ123456", "valid_for_days": 365}	2024-01-15 02:05:00-08	processed
20202020-2020-4020-8020-202020202020	1	prescription_refill_request	SUR-20240116-002	{"rx_number": "4892401", "medication": "Metformin 500mg", "patient_name": "Sarah Martinez", "date_submitted": "2024-01-16", "current_refills": 2, "refills_requested": 5}	2024-01-16 06:40:00-08	processed
30303030-3030-4030-8030-303030303030	1	prescription_transferred	SUR-20240124-003	{"status": "accepted", "medication": "Ibuprofen 200mg", "transfer_to": "Downtown Pharmacy", "patient_name": "Michelle Brown", "transfer_from": "Community Pharmacy"}	2024-01-25 01:05:00-08	processed
40404040-4040-4040-8040-404040404040	1	prescription_status	SUR-20240122-004	{"status": "filled", "medication": "Albuterol 90mcg", "patient_name": "Angela Kim", "dispensed_date": "2024-01-22", "quantity_dispensed": 1}	2024-01-22 04:40:00-08	processed
50505050-5050-4050-8050-505050505050	2	auth_request_submitted	CMM-PA-20240117-001	{"payer": "United Healthcare", "medication": "Amoxicillin 500mg", "prescriber": "Dr. James Wilson", "patient_name": "Michael Chen", "date_submitted": "2024-01-17"}	2024-01-17 01:30:00-08	processed
60606060-6060-4060-8060-606060606060	2	auth_approved	CMM-PA-20240117-001	{"medication": "Amoxicillin 500mg", "valid_until": "2024-04-17", "patient_name": "Michael Chen", "approval_code": "AUTH-12345", "date_approved": "2024-01-17"}	2024-01-17 06:00:00-08	processed
70707070-7070-4070-8070-707070707070	2	auth_denied	CMM-PA-20240119-002	{"payer": "Cigna", "medication": "Atorvastatin 20mg", "patient_name": "David Rodriguez", "denial_reason": "generic_available", "appeal_deadline": "2024-02-19"}	2024-01-24 07:30:00-08	processed
80808080-8080-4080-8080-808080808080	2	auth_status_check	CMM-PA-20240123-003	{"payer": "United Healthcare", "medication": "Gabapentin 300mg", "days_pending": 5, "patient_name": "Christopher Lee", "current_status": "pending"}	2024-01-27 02:20:00-08	processed
90909090-9090-4090-8090-909090909090	3	lab_order_received	LAB-HL7-20240115-001	{"status": "received", "test_code": "LIPID_PANEL", "test_name": "Lipid Panel", "patient_id": "MRN001", "date_received": "2024-01-15"}	2024-01-15 02:15:00-08	processed
a0a0a0a0-a0a0-4a0a-8a0a-a0a0a0a0a0a0	3	lab_result_received	LAB-HL7-20240120-002	{"status": "complete", "results": {"hdl": 42, "ldl": 140, "triglycerides": 150, "total_cholesterol": 210}, "test_code": "LIPID_PANEL", "patient_id": "MRN001", "date_resulted": "2024-01-20"}	2024-01-20 03:30:00-08	processed
b0b0b0b0-b0b0-4b0b-8b0b-b0b0b0b0b0b0	3	lab_abnormal_value	LAB-HL7-20240120-003	{"date": "2024-01-20", "test_code": "CMP", "patient_id": "MRN002", "abnormal_values": [{"flag": "H", "test": "creatinine", "value": 2.1, "normal_range": "0.7-1.3"}]}	2024-01-20 04:00:00-08	processed
c0c0c0c0-c0c0-4c0c-8c0c-c0c0c0c0c0c0	4	mtm_consultation_submitted	MTM-20240120-001	{"patient_name": "Jessica Williams", "pharmacist_id": "asmith", "date_submitted": "2024-01-20", "consultation_type": "comprehensive_medication_review"}	2024-01-20 01:10:00-08	processed
d0d0d0d0-d0d0-4d0d-8d0d-d0d0d0d0d0d0	4	mtm_recommendation_received	MTM-20240120-001	{"priority": "high", "medication": "Simvastatin 40mg", "date_received": "2024-01-21", "recommendation": "discontinue_duplicate_therapy", "recommendation_id": "MTM-REC-001"}	2024-01-21 02:30:00-08	processed
e0e0e0e0-e0e0-4e0e-8e0e-e0e0e0e0e0e0	5	pdmp_query_submitted	PDMP-WA-20240123-001	{"state": "WA", "query_type": "patient_query", "patient_name": "Christopher Lee", "date_submitted": "2024-01-23"}	2024-01-23 02:40:00-08	processed
f0f0f0f0-f0f0-4f0f-8f0f-f0f0f0f0f0f0	5	pdmp_result_received	PDMP-WA-20240123-001	{"date_range": "last_30_days", "dispensers": 1, "alert_level": "medium", "prescribers": 2, "patient_name": "Christopher Lee", "date_received": "2024-01-23", "controlled_substance_count": 3}	2024-01-23 02:50:00-08	processed
a1a1a1a1-a1a1-4a1a-8a1a-a1a1a1a1a1a1	6	claim_submitted	CMS-20240115-001	{"ndc": "0069-0070-01", "batch_id": "BATCH-001", "quantity": 30, "medication": "Lisinopril 10mg", "patient_id": "MEDID001", "claim_total": 35.50, "date_filled": "2024-01-15"}	2024-01-15 12:00:00-08	processed
a2a2a2a2-a2a2-4a2a-8a2a-a2a2a2a2a2a2	6	claim_accepted	CMS-20240118-001	{"status": "accepted", "claim_ref": "CMS-20240115-001", "date_accepted": "2024-01-18", "patient_copay": 10.00, "payment_amount": 25.50}	2024-01-18 01:00:00-08	processed
a3a3a3a3-a3a3-4a3a-8a3a-a3a3a3a3a3a3	6	claim_rejected	CMS-20240117-002	{"status": "rejected", "claim_ref": "CMS-20240116-002", "date_rejected": "2024-01-17", "rejection_code": "CO", "rejection_reason": "COB - Coordination of Benefits Required"}	2024-01-17 06:30:00-08	processed
a4a4a4a4-a4a4-4a4a-8a4a-a4a4a4a4a4a4	7	eligibility_checked	ELIG-20240120-001	{"member_id": "UHC123456", "date_checked": "2024-01-20", "patient_name": "Robert Johnson", "eligibility_status": "active"}	2024-01-20 00:30:00-08	processed
a5a5a5a5-a5a5-4a5a-8a5a-a5a5a5a5a5a5	7	benefits_retrieved	ELIG-20240120-001	{"rx_copay": 20, "member_id": "UHC123456", "plan_name": "PPO Select", "coverage_type": "retail_and_mail", "rx_deductible": 250, "deductible_met": false}	2024-01-20 00:35:00-08	processed
a6a6a6a6-a6a6-4a6a-8a6a-a6a6a6a6a6a6	7	eligibility_ineligible	ELIG-20240121-002	{"reason": "coverage_terminated", "member_id": "CIG789012", "date_checked": "2024-01-21", "patient_name": "Emily Thompson", "eligibility_status": "inactive"}	2024-01-21 06:00:00-08	processed
a7a7a7a7-a7a7-4a7a-8a7a-a7a7a7a7a7a7	8	patient_record_retrieved	EHR-FHIR-20240122-001	{"dob": "1975-12-03", "allergies": ["NKDA"], "patient_id": "MRN007", "patient_name": "Robert Johnson", "date_retrieved": "2024-01-22"}	2024-01-22 01:00:00-08	processed
a8a8a8a8-a8a8-4a8a-8a8a-a8a8a8a8a8a8	8	medication_list_updated	EHR-FHIR-20240123-002	{"patient_id": "MRN002", "date_updated": "2024-01-23", "medications_added": [{"medication": "Metformin 500mg", "dose_frequency": "BID"}]}	2024-01-23 05:00:00-08	processed
a9a9a9a9-a9a9-4a9a-8a9a-a9a9a9a9a9a9	8	allergy_record_updated	EHR-FHIR-20240124-003	{"patient_id": "MRN003", "new_allergy": {"reaction": "anaphylaxis", "severity": "severe", "substance": "Penicillin"}, "date_updated": "2024-01-24"}	2024-01-24 02:30:00-08	processed
aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa	9	shipment_created	TPL-SHIP-20240115-001	{"items": 50, "origin": "Cardinal Health Distribution", "destination": "Downtown Pharmacy", "shipment_id": "SHIP-001", "date_created": "2024-01-15"}	2024-01-15 08:00:00-08	processed
bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb	9	shipment_in_transit	TPL-SHIP-20240115-001	{"status": "in_transit", "shipment_id": "SHIP-001", "date_updated": "2024-01-16", "current_location": "Portland Distribution Center", "estimated_delivery": "2024-01-17"}	2024-01-16 06:00:00-08	processed
cccccccc-cccc-4ccc-8ccc-cccccccccccc	9	delivery_confirmation	TPL-SHIP-20240115-001	{"status": "delivered", "shipment_id": "SHIP-001", "date_updated": "2024-01-17", "delivered_to": "Downtown Pharmacy", "delivery_date": "2024-01-17", "items_received": 50}	2024-01-17 02:00:00-08	processed
dddddddd-dddd-4ddd-8ddd-dddddddddddd	10	refill_reminder_sent	MSG-SMS-20240120-001	{"date_sent": "2024-01-20", "medication": "Metformin 500mg", "message_type": "refill_reminder", "patient_name": "Sarah Martinez", "patient_phone": "+12065550102"}	2024-01-20 01:00:00-08	processed
eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee	10	pickup_notification_sent	MSG-EMAIL-20240115-002	{"date_sent": "2024-01-15", "medication": "Lisinopril 10mg", "message_type": "ready_for_pickup", "patient_name": "James Anderson", "patient_email": "james.anderson@example.com"}	2024-01-15 06:00:00-08	processed
ffffffff-ffff-4fff-8fff-ffffffffffff	10	patient_response_received	MSG-SMS-20240121-003	{"message_type": "refill_confirmation", "patient_name": "Emily Thompson", "date_received": "2024-01-21", "message_content": "Yes, I would like to pick up my prescription tomorrow"}	2024-01-21 02:30:00-08	processed
\.


--
-- Data for Name: integrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.integrations (id, name, type, config, created_at) FROM stdin;
1	Surescripts	erx_gateway	{"endpoint": "https://emsapi.surescripts.com/api/v3", "api_version": "3.0", "authentication": "oauth2", "retry_attempts": 3, "timeout_seconds": 30, "supported_operations": ["new_prescription", "refill_request", "transfer", "cancel", "status_check"]}	2024-01-01 00:00:00-08
2	CoverMyMeds	prior_auth	{"endpoint": "https://api.covermymeds.com/v1", "api_version": "2.1", "authentication": "api_key", "retry_attempts": 5, "timeout_seconds": 60, "supported_operations": ["submit_auth", "check_status", "receive_response", "appeal"]}	2024-01-01 00:15:00-08
3	HL7-Lab	hl7_interface	{"host": "lab.hospital.local", "port": 2575, "encoding": "MLLP", "hl7_version": "2.5", "message_types": ["ORU^R01", "ORM^O01", "ADT^A01"], "timeout_seconds": 45, "supported_operations": ["receive_results", "send_orders"]}	2024-01-01 00:30:00-08
4	Medication Therapy Management	mtm_platform	{"endpoint": "https://mtm.insurance.com/api/pharmacist", "api_version": "1.0", "authentication": "oauth2", "timeout_seconds": 30, "supported_operations": ["submit_consultation", "get_recommendations", "log_interventions"]}	2024-01-02 00:00:00-08
5	PDMP - Washington State	state_pdmp	{"state": "WA", "endpoint": "https://pdmp.wa.gov/api/v2", "authentication": "certificate_based", "timeout_seconds": 90, "batch_processing": true, "supported_operations": ["query", "report"]}	2024-01-02 00:15:00-08
6	Medicare Claims Submission	claims_gateway	{"type": "medicare", "endpoint": "https://claims.cms.gov/submit", "batch_size": 1000, "authentication": "ssl_certificate", "timeout_seconds": 120, "supported_operations": ["submit_claim", "check_status", "receive_explanation"]}	2024-01-02 00:30:00-08
7	Insurance Eligibility Verification	eligibility_service	{"endpoint": "https://eligibility.multiplan.com/api", "provider": "MultiPlan", "authentication": "api_key", "timeout_seconds": 15, "supported_operations": ["check_eligibility", "get_benefits", "verify_coverage"]}	2024-01-03 00:00:00-08
8	Electronic Health Record	ehr_system	{"ehr_type": "Cerner", "endpoint": "https://ehr.hospital.local/fhir/r4", "api_version": "FHIR_R4", "authentication": "oauth2", "timeout_seconds": 30, "supported_operations": ["read_patient", "read_medication", "read_allergy", "update_note"]}	2024-01-03 00:15:00-08
9	Third-Party Logistics	tpl_tracking	{"endpoint": "https://tracking.cardinalhealth.com/api", "provider": "Cardinal Health", "authentication": "api_key", "timeout_seconds": 20, "supported_operations": ["track_shipment", "receive_delivery_confirmation", "update_inventory"]}	2024-01-03 00:30:00-08
10	Patient Communication Platform	patient_messaging	{"endpoint": "https://api.twilio.com/2010-04-01", "platform": "TwilioHealthCloud", "authentication": "api_key", "timeout_seconds": 30, "supported_operations": ["send_sms", "send_email", "receive_response"]}	2024-01-04 00:00:00-08
\.


--
-- Data for Name: inventory_batches; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.inventory_batches (id, inventory_item_id, lot_number, expiry_date, quantity_on_hand, location, wholesaler_id, created_at, last_order) FROM stdin;
550e8400-e29b-41d4-a716-446655440002	990e8400-e29b-41d4-a716-446655440002	LOT-2024-002	2025-11-15	350	Shelf B2	2	2025-11-12 21:39:17.083328-08	2025-11-12 21:39:17.083328-08
550e8400-e29b-41d4-a716-446655440003	990e8400-e29b-41d4-a716-446655440003	LOT-2024-003	2026-02-28	120	Shelf C3	1	2025-11-12 21:39:17.083328-08	2025-11-12 21:39:17.083328-08
550e8400-e29b-41d4-a716-446655440004	990e8400-e29b-41d4-a716-446655440004	LOT-2024-004	2025-09-30	450	Storage D	3	2025-11-12 21:39:17.083328-08	2025-11-12 21:39:17.083328-08
550e8400-e29b-41d4-a716-446655440005	990e8400-e29b-41d4-a716-446655440005	LOT-2024-005	2026-01-15	200	Shelf A2	2	2025-11-12 21:39:17.083328-08	2025-11-12 21:39:17.083328-08
550e8400-e29b-41d4-a716-446655440007	990e8400-e29b-41d4-a716-446655440002	LOT-2024-007	2026-03-10	175	Shelf C1	2	2025-11-12 21:39:17.083328-08	2025-11-12 21:39:17.083328-08
550e8400-e29b-41d4-a716-446655440008	990e8400-e29b-41d4-a716-446655440003	LOT-2024-008	2025-08-25	600	Storage E	3	2025-11-12 21:39:17.083328-08	2025-11-12 21:39:17.083328-08
550e8400-e29b-41d4-a716-446655440009	990e8400-e29b-41d4-a716-446655440004	LOT-2024-009	2025-12-15	250	Shelf D2	1	2025-11-12 21:39:17.083328-08	2025-11-12 21:39:17.083328-08
550e8400-e29b-41d4-a716-446655440010	990e8400-e29b-41d4-a716-446655440005	LOT-2024-010	2026-04-05	425	Shelf A3	2	2025-11-12 21:39:17.083328-08	2025-11-12 21:39:17.083328-08
550e8400-e29b-41d4-a716-446655440012	990e8400-e29b-41d4-a716-446655440002	LOT-2024-012	2025-07-15	380	Storage F	1	2025-11-12 21:39:17.083328-08	2025-11-12 21:39:17.083328-08
550e8400-e29b-41d4-a716-446655440013	990e8400-e29b-41d4-a716-446655440003	LOT-2024-013	2026-02-10	520	Shelf C2	2	2025-11-12 21:39:17.083328-08	2025-11-12 21:39:17.083328-08
550e8400-e29b-41d4-a716-446655440014	990e8400-e29b-41d4-a716-446655440004	LOT-2024-014	2025-09-20	275	Shelf D1	3	2025-11-12 21:39:17.083328-08	2025-11-12 21:39:17.083328-08
550e8400-e29b-41d4-a716-446655440015	990e8400-e29b-41d4-a716-446655440005	LOT-2024-015	2026-05-12	310	Shelf E1	1	2025-11-12 21:39:17.083328-08	2025-11-12 21:39:17.083328-08
550e8400-e29b-41d4-a716-446655440017	990e8400-e29b-41d4-a716-446655440002	LOT-2024-017	2025-12-10	190	Shelf A4	3	2025-11-12 21:39:17.083328-08	2025-11-12 21:39:17.083328-08
550e8400-e29b-41d4-a716-446655440018	990e8400-e29b-41d4-a716-446655440003	LOT-2024-018	2026-01-22	360	Shelf B4	1	2025-11-12 21:39:17.083328-08	2025-11-12 21:39:17.083328-08
550e8400-e29b-41d4-a716-446655440019	990e8400-e29b-41d4-a716-446655440004	LOT-2024-019	2025-08-30	540	Shelf C4	2	2025-11-12 21:39:17.083328-08	2025-11-12 21:39:17.083328-08
550e8400-e29b-41d4-a716-446655440020	990e8400-e29b-41d4-a716-446655440005	LOT-2024-020	2026-03-25	220	Storage H	3	2025-11-12 21:39:17.083328-08	2025-11-12 21:39:17.083328-08
550e8400-e29b-41d4-a716-446655440001	990e8400-e29b-41d4-a716-446655440001	LOT-2024-001	2025-12-31	5	Shelf A1	1	2025-11-12 21:39:17.083328-08	2025-11-12 21:39:17.083328-08
550e8400-e29b-41d4-a716-446655440006	990e8400-e29b-41d4-a716-446655440001	LOT-2024-006	2025-10-20	5	Shelf B1	1	2025-11-12 21:39:17.083328-08	2025-11-12 21:39:17.083328-08
550e8400-e29b-41d4-a716-446655440011	990e8400-e29b-41d4-a716-446655440001	LOT-2024-011	2025-11-30	5	Shelf B3	3	2025-11-12 21:39:17.083328-08	2025-11-12 21:39:17.083328-08
550e8400-e29b-41d4-a716-446655440016	990e8400-e29b-41d4-a716-446655440001	LOT-2024-016	2025-10-05	5	Storage G	2	2025-11-12 21:39:17.083328-08	2025-11-12 21:39:17.083328-08
\.


--
-- Data for Name: inventory_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.inventory_items (id, ndc, sku, name, strength, form, pack_size, reorder_rule_id, attributes, created_at) FROM stdin;
990e8400-e29b-41d4-a716-446655440001	0069-0070-01	SKU-LISINOPRIL-10	Lisinopril	10mg	tablet	30	1	{"dea_class": null, "controlled": false, "requires_rx": true, "manufacturer": "Merck"}	2024-01-10 01:30:00-08
990e8400-e29b-41d4-a716-446655440002	0093-0068-01	SKU-METFORMIN-500	Metformin	500mg	tablet	60	2	{"dea_class": null, "controlled": false, "requires_rx": true, "manufacturer": "Sandoz"}	2024-01-11 02:15:00-08
990e8400-e29b-41d4-a716-446655440003	0006-0057-03	SKU-AMOXICILLIN-500	Amoxicillin	500mg	capsule	30	3	{"dea_class": null, "controlled": false, "requires_rx": true, "manufacturer": "GlaxoSmithKline"}	2024-01-12 03:00:00-08
990e8400-e29b-41d4-a716-446655440004	0078-0165-01	SKU-HYDROCODONE-5	Hydrocodone/Acetaminophen	5mg/500mg	tablet	20	4	{"dea_class": "II", "controlled": true, "requires_rx": true, "manufacturer": "Bayer", "requires_cii": true}	2024-01-13 00:20:00-08
990e8400-e29b-41d4-a716-446655440005	0031-1924-18	SKU-ATORVASTATIN-20	Atorvastatin	20mg	tablet	30	5	{"dea_class": null, "controlled": false, "requires_rx": true, "manufacturer": "Pfizer"}	2024-01-14 05:45:00-08
990e8400-e29b-41d4-a716-446655440006	0115-1509-01	SKU-OMEPRAZOLE-20	Omeprazole	20mg	capsule	30	1	{"dea_class": null, "controlled": false, "requires_rx": true, "manufacturer": "AstraZeneca"}	2024-01-15 06:30:00-08
990e8400-e29b-41d4-a716-446655440007	0025-1321-31	SKU-LEVOTHYROXINE-75	Levothyroxine	75mcg	tablet	30	2	{"dea_class": null, "controlled": false, "requires_rx": true, "manufacturer": "Abbott"}	2024-01-16 01:00:00-08
990e8400-e29b-41d4-a716-446655440008	0001-0636-01	SKU-ASPIRIN-325	Aspirin	325mg	tablet	100	3	{"otc": true, "dea_class": null, "controlled": false, "requires_rx": false, "manufacturer": "Bayer"}	2024-01-17 02:30:00-08
990e8400-e29b-41d4-a716-446655440009	0597-0112-05	SKU-GABAPENTIN-300	Gabapentin	300mg	capsule	30	4	{"dea_class": null, "controlled": false, "requires_rx": true, "manufacturer": "Pfizer"}	2024-01-18 07:15:00-08
990e8400-e29b-41d4-a716-446655440010	0023-4153-02	SKU-IBUPROFEN-200	Ibuprofen	200mg	tablet	50	5	{"otc": true, "dea_class": null, "controlled": false, "requires_rx": false, "manufacturer": "Pfizer"}	2024-01-19 00:40:00-08
990e8400-e29b-41d4-a716-446655440011	0406-0122-01	SKU-AZITHROMYCIN-250	Azithromycin	250mg	tablet	30	1	{"dea_class": null, "controlled": false, "requires_rx": true, "manufacturer": "Pfizer"}	2024-01-20 01:30:00-08
990e8400-e29b-41d4-a716-446655440012	0143-1243-01	SKU-SERTRALINE-50	Sertraline	50mg	tablet	30	2	{"dea_class": null, "controlled": false, "requires_rx": true, "manufacturer": "Pfizer"}	2024-01-21 04:00:00-08
990e8400-e29b-41d4-a716-446655440013	0172-4220-60	SKU-ALBUTEROL-90	Albuterol	90mcg	inhaler	1	3	{"dea_class": null, "controlled": false, "requires_rx": true, "manufacturer": "GlaxoSmithKline"}	2024-01-22 00:15:00-08
990e8400-e29b-41d4-a716-446655440014	0009-0059-03	SKU-AMITRIPTYLINE-25	Amitriptyline	25mg	tablet	30	4	{"dea_class": null, "controlled": false, "requires_rx": true, "manufacturer": "Merck"}	2024-01-23 02:45:00-08
990e8400-e29b-41d4-a716-446655440015	0054-0123-30	SKU-LORATADINE-10	Loratadine	10mg	tablet	30	5	{"otc": true, "dea_class": null, "controlled": false, "requires_rx": false, "manufacturer": "Bayer"}	2024-01-24 05:20:00-08
990e8400-e29b-41d4-a716-446655440016	0536-1084-01	SKU-MORPHINE-30	Morphine Sulfate	30mg	tablet	20	1	{"dea_class": "II", "controlled": true, "requires_rx": true, "manufacturer": "Purdue Pharma", "requires_cii": true}	2024-01-25 06:50:00-08
990e8400-e29b-41d4-a716-446655440017	0173-0854-00	SKU-METOPROLOL-50	Metoprolol	50mg	tablet	30	2	{"dea_class": null, "controlled": false, "requires_rx": true, "manufacturer": "Novartis"}	2024-01-26 03:30:00-08
990e8400-e29b-41d4-a716-446655440018	0490-1053-01	SKU-FUROSEMIDE-40	Furosemide	40mg	tablet	30	3	{"dea_class": null, "controlled": false, "requires_rx": true, "manufacturer": "Sun Pharma"}	2024-01-27 01:00:00-08
990e8400-e29b-41d4-a716-446655440019	0054-4013-25	SKU-DIPHENHYDRAMINE-25	Diphenhydramine	25mg	capsule	24	4	{"otc": true, "dea_class": null, "controlled": false, "requires_rx": false, "manufacturer": "J&J"}	2024-01-28 07:25:00-08
990e8400-e29b-41d4-a716-446655440020	0527-1627-01	SKU-PAROXETINE-20	Paroxetine	20mg	tablet	30	5	{"dea_class": null, "controlled": false, "requires_rx": true, "manufacturer": "GlaxoSmithKline"}	2024-01-29 02:10:00-08
\.


--
-- Data for Name: patient_aliases; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.patient_aliases (id, patient_id, alias_type, alias_value, created_at) FROM stdin;
1	770e8400-e29b-41d4-a716-446655440001	school_id	SID-2024-00001	2024-01-10 01:35:00-08
2	770e8400-e29b-41d4-a716-446655440001	insurance_id	INS-WA-8374921	2024-01-10 01:40:00-08
3	770e8400-e29b-41d4-a716-446655440002	insurance_id	INS-WA-5829471	2024-01-11 02:20:00-08
4	770e8400-e29b-41d4-a716-446655440003	school_id	SID-2024-00002	2024-01-12 03:50:00-08
5	770e8400-e29b-41d4-a716-446655440003	social_security	SSN-XXX-XX-4821	2024-01-12 04:00:00-08
6	770e8400-e29b-41d4-a716-446655440004	insurance_id	INS-WA-3847562	2024-01-13 00:25:00-08
7	770e8400-e29b-41d4-a716-446655440005	school_id	SID-2024-00003	2024-01-14 05:55:00-08
8	770e8400-e29b-41d4-a716-446655440005	employee_id	EMP-SEA-7392851	2024-01-14 06:05:00-08
9	770e8400-e29b-41d4-a716-446655440006	insurance_id	INS-WA-6574938	2024-01-15 06:35:00-08
10	770e8400-e29b-41d4-a716-446655440007	school_id	SID-2024-00004	2024-01-16 01:20:00-08
11	770e8400-e29b-41d4-a716-446655440007	insurance_id	INS-WA-9283746	2024-01-16 01:30:00-08
12	770e8400-e29b-41d4-a716-446655440008	employee_id	EMP-SEA-4928374	2024-01-17 02:45:00-08
13	770e8400-e29b-41d4-a716-446655440009	school_id	SID-2024-00005	2024-01-18 07:30:00-08
14	770e8400-e29b-41d4-a716-446655440009	insurance_id	INS-WA-1847562	2024-01-18 07:40:00-08
15	770e8400-e29b-41d4-a716-446655440010	insurance_id	INS-WA-7384920	2024-01-19 04:00:00-08
16	770e8400-e29b-41d4-a716-446655440011	school_id	SID-2024-00006	2024-01-20 01:35:00-08
17	770e8400-e29b-41d4-a716-446655440011	employee_id	EMP-TAC-5829371	2024-01-20 01:45:00-08
18	770e8400-e29b-41d4-a716-446655440012	insurance_id	INS-WA-3927481	2024-01-21 00:50:00-08
19	770e8400-e29b-41d4-a716-446655440013	school_id	SID-2024-00007	2024-01-22 05:20:00-08
20	770e8400-e29b-41d4-a716-446655440013	insurance_id	INS-WA-8374629	2024-01-22 05:30:00-08
\.


--
-- Data for Name: patient_insurances; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.patient_insurances (id, patient_id, insurance_company_id, member_id, group_number, plan_name, effective_date, expiration_date, coverage_type, copay_fixed, copay_percent, deductible, out_of_pocket_max, status, created_at, updated_at) FROM stdin;
e2675756-7539-4877-bc4f-d403f7190cc8	770e8400-e29b-41d4-a716-446655440001	dc0f2790-c152-4948-93f1-04fe12c9e8ae	MEM001234567	GRP12345	BlueCross Preferred Plus	2024-01-01	2024-12-31	primary	25.00	\N	1000.00	5000.00	active	2025-11-11 21:11:28.259369-08	2025-11-11 21:11:28.259369-08
cc9868db-cfe2-4b6b-8c16-ef50688a64f4	770e8400-e29b-41d4-a716-446655440002	5b0b325d-20bf-40f4-ae1d-cd03336e87a1	UH987654321	GRP54321	UnitedHealth Choice Plus	2024-03-15	2025-03-14	primary	30.00	\N	1500.00	6000.00	active	2025-11-11 21:11:28.259369-08	2025-11-11 21:11:28.259369-08
f65bf5f3-bf3e-47eb-b25c-91d8a49560ff	770e8400-e29b-41d4-a716-446655440003	c3040c83-a8b0-4a8b-9ec7-cc7f71587bca	AETNA56789012	GRP98765	Aetna PPO Select	2023-06-01	2024-05-31	primary	20.00	\N	750.00	4000.00	inactive	2025-05-11 21:11:28.259369-07	2025-08-11 21:11:28.259369-07
2b9ee988-66ca-4717-8796-551595618004	770e8400-e29b-41d4-a716-446655440004	766ccc66-460a-4c63-8396-0f55713d9c19	CIGNA111222333	GRP11111	Cigna Open Access Plus	2024-02-01	2025-01-31	primary	35.00	\N	2000.00	7000.00	active	2025-11-11 21:11:28.259369-08	2025-11-11 21:11:28.259369-08
c44c8467-e85c-40a9-993e-1627c8c2415a	770e8400-e29b-41d4-a716-446655440005	a5c95636-5ddc-49c1-bc45-4d96529ea61f	HUMANA444555666	GRP22222	Humana Choice	2024-01-15	2024-12-31	secondary	15.00	\N	500.00	3000.00	active	2025-11-11 21:11:28.259369-08	2025-11-11 21:11:28.259369-08
248ce4d3-18ba-4bdd-a33f-cb400fd34ed9	770e8400-e29b-41d4-a716-446655440006	ec92e4e6-8d5f-4fe2-82d6-cd78ad3fa842	KP777888999	GRP33333	Kaiser Permanente HMO	2024-04-01	2025-03-31	primary	40.00	\N	1200.00	5500.00	active	2025-11-11 21:11:28.259369-08	2025-11-11 21:11:28.259369-08
26cbf954-8ca7-4d87-8de2-82e6963ea45e	770e8400-e29b-41d4-a716-446655440007	28c88ff4-68c8-40f1-80bb-63cf18f9fb6d	MCRE000111222	GROUPA	Medicare Part B	2023-01-01	2024-12-31	primary	\N	20.00	1600.00	8000.00	active	2025-11-11 21:11:28.259369-08	2025-11-11 21:11:28.259369-08
7ae0ab81-e263-47ad-a1c4-27fb65869a7a	770e8400-e29b-41d4-a716-446655440008	620e99ae-4d87-4f34-9e3a-671eb3f0a6e5	MCD333444555	STATEID	Medicaid State Program	2024-01-01	2024-12-31	primary	\N	\N	0.00	2500.00	active	2025-11-11 21:11:28.259369-08	2025-11-11 21:11:28.259369-08
5d6fc211-b1bf-4a0b-9f57-45af3aa8654a	770e8400-e29b-41d4-a716-446655440009	81f8d6fd-746a-42d9-8fe2-fc4b837d3802	HUHP666777888	HSGP01	Harvard Student Health Plus	2024-08-01	2025-07-31	primary	10.00	\N	250.00	2000.00	active	2025-11-11 21:11:28.259369-08	2025-11-11 21:11:28.259369-08
f363f253-a7b9-4479-a38e-731b1409bae2	770e8400-e29b-41d4-a716-446655440010	edb67b7c-6634-4e4c-aa4b-d76d7bc57d81	SUHP999000111	SSGP02	Stanford Cardinal Care	2024-09-01	2025-08-31	primary	15.00	\N	300.00	2500.00	active	2025-11-11 21:11:28.259369-08	2025-11-11 21:11:28.259369-08
9d386647-4319-48e9-8c44-95813e7d7833	770e8400-e29b-41d4-a716-446655440011	a30e07fb-a9d2-4aa6-ae2c-77b46c6dfda0	ABC222333444	GRP44444	Anthem Blue Cross Select	2024-05-01	2025-04-30	primary	25.00	\N	1000.00	5000.00	active	2025-11-11 21:11:28.259369-08	2025-11-11 21:11:28.259369-08
363fef83-7ebd-4eb4-b9e2-c3f1d0c6ec03	770e8400-e29b-41d4-a716-446655440012	d8197f0b-12fc-4806-94bf-faac78c8b440	MHCP555666777	GRP55555	Molina Marketplace Plus	2024-01-01	2024-12-31	secondary	20.00	\N	750.00	4000.00	active	2025-11-11 21:11:28.259369-08	2025-11-11 21:11:28.259369-08
41eb2ee8-0090-4146-a745-7c08aab5628b	770e8400-e29b-41d4-a716-446655440013	62539581-71cd-4564-83b0-de35b1ce4e81	WCP888999000	GRP66666	WellCare Health Advantage	2023-11-01	2024-10-31	primary	\N	15.00	500.00	3500.00	inactive	2024-11-11 21:11:28.259369-08	2025-10-11 21:11:28.259369-07
de06541f-9397-4039-a308-57cad1fe00c9	770e8400-e29b-41d4-a716-446655440014	f7a29654-15ce-4b6e-8710-921d03970d50	CVS111222333	GRP77777	CVS Health Care Select	2024-03-01	2025-02-28	primary	30.00	\N	1200.00	6000.00	active	2025-11-11 21:11:28.259369-08	2025-11-11 21:11:28.259369-08
23ebd428-6436-4478-8edf-b6cea458f460	770e8400-e29b-41d4-a716-446655440015	e70460ff-e525-4846-bbfa-525d9d8ee9bd	CENT444555666	GRP88888	Centene State Medicaid	2024-02-01	2025-01-31	primary	\N	\N	0.00	2000.00	active	2025-11-11 21:11:28.259369-08	2025-11-11 21:11:28.259369-08
8da02216-28ff-4be7-ae6b-1b31aca4d59c	770e8400-e29b-41d4-a716-446655440016	778e34d0-9da2-4101-ba5d-194adbb9b377	OSCAR777888999	GRP99999	Oscar Health Marketplace	2024-01-01	2024-12-31	primary	35.00	\N	2000.00	7000.00	active	2025-11-11 21:11:28.259369-08	2025-11-11 21:11:28.259369-08
03888f9c-2d03-4565-bf1a-111827bcde69	770e8400-e29b-41d4-a716-446655440017	ee46f287-e07e-4026-b80f-c8345ae461e3	BHG000111222	GRP00001	Bright Health Select	2024-04-15	2025-04-14	primary	25.00	\N	1000.00	5000.00	active	2025-11-11 21:11:28.259369-08	2025-11-11 21:11:28.259369-08
525cc520-86fe-4891-993d-46678cc202e4	770e8400-e29b-41d4-a716-446655440018	e1d0952d-2d73-426b-831c-20bd48d42f08	ELEV333444555	GRP00002	Elevance Health Premier	2024-06-01	2025-05-31	secondary	20.00	\N	750.00	4500.00	active	2025-11-11 21:11:28.259369-08	2025-11-11 21:11:28.259369-08
c090d552-982c-43df-abc2-9b1cdb0d46b4	770e8400-e29b-41d4-a716-446655440019	82de06a9-2d36-4ef2-9ad7-79e0d9724f16	UCLAHI666777888	UCSGP01	UCLA Health Coverage	2024-07-01	2025-06-30	primary	10.00	\N	200.00	1500.00	active	2025-11-11 21:11:28.259369-08	2025-11-11 21:11:28.259369-08
6a39a161-0eed-4d0a-a483-bdc7961cbcab	770e8400-e29b-41d4-a716-446655440020	4c79257a-3075-4870-bc23-a11f1ef7f921	JHHP999000111	JHSGP01	Johns Hopkins Health Plan	2024-08-15	2025-08-14	primary	15.00	\N	400.00	2500.00	active	2025-11-11 21:11:28.259369-08	2025-11-11 21:11:28.259369-08
\.


--
-- Data for Name: patients; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.patients (id, mrn, first_name, last_name, dob, gender, contact, sensitive_data, is_student_record, preferred_language, accessibility_preferences, created_at) FROM stdin;
770e8400-e29b-41d4-a716-446655440001	MRN001	James	Anderson	1985-03-15	Male	{"email": "james.anderson@example.com", "phone": "206-555-0101", "addresses": [{"zip": "98101", "city": "Seattle", "type": "home", "state": "WA", "street": "123 Main St"}]}	\N	f	English	{"tts": false, "braille": false, "large_print": false}	2024-01-10 01:30:00-08
770e8400-e29b-41d4-a716-446655440002	MRN002	Sarah	Martinez	1992-07-22	Female	{"email": "sarah.martinez@example.com", "phone": "206-555-0102", "addresses": [{"zip": "98402", "city": "Tacoma", "type": "home", "state": "WA", "street": "456 Oak Ave"}]}	\N	f	Spanish	{"tts": false, "braille": false, "large_print": true}	2024-01-11 02:15:00-08
770e8400-e29b-41d4-a716-446655440003	MRN003	Michael	Chen	1978-11-05	Male	{"email": "michael.chen@example.com", "phone": "206-555-0103", "addresses": [{"zip": "98004", "city": "Bellevue", "type": "home", "state": "WA", "street": "789 Pine Rd"}]}	\N	f	Mandarin	{"tts": true, "braille": false, "large_print": false}	2024-01-12 03:00:00-08
770e8400-e29b-41d4-a716-446655440005	MRN005	David	Rodriguez	1995-06-30	Male	{"email": "david.rodriguez@example.com", "phone": "206-555-0105", "addresses": [{"zip": "98033", "city": "Kirkland", "type": "home", "state": "WA", "street": "654 Maple Dr"}]}	\N	f	English	{"tts": true, "braille": true, "large_print": false}	2024-01-14 05:45:00-08
770e8400-e29b-41d4-a716-446655440006	MRN006	Jessica	Williams	1981-09-18	Female	{"email": "jessica.williams@example.com", "phone": "206-555-0106", "addresses": [{"zip": "98055", "city": "Renton", "type": "home", "state": "WA", "street": "987 Cedar Ln"}]}	\N	f	English	{"tts": false, "braille": true, "large_print": true}	2024-01-15 06:30:00-08
770e8400-e29b-41d4-a716-446655440007	MRN007	Robert	Johnson	1975-12-03	Male	{"email": "robert.johnson@example.com", "phone": "206-555-0107", "addresses": [{"zip": "98027", "city": "Issaquah", "type": "home", "state": "WA", "street": "147 Birch Way"}]}	\N	f	English	{"tts": false, "braille": false, "large_print": false}	2024-01-16 01:00:00-08
770e8400-e29b-41d4-a716-446655440008	MRN008	Angela	Kim	1990-04-27	Female	{"email": "angela.kim@example.com", "phone": "206-555-0108", "addresses": [{"zip": "98003", "city": "Federal Way", "type": "home", "state": "WA", "street": "258 Spruce Ave"}]}	\N	t	Korean	{"tts": true, "braille": false, "large_print": false}	2024-01-17 02:30:00-08
770e8400-e29b-41d4-a716-446655440009	MRN009	Christopher	Lee	1987-08-11	Male	{"email": "christopher.lee@example.com", "phone": "206-555-0109", "addresses": [{"zip": "98031", "city": "Kent", "type": "home", "state": "WA", "street": "369 Ash Ct"}]}	\N	f	English	{"tts": false, "braille": false, "large_print": true}	2024-01-18 07:15:00-08
770e8400-e29b-41d4-a716-446655440010	MRN010	Michelle	Brown	1993-05-19	Female	{"email": "michelle.brown@example.com", "phone": "206-555-0110", "addresses": [{"zip": "98002", "city": "Auburn", "type": "home", "state": "WA", "street": "741 Oak St"}]}	\N	f	English	{"tts": false, "braille": false, "large_print": false}	2024-01-19 00:40:00-08
770e8400-e29b-41d4-a716-446655440011	MRN011	Daniel	Garcia	1982-10-02	Male	{"email": "daniel.garcia@example.com", "phone": "206-555-0111", "addresses": [{"zip": "98198", "city": "SeaTac", "type": "home", "state": "WA", "street": "852 Willow Rd"}]}	\N	f	Spanish	{"tts": true, "braille": false, "large_print": false}	2024-01-20 01:30:00-08
770e8400-e29b-41d4-a716-446655440012	MRN012	Lisa	Hernandez	1986-01-25	Female	{"email": "lisa.hernandez@example.com", "phone": "206-555-0112", "addresses": [{"zip": "98133", "city": "Shoreline", "type": "home", "state": "WA", "street": "963 Poplar Ln"}]}	\N	t	Spanish	{"tts": false, "braille": false, "large_print": true}	2024-01-21 04:00:00-08
770e8400-e29b-41d4-a716-446655440013	MRN013	Kevin	Taylor	1979-07-14	Male	{"email": "kevin.taylor@example.com", "phone": "206-555-0113", "addresses": [{"zip": "98011", "city": "Bothell", "type": "home", "state": "WA", "street": "159 Fir Way"}]}	\N	f	English	{"tts": false, "braille": true, "large_print": false}	2024-01-22 00:15:00-08
770e8400-e29b-41d4-a716-446655440014	MRN014	Karen	Anderson	1994-03-08	Female	{"email": "karen.anderson@example.com", "phone": "206-555-0114", "addresses": [{"zip": "98036", "city": "Lynnwood", "type": "home", "state": "WA", "street": "246 Maple Ave"}]}	\N	f	English	{"tts": false, "braille": false, "large_print": false}	2024-01-23 02:45:00-08
770e8400-e29b-41d4-a716-446655440015	MRN015	Mark	White	1980-09-12	Male	{"email": "mark.white@example.com", "phone": "206-555-0115", "addresses": [{"zip": "98020", "city": "Edmonds", "type": "home", "state": "WA", "street": "357 Spruce Dr"}]}	\N	f	English	{"tts": true, "braille": true, "large_print": true}	2024-01-24 05:20:00-08
770e8400-e29b-41d4-a716-446655440016	MRN016	Patricia	Clark	1989-06-20	Female	{"email": "patricia.clark@example.com", "phone": "206-555-0116", "addresses": [{"zip": "98043", "city": "Mountlake Terrace", "type": "home", "state": "WA", "street": "468 Cedar St"}]}	\N	t	English	{"tts": false, "braille": false, "large_print": false}	2024-01-25 06:50:00-08
770e8400-e29b-41d4-a716-446655440017	MRN017	Steven	Lewis	1983-11-30	Male	{"email": "steven.lewis@example.com", "phone": "206-555-0117", "addresses": [{"zip": "98074", "city": "Sammamish", "type": "home", "state": "WA", "street": "579 Birch Ave"}]}	\N	f	English	{"tts": false, "braille": false, "large_print": false}	2024-01-26 03:30:00-08
770e8400-e29b-41d4-a716-446655440018	MRN018	Nancy	Walker	1991-04-05	Female	{"email": "nancy.walker@example.com", "phone": "206-555-0118", "addresses": [{"zip": "98040", "city": "Mercer Island", "type": "home", "state": "WA", "street": "680 Pine Ave"}]}	\N	f	English	{"tts": true, "braille": false, "large_print": true}	2024-01-27 01:00:00-08
770e8400-e29b-41d4-a716-446655440019	MRN019	Joseph	Hall	1976-02-17	Male	{"email": "joseph.hall@example.com", "phone": "206-555-0119", "addresses": [{"zip": "98070", "city": "Vashon", "type": "home", "state": "WA", "street": "791 Ash Ln"}]}	\N	f	English	{"tts": false, "braille": true, "large_print": false}	2024-01-28 07:25:00-08
770e8400-e29b-41d4-a716-446655440020	MRN020	Sandra	Allen	1984-08-23	Female	{"email": "sandra.allen@example.com", "phone": "206-555-0120", "addresses": [{"zip": "98310", "city": "Bremerton", "type": "home", "state": "WA", "street": "802 Elm Dr"}]}	\N	f	English	{"tts": false, "braille": false, "large_print": false}	2024-01-29 02:10:00-08
770e8400-e29b-41d4-a716-446655440004	MRN004	Emily	Thompson	1988-02-14	Female	{"email": "emily.thompson@example.com", "phone": "206-555-0104", "addresses": [{"zip": "98052", "city": "Redmond", "type": "home", "state": "WA", "street": "321 Elm St"}]}	\N	t	English	{"tts": false, "braille": false, "large_print": false}	2024-01-13 00:20:00-08
\.


--
-- Data for Name: payments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payments (id, pos_transaction_id, payment_method, amount, payment_meta) FROM stdin;
36df45d5-7a73-4076-8f49-dfe68eee8cdf	730c18d2-6370-40cc-98e0-87398af69d1f	insurance	56.93	{"note": "Auto-generated payment record", "processor": "square", "timestamp": "2025-11-16T10:46:51.254852-08:00"}
8089f5aa-e8e6-4abd-822c-170b94e8b203	f470e1ad-dc50-48f0-b27d-13e949b2e2e2	other	28.30	{"note": "Auto-generated payment record", "processor": "worldpay", "timestamp": "2025-11-16T10:46:51.254852-08:00"}
605ea67c-b946-425c-8a75-da06944e0353	fffa2821-c078-4071-bc69-9c22539fa9db	other	61.78	{"note": "Auto-generated payment record", "processor": "stripe", "timestamp": "2025-11-16T10:46:51.254852-08:00"}
3f776b36-2e31-4121-b948-7f4e015bc203	6bef1418-8cb1-4589-b82e-23c653f63482	card	74.78	{"note": "Auto-generated payment record", "processor": "worldpay", "timestamp": "2025-11-16T10:46:51.254852-08:00"}
e9dc703e-9422-46a8-8767-5999cd9c791a	b42087ee-c3ec-4cd5-ba7f-90c222dcc204	card	17.44	{"note": "Auto-generated payment record", "processor": "square", "timestamp": "2025-11-16T10:46:51.254852-08:00"}
91cf7b0d-491b-4064-a85f-723f5e7b7ad4	b223c933-0e56-478c-93f9-e74859b2299d	cash	0.95	{"note": "Auto-generated payment record", "processor": "none", "timestamp": "2025-11-16T10:46:51.254852-08:00"}
6c517010-71ac-47f8-aa2f-bbe29c185161	ab2873a4-f731-40be-ab98-920e7146f628	copay assistance	64.77	{"note": "Auto-generated payment record", "processor": "stripe", "timestamp": "2025-11-16T10:46:51.254852-08:00"}
247c3319-65b9-4d9e-b3a9-2f9b5e1afc40	ec004000-ed40-47b3-9a63-eac967ab7f96	copay assistance	41.46	{"note": "Auto-generated payment record", "processor": "worldpay", "timestamp": "2025-11-16T10:46:51.254852-08:00"}
6cb879a1-97cf-4081-8754-e8a70027a42b	9084982c-ab68-46e3-a9c2-b483887f7b7c	card	8.64	{"note": "Auto-generated payment record", "processor": "worldpay", "timestamp": "2025-11-16T10:46:51.254852-08:00"}
6ecb8089-bae2-4972-996b-3bf52960da09	e0a76765-1962-44e6-a9db-01ccfeca4442	other	63.36	{"note": "Auto-generated payment record", "processor": "worldpay", "timestamp": "2025-11-16T10:46:51.254852-08:00"}
827a014b-0e90-4727-a562-38dc6d350cc0	ffe9017c-edbf-474b-b961-0dd8b5199015	insurance	84.71	{"note": "Auto-generated payment record", "processor": "square", "timestamp": "2025-11-16T10:46:51.254852-08:00"}
df853cce-14ab-440a-b102-472e9f86004e	74b2f1c2-7284-4098-9b90-539e091416aa	cash	51.81	{"note": "Auto-generated payment record", "processor": "worldpay", "timestamp": "2025-11-16T10:46:51.254852-08:00"}
09da6031-8312-4a57-bb8e-1d00a71e113e	3b3ebcb7-841c-4d05-bdaf-7478b2328272	card	31.28	{"note": "Auto-generated payment record", "processor": "none", "timestamp": "2025-11-16T10:46:51.254852-08:00"}
da42e9bd-9a91-4b49-8140-421b9860e4b6	a466c97d-da96-4cbb-a042-dcd99b9ecbdd	cash	4.36	{"note": "Auto-generated payment record", "processor": "none", "timestamp": "2025-11-16T10:46:51.254852-08:00"}
132a9f27-95ca-43f1-a0a9-a2ea9ecbce69	7e108bbb-8ec6-4fd6-b12a-9c3874af6fea	copay assistance	81.28	{"note": "Auto-generated payment record", "processor": "stripe", "timestamp": "2025-11-16T10:46:51.254852-08:00"}
b4be344e-16da-43b3-a886-32e0c5851095	2d13795e-bb33-43a1-93fc-8da301368097	other	12.17	{"note": "Auto-generated payment record", "processor": "none", "timestamp": "2025-11-16T10:46:51.254852-08:00"}
d09a2ac1-6791-4690-b80d-6b9f4ca118a6	2b273b1e-0b1f-4aed-9d5e-ca75c27e2b38	card	38.89	{"note": "Auto-generated payment record", "processor": "worldpay", "timestamp": "2025-11-16T10:46:51.254852-08:00"}
683c418e-1ca1-4272-a958-73d7f3842606	ca0471af-ee05-4ea2-ba92-a22072b1686a	other	88.82	{"note": "Auto-generated payment record", "processor": "worldpay", "timestamp": "2025-11-16T10:46:51.254852-08:00"}
a50ae06a-aa42-488f-80fc-4fb0756a826b	35d590f8-b094-4b78-b645-9588a1d8bf0a	cash	13.53	{"note": "Auto-generated payment record", "processor": "stripe", "timestamp": "2025-11-16T10:46:51.254852-08:00"}
a130a06b-ce4f-493b-ae8f-5948b957e65c	aebe36c3-7fc9-493d-be82-600b1f481504	card	68.47	{"note": "Auto-generated payment record", "processor": "stripe", "timestamp": "2025-11-16T10:46:51.254852-08:00"}
\.


--
-- Data for Name: pdmp_queries; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pdmp_queries (id, patient_id, user_id, prescription_id, state, query_reason, status, response_code, response_payload, transmitted_at, completed_at, error_message, created_at) FROM stdin;
\.


--
-- Data for Name: pharmacists; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pharmacists (id, user_id, license_number, license_state, active) FROM stdin;
880e8400-e29b-41d4-a716-446655440001	550e8400-e29b-41d4-a716-446655440001	RPH-WA-2024001	WA	t
880e8400-e29b-41d4-a716-446655440002	550e8400-e29b-41d4-a716-446655440002	RPH-WA-2024002	WA	t
880e8400-e29b-41d4-a716-446655440003	550e8400-e29b-41d4-a716-446655440007	RPH-OR-2024003	OR	t
880e8400-e29b-41d4-a716-446655440004	550e8400-e29b-41d4-a716-446655440013	RPH-WA-2024004	WA	t
880e8400-e29b-41d4-a716-446655440005	550e8400-e29b-41d4-a716-446655440015	RPH-CA-2024005	CA	f
880e8400-e29b-41d4-a716-446655440006	550e8400-e29b-41d4-a716-446655440018	RPH-ID-2024006	ID	t
880e8400-e29b-41d4-a716-446655440007	550e8400-e29b-41d4-a716-446655440020	RPH-WA-2024007	WA	t
\.


--
-- Data for Name: pos_signatures; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pos_signatures (id, pos_transaction_id, station_id, signature_data, signed_by, signed_at) FROM stdin;
\.


--
-- Data for Name: pos_transactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pos_transactions (id, prescription_id, patient_id, station_id, total_amount, status, created_at, metadata) FROM stdin;
2d13795e-bb33-43a1-93fc-8da301368097	dd0e8400-e29b-41d4-a716-446655440005	770e8400-e29b-41d4-a716-446655440008	WINDOW-A	83.76	completed	2025-11-10 10:45:32.735553-08	{"notes": "Auto-generated POS transaction", "operator": "shill", "payment_method": "cash"}
3b3ebcb7-841c-4d05-bdaf-7478b2328272	dd0e8400-e29b-41d4-a716-446655440005	770e8400-e29b-41d4-a716-446655440008	POS-3	108.90	refunded	2025-10-25 10:45:32.735553-07	{"notes": "Auto-generated POS transaction", "operator": "shill", "payment_method": "copay assistance"}
aebe36c3-7fc9-493d-be82-600b1f481504	dd0e8400-e29b-41d4-a716-446655440005	770e8400-e29b-41d4-a716-446655440008	POS-3	112.73	completed	2025-10-18 10:45:32.735553-07	{"notes": "Auto-generated POS transaction", "operator": "shill", "payment_method": "card"}
2b273b1e-0b1f-4aed-9d5e-ca75c27e2b38	dd0e8400-e29b-41d4-a716-446655440005	770e8400-e29b-41d4-a716-446655440008	POS-1	47.29	pending	2025-10-29 10:45:32.735553-07	{"notes": "Auto-generated POS transaction", "operator": "shill", "payment_method": "copay assistance"}
ec004000-ed40-47b3-9a63-eac967ab7f96	dd0e8400-e29b-41d4-a716-446655440005	770e8400-e29b-41d4-a716-446655440008	DRIVE-THRU	49.34	completed	2025-11-10 10:45:32.735553-08	{"notes": "Auto-generated POS transaction", "operator": "shill", "payment_method": "copay assistance"}
a466c97d-da96-4cbb-a042-dcd99b9ecbdd	dd0e8400-e29b-41d4-a716-446655440005	770e8400-e29b-41d4-a716-446655440008	POS-1	41.94	pending	2025-10-28 10:45:32.735553-07	{"notes": "Auto-generated POS transaction", "operator": "shill", "payment_method": "copay assistance"}
ca0471af-ee05-4ea2-ba92-a22072b1686a	dd0e8400-e29b-41d4-a716-446655440005	770e8400-e29b-41d4-a716-446655440008	DRIVE-THRU	115.74	pending	2025-10-29 10:45:32.735553-07	{"notes": "Auto-generated POS transaction", "operator": "shill", "payment_method": "insurance"}
35d590f8-b094-4b78-b645-9588a1d8bf0a	dd0e8400-e29b-41d4-a716-446655440005	770e8400-e29b-41d4-a716-446655440008	POS-1	62.42	completed	2025-10-27 10:45:32.735553-07	{"notes": "Auto-generated POS transaction", "operator": "shill", "payment_method": "cash"}
b42087ee-c3ec-4cd5-ba7f-90c222dcc204	dd0e8400-e29b-41d4-a716-446655440005	770e8400-e29b-41d4-a716-446655440008	POS-2	131.65	completed	2025-10-22 10:45:32.735553-07	{"notes": "Auto-generated POS transaction", "operator": "shill", "payment_method": "cash"}
74b2f1c2-7284-4098-9b90-539e091416aa	dd0e8400-e29b-41d4-a716-446655440005	770e8400-e29b-41d4-a716-446655440008	DRIVE-THRU	118.53	refunded	2025-11-08 10:45:32.735553-08	{"notes": "Auto-generated POS transaction", "operator": "shill", "payment_method": "insurance"}
f470e1ad-dc50-48f0-b27d-13e949b2e2e2	dd0e8400-e29b-41d4-a716-446655440005	770e8400-e29b-41d4-a716-446655440008	DRIVE-THRU	147.65	pending	2025-10-28 10:45:32.735553-07	{"notes": "Auto-generated POS transaction", "operator": "shill", "payment_method": "insurance"}
b223c933-0e56-478c-93f9-e74859b2299d	dd0e8400-e29b-41d4-a716-446655440005	770e8400-e29b-41d4-a716-446655440008	POS-3	26.39	refunded	2025-11-07 10:45:32.735553-08	{"notes": "Auto-generated POS transaction", "operator": "shill", "payment_method": "insurance"}
730c18d2-6370-40cc-98e0-87398af69d1f	dd0e8400-e29b-41d4-a716-446655440005	770e8400-e29b-41d4-a716-446655440008	DRIVE-THRU	76.21	pending	2025-10-18 10:45:32.735553-07	{"notes": "Auto-generated POS transaction", "operator": "shill", "payment_method": "cash"}
e0a76765-1962-44e6-a9db-01ccfeca4442	dd0e8400-e29b-41d4-a716-446655440005	770e8400-e29b-41d4-a716-446655440008	WINDOW-A	61.29	completed	2025-11-02 10:45:32.735553-08	{"notes": "Auto-generated POS transaction", "operator": "shill", "payment_method": "copay assistance"}
fffa2821-c078-4071-bc69-9c22539fa9db	dd0e8400-e29b-41d4-a716-446655440005	770e8400-e29b-41d4-a716-446655440008	WINDOW-A	47.59	refunded	2025-10-17 10:45:32.735553-07	{"notes": "Auto-generated POS transaction", "operator": "shill", "payment_method": "insurance"}
9084982c-ab68-46e3-a9c2-b483887f7b7c	dd0e8400-e29b-41d4-a716-446655440005	770e8400-e29b-41d4-a716-446655440008	POS-3	145.48	completed	2025-11-06 10:45:32.735553-08	{"notes": "Auto-generated POS transaction", "operator": "shill", "payment_method": "card"}
7e108bbb-8ec6-4fd6-b12a-9c3874af6fea	dd0e8400-e29b-41d4-a716-446655440005	770e8400-e29b-41d4-a716-446655440008	POS-2	55.51	pending	2025-11-05 10:45:32.735553-08	{"notes": "Auto-generated POS transaction", "operator": "shill", "payment_method": "copay assistance"}
ffe9017c-edbf-474b-b961-0dd8b5199015	dd0e8400-e29b-41d4-a716-446655440005	770e8400-e29b-41d4-a716-446655440008	POS-3	149.04	refunded	2025-11-13 10:45:32.735553-08	{"notes": "Auto-generated POS transaction", "operator": "shill", "payment_method": "insurance"}
6bef1418-8cb1-4589-b82e-23c653f63482	dd0e8400-e29b-41d4-a716-446655440005	770e8400-e29b-41d4-a716-446655440008	DRIVE-THRU	79.02	pending	2025-11-12 10:45:32.735553-08	{"notes": "Auto-generated POS transaction", "operator": "shill", "payment_method": "cash"}
ab2873a4-f731-40be-ab98-920e7146f628	dd0e8400-e29b-41d4-a716-446655440005	770e8400-e29b-41d4-a716-446655440008	DRIVE-THRU	95.37	completed	2025-11-03 10:45:32.735553-08	{"notes": "Auto-generated POS transaction", "operator": "shill", "payment_method": "insurance"}
\.


--
-- Data for Name: prescription_audit; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.prescription_audit (id, prescription_id, user_id, action, diff, reason, created_at) FROM stdin;
22	dd0e8400-e29b-41d4-a716-446655440001	550e8400-e29b-41d4-a716-446655440010	created	{"quantity": 30, "medication": "Metformin 500mg", "prescriber": "Dr. James Smith"}	Prescription received from provider	2025-11-10 01:23:13.547743-08
23	dd0e8400-e29b-41d4-a716-446655440001	550e8400-e29b-41d4-a716-446655440010	status_change	{"new_status": "reviewed", "old_status": "pending"}	Pharmacist review completed	2025-11-10 05:23:13.547743-08
24	dd0e8400-e29b-41d4-a716-446655440001	550e8400-e29b-41d4-a716-446655440011	status_change	{"new_status": "filled", "old_status": "reviewed"}	Prescription dispensed to patient	2025-11-11 01:23:13.547743-08
25	dd0e8400-e29b-41d4-a716-446655440002	550e8400-e29b-41d4-a716-446655440010	created	{"quantity": 90, "medication": "Lisinopril 10mg", "prescriber": "Dr. Sarah Johnson"}	eRx received via Surescripts	2025-11-09 01:23:13.547743-08
26	dd0e8400-e29b-41d4-a716-446655440002	550e8400-e29b-41d4-a716-446655440012	updated	{"field": "insurance_verified", "new_value": true, "old_value": false}	Insurance coverage verified with payer	2025-11-09 05:23:13.547743-08
27	dd0e8400-e29b-41d4-a716-446655440002	550e8400-e29b-41d4-a716-446655440010	status_change	{"new_status": "filled", "old_status": "pending"}	Prior authorization received and approved	2025-11-11 01:23:13.547743-08
28	dd0e8400-e29b-41d4-a716-446655440003	550e8400-e29b-41d4-a716-446655440010	created	{"quantity": 14, "medication": "Atorvastatin 20mg", "prescriber": "Dr. Michael Chen"}	Emergency refill request submitted	2025-11-11 01:23:13.547743-08
29	dd0e8400-e29b-41d4-a716-446655440003	550e8400-e29b-41d4-a716-446655440012	override	{"field": "priority", "new_value": "urgent", "old_value": "normal"}	Patient reported critical medication shortage	2025-11-11 01:23:13.547743-08
30	dd0e8400-e29b-41d4-a716-446655440004	550e8400-e29b-41d4-a716-446655440010	created	{"quantity": 60, "medication": "Omeprazole 20mg", "prescriber": "Dr. Emily Rodriguez"}	Regular maintenance prescription entered	2025-11-07 01:23:13.547743-08
31	dd0e8400-e29b-41d4-a716-446655440004	550e8400-e29b-41d4-a716-446655440011	status_change	{"new_status": "filled", "old_status": "pending"}	Prescription filled and ready for pickup	2025-11-08 01:23:13.547743-08
32	dd0e8400-e29b-41d4-a716-446655440005	550e8400-e29b-41d4-a716-446655440010	created	{"quantity": 30, "medication": "Sertraline 50mg", "prescriber": "Dr. Robert Williams"}	New psychiatric medication prescription	2025-11-08 01:23:13.547743-08
33	dd0e8400-e29b-41d4-a716-446655440005	550e8400-e29b-41d4-a716-446655440012	override	{"field": "counseling_required", "new_value": true, "old_value": false}	Pharmacist mandated counseling due to drug interactions	2025-11-08 05:23:13.547743-08
34	dd0e8400-e29b-41d4-a716-446655440006	550e8400-e29b-41d4-a716-446655440010	created	{"quantity": 30, "medication": "Amlodipine 5mg", "prescriber": "Dr. Lisa Anderson"}	Prescription received from provider	2025-11-10 01:23:13.547743-08
35	dd0e8400-e29b-41d4-a716-446655440006	550e8400-e29b-41d4-a716-446655440011	updated	{"field": "insurance_status", "new_value": "awaiting_response", "old_value": "pending"}	Insurance verification query submitted	2025-11-11 01:23:13.547743-08
36	dd0e8400-e29b-41d4-a716-446655440007	550e8400-e29b-41d4-a716-446655440010	created	{"quantity": 100, "medication": "Vitamin D3 1000IU", "prescriber": "Dr. David Martinez"}	OTC supplement request entered	2025-11-06 01:23:13.547743-08
37	dd0e8400-e29b-41d4-a716-446655440008	550e8400-e29b-41d4-a716-446655440010	created	{"quantity": 28, "medication": "Metoprolol 25mg", "prescriber": "Dr. Jennifer Brown"}	Medicaid prescription received	2025-11-11 01:23:13.547743-08
38	dd0e8400-e29b-41d4-a716-446655440008	550e8400-e29b-41d4-a716-446655440012	status_change	{"new_status": "filled", "old_status": "reviewed"}	Prescription dispensed - Medicaid coverage verified	2025-11-11 01:23:13.547743-08
39	dd0e8400-e29b-41d4-a716-446655440009	550e8400-e29b-41d4-a716-446655440010	created	{"quantity": 30, "medication": "Ibuprofen 200mg", "prescriber": "Dr. Thomas Lee"}	Prescription entered into system	2025-11-09 01:23:13.547743-08
40	dd0e8400-e29b-41d4-a716-446655440009	550e8400-e29b-41d4-a716-446655440011	status_change	{"new_status": "voided", "old_status": "pending"}	Patient requested cancellation - duplicate prescription already filled	2025-11-10 01:23:13.547743-08
41	dd0e8400-e29b-41d4-a716-446655440010	550e8400-e29b-41d4-a716-446655440010	created	{"quantity": 30, "medication": "Hydrocodone 5mg/500mg", "prescriber": "Dr. Patricia Garcia"}	Controlled substance prescription received	2025-11-08 01:23:13.547743-08
42	dd0e8400-e29b-41d4-a716-446655440010	550e8400-e29b-41d4-a716-446655440012	override	{"field": "id_verification_required", "new_value": true, "old_value": true}	DEA controlled substance audit verification required	2025-11-08 05:23:13.547743-08
43	dd0e8400-e29b-41d4-a716-446655440010	550e8400-e29b-41d4-a716-446655440011	status_change	{"new_status": "filled", "old_status": "reviewed"}	Patient identity verified - controlled substance dispensed	2025-11-09 01:23:13.547743-08
\.


--
-- Data for Name: prescription_claims; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.prescription_claims (id, prescription_id, patient_insurance_id, claim_number, claim_status, claim_date, billed_amount, reimbursed_amount, patient_responsibility, rejection_code, rejection_reason, prior_authorization_number, adjudication_data, created_at, updated_at) FROM stdin;
eeea7da0-6ea8-4da6-b50e-3c26cc2609ee	dd0e8400-e29b-41d4-a716-446655440001	e2675756-7539-4877-bc4f-d403f7190cc8	CLM001001	APPROVED	2025-11-07 01:39:43.13215-08	125.50	100.40	25.10	\N	\N	PA001001	{"payer_id": "BCBS001", "response_code": "00", "allowed_amount": 100.40, "processing_date": "2024-11-06"}	2025-11-07 01:39:43.13215-08	2025-11-10 01:39:43.13215-08
743b60f6-a94f-445d-8d10-d176047a86a3	dd0e8400-e29b-41d4-a716-446655440002	cc9868db-cfe2-4b6b-8c16-ef50688a64f4	CLM002001	APPROVED	2025-11-05 01:39:43.13215-08	250.75	200.60	50.15	\N	\N	PA002001	{"payer_id": "UH002", "response_code": "00", "allowed_amount": 200.60, "processing_date": "2024-11-04"}	2025-11-05 01:39:43.13215-08	2025-11-08 01:39:43.13215-08
ed7293c3-86a7-40a1-bc4d-5744eaedd3ac	dd0e8400-e29b-41d4-a716-446655440003	f65bf5f3-bf3e-47eb-b25c-91d8a49560ff	CLM003001	REJECTED	2025-11-02 01:39:43.13215-08	180.00	0.00	180.00	NOTCOVERED	Drug not covered under plan formulary	\N	{"payer_id": "AETNA003", "response_code": "16", "processing_date": "2024-11-01", "rejection_reason": "Not on formulary"}	2025-11-02 01:39:43.13215-08	2025-11-05 01:39:43.13215-08
55763187-fa34-4d80-9b27-eb5cde3131e7	dd0e8400-e29b-41d4-a716-446655440004	2b9ee988-66ca-4717-8796-551595618004	CLM004001	PENDING	2025-11-11 01:39:43.13215-08	95.25	\N	\N	\N	\N	PA004001	{"payer_id": "CIGNA004", "response_code": null, "processing_date": null, "submission_status": "pending"}	2025-11-11 01:39:43.13215-08	2025-11-11 01:39:43.13215-08
b829e40e-dd8e-46bc-8a00-bb4fd94e4986	dd0e8400-e29b-41d4-a716-446655440005	c44c8467-e85c-40a9-993e-1627c8c2415a	CLM005001	SUBMITTED	2025-11-12 01:39:43.13215-08	340.00	\N	\N	\N	\N	PA005001	{"payer_id": "HUMANA005", "response_code": null, "processing_date": null, "submission_status": "submitted"}	2025-11-12 01:39:43.13215-08	2025-11-12 01:39:43.13215-08
c7436744-8694-4ce6-863a-deb4c77fbdb3	dd0e8400-e29b-41d4-a716-446655440006	248ce4d3-18ba-4bdd-a33f-cb400fd34ed9	CLM006001	APPROVED	2025-11-09 01:39:43.13215-08	155.50	124.40	31.10	\N	\N	PA006001	{"payer_id": "KP006", "response_code": "00", "allowed_amount": 124.40, "processing_date": "2024-11-08"}	2025-11-09 01:39:43.13215-08	2025-11-11 01:39:43.13215-08
a17124ab-f532-4595-add7-5c0733857ba8	dd0e8400-e29b-41d4-a716-446655440007	26cbf954-8ca7-4d87-8de2-82e6963ea45e	CLM007001	APPROVED	2025-11-06 01:39:43.13215-08	87.99	70.39	17.60	\N	\N	PA007001	{"payer_id": "MCRE007", "medicare_part": "D", "response_code": "00", "allowed_amount": 70.39, "processing_date": "2024-11-05"}	2025-11-06 01:39:43.13215-08	2025-11-09 01:39:43.13215-08
ed1f3d0b-97e2-4fb9-b517-6f6bf29a349c	dd0e8400-e29b-41d4-a716-446655440008	7ae0ab81-e263-47ad-a1c4-27fb65869a7a	CLM008001	APPROVED	2025-11-08 01:39:43.13215-08	210.00	210.00	0.00	\N	\N	\N	{"program": "Medicaid", "payer_id": "MCD008", "response_code": "00", "allowed_amount": 210.00, "processing_date": "2024-11-07"}	2025-11-08 01:39:43.13215-08	2025-11-10 01:39:43.13215-08
bcc9e5a8-b924-4f3b-b692-28af8088bb71	dd0e8400-e29b-41d4-a716-446655440009	5d6fc211-b1bf-4a0b-9f57-45af3aa8654a	CLM009001	REJECTED	2025-11-04 01:39:43.13215-08	320.50	0.00	320.50	DUPETHERAPY	Duplicate therapy with existing prescription	\N	{"payer_id": "HUHP009", "response_code": "75", "processing_date": "2024-11-03", "rejection_reason": "Duplicate therapy conflict"}	2025-11-04 01:39:43.13215-08	2025-11-07 01:39:43.13215-08
75468ae6-31ef-41dd-a07d-94454d305039	dd0e8400-e29b-41d4-a716-446655440010	f363f253-a7b9-4479-a38e-731b1409bae2	CLM010001	APPROVED	2025-11-10 01:39:43.13215-08	145.75	116.60	29.15	\N	\N	PA010001	{"payer_id": "SUHP010", "response_code": "00", "allowed_amount": 116.60, "processing_date": "2024-11-09"}	2025-11-10 01:39:43.13215-08	2025-11-11 01:39:43.13215-08
c09beb4d-a8eb-4064-a7bc-b61b12cafabe	dd0e8400-e29b-41d4-a716-446655440011	9d386647-4319-48e9-8c44-95813e7d7833	CLM011001	APPROVED	2025-11-07 01:39:43.13215-08	265.30	212.24	53.06	\N	\N	PA011001	{"payer_id": "ABC011", "response_code": "00", "allowed_amount": 212.24, "processing_date": "2024-11-06"}	2025-11-07 01:39:43.13215-08	2025-11-09 01:39:43.13215-08
02b8a764-4b80-46cd-8940-24161810451d	dd0e8400-e29b-41d4-a716-446655440012	363fef83-7ebd-4eb4-b9e2-c3f1d0c6ec03	CLM012001	REVERSED	2025-10-31 01:39:43.13215-07	175.00	0.00	175.00	\N	Claim reversed - patient coverage terminated	\N	{"payer_id": "MHCP012", "response_code": "99", "reversal_date": "2024-11-02", "processing_date": "2024-10-30", "reversal_reason": "Coverage terminated"}	2025-10-31 01:39:43.13215-07	2025-11-03 01:39:43.13215-08
83b5d198-3d21-4f6e-9cd7-d47c80136fdd	dd0e8400-e29b-41d4-a716-446655440013	41eb2ee8-0090-4146-a745-7c08aab5628b	CLM013001	PENDING	2025-11-10 01:39:43.13215-08	295.50	\N	\N	\N	\N	PA013001	{"payer_id": "WCP013", "response_code": null, "processing_date": null, "submission_status": "pending"}	2025-11-10 01:39:43.13215-08	2025-11-10 01:39:43.13215-08
207d37a9-0f4e-4696-b1c6-d357e854e6b2	dd0e8400-e29b-41d4-a716-446655440014	de06541f-9397-4039-a308-57cad1fe00c9	CLM014001	APPROVED	2025-11-06 01:39:43.13215-08	185.00	148.00	37.00	\N	\N	PA014001	{"payer_id": "CVS014", "response_code": "00", "allowed_amount": 148.00, "processing_date": "2024-11-05"}	2025-11-06 01:39:43.13215-08	2025-11-08 01:39:43.13215-08
970b5be5-b3a6-47f6-8ee9-ac7a9e96a47b	dd0e8400-e29b-41d4-a716-446655440015	23ebd428-6436-4478-8edf-b6cea458f460	CLM015001	APPROVED	2025-11-09 01:39:43.13215-08	220.75	220.75	0.00	\N	\N	\N	{"program": "Medicaid", "payer_id": "CENT015", "response_code": "00", "allowed_amount": 220.75, "processing_date": "2024-11-08"}	2025-11-09 01:39:43.13215-08	2025-11-11 01:39:43.13215-08
82a52b6e-a2ea-4bab-a7a1-d1a4abc35393	dd0e8400-e29b-41d4-a716-446655440016	8da02216-28ff-4be7-ae6b-1b31aca4d59c	CLM016001	APPROVED	2025-11-08 01:39:43.13215-08	310.25	248.20	62.05	\N	\N	PA016001	{"payer_id": "OSCAR016", "response_code": "00", "allowed_amount": 248.20, "processing_date": "2024-11-07"}	2025-11-08 01:39:43.13215-08	2025-11-10 01:39:43.13215-08
2f29eb44-6b7b-40f9-8be1-22a251c86ef7	dd0e8400-e29b-41d4-a716-446655440017	03888f9c-2d03-4565-bf1a-111827bcde69	CLM017001	SUBMITTED	2025-11-11 01:39:43.13215-08	135.50	\N	\N	\N	\N	PA017001	{"payer_id": "BHG017", "response_code": null, "processing_date": null, "submission_status": "submitted"}	2025-11-11 01:39:43.13215-08	2025-11-11 01:39:43.13215-08
0ab4a484-f639-4ad8-b927-e72151cb1c94	dd0e8400-e29b-41d4-a716-446655440018	525cc520-86fe-4891-993d-46678cc202e4	CLM018001	APPROVED	2025-11-07 01:39:43.13215-08	275.00	220.00	55.00	\N	\N	PA018001	{"payer_id": "ELEV018", "response_code": "00", "allowed_amount": 220.00, "processing_date": "2024-11-06"}	2025-11-07 01:39:43.13215-08	2025-11-09 01:39:43.13215-08
4c12ae56-850c-4f77-8f33-b1b690ad2092	dd0e8400-e29b-41d4-a716-446655440019	c090d552-982c-43df-abc2-9b1cdb0d46b4	CLM019001	APPROVED	2025-11-05 01:39:43.13215-08	165.50	132.40	33.10	\N	\N	PA019001	{"payer_id": "UCLAHI019", "response_code": "00", "allowed_amount": 132.40, "processing_date": "2024-11-04"}	2025-11-05 01:39:43.13215-08	2025-11-07 01:39:43.13215-08
491a1a1e-17c5-4244-8df1-df0973f60c19	dd0e8400-e29b-41d4-a716-446655440020	6a39a161-0eed-4d0a-a483-bdc7961cbcab	CLM020001	PENDING	2025-11-12 01:39:43.13215-08	245.75	\N	\N	\N	\N	PA020001	{"payer_id": "JHHP020", "response_code": null, "processing_date": null, "submission_status": "pending"}	2025-11-12 01:39:43.13215-08	2025-11-12 01:39:43.13215-08
\.


--
-- Data for Name: prescription_copays; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.prescription_copays (id, prescription_id, patient_id, insurance_company_id, claim_id, copay_amount, copay_status, payment_method, payment_reference, paid_at, created_at) FROM stdin;
cdde1274-f996-4f81-9645-d567cd966042	dd0e8400-e29b-41d4-a716-446655440001	770e8400-e29b-41d4-a716-446655440001	dc0f2790-c152-4948-93f1-04fe12c9e8ae	eeea7da0-6ea8-4da6-b50e-3c26cc2609ee	25.10	paid	card	CARD-0001-1001	2025-11-08 01:42:52.681778-08	2025-11-07 01:42:52.681778-08
a3be65e5-d92a-4095-a9d3-a531e78692de	dd0e8400-e29b-41d4-a716-446655440002	770e8400-e29b-41d4-a716-446655440002	5b0b325d-20bf-40f4-ae1d-cd03336e87a1	743b60f6-a94f-445d-8d10-d176047a86a3	50.15	paid	cash	CASH-0002-1001	2025-11-06 01:42:52.681778-08	2025-11-05 01:42:52.681778-08
70293f2a-17ad-427f-a281-093b08f050db	dd0e8400-e29b-41d4-a716-446655440003	770e8400-e29b-41d4-a716-446655440003	c3040c83-a8b0-4a8b-9ec7-cc7f71587bca	ed7293c3-86a7-40a1-bc4d-5744eaedd3ac	180.00	unpaid	\N	\N	\N	2025-11-02 01:42:52.681778-08
d2ba316b-831c-4e91-96c5-bb6563812aee	dd0e8400-e29b-41d4-a716-446655440004	770e8400-e29b-41d4-a716-446655440004	766ccc66-460a-4c63-8396-0f55713d9c19	55763187-fa34-4d80-9b27-eb5cde3131e7	35.00	waived	copay assistance	COPAY-ASSIST-0004	2025-11-11 01:42:52.681778-08	2025-11-11 01:42:52.681778-08
84d302c3-dd19-457d-8622-d2566208a739	dd0e8400-e29b-41d4-a716-446655440005	770e8400-e29b-41d4-a716-446655440005	a5c95636-5ddc-49c1-bc45-4d96529ea61f	b829e40e-dd8e-46bc-8a00-bb4fd94e4986	15.00	billed	insurance	INS-0005-1001	\N	2025-11-12 01:42:52.681778-08
418d2978-c3bd-484d-be7e-858b747f4c54	dd0e8400-e29b-41d4-a716-446655440006	770e8400-e29b-41d4-a716-446655440006	ec92e4e6-8d5f-4fe2-82d6-cd78ad3fa842	c7436744-8694-4ce6-863a-deb4c77fbdb3	31.10	paid	card	CARD-0006-1001	2025-11-10 01:42:52.681778-08	2025-11-09 01:42:52.681778-08
698b716a-ba99-4f00-abc7-9224d71ba238	dd0e8400-e29b-41d4-a716-446655440007	770e8400-e29b-41d4-a716-446655440007	28c88ff4-68c8-40f1-80bb-63cf18f9fb6d	a17124ab-f532-4595-add7-5c0733857ba8	17.60	paid	cash	CASH-0007-1001	2025-11-07 01:42:52.681778-08	2025-11-06 01:42:52.681778-08
0a416b1b-e102-4249-9e96-2e30b70afef3	dd0e8400-e29b-41d4-a716-446655440008	770e8400-e29b-41d4-a716-446655440008	620e99ae-4d87-4f34-9e3a-671eb3f0a6e5	ed1f3d0b-97e2-4fb9-b517-6f6bf29a349c	0.00	waived	insurance	MEDICAID-WAIVED	2025-11-08 01:42:52.681778-08	2025-11-08 01:42:52.681778-08
66493489-b705-4023-bb1f-dc03a1394366	dd0e8400-e29b-41d4-a716-446655440009	770e8400-e29b-41d4-a716-446655440009	81f8d6fd-746a-42d9-8fe2-fc4b837d3802	bcc9e5a8-b924-4f3b-b692-28af8088bb71	320.50	unpaid	\N	\N	\N	2025-11-04 01:42:52.681778-08
f44fc553-9613-4dd0-bf70-7d4c270523af	dd0e8400-e29b-41d4-a716-446655440010	770e8400-e29b-41d4-a716-446655440010	edb67b7c-6634-4e4c-aa4b-d76d7bc57d81	75468ae6-31ef-41dd-a07d-94454d305039	29.15	paid	card	CARD-0010-1001	2025-11-11 01:42:52.681778-08	2025-11-10 01:42:52.681778-08
21f94774-ae0e-4ef0-ae1c-8c5b8b3e2234	dd0e8400-e29b-41d4-a716-446655440011	770e8400-e29b-41d4-a716-446655440011	a30e07fb-a9d2-4aa6-ae2c-77b46c6dfda0	c09beb4d-a8eb-4064-a7bc-b61b12cafabe	53.06	paid	cash	CASH-0011-1001	2025-11-08 01:42:52.681778-08	2025-11-07 01:42:52.681778-08
2fbf46b8-35c5-4153-a59d-49e6cf6e162b	dd0e8400-e29b-41d4-a716-446655440012	770e8400-e29b-41d4-a716-446655440012	d8197f0b-12fc-4806-94bf-faac78c8b440	02b8a764-4b80-46cd-8940-24161810451d	175.00	unpaid	\N	\N	\N	2025-10-31 01:42:52.681778-07
52b07f97-9de0-4215-8d65-56c78b781980	dd0e8400-e29b-41d4-a716-446655440013	770e8400-e29b-41d4-a716-446655440013	62539581-71cd-4564-83b0-de35b1ce4e81	83b5d198-3d21-4f6e-9cd7-d47c80136fdd	20.00	billed	insurance	INS-0013-1001	\N	2025-11-10 01:42:52.681778-08
3a5e7a5c-09a8-4dc3-9887-64a1da099f00	dd0e8400-e29b-41d4-a716-446655440014	770e8400-e29b-41d4-a716-446655440014	f7a29654-15ce-4b6e-8710-921d03970d50	207d37a9-0f4e-4696-b1c6-d357e854e6b2	37.00	paid	card	CARD-0014-1001	2025-11-07 01:42:52.681778-08	2025-11-06 01:42:52.681778-08
577bfc1d-82cc-42db-a2c7-871a39df2abc	dd0e8400-e29b-41d4-a716-446655440015	770e8400-e29b-41d4-a716-446655440015	e70460ff-e525-4846-bbfa-525d9d8ee9bd	970b5be5-b3a6-47f6-8ee9-ac7a9e96a47b	0.00	waived	insurance	MEDICAID-WAIVED	2025-11-09 01:42:52.681778-08	2025-11-09 01:42:52.681778-08
49bb311b-b693-4b95-b1c9-5f1a7cbe65b4	dd0e8400-e29b-41d4-a716-446655440016	770e8400-e29b-41d4-a716-446655440016	778e34d0-9da2-4101-ba5d-194adbb9b377	82a52b6e-a2ea-4bab-a7a1-d1a4abc35393	62.05	paid	card	CARD-0016-1001	2025-11-09 01:42:52.681778-08	2025-11-08 01:42:52.681778-08
3f99d96d-01b9-46b4-ac3e-813c5a1bd8c8	dd0e8400-e29b-41d4-a716-446655440017	770e8400-e29b-41d4-a716-446655440017	ee46f287-e07e-4026-b80f-c8345ae461e3	2f29eb44-6b7b-40f9-8be1-22a251c86ef7	25.00	unpaid	\N	\N	\N	2025-11-11 01:42:52.681778-08
6401aeef-4a5b-41fc-83a0-9d79bcf9c4d2	dd0e8400-e29b-41d4-a716-446655440018	770e8400-e29b-41d4-a716-446655440018	e1d0952d-2d73-426b-831c-20bd48d42f08	0ab4a484-f639-4ad8-b927-e72151cb1c94	55.00	paid	cash	CASH-0018-1001	2025-11-08 01:42:52.681778-08	2025-11-07 01:42:52.681778-08
6f7054c9-3438-4345-927d-b172bba610fd	dd0e8400-e29b-41d4-a716-446655440019	770e8400-e29b-41d4-a716-446655440019	82de06a9-2d36-4ef2-9ad7-79e0d9724f16	4c12ae56-850c-4f77-8f33-b1b690ad2092	33.10	paid	card	CARD-0019-1001	2025-11-06 01:42:52.681778-08	2025-11-05 01:42:52.681778-08
83f8c009-f43c-475b-8f9f-d554f60bd243	dd0e8400-e29b-41d4-a716-446655440020	770e8400-e29b-41d4-a716-446655440020	4c79257a-3075-4870-bc23-a11f1ef7f921	491a1a1e-17c5-4244-8df1-df0973f60c19	45.75	billed	insurance	INS-0020-1001	\N	2025-11-12 01:42:52.681778-08
\.


--
-- Data for Name: prescription_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.prescription_items (id, prescription_id, inventory_item_id, quantity, days_supply, sig, refills_allowed, is_controlled, label_options, status, created_at) FROM stdin;
4226fac1-7018-4bb6-b250-7a0fd7f59c39	dd0e8400-e29b-41d4-a716-446655440001	990e8400-e29b-41d4-a716-446655440001	30	30	Take one tablet by mouth twice daily with food	3	f	{"audio": false, "braille": false, "large_print": true}	active	2025-11-10 01:18:10.479738-08
b125d4ee-5c1e-4fc3-98d4-9ee80aeb5e5a	dd0e8400-e29b-41d4-a716-446655440002	990e8400-e29b-41d4-a716-446655440002	90	30	Take one tablet by mouth once daily in the morning	11	f	{"audio": false, "braille": false, "large_print": false}	active	2025-11-09 01:18:10.479738-08
95302fd3-92c1-47cf-a0fd-da4c9edac07f	dd0e8400-e29b-41d4-a716-446655440003	990e8400-e29b-41d4-a716-446655440003	14	14	Take one tablet by mouth three times daily as needed for pain	0	f	{"audio": true, "braille": false, "large_print": true}	active	2025-11-11 01:18:10.479738-08
4ae8088d-cb73-4490-9170-360d7932e7ba	dd0e8400-e29b-41d4-a716-446655440004	990e8400-e29b-41d4-a716-446655440004	60	30	Take one capsule by mouth once daily before bedtime	5	f	{"audio": false, "braille": false, "large_print": false}	active	2025-11-07 01:18:10.479738-08
15abb297-4452-401e-b08f-3f4b288a2083	dd0e8400-e29b-41d4-a716-446655440005	990e8400-e29b-41d4-a716-446655440005	30	30	Take one tablet by mouth once daily in the morning	2	f	{"audio": false, "braille": true, "large_print": false}	active	2025-11-08 01:18:10.479738-08
4936fd73-3aab-44c5-88cb-ac21cdbe2a85	dd0e8400-e29b-41d4-a716-446655440006	990e8400-e29b-41d4-a716-446655440006	30	30	Take one tablet by mouth once daily	0	f	{"audio": false, "braille": false, "large_print": false}	active	2025-11-10 01:18:10.479738-08
dcf5c80a-9e37-4b32-8615-9064d1437220	dd0e8400-e29b-41d4-a716-446655440007	990e8400-e29b-41d4-a716-446655440007	100	30	Take one capsule by mouth once daily with meals	11	f	{"audio": false, "braille": false, "large_print": false}	active	2025-11-06 01:18:10.479738-08
d39cfc10-2df8-42fa-9c89-175e7543767f	dd0e8400-e29b-41d4-a716-446655440008	990e8400-e29b-41d4-a716-446655440008	28	28	Take one tablet by mouth once daily in the morning	3	f	{"audio": false, "braille": false, "large_print": false}	active	2025-11-11 01:18:10.479738-08
7c29838d-149c-40dd-8e12-9269d46b0dff	dd0e8400-e29b-41d4-a716-446655440009	990e8400-e29b-41d4-a716-446655440009	0	0	Do not use - prescription voided	0	f	{"audio": false, "braille": false, "large_print": false}	cancelled	2025-11-09 01:18:10.479738-08
7809f622-d3a1-41b8-bab0-0b931387e264	dd0e8400-e29b-41d4-a716-446655440010	990e8400-e29b-41d4-a716-446655440010	30	15	Take one tablet by mouth every four to six hours as needed for pain	0	t	{"audio": false, "braille": false, "large_print": true}	active	2025-11-08 01:18:10.479738-08
20424ae0-0b2f-4c93-8785-fd35295df686	dd0e8400-e29b-41d4-a716-446655440011	990e8400-e29b-41d4-a716-446655440011	30	30	Take tablet as directed - pharmacist will counsel	0	t	{"audio": false, "braille": false, "large_print": false}	active	2025-11-10 01:18:10.479738-08
79534eed-fbaf-4153-a05b-e8536029e328	dd0e8400-e29b-41d4-a716-446655440012	990e8400-e29b-41d4-a716-446655440012	90	90	Take one tablet by mouth once daily	11	f	{"audio": false, "braille": false, "large_print": false}	active	2025-11-07 01:18:10.479738-08
0ccddae4-17bb-4c33-9ba6-f85ac5e9efbf	dd0e8400-e29b-41d4-a716-446655440013	990e8400-e29b-41d4-a716-446655440013	0	0	Transferred to another pharmacy	0	f	{"audio": false, "braille": false, "large_print": false}	cancelled	2025-11-11 01:18:10.479738-08
c2429509-6f81-4421-bde6-35e1905938ce	dd0e8400-e29b-41d4-a716-446655440014	990e8400-e29b-41d4-a716-446655440014	300	90	Inhale one to two puffs into the lungs every four to six hours as needed	3	f	{"audio": false, "braille": false, "large_print": false}	active	2025-11-09 01:18:10.479738-08
62d236a6-ceb1-48d9-b449-b836202fd183	dd0e8400-e29b-41d4-a716-446655440015	990e8400-e29b-41d4-a716-446655440015	0	0	Awaiting prior authorization	0	f	{"audio": false, "braille": false, "large_print": false}	active	2025-11-10 01:18:10.479738-08
5bd42955-1655-4656-a139-8d1f55c20520	dd0e8400-e29b-41d4-a716-446655440016	990e8400-e29b-41d4-a716-446655440016	45	45	Take one tablet by mouth once daily	1	f	{"audio": false, "braille": false, "large_print": false}	active	2025-11-08 01:18:10.479738-08
cf3a3370-9d93-416b-b6ff-7f8e925fb36c	dd0e8400-e29b-41d4-a716-446655440017	990e8400-e29b-41d4-a716-446655440017	60	30	Take one tablet by mouth twice daily with meals	11	f	{"audio": false, "braille": false, "large_print": false}	active	2025-11-06 01:18:10.479738-08
abd56c44-a868-4a87-a372-21a50cb67107	dd0e8400-e29b-41d4-a716-446655440018	990e8400-e29b-41d4-a716-446655440018	30	30	Take tablet as directed - requires pharmacist consultation	0	f	{"audio": false, "braille": false, "large_print": false}	active	2025-11-11 01:18:10.479738-08
388c16dd-7fc7-4a92-80c8-d0ff9907d312	dd0e8400-e29b-41d4-a716-446655440019	990e8400-e29b-41d4-a716-446655440019	14	14	Take tablet by mouth every four hours as needed for severe pain	0	t	{"audio": false, "braille": false, "large_print": false}	active	2025-11-09 01:18:10.479738-08
6bd94f61-9ecf-4da7-bc7a-857cd45a2643	dd0e8400-e29b-41d4-a716-446655440020	990e8400-e29b-41d4-a716-446655440020	60	60	Take one tablet by mouth once daily as needed for allergy symptoms	5	f	{"audio": false, "braille": false, "large_print": false}	active	2025-11-10 01:18:10.479738-08
\.


--
-- Data for Name: prescription_transfers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.prescription_transfers (id, prescription_id, transfer_type, provider, external_id, payload, transmitted_at, status, signed) FROM stdin;
28e77473-f533-491a-8409-99e3350e860b	dd0e8400-e29b-41d4-a716-446655440001	send	Surescripts	EXT001001	{"quantity": 30, "medication": "Metformin 500mg", "message_type": "NewRx", "patient_name": "John Doe"}	2025-11-10 01:21:05.187477-08	transmitted	t
84046542-df7f-48f7-84c8-d45f9765acad	dd0e8400-e29b-41d4-a716-446655440002	receive	CoverMyMeds	EXT002001	{"insurance_id": "INS123456", "message_type": "PARequest", "prior_auth_required": true}	2025-11-09 01:21:05.187477-08	received	f
d7422acf-9d23-4cc3-b126-9398ed4ed758	dd0e8400-e29b-41d4-a716-446655440003	send	Surescripts	EXT003001	{"medication": "Atorvastatin 20mg", "patient_id": "PAT003", "message_type": "Refill"}	2025-11-11 01:21:05.187477-08	transmitted	t
09f3507e-581e-4968-9849-9df1aefc3f32	dd0e8400-e29b-41d4-a716-446655440004	receive	Surescripts	EXT004001	{"fill_number": 1, "status_code": "01", "message_type": "RxFill"}	2025-11-07 01:21:05.187477-08	received	t
4f64904f-8be9-404a-96a4-144f37026e0b	dd0e8400-e29b-41d4-a716-446655440005	send	CoverMyMeds	EXT005001	{"drug_name": "Sertraline", "message_type": "PARequest", "diagnosis_code": "F32.0"}	2025-11-08 01:21:05.187477-08	transmitted	f
2fb92b3e-9bd2-46fc-9c6d-121d92ca95bb	dd0e8400-e29b-41d4-a716-446655440006	receive	CoverMyMeds	EXT006001	{"message_type": "PADenial", "denial_reason": "Not covered under formulary"}	2025-11-10 01:21:05.187477-08	received	t
9b407119-a841-4c7b-9cb5-e52328363864	dd0e8400-e29b-41d4-a716-446655440007	send	Surescripts	EXT007001	{"message_type": "Transfer", "destination_pharmacy": "Walgreens456", "originating_pharmacy": "CVS123"}	2025-11-06 01:21:05.187477-08	transmitted	t
5d58d66b-9451-477d-9c8e-7cc51758e13a	dd0e8400-e29b-41d4-a716-446655440008	receive	Surescripts	EXT008001	{"patient_id": "PAT008", "message_type": "NewRx", "from_provider": "Dr. Brown"}	2025-11-11 01:21:05.187477-08	received	f
36ba6326-9d47-4963-b904-421d9929c981	dd0e8400-e29b-41d4-a716-446655440009	send	CoverMyMeds	EXT009001	{"reason": "Patient request", "original_rx": "RX123456789", "message_type": "Void"}	2025-11-09 01:21:05.187477-08	failed	f
9a99a1b5-1c64-4ad6-9860-052d27c36368	dd0e8400-e29b-41d4-a716-446655440010	receive	Surescripts	EXT010001	{"dea_number": "AS1234567", "cii_required": true, "message_type": "ControlledSubstance"}	2025-11-08 01:21:05.187477-08	received	t
6ea1b3ce-fd6a-41c2-b0e5-88a98d23122f	dd0e8400-e29b-41d4-a716-446655440011	send	CoverMyMeds	EXT011001	{"message_type": "PAApproval", "duration_days": 30, "approval_number": "PA2024001"}	2025-11-10 01:21:05.187477-08	transmitted	t
24a3f5ec-cb7c-4721-a0f0-dc4738c76b7c	dd0e8400-e29b-41d4-a716-446655440012	receive	Surescripts	EXT012001	{"fill_status": "approved", "message_type": "Refill", "remaining_refills": 10}	2025-11-07 01:21:05.187477-08	received	t
8d40dffb-499d-42e8-b402-3c3df6ebf090	dd0e8400-e29b-41d4-a716-446655440013	send	CoverMyMeds	EXT013001	{"status": "in_transit", "tracking_id": "TRACK13001", "message_type": "Transfer"}	2025-11-11 01:21:05.187477-08	transmitted	f
b45f7219-9469-4359-b5f0-c6aacb27056e	dd0e8400-e29b-41d4-a716-446655440014	receive	Surescripts	EXT014001	{"refills": 3, "quantity": 1, "medication": "Albuterol Inhaler", "message_type": "RxFill"}	2025-11-09 01:21:05.187477-08	received	t
31fe8a5f-88e8-4e8c-a895-0389c2e65422	dd0e8400-e29b-41d4-a716-446655440015	send	CoverMyMeds	EXT015001	{"status": "pending", "message_type": "PARequest", "request_date": "2024-11-06"}	2025-11-10 01:21:05.187477-08	pending	f
75e6e013-2534-4cbe-a148-eca492f823f6	dd0e8400-e29b-41d4-a716-446655440016	receive	Surescripts	EXT016001	{"drug_code": "308230", "message_type": "NewRx", "prescriber_npi": "1234567890"}	2025-11-08 01:21:05.187477-08	received	t
da6caad7-5ba2-446a-92e4-58575054156b	dd0e8400-e29b-41d4-a716-446655440017	send	CoverMyMeds	EXT017001	{"rx_number": "RX9876543210", "message_type": "Refill", "patient_last_name": "Smith"}	2025-11-06 01:21:05.187477-08	transmitted	t
2da84435-9cad-49fc-99f3-ae245e4796be	dd0e8400-e29b-41d4-a716-446655440018	receive	Surescripts	EXT018001	{"specialty": "Oncology", "message_type": "SpecialtyCare", "clinical_data": "included"}	2025-11-11 01:21:05.187477-08	received	f
f1cc6cce-ed90-4d19-9aae-d8936dbb59cf	dd0e8400-e29b-41d4-a716-446655440019	send	CoverMyMeds	EXT019001	{"form_222": true, "message_type": "ControlledSubstance", "dea_signature": "required"}	2025-11-09 01:21:05.187477-08	transmitted	t
88c48ddc-5bfd-42fa-86f1-60f7f8f03df8	dd0e8400-e29b-41d4-a716-446655440020	receive	Surescripts	EXT020001	{"event": "rx_ready_for_pickup", "message_type": "Notification", "patient_notification_sent": true}	2025-11-12 01:21:05.187477-08	received	t
\.


--
-- Data for Name: prescription_workflow_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.prescription_workflow_logs (id, prescription_id, from_status, to_status, queue_name, changed_by, change_reason, changed_at, metadata) FROM stdin;
1	dd0e8400-e29b-41d4-a716-446655440012	PENDING	IN_REVIEW	clinical_review	550e8400-e29b-41d4-a716-446655440008	Clinical review initiated	2025-11-20 01:03:40.403606-08	{"priority": "normal", "reviewer_notes": "Standard review process"}
2	dd0e8400-e29b-41d4-a716-446655440016	IN_REVIEW	APPROVED	approval_queue	550e8400-e29b-41d4-a716-446655440008	Prescription approved after clinical review	2025-11-20 01:03:40.403606-08	{"approval_type": "standard", "review_time_minutes": 15, "reviewer_credentials": "PharmD"}
3	dd0e8400-e29b-41d4-a716-446655440011	APPROVED	SENT_TO_PATIENT	dispensing_queue	550e8400-e29b-41d4-a716-446655440011	Prescription transmitted to patient	2025-11-20 01:03:40.403606-08	{"delivery_method": "secure_email", "patient_notified": true}
4	dd0e8400-e29b-41d4-a716-446655440005	PENDING	REJECTED	rejection_queue	550e8400-e29b-41d4-a716-446655440014	Rejected - incomplete patient information	2025-11-20 01:03:40.403606-08	{"rejection_code": "INCOMPLETE_INFO", "required_fields": ["insurance_id", "allergy_check"]}
5	dd0e8400-e29b-41d4-a716-446655440011	IN_REVIEW	HOLD	hold_queue	550e8400-e29b-41d4-a716-446655440002	Waiting for insurance verification	2025-11-20 01:03:40.403606-08	{"hold_type": "insurance_pending", "expected_response": "2024-01-20T17:00:00Z", "insurance_contacted": true}
6	dd0e8400-e29b-41d4-a716-446655440016	HOLD	APPROVED	approval_queue	550e8400-e29b-41d4-a716-446655440015	Insurance verification completed successfully	2025-11-20 01:03:40.403606-08	{"copay_amount": 25.00, "coverage_tier": "standard", "verification_status": "approved"}
7	dd0e8400-e29b-41d4-a716-446655440016	SENT_TO_PATIENT	FILLED	fulfilled_queue	550e8400-e29b-41d4-a716-446655440015	Prescription filled by pharmacy	2025-11-20 01:03:40.403606-08	{"unit": "tablets", "filled_date": "2024-01-16T13:45:00Z", "quantity_dispensed": 30, "refills_authorized": 2}
8	dd0e8400-e29b-41d4-a716-446655440004	PENDING	IN_REVIEW	urgent_queue	550e8400-e29b-41d4-a716-446655440011	High-priority prescription - expedited review	2025-11-20 01:03:40.403606-08	{"reason": "acute_condition", "urgency": "high", "target_completion": "2024-01-15T17:00:00Z"}
9	dd0e8400-e29b-41d4-a716-446655440012	APPROVED	CANCELLED	cancellation_queue	550e8400-e29b-41d4-a716-446655440017	Prescription cancelled by patient request	2025-11-20 01:03:40.403606-08	{"cancelled_by": "patient", "cancellation_code": "PATIENT_REQUEST", "cancellation_reason": "patient_requested"}
10	dd0e8400-e29b-41d4-a716-446655440007	FILLED	COMPLETED	archive_queue	550e8400-e29b-41d4-a716-446655440015	Prescription workflow completed	2025-11-20 01:03:40.403606-08	{"completion_date": "2024-01-17T09:30:00Z", "patient_feedback": "excellent", "total_processing_time_hours": 48}
11	dd0e8400-e29b-41d4-a716-446655440001	Prescription Intake	Pharmacist Review	Standard	85ed3940-0383-4976-8e2e-edf71e148e99	Standard	2025-11-20 15:35:33.982728-08	{"priority": "normal", "reviewer_notes": "Standard review process"}
12	dd0e8400-e29b-41d4-a716-446655440001	Pharmacist Review	Patient Verification	Standard	85ed3940-0383-4976-8e2e-edf71e148e99	Standard	2025-11-20 15:40:04.599309-08	{"priority": "normal", "reviewer_notes": "Standard review process"}
13	dd0e8400-e29b-41d4-a716-446655440001	Patient Verification	Medication Dispensing	Standard	85ed3940-0383-4976-8e2e-edf71e148e99	Standard	2025-11-20 15:40:09.523796-08	{"priority": "normal", "reviewer_notes": "Standard review process"}
14	dd0e8400-e29b-41d4-a716-446655440001	Medication Dispensing	Quality Assurance	Standard	85ed3940-0383-4976-8e2e-edf71e148e99	Standard	2025-11-20 15:40:11.267618-08	{"priority": "normal", "reviewer_notes": "Standard review process"}
15	dd0e8400-e29b-41d4-a716-446655440001	Prescription Intake	Pharmacist Review	Standard	85ed3940-0383-4976-8e2e-edf71e148e99	Standard	2025-11-21 20:17:55.762023-08	{"priority": "normal", "reviewer_notes": "Standard review process"}
\.


--
-- Data for Name: prescriptions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.prescriptions (id, patient_id, prescriber_name, prescriber_dea, issue_date, status, workflow_step_id, priority, notes, metadata, created_at, queue_name, assigned_to, last_status_update, estimated_ready_time, pickup_time, completion_time) FROM stdin;
dd0e8400-e29b-41d4-a716-446655440001	770e8400-e29b-41d4-a716-446655440001	Dr. James Smith	AS1234567	2025-11-24 21:14:42.552153-08	filled	1	normal	Patient requested morning dose	{"erx_id": "ERX001", "medication": "Metformin 500mg", "quantity_dispensed": 30}	2025-11-24 21:14:42.552153-08	Standard	\N	2025-11-25 21:14:42.552153-08	2025-11-26 22:14:42.552153-08	\N	\N
dd0e8400-e29b-41d4-a716-446655440002	770e8400-e29b-41d4-a716-446655440002	Dr. Sarah Johnson	AJ2345678	2025-11-23 21:14:42.552153-08	filled	2	high	Prior authorization received	{"erx_id": "ERX002", "medication": "Lisinopril 10mg", "quantity_dispensed": 90}	2025-11-23 21:14:42.552153-08	Insurance Hold	\N	2025-11-25 21:14:42.552153-08	2025-11-26 23:14:42.552153-08	\N	\N
dd0e8400-e29b-41d4-a716-446655440003	770e8400-e29b-41d4-a716-446655440003	Dr. Michael Chen	AC3456789	2025-11-25 21:14:42.552153-08	reviewed	3	urgent	Emergency refill - patient out of stock	{"erx_id": "ERX003", "medication": "Atorvastatin 20mg", "quantity_dispensed": 14}	2025-11-25 21:14:42.552153-08	Urgent Queue	\N	2025-11-26 21:14:42.552153-08	2025-11-26 21:44:42.552153-08	\N	\N
dd0e8400-e29b-41d4-a716-446655440004	770e8400-e29b-41d4-a716-446655440004	Dr. Emily Rodriguez	AD4567890	2025-11-21 21:14:42.552153-08	filled	4	normal	Regular maintenance prescription	{"erx_id": "ERX004", "medication": "Omeprazole 20mg", "quantity_dispensed": 60}	2025-11-21 21:14:42.552153-08	Standard	\N	2025-11-22 21:14:42.552153-08	2025-11-26 22:14:42.552153-08	\N	\N
dd0e8400-e29b-41d4-a716-446655440005	770e8400-e29b-41d4-a716-446655440005	Dr. Robert Williams	AE5678901	2025-11-22 21:14:42.552153-08	filled	5	high	Requires counseling on side effects	{"erx_id": "ERX005", "medication": "Sertraline 50mg", "quantity_dispensed": 30}	2025-11-22 21:14:42.552153-08	Counseling	\N	2025-11-23 21:14:42.552153-08	2025-11-26 23:14:42.552153-08	\N	\N
dd0e8400-e29b-41d4-a716-446655440006	770e8400-e29b-41d4-a716-446655440006	Dr. Lisa Anderson	AF6789012	2025-11-24 21:14:42.552153-08	pending	6	normal	Awaiting insurance verification	{"erx_id": "ERX006", "medication": "Amlodipine 5mg", "quantity_dispensed": 0}	2025-11-24 21:14:42.552153-08	Insurance Hold	\N	2025-11-26 21:14:42.552153-08	2025-11-27 01:14:42.552153-08	\N	\N
dd0e8400-e29b-41d4-a716-446655440007	770e8400-e29b-41d4-a716-446655440007	Dr. David Martinez	AG7890123	2025-11-20 21:14:42.552153-08	filled	7	low	OTC supplement - no counseling needed	{"erx_id": "ERX007", "medication": "Vitamin D3 1000IU", "quantity_dispensed": 100}	2025-11-20 21:14:42.552153-08	Standard	\N	2025-11-21 21:14:42.552153-08	2025-11-26 21:44:42.552153-08	\N	\N
dd0e8400-e29b-41d4-a716-446655440008	770e8400-e29b-41d4-a716-446655440008	Dr. Jennifer Brown	AH8901234	2025-11-25 21:14:42.552153-08	filled	8	urgent	Medicaid coverage verified	{"erx_id": "ERX008", "medication": "Metoprolol 25mg", "quantity_dispensed": 28}	2025-11-25 21:14:42.552153-08	Standard	\N	2025-11-26 21:14:42.552153-08	2025-11-26 22:14:42.552153-08	\N	\N
dd0e8400-e29b-41d4-a716-446655440009	770e8400-e29b-41d4-a716-446655440009	Dr. Thomas Lee	AI9012345	2025-11-23 21:14:42.552153-08	voided	9	normal	Patient requested cancellation - duplicate prescription	{"erx_id": "ERX009", "medication": "Ibuprofen 200mg", "quantity_dispensed": 0}	2025-11-23 21:14:42.552153-08	Voided	\N	2025-11-24 21:14:42.552153-08	\N	\N	\N
dd0e8400-e29b-41d4-a716-446655440010	770e8400-e29b-41d4-a716-446655440010	Dr. Patricia Garcia	AJ0123456	2025-11-22 21:14:42.552153-08	filled	10	high	Controlled substance - requires ID verification	{"erx_id": "ERX010", "medication": "Hydrocodone 5mg/500mg", "quantity_dispensed": 30}	2025-11-22 21:14:42.552153-08	Controlled Substances	\N	2025-11-23 21:14:42.552153-08	2025-11-26 23:14:42.552153-08	\N	\N
dd0e8400-e29b-41d4-a716-446655440011	770e8400-e29b-41d4-a716-446655440011	Dr. Christopher Davis	AK1234567	2025-11-24 21:14:42.552153-08	reviewed	11	normal	Checking for drug interactions	{"erx_id": "ERX011", "medication": "Warfarin 5mg", "quantity_dispensed": 0}	2025-11-24 21:14:42.552153-08	Pharmacist Review	\N	2025-11-25 21:14:42.552153-08	2025-11-27 00:14:42.552153-08	\N	\N
dd0e8400-e29b-41d4-a716-446655440012	770e8400-e29b-41d4-a716-446655440012	Dr. Nancy White	AL2345678	2025-11-21 21:14:42.552153-08	filled	12	normal	Patient preference - generic acceptable	{"erx_id": "ERX012", "medication": "Levothyroxine 75mcg", "quantity_dispensed": 90}	2025-11-21 21:14:42.552153-08	Standard	\N	2025-11-22 21:14:42.552153-08	2025-11-26 22:14:42.552153-08	\N	\N
dd0e8400-e29b-41d4-a716-446655440013	770e8400-e29b-41d4-a716-446655440013	Dr. Mark Taylor	AM3456789	2025-11-25 21:14:42.552153-08	transferred	13	low	Patient transferred to different pharmacy	{"erx_id": "ERX013", "medication": "Fluoxetine 20mg", "quantity_dispensed": 0}	2025-11-25 21:14:42.552153-08	Transferred	\N	2025-11-26 21:14:42.552153-08	\N	\N	\N
dd0e8400-e29b-41d4-a716-446655440014	770e8400-e29b-41d4-a716-446655440014	Dr. Sandra Miller	AN4567890	2025-11-23 21:14:42.552153-08	filled	14	high	Multiple refills authorized	{"erx_id": "ERX014", "medication": "Albuterol Inhaler", "quantity_dispensed": 300}	2025-11-23 21:14:42.552153-08	Standard	\N	2025-11-24 21:14:42.552153-08	2025-11-26 22:14:42.552153-08	\N	\N
dd0e8400-e29b-41d4-a716-446655440015	770e8400-e29b-41d4-a716-446655440015	Dr. Kevin Anderson	AO5678901	2025-11-24 21:14:42.552153-08	pending	15	urgent	Waiting for prior authorization from insurance	{"erx_id": "ERX015", "medication": "Insulin Glargine 100U/ml", "quantity_dispensed": 0}	2025-11-24 21:14:42.552153-08	Insurance Hold	\N	2025-11-26 21:14:42.552153-08	2025-11-27 03:14:42.552153-08	\N	\N
dd0e8400-e29b-41d4-a716-446655440016	770e8400-e29b-41d4-a716-446655440016	Dr. Nicole Thompson	AP6789012	2025-11-22 21:14:42.552153-08	filled	16	normal	New patient - first time at pharmacy	{"erx_id": "ERX016", "medication": "Losartan 50mg", "quantity_dispensed": 45}	2025-11-22 21:14:42.552153-08	Counseling	\N	2025-11-23 21:14:42.552153-08	2025-11-26 23:14:42.552153-08	\N	\N
dd0e8400-e29b-41d4-a716-446655440017	770e8400-e29b-41d4-a716-446655440017	Dr. Gregory Wilson	AQ7890123	2025-11-20 21:14:42.552153-08	filled	17	low	Routine refill - no issues	{"erx_id": "ERX017", "medication": "Metformin XR 1000mg", "quantity_dispensed": 60}	2025-11-20 21:14:42.552153-08	Standard	\N	2025-11-21 21:14:42.552153-08	2025-11-26 22:14:42.552153-08	\N	\N
dd0e8400-e29b-41d4-a716-446655440018	770e8400-e29b-41d4-a716-446655440018	Dr. Victoria Harris	AR8901234	2025-11-25 21:14:42.552153-08	reviewed	18	high	Patient age requires caution with dosing	{"erx_id": "ERX018", "medication": "Digoxin 0.25mg", "quantity_dispensed": 0}	2025-11-25 21:14:42.552153-08	Pharmacist Review	\N	2025-11-26 21:14:42.552153-08	2025-11-27 01:14:42.552153-08	\N	\N
dd0e8400-e29b-41d4-a716-446655440019	770e8400-e29b-41d4-a716-446655440019	Dr. Stephen Moore	AS9012345	2025-11-23 21:14:42.552153-08	filled	19	urgent	Patient hospitalized - stat refill needed	{"erx_id": "ERX019", "medication": "Morphine 15mg", "quantity_dispensed": 14}	2025-11-23 21:14:42.552153-08	Urgent Queue	\N	2025-11-24 21:14:42.552153-08	2025-11-26 21:44:42.552153-08	\N	\N
dd0e8400-e29b-41d4-a716-446655440020	770e8400-e29b-41d4-a716-446655440020	Dr. Amanda Jackson	AT0123456	2025-11-24 21:14:42.552153-08	filled	20	normal	Seasonal allergy medication - expected refill	{"erx_id": "ERX020", "medication": "Cetirizine 10mg", "quantity_dispensed": 60}	2025-11-24 21:14:42.552153-08	Standard	\N	2025-11-25 21:14:42.552153-08	2025-11-26 22:14:42.552153-08	\N	\N
\.


--
-- Data for Name: profit_audit_warnings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.profit_audit_warnings (id, related_object_type, related_object_id, warning_code, description, created_at) FROM stdin;
1	prescription	dd0e8400-e29b-41d4-a716-446655440004	NEGATIVE_MARGIN_CII	Controlled substance fill resulted in negative margin due to acquisition cost exceeding reimbursement	2024-01-18 08:00:00-08
2	prescription	dd0e8400-e29b-41d4-a716-446655440005	DIR_FEE_EXCEEDS_MARGIN	DIR fees applied to this claim exceed the pharmacy margin	2024-01-24 03:00:00-08
3	claim	e4e4e4e4-e4e4-4e4e-8e4e-e4e4e4e4e4e4	CLAIM_REJECTION_LOSS	Claim rejection resulted in unrecovered dispensing cost	2024-01-24 06:00:00-08
4	prescription	dd0e8400-e29b-41d4-a716-446655440008	STUDENT_PLAN_UNDERREIMBURSEMENT	Student health plan reimbursement below acquisition cost	2024-01-22 05:00:00-08
5	prescription	dd0e8400-e29b-41d4-a716-446655440009	LOW_MARGIN_ALERT	Prescription margin below 5% threshold - monitor for volume impact	2024-01-23 03:30:00-08
6	claim	c2c2c2c2-c2c2-4c2c-8c2c-c2c2c2c2c2c2	PENDING_CLAIM_RISK	Pending claim status exceeds 48 hours - reimbursement uncertain	2024-01-25 02:40:00-08
7	prescription	dd0e8400-e29b-41d4-a716-446655440010	REFUND_LOSS	Refunded prescription resulted in operating loss	2024-01-25 02:50:00-08
8	claim	a6a6a6a6-a6a6-4a6a-8a6a-a6a6a6a6a6a6	BRAND_OVERRIDE_LOSS	Brand required override resulted in reduced reimbursement vs generic	2024-01-21 08:30:00-08
\.


--
-- Data for Name: purchase_orders; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.purchase_orders (id, wholesaler_id, created_by, status, ordered_at, expected_arrival, payload) FROM stdin;
cc0e8400-e29b-41d4-a716-446655440001	1	550e8400-e29b-41d4-a716-446655440006	received	2024-01-10 01:30:00-08	2024-01-15	{"items": [{"sku": "SKU-LISINOPRIL-10", "total": 2500, "quantity": 500, "unit_price": 5.00}], "order_total": 2500, "status_notes": "Received and verified"}
cc0e8400-e29b-41d4-a716-446655440002	2	550e8400-e29b-41d4-a716-446655440006	received	2024-01-11 02:15:00-08	2024-01-17	{"items": [{"sku": "SKU-METFORMIN-500", "total": 3375, "quantity": 750, "unit_price": 4.50}], "order_total": 3375, "status_notes": "All items verified"}
cc0e8400-e29b-41d4-a716-446655440003	3	550e8400-e29b-41d4-a716-446655440006	submitted	2024-01-12 03:00:00-08	2024-01-20	{"items": [{"sku": "SKU-AMOXICILLIN-500", "total": 2500, "quantity": 400, "unit_price": 6.25}], "order_total": 2500, "status_notes": "Awaiting shipment confirmation"}
cc0e8400-e29b-41d4-a716-446655440004	1	550e8400-e29b-41d4-a716-446655440006	received	2024-01-13 00:20:00-08	2024-01-18	{"items": [{"sku": "SKU-HYDROCODONE-5", "total": 4500, "quantity": 300, "unit_price": 15.00}, {"sku": "SKU-MORPHINE-30", "total": 5000, "quantity": 200, "unit_price": 25.00}], "order_total": 9500, "status_notes": "DEA Form 224 submitted"}
cc0e8400-e29b-41d4-a716-446655440005	4	550e8400-e29b-41d4-a716-446655440006	open	2024-01-14 05:45:00-08	2024-01-25	{"items": [{"sku": "SKU-ATORVASTATIN-20", "total": 4500, "quantity": 600, "unit_price": 7.50}], "order_total": 4500, "status_notes": "Pending approval"}
cc0e8400-e29b-41d4-a716-446655440006	2	550e8400-e29b-41d4-a716-446655440006	received	2024-01-15 06:30:00-08	2024-01-21	{"items": [{"sku": "SKU-OMEPRAZOLE-20", "total": 3200, "quantity": 400, "unit_price": 8.00}], "order_total": 3200, "status_notes": "Lot numbers documented"}
cc0e8400-e29b-41d4-a716-446655440007	1	550e8400-e29b-41d4-a716-446655440006	submitted	2024-01-16 01:00:00-08	2024-01-23	{"items": [{"sku": "SKU-LEVOTHYROXINE-75", "total": 1750, "quantity": 500, "unit_price": 3.50}], "order_total": 1750, "status_notes": "In transit"}
cc0e8400-e29b-41d4-a716-446655440008	3	550e8400-e29b-41d4-a716-446655440006	received	2024-01-17 02:30:00-08	2024-01-22	{"items": [{"sku": "SKU-ASPIRIN-325", "total": 2000, "quantity": 1000, "unit_price": 2.00}], "order_total": 2000, "status_notes": "OTC verification complete"}
cc0e8400-e29b-41d4-a716-446655440009	5	550e8400-e29b-41d4-a716-446655440006	cancelled	2024-01-18 07:15:00-08	2024-01-26	{"items": [{"sku": "SKU-GABAPENTIN-300", "total": 1375, "quantity": 250, "unit_price": 5.50}], "order_total": 1375, "status_notes": "Cancelled - supplier out of stock"}
cc0e8400-e29b-41d4-a716-446655440010	2	550e8400-e29b-41d4-a716-446655440006	open	2024-01-19 00:40:00-08	2024-01-27	{"items": [{"sku": "SKU-IBUPROFEN-200", "total": 1400, "quantity": 800, "unit_price": 1.75}], "order_total": 1400, "status_notes": "Awaiting payment approval"}
\.


--
-- Data for Name: queues; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.queues (id, name, description, config) FROM stdin;
1	Prescription_Intake	Queue for new prescription intake	{"priority_levels": [0, 1, 2], "max_wait_minutes": 30, "routing_strategy": "round_robin"}
2	Pharmacist_Review	Queue for pharmacist prescription reviews	{"roles": ["pharmacist"], "priority_levels": [0, 1, 2], "max_wait_minutes": 20, "routing_strategy": "skill_based"}
3	Prior_Authorization	Queue for prior authorization requests	{"roles": ["insurance_coordinator"], "priority_levels": [0, 1, 2], "max_wait_minutes": 60, "routing_strategy": "skill_based"}
4	Controlled_Substance	Queue for controlled substance prescriptions	{"roles": ["pharmacist"], "priority_levels": [0, 1, 2], "compliance_level": "high", "max_wait_minutes": 30, "routing_strategy": "skill_based"}
5	Inventory_Receiving	Queue for inventory receiving tasks	{"roles": ["warehouse_staff"], "priority_levels": [0, 1, 2], "max_wait_minutes": 45, "routing_strategy": "fifo"}
6	Quality_Assurance	Queue for quality assurance checks	{"roles": ["pharmacist", "quality_assurance_specialist"], "priority_levels": [0, 1, 2], "max_wait_minutes": 15, "routing_strategy": "round_robin"}
7	Billing_Claims	Queue for billing and claims processing	{"roles": ["billing_specialist"], "priority_levels": [0, 1, 2], "max_wait_minutes": 120, "routing_strategy": "round_robin"}
8	Patient_Care	Queue for patient care and refill requests	{"roles": ["patient_care_specialist"], "priority_levels": [0, 1, 2], "max_wait_minutes": 15, "routing_strategy": "skill_based"}
9	PDMP_Monitoring	Queue for PDMP queries and monitoring	{"automated": true, "priority_levels": [1, 2], "max_wait_minutes": 5, "routing_strategy": "automated"}
10	Insurance_Verification	Queue for patient insurance verification	{"roles": ["billing_specialist", "patient_care_specialist"], "priority_levels": [0, 1, 2], "max_wait_minutes": 20, "routing_strategy": "round_robin"}
\.


--
-- Data for Name: reorder_rules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reorder_rules (id, inventory_item_id, min_level, max_level, preferred_wholesalers) FROM stdin;
1	990e8400-e29b-41d4-a716-446655440001	50	200	{1,2,3}
2	990e8400-e29b-41d4-a716-446655440002	75	250	{2,1,3}
3	990e8400-e29b-41d4-a716-446655440003	40	150	{1,3,2}
4	990e8400-e29b-41d4-a716-446655440004	30	100	{1,2}
5	990e8400-e29b-41d4-a716-446655440005	60	200	{2,3,1}
6	990e8400-e29b-41d4-a716-446655440006	45	180	{3,1,2}
7	990e8400-e29b-41d4-a716-446655440007	50	150	{1,2,3}
8	990e8400-e29b-41d4-a716-446655440008	100	300	{2,1}
9	990e8400-e29b-41d4-a716-446655440009	40	120	{1,3,2}
10	990e8400-e29b-41d4-a716-446655440010	80	250	{3,2,1}
\.


--
-- Data for Name: reports; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reports (id, owner_id, name, description, filters, schedule, last_run) FROM stdin;
\.


--
-- Data for Name: role_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.role_permissions (id, role_id, permission_key, granted_by, granted_at) FROM stdin;
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles (id, name, description) FROM stdin;
1	Super Administrator	Full system access. Manages all users, roles, permissions, and system configuration.
2	Pharmacy Manager	Oversees daily pharmacy operations, staff management, and handles escalations.
3	Pharmacist	Licensed pharmacist. Reviews prescriptions, verifies patient information, manages PDMP queries.
4	Pharmacy Technician	Assists pharmacists with prescription filling, inventory management, and data entry.
5	Inventory Manager	Manages pharmaceutical inventory, orders, receiving, and stock levels.
6	Compliance Officer	Monitors regulatory compliance, HIPAA requirements, and audit trails.
7	Billing Specialist	Processes billing, POS transactions, and manages patient payments.
8	Patient Care Specialist	Assists patients with prescriptions, insurance information, and refills.
\.


--
-- Data for Name: spatial_ref_sys; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.spatial_ref_sys (srid, auth_name, auth_srid, srtext, proj4text) FROM stdin;
\.


--
-- Data for Name: stations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.stations (id, station_prefix, department, location, starting_number, current_number, max_stations, created_date, updated_date) FROM stdin;
2	IP	Inventory	Storage Room	1	1	1	2025-11-18 01:32:20.340628	2025-11-19 20:39:44.436238
3	LD	Lab/Dispensary	Main Floor	1	1	1	2025-11-18 01:32:20.340628	2025-11-19 20:39:44.436238
4	AR	Administration	Office	1	1	1	2025-11-18 01:32:20.340628	2025-11-19 20:39:44.436238
5	QA	Quality Assurance	Testing Area	1	1	1	2025-11-18 01:32:20.340628	2025-11-19 20:39:44.436238
1	RX	Pharmacy	Main Counter	1	2	1	2025-11-18 01:32:20.340628	2025-11-25 00:36:48.651866
\.


--
-- Data for Name: task_routing; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.task_routing (id, queue_id, rule_order, rule) FROM stdin;
1	1	1	{"action": "assign_immediately", "condition": {"priority": 2}}
2	1	2	{"action": "assign_within_10_minutes", "condition": {"priority": 1}}
3	1	3	{"action": "assign_within_30_minutes", "condition": {"priority": 0}}
4	2	1	{"action": "assign_to_senior_pharmacist", "condition": {"is_controlled": true}}
5	2	2	{"action": "assign_immediately", "condition": {"priority": 2}}
6	2	3	{"action": "assign_to_manager", "condition": {"requires_override": true}}
7	2	4	{"action": "assign_within_15_minutes", "condition": {"priority": 1}}
8	3	1	{"action": "assign_immediately_to_insurance_coordinator", "condition": {"priority": 2}}
9	3	2	{"action": "escalate", "condition": {"sla_hours": {"remaining": {"less_than": 24}}}}
10	3	3	{"action": "manual_review", "condition": {"attempt_count": {"greater_than": 2}}}
11	4	1	{"action": "assign_to_pharmacist", "condition": {"dea_schedule": {"in": ["II", "III"]}}}
12	4	2	{"action": "assign_immediately", "condition": {"priority": 2}}
13	4	3	{"action": "flag_for_pdmp_check", "condition": {"pdmp_required": true}}
14	5	1	{"action": "assign_to_senior_warehouse_staff", "condition": {"controlled": true}}
15	5	2	{"action": "notify_inventory_manager", "condition": {"total_items": {"greater_than": 500}}}
16	5	3	{"action": "expedite_processing", "condition": {"priority": 2}}
17	6	1	{"action": "assign_to_pharmacist", "condition": {"is_controlled": true}}
18	6	2	{"action": "assign_immediately", "condition": {"priority": 2}}
19	6	3	{"action": "assign_to_experienced_qa", "condition": {"requires_counseling": true}}
20	7	1	{"action": "manual_review", "condition": {"claim_status": "rejected"}}
21	7	2	{"action": "expedite", "condition": {"priority": 2}}
22	7	3	{"action": "escalate", "condition": {"sla_hours": {"remaining": {"less_than": 24}}}}
23	8	1	{"action": "assign_immediately", "condition": {"priority": 2}}
24	8	2	{"action": "assign_patient_care_specialist", "condition": {"refill_request": true}}
25	8	3	{"action": "route_to_trained_staff", "condition": {"accessibility_needs": true}}
26	9	1	{"action": "automated_pdmp_query", "condition": {"dea_schedule": {"in": ["II", "III", "IV"]}}}
27	9	2	{"action": "escalate_to_pharmacist", "condition": {"opioid_alert": true}}
28	10	1	{"action": "assign_immediately", "condition": {"priority": 2}}
29	10	2	{"action": "assign_to_medicaid_specialist", "condition": {"insurance_type": "medicaid"}}
30	10	3	{"action": "manual_verification_required", "condition": {"verification_failed": true}}
\.


--
-- Data for Name: tasks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tasks (id, object_type, object_id, workflow_id, step_id, queue_id, assignee, status, payload, priority, created_at, due_at) FROM stdin;
11111111-1111-4111-8111-111111111111	prescription	dd0e8400-e29b-41d4-a716-446655440001	1	2	2	550e8400-e29b-41d4-a716-446655440001	completed	{"patient": "James Anderson", "quantity": 30, "medication": "Lisinopril 10mg"}	0	2024-01-15 02:00:00-08	2024-01-15 02:20:00-08
22222222-2222-4222-8222-222222222222	prescription	dd0e8400-e29b-41d4-a716-446655440002	1	2	2	550e8400-e29b-41d4-a716-446655440002	completed	{"patient": "Sarah Martinez", "quantity": 60, "medication": "Metformin 500mg", "refill_count": 5}	0	2024-01-16 06:30:00-08	2024-01-16 06:50:00-08
33333333-3333-4333-8333-333333333333	prescription	dd0e8400-e29b-41d4-a716-446655440003	3	13	3	550e8400-e29b-41d4-a716-446655440010	open	{"patient": "Michael Chen", "insurance": "United", "medication": "Amoxicillin 500mg", "prior_auth_status": "submitted"}	1	2024-01-17 01:15:00-08	2024-01-18 01:15:00-08
44444444-4444-4444-8444-444444444444	prescription	dd0e8400-e29b-41d4-a716-446655440004	2	9	4	550e8400-e29b-41d4-a716-446655440001	completed	{"patient": "Emily Thompson", "quantity": 20, "medication": "Hydrocodone/Acetaminophen 5mg/500mg", "dea_schedule": "II", "student_flag": true}	1	2024-01-18 03:45:00-08	2024-01-18 04:45:00-08
55555555-5555-4555-8555-555555555555	prescription	dd0e8400-e29b-41d4-a716-446655440005	3	13	3	550e8400-e29b-41d4-a716-446655440010	in_progress	{"patient": "David Rodriguez", "insurance": "Cigna", "medication": "Atorvastatin 20mg", "prior_auth_required": true}	1	2024-01-19 05:20:00-08	2024-01-20 05:20:00-08
66666666-6666-4666-8666-666666666666	prescription	dd0e8400-e29b-41d4-a716-446655440006	1	2	2	550e8400-e29b-41d4-a716-446655440002	completed	{"patient": "Jessica Williams", "quantity": 30, "medication": "Omeprazole 20mg", "otc_eligible": true}	0	2024-01-20 00:30:00-08	2024-01-20 00:50:00-08
77777777-7777-4777-8777-777777777777	prescription	dd0e8400-e29b-41d4-a716-446655440007	1	2	2	550e8400-e29b-41d4-a716-446655440001	completed	{"patient": "Robert Johnson", "quantity": 30, "medication": "Levothyroxine 75mcg", "brand_required": true}	0	2024-01-21 07:45:00-08	2024-01-21 08:05:00-08
88888888-8888-4888-8888-888888888888	prescription	dd0e8400-e29b-41d4-a716-446655440008	1	2	2	550e8400-e29b-41d4-a716-446655440007	completed	{"patient": "Angela Kim", "quantity": 1, "medication": "Albuterol 90mcg inhaler", "student_flag": true}	0	2024-01-22 04:10:00-08	2024-01-22 04:30:00-08
99999999-9999-4999-8999-999999999999	prescription	dd0e8400-e29b-41d4-a716-446655440009	2	9	4	550e8400-e29b-41d4-a716-446655440001	in_progress	{"patient": "Christopher Lee", "quantity": 30, "medication": "Gabapentin 300mg", "dea_schedule": "V", "pdmp_required": true}	2	2024-01-23 02:25:00-08	2024-01-23 03:25:00-08
aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa	prescription	dd0e8400-e29b-41d4-a716-446655440010	9	15	8	550e8400-e29b-41d4-a716-446655440002	completed	{"patient": "Michelle Brown", "medication": "Ibuprofen 200mg", "transfer_reason": "patient_convenience", "destination_pharmacy": "Community Pharmacy"}	0	2024-01-24 08:50:00-08	2024-01-24 09:10:00-08
bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb	inventory_batch	aa0e8400-e29b-41d4-a716-446655440001	4	18	5	550e8400-e29b-41d4-a716-446655440006	completed	{"cost": 2500, "items": 120, "lot_number": "LOT-20240110-001", "wholesaler": "Cardinal Health"}	0	2024-01-10 01:30:00-08	2024-01-10 03:00:00-08
cccccccc-cccc-4ccc-8ccc-cccccccccccc	inventory_batch	aa0e8400-e29b-41d4-a716-446655440002	4	18	5	550e8400-e29b-41d4-a716-446655440006	completed	{"cost": 3375, "items": 180, "lot_number": "LOT-20240111-001", "wholesaler": "McKesson"}	0	2024-01-11 02:15:00-08	2024-01-11 03:45:00-08
dddddddd-dddd-4ddd-8ddd-dddddddddddd	inventory_batch	aa0e8400-e29b-41d4-a716-446655440003	4	20	5	550e8400-e29b-41d4-a716-446655440006	in_progress	{"cost": 2500, "items": 85, "lot_number": "LOT-20240112-001", "wholesaler": "AmerisourceBergen"}	0	2024-01-12 03:00:00-08	2024-01-12 04:30:00-08
eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee	inventory_batch	aa0e8400-e29b-41d4-a716-446655440004	4	21	5	550e8400-e29b-41d4-a716-446655440008	open	{"cost": 9500, "items": 45, "controlled": true, "lot_number": "LOT-20240113-001", "wholesaler": "Cardinal Health", "requires_dea_verification": true}	2	2024-01-13 00:20:00-08	2024-01-13 02:00:00-08
ffffffff-ffff-4fff-8fff-ffffffffffff	prescription_item	ee0e8400-e29b-41d4-a716-446655440001	8	5	6	550e8400-e29b-41d4-a716-446655440001	completed	{"patient": "James Anderson", "medication": "Lisinopril", "accuracy_check": "passed", "label_verified": true}	0	2024-01-15 06:00:00-08	2024-01-15 06:15:00-08
10101010-1010-4010-8010-101010101010	prescription_item	ee0e8400-e29b-41d4-a716-446655440004	8	5	6	550e8400-e29b-41d4-a716-446655440001	completed	{"patient": "Emily Thompson", "medication": "Hydrocodone/Acetaminophen", "label_verified": true, "counseling_needed": true, "controlled_substance_check": "passed"}	1	2024-01-18 07:30:00-08	2024-01-18 07:45:00-08
20202020-2020-4020-8020-202020202020	prescription_item	ee0e8400-e29b-41d4-a716-446655440009	8	5	6	550e8400-e29b-41d4-a716-446655440001	open	{"patient": "Christopher Lee", "medication": "Gabapentin", "accuracy_check": "pending", "label_verification": "pending"}	1	2024-01-23 02:25:00-08	2024-01-23 02:40:00-08
30303030-3030-4030-8030-303030303030	claim	dd0e8400-e29b-41d4-a716-446655440001	10	16	7	550e8400-e29b-41d4-a716-446655440009	completed	{"payer": "United Healthcare", "status": "approved", "claim_amount": 35.50, "patient_copay": 25.00}	0	2024-01-15 06:05:00-08	2024-01-18 06:05:00-08
40404040-4040-4040-8040-404040404040	claim	dd0e8400-e29b-41d4-a716-446655440002	10	16	7	550e8400-e29b-41d4-a716-446655440009	completed	{"payer": "Premera Blue Cross", "status": "approved", "claim_amount": 45.75, "patient_copay": 0.00}	0	2024-01-16 07:20:00-08	2024-01-19 07:20:00-08
50505050-5050-4050-8050-505050505050	claim	dd0e8400-e29b-41d4-a716-446655440003	10	14	7	550e8400-e29b-41d4-a716-446655440009	open	{"payer": "Cigna", "status": "pending", "sla_due": "2024-02-03", "claim_amount": 28.99, "patient_copay": 20.00}	1	2024-01-17 02:35:00-08	2024-02-03 02:35:00-08
\.


--
-- Data for Name: user_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_permissions (id, user_id, permission_key, granted, granted_at) FROM stdin;
1	550e8400-e29b-41d4-a716-446655440001	prescription.review.override	t	2024-01-10 01:30:00-08
2	550e8400-e29b-41d4-a716-446655440001	prescription.fill	t	2024-01-10 01:30:00-08
3	550e8400-e29b-41d4-a716-446655440001	pdmp.query	t	2024-01-10 01:30:00-08
4	550e8400-e29b-41d4-a716-446655440002	prescription.review.override	t	2024-01-11 02:15:00-08
5	550e8400-e29b-41d4-a716-446655440002	prescription.fill	t	2024-01-11 02:15:00-08
6	550e8400-e29b-41d4-a716-446655440002	pdmp.query	t	2024-01-11 02:15:00-08
7	550e8400-e29b-41d4-a716-446655440003	prescription.fill	t	2024-01-12 03:00:00-08
8	550e8400-e29b-41d4-a716-446655440004	prescription.fill	t	2024-01-13 00:20:00-08
9	550e8400-e29b-41d4-a716-446655440007	prescription.review.override	t	2024-01-16 01:00:00-08
10	550e8400-e29b-41d4-a716-446655440007	prescription.fill	t	2024-01-16 01:00:00-08
11	550e8400-e29b-41d4-a716-446655440013	prescription.review.override	t	2024-01-22 00:15:00-08
12	550e8400-e29b-41d4-a716-446655440013	prescription.fill	t	2024-01-22 00:15:00-08
13	550e8400-e29b-41d4-a716-446655440015	prescription.review.override	t	2024-01-24 05:20:00-08
14	550e8400-e29b-41d4-a716-446655440015	prescription.fill	t	2024-01-24 05:20:00-08
15	550e8400-e29b-41d4-a716-446655440018	prescription.review.override	t	2024-01-27 01:00:00-08
16	550e8400-e29b-41d4-a716-446655440018	prescription.fill	t	2024-01-27 01:00:00-08
17	550e8400-e29b-41d4-a716-446655440020	prescription.review.override	t	2024-01-29 02:10:00-08
18	550e8400-e29b-41d4-a716-446655440020	prescription.fill	t	2024-01-29 02:10:00-08
\.


--
-- Data for Name: user_sso; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_sso (id, user_id, provider, external_id, metadata) FROM stdin;
660e8400-e29b-41d4-a716-446655440001	550e8400-e29b-41d4-a716-446655440001	okta	okta-user-8374629	{"email": "alice.smith@pharmacy.com", "okta_id": "00u8374629abc", "last_name": "Smith", "first_name": "Alice", "activated_date": "2024-01-10T09:30:00Z"}
660e8400-e29b-41d4-a716-446655440002	550e8400-e29b-41d4-a716-446655440002	okta	okta-user-5829471	{"email": "bob.wilson@pharmacy.com", "okta_id": "00u5829471def", "last_name": "Wilson", "first_name": "Bob", "activated_date": "2024-01-11T10:15:00Z"}
660e8400-e29b-41d4-a716-446655440003	550e8400-e29b-41d4-a716-446655440003	okta	okta-user-3847562	{"email": "carol.johnson@pharmacy.com", "okta_id": "00u3847562ghi", "last_name": "Johnson", "first_name": "Carol", "activated_date": "2024-01-12T11:00:00Z"}
660e8400-e29b-41d4-a716-446655440004	550e8400-e29b-41d4-a716-446655440004	okta	okta-user-6574938	{"email": "david.miller@pharmacy.com", "okta_id": "00u6574938jkl", "last_name": "Miller", "first_name": "David", "activated_date": "2024-01-13T08:20:00Z"}
660e8400-e29b-41d4-a716-446655440005	550e8400-e29b-41d4-a716-446655440005	okta	okta-user-1847562	{"email": "emma.lee@pharmacy.com", "okta_id": "00u1847562mno", "last_name": "Lee", "first_name": "Emma", "activated_date": "2024-01-14T13:45:00Z"}
660e8400-e29b-41d4-a716-446655440006	550e8400-e29b-41d4-a716-446655440006	okta	okta-user-7384920	{"email": "frank.brown@pharmacy.com", "okta_id": "00u7384920pqr", "last_name": "Brown", "first_name": "Frank", "activated_date": "2024-01-15T14:30:00Z"}
660e8400-e29b-41d4-a716-446655440007	550e8400-e29b-41d4-a716-446655440007	okta	okta-user-9283746	{"email": "grace.davis@pharmacy.com", "okta_id": "00u9283746stu", "last_name": "Davis", "first_name": "Grace", "activated_date": "2024-01-16T09:00:00Z"}
660e8400-e29b-41d4-a716-446655440008	550e8400-e29b-41d4-a716-446655440008	okta	okta-user-4928374	{"email": "henry.martin@pharmacy.com", "okta_id": "00u4928374vwx", "last_name": "Martin", "first_name": "Henry", "activated_date": "2024-01-17T10:30:00Z"}
660e8400-e29b-41d4-a716-446655440009	550e8400-e29b-41d4-a716-446655440009	okta	okta-user-3927481	{"email": "iris.taylor@pharmacy.com", "okta_id": "00u3927481yza", "last_name": "Taylor", "first_name": "Iris", "activated_date": "2024-01-18T15:15:00Z"}
660e8400-e29b-41d4-a716-446655440010	550e8400-e29b-41d4-a716-446655440010	okta	okta-user-8374622	{"email": "jack.white@pharmacy.com", "okta_id": "00u8374629bcd", "last_name": "White", "first_name": "Jack", "activated_date": "2024-01-19T08:40:00Z"}
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, username, display_name, email, role_id, is_active, created_at, last_login_at) FROM stdin;
85ed3940-0383-4976-8e2e-edf71e148e99	Paul	Paul Mai	paul.mai@datascience9.com	1	t	2025-11-17 08:58:13-08	\N
550e8400-e29b-41d4-a716-446655440001	asmith	Alice Smith	alice.smith@pharmacy.com	3	t	2024-01-10 01:30:00-08	2025-11-06 06:22:00-08
550e8400-e29b-41d4-a716-446655440002	bwilson	Bob Wilson	bob.wilson@pharmacy.com	3	t	2024-01-11 02:15:00-08	2025-11-05 01:45:00-08
550e8400-e29b-41d4-a716-446655440003	cjohnson	Carol Johnson	carol.johnson@pharmacy.com	4	t	2024-01-12 03:00:00-08	2025-11-04 08:30:00-08
550e8400-e29b-41d4-a716-446655440004	dmiller	David Miller	david.miller@pharmacy.com	4	t	2024-01-13 00:20:00-08	2025-11-06 03:15:00-08
550e8400-e29b-41d4-a716-446655440005	elee	Emma Lee	emma.lee@pharmacy.com	2	t	2024-01-14 05:45:00-08	2025-11-03 02:00:00-08
550e8400-e29b-41d4-a716-446655440006	fbrown	Frank Brown	frank.brown@pharmacy.com	5	t	2024-01-15 06:30:00-08	2025-11-02 05:20:00-08
550e8400-e29b-41d4-a716-446655440007	gdavis	Grace Davis	grace.davis@pharmacy.com	3	t	2024-01-16 01:00:00-08	2025-11-06 04:45:00-08
550e8400-e29b-41d4-a716-446655440008	hmartin	Henry Martin	henry.martin@pharmacy.com	6	t	2024-01-17 02:30:00-08	2025-11-01 07:55:00-07
550e8400-e29b-41d4-a716-446655440009	itaylor	Iris Taylor	iris.taylor@pharmacy.com	7	t	2024-01-18 07:15:00-08	2025-11-06 05:20:00-08
550e8400-e29b-41d4-a716-446655440015	oallen	Olivia Allen	olivia.allen@pharmacy.com	3	t	2024-01-24 05:20:00-08	2025-11-04 01:15:00-08
550e8400-e29b-41d4-a716-446655440016	pking	Patrick King	patrick.king@pharmacy.com	4	t	2024-01-25 06:50:00-08	2025-11-06 07:40:00-08
550e8400-e29b-41d4-a716-446655440017	qwrong	Quinn Wright	quinn.wright@pharmacy.com	2	f	2024-01-26 03:30:00-08	2025-08-10 05:00:00-07
550e8400-e29b-41d4-a716-446655440018	rlopez	Rachel Lopez	rachel.lopez@pharmacy.com	3	t	2024-01-27 01:00:00-08	2025-11-03 05:50:00-08
550e8400-e29b-41d4-a716-446655440019	shill	Samuel Hill	samuel.hill@pharmacy.com	5	t	2024-01-28 07:25:00-08	2025-11-06 02:30:00-08
550e8400-e29b-41d4-a716-446655440020	tscott	Tina Scott	tina.scott@pharmacy.com	3	t	2024-01-29 02:10:00-08	2025-11-02 06:15:00-08
550e8400-e29b-41d4-a716-446655440010	jwhite	Jack White	jack.white@pharmacy.com	8	t	2024-01-19 00:40:00-08	2025-11-14 00:00:06.623-08
550e8400-e29b-41d4-a716-446655440011	kharris	Karen Harris	karen.harris@pharmacy.com	3	t	2024-01-20 01:30:00-08	2025-11-14 00:01:15.181-08
550e8400-e29b-41d4-a716-446655440012	lclark	Leo Clark	leo.clark@pharmacy.com	4	t	2024-01-21 04:00:00-08	2025-11-14 00:02:38.21-08
550e8400-e29b-41d4-a716-446655440013	mlewis	Maria Lewis2	maria.lewis@pharmacy.com	3	t	2024-01-22 00:15:00-08	2025-11-14 00:03:26.866-08
550e8400-e29b-41d4-a716-446655440014	nwalker	Nathan Walker	nathan.walker@pharmacy.com	4	t	2024-01-23 02:45:00-08	2025-11-14 00:09:27.162-08
\.


--
-- Data for Name: wholesalers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.wholesalers (id, name, contact, trading_partner_id) FROM stdin;
1	Cardinal Health	{"email": "sales@cardinal.com", "phone": "614-757-5000", "address": "7000 Cardinal Place, Dublin, OH 43017", "contact_person": "John Martinez"}	TP-2024-00001
2	McKesson Corporation	{"email": "wholesale@mckesson.com", "phone": "415-983-8300", "address": "6555 State Route 161, Houston, TX 77024", "contact_person": "Sarah Chen"}	TP-2024-00002
3	AmerisourceBergen	{"email": "partner.services@amerisourcebergen.com", "phone": "610-727-7000", "address": "1300 Morris Drive, Chesterbrook, PA 19087", "contact_person": "Michael Thompson"}	TP-2024-00003
4	Henry Schein	{"email": "wholesale@henryschein.com", "phone": "516-354-3444", "address": "135 Duffy Avenue, Melville, NY 11747", "contact_person": "Emily Rodriguez"}	TP-2024-00004
5	Orsini Specialty Pharmacy	{"email": "sales@orsini.com", "phone": "201-339-6000", "address": "400 Plaza Drive, Secaucus, NJ 07094", "contact_person": "David Lee"}	TP-2024-00005
\.


--
-- Data for Name: workflow_steps; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_steps (id, workflow_id, step_key, display_name, config, queue_name) FROM stdin;
1	1	intake	Prescription Intake	{"auto_assign": false, "sla_minutes": 5, "roles_allowed": ["pharmacy_technician", "pharmacist"]}	\N
2	1	review	Pharmacist Review	{"auto_assign": true, "sla_minutes": 15, "roles_allowed": ["pharmacist"], "requires_verification": true}	\N
3	1	verification	Patient Verification	{"auto_assign": false, "sla_minutes": 10, "roles_allowed": ["pharmacy_technician"]}	\N
4	1	dispensing	Medication Dispensing	{"auto_assign": false, "sla_minutes": 10, "roles_allowed": ["pharmacy_technician"], "requires_barcode_scan": true}	\N
5	1	quality_check	Quality Assurance	{"auto_assign": true, "sla_minutes": 5, "roles_allowed": ["pharmacist", "quality_assurance_specialist"]}	\N
6	1	patient_pickup	Patient Pickup	{"auto_assign": false, "sla_minutes": 5, "roles_allowed": ["pharmacy_technician"]}	\N
7	2	intake	Controlled Substance Intake	{"auto_assign": false, "sla_minutes": 5, "requires_cii": true, "roles_allowed": ["pharmacist"]}	\N
8	2	pdmp_check	PDMP Query	{"automated": true, "auto_assign": true, "sla_minutes": 10, "roles_allowed": ["pharmacist"]}	\N
9	2	pharmacist_review	Pharmacist Review	{"auto_assign": true, "sla_minutes": 15, "roles_allowed": ["pharmacist"]}	\N
10	2	cii_verification	DEA Form 222 Verification	{"auto_assign": false, "sla_minutes": 10, "roles_allowed": ["pharmacist", "compliance_officer"], "requires_documentation": true}	\N
11	2	dispensing	Controlled Substance Dispensing	{"auto_assign": false, "sla_minutes": 10, "roles_allowed": ["pharmacist"], "requires_verification": true}	\N
12	2	record_keeping	Record & Documentation	{"auto_assign": false, "sla_minutes": 10, "roles_allowed": ["pharmacy_technician"]}	\N
13	3	submission	Insurance Submission	{"auto_assign": true, "sla_minutes": 30, "roles_allowed": ["insurance_coordinator", "pharmacy_technician"]}	\N
14	3	tracking	Tracking & Monitoring	{"auto_assign": false, "sla_minutes": 60, "roles_allowed": ["insurance_coordinator"]}	\N
15	3	follow_up	Follow-up Contact	{"auto_assign": false, "sla_minutes": 120, "roles_allowed": ["insurance_coordinator"]}	\N
16	3	approval_received	Approval Processing	{"auto_assign": true, "sla_minutes": 15, "roles_allowed": ["insurance_coordinator", "pharmacist"]}	\N
17	3	prescription_fill	Prescription Fill	{"auto_assign": true, "sla_minutes": 30, "roles_allowed": ["pharmacy_technician"]}	\N
18	4	receiving	Goods Received	{"auto_assign": false, "sla_minutes": 15, "roles_allowed": ["warehouse_staff"]}	\N
19	4	barcode_scan	Barcode Scanning	{"automated": true, "auto_assign": false, "sla_minutes": 20, "roles_allowed": ["warehouse_staff"]}	\N
20	4	lot_verification	Lot Number Verification	{"auto_assign": true, "sla_minutes": 15, "roles_allowed": ["inventory_manager"]}	\N
21	4	dscsa_check	DSCSA Serial Check	{"automated": true, "auto_assign": false, "sla_minutes": 10, "roles_allowed": ["compliance_officer"]}	\N
22	4	shelving	Shelving & Storage	{"auto_assign": false, "sla_minutes": 30, "roles_allowed": ["warehouse_staff"]}	\N
23	4	database_update	Database Update	{"automated": true, "auto_assign": true, "sla_minutes": 10, "roles_allowed": ["inventory_manager"]}	\N
24	5	patient_intake	Patient Information Collection	{"auto_assign": false, "sla_minutes": 5, "roles_allowed": ["pharmacy_technician", "patient_care_specialist"]}	\N
25	5	insurance_lookup	Insurance Lookup	{"automated": true, "auto_assign": true, "sla_minutes": 10, "roles_allowed": ["pharmacy_technician"]}	\N
26	5	coverage_check	Coverage Verification	{"auto_assign": true, "sla_minutes": 5, "roles_allowed": ["billing_specialist"]}	\N
27	5	copay_determination	Copay & Cost Determination	{"auto_assign": true, "sla_minutes": 5, "roles_allowed": ["billing_specialist"]}	\N
28	5	documentation	Documentation	{"auto_assign": false, "sla_minutes": 5, "roles_allowed": ["pharmacy_technician"]}	\N
29	6	refill_request	Refill Request Received	{"auto_assign": false, "sla_minutes": 5, "roles_allowed": ["pharmacy_technician"]}	\N
30	6	validation	Prescription Validation	{"auto_assign": false, "sla_minutes": 10, "roles_allowed": ["pharmacy_technician"]}	\N
31	6	pharmacist_review	Pharmacist Review	{"auto_assign": true, "sla_minutes": 10, "roles_allowed": ["pharmacist"]}	\N
32	6	dispensing	Dispensing	{"auto_assign": true, "sla_minutes": 15, "roles_allowed": ["pharmacy_technician"]}	\N
33	6	notification	Patient Notification	{"auto_assign": false, "sla_minutes": 5, "roles_allowed": ["pharmacy_technician"]}	\N
\.


--
-- Data for Name: workflows; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflows (id, name, description, config, created_by, created_at) FROM stdin;
1	Prescription Review & Dispensing	Standard workflow for reviewing and dispensing prescriptions	{"steps": ["intake", "review", "verification", "dispensing", "quality_check", "patient_pickup"], "parallelization": false, "estimated_time_minutes": 45}	550e8400-e29b-41d4-a716-446655440005	2024-01-01 00:00:00-08
2	Controlled Substance Handling	Special workflow for DEA Schedule II and III medications	{"steps": ["intake", "pdmp_check", "pharmacist_review", "cii_verification", "dispensing", "record_keeping"], "parallelization": false, "requires_cii_form": true, "estimated_time_minutes": 60}	550e8400-e29b-41d4-a716-446655440001	2024-01-01 00:15:00-08
3	Prior Authorization Processing	Workflow for managing prior auth requests with insurance	{"steps": ["submission", "tracking", "follow_up", "approval_received", "prescription_fill"], "sla_hours": 24, "retry_limit": 3, "parallelization": true, "estimated_time_minutes": 120}	550e8400-e29b-41d4-a716-446655440006	2024-01-01 00:30:00-08
4	Inventory Receiving & Verification	Workflow for receiving and verifying pharmaceutical shipments	{"steps": ["receiving", "barcode_scan", "lot_verification", "dscsa_check", "shelving", "database_update"], "parallelization": false, "estimated_time_minutes": 90, "requires_dscsa_verification": true}	550e8400-e29b-41d4-a716-446655440006	2024-01-02 00:00:00-08
5	Patient Insurance Verification	Workflow for verifying patient insurance coverage and benefits	{"steps": ["patient_intake", "insurance_lookup", "coverage_check", "copay_determination", "documentation"], "parallelization": false, "estimated_time_minutes": 15}	550e8400-e29b-41d4-a716-446655440010	2024-01-02 00:15:00-08
6	Refill Processing	Workflow for processing prescription refills	{"steps": ["refill_request", "validation", "pharmacist_review", "dispensing", "patient_notification"], "parallelization": false, "estimated_time_minutes": 20}	550e8400-e29b-41d4-a716-446655440002	2024-01-02 00:30:00-08
7	PDMP Compliance Check	Workflow for PDMP queries and opioid monitoring	{"steps": ["pdmp_query", "result_analysis", "concern_escalation", "documentation", "record_keeping"], "automated": true, "parallelization": false, "estimated_time_minutes": 5}	550e8400-e29b-41d4-a716-446655440008	2024-01-03 00:00:00-08
8	Quality Assurance Review	Workflow for quality checks on filled prescriptions	{"steps": ["prescription_selection", "accuracy_check", "label_verification", "patient_counseling_prep", "final_verification"], "parallelization": false, "estimated_time_minutes": 10}	550e8400-e29b-41d4-a716-446655440001	2024-01-03 00:15:00-08
9	Prescription Transfer Workflow	Workflow for transferring prescriptions to other pharmacies	{"steps": ["transfer_request", "validation", "erx_submission", "confirmation", "record_update"], "parallelization": false, "supports_surescripts": true, "estimated_time_minutes": 15}	550e8400-e29b-41d4-a716-446655440002	2024-01-03 00:30:00-08
10	Billing & Claims Processing	Workflow for processing insurance claims and billing	{"steps": ["claim_generation", "claim_submission", "response_tracking", "adjudication", "payment_posting"], "sla_hours": 72, "parallelization": true, "estimated_time_minutes": 180}	550e8400-e29b-41d4-a716-446655440009	2024-01-04 00:00:00-08
\.


--
-- Name: audit_log_id_seq; Type: SEQUENCE SET; Schema: eam; Owner: postgres
--

SELECT pg_catalog.setval('eam.audit_log_id_seq', 1, false);


--
-- Name: auth_logs_id_seq; Type: SEQUENCE SET; Schema: pharmacy; Owner: postgres
--

SELECT pg_catalog.setval('pharmacy.auth_logs_id_seq', 149, true);


--
-- Name: reorder_rules_id_seq; Type: SEQUENCE SET; Schema: pharmacy; Owner: postgres
--

SELECT pg_catalog.setval('pharmacy.reorder_rules_id_seq', 5, true);


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: pharmacy; Owner: postgres
--

SELECT pg_catalog.setval('pharmacy.roles_id_seq', 10, true);


--
-- Name: stations_id_seq; Type: SEQUENCE SET; Schema: pharmacy; Owner: postgres
--

SELECT pg_catalog.setval('pharmacy.stations_id_seq', 2, true);


--
-- Name: workflow_transitions_id_seq; Type: SEQUENCE SET; Schema: pharmacy; Owner: postgres
--

SELECT pg_catalog.setval('pharmacy.workflow_transitions_id_seq', 27, true);


--
-- Name: access_logs_id_seq; Type: SEQUENCE SET; Schema: pharmacy3; Owner: postgres
--

SELECT pg_catalog.setval('pharmacy3.access_logs_id_seq', 1, true);


--
-- Name: auth_logs_id_seq; Type: SEQUENCE SET; Schema: pharmacy3; Owner: postgres
--

SELECT pg_catalog.setval('pharmacy3.auth_logs_id_seq', 12, true);


--
-- Name: efax_status_logs_id_seq; Type: SEQUENCE SET; Schema: pharmacy3; Owner: postgres
--

SELECT pg_catalog.setval('pharmacy3.efax_status_logs_id_seq', 1, false);


--
-- Name: pharmacy_types_id_seq; Type: SEQUENCE SET; Schema: pharmacy3; Owner: postgres
--

SELECT pg_catalog.setval('pharmacy3.pharmacy_types_id_seq', 13, true);


--
-- Name: reorder_rules_id_seq; Type: SEQUENCE SET; Schema: pharmacy3; Owner: postgres
--

SELECT pg_catalog.setval('pharmacy3.reorder_rules_id_seq', 1, false);


--
-- Name: stations_id_seq; Type: SEQUENCE SET; Schema: pharmacy3; Owner: postgres
--

SELECT pg_catalog.setval('pharmacy3.stations_id_seq', 2, true);


--
-- Name: workflow_transitions_id_seq; Type: SEQUENCE SET; Schema: pharmacy3; Owner: postgres
--

SELECT pg_catalog.setval('pharmacy3.workflow_transitions_id_seq', 58, true);


--
-- Name: access_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.access_logs_id_seq', 30, true);


--
-- Name: alert_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.alert_logs_id_seq', 52, true);


--
-- Name: alert_rules_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.alert_rules_id_seq', 10, true);


--
-- Name: auth_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_logs_id_seq', 455, true);


--
-- Name: awp_reclaims_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.awp_reclaims_id_seq', 5, true);


--
-- Name: device_fingerprints_station_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.device_fingerprints_station_id_seq', 1, false);


--
-- Name: dir_fees_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.dir_fees_id_seq', 50, true);


--
-- Name: efax_status_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.efax_status_logs_id_seq', 1, false);


--
-- Name: encryption_keys_meta_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.encryption_keys_meta_id_seq', 1, false);


--
-- Name: fingerprint_history_station_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.fingerprint_history_station_id_seq', 1, false);


--
-- Name: integrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.integrations_id_seq', 1, false);


--
-- Name: patient_aliases_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.patient_aliases_id_seq', 20, true);


--
-- Name: prescription_audit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.prescription_audit_id_seq', 43, true);


--
-- Name: prescription_workflow_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.prescription_workflow_logs_id_seq', 15, true);


--
-- Name: profit_audit_warnings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.profit_audit_warnings_id_seq', 8, true);


--
-- Name: queues_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.queues_id_seq', 1, false);


--
-- Name: reorder_rules_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reorder_rules_id_seq', 1, false);


--
-- Name: role_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.role_permissions_id_seq', 1, false);


--
-- Name: role_permissions_role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.role_permissions_role_id_seq', 1, false);


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.roles_id_seq', 1, false);


--
-- Name: stations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.stations_id_seq', 5, true);


--
-- Name: task_routing_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.task_routing_id_seq', 1, false);


--
-- Name: user_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_permissions_id_seq', 18, true);


--
-- Name: wholesalers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.wholesalers_id_seq', 1, false);


--
-- Name: workflow_steps_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.workflow_steps_id_seq', 1, false);


--
-- Name: workflows_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.workflows_id_seq', 1, false);


--
-- Name: asset_meters asset_meters_pkey; Type: CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.asset_meters
    ADD CONSTRAINT asset_meters_pkey PRIMARY KEY (id);


--
-- Name: asset_types asset_types_name_key; Type: CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.asset_types
    ADD CONSTRAINT asset_types_name_key UNIQUE (name);


--
-- Name: asset_types asset_types_pkey; Type: CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.asset_types
    ADD CONSTRAINT asset_types_pkey PRIMARY KEY (id);


--
-- Name: assets assets_code_key; Type: CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.assets
    ADD CONSTRAINT assets_code_key UNIQUE (code);


--
-- Name: assets assets_pkey; Type: CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.assets
    ADD CONSTRAINT assets_pkey PRIMARY KEY (id);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: inventory_transactions inventory_transactions_pkey; Type: CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.inventory_transactions
    ADD CONSTRAINT inventory_transactions_pkey PRIMARY KEY (id);


--
-- Name: maintenance_plans maintenance_plans_pkey; Type: CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.maintenance_plans
    ADD CONSTRAINT maintenance_plans_pkey PRIMARY KEY (id);


--
-- Name: maintenance_triggers maintenance_triggers_pkey; Type: CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.maintenance_triggers
    ADD CONSTRAINT maintenance_triggers_pkey PRIMARY KEY (id);


--
-- Name: meter_readings meter_readings_pkey; Type: CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.meter_readings
    ADD CONSTRAINT meter_readings_pkey PRIMARY KEY (id);


--
-- Name: outbox_events outbox_events_pkey; Type: CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.outbox_events
    ADD CONSTRAINT outbox_events_pkey PRIMARY KEY (id);


--
-- Name: parts parts_pkey; Type: CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.parts
    ADD CONSTRAINT parts_pkey PRIMARY KEY (id);


--
-- Name: parts parts_sku_key; Type: CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.parts
    ADD CONSTRAINT parts_sku_key UNIQUE (sku);


--
-- Name: stock_locations stock_locations_pkey; Type: CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.stock_locations
    ADD CONSTRAINT stock_locations_pkey PRIMARY KEY (id);


--
-- Name: technicians technicians_email_key; Type: CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.technicians
    ADD CONSTRAINT technicians_email_key UNIQUE (email);


--
-- Name: technicians technicians_pkey; Type: CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.technicians
    ADD CONSTRAINT technicians_pkey PRIMARY KEY (id);


--
-- Name: vendors vendors_name_key; Type: CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.vendors
    ADD CONSTRAINT vendors_name_key UNIQUE (name);


--
-- Name: vendors vendors_pkey; Type: CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.vendors
    ADD CONSTRAINT vendors_pkey PRIMARY KEY (id);


--
-- Name: work_order_labor work_order_labor_pkey; Type: CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.work_order_labor
    ADD CONSTRAINT work_order_labor_pkey PRIMARY KEY (id);


--
-- Name: work_order_parts work_order_parts_pkey; Type: CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.work_order_parts
    ADD CONSTRAINT work_order_parts_pkey PRIMARY KEY (id);


--
-- Name: work_order_tasks work_order_tasks_pkey; Type: CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.work_order_tasks
    ADD CONSTRAINT work_order_tasks_pkey PRIMARY KEY (id);


--
-- Name: work_orders work_orders_pkey; Type: CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.work_orders
    ADD CONSTRAINT work_orders_pkey PRIMARY KEY (id);


--
-- Name: applied_learning_experiences applied_learning_experiences_pkey; Type: CONSTRAINT; Schema: learningsystem; Owner: postgres
--

ALTER TABLE ONLY learningsystem.applied_learning_experiences
    ADD CONSTRAINT applied_learning_experiences_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: learningsystem; Owner: postgres
--

ALTER TABLE ONLY learningsystem.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: employer_profiles employer_profiles_pkey; Type: CONSTRAINT; Schema: learningsystem; Owner: postgres
--

ALTER TABLE ONLY learningsystem.employer_profiles
    ADD CONSTRAINT employer_profiles_pkey PRIMARY KEY (user_id);


--
-- Name: event_registrations event_registrations_pkey; Type: CONSTRAINT; Schema: learningsystem; Owner: postgres
--

ALTER TABLE ONLY learningsystem.event_registrations
    ADD CONSTRAINT event_registrations_pkey PRIMARY KEY (event_id, user_id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: learningsystem; Owner: postgres
--

ALTER TABLE ONLY learningsystem.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: job_postings job_postings_pkey; Type: CONSTRAINT; Schema: learningsystem; Owner: postgres
--

ALTER TABLE ONLY learningsystem.job_postings
    ADD CONSTRAINT job_postings_pkey PRIMARY KEY (id);


--
-- Name: student_profiles student_profiles_pkey; Type: CONSTRAINT; Schema: learningsystem; Owner: postgres
--

ALTER TABLE ONLY learningsystem.student_profiles
    ADD CONSTRAINT student_profiles_pkey PRIMARY KEY (user_id);


--
-- Name: system_configs system_configs_pkey; Type: CONSTRAINT; Schema: learningsystem; Owner: postgres
--

ALTER TABLE ONLY learningsystem.system_configs
    ADD CONSTRAINT system_configs_pkey PRIMARY KEY (config_key);


--
-- Name: users users_banner_id_key; Type: CONSTRAINT; Schema: learningsystem; Owner: postgres
--

ALTER TABLE ONLY learningsystem.users
    ADD CONSTRAINT users_banner_id_key UNIQUE (banner_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: learningsystem; Owner: postgres
--

ALTER TABLE ONLY learningsystem.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_okta_id_key; Type: CONSTRAINT; Schema: learningsystem; Owner: postgres
--

ALTER TABLE ONLY learningsystem.users
    ADD CONSTRAINT users_okta_id_key UNIQUE (okta_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: learningsystem; Owner: postgres
--

ALTER TABLE ONLY learningsystem.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: volunteer_logs volunteer_logs_pkey; Type: CONSTRAINT; Schema: learningsystem; Owner: postgres
--

ALTER TABLE ONLY learningsystem.volunteer_logs
    ADD CONSTRAINT volunteer_logs_pkey PRIMARY KEY (id);


--
-- Name: workflows workflows_pkey; Type: CONSTRAINT; Schema: learningsystem; Owner: postgres
--

ALTER TABLE ONLY learningsystem.workflows
    ADD CONSTRAINT workflows_pkey PRIMARY KEY (id);


--
-- Name: auth_logs auth_logs_pkey; Type: CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.auth_logs
    ADD CONSTRAINT auth_logs_pkey PRIMARY KEY (id);


--
-- Name: device_fingerprints device_fingerprints_fingerprint_hash_key; Type: CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.device_fingerprints
    ADD CONSTRAINT device_fingerprints_fingerprint_hash_key UNIQUE (fingerprint_hash);


--
-- Name: device_fingerprints device_fingerprints_pkey; Type: CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.device_fingerprints
    ADD CONSTRAINT device_fingerprints_pkey PRIMARY KEY (id);


--
-- Name: insurance_plans insurance_plans_pkey; Type: CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.insurance_plans
    ADD CONSTRAINT insurance_plans_pkey PRIMARY KEY (id);


--
-- Name: inventory_items inventory_items_ndc_key; Type: CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.inventory_items
    ADD CONSTRAINT inventory_items_ndc_key UNIQUE (ndc);


--
-- Name: inventory_items inventory_items_pkey; Type: CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.inventory_items
    ADD CONSTRAINT inventory_items_pkey PRIMARY KEY (id);


--
-- Name: patient_insurances patient_insurances_pkey; Type: CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.patient_insurances
    ADD CONSTRAINT patient_insurances_pkey PRIMARY KEY (id);


--
-- Name: patients patients_pkey; Type: CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.patients
    ADD CONSTRAINT patients_pkey PRIMARY KEY (id);


--
-- Name: prescribers prescribers_npi_key; Type: CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.prescribers
    ADD CONSTRAINT prescribers_npi_key UNIQUE (npi);


--
-- Name: prescribers prescribers_pkey; Type: CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.prescribers
    ADD CONSTRAINT prescribers_pkey PRIMARY KEY (id);


--
-- Name: prescription_queue prescription_queue_pkey; Type: CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.prescription_queue
    ADD CONSTRAINT prescription_queue_pkey PRIMARY KEY (id);


--
-- Name: prescription_workflow_events prescription_workflow_events_pkey; Type: CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.prescription_workflow_events
    ADD CONSTRAINT prescription_workflow_events_pkey PRIMARY KEY (id);


--
-- Name: prescriptions prescriptions_pkey; Type: CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.prescriptions
    ADD CONSTRAINT prescriptions_pkey PRIMARY KEY (id);


--
-- Name: reorder_rules reorder_rules_pkey; Type: CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.reorder_rules
    ADD CONSTRAINT reorder_rules_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: roles roles_role_name_key; Type: CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.roles
    ADD CONSTRAINT roles_role_name_key UNIQUE (role_name);


--
-- Name: stations stations_pkey; Type: CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.stations
    ADD CONSTRAINT stations_pkey PRIMARY KEY (id);


--
-- Name: stations unique_station_config; Type: CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.stations
    ADD CONSTRAINT unique_station_config UNIQUE (station_prefix, department, location);


--
-- Name: device_fingerprints unique_station_device; Type: CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.device_fingerprints
    ADD CONSTRAINT unique_station_device UNIQUE (station_id);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (user_id, role_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: workflow_statuses workflow_statuses_pkey; Type: CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.workflow_statuses
    ADD CONSTRAINT workflow_statuses_pkey PRIMARY KEY (status_code);


--
-- Name: workflow_steps workflow_steps_pkey; Type: CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.workflow_steps
    ADD CONSTRAINT workflow_steps_pkey PRIMARY KEY (step_code);


--
-- Name: workflow_transitions workflow_transitions_pkey; Type: CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.workflow_transitions
    ADD CONSTRAINT workflow_transitions_pkey PRIMARY KEY (id);


--
-- Name: access_logs access_logs_pkey; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.access_logs
    ADD CONSTRAINT access_logs_pkey PRIMARY KEY (id);


--
-- Name: auth_logs auth_logs_pkey; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.auth_logs
    ADD CONSTRAINT auth_logs_pkey PRIMARY KEY (id);


--
-- Name: claim_transactions claim_transactions_pkey; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.claim_transactions
    ADD CONSTRAINT claim_transactions_pkey PRIMARY KEY (id);


--
-- Name: claims claims_pkey; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.claims
    ADD CONSTRAINT claims_pkey PRIMARY KEY (id);


--
-- Name: documents documents_pkey; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.documents
    ADD CONSTRAINT documents_pkey PRIMARY KEY (id);


--
-- Name: efax_incoming efax_incoming_pkey; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.efax_incoming
    ADD CONSTRAINT efax_incoming_pkey PRIMARY KEY (id);


--
-- Name: efax_jobs efax_jobs_pkey; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.efax_jobs
    ADD CONSTRAINT efax_jobs_pkey PRIMARY KEY (id);


--
-- Name: efax_recipients efax_recipients_fax_number_key; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.efax_recipients
    ADD CONSTRAINT efax_recipients_fax_number_key UNIQUE (fax_number);


--
-- Name: efax_recipients efax_recipients_pkey; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.efax_recipients
    ADD CONSTRAINT efax_recipients_pkey PRIMARY KEY (id);


--
-- Name: efax_status_logs efax_status_logs_pkey; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.efax_status_logs
    ADD CONSTRAINT efax_status_logs_pkey PRIMARY KEY (id);


--
-- Name: insurance_companies insurance_companies_pkey; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.insurance_companies
    ADD CONSTRAINT insurance_companies_pkey PRIMARY KEY (id);


--
-- Name: insurance_plans insurance_plans_pkey; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.insurance_plans
    ADD CONSTRAINT insurance_plans_pkey PRIMARY KEY (id);


--
-- Name: inventory_items inventory_items_ndc_key; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.inventory_items
    ADD CONSTRAINT inventory_items_ndc_key UNIQUE (ndc);


--
-- Name: inventory_items inventory_items_pkey; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.inventory_items
    ADD CONSTRAINT inventory_items_pkey PRIMARY KEY (id);


--
-- Name: patient_insurances patient_insurances_pkey; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.patient_insurances
    ADD CONSTRAINT patient_insurances_pkey PRIMARY KEY (id);


--
-- Name: patients patients_pkey; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.patients
    ADD CONSTRAINT patients_pkey PRIMARY KEY (id);


--
-- Name: pharmacist_note_addendums pharmacist_note_addendums_pkey; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.pharmacist_note_addendums
    ADD CONSTRAINT pharmacist_note_addendums_pkey PRIMARY KEY (id);


--
-- Name: pharmacist_notes pharmacist_notes_pkey; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.pharmacist_notes
    ADD CONSTRAINT pharmacist_notes_pkey PRIMARY KEY (id);


--
-- Name: pharmacy_types pharmacy_types_pkey; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.pharmacy_types
    ADD CONSTRAINT pharmacy_types_pkey PRIMARY KEY (id);


--
-- Name: pharmacy_types pharmacy_types_taxonomy_code_key; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.pharmacy_types
    ADD CONSTRAINT pharmacy_types_taxonomy_code_key UNIQUE (taxonomy_code);


--
-- Name: prescribers prescribers_npi_key; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.prescribers
    ADD CONSTRAINT prescribers_npi_key UNIQUE (npi);


--
-- Name: prescribers prescribers_pkey; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.prescribers
    ADD CONSTRAINT prescribers_pkey PRIMARY KEY (id);


--
-- Name: prescription_items prescription_items_pkey; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.prescription_items
    ADD CONSTRAINT prescription_items_pkey PRIMARY KEY (id);


--
-- Name: prescription_queue prescription_queue_pkey; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.prescription_queue
    ADD CONSTRAINT prescription_queue_pkey PRIMARY KEY (id);


--
-- Name: prescription_workflow_events prescription_workflow_events_pkey; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.prescription_workflow_events
    ADD CONSTRAINT prescription_workflow_events_pkey PRIMARY KEY (id);


--
-- Name: prescriptions prescriptions_pkey; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.prescriptions
    ADD CONSTRAINT prescriptions_pkey PRIMARY KEY (id);


--
-- Name: reorder_rules reorder_rules_pkey; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.reorder_rules
    ADD CONSTRAINT reorder_rules_pkey PRIMARY KEY (id);


--
-- Name: stations stations_pkey; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.stations
    ADD CONSTRAINT stations_pkey PRIMARY KEY (id);


--
-- Name: workflow_statuses status_code_unique; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.workflow_statuses
    ADD CONSTRAINT status_code_unique UNIQUE (status_code);


--
-- Name: workflow_steps step_code_unique; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.workflow_steps
    ADD CONSTRAINT step_code_unique UNIQUE (step_code);


--
-- Name: stations unique_station_config; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.stations
    ADD CONSTRAINT unique_station_config UNIQUE (station_prefix, department, location);


--
-- Name: users users_id_unique; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.users
    ADD CONSTRAINT users_id_unique UNIQUE (id);


--
-- Name: workflow_transitions workflow_transitions_pkey; Type: CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.workflow_transitions
    ADD CONSTRAINT workflow_transitions_pkey PRIMARY KEY (id);


--
-- Name: access_logs access_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.access_logs
    ADD CONSTRAINT access_logs_pkey PRIMARY KEY (id);


--
-- Name: alert_logs alert_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_logs
    ADD CONSTRAINT alert_logs_pkey PRIMARY KEY (id);


--
-- Name: alert_rules alert_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_rules
    ADD CONSTRAINT alert_rules_pkey PRIMARY KEY (id);


--
-- Name: auth_logs auth_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_logs
    ADD CONSTRAINT auth_logs_pkey PRIMARY KEY (id);


--
-- Name: awp_reclaims awp_reclaims_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.awp_reclaims
    ADD CONSTRAINT awp_reclaims_pkey PRIMARY KEY (id);


--
-- Name: barcode_labels barcode_labels_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.barcode_labels
    ADD CONSTRAINT barcode_labels_pkey PRIMARY KEY (id);


--
-- Name: claims claims_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.claims
    ADD CONSTRAINT claims_pkey PRIMARY KEY (id);


--
-- Name: consent_records consent_records_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.consent_records
    ADD CONSTRAINT consent_records_pkey PRIMARY KEY (id);


--
-- Name: device_fingerprints device_fingerprints_fingerprint_hash_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_fingerprints
    ADD CONSTRAINT device_fingerprints_fingerprint_hash_key UNIQUE (fingerprint_hash);


--
-- Name: device_fingerprints device_fingerprints_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_fingerprints
    ADD CONSTRAINT device_fingerprints_pkey PRIMARY KEY (id);


--
-- Name: dir_fees dir_fees_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dir_fees
    ADD CONSTRAINT dir_fees_pkey PRIMARY KEY (id);


--
-- Name: dscsa_serials dscsa_serials_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dscsa_serials
    ADD CONSTRAINT dscsa_serials_pkey PRIMARY KEY (id);


--
-- Name: efax_attachments efax_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.efax_attachments
    ADD CONSTRAINT efax_attachments_pkey PRIMARY KEY (id);


--
-- Name: efax_incoming efax_incoming_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.efax_incoming
    ADD CONSTRAINT efax_incoming_pkey PRIMARY KEY (id);


--
-- Name: efax_jobs efax_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.efax_jobs
    ADD CONSTRAINT efax_jobs_pkey PRIMARY KEY (id);


--
-- Name: efax_recipients efax_recipients_fax_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.efax_recipients
    ADD CONSTRAINT efax_recipients_fax_number_key UNIQUE (fax_number);


--
-- Name: efax_recipients efax_recipients_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.efax_recipients
    ADD CONSTRAINT efax_recipients_pkey PRIMARY KEY (id);


--
-- Name: efax_status_logs efax_status_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.efax_status_logs
    ADD CONSTRAINT efax_status_logs_pkey PRIMARY KEY (id);


--
-- Name: encryption_keys_meta encryption_keys_meta_key_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.encryption_keys_meta
    ADD CONSTRAINT encryption_keys_meta_key_id_key UNIQUE (key_id);


--
-- Name: encryption_keys_meta encryption_keys_meta_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.encryption_keys_meta
    ADD CONSTRAINT encryption_keys_meta_pkey PRIMARY KEY (id);


--
-- Name: fingerprint_history fingerprint_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fingerprint_history
    ADD CONSTRAINT fingerprint_history_pkey PRIMARY KEY (id);


--
-- Name: insurance_companies insurance_companies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insurance_companies
    ADD CONSTRAINT insurance_companies_pkey PRIMARY KEY (id);


--
-- Name: integration_events integration_events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.integration_events
    ADD CONSTRAINT integration_events_pkey PRIMARY KEY (id);


--
-- Name: integrations integrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.integrations
    ADD CONSTRAINT integrations_pkey PRIMARY KEY (id);


--
-- Name: inventory_batches inventory_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventory_batches
    ADD CONSTRAINT inventory_batches_pkey PRIMARY KEY (id);


--
-- Name: inventory_items inventory_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT inventory_items_pkey PRIMARY KEY (id);


--
-- Name: patient_aliases patient_aliases_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_aliases
    ADD CONSTRAINT patient_aliases_pkey PRIMARY KEY (id);


--
-- Name: patient_insurances patient_insurances_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_insurances
    ADD CONSTRAINT patient_insurances_pkey PRIMARY KEY (id);


--
-- Name: patients patients_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patients
    ADD CONSTRAINT patients_pkey PRIMARY KEY (id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: pdmp_queries pdmp_queries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pdmp_queries
    ADD CONSTRAINT pdmp_queries_pkey PRIMARY KEY (id);


--
-- Name: pharmacists pharmacists_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pharmacists
    ADD CONSTRAINT pharmacists_pkey PRIMARY KEY (id);


--
-- Name: pharmacists pharmacists_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pharmacists
    ADD CONSTRAINT pharmacists_user_id_key UNIQUE (user_id);


--
-- Name: pos_signatures pos_signatures_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pos_signatures
    ADD CONSTRAINT pos_signatures_pkey PRIMARY KEY (id);


--
-- Name: pos_transactions pos_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pos_transactions
    ADD CONSTRAINT pos_transactions_pkey PRIMARY KEY (id);


--
-- Name: prescription_audit prescription_audit_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prescription_audit
    ADD CONSTRAINT prescription_audit_pkey PRIMARY KEY (id);


--
-- Name: prescription_claims prescription_claims_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prescription_claims
    ADD CONSTRAINT prescription_claims_pkey PRIMARY KEY (id);


--
-- Name: prescription_copays prescription_copays_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prescription_copays
    ADD CONSTRAINT prescription_copays_pkey PRIMARY KEY (id);


--
-- Name: prescription_items prescription_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prescription_items
    ADD CONSTRAINT prescription_items_pkey PRIMARY KEY (id);


--
-- Name: prescription_transfers prescription_transfers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prescription_transfers
    ADD CONSTRAINT prescription_transfers_pkey PRIMARY KEY (id);


--
-- Name: prescription_workflow_logs prescription_workflow_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prescription_workflow_logs
    ADD CONSTRAINT prescription_workflow_logs_pkey PRIMARY KEY (id);


--
-- Name: prescriptions prescriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prescriptions
    ADD CONSTRAINT prescriptions_pkey PRIMARY KEY (id);


--
-- Name: profit_audit_warnings profit_audit_warnings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profit_audit_warnings
    ADD CONSTRAINT profit_audit_warnings_pkey PRIMARY KEY (id);


--
-- Name: purchase_orders purchase_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT purchase_orders_pkey PRIMARY KEY (id);


--
-- Name: queues queues_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.queues
    ADD CONSTRAINT queues_pkey PRIMARY KEY (id);


--
-- Name: reorder_rules reorder_rules_inventory_item_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reorder_rules
    ADD CONSTRAINT reorder_rules_inventory_item_id_key UNIQUE (inventory_item_id);


--
-- Name: reorder_rules reorder_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reorder_rules
    ADD CONSTRAINT reorder_rules_pkey PRIMARY KEY (id);


--
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- Name: role_permissions role_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (id);


--
-- Name: roles roles_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: stations stations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stations
    ADD CONSTRAINT stations_pkey PRIMARY KEY (id);


--
-- Name: task_routing task_routing_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_routing
    ADD CONSTRAINT task_routing_pkey PRIMARY KEY (id);


--
-- Name: tasks tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);


--
-- Name: stations unique_station_config; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stations
    ADD CONSTRAINT unique_station_config UNIQUE (station_prefix, department, location);


--
-- Name: user_permissions user_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_permissions
    ADD CONSTRAINT user_permissions_pkey PRIMARY KEY (id);


--
-- Name: user_sso user_sso_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_sso
    ADD CONSTRAINT user_sso_pkey PRIMARY KEY (id);


--
-- Name: user_sso user_sso_provider_external_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_sso
    ADD CONSTRAINT user_sso_provider_external_id_key UNIQUE (provider, external_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: wholesalers wholesalers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wholesalers
    ADD CONSTRAINT wholesalers_pkey PRIMARY KEY (id);


--
-- Name: workflow_steps workflow_steps_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_steps
    ADD CONSTRAINT workflow_steps_pkey PRIMARY KEY (id);


--
-- Name: workflows workflows_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflows
    ADD CONSTRAINT workflows_pkey PRIMARY KEY (id);


--
-- Name: outbox_events_aggregate_type_aggregate_id_idx; Type: INDEX; Schema: eam; Owner: postgres
--

CREATE INDEX outbox_events_aggregate_type_aggregate_id_idx ON eam.outbox_events USING btree (aggregate_type, aggregate_id);


--
-- Name: idx_audit_logs_created_at; Type: INDEX; Schema: learningsystem; Owner: postgres
--

CREATE INDEX idx_audit_logs_created_at ON learningsystem.audit_logs USING btree (created_at DESC);


--
-- Name: idx_audit_logs_target_type; Type: INDEX; Schema: learningsystem; Owner: postgres
--

CREATE INDEX idx_audit_logs_target_type ON learningsystem.audit_logs USING btree (target_type);


--
-- Name: idx_experiences_jsonb_data; Type: INDEX; Schema: learningsystem; Owner: postgres
--

CREATE INDEX idx_experiences_jsonb_data ON learningsystem.applied_learning_experiences USING gin (type_specific_data);


--
-- Name: idx_user_banner_id; Type: INDEX; Schema: learningsystem; Owner: postgres
--

CREATE UNIQUE INDEX idx_user_banner_id ON learningsystem.users USING btree (banner_id) WHERE (banner_id IS NOT NULL);


--
-- Name: idx_user_okta_id; Type: INDEX; Schema: learningsystem; Owner: postgres
--

CREATE UNIQUE INDEX idx_user_okta_id ON learningsystem.users USING btree (okta_id) WHERE (okta_id IS NOT NULL);


--
-- Name: idx_auth_logs_created_at; Type: INDEX; Schema: pharmacy; Owner: postgres
--

CREATE INDEX idx_auth_logs_created_at ON pharmacy.auth_logs USING btree (created_at);


--
-- Name: idx_auth_logs_event_type; Type: INDEX; Schema: pharmacy; Owner: postgres
--

CREATE INDEX idx_auth_logs_event_type ON pharmacy.auth_logs USING btree (event_type);


--
-- Name: idx_auth_logs_status; Type: INDEX; Schema: pharmacy; Owner: postgres
--

CREATE INDEX idx_auth_logs_status ON pharmacy.auth_logs USING btree (status);


--
-- Name: idx_auth_logs_user_id; Type: INDEX; Schema: pharmacy; Owner: postgres
--

CREATE INDEX idx_auth_logs_user_id ON pharmacy.auth_logs USING btree (user_id);


--
-- Name: idx_auth_logs_username; Type: INDEX; Schema: pharmacy; Owner: postgres
--

CREATE INDEX idx_auth_logs_username ON pharmacy.auth_logs USING btree (username);


--
-- Name: idx_device_fingerprints_hash; Type: INDEX; Schema: pharmacy; Owner: postgres
--

CREATE INDEX idx_device_fingerprints_hash ON pharmacy.device_fingerprints USING btree (fingerprint_hash);


--
-- Name: idx_access_logs_entity; Type: INDEX; Schema: pharmacy3; Owner: postgres
--

CREATE INDEX idx_access_logs_entity ON pharmacy3.access_logs USING btree (entity_type, entity_id);


--
-- Name: idx_access_logs_patient; Type: INDEX; Schema: pharmacy3; Owner: postgres
--

CREATE INDEX idx_access_logs_patient ON pharmacy3.access_logs USING btree (patient_id);


--
-- Name: idx_access_logs_time; Type: INDEX; Schema: pharmacy3; Owner: postgres
--

CREATE INDEX idx_access_logs_time ON pharmacy3.access_logs USING btree (accessed_at);


--
-- Name: idx_access_logs_user; Type: INDEX; Schema: pharmacy3; Owner: postgres
--

CREATE INDEX idx_access_logs_user ON pharmacy3.access_logs USING btree (user_id);


--
-- Name: idx_auth_logs_created_at; Type: INDEX; Schema: pharmacy3; Owner: postgres
--

CREATE INDEX idx_auth_logs_created_at ON pharmacy3.auth_logs USING btree (created_at);


--
-- Name: idx_auth_logs_event_type; Type: INDEX; Schema: pharmacy3; Owner: postgres
--

CREATE INDEX idx_auth_logs_event_type ON pharmacy3.auth_logs USING btree (event_type);


--
-- Name: idx_auth_logs_status; Type: INDEX; Schema: pharmacy3; Owner: postgres
--

CREATE INDEX idx_auth_logs_status ON pharmacy3.auth_logs USING btree (status);


--
-- Name: idx_auth_logs_user_id; Type: INDEX; Schema: pharmacy3; Owner: postgres
--

CREATE INDEX idx_auth_logs_user_id ON pharmacy3.auth_logs USING btree (user_id);


--
-- Name: idx_auth_logs_username; Type: INDEX; Schema: pharmacy3; Owner: postgres
--

CREATE INDEX idx_auth_logs_username ON pharmacy3.auth_logs USING btree (username);


--
-- Name: idx_efax_incoming_received_at; Type: INDEX; Schema: pharmacy3; Owner: postgres
--

CREATE INDEX idx_efax_incoming_received_at ON pharmacy3.efax_incoming USING btree (received_at);


--
-- Name: idx_efax_jobs_created_at; Type: INDEX; Schema: pharmacy3; Owner: postgres
--

CREATE INDEX idx_efax_jobs_created_at ON pharmacy3.efax_jobs USING btree (created_at);


--
-- Name: idx_efax_jobs_patient; Type: INDEX; Schema: pharmacy3; Owner: postgres
--

CREATE INDEX idx_efax_jobs_patient ON pharmacy3.efax_jobs USING btree (patient_id);


--
-- Name: idx_efax_jobs_prescription; Type: INDEX; Schema: pharmacy3; Owner: postgres
--

CREATE INDEX idx_efax_jobs_prescription ON pharmacy3.efax_jobs USING btree (prescription_id);


--
-- Name: idx_efax_jobs_status; Type: INDEX; Schema: pharmacy3; Owner: postgres
--

CREATE INDEX idx_efax_jobs_status ON pharmacy3.efax_jobs USING btree (status);


--
-- Name: idx_efax_recipients_fax_number; Type: INDEX; Schema: pharmacy3; Owner: postgres
--

CREATE INDEX idx_efax_recipients_fax_number ON pharmacy3.efax_recipients USING btree (fax_number);


--
-- Name: idx_efax_status_logs_job; Type: INDEX; Schema: pharmacy3; Owner: postgres
--

CREATE INDEX idx_efax_status_logs_job ON pharmacy3.efax_status_logs USING btree (efax_job_id);


--
-- Name: idx_efax_status_logs_status; Type: INDEX; Schema: pharmacy3; Owner: postgres
--

CREATE INDEX idx_efax_status_logs_status ON pharmacy3.efax_status_logs USING btree (status);


--
-- Name: idx_pharmacist_notes_actor; Type: INDEX; Schema: pharmacy3; Owner: postgres
--

CREATE INDEX idx_pharmacist_notes_actor ON pharmacy3.pharmacist_notes USING btree (actor_user_id);


--
-- Name: idx_pharmacist_notes_prescription; Type: INDEX; Schema: pharmacy3; Owner: postgres
--

CREATE INDEX idx_pharmacist_notes_prescription ON pharmacy3.pharmacist_notes USING btree (prescription_id);


--
-- Name: idx_pharmacy_types_code; Type: INDEX; Schema: pharmacy3; Owner: postgres
--

CREATE INDEX idx_pharmacy_types_code ON pharmacy3.pharmacy_types USING btree (taxonomy_code);


--
-- Name: idx_pharmacy_types_name; Type: INDEX; Schema: pharmacy3; Owner: postgres
--

CREATE INDEX idx_pharmacy_types_name ON pharmacy3.pharmacy_types USING btree (pharmacy_type_name);


--
-- Name: idx_access_logs_entity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_access_logs_entity ON public.access_logs USING btree (entity_type, entity_id);


--
-- Name: idx_access_logs_patient; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_access_logs_patient ON public.access_logs USING btree (patient_id);


--
-- Name: idx_access_logs_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_access_logs_time ON public.access_logs USING btree (accessed_at);


--
-- Name: idx_access_logs_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_access_logs_user ON public.access_logs USING btree (user_id);


--
-- Name: idx_dir_fees_claim_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_dir_fees_claim_id ON public.dir_fees USING btree (claim_id);


--
-- Name: idx_dir_fees_reconciliation_period; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_dir_fees_reconciliation_period ON public.dir_fees USING btree (reconciliation_period);


--
-- Name: idx_dir_fees_recorded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_dir_fees_recorded_at ON public.dir_fees USING btree (recorded_at);


--
-- Name: idx_efax_attachments_job; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_efax_attachments_job ON public.efax_attachments USING btree (efax_job_id);


--
-- Name: idx_efax_incoming_received_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_efax_incoming_received_at ON public.efax_incoming USING btree (received_at);


--
-- Name: idx_efax_jobs_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_efax_jobs_created_at ON public.efax_jobs USING btree (created_at);


--
-- Name: idx_efax_jobs_patient; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_efax_jobs_patient ON public.efax_jobs USING btree (patient_id);


--
-- Name: idx_efax_jobs_prescription; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_efax_jobs_prescription ON public.efax_jobs USING btree (prescription_id);


--
-- Name: idx_efax_jobs_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_efax_jobs_status ON public.efax_jobs USING btree (status);


--
-- Name: idx_efax_recipients_fax_number; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_efax_recipients_fax_number ON public.efax_recipients USING btree (fax_number);


--
-- Name: idx_efax_status_logs_job; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_efax_status_logs_job ON public.efax_status_logs USING btree (efax_job_id);


--
-- Name: idx_efax_status_logs_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_efax_status_logs_status ON public.efax_status_logs USING btree (status);


--
-- Name: idx_insurance_companies_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_insurance_companies_name ON public.insurance_companies USING btree (name);


--
-- Name: idx_patient_insurances_company; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_patient_insurances_company ON public.patient_insurances USING btree (insurance_company_id);


--
-- Name: idx_patient_insurances_patient; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_patient_insurances_patient ON public.patient_insurances USING btree (patient_id);


--
-- Name: idx_patients_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_patients_name ON public.patients USING btree (last_name, first_name);


--
-- Name: idx_pdmp_queries_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pdmp_queries_created_at ON public.pdmp_queries USING btree (created_at);


--
-- Name: idx_pdmp_queries_patient; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pdmp_queries_patient ON public.pdmp_queries USING btree (patient_id);


--
-- Name: idx_pdmp_queries_state_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pdmp_queries_state_status ON public.pdmp_queries USING btree (state, status);


--
-- Name: idx_pdmp_queries_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pdmp_queries_user ON public.pdmp_queries USING btree (user_id);


--
-- Name: idx_prescription_audit_presc; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_prescription_audit_presc ON public.prescription_audit USING btree (prescription_id);


--
-- Name: idx_prescription_claims_prescription; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_prescription_claims_prescription ON public.prescription_claims USING btree (prescription_id);


--
-- Name: idx_prescription_claims_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_prescription_claims_status ON public.prescription_claims USING btree (claim_status);


--
-- Name: idx_workflow_logs_changed_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_workflow_logs_changed_at ON public.prescription_workflow_logs USING btree (changed_at);


--
-- Name: idx_workflow_logs_prescription; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_workflow_logs_prescription ON public.prescription_workflow_logs USING btree (prescription_id);


--
-- Name: idx_workflow_logs_to_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_workflow_logs_to_status ON public.prescription_workflow_logs USING btree (to_status);


--
-- Name: uq_barcode_labels_barcode; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_barcode_labels_barcode ON public.barcode_labels USING btree (barcode);


--
-- Name: uq_dscsa_serial_unique; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_dscsa_serial_unique ON public.dscsa_serials USING btree (serial_number);


--
-- Name: patients trg_patients_updated; Type: TRIGGER; Schema: pharmacy; Owner: postgres
--

CREATE TRIGGER trg_patients_updated BEFORE UPDATE ON pharmacy.patients FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();


--
-- Name: efax_jobs trg_efax_audit; Type: TRIGGER; Schema: pharmacy3; Owner: postgres
--

CREATE TRIGGER trg_efax_audit AFTER INSERT ON pharmacy3.efax_jobs FOR EACH ROW EXECUTE FUNCTION public.log_efax_access();


--
-- Name: patients trg_patients_updated; Type: TRIGGER; Schema: pharmacy3; Owner: postgres
--

CREATE TRIGGER trg_patients_updated BEFORE UPDATE ON pharmacy3.patients FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();


--
-- Name: efax_jobs trg_efax_audit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_efax_audit AFTER INSERT ON public.efax_jobs FOR EACH ROW EXECUTE FUNCTION public.log_efax_access();


--
-- Name: stations trigger_update_stations_timestamp; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_update_stations_timestamp BEFORE UPDATE ON public.stations FOR EACH ROW EXECUTE FUNCTION public.update_stations_timestamp();


--
-- Name: asset_meters asset_meters_asset_id_fkey; Type: FK CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.asset_meters
    ADD CONSTRAINT asset_meters_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES eam.assets(id) ON DELETE CASCADE;


--
-- Name: assets assets_asset_type_id_fkey; Type: FK CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.assets
    ADD CONSTRAINT assets_asset_type_id_fkey FOREIGN KEY (asset_type_id) REFERENCES eam.asset_types(id);


--
-- Name: assets assets_parent_id_fkey; Type: FK CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.assets
    ADD CONSTRAINT assets_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES eam.assets(id) ON DELETE SET NULL;


--
-- Name: inventory_transactions inventory_transactions_location_id_fkey; Type: FK CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.inventory_transactions
    ADD CONSTRAINT inventory_transactions_location_id_fkey FOREIGN KEY (location_id) REFERENCES eam.stock_locations(id);


--
-- Name: inventory_transactions inventory_transactions_part_id_fkey; Type: FK CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.inventory_transactions
    ADD CONSTRAINT inventory_transactions_part_id_fkey FOREIGN KEY (part_id) REFERENCES eam.parts(id);


--
-- Name: maintenance_plans maintenance_plans_asset_id_fkey; Type: FK CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.maintenance_plans
    ADD CONSTRAINT maintenance_plans_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES eam.assets(id);


--
-- Name: maintenance_triggers maintenance_triggers_meter_id_fkey; Type: FK CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.maintenance_triggers
    ADD CONSTRAINT maintenance_triggers_meter_id_fkey FOREIGN KEY (meter_id) REFERENCES eam.asset_meters(id);


--
-- Name: maintenance_triggers maintenance_triggers_plan_id_fkey; Type: FK CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.maintenance_triggers
    ADD CONSTRAINT maintenance_triggers_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES eam.maintenance_plans(id) ON DELETE CASCADE;


--
-- Name: meter_readings meter_readings_meter_id_fkey; Type: FK CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.meter_readings
    ADD CONSTRAINT meter_readings_meter_id_fkey FOREIGN KEY (meter_id) REFERENCES eam.asset_meters(id) ON DELETE CASCADE;


--
-- Name: work_order_labor work_order_labor_technician_id_fkey; Type: FK CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.work_order_labor
    ADD CONSTRAINT work_order_labor_technician_id_fkey FOREIGN KEY (technician_id) REFERENCES eam.technicians(id);


--
-- Name: work_order_labor work_order_labor_work_order_id_fkey; Type: FK CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.work_order_labor
    ADD CONSTRAINT work_order_labor_work_order_id_fkey FOREIGN KEY (work_order_id) REFERENCES eam.work_orders(id) ON DELETE CASCADE;


--
-- Name: work_order_parts work_order_parts_part_id_fkey; Type: FK CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.work_order_parts
    ADD CONSTRAINT work_order_parts_part_id_fkey FOREIGN KEY (part_id) REFERENCES eam.parts(id);


--
-- Name: work_order_parts work_order_parts_work_order_id_fkey; Type: FK CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.work_order_parts
    ADD CONSTRAINT work_order_parts_work_order_id_fkey FOREIGN KEY (work_order_id) REFERENCES eam.work_orders(id) ON DELETE CASCADE;


--
-- Name: work_order_tasks work_order_tasks_work_order_id_fkey; Type: FK CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.work_order_tasks
    ADD CONSTRAINT work_order_tasks_work_order_id_fkey FOREIGN KEY (work_order_id) REFERENCES eam.work_orders(id) ON DELETE CASCADE;


--
-- Name: work_orders work_orders_asset_id_fkey; Type: FK CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.work_orders
    ADD CONSTRAINT work_orders_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES eam.assets(id);


--
-- Name: work_orders work_orders_assigned_to_fkey; Type: FK CONSTRAINT; Schema: eam; Owner: postgres
--

ALTER TABLE ONLY eam.work_orders
    ADD CONSTRAINT work_orders_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES eam.technicians(id);


--
-- Name: applied_learning_experiences applied_learning_experiences_faculty_advisor_id_fkey; Type: FK CONSTRAINT; Schema: learningsystem; Owner: postgres
--

ALTER TABLE ONLY learningsystem.applied_learning_experiences
    ADD CONSTRAINT applied_learning_experiences_faculty_advisor_id_fkey FOREIGN KEY (faculty_advisor_id) REFERENCES learningsystem.users(id);


--
-- Name: applied_learning_experiences applied_learning_experiences_student_id_fkey; Type: FK CONSTRAINT; Schema: learningsystem; Owner: postgres
--

ALTER TABLE ONLY learningsystem.applied_learning_experiences
    ADD CONSTRAINT applied_learning_experiences_student_id_fkey FOREIGN KEY (student_id) REFERENCES learningsystem.users(id);


--
-- Name: audit_logs audit_logs_actor_id_fkey; Type: FK CONSTRAINT; Schema: learningsystem; Owner: postgres
--

ALTER TABLE ONLY learningsystem.audit_logs
    ADD CONSTRAINT audit_logs_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES learningsystem.users(id) ON DELETE SET NULL;


--
-- Name: employer_profiles employer_profiles_user_id_fkey; Type: FK CONSTRAINT; Schema: learningsystem; Owner: postgres
--

ALTER TABLE ONLY learningsystem.employer_profiles
    ADD CONSTRAINT employer_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES learningsystem.users(id) ON DELETE CASCADE;


--
-- Name: event_registrations event_registrations_event_id_fkey; Type: FK CONSTRAINT; Schema: learningsystem; Owner: postgres
--

ALTER TABLE ONLY learningsystem.event_registrations
    ADD CONSTRAINT event_registrations_event_id_fkey FOREIGN KEY (event_id) REFERENCES learningsystem.events(id);


--
-- Name: event_registrations event_registrations_user_id_fkey; Type: FK CONSTRAINT; Schema: learningsystem; Owner: postgres
--

ALTER TABLE ONLY learningsystem.event_registrations
    ADD CONSTRAINT event_registrations_user_id_fkey FOREIGN KEY (user_id) REFERENCES learningsystem.users(id);


--
-- Name: events events_organizer_id_fkey; Type: FK CONSTRAINT; Schema: learningsystem; Owner: postgres
--

ALTER TABLE ONLY learningsystem.events
    ADD CONSTRAINT events_organizer_id_fkey FOREIGN KEY (organizer_id) REFERENCES learningsystem.users(id);


--
-- Name: job_postings job_postings_employer_id_fkey; Type: FK CONSTRAINT; Schema: learningsystem; Owner: postgres
--

ALTER TABLE ONLY learningsystem.job_postings
    ADD CONSTRAINT job_postings_employer_id_fkey FOREIGN KEY (employer_id) REFERENCES learningsystem.users(id) ON DELETE CASCADE;


--
-- Name: student_profiles student_profiles_user_id_fkey; Type: FK CONSTRAINT; Schema: learningsystem; Owner: postgres
--

ALTER TABLE ONLY learningsystem.student_profiles
    ADD CONSTRAINT student_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES learningsystem.users(id);


--
-- Name: system_configs system_configs_updated_by_fkey; Type: FK CONSTRAINT; Schema: learningsystem; Owner: postgres
--

ALTER TABLE ONLY learningsystem.system_configs
    ADD CONSTRAINT system_configs_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES learningsystem.users(id);


--
-- Name: volunteer_logs volunteer_logs_experience_id_fkey; Type: FK CONSTRAINT; Schema: learningsystem; Owner: postgres
--

ALTER TABLE ONLY learningsystem.volunteer_logs
    ADD CONSTRAINT volunteer_logs_experience_id_fkey FOREIGN KEY (experience_id) REFERENCES learningsystem.applied_learning_experiences(id);


--
-- Name: volunteer_logs volunteer_logs_student_id_fkey; Type: FK CONSTRAINT; Schema: learningsystem; Owner: postgres
--

ALTER TABLE ONLY learningsystem.volunteer_logs
    ADD CONSTRAINT volunteer_logs_student_id_fkey FOREIGN KEY (student_id) REFERENCES learningsystem.users(id);


--
-- Name: workflows workflows_experience_id_fkey; Type: FK CONSTRAINT; Schema: learningsystem; Owner: postgres
--

ALTER TABLE ONLY learningsystem.workflows
    ADD CONSTRAINT workflows_experience_id_fkey FOREIGN KEY (experience_id) REFERENCES learningsystem.applied_learning_experiences(id);


--
-- Name: auth_logs auth_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.auth_logs
    ADD CONSTRAINT auth_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES pharmacy.users(id);


--
-- Name: device_fingerprints device_fingerprints_station_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.device_fingerprints
    ADD CONSTRAINT device_fingerprints_station_id_fkey FOREIGN KEY (station_id) REFERENCES pharmacy.stations(id) ON DELETE CASCADE;


--
-- Name: inventory_items inventory_items_reorder_rule_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.inventory_items
    ADD CONSTRAINT inventory_items_reorder_rule_id_fkey FOREIGN KEY (reorder_rule_id) REFERENCES pharmacy.reorder_rules(id);


--
-- Name: patient_insurances patient_insurances_patient_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.patient_insurances
    ADD CONSTRAINT patient_insurances_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES pharmacy.patients(id) ON DELETE CASCADE;


--
-- Name: prescription_queue prescription_queue_assigned_to_fkey; Type: FK CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.prescription_queue
    ADD CONSTRAINT prescription_queue_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES pharmacy.users(id);


--
-- Name: prescription_workflow_events prescription_workflow_events_changed_by_fkey; Type: FK CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.prescription_workflow_events
    ADD CONSTRAINT prescription_workflow_events_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES pharmacy.users(id);


--
-- Name: prescriptions prescriptions_current_status_fkey; Type: FK CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.prescriptions
    ADD CONSTRAINT prescriptions_current_status_fkey FOREIGN KEY (current_status) REFERENCES pharmacy.workflow_statuses(status_code);


--
-- Name: prescriptions prescriptions_current_step_fkey; Type: FK CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.prescriptions
    ADD CONSTRAINT prescriptions_current_step_fkey FOREIGN KEY (current_step) REFERENCES pharmacy.workflow_steps(step_code);


--
-- Name: prescriptions prescriptions_patient_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.prescriptions
    ADD CONSTRAINT prescriptions_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES pharmacy.patients(id);


--
-- Name: prescriptions prescriptions_prescriber_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.prescriptions
    ADD CONSTRAINT prescriptions_prescriber_id_fkey FOREIGN KEY (prescriber_id) REFERENCES pharmacy.prescribers(id);


--
-- Name: user_roles user_roles_role_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.user_roles
    ADD CONSTRAINT user_roles_role_id_fkey FOREIGN KEY (role_id) REFERENCES pharmacy.roles(id) ON DELETE RESTRICT;


--
-- Name: user_roles user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES pharmacy.users(id) ON DELETE CASCADE;


--
-- Name: workflow_transitions workflow_transitions_from_step_fkey; Type: FK CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.workflow_transitions
    ADD CONSTRAINT workflow_transitions_from_step_fkey FOREIGN KEY (from_step) REFERENCES pharmacy.workflow_steps(step_code);


--
-- Name: workflow_transitions workflow_transitions_to_step_fkey; Type: FK CONSTRAINT; Schema: pharmacy; Owner: postgres
--

ALTER TABLE ONLY pharmacy.workflow_transitions
    ADD CONSTRAINT workflow_transitions_to_step_fkey FOREIGN KEY (to_step) REFERENCES pharmacy.workflow_steps(step_code);


--
-- Name: access_logs access_logs_patient_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.access_logs
    ADD CONSTRAINT access_logs_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES pharmacy3.patients(id);


--
-- Name: access_logs access_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.access_logs
    ADD CONSTRAINT access_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES pharmacy3.users(id);


--
-- Name: auth_logs auth_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.auth_logs
    ADD CONSTRAINT auth_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES pharmacy3.users(id);


--
-- Name: claim_transactions claim_transactions_claim_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.claim_transactions
    ADD CONSTRAINT claim_transactions_claim_id_fkey FOREIGN KEY (claim_id) REFERENCES pharmacy3.claims(id) ON DELETE CASCADE;


--
-- Name: claims claims_patient_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.claims
    ADD CONSTRAINT claims_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES pharmacy3.patients(id);


--
-- Name: claims claims_patient_insurance_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.claims
    ADD CONSTRAINT claims_patient_insurance_id_fkey FOREIGN KEY (patient_insurance_id) REFERENCES pharmacy3.patient_insurances(id);


--
-- Name: claims claims_prescription_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.claims
    ADD CONSTRAINT claims_prescription_id_fkey FOREIGN KEY (prescription_id) REFERENCES pharmacy3.prescriptions(id);


--
-- Name: documents documents_created_by_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.documents
    ADD CONSTRAINT documents_created_by_fkey FOREIGN KEY (created_by) REFERENCES pharmacy3.users(id);


--
-- Name: documents documents_updated_by_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.documents
    ADD CONSTRAINT documents_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES pharmacy3.users(id);


--
-- Name: efax_incoming efax_incoming_linked_patient_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.efax_incoming
    ADD CONSTRAINT efax_incoming_linked_patient_id_fkey FOREIGN KEY (linked_patient_id) REFERENCES pharmacy3.patients(id);


--
-- Name: efax_incoming efax_incoming_linked_prescription_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.efax_incoming
    ADD CONSTRAINT efax_incoming_linked_prescription_id_fkey FOREIGN KEY (linked_prescription_id) REFERENCES pharmacy3.prescriptions(id);


--
-- Name: efax_incoming efax_incoming_processed_by_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.efax_incoming
    ADD CONSTRAINT efax_incoming_processed_by_fkey FOREIGN KEY (processed_by) REFERENCES pharmacy3.users(id);


--
-- Name: efax_jobs efax_jobs_claim_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.efax_jobs
    ADD CONSTRAINT efax_jobs_claim_id_fkey FOREIGN KEY (claim_id) REFERENCES pharmacy3.claims(id);


--
-- Name: efax_jobs efax_jobs_document_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.efax_jobs
    ADD CONSTRAINT efax_jobs_document_id_fkey FOREIGN KEY (document_id) REFERENCES pharmacy3.documents(id);


--
-- Name: efax_jobs efax_jobs_patient_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.efax_jobs
    ADD CONSTRAINT efax_jobs_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES pharmacy3.patients(id);


--
-- Name: efax_jobs efax_jobs_prescription_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.efax_jobs
    ADD CONSTRAINT efax_jobs_prescription_id_fkey FOREIGN KEY (prescription_id) REFERENCES pharmacy3.prescriptions(id);


--
-- Name: efax_jobs efax_jobs_recipient_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.efax_jobs
    ADD CONSTRAINT efax_jobs_recipient_id_fkey FOREIGN KEY (recipient_id) REFERENCES pharmacy3.efax_recipients(id);


--
-- Name: efax_jobs efax_jobs_user_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.efax_jobs
    ADD CONSTRAINT efax_jobs_user_id_fkey FOREIGN KEY (user_id) REFERENCES pharmacy3.users(id);


--
-- Name: efax_status_logs efax_status_logs_efax_job_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.efax_status_logs
    ADD CONSTRAINT efax_status_logs_efax_job_id_fkey FOREIGN KEY (efax_job_id) REFERENCES pharmacy3.efax_jobs(id) ON DELETE CASCADE;


--
-- Name: insurance_plans insurance_plans_company_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.insurance_plans
    ADD CONSTRAINT insurance_plans_company_id_fkey FOREIGN KEY (company_id) REFERENCES pharmacy3.insurance_companies(id);


--
-- Name: inventory_items inventory_items_reorder_rule_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.inventory_items
    ADD CONSTRAINT inventory_items_reorder_rule_id_fkey FOREIGN KEY (reorder_rule_id) REFERENCES pharmacy3.reorder_rules(id);


--
-- Name: patient_insurances patient_insurances_insurance_plan_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.patient_insurances
    ADD CONSTRAINT patient_insurances_insurance_plan_id_fkey FOREIGN KEY (insurance_plan_id) REFERENCES pharmacy3.insurance_plans(id) ON DELETE RESTRICT;


--
-- Name: patient_insurances patient_insurances_patient_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.patient_insurances
    ADD CONSTRAINT patient_insurances_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES pharmacy3.patients(id) ON DELETE CASCADE;


--
-- Name: pharmacist_note_addendums pharmacist_note_addendums_actor_user_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.pharmacist_note_addendums
    ADD CONSTRAINT pharmacist_note_addendums_actor_user_id_fkey FOREIGN KEY (actor_user_id) REFERENCES pharmacy3.users(id) ON DELETE SET NULL;


--
-- Name: pharmacist_note_addendums pharmacist_note_addendums_pharmacist_note_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.pharmacist_note_addendums
    ADD CONSTRAINT pharmacist_note_addendums_pharmacist_note_id_fkey FOREIGN KEY (pharmacist_note_id) REFERENCES pharmacy3.pharmacist_notes(id) ON DELETE CASCADE;


--
-- Name: pharmacist_notes pharmacist_notes_actor_user_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.pharmacist_notes
    ADD CONSTRAINT pharmacist_notes_actor_user_id_fkey FOREIGN KEY (actor_user_id) REFERENCES pharmacy3.users(id) ON DELETE SET NULL;


--
-- Name: pharmacist_notes pharmacist_notes_prescription_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.pharmacist_notes
    ADD CONSTRAINT pharmacist_notes_prescription_id_fkey FOREIGN KEY (prescription_id) REFERENCES pharmacy3.prescriptions(id) ON DELETE CASCADE;


--
-- Name: prescription_items prescription_items_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.prescription_items
    ADD CONSTRAINT prescription_items_inventory_item_id_fkey FOREIGN KEY (inventory_item_id) REFERENCES pharmacy3.inventory_items(id);


--
-- Name: prescription_items prescription_items_prescription_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.prescription_items
    ADD CONSTRAINT prescription_items_prescription_id_fkey FOREIGN KEY (prescription_id) REFERENCES pharmacy3.prescriptions(id) ON DELETE CASCADE;


--
-- Name: prescription_queue prescription_queue_assigned_to_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.prescription_queue
    ADD CONSTRAINT prescription_queue_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES pharmacy3.users(id);


--
-- Name: prescription_queue prescription_queue_prescription_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.prescription_queue
    ADD CONSTRAINT prescription_queue_prescription_id_fkey FOREIGN KEY (prescription_id) REFERENCES pharmacy3.prescriptions(id) ON DELETE CASCADE;


--
-- Name: prescription_workflow_events prescription_workflow_events_changed_by_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.prescription_workflow_events
    ADD CONSTRAINT prescription_workflow_events_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES pharmacy3.users(id);


--
-- Name: prescription_workflow_events prescription_workflow_events_prescription_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.prescription_workflow_events
    ADD CONSTRAINT prescription_workflow_events_prescription_id_fkey FOREIGN KEY (prescription_id) REFERENCES pharmacy3.prescriptions(id) ON DELETE CASCADE;


--
-- Name: prescriptions prescriptions_patient_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.prescriptions
    ADD CONSTRAINT prescriptions_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES pharmacy3.patients(id);


--
-- Name: prescriptions prescriptions_prescriber_id_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.prescriptions
    ADD CONSTRAINT prescriptions_prescriber_id_fkey FOREIGN KEY (prescriber_id) REFERENCES pharmacy3.prescribers(id);


--
-- Name: workflow_transitions workflow_transitions_from_step_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.workflow_transitions
    ADD CONSTRAINT workflow_transitions_from_step_fkey FOREIGN KEY (from_step) REFERENCES pharmacy3.workflow_steps(step_code);


--
-- Name: workflow_transitions workflow_transitions_to_step_fkey; Type: FK CONSTRAINT; Schema: pharmacy3; Owner: postgres
--

ALTER TABLE ONLY pharmacy3.workflow_transitions
    ADD CONSTRAINT workflow_transitions_to_step_fkey FOREIGN KEY (to_step) REFERENCES pharmacy3.workflow_steps(step_code);


--
-- Name: access_logs access_logs_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.access_logs
    ADD CONSTRAINT access_logs_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id);


--
-- Name: access_logs access_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.access_logs
    ADD CONSTRAINT access_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: alert_logs alert_logs_alert_rule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_logs
    ADD CONSTRAINT alert_logs_alert_rule_id_fkey FOREIGN KEY (alert_rule_id) REFERENCES public.alert_rules(id);


--
-- Name: alert_logs alert_logs_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_logs
    ADD CONSTRAINT alert_logs_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id);


--
-- Name: alert_logs alert_logs_triggered_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_logs
    ADD CONSTRAINT alert_logs_triggered_by_fkey FOREIGN KEY (triggered_by) REFERENCES public.users(id);


--
-- Name: auth_logs auth_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_logs
    ADD CONSTRAINT auth_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: barcode_labels barcode_labels_prescription_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.barcode_labels
    ADD CONSTRAINT barcode_labels_prescription_item_id_fkey FOREIGN KEY (prescription_item_id) REFERENCES public.prescription_items(id);


--
-- Name: barcode_labels barcode_labels_printed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.barcode_labels
    ADD CONSTRAINT barcode_labels_printed_by_fkey FOREIGN KEY (printed_by) REFERENCES public.users(id);


--
-- Name: consent_records consent_records_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.consent_records
    ADD CONSTRAINT consent_records_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id);


--
-- Name: consent_records consent_records_recorded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.consent_records
    ADD CONSTRAINT consent_records_recorded_by_fkey FOREIGN KEY (recorded_by) REFERENCES public.users(id);


--
-- Name: device_fingerprints device_fingerprints_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_fingerprints
    ADD CONSTRAINT device_fingerprints_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id) ON DELETE CASCADE;


--
-- Name: dir_fees dir_fees_claim_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dir_fees
    ADD CONSTRAINT dir_fees_claim_id_fkey FOREIGN KEY (claim_id) REFERENCES public.claims(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: dscsa_serials dscsa_serials_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dscsa_serials
    ADD CONSTRAINT dscsa_serials_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.inventory_batches(id) ON DELETE CASCADE;


--
-- Name: efax_attachments efax_attachments_efax_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.efax_attachments
    ADD CONSTRAINT efax_attachments_efax_job_id_fkey FOREIGN KEY (efax_job_id) REFERENCES public.efax_jobs(id) ON DELETE CASCADE;


--
-- Name: efax_incoming efax_incoming_linked_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.efax_incoming
    ADD CONSTRAINT efax_incoming_linked_patient_id_fkey FOREIGN KEY (linked_patient_id) REFERENCES public.patients(id);


--
-- Name: efax_incoming efax_incoming_processed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.efax_incoming
    ADD CONSTRAINT efax_incoming_processed_by_fkey FOREIGN KEY (processed_by) REFERENCES public.users(id);


--
-- Name: efax_jobs efax_jobs_claim_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.efax_jobs
    ADD CONSTRAINT efax_jobs_claim_id_fkey FOREIGN KEY (claim_id) REFERENCES public.prescription_claims(id);


--
-- Name: efax_jobs efax_jobs_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.efax_jobs
    ADD CONSTRAINT efax_jobs_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id);


--
-- Name: efax_jobs efax_jobs_recipient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.efax_jobs
    ADD CONSTRAINT efax_jobs_recipient_id_fkey FOREIGN KEY (recipient_id) REFERENCES public.efax_recipients(id);


--
-- Name: efax_jobs efax_jobs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.efax_jobs
    ADD CONSTRAINT efax_jobs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: efax_status_logs efax_status_logs_efax_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.efax_status_logs
    ADD CONSTRAINT efax_status_logs_efax_job_id_fkey FOREIGN KEY (efax_job_id) REFERENCES public.efax_jobs(id) ON DELETE CASCADE;


--
-- Name: integration_events integration_events_integration_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.integration_events
    ADD CONSTRAINT integration_events_integration_id_fkey FOREIGN KEY (integration_id) REFERENCES public.integrations(id);


--
-- Name: inventory_batches inventory_batches_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventory_batches
    ADD CONSTRAINT inventory_batches_inventory_item_id_fkey FOREIGN KEY (inventory_item_id) REFERENCES public.inventory_items(id) ON DELETE CASCADE;


--
-- Name: inventory_batches inventory_batches_wholesaler_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventory_batches
    ADD CONSTRAINT inventory_batches_wholesaler_id_fkey FOREIGN KEY (wholesaler_id) REFERENCES public.wholesalers(id);


--
-- Name: patient_aliases patient_aliases_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_aliases
    ADD CONSTRAINT patient_aliases_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id) ON DELETE CASCADE;


--
-- Name: patient_insurances patient_insurances_insurance_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_insurances
    ADD CONSTRAINT patient_insurances_insurance_company_id_fkey FOREIGN KEY (insurance_company_id) REFERENCES public.insurance_companies(id);


--
-- Name: patient_insurances patient_insurances_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_insurances
    ADD CONSTRAINT patient_insurances_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id) ON DELETE CASCADE;


--
-- Name: payments payments_pos_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pos_transaction_id_fkey FOREIGN KEY (pos_transaction_id) REFERENCES public.pos_transactions(id);


--
-- Name: pdmp_queries pdmp_queries_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pdmp_queries
    ADD CONSTRAINT pdmp_queries_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id) ON DELETE CASCADE;


--
-- Name: pdmp_queries pdmp_queries_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pdmp_queries
    ADD CONSTRAINT pdmp_queries_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: pharmacists pharmacists_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pharmacists
    ADD CONSTRAINT pharmacists_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: pos_signatures pos_signatures_pos_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pos_signatures
    ADD CONSTRAINT pos_signatures_pos_transaction_id_fkey FOREIGN KEY (pos_transaction_id) REFERENCES public.pos_transactions(id) ON DELETE CASCADE;


--
-- Name: pos_signatures pos_signatures_signed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pos_signatures
    ADD CONSTRAINT pos_signatures_signed_by_fkey FOREIGN KEY (signed_by) REFERENCES public.users(id);


--
-- Name: pos_transactions pos_transactions_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pos_transactions
    ADD CONSTRAINT pos_transactions_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id);


--
-- Name: prescription_audit prescription_audit_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prescription_audit
    ADD CONSTRAINT prescription_audit_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: prescription_claims prescription_claims_patient_insurance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prescription_claims
    ADD CONSTRAINT prescription_claims_patient_insurance_id_fkey FOREIGN KEY (patient_insurance_id) REFERENCES public.patient_insurances(id);


--
-- Name: prescription_copays prescription_copays_claim_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prescription_copays
    ADD CONSTRAINT prescription_copays_claim_id_fkey FOREIGN KEY (claim_id) REFERENCES public.prescription_claims(id);


--
-- Name: prescription_copays prescription_copays_insurance_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prescription_copays
    ADD CONSTRAINT prescription_copays_insurance_company_id_fkey FOREIGN KEY (insurance_company_id) REFERENCES public.insurance_companies(id);


--
-- Name: prescription_copays prescription_copays_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prescription_copays
    ADD CONSTRAINT prescription_copays_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id) ON DELETE CASCADE;


--
-- Name: prescription_items prescription_items_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prescription_items
    ADD CONSTRAINT prescription_items_inventory_item_id_fkey FOREIGN KEY (inventory_item_id) REFERENCES public.inventory_items(id);


--
-- Name: prescription_workflow_logs prescription_workflow_logs_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prescription_workflow_logs
    ADD CONSTRAINT prescription_workflow_logs_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.users(id);


--
-- Name: prescriptions prescriptions_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prescriptions
    ADD CONSTRAINT prescriptions_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.users(id);


--
-- Name: prescriptions prescriptions_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prescriptions
    ADD CONSTRAINT prescriptions_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id);


--
-- Name: prescriptions prescriptions_workflow_step_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prescriptions
    ADD CONSTRAINT prescriptions_workflow_step_id_fkey FOREIGN KEY (workflow_step_id) REFERENCES public.workflow_steps(id);


--
-- Name: purchase_orders purchase_orders_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT purchase_orders_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: purchase_orders purchase_orders_wholesaler_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT purchase_orders_wholesaler_id_fkey FOREIGN KEY (wholesaler_id) REFERENCES public.wholesalers(id);


--
-- Name: reorder_rules reorder_rules_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reorder_rules
    ADD CONSTRAINT reorder_rules_inventory_item_id_fkey FOREIGN KEY (inventory_item_id) REFERENCES public.inventory_items(id);


--
-- Name: reports reports_owner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.users(id);


--
-- Name: role_permissions role_permissions_granted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_granted_by_fkey FOREIGN KEY (granted_by) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: role_permissions role_permissions_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: task_routing task_routing_queue_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_routing
    ADD CONSTRAINT task_routing_queue_id_fkey FOREIGN KEY (queue_id) REFERENCES public.queues(id);


--
-- Name: tasks tasks_assignee_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_assignee_fkey FOREIGN KEY (assignee) REFERENCES public.users(id);


--
-- Name: tasks tasks_queue_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_queue_id_fkey FOREIGN KEY (queue_id) REFERENCES public.queues(id);


--
-- Name: tasks tasks_step_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_step_id_fkey FOREIGN KEY (step_id) REFERENCES public.workflow_steps(id);


--
-- Name: tasks tasks_workflow_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_workflow_id_fkey FOREIGN KEY (workflow_id) REFERENCES public.workflows(id);


--
-- Name: user_permissions user_permissions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_permissions
    ADD CONSTRAINT user_permissions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_sso user_sso_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_sso
    ADD CONSTRAINT user_sso_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: users users_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- Name: workflow_steps workflow_steps_workflow_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_steps
    ADD CONSTRAINT workflow_steps_workflow_id_fkey FOREIGN KEY (workflow_id) REFERENCES public.workflows(id) ON DELETE CASCADE;


--
-- Name: workflows workflows_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflows
    ADD CONSTRAINT workflows_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: mv_user_access_summary_monthly; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: postgres
--

REFRESH MATERIALIZED VIEW public.mv_user_access_summary_monthly;


--
-- PostgreSQL database dump complete
--

\unrestrict SsmlKxm0NWOqApxV8veQEHbHaO6BD4LEar9UdYqTDgfgmjcvSYMa8KN1xt2Zb0q

