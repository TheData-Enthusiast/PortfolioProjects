SELECT*
FROM PortfolioProject.dbo.CovidDeaths$
WHERE continent is not null
ORDER BY 3,4

SELECT*
FROM PortfolioProject.dbo.CovidVaccinations$
ORDER BY 3,4


--This query returns the range of data we will be working within the CovidDeaths table

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths$
ORDER BY location, date --You can either write it as ORDER BY 1,2

-- Now let's calculate the percentage of death related to the number of cases
-- Total cases VS total deaths (Given the number of cases in a location, what is the percentage of deaths?)

SELECT location, date, total_cases, total_deaths, ROUND((total_deaths *1.0/total_cases)*100,2) AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths$
ORDER BY location, date

--I attempted to round up the result of this query above but I got this error
--Msg 8115, Level 16, State 8, Line 17
--Arithmetic overflow error converting nvarchar to data type numeric.
-- Reason being total_cases, total_deaths, or both being stored as nvarchar rather than numeric types.

SELECT location, date, total_cases, total_deaths, ROUND((CONVERT(FLOAT,total_deaths) *1.0/CONVERT(FLOAT,total_cases))*100,2) AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths$
WHERE location = 'Cameroon' OR location = 'United States' -- Probalities of dying if you had COVID
ORDER BY location, date


--*****SOME CONTEXT****

--COVID-19 was declared a pandemic by the World Health Organization (WHO) on March 11, 2020. 
--This declaration was made as the coronavirus, which was first identified in December 2019 in Wuhan, China, had spread rapidly across the globe, 
--affecting a large number of countries and leading to significant health, economic, and social impacts worldwide.


--Total cases VS Population
--What is the percentage of the population that got COVID?

SELECT location, date, population, total_cases, (total_cases/population) *100 AS PercentagePopInfected
FROM PortfolioProject.dbo.CovidDeaths$
WHERE location = 'Cameroon' OR location = 'United States'
ORDER BY location, date

-- After a quick internet search, I came up with this query to get rid of the exponential format

SELECT location, date, population, total_cases,
       FORMAT((total_cases * 1.0 / population) * 100, 'N4') AS DeathPercentagePop
FROM PortfolioProject.dbo.CovidDeaths$
--WHERE location = 'Cameroon'OR location = 'United States'
ORDER BY location, date 

--Countries with the highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population) *100 
       AS PercentagePopInfected
FROM PortfolioProject.dbo.CovidDeaths$
--WHERE location = 'Cameroon' OR location = 'United States'
WHERE total_cases is not null
GROUP BY location, population
ORDER BY PercentagePopInfected DESC

--Countries with the highest death count per population (How many people died from COVID?)

SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths$
WHERE continent is not null--In our CovidDeath$ table some location = continent because continent = NULL
GROUP BY location
ORDER BY TotalDeathCount DESC


--LET'S EXPLORE AND FILTER THE DATA PER CONTINENT


--This query returns the range of data we will be working within the CovidDeaths table

SELECT continent, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths$
WHERE continent is not null AND total_cases is not null AND new_cases is not null AND total_deaths is not null
ORDER BY continent, date

-- Now let's calculate the percentage of death related to the number of cases
-- Total cases VS total deaths (Given the number of cases in a continent, what is the percentage of deaths?)

SELECT continent, date, total_cases, total_deaths, ROUND((CONVERT(FLOAT,total_deaths) *1.0/CONVERT(FLOAT,total_cases))*100,2) AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths$
--WHERE continent = 'Africa' OR continent = 'North America' -- Probalities of dying if you had COVID
WHERE continent is not null AND total_cases is not null AND new_cases is not null AND total_deaths is not null
ORDER BY continent, date

--Total cases VS Population
--What is the percentage of the population that got COVID?

SELECT continent, date, population, total_cases,
       FORMAT((total_cases * 1.0 / population) * 100, 'N4') AS DeathPercentagePop
FROM PortfolioProject.dbo.CovidDeaths$
--WHERE location = 'Cameroon'OR location = 'United States'
WHERE continent is not null AND total_cases is not null
ORDER BY continent, date 

