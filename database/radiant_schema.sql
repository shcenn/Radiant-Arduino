-- =====================================================================
-- RADIANT database schema (PostgreSQL)
-- ITE 013 Application Development | Team BBC
--
-- Radiant dims traffic signal lamps when an intersection is idle and
-- reports status to a mobile app. It does NOT control signal phases or
-- timing, so there are no signal-timing tables.
-- =====================================================================

-- ---------------------------------------------------------------------
-- ACCOUNTS (registration, login, logout, per-user settings)
-- ---------------------------------------------------------------------
CREATE TABLE users (
    user_id        BIGSERIAL    PRIMARY KEY,
    username       VARCHAR(30)  NOT NULL UNIQUE,
    full_name      VARCHAR(100) NOT NULL,
    email          VARCHAR(255) NOT NULL UNIQUE,
    password_hash  VARCHAR(255) NOT NULL,          -- bcrypt/argon2 hash, never plain text
    role           VARCHAR(20)  NOT NULL DEFAULT 'technician'
                   CHECK (role IN ('admin', 'technician')),
    is_active      BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    last_login_at  TIMESTAMPTZ
);

-- One row per user; mirrors the Settings screen in the app.
CREATE TABLE user_settings (
    user_id               BIGINT   PRIMARY KEY REFERENCES users (user_id) ON DELETE CASCADE,
    dark_mode             BOOLEAN  NOT NULL DEFAULT FALSE,
    notifications_enabled BOOLEAN  NOT NULL DEFAULT TRUE,
    critical_alerts       BOOLEAN  NOT NULL DEFAULT TRUE,
    maintenance_alerts    BOOLEAN  NOT NULL DEFAULT TRUE,
    daily_energy_summary  BOOLEAN  NOT NULL DEFAULT FALSE,
    auto_refresh          BOOLEAN  NOT NULL DEFAULT TRUE,
    refresh_interval_sec  INTEGER  NOT NULL DEFAULT 60
                          CHECK (refresh_interval_sec IN (30, 60, 300, 900)),
    default_map_view      VARCHAR(10) NOT NULL DEFAULT 'all'
                          CHECK (default_map_view IN ('all', 'warnings', 'failures'))
);

