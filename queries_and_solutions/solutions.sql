-- ============================================
-- JOINS
-- ============================================

-- 1. Which country has the highest number of confirmed cases on a specific date?

SELECT 
    c.name,
    g.confirmed
FROM covid.country c
INNER JOIN covid.global_covid_stats g
    ON c.country_id = g.country_id
WHERE g.report_date = '2021-09-30'
ORDER BY g.confirmed DESC
LIMIT 1;

-- 2. Show the total number of deaths in each country, including provinces/states, for a given date.

SELECT 
    c.name AS country_name,
    s.name AS state_name,
    SUM(cs.deaths) AS total_deaths
FROM covid.covid_case_stats cs
INNER JOIN covid.states s
    ON cs.state_id = s.state_id
INNER JOIN covid.country c
    ON c.country_id = s.country_id
WHERE cs.report_date = '2021-09-30'
GROUP BY c.name, s.name;

-- 3. List the continents along with the total number of confirmed cases, deaths, and recoveries.

SELECT 
    c.continent,
    SUM(g.confirmed) AS total_confirmed,
    SUM(g.deaths) AS total_deaths,
    SUM(g.recovered) AS total_recovered
FROM covid.country c
INNER JOIN covid.global_covid_stats g
    ON c.country_id = g.country_id
WHERE g.report_date = (
    SELECT MAX(report_date)
    FROM covid.global_covid_stats
)

GROUP BY c.continent
ORDER BY c.continent

-- =========================
-- AGGREGATE FUNCTIONS
-- =========================

-- 4. Calculate the average number of new deaths per day across all countries.

SELECT 
    AVG(g.new_deaths) AS average_new_deaths_per_day
FROM covid.global_covid_stats g;

-- 5. Find the maximum number of active cases recorded in any country on a specific date.

SELECT 
    c.name,
    g.active_cases
FROM covid.country c
INNER JOIN covid.global_covid_stats g 
    ON c.country_id = g.country_id
WHERE g.report_date = '2021-09-30'
ORDER BY g.active_cases DESC
LIMIT 1;

-- =========================
-- STORED PROCEDURES
-- =========================

-- 6. Create a stored procedure that returns the total number of recovered cases for a given country and date.

CREATE OR REPLACE PROCEDURE get_recovered_cases(
    a_country VARCHAR,
    a_date DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    total_recovered BIGINT;
BEGIN
    SELECT 
        g.recovered
    INTO total_recovered
    FROM covid.country c
    INNER JOIN covid.global_covid_stats g
        ON c.country_id = g.country_id
    WHERE c.name = a_country
      AND g.report_date = a_date;

    RAISE NOTICE 'Total recovered cases: %', total_recovered;
END;
$$;

-- Execute the procedure
CALL get_recovered_cases('India', '2021-09-30');


-- 7. Design a stored procedure to update the number of deaths for a specific country and date.

CREATE OR REPLACE PROCEDURE update_deaths(
    p_country VARCHAR,
    p_date DATE,
    p_deaths BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE covid.global_covid_stats g
    SET deaths = p_deaths
    FROM covid.country c
    WHERE g.country_id = c.country_id
      AND c.name = p_country
      AND g.report_date = p_date;
END;
$$;
CALL update_deaths('india', '2021-09-30', 500);

-- =========================
-- VIEWS
-- =========================

-- 8. Create a view that displays the total number of cases (confirmed, deaths, and recovered) for each country on a specific date.

CREATE OR REPLACE VIEW covid_cases_on_date AS
SELECT 
    c.name AS country,
    g.report_date,
    g.confirmed,
    g.deaths,
    g.recovered
FROM covid.country c
INNER JOIN covid.global_covid_stats g
    ON c.country_id = g.country_id
WHERE g.report_date = '2021-09-30';


-- 9. Implement a view to show the latest data (confirmed, deaths, recovered) for each country.

CREATE OR REPLACE VIEW latest_country_data AS
SELECT DISTINCT ON (c.name)
    c.name AS country,
    g.report_date,
    g.confirmed,
    g.deaths,
    g.recovered
FROM covid.country c
INNER JOIN covid.global_covid_stats g
    ON c.country_id = g.country_id
ORDER BY c.name, g.report_date DESC;

-- =========================
-- T-SQL
-- =========================

-- 10. Write a T-SQL query to calculate the total number of cases (confirmed + deaths + recovered) for each country.

SELECT 
    c.name AS country,
    g.confirmed + g.deaths + g.recovered AS total_cases
FROM covid.country c
INNER JOIN covid.global_covid_stats g
    ON c.country_id = g.country_id
WHERE g.report_date = (
    SELECT MAX(report_date)
    FROM covid.global_covid_stats
);


-- 11. Use T-SQL to identify the country with the highest number of new cases reported on a specific date.

SELECT TOP 1
    c.name AS country,
    g.new_confirmed
FROM covid.country c
INNER JOIN covid.global_covid_stats g
    ON c.country_id = g.country_id
WHERE g.report_date = '2021-09-30'
ORDER BY g.new_confirmed DESC;

-- =========================
-- CTE (COMMON TABLE EXPRESSIONS)
-- =========================

-- 12. Create a CTE to calculate the percentage increase in confirmed cases for each country over the past week.

WITH weekly_data AS (
    SELECT 
        c.name AS country,
        MIN(g.confirmed) AS starting_cases,
        MAX(g.confirmed) AS ending_cases
    FROM covid.country c
    JOIN covid.global_covid_stats g
        ON c.country_id = g.country_id
    WHERE g.report_date >= '2021-09-24'
      AND g.report_date <= '2021-09-30'
    GROUP BY c.name
)
SELECT 
    country,
    ((ending_cases - starting_cases) * 100.0 
        / NULLIF(starting_cases, 0)) AS percentage_increase
FROM weekly_data;


-- 13. Use a CTE to find the country with the highest number of active cases at the moment.

WITH current_cases AS (
    SELECT 
        c.name AS country,
        g.active_cases
    FROM covid.country c
    INNER JOIN covid.global_covid_stats g
        ON c.country_id = g.country_id
    WHERE g.report_date = (
        SELECT MAX(report_date)
        FROM covid.global_covid_stats
    )
)
SELECT 
    country,
    active_cases
FROM current_cases
ORDER BY active_cases DESC
LIMIT 1;