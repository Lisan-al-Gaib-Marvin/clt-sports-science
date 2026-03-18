CREATE DATABASE uncc_fb_data; 
USE uncc_fb_data;
-- NOTE ON NAMES: 
-- ForceDecks/NordBord/GPS use "First Last" format.
-- TAP_GRIP and Bodyweights use "Last, First" format.

-- players fact table
CREATE TABLE players (
    player_id INT NOT NULL AUTO_INCREMENT,
    player_name VARCHAR(100) NOT NULL,
    position VARCHAR(10),              -- DT, DE, LB, CB, WR, OL, S, etc.
    position_group VARCHAR(20),        -- DLINE, LINEBACKERS, DB, WR, OL, etc.
    PRIMARY KEY (player_id),
    UNIQUE KEY uk_player_name (player_name)
);
 
-- bodyweights
CREATE TABLE bodyweights (
    bodyweight_id INT NOT NULL AUTO_INCREMENT,
    player_id INT NOT NULL,
    weigh_date DATE NOT NULL,
    weight_lbs DECIMAL(5,1) NOT NULL,  
    PRIMARY KEY (bodyweight_id),
    FOREIGN KEY (player_id) REFERENCES players(player_id),
    UNIQUE KEY uk_bw_player_date (player_id, weigh_date)
);
 
 
-- cmj
CREATE TABLE cmj_tests (
    cmj_id INT NOT NULL AUTO_INCREMENT,
    player_id INT NOT NULL,
    test_date DATE NOT NULL,
    test_time TIME,
    bodyweight_kg DECIMAL(6,2),                   -- BW [KG] from ForceDecks
    reps INT,
    additional_load_lbs INT DEFAULT 0,             -- Additional Load [lb] 
    jump_height_in DECIMAL(5,2),                   -- Jump Height (Imp-Mom) in Inches [in]
    rsi_modified DECIMAL(4,2),                     -- RSI-modified [m/s]
    concentric_peak_force_n INT,                   -- Concentric Peak Force [N]
    eccentric_peak_force_n INT,                    -- Eccentric Peak Force [N]
    concentric_peak_force_per_bm DECIMAL(5,2),     -- Concentric Peak Force / BM [N/kg]

    vertical_velocity_takeoff DECIMAL(4,2),        -- Vertical Velocity at Takeoff [m/s]
    ecc_braking_rfd_asym_pct DECIMAL(5,2),         -- Eccentric Braking RFD % (Asym) — the number
    ecc_braking_rfd_asym_side CHAR(1),             -- 'L' or 'R' — which side is dominant
                                                   -- source data is "17.3 R" (one combined field)
    ecc_braking_rfd_L INT,                         -- Eccentric Braking RFD [N/s] (L)
    ecc_braking_rfd_R INT,                         -- Eccentric Braking RFD [N/s] (R)
    countermovement_depth_cm DECIMAL(5,2),         -- Countermovement Depth [cm]
    positive_impulse_asym_pct DECIMAL(5,2),        -- Positive Impulse % (Asym) — the number
    positive_impulse_asym_side CHAR(1),            -- 'L' or 'R' — which side is dominant
                                 
    braking_phase_duration_ms INT,                 -- Braking Phase Duration [ms]
    flight_time_contraction_time DECIMAL(4,2),     -- Flight Time:Contraction Time
    PRIMARY KEY (cmj_id),
    FOREIGN KEY (player_id) REFERENCES players(player_id),
    INDEX idx_cmj_date (test_date),
    INDEX idx_cmj_player (player_id)
);
 
 
-- nordbord
CREATE TABLE nordbord_tests (
    nord_id INT NOT NULL AUTO_INCREMENT,
    player_id INT NOT NULL,
    test_date DATE NOT NULL,
    test_time TIME,
    device VARCHAR(20),                            
    test_type VARCHAR(20),                         
    reps_L INT,
    reps_R INT,
 
    max_force_L DECIMAL(7,2),                      -- L Max Force (N)
    max_force_R DECIMAL(7,2),                      -- R Max Force (N)
    max_imbalance_pct DECIMAL(6,2),                -- Max Imbalance (%)
    avg_force_L DECIMAL(7,2),                      -- L Avg Force (N)
    avg_force_R DECIMAL(7,2),                      -- R Avg Force (N)
    avg_imbalance_pct DECIMAL(6,2),                -- Avg Imbalance (%)
 
    max_torque_L DECIMAL(7,2),                     -- L Max Torque (Nm)
    max_torque_R DECIMAL(7,2),                     -- R Max Torque (Nm)
 
    max_impulse_L DECIMAL(10,2),                   -- L Max Impulse (Ns)
    max_impulse_R DECIMAL(10,2),                   -- R Max Impulse (Ns)
    impulse_imbalance_pct DECIMAL(6,2),            -- Impulse Imbalance (%)
 
    min_time_to_peak_L DECIMAL(6,4),               -- L Min Time to Peak Force (s)
    min_time_to_peak_R DECIMAL(6,4),               -- R Min Time to PeakForce (s)
    avg_time_to_peak_L DECIMAL(6,4),               -- L Avg Time to Peak Force (s)
    avg_time_to_peak_R DECIMAL(6,4),               -- R Avg Time to Peak Force (s)
 
    max_force_per_kg_L DECIMAL(5,2),               -- L Max Force Per Kg (N/kg)
    max_force_per_kg_R DECIMAL(5,2),               -- R Max Force Per Kg (N/kg)
    avg_force_per_kg_L DECIMAL(5,2),               -- L Avg Force Per Kg (N/kg)
    avg_force_per_kg_R DECIMAL(5,2),               -- R Avg Force Per Kg (N/kg)
    max_torque_per_kg_L DECIMAL(5,2),              -- L Max Torque Per Kg (Nm/kg)
    max_torque_per_kg_R DECIMAL(5,2),              -- R Max Torque Per Kg (Nm/kg)
    avg_torque_per_kg_L DECIMAL(5,2),              -- L Avg Torque Per Kg (Nm/kg)
    avg_torque_per_kg_R DECIMAL(5,2),              -- R Avg Torque Per Kg (Nm/kg)
 
    PRIMARY KEY (nord_id),
    FOREIGN KEY (player_id) REFERENCES players(player_id),
    INDEX idx_nord_date (test_date),
    INDEX idx_nord_player (player_id)
);
 
 
-- gps_sessions
CREATE TABLE gps_sessions (
    gps_id INT NOT NULL AUTO_INCREMENT,
    player_id INT NOT NULL,
    session_date DATE NOT NULL,
    activity_name VARCHAR(50),                     
                                                   -- Multiple sessions per day
    avg_player_load DECIMAL(8,5),                  -- Average Player Load (Session)
    player_load_per_min DECIMAL(7,5),              -- Player Load Per Minute
    total_distance_y DECIMAL(10,5),                -- Total Distance (y)
    walking_pct DECIMAL(7,5),                      -- Walking %
    max_velocity_mph DECIMAL(7,5),                 -- Maximum Velocity (mph)
    pct_max_velocity DECIMAL(8,5),                 -- Percentage of Max Velocity
    accel_efforts INT,                             -- Acceleration B1-3 Average Efforts
    max_acceleration DECIMAL(7,5),                 -- Max Acceleration
    decel_efforts INT,                             -- Deceleration B1-3 Average Efforts
    max_deceleration DECIMAL(7,5),                 -- Max Deceleration
    accel_decel_efforts INT,                       -- Accel + Decel Efforts
    explosive_efforts INT,                         -- Explosive Efforts (IMA) (avg)
    velocity_band_1_y DECIMAL(10,5),               -- Velocity Band 1 Total Distance (y)
    velocity_band_2_y DECIMAL(10,5),               -- Velocity Band 2 Total Distance (y)
    velocity_band_3_y DECIMAL(10,5),               -- Velocity Band 3 Total Distance (y)
    velocity_band_4_y DECIMAL(10,5),               -- Velocity Band 4 Total Distance (y)
    velocity_band_5_y DECIMAL(10,5),               -- Velocity Band 5 Total Distance (y)
    velocity_band_6_y DECIMAL(10,5),               -- Velocity Band 6 Total Distance (y)
    velocity_band_7_y DECIMAL(10,5),               -- Velocity Band 7 Total Distance (y)
    velocity_band_8_y DECIMAL(10,5),               -- Velocity Band 8 Total Distance (y)
    velocity_band_7_plus_efforts INT,              
    relative_hsd DECIMAL(10,5),                    -- Relative HSD (>75%)
    relative_vhsd DECIMAL(10,5),                   -- Relative VHSD (>90%)
    PRIMARY KEY (gps_id),
    FOREIGN KEY (player_id) REFERENCES players(player_id),
    INDEX idx_gps_date (session_date),
    INDEX idx_gps_player (player_id),
    INDEX idx_gps_activity (activity_name)
);
 
 
-- grip table
CREATE TABLE grip_tests (
    grip_id INT NOT NULL AUTO_INCREMENT,
    player_id INT NOT NULL,
    test_date DATE NOT NULL,
    grip_L DECIMAL(5,1),                           -- Left hand grip strength (lbs)
    grip_R DECIMAL(5,1),                           -- Right hand grip strength (lbs)
    PRIMARY KEY (grip_id),
    FOREIGN KEY (player_id) REFERENCES players(player_id),
    INDEX idx_grip_player_date (player_id, test_date)
);
 
 
-- tap table
CREATE TABLE tap_tests (
    tap_id INT NOT NULL AUTO_INCREMENT,
    player_id INT NOT NULL,
    test_date DATE NOT NULL,
    tap_score INT,                                 -- Finger tap count
    PRIMARY KEY (tap_id),
    FOREIGN KEY (player_id) REFERENCES players(player_id),
    INDEX idx_tap_player_date (player_id, test_date)
);
 
 
-- NordBord 
CREATE TABLE nordbord_rfd_detail (
    rfd_detail_id INT NOT NULL AUTO_INCREMENT,
    nord_id INT NOT NULL,
    time_window_ms INT NOT NULL,           -- 50, 100, 150, 200, or 250
    max_rfd_L DECIMAL(10,2),               -- L Max RFD (N/s)
    avg_rfd_L DECIMAL(10,2),               -- L Avg RFD (N/s)
    max_rfd_R DECIMAL(10,2),               -- R Max RFD (N/s)
    avg_rfd_R DECIMAL(10,2),               -- R Avg RFD (N/s)
    max_impulse_L DECIMAL(10,4),           -- L Max Impulse (N·s)
    avg_impulse_L DECIMAL(10,4),           -- L Avg Impulse (N·s)
    max_impulse_R DECIMAL(10,4),           -- R Max Impulse (N·s)
    avg_impulse_R DECIMAL(10,4),           -- R Avg Impulse (N·s)
    PRIMARY KEY (rfd_detail_id),
    FOREIGN KEY (nord_id) REFERENCES nordbord_tests(nord_id),
    UNIQUE KEY uk_rfd_window (nord_id, time_window_ms)
);
-- Truncate tables 
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE tap_tests;
TRUNCATE TABLE grip_tests;
TRUNCATE TABLE gps_sessions;
TRUNCATE TABLE nordbord_tests;
TRUNCATE TABLE cmj_tests;
TRUNCATE TABLE bodyweights;
TRUNCATE TABLE players;
SET FOREIGN_KEY_CHECKS = 1;