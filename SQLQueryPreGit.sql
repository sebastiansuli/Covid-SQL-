-- SQL Data Exploration Project for Portfolio

/* This project contains global COVID-19 data. 

There are two tables:
- 'Deaths' - data of cases, deaths and hospitalizations. There are columns like location, date, population, total cases/deaths, new cases/deaths, cases/deaths per milion, 
	reproduction rate, hospitalizated patients and patients per million
- 'Vax' - this table contains columns such as location, date, total/new tests, tests_per thousand, positive rate, tests per case, total/new vaccinations, people vaccinated and data about 
	population, ages, smokers, diabetes etc.

They are from ourworldindata.org
Purpose of this analysis is to make some observation about data and just to show some SQL skills. 

There are two stages here, the first where I analyze table A and use SELECT, FROM, WHERE and aggregation functions
and second stage, mostly technical, without much analyzing, with tables 'Deaths' and 'Vax', where I use JOINS, TEMP TABLES, DROP TABLE, WITH, OVER, Views.

*/

-- First table, cases and deaths:

Select *
From PortfolioProject..Deaths
Where continent is not null 
order by 3,4

-- Second table, vaxxes and tests:

Select *
From PortfolioProject..Vax
Where continent is not null 
order by 3,4


-- Total Cases vs Total Deaths

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..Deaths
Where location like 'Poland'
and continent is not null 
order by DeathPercentage DESC;

-- New cases vs New deaths

Select Location, date, new_cases, new_deaths, (new_deaths/new_cases)*100 as NewDeathPercentage
From PortfolioProject..Deaths
Where location like 'Poland'
and continent is not null 
order by new_cases DESC;

-- Total cases vs population

Select Location, date, total_cases, population, (total_cases/population)*100 as CasesPercentage
From PortfolioProject..Deaths
Where location like 'Poland'
and continent is not null 
order by CasesPercentage DESC;

-- New cases vs population

Select Location, date, new_cases, population, (new_cases/population)*100 as NewCasesPercentage
From PortfolioProject..Deaths
Where location like 'Poland'
and continent is not null 
order by NewCasesPercentage DESC;

/* The first infection was registered 2020-03-04 andd first dead 2020-03-12.
In the begining of pandemic in Poland death percentage was about 1/2% with growth to 5% in april and may - it was the highest death percentages. Then persisted in holidays at level of 3/4 perceentage points.
Next mutations of covid weren't that deadly, deaths to cases ratio usually was lower, but there was a time in may-july 2021 when NewDeathPercentage was the highest and even higher than 20%!
Probably it was because at that time not many tests have been done due to the period with less infections. At the same time, the holidays made the government want to open 
the economy or schools in these most active months.
The highest new cases were at begining of 2022 but there weren't new deaths as much as cases. For example NewDeathPercentage in most of january was about 0.5%, but NewCasesPercentage was the highest,
even higher than 0.1%, that's more than 40k infected in one day.
In the last measured day - 2022-12-20 - CasesPercentage was about 16%, it should mean that 16% of population passed the COVID-19, but we must to remember that one person could passed it two or more time
and these figures are not accurate, the number of infections was probably several times higher.
*/


-- What about world? 


-- Highest cases/population

Select Location, Population, MAX(total_cases) as HighestInfectCount, MAX((total_cases/population))*100 as CasesPercentage
From PortfolioProject..Deaths
Group by Location, Population
order by HighestInfectCount desc

-- The highest CasesPercentage is in Cyprus - 69.8%. On next places are San Marino, Faeroe Islands, there are mostly small or island countries, where is easier to test people, just closed circuits. 
-- What about bigger countries? France have a 57.5% of CasesPercentage and USA with the highest HighestInfectCount have a 29.5%. Poland for example 16%.


-- Highest deaths/population 

Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount, MAX((total_deaths/population))*100 as DeathsPercentage
From PortfolioProject..Deaths
Where continent is not null 
Group by Location, Population
order by 3 desc

-- Highest DeathsPercentage is in Peru, next places Bulgaria and Bosnia. United States have a 19th place and Poland 26.


-- Case-fatality rates for countries

Select location, population, MAX(total_cases) as TotalCasesCount, MAX(cast(total_deaths as int)) as TotalDeathCount, MAX(cast(total_deaths as int))/MAX(total_cases)*100 as CaseFatalityRate
From PortfolioProject..Deaths
Where continent is not null 
Group by Location, Population
order by CaseFatalityRate desc

-- The highest Case-fatality rates have so-called third world countries such as Yemen, Sudan, Syria.


-- Global development of COVID-19. 

Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathsPercentage
From PortfolioProject..Deaths
Where continent is not null 
Group by date
order by 1, 2



-- Analysis with Tests and Vaccinations 



-- Look on vax and tests by country and date

SELECT d.location, d.date, d.total_cases, d.total_deaths, v.total_vaccinations, v.total_tests
FROM PortfolioProject..Deaths d
JOIN PortfolioProject..Vax v
ON d.location = v.location AND d.date = v.date
WHERE d.continent is not null -- Filter by continent (optional)
  AND d.total_cases > 1000 
  AND v.total_vaccinations IS NOT NULL
  AND v.total_tests is not null 
ORDER BY d.location, d.date;


-- CTE to calculate the case-fatality rate and vaccination rate for each country

WITH combined_data AS (
	SELECT d.population, d.continent, d.location, d.date, d.total_cases, d.total_deaths, v.total_vaccinations
	From PortfolioProject..Deaths d
	Join PortfolioProject..Vax v
	ON d.location = v.location AND d.date = v.date
)

SELECT location, date, total_cases, total_deaths, total_vaccinations, 
	total_deaths / total_cases AS case_fatality_rate,
	total_vaccinations / population AS vaccination_rate
FROM combined_data
WHERE continent is not null 
ORDER BY location, date;


-- CTE for rolling averages of daily new cases, deaths and vaccinations for each country, 
-- rolling of 7 days including the current day, partition by is for reset rolling for each country, order by to rolling chronological 

WITH combined_data AS (
  SELECT d.location,
         d.date,
         d.new_cases,
         d.new_deaths,
         v.new_vaccinations
	From PortfolioProject..Deaths d
	Join PortfolioProject..Vax v
  ON d.location = v.location AND d.date = v.date
), 
aggregated_data AS (
  SELECT location,
         date,
         SUM(CAST(new_cases as FLOAT)) OVER (PARTITION BY location ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_avg_new_cases,
         SUM(CAST(new_deaths as FLOAT)) OVER (PARTITION BY location ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_avg_new_deaths,
         SUM(CAST(new_vaccinations as FLOAT)) OVER (PARTITION BY location ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_avg_new_vaccinations
  FROM combined_data
)
SELECT *
FROM aggregated_data
ORDER BY location, date;


-- Temporary table with CFR calculation and non-null vaccination rate

DROP Table if exists #cfrTable
SELECT d.location, d.date, d.total_cases, d.total_deaths, v.total_vaccinations, d.population,
    total_deaths / total_cases AS cfr,
    total_vaccinations / d.population AS vaccination_rate
INTO #cfrTable
From PortfolioProject..Deaths d
Join PortfolioProject..Vax v
ON d.location = v.location AND d.date = v.date
WHERE v.total_vaccinations IS NOT NULL;

-- Compare temp table to original table with both CFR and vaccination rate
SELECT t.*, d.total_cases_per_million, d.total_deaths_per_million, d.reproduction_rate
FROM #cfrTable t
JOIN PortfolioProject..Deaths d ON t.location = d.location AND t.date = d.date
ORDER BY t.location, t.date;


-- Temporary table with rolling people vaccination (another way)

DROP Table if exists #PopVac
Create Table #PopVac
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vac numeric
)

Insert into #PopVac

Select d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(Convert(float, v.new_vaccinations)) OVER (Partition by d.location, d.date) as rolling_people_vac
From PortfolioProject..Deaths d
Join PortfolioProject..Vax v
	On d.location = v.location
	and d.date = v.date
Where d.continent is not null

Select *, (rolling_people_vac/population)*100
From #PopVac


-- View with aggregated data for countries

GO

Create View aggCovid AS (
	SELECT d.location, 
		MAX(d.date) AS latest_date, 
		SUM(d.total_cases) AS total_cases, 
		SUM(CAST(d.total_deaths as FLOAT)) AS total_deaths, 
		SUM(CAST(v.total_vaccinations as FLOAT)) AS total_vaccinations,
		AVG(CAST(d.total_cases_per_million as FLOAT)) AS avg_total_cases_per_million,
		AVG(CAST(d.total_deaths_per_million as FLOAT)) AS avg_total_deaths_per_million,
		AVG(CAST(v.total_vaccinations as FLOAT) / CAST(d.population as FLOAT)) AS avg_vaccination_rate
	From PortfolioProject..Deaths d
	Join PortfolioProject..Vax v
	ON d.location = v.location AND d.date = v.date
	WHERE d.continent is not null
	GROUP BY d.location);   

GO 

DROP VIEW aggCovid;

