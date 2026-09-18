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