--Continents with the highest death count per population (How many people died from COVID?)

SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths$
WHERE continent is not null--In our CovidDeath$ table some location = continent because continent = NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC


--Percentage of death around the world
SELECT SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS int)) AS TotalDeaths, 
SUM(CAST(new_deaths AS int))/SUM(new_cases) * 100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths$
WHERE continent is not null
ORDER BY 1,2


SELECT *
FROM PortfolioProject.dbo.CovidDeaths$ dea
JOIN PortfolioProject.dbo.CovidVaccinations$ vac
   ON dea.location = vac.location
   AND dea.date = vac.date

                 --BREAK DOWN OF THIS JOIN ABOVE (LINES 123-127)

--In this SQL command, we are working with two tables from a database called PortfolioProject. 
--The tables are named CovidDeaths$ (we'll call it "dea" for short) and CovidVaccinations$ (we'll call it "vac" for short)
--When we say FROM (line 124) PortfolioProject.dbo.CovidDeaths$ dea, it means we're starting with the CovidDeaths$ table
--The JOIN part (line 125) is where we start to overlay our two maps (tables). 
--By default, JOIN is an INNER JOIN, which means we only want to see locations and dates that appear in both tables
--The ON dea.location = vac.location AND dea.date = vac.date part (lines 126-127) tells the database how to match the two maps (tables). 
--It's saying, "Put the information together only when the location and the date on both tables are exactly the same." 


--Total population VS vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject.dbo.CovidDeaths$ dea
JOIN PortfolioProject.dbo.CovidVaccinations$ vac
   ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

--Rolling count of the number of people vaccinated per location and date
-- This displays a sort of cumulative count of the number of vaccinations per location and date.
--Cool stuff here

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
     SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
	 AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths$ dea
JOIN PortfolioProject.dbo.CovidVaccinations$ vac
   ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent is not null AND dea.new_vaccinations is not null
ORDER BY 2,3

                       --CTE (Common Table Expressions)
--A Common Table Expression (CTE) is a temporary result set that you can reference within a SELECT, INSERT, UPDATE, or DELETE statement. 
--CTEs can be thought of as named temporary views for a single query
-- Using a CTE in our code here is suitable to prepare data for aggregation.
-- Calculations need to be applied on "RollingPeopleVaccinated"

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
     SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
	 AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths$ dea
JOIN PortfolioProject.dbo.CovidVaccinations$ vac
   ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent is not null AND dea.new_vaccinations is not null
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/ population) *100
FROM PopvsVac

              --TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
     SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
	 AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths$ dea
JOIN PortfolioProject.dbo.CovidVaccinations$ vac
   ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent is not null AND dea.new_vaccinations is not null
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/ population) *100
FROM #PercentPopulationVaccinated

--CREATE A VIEW FOR VISUALIZATION

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
     SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
	 AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths$ dea
JOIN PortfolioProject.dbo.CovidVaccinations$ vac
   ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent is not null AND dea.new_vaccinations is not null
--ORDER BY 2,3


--     QUERIES FOR VISUALIZATION

--Percentage of deaths around the world

SELECT SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS int)) AS TotalDeaths, 
SUM(CAST(new_deaths AS int))/SUM(new_cases) * 100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths$
WHERE continent is not null
ORDER BY 1,2

--Locations with the highest death count per population (How many people actually died from COVID-19?)

SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths$
WHERE continent is null AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY TotalDeathCount DESC


SELECT location, SUM(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths$
WHERE continent is null AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY TotalDeathCount DESC


SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population) *100 
       AS PercentagePopInfected
FROM PortfolioProject.dbo.CovidDeaths$
--WHERE location = 'Cameroon' OR location = 'United States'
--WHERE total_cases is not null
GROUP BY location, population
ORDER BY PercentagePopInfected DESC


SELECT location, population, date, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population) *100 
       AS PercentagePopInfected
FROM PortfolioProject.dbo.CovidDeaths$
--WHERE location = 'Cameroon' OR location = 'United States'
--WHERE total_cases is not null
GROUP BY location, population, date
ORDER BY PercentagePopInfected DESC
