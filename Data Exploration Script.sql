/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT
    [location],
    continent,
    [date],
    total_cases,
    new_cases,
    total_deaths,
    [population]
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;


-- Total Cases vs. Total Deaths for India
SELECT
    [location],
    [date],
    total_cases,
    total_deaths,
    (CAST(total_deaths AS INT)/total_cases)*100 AS death_percentage
FROM CovidDeaths
WHERE [location] = 'India'
ORDER BY 1, 2;


-- Total Cases vs. Population for India
SELECT
    [location],
    [date],
    total_cases,
    [population],
    (total_cases/[population])*100 AS cases_percentage
FROM CovidDeaths
WHERE [location] = 'India'
ORDER BY 1, 2;


-- Countries with Highest Infection Rates compared to Population
SELECT
    [location],
    [population],
    MAX(total_cases) AS highest_infection_count,
    MAX((total_cases/[population]))*100 AS infected_population_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY [location], [population]
ORDER BY infected_population_percentage DESC;


-- Countries with Highest Death Count
SELECT
    [location],
    MAX(CAST(total_deaths AS INT)) AS highest_death_count
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY [location]
ORDER BY highest_death_count DESC;


-- Continents with Highest Death Count
SELECT
    continent,
    MAX(CAST(total_deaths AS INT)) AS highest_death_count
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY highest_death_count DESC;


-- Total Cases vs. Total Deaths for the World
SELECT
    SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS INT)) AS total_deaths,
    (SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100 AS death_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1;


-- Total Vaccinations vs. Total Population
WITH
    PopvsVac (Continent, Location, Date, Population, New_Vaccinations, Rolling_Total_Vaccinations)
    AS
    (
        SELECT
            dea.continent,
            dea.location,
            dea.date,
            dea.population,
            vac.new_vaccinations,
            SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_total_vaccinations
        FROM CovidDeaths dea
            JOIN CovidVaccinations vac
            ON dea.location = vac.location
                AND dea.date = vac.date
        WHERE dea.continent IS NOT NULL
    )
SELECT
    Location,
    Population,
    MAX(Rolling_Total_Vaccinations) AS Total_Vaccinations,
    MAX(Rolling_Total_Vaccinations/Population)*100 AS Percent_Vaccinated
FROM PopvsVac
WHERE Continent IS NOT NULL
GROUP BY Location, Population
ORDER BY 4 DESC


-- Using Temp Table to perform Calculation on Partition By in previous query
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
)

INSERT INTO #PercentPopulationVaccinated
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
        AND dea.date = vac.date

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated


-- Creating Views to use data in Tableau
CREATE VIEW PercentPopulationVaccinated
AS
    SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_total_vaccinations
    FROM CovidDeaths dea
        JOIN CovidVaccinations vac
        ON dea.location = vac.location
            AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL