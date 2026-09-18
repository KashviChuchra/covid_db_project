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

-- =========================================================
-- INDEXES
-- =========================================================

-- 14. Explain the importance of indexes in optimizing queries for this dataset.

-- Indexes improve query performance by allowing the database to find rows faster instead of scanning the entire table. They are especially useful for columns frequently used in WHERE, JOIN, ORDER BY, and GROUP BY clauses.


-- 15. Implement an index on the "Country/Region" column
-- to speed up search operations.

CREATE INDEX idx_country_name ON covid.country(name);

-- =========================================================
-- USER-DEFINED FUNCTIONS (UDF)
-- =========================================================

-- 16. Develop a UDF to calculate the mortality rate(deaths / confirmed cases * 100) for a given country.

CREATE OR REPLACE FUNCTION mortality_rate(p_country VARCHAR)
RETURNS NUMERIC
LANGUAGE SQL
AS $$
    SELECT
        CASE
            WHEN g.confirmed = 0 THEN 0
            ELSE (g.deaths::NUMERIC / g.confirmed) * 100
        END
    FROM covid.global_covid_stats g
    INNER JOIN covid.country c
        ON g.country_id = c.country_id
    WHERE c.name = p_country
    ORDER BY g.report_date DESC
    LIMIT 1;
$$;

-- Execute the function
SELECT mortality_rate('India');


-- 17. Create a UDF to determine the recovery rate(recovered / confirmed cases * 100) for a specific date.

CREATE OR REPLACE FUNCTION recovery_rate(
    p_country VARCHAR,
    p_date DATE
)
RETURNS NUMERIC
LANGUAGE SQL
AS $$
    SELECT
        CASE
            WHEN g.confirmed = 0 THEN 0
            ELSE (g.recovered::NUMERIC / g.confirmed) * 100
        END
    FROM covid.global_covid_stats g
    INNER JOIN covid.country c
        ON g.country_id = c.country_id
    WHERE c.name = p_country
      AND g.report_date = p_date;
$$;

-- Execute the function
SELECT recovery_rate('India', '2021-09-30');

-- =========================================================
-- GROUP BY
-- =========================================================

-- 18. Group the data by continent and calculate the total
-- number of confirmed cases for each continent.

SELECT
    c.continent,
    SUM(g.confirmed) AS total_confirmed
FROM covid.country c
INNER JOIN covid.global_covid_stats g
    ON c.country_id = g.country_id
WHERE g.report_date = (
    SELECT MAX(report_date)
    FROM covid.global_covid_stats
)
GROUP BY c.continent
ORDER BY total_confirmed DESC;


-- 19. Group the data by date and compute the total number
-- of deaths and recoveries for each date.

SELECT
    report_date,
    SUM(deaths) AS total_deaths,
    SUM(recovered) AS total_recovered
FROM covid.global_covid_stats
GROUP BY report_date
ORDER BY report_date;


-- 20. Group the data by country and calculate the average
-- number of new cases reported daily for each country.

SELECT
    c.name AS country,
    AVG(g.new_confirmed) AS average_new_cases
FROM covid.country c
INNER JOIN covid.global_covid_stats g
    ON c.country_id = g.country_id
GROUP BY c.name
ORDER BY average_new_cases DESC;

-- =========================================================
-- COVID-DATA-GLOBAL
-- =========================================================

-- 1. To find out the death percentage locally and globally.

-- Global death percentage
SELECT
    (SUM(g.deaths)::NUMERIC
     / NULLIF(SUM(g.confirmed), 0)) * 100
     AS global_death_percentage
FROM covid.global_covid_stats g
WHERE g.report_date = (
    SELECT MAX(report_date)
    FROM covid.global_covid_stats
);


-- Local / Country-wise death percentage
SELECT
    c.name AS country,
    (g.deaths::NUMERIC
     / NULLIF(g.confirmed, 0)) * 100
     AS death_percentage
FROM covid.country c
INNER JOIN covid.global_covid_stats g
    ON c.country_id = g.country_id
WHERE g.report_date = (
    SELECT MAX(report_date)
    FROM covid.global_covid_stats
)
ORDER BY death_percentage DESC;


-- 2. To find out the infected population percentage
-- locally and globally.

-- Global infected population percentage
SELECT
    (SUM(g.confirmed)::NUMERIC
     / NULLIF(SUM(c.population), 0)) * 100
     AS global_infected_percentage
FROM covid.country c
INNER JOIN covid.global_covid_stats g
    ON c.country_id = g.country_id
WHERE g.report_date = (
    SELECT MAX(report_date)
    FROM covid.global_covid_stats
);


-- Country-wise infected population percentage
SELECT
    c.name AS country,
    (g.confirmed::NUMERIC
     / NULLIF(c.population, 0)) * 100
     AS infected_population_percentage
FROM covid.country c
INNER JOIN covid.global_covid_stats g
    ON c.country_id = g.country_id
WHERE g.report_date = (
    SELECT MAX(report_date)
    FROM covid.global_covid_stats
)
ORDER BY infected_population_percentage DESC;


-- 3. To find out the countries with the highest infection rates.

SELECT
    c.name AS country,
    MAX(g.confirmed)::NUMERIC
        / NULLIF(c.population, 0) * 100 AS infection_rate
FROM covid.country c
INNER JOIN covid.global_covid_stats g
    ON c.country_id = g.country_id
GROUP BY c.name, c.population
ORDER BY infection_rate DESC;


-- 4. To find out the countries and continents
-- with the highest death counts.

-- Countries with highest death counts
SELECT
    c.name AS country,
    MAX(g.deaths) AS highest_deaths
FROM covid.country c
INNER JOIN covid.global_covid_stats g
    ON c.country_id = g.country_id
GROUP BY c.name
ORDER BY highest_deaths DESC;


-- Continents with highest death counts
SELECT
    c.continent,
    SUM(g.deaths) AS total_deaths
FROM covid.country c
INNER JOIN covid.global_covid_stats g
    ON c.country_id = g.country_id
WHERE g.report_date = (
    SELECT MAX(report_date)
    FROM covid.global_covid_stats
)
GROUP BY c.continent
ORDER BY total_deaths DESC;


-- 5. Average number of deaths by day
-- (Continents and Countries).

-- Country-wise average new deaths
SELECT
    c.name AS country,
    AVG(g.new_deaths) AS average_new_deaths
FROM covid.country c
INNER JOIN covid.global_covid_stats g
    ON c.country_id = g.country_id
GROUP BY c.name
ORDER BY average_new_deaths DESC;


-- Continent-wise average new deaths
SELECT
    c.continent,
    AVG(g.new_deaths) AS average_new_deaths
FROM covid.country c
INNER JOIN covid.global_covid_stats g
    ON c.country_id = g.country_id
GROUP BY c.continent
ORDER BY average_new_deaths DESC;


-- 6. Average of cases divided by the number of population
-- of each country (TOP 10).

SELECT
    c.name AS country,
    AVG(g.confirmed)::NUMERIC
        / NULLIF(c.population, 0) * 100
        AS average_infection_percentage
FROM covid.country c
INNER JOIN covid.global_covid_stats g
    ON c.country_id = g.country_id
GROUP BY c.name, c.population
ORDER BY average_infection_percentage DESC
LIMIT 10;


-- 7. Considering the highest value of total cases,
-- which countries have the highest rate of infection
-- in relation to population?

SELECT
    c.name AS country,
    g.confirmed AS highest_cases,
    (g.confirmed::NUMERIC
     / NULLIF(c.population, 0)) * 100 AS infection_rate
FROM covid.country c
INNER JOIN covid.global_covid_stats g
    ON c.country_id = g.country_id
WHERE g.confirmed = (
    SELECT MAX(confirmed)
    FROM covid.global_covid_stats
)
ORDER BY infection_rate DESC;


-- 8. Countries with the highest number of deaths.

SELECT
    c.name AS country,
    MAX(g.deaths) AS highest_deaths
FROM covid.country c
INNER JOIN covid.global_covid_stats g
    ON c.country_id = g.country_id
GROUP BY c.name
ORDER BY highest_deaths DESC;


-- 9. Continents with the highest number of deaths.

SELECT
    c.continent,
    SUM(g.deaths) AS total_deaths
FROM covid.country c
INNER JOIN covid.global_covid_stats g
    ON c.country_id = g.country_id
WHERE g.report_date = (
    SELECT MAX(report_date)
    FROM covid.global_covid_stats
)
GROUP BY c.continent
ORDER BY total_deaths DESC;

-- =========================================================
-- QUERIES ON VACCINATION
-- =========================================================

-- 1. Total vaccinated with at least 1 dose over time
-- (All countries).

SELECT
    v.date,
    SUM(v.first_dose) AS total_vaccinated
FROM covid.vaccination v
GROUP BY v.date
ORDER BY v.date;


-- 2. Percentage of the population vaccinated with at least
-- the first dose until 30/09/2021 (Top 3).

SELECT
    c.name AS country,
    s.name AS state,
    (
        SUM(v.first_dose)::NUMERIC
        / NULLIF(s.population, 0)
    ) * 100 AS people_vaccinated
FROM covid.vaccination v
INNER JOIN covid.state s
    ON v.state_id = s.state_id
INNER JOIN covid.country c
    ON s.country_id = c.country_id
WHERE v.date = (
    SELECT MAX(date)
    FROM covid.vaccination
    WHERE date <= '2021-09-30'
)
GROUP BY c.name, s.name, s.population
ORDER BY people_vaccinated DESC
LIMIT 3;


-- 3. To find out the population vs the number of people vaccinated.

SELECT
    c.name AS country,
    s.name AS state,
    s.population,
    v.first_dose,
    v.second_dose
FROM covid.state s
INNER JOIN covid.country c
    ON s.country_id = c.country_id
INNER JOIN covid.vaccination v
    ON v.state_id = s.state_id;


-- 4. To find out the percentage of different vaccines
-- taken by people in a country.

SELECT
    c.name,
    s.name,
    (
        SUM(v.covaxin)::NUMERIC / NULLIF(SUM(v.total_doses), 0)
    ) * 100 AS covaxin_percentage,

    (
        SUM(v.covishield)::NUMERIC
        / NULLIF(SUM(v.total_doses), 0)
    ) * 100 AS covishield_percentage,

    (
        SUM(v.sputnik_v)::NUMERIC
        / NULLIF(SUM(v.total_doses), 0)
    ) * 100 AS sputnik_v_percentage
FROM covid.vaccination v
INNER JOIN covid.state s
    ON v.state_id = s.state_id
INNER JOIN covid.country c
    ON s.country_id = c.country_id
GROUP BY c.name, s.name;


-- 5. To find out the percentage of people
-- who took both the doses.

SELECT
    s.name,
    (SUM(v.second_dose)::NUMERIC / NULLIF(SUM(v.first_dose), 0) ) * 100 AS both_dose_percentage
FROM covid.vaccination v
INNER JOIN covid.state s
    ON v.state_id = s.state_id
GROUP BY s.name
ORDER BY both_dose_percentage DESC;

-- =========================================================
-- INDIAN STATE-WISE ANALYSIS
-- =========================================================

-- 1. Total State-wise Confirmed Cases.

SELECT
    s.name AS state,
    SUM(cs.confirmed) AS total_confirmed
FROM covid.state s
INNER JOIN covid.covid_case_stats cs
    ON s.state_id = cs.state_id
GROUP BY s.name
ORDER BY total_confirmed DESC;


-- 2. Maximum Active Cases State-wise till date.

SELECT
    s.name AS state,
    MAX(cs.active_cases) AS maximum_active_cases
FROM covid.state s
INNER JOIN covid.covid_case_stats cs
    ON s.state_id = cs.state_id
GROUP BY s.name
ORDER BY maximum_active_cases DESC;


-- 3. Max Per Day Confirmed Cases in States.

SELECT
    s.name AS state,
    MAX(cs.new_confirmed) AS max_per_day_confirmed
FROM covid.state s
INNER JOIN covid.covid_case_stats cs
    ON s.state_id = cs.state_id
GROUP BY s.name
ORDER BY max_per_day_confirmed DESC;


-- 4. Max Per Day Death Cases in States.

SELECT
    s.name AS state,
    MAX(cs.new_deaths) AS max_per_day_deaths
FROM covid.state s
INNER JOIN covid.covid_case_stats cs
    ON s.state_id = cs.state_id
GROUP BY s.name
ORDER BY max_per_day_deaths DESC;


-- 5. State-wise Mortality Rate.

SELECT
    s.name AS state,
    (
        SUM(cs.deaths)::NUMERIC
        / NULLIF(SUM(cs.confirmed), 0)
    ) * 100 AS mortality_rate
FROM covid.state s
INNER JOIN covid.covid_case_stats cs
    ON s.state_id = cs.state_id
GROUP BY s.name
ORDER BY mortality_rate DESC;