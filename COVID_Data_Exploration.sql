-- DROP TABLE public.coviddeaths;

CREATE TABLE IF NOT EXISTS public.coviddeaths
(
    iso_code character varying(10) COLLATE pg_catalog."default",
    continent character varying(155) COLLATE pg_catalog."default",
    location character varying(155) COLLATE pg_catalog."default",
    date date,
    population bigint,
    total_cases bigint,
    new_cases bigint,
    new_cases_smoothed double precision,
    total_deaths bigint,
    new_deaths bigint,
    new_deaths_smoothed double precision,
    total_cases_per_million double precision,
    new_cases_per_million double precision,
    new_cases_smoothed_per_million double precision,
    total_deaths_per_million double precision,
    new_deaths_per_million double precision,
    new_deaths_smoothed_per_million double precision,
    reproduction_rate double precision,
    icu_patients bigint,
    icu_patients_per_million double precision,
    hosp_patients bigint,
    hosp_patients_per_million double precision,
    weekly_icu_admissions double precision,
    weekly_icu_admissions_per_million double precision,
    weekly_hosp_admissions double precision,
    weekly_hosp_admissions_per_million double precision
);

-- COPY coviddeaths
-- FROM '/Users/GerendChristopher/Downloads/coviddeaths.csv'
-- DELIMITER ';'
-- CSV HEADER;

-- TABLESPACE pg_default;

-- ALTER TABLE public.coviddeaths
    -- OWNER to "GerendChristopher";
	
CREATE TABLE IF NOT EXISTS public.covidvaccinations
(
	iso_code character varying(10) COLLATE pg_catalog."default",
    continent character varying(155) COLLATE pg_catalog."default",
    location character varying(155) COLLATE pg_catalog."default",
    date date,
	new_tests bigint,
	total_tests bigint,
	total_tests_per_thousand double precision,
	new_tests_per_thousand double precision,
	new_tests_smoothed bigint,
	new_tests_smoothed_per_thousand double precision,
	positive_rate double precision,
	tests_per_case double precision,
	tests_units character varying(155),
	total_vaccinations bigint,
	people_vaccinated bigint,
	people_fully_vaccinated bigint,
	total_boosters bigint,
	new_vaccinations bigint,
	new_vaccinations_smoothed bigint,
	total_vaccinations_per_hundred double precision,
	people_vaccinated_per_hundred double precision,
	people_fully_vaccinated_per_hundred double precision,
	total_boosters_per_hundred double precision,
	new_vaccinations_smoothed_per_million bigint,
	stringency_index double precision,
	population_density double precision,
	median_age double precision,
	aged_65_older double precision,
	aged_70_older double precision,
	gdp_per_capita double precision,
	extreme_poverty double precision,
	cardiovasc_death_rate double precision,
	diabetes_prevalence double precision,
	female_smokers double precision,
	male_smokers double precision,
	handwashing_facilities double precision,
	hospital_beds_per_thousand double precision,
	life_expectancy double precision,
	human_development_index double precision,
	excess_mortality double precision
);

-- COPY covidvaccinations
-- FROM '/Users/GerendChristopher/Downloads/covidvaccinations.csv'
-- DELIMITER ';'
-- CSV HEADER;

-- ALTER TABLE public.covidvaccinations
    -- OWNER to "GerendChristopher";

-- SELECT * FROM coviddeaths;
-- SELECT * FROM covidvaccinations;

-------------------------------------
-- Covid data from 1 January 2020 until 27 August 2021
-- Select data that will be used

SELECT location, date, population, total_cases, new_cases, total_deaths
FROM coviddeaths
ORDER BY 1, 2;


-- 1. Look at total cases vs. total deaths
-- First, change total cases and total deaths data types from bigint to real
ALTER TABLE coviddeaths
	ALTER COLUMN total_cases TYPE real,
	ALTER COLUMN total_deaths TYPE real;

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM coviddeaths
ORDER BY 1, 2;

-- Total cases vs. total deaths in Indonesia
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM coviddeaths
WHERE location like '%Indonesia%'
ORDER BY 2;


-- 2. Total cases vs. Population
-- Shows percentage of population got COVID
-- First, change total cases and total deaths data types from bigint to real
ALTER TABLE coviddeaths
	ALTER COLUMN population TYPE real;

SELECT location, date, total_cases, population, (total_deaths/population)*100 AS PercentPopulationInfected
FROM coviddeaths
-- WHERE location like '%Indonesia%'
ORDER BY 1,2;


-- 3. Look at Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount,
		MAX(total_cases/population)*100 AS PercentPopulationInfected
FROM coviddeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- Shows Countries with Highest Death Cases compared to Population
SELECT location, MAX(total_deaths) AS TotalDeath
FROM coviddeaths
GROUP BY location
ORDER BY TotalDeath DESC;
-- There is a problem in our data. World, Europe, Asia, etc. should be 
-- appear only in Continent column, but those are in Location column as well.
SELECT iso_code, location, continent
FROM coviddeaths
WHERE continent is null;
-- When the Continent is null, the values are moved to Location column.

SELECT location, MAX(total_deaths) AS TotalDeath
FROM coviddeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeath DESC;

-- Shows Continent with Highest Death Cases compared to Population

SELECT continent, MAX(total_deaths) AS TotalDeath
FROM coviddeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeath DESC;


-- 4. Global Numbers
-- First change new_cases and new_death data types
SELECT date, SUM(CAST(new_cases AS real)) AS summed_cases,
		SUM(CAST(new_deaths AS real)) AS summed_deaths,
		SUM(CAST(new_deaths AS real))/SUM(CAST(new_cases AS real))*100 AS DeathPercentage
FROM coviddeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1;


----------
-- Shows Total Population vs. Vaccinations

With VacvsPop (Continent, Location, Date, Population, New_Vaccinations, CummulativeVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS real)) 
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CummulativeVaccinated
FROM coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location
		AND dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (CummulativeVaccinated/Population)*100 AS PercentVaccinatedPopulation
FROM VacvsPop;

---------
-- Creating view

CREATE VIEW VaccinatedPopulation AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS real)) 
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CummulativeVaccinated
FROM coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location
		AND dea.date = vac.date
WHERE dea.continent is not null;