-- Audit trail for the register / login / logout feature.
CREATE TABLE auth_log (
    log_id              BIGSERIAL   PRIMARY KEY,
    user_id             BIGINT      REFERENCES users (user_id) ON DELETE SET NULL,
    username_attempted  VARCHAR(30),
    event               VARCHAR(20) NOT NULL
                        CHECK (event IN ('register', 'login', 'logout', 'login_failed')),
    occurred_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_auth_log_user_time ON auth_log (user_id, occurred_at DESC);

-- ---------------------------------------------------------------------
-- HARDWARE (intersections, Radiant units, approaches)
-- ---------------------------------------------------------------------
CREATE TABLE intersections (
    intersection_id  SERIAL        PRIMARY KEY,
    name             VARCHAR(100)  NOT NULL,        -- e.g. 'Rizal Ave. cor. 5th St.'
    latitude         NUMERIC(9, 6),
    longitude        NUMERIC(9, 6),
    created_at       TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- One Radiant unit per intersection (unit_id is the number shown as "UNIT #12").
CREATE TABLE units (
    unit_id            INTEGER      PRIMARY KEY,
    intersection_id    INTEGER      NOT NULL UNIQUE,
    status             VARCHAR(10)  NOT NULL DEFAULT 'functional'
                       CHECK (status IN ('functional', 'warning', 'failed')),
    brightness_percent SMALLINT     NOT NULL DEFAULT 100
                       CHECK (brightness_percent BETWEEN 0 AND 100),
    battery_percent    SMALLINT
                       CHECK (battery_percent BETWEEN 0 AND 100),
    firmware_version   VARCHAR(20),
    installed_at       DATE,
    last_seen_at       TIMESTAMPTZ                  -- used to detect "offline"
);

-- One row per approach (N/E/S/W): one PIR sensor and one signal lamp each.
CREATE TABLE approaches (
    approach_id    SERIAL      PRIMARY KEY,
    unit_id        INTEGER     NOT NULL REFERENCES units (unit_id) ON DELETE CASCADE,
    direction      CHAR(1)     NOT NULL CHECK (direction IN ('N', 'E', 'S', 'W')),
    sensor_status  VARCHAR(10) NOT NULL DEFAULT 'ok' CHECK (sensor_status IN ('ok', 'fault')),
    lamp_status    VARCHAR(10) NOT NULL DEFAULT 'ok' CHECK (lamp_status   IN ('ok', 'failed')),
    UNIQUE (unit_id, direction)
);

-- ---------------------------------------------------------------------
-- MEASUREMENTS (what the Arduino reports)
-- ---------------------------------------------------------------------
-- Periodic status snapshots, e.g. one row per minute per unit.
CREATE TABLE unit_readings (
    reading_id          BIGSERIAL   PRIMARY KEY,
    unit_id             INTEGER     NOT NULL REFERENCES units (unit_id) ON DELETE CASCADE,
    recorded_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    state               VARCHAR(10) NOT NULL CHECK (state IN ('dimmed', 'full', 'fault')),
    brightness_percent  SMALLINT    NOT NULL CHECK (brightness_percent BETWEEN 0 AND 100),
    battery_percent     SMALLINT    CHECK (battery_percent BETWEEN 0 AND 100)
);
CREATE INDEX idx_readings_unit_time ON unit_readings (unit_id, recorded_at DESC);

-- One row each time a PIR goes LOW -> HIGH (a vehicle detection).
CREATE TABLE detection_events (
    event_id     BIGSERIAL   PRIMARY KEY,
    approach_id  INTEGER     NOT NULL REFERENCES approaches (approach_id) ON DELETE CASCADE,
    detected_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_detections_approach_time ON detection_events (approach_id, detected_at DESC);

-- Daily energy per unit. Estimated from brightness over time;
-- baseline = the same lamps at full brightness all day.
CREATE TABLE daily_energy (
    unit_id        INTEGER       NOT NULL REFERENCES units (unit_id) ON DELETE CASCADE,
    log_date       DATE          NOT NULL,
    estimated_kwh  NUMERIC(8, 3) NOT NULL,
    baseline_kwh   NUMERIC(8, 3) NOT NULL,
    PRIMARY KEY (unit_id, log_date)
);

-- ---------------------------------------------------------------------
-- ALERTS AND MAINTENANCE
-- ---------------------------------------------------------------------
CREATE TABLE alerts (
    alert_id         BIGSERIAL    PRIMARY KEY,
    unit_id          INTEGER      NOT NULL REFERENCES units (unit_id) ON DELETE CASCADE,
    approach_id      INTEGER      REFERENCES approaches (approach_id) ON DELETE SET NULL,
    alert_type       VARCHAR(20)  NOT NULL
                     CHECK (alert_type IN ('sensor_fault', 'lamp_failure', 'low_battery', 'offline')),
    severity         VARCHAR(10)  NOT NULL CHECK (severity IN ('info', 'warning', 'critical')),
    message          VARCHAR(255) NOT NULL,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    acknowledged_by  BIGINT       REFERENCES users (user_id) ON DELETE SET NULL,
    acknowledged_at  TIMESTAMPTZ,
    resolved_at      TIMESTAMPTZ
);
CREATE INDEX idx_alerts_unit_time ON alerts (unit_id, created_at DESC);

-- One ticket per alert; tracks dispatch so response time can be measured.
CREATE TABLE maintenance_tickets (
    ticket_id      BIGSERIAL   PRIMARY KEY,
    alert_id       BIGINT      NOT NULL UNIQUE REFERENCES alerts (alert_id) ON DELETE CASCADE,
    assigned_to    BIGINT      REFERENCES users (user_id) ON DELETE SET NULL,
    status         VARCHAR(12) NOT NULL DEFAULT 'open'
                   CHECK (status IN ('open', 'dispatched', 'resolved')),
    dispatched_at  TIMESTAMPTZ,
    resolved_at    TIMESTAMPTZ,
    notes          TEXT
);

-- ---------------------------------------------------------------------
-- REPORTING VIEW: supports the objective "shorten the time between a
-- fault occurring and a technician being dispatched".
-- ---------------------------------------------------------------------
CREATE VIEW v_time_to_dispatch AS
SELECT t.ticket_id,
       a.unit_id,
       a.alert_type,
       a.created_at                    AS fault_at,
       t.dispatched_at,
       t.dispatched_at - a.created_at  AS time_to_dispatch
FROM maintenance_tickets t
JOIN alerts a ON a.alert_id = t.alert_id
WHERE t.dispatched_at IS NOT NULL;

-- Total energy used per day across all units, and how much was saved
-- compared with running every lamp at full brightness (the baseline).
CREATE VIEW v_total_energy AS
SELECT log_date,
       SUM(estimated_kwh)                     AS total_kwh,
       SUM(baseline_kwh)                      AS baseline_kwh,
       SUM(baseline_kwh) - SUM(estimated_kwh) AS saved_kwh
FROM daily_energy
GROUP BY log_date;

-- ---------------------------------------------------------------------
-- SAMPLE DATA matching the mockup (users are created by the app's
-- registration, so none are seeded here: password hashes must come
-- from the app, not from this file).
-- ---------------------------------------------------------------------
INSERT INTO intersections (name) VALUES
    ('Rizal Ave. cor. 5th St.'), ('Commonwealth Ave.'), ('Katipunan Ave.'), ('España Blvd.');

INSERT INTO units (unit_id, intersection_id, status, brightness_percent, battery_percent) VALUES
    (12, 1, 'functional', 30, 86),
    (23, 2, 'warning',   100, 18),
    (15, 3, 'failed',      0, 74),
    (47, 4, 'failed',      0, 52);

INSERT INTO approaches (unit_id, direction)
SELECT u.unit_id, d.direction
FROM units u CROSS JOIN (VALUES ('N'), ('E'), ('S'), ('W')) AS d (direction);

INSERT INTO alerts (unit_id, alert_type, severity, message, created_at) VALUES
    (47, 'offline',      'critical', 'UNIT #47 offline', now() - interval '15 minutes'),
    (23, 'low_battery',  'warning',  'UNIT #23 at 18%',  now() - interval '2 hours'),
    (15, 'lamp_failure', 'critical', 'UNIT #15 dark',    now() - interval '4 hours');