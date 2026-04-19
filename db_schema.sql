-- ============================================================
--  아르모니아 Master DB Schema  (MS-SQL Server)
--  앱 8개 통합 포인트 + 활동 이력 관리
-- ============================================================

-- ──────────────────────────────────────────
--  1. 앱 목록 (lookup)
-- ──────────────────────────────────────────
CREATE TABLE Apps (
    app_id      VARCHAR(20)  PRIMARY KEY,   -- 'toro_math', 'science_game' 등
    app_name    NVARCHAR(40) NOT NULL,
    icon        NVARCHAR(10),               -- 이모지
    color       VARCHAR(10),                -- 브랜드 색상 hex
    url_path    NVARCHAR(100),              -- ../toro_math/index.html
    sort_order  TINYINT DEFAULT 0,
    is_active   BIT DEFAULT 1
);

INSERT INTO Apps VALUES
('toro_math',     N'토로 수학',     N'🦕', '#22c55e', '../toro_math/index.html',      1, 1),
('science_game',  N'옴섬 과학탐험', N'🔭', '#3b82f6', '../science_game/index.html',   2, 1),
('toro',          N'토로와 30일',   N'🌱', '#a855f7', '../toro/index.html',           3, 1),
('detective_math',N'수학탐정단',    N'🔍', '#f97316', '../detective_math/detective_game.html', 4, 1),
('happy_day',     N'해피데이',      N'☀️', '#ec4899', '../happy_day/index.html',      5, 1),
('math_game',     N'수학게임',      N'🎮', '#14b8a6', '../math_game/index.html',      6, 1),
('math_blog',     N'수학블로그',    N'📖', '#a855f7', '../math_blog/index.html',      7, 1),
('armoonia_hub',  N'아르모니아 허브',N'🏠','#a855f7', '../armoonia_hub/index.html',   0, 1);

-- ──────────────────────────────────────────
--  2. 사용자
-- ──────────────────────────────────────────
CREATE TABLE Users (
    user_id     INT IDENTITY(1,1) PRIMARY KEY,
    nickname    NVARCHAR(30)  NOT NULL,
    age         TINYINT,                    -- 아이 나이
    role        VARCHAR(10)   DEFAULT 'child' CHECK(role IN ('child','parent','teacher')),
    device_id   VARCHAR(100)  UNIQUE,       -- 기기 식별자 (로그인 없는 경우)
    created_at  DATETIME2     DEFAULT GETDATE(),
    last_seen   DATETIME2     DEFAULT GETDATE()
);

-- ──────────────────────────────────────────
--  3. 포인트 원장 (모든 앱 통합)
-- ──────────────────────────────────────────
CREATE TABLE PointLedger (
    ledger_id   BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id     INT           NOT NULL REFERENCES Users(user_id),
    app_id      VARCHAR(20)   NOT NULL REFERENCES Apps(app_id),
    event_type  VARCHAR(30)   NOT NULL,     -- 'correct','complete','daily','bonus'
    points      SMALLINT      NOT NULL,     -- 양수=획득, 음수=사용
    memo        NVARCHAR(100),
    created_at  DATETIME2     DEFAULT GETDATE()
);
CREATE INDEX IX_PointLedger_User ON PointLedger(user_id, created_at DESC);

-- 사용자별 총 포인트 조회용 뷰
CREATE VIEW vw_UserTotalPoints AS
SELECT user_id, SUM(points) AS total_points
FROM PointLedger
GROUP BY user_id;

-- ──────────────────────────────────────────
--  4. 활동 로그 (앱별 상세 이력)
-- ──────────────────────────────────────────
CREATE TABLE ActivityLog (
    log_id      BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id     INT           NOT NULL REFERENCES Users(user_id),
    app_id      VARCHAR(20)   NOT NULL REFERENCES Apps(app_id),
    event_type  VARCHAR(30)   NOT NULL,     -- 'start','correct','wrong','complete','hint'
    topic_id    VARCHAR(50),                -- 앱 내 토픽/챕터 ID
    score       SMALLINT,                   -- 해당 이벤트 점수
    extra_json  NVARCHAR(500),              -- 앱별 추가 데이터 (JSON)
    created_at  DATETIME2     DEFAULT GETDATE()
);
CREATE INDEX IX_ActivityLog_User ON ActivityLog(user_id, app_id, created_at DESC);

-- ──────────────────────────────────────────
--  5. 퀴즈 결과 (math_game / science_game / detective_math / toro_math)
-- ──────────────────────────────────────────
CREATE TABLE QuizResult (
    result_id   BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id     INT           NOT NULL REFERENCES Users(user_id),
    app_id      VARCHAR(20)   NOT NULL REFERENCES Apps(app_id),
    topic_id    VARCHAR(50)   NOT NULL,     -- 'frac_add', 'solar_system' 등
    correct_cnt TINYINT       NOT NULL,
    total_cnt   TINYINT       NOT NULL,
    accuracy    AS CAST(correct_cnt AS FLOAT) / NULLIF(total_cnt,0) * 100 PERSISTED,
    time_sec    SMALLINT,                   -- 소요 시간(초)
    played_at   DATETIME2     DEFAULT GETDATE()
);
CREATE INDEX IX_QuizResult_User ON QuizResult(user_id, app_id, played_at DESC);

-- ──────────────────────────────────────────
--  6. 일일 도전 (toro 30일 / happy_day)
-- ──────────────────────────────────────────
CREATE TABLE DailyChallenge (
    challenge_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id     INT           NOT NULL REFERENCES Users(user_id),
    app_id      VARCHAR(20)   NOT NULL REFERENCES Apps(app_id),
    day_number  TINYINT       NOT NULL,     -- 1~30
    emotion     VARCHAR(20),                -- 'joy','calm','excited' 등
    note        NVARCHAR(200),              -- 오늘의 한마디
    completed_at DATETIME2    DEFAULT GETDATE(),
    UNIQUE(user_id, app_id, day_number)    -- 하루 1회만
);

-- ──────────────────────────────────────────
--  7. 앱 설정 (날씨 API 키 등 사용자별 설정)
-- ──────────────────────────────────────────
CREATE TABLE UserSettings (
    user_id     INT           PRIMARY KEY REFERENCES Users(user_id),
    weather_api_key VARCHAR(50),
    weather_city    NVARCHAR(30) DEFAULT N'서울',
    theme           VARCHAR(20)  DEFAULT 'dark',
    toro_voice      BIT          DEFAULT 1,   -- 토로 말풍선 ON/OFF
    updated_at  DATETIME2     DEFAULT GETDATE()
);

-- ──────────────────────────────────────────
--  8. 뱃지/업적
-- ──────────────────────────────────────────
CREATE TABLE Badge (
    badge_id    VARCHAR(30)   PRIMARY KEY,   -- 'first_correct','all_apps','30days'
    name        NVARCHAR(40)  NOT NULL,
    icon        NVARCHAR(10),
    description NVARCHAR(100),
    condition_type VARCHAR(20)               -- 'points','streak','app_complete'
);

CREATE TABLE UserBadge (
    user_id     INT           NOT NULL REFERENCES Users(user_id),
    badge_id    VARCHAR(30)   NOT NULL REFERENCES Badge(badge_id),
    earned_at   DATETIME2     DEFAULT GETDATE(),
    PRIMARY KEY (user_id, badge_id)
);

INSERT INTO Badge VALUES
('first_correct',  N'첫 정답',      N'⭐', N'처음으로 정답을 맞혔어요',      'activity'),
('combo_5',        N'5콤보',         N'🔥', N'연속 5문제 정답',              'activity'),
('combo_10',       N'10콤보',        N'💥', N'연속 10문제 정답',             'activity'),
('all_apps',       N'탐험가',        N'🗺️',N'모든 앱을 한 번씩 사용',       'app_complete'),
('points_1000',    N'포인트 부자',   N'💰', N'총 1000포인트 달성',           'points'),
('points_5000',    N'포인트 왕',     N'👑', N'총 5000포인트 달성',           'points'),
('toro_30days',    N'30일 완주',     N'🌳', N'토로와 30일 모험 완주',        'streak'),
('math_master',    N'수학 마스터',   N'🧮', N'수학 관련 앱 모두 완료',       'app_complete');

-- ──────────────────────────────────────────
--  9. 자주 쓰는 조회 뷰
-- ──────────────────────────────────────────

-- 사용자별 앱 사용 현황
CREATE VIEW vw_UserAppSummary AS
SELECT
    u.user_id,
    u.nickname,
    a.app_id,
    a.app_name,
    COUNT(al.log_id)               AS total_events,
    SUM(CASE WHEN al.event_type='correct' THEN 1 ELSE 0 END) AS correct_count,
    SUM(CASE WHEN al.event_type='wrong'   THEN 1 ELSE 0 END) AS wrong_count,
    MAX(al.created_at)             AS last_used,
    COALESCE(SUM(pl.points), 0)    AS app_points
FROM Users u
CROSS JOIN Apps a
LEFT JOIN ActivityLog al ON al.user_id=u.user_id AND al.app_id=a.app_id
LEFT JOIN PointLedger pl ON pl.user_id=u.user_id AND pl.app_id=a.app_id
GROUP BY u.user_id, u.nickname, a.app_id, a.app_name;

-- 전체 리더보드 (포인트 순)
CREATE VIEW vw_Leaderboard AS
SELECT
    u.user_id, u.nickname, u.age,
    COALESCE(SUM(pl.points), 0) AS total_points,
    RANK() OVER (ORDER BY COALESCE(SUM(pl.points),0) DESC) AS rank_no
FROM Users u
LEFT JOIN PointLedger pl ON pl.user_id = u.user_id
GROUP BY u.user_id, u.nickname, u.age;
