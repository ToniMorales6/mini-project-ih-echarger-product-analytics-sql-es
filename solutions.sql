use echarger;

-- LEVEL 1

SELECT COUNT(DISTINCT user_id) AS total_unique_users_with_sessions
FROM sessions;

-- Question 2: Number of chargers used by user with id 1

SELECT COUNT(charger_id) AS total_chargers_used
FROM sessions s
WHERE s.user_id = 1;

-- LEVEL 2

SELECT c.type, COUNT(*) AS number_of_sessions
FROM sessions s
INNER JOIN chargers c WHERE s.charger_id = c.id
GROUP BY c.type;

-- Question 4: Chargers being used by more than one user

SELECT charger_id, COUNT(DISTINCT user_id) AS user_count
FROM sessions
GROUP BY charger_id
HAVING user_count > 1;

-- Question 5: Average session time per charger

SELECT charger_id, AVG(TIMESTAMPDIFF(MINUTE, start_time, end_time)) AS average_session_time_minutes
FROM sessions
GROUP BY charger_id;

-- LEVEL 3

-- Question 6: Full username of users that have used more than one charger in one day (NOTE: for date only consider start_time)

WITH multiple_chargers_users AS (
  SELECT DISTINCT user_id
  FROM sessions
  GROUP BY user_id, DATE(start_time)
  HAVING COUNT(DISTINCT charger_id) > 1
)

SELECT u.name, u.surname
FROM users u
JOIN multiple_chargers_users mcu ON u.id = mcu.user_id;


-- Question 7: Top 3 chargers with longer sessions

SELECT charger_id, MAX(TIMESTAMPDIFF(MINUTE, start_time, end_time)) AS longer_session_time_minutes
FROM sessions
GROUP BY charger_id
ORDER BY longer_session_time_minutes DESC
LIMIT 3;

-- Question 8: Average number of users per charger (per charger in general, not per charger_id specifically)

WITH average_per_id as (
	SELECT charger_id, COUNT(distinct user_id) AS user_count
	FROM sessions
	GROUP BY charger_id
    )
SELECT AVG(user_count) AS average_users_per_charger
FROM average_per_id;

-- Question 9: Top 3 users with more chargers being used

SELECT user_id, COUNT(DISTINCT charger_id) AS total_chargers
FROM sessions
GROUP BY user_id
ORDER BY total_chargers DESC
LIMIT 3;

-- LEVEL 4

-- Question 10: Number of users that have used only AC chargers, DC chargers or both

WITH charger_per_user AS (
    SELECT s.user_id,
        MAX(CASE WHEN c.type = 'AC' THEN 1 ELSE 0 END) AS used_AC,
        MAX(CASE WHEN c.type = 'DC' THEN 1 ELSE 0 END) AS used_DC
    FROM sessions s
    INNER JOIN chargers c ON s.charger_id = c.id
    GROUP BY s.user_id
)

SELECT SUM(used_AC) AS total_AC_users, SUM(used_DC) AS total_DC_users, SUM(used_AC = 1 AND used_DC= 1) AS total_both_users
FROM charger_per_user;

-- Question 11: Monthly average number of users per charger

WITH average_per_id_per_month as (
	SELECT charger_id, COUNT(distinct user_id) AS user_count, MONTH(s.start_time) AS `month`
	FROM sessions s
	GROUP BY charger_id, `month`
    )
SELECT `month`,AVG(user_count) AS average_users_per_charger_per_month
FROM average_per_id_per_month
GROUP BY `month`;

-- Question 12: Top 3 users per charger (for each charger, number of sessions)

WITH user_per_charger as (
	SELECT s.user_id, s.charger_id, count(*) as session_count
    FROM sessions s
    GROUP BY s.user_id, s.charger_id
    ),
    ranked_users_per_charger as (
    SELECT *,
    RANK() OVER (partition by charger_id ORDER BY session_count DESC) AS user_rank
    FROM user_per_charger
    )
    SELECT charger_id, user_id, session_count
    FROM ranked_users_per_charger
    WHERE user_rank <= 3;

-- LEVEL 5

-- Question 13: Top 3 users with longest sessions per month (consider the month of start_time)

WITH monthly_user_higher_durations AS (
    SELECT s.user_id, MONTH(start_time) AS month, MAX(TIMESTAMPDIFF(MINUTE, start_time, end_time)) AS higher_duration
	FROM sessions s
    GROUP BY user_id, month
	),
	ranked_users AS (
		SELECT muhd.user_id, muhd.month, muhd.higher_duration,
		RANK() OVER (PARTITION BY month ORDER BY muhd.higher_duration DESC) AS user_rank
		FROM monthly_user_higher_durations muhd
	)
SELECT ru.month, ru.user_id, ru.higher_duration
FROM ranked_users ru
WHERE user_rank <=3
ORDER BY month, user_rank;

-- Question 14. Average time between sessions for each charger for each month (consider the month of start_time)

WITH session_start_times AS (
	SELECT s.charger_id, MONTH(s.start_time) as month, s.start_time, 
    LEAD(start_time) OVER (PARTITION BY charger_id, MONTH(start_time) ORDER BY start_time) AS next_session_start_time
    FROM sessions s
    ),
	session_gaps AS (
    SELECT charger_id, month, TIMESTAMPDIFF(MINUTE, start_time, next_session_start_time) AS session_gap_minutes
    FROM session_start_times
    )
    
SELECT charger_id, month, AVG(session_gap_minutes) as average_time_between_sessions
FROM session_gaps
GROUP BY charger_id, month;