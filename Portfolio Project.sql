SELECT *
FROM CovidDeaths
WHERE continent is not NULL
ORDER BY 3, 4

--SELECT *
--FROM CovidVaccinations
--ORDER BY 3, 4

-- Select Data that we are going to be starting with

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent is not NULL
ORDER BY 1, 2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
--WHERE location = 'Lebanon'
WHERE continent is not NULL
ORDER BY 1, 2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

SELECT location, date, population, total_cases, (total_cases/population)*100 AS InfectedPercentage
FROM CovidDeaths
--WHERE location = 'Lebanon'
WHERE continent is not NULL
ORDER BY 1, 2

-- Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS MaxInfectedPercentage
FROM CovidDeaths
--WHERE location = 'Lebanon'
WHERE continent is not NULL
GROUP BY location, population
ORDER BY MaxInfectedPercentage DESC

-- Countries with Highest Death Count per Population

SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
--WHERE location = 'Lebanon'
WHERE continent is NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;


-- Showing contintents with the highest death count per population

SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
--WHERE location = 'Lebanon'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

--Global numbers

SELECT  SUM(new_cases) as total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2




-- the below query: first of what we did is that we wanted to see each location's population, new_vaccination according 
-- to the date. then we created the RollingPeopleVacc in order to sum day by day the new vaccinations according to location.
-- lastly we want to see the percentage of the RollingPeopleVacc according to the population, so we have to use a CTE or
-- a temp_table, since we can't use a column we just created.

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVacc
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;

-- USE CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVacc)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVacc
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3
)
SELECT *, (RollingPeopleVacc/population)*100
FROM PopvsVac


--USE TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVacc numeric
)


INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVacc
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

SELECT *, (RollingPeopleVacc/population)*100
FROM #PercentPopulationVaccinated

-- NOTE: ORDER BY DOESN'T WORK WITH CTE, WHILE WITH TEMP TABLES IT WORKS PERFECTLY

-- end of query

-- same query as above but checking the max percentage for each location

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVacc
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;

-- USE CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVacc, VaccinationPercentage)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVacc,
(SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) / dea.population) * 100 AS VaccinationPercentage
FROM CovidDeaths dea
JOIN CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)

SELECT continent, location, population,
MAX(VaccinationPercentage) AS MaxVaccinationPercentage
FROM PopvsVac
GROUP BY continent, location, population;

-- end of query

----------------------------------------------------------------------------------------------

--Creating views to store data for later visualizations

-- Death Percentage view

CREATE VIEW DeathPercentage AS
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent is not NULL

SELECT *
FROM DeathPercentage

-- Infected Percentage View

CREATE VIEW InfectedPercentage AS
SELECT location, date, population, total_cases, (total_cases/population)*100 AS InfectedPercentage
FROM CovidDeaths
WHERE continent is not NULL

SELECT *
FROM InfectedPercentage

-- Max Infected Percentage

CREATE VIEW MaxInfectedPercentage AS
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS MaxInfectedPercentage
FROM CovidDeaths
WHERE continent is not NULL
GROUP BY location, population

SELECT *
FROM MaxInfectedPercentage

-- Countries Total Death Count View

CREATE VIEW TotalDeathCount AS
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
WHERE continent is NOT NULL
GROUP BY location

SELECT *
FROM TotalDeathCount

-- Continents Total Death Count View

CREATE VIEW ContinentDeathCount AS
SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent

SELECT *
FROM ContinentDeathCount

-- Global Numbers View

CREATE VIEW GlobalNumbers AS
SELECT  SUM(new_cases) as total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL

SELECT *
FROM GlobalNumbers

-- Percent Population Vaccinated View

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVacc
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent IS NOT NULL

Select *
FROM PercentPopulationVaccinated