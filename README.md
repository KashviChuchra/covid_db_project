# COVID-19 Database Project

A PostgreSQL database project designed to store, organize, and analyze COVID-19 cases, deaths, recoveries, population, and vaccination data at country, state, and district levels.

The project focuses on practicing relational database design and SQL concepts through real-world COVID-19 data.

## Project Overview

The database organizes COVID-19 information into related tables using primary keys and foreign keys. It supports queries for analyzing case trends, deaths, recoveries, vaccination progress, and country/state/district-level statistics.

The project was created to practice PostgreSQL concepts such as:

* Database and schema design
* Primary and foreign keys
* Constraints
* DDL and DML
* Joins
* Subqueries
* CTEs
* Views
* Stored procedures
* User-defined functions
* Triggers
* Transactions
* Indexing
* Aggregation and grouping
* Date-based analysis

## Database Structure

The project uses the `covid` schema.

### Main Tables

#### Country

Stores country-level information.

* `country_id`
* `name`
* `continent`
* `population`

#### State

Stores state-level information and connects each state to a country.

* `state_id`
* `country_id`
* `name`
* `population`

#### District

Stores district-level information and connects each district to a state.

* `district_id`
* `state_id`
* `name`

#### COVID Case Statistics

Stores COVID-19 case information by date.

The table contains information such as:

* Confirmed cases
* Deaths
* Recovered cases
* Active cases
* New cases
* Report date

#### Global COVID Statistics

Stores aggregated COVID-19 statistics for broader analysis.

#### Vaccination

Stores vaccination-related information over time, including first-dose and other vaccination statistics.

## Relationships

The database follows a hierarchical structure:

```text
Country
   |
   └── State
         |
         └── District
```

COVID statistics can be connected with country and state information using foreign keys.

## Repository Structure

```text
covid_db_project/
│
├── data/
│   └── Database data files
│
├── docs/
│   └── Project documentation
│
├── queries_and_solutions/
│   └── SQL questions and solutions
│
└── schema/
    └── Database schema and SQL scripts
```

## Key SQL Analysis

The project contains SQL queries for questions such as:

* Total confirmed COVID-19 cases
* Total deaths
* Total recovered cases
* Active cases
* Case trends over time
* Death statistics by country
* Vaccination progress
* Percentage of population vaccinated
* Country-level comparisons
* State-level COVID statistics
* Weekly changes in confirmed cases
* Latest available COVID-19 data
* Aggregated statistics using `GROUP BY`
* Data analysis using joins and subqueries

## PostgreSQL Concepts Used

### DDL

Used for creating and modifying database objects.

```sql
CREATE TABLE
ALTER TABLE
DROP TABLE
```

### DML

Used for working with data.

```sql
INSERT
UPDATE
DELETE
```

### Joins

Used to combine information from related tables.

```sql
INNER JOIN
LEFT JOIN
RIGHT JOIN
```

### CTEs

Common Table Expressions are used to break complex queries into smaller, readable steps.

```sql
WITH ...
```

### Subqueries

Used when the result of one query is required by another query.

### Views

Used to create reusable queries that can be accessed like virtual tables.

### Stored Procedures

Used to execute a predefined set of SQL statements.

### User-Defined Functions

Used to create reusable database functions that return a value or result.

### Triggers

Used to automatically execute logic when specific database events occur.

### Indexes

Used to improve query performance when searching or filtering data.

### Transactions

Used to ensure that a group of database operations is handled as a single unit.

## Example Query

```sql
SELECT
    c.name,
    SUM(s.confirmed) AS total_confirmed
FROM covid.country c
JOIN covid.covid_case_stats s
    ON c.country_id = s.country_id
GROUP BY c.name
ORDER BY total_confirmed DESC;
```

## Tools & Technologies

* PostgreSQL
* pgAdmin
* SQL
* Git
* GitHub

## Learning Objectives

This project helped me strengthen my understanding of:

* Relational database design
* SQL query writing
* Database relationships
* Data aggregation
* Query optimization
* PostgreSQL programming
* Real-world data analysis

## How to Use

1. Install PostgreSQL.
2. Open pgAdmin or another PostgreSQL client.
3. Create a PostgreSQL database.
4. Create the required `covid` schema.
5. Execute the schema scripts from the `schema` folder.
6. Load the required data from the `data` folder.
7. Run the SQL queries from the `queries_and_solutions` folder.

## Project Purpose

This project was developed as a hands-on PostgreSQL learning project to understand how a real-world dataset can be modeled using relational database concepts and analyzed using SQL.

## Author

**Kashvi Chuchra**

B.E. Computer Science Engineering
