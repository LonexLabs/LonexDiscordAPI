-- ============================================================================
-- LonexDiscordAPI Activity System Database Schema
-- Requires: oxmysql
-- ============================================================================

-- Duty Sessions Table
-- Stores individual clock-in/clock-out sessions
CREATE TABLE IF NOT EXISTS lonex_duty_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    discord_id VARCHAR(20) NOT NULL,
    player_name VARCHAR(64),
    department VARCHAR(32) NOT NULL,
    clock_in DATETIME NOT NULL,
    clock_out DATETIME DEFAULT NULL,
    duration_seconds INT DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_discord_id (discord_id),
    INDEX idx_department (department),
    INDEX idx_clock_in (clock_in),
    INDEX idx_discord_department (discord_id, department)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Duty Totals Table
-- Stores aggregated total duty time per user per department
CREATE TABLE IF NOT EXISTS lonex_duty_totals (
    discord_id VARCHAR(20) NOT NULL,
    department VARCHAR(32) NOT NULL,
    total_seconds BIGINT DEFAULT 0,
    last_updated DATETIME,
    
    PRIMARY KEY (discord_id, department),
    INDEX idx_department (department),
    INDEX idx_total (total_seconds DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- Example Queries (for external tools)
-- ============================================================================

-- Get all sessions for a user in the last 7 days
-- SELECT * FROM lonex_duty_sessions 
-- WHERE discord_id = '306838265174949888' 
-- AND clock_in >= DATE_SUB(NOW(), INTERVAL 7 DAY)
-- ORDER BY clock_in DESC;

-- Get total hours per department for a user
-- SELECT department, total_seconds, total_seconds/3600 as hours 
-- FROM lonex_duty_totals 
-- WHERE discord_id = '306838265174949888';

-- Get leaderboard for a department (last 30 days)
-- SELECT discord_id, player_name, SUM(duration_seconds) as total_seconds,
--        SUM(duration_seconds)/3600 as hours
-- FROM lonex_duty_sessions 
-- WHERE department = 'leo' 
-- AND clock_in >= DATE_SUB(NOW(), INTERVAL 30 DAY)
-- AND duration_seconds IS NOT NULL
-- GROUP BY discord_id, player_name
-- ORDER BY total_seconds DESC
-- LIMIT 10;

-- Get currently incomplete sessions (players who didn't clock out properly)
-- SELECT * FROM lonex_duty_sessions 
-- WHERE clock_out IS NULL 
-- AND clock_in < DATE_SUB(NOW(), INTERVAL 24 HOUR);
