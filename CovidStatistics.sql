select *
from covid..CovidVaccinations$
order by 3,4;

select location, date, total_cases, new_cases, total_deaths, population
from covid..CovidDeaths$
order by 1,2

-- total cases vs total deaths
-- shows likelihood of dying if you contract covid in your country
Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From covid..CovidDeaths$
Where location like '%states%'
and continent is not null 
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From covid..CovidDeaths$
--Where location like '%states%'
order by 1,2

-- Countries with Highest Infection Rate compared to Population
Select Location, Population,DATE, max( total_cases) as HighestInfectionCount,  max(total_cases/population)*100 as PercentPopulationInfected
From covid..CovidDeaths$
--Where location like '%states%'
group by location, population,date
order by 5 desc

-- showing countries with highest death count per population
Select Location,max(cast(total_deaths as int)) as TotalDeathCount
From covid..CovidDeaths$
--Where location like '%states%'
where continent is not null
group by location
order by 2 desc

-- breaking things down by continent

-- showing contintents with the highest death count per population

select continent, max(cast(total_deaths as int)) as TotalDeathCount
from covid..CovidDeaths$
where continent is not null
group by continent
order by 2 desc

-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From covid..CovidDeaths$
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

-- by continent, take 'world', 'european union', 'international' out

select location, sum(cast(new_deaths as int)) as TotalDeathCount
from CovidDeaths$
where continent is null and location not in ('World', 'European union', 'international')
GROUP by location
order by TotalDeathCount DESC	

-- Total population vs Vaccinations
-- shows percentage of population that has received at least one covid vaccine

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(int, vac.new_vaccinations)) over (Partition by dea.location order by dea.location, dea.date) as rollingpeoplevaccinated
--, (rollingpeoplevaccinated/population)*100
from covid..CovidDeaths$ dea join covid..CovidVaccinations$ vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- USE CTE
with popvsvac (continent, location, date, population, new_Vaccinations, rollingpeoplevaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location,
dea.date) as rollingpeoplevaccinated
--, (rollingpeoplevaccinated/population) * 100
from covid..CovidDeaths$ dea
join covid..CovidVaccinations$ vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
-- order by 2,3
)
select *, (rollingpeoplevaccinated/population) *100
from popvsvac

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From covid..CovidDeaths$ dea
Join CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths$ dea
Join CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

select *
from PercentPopulationVaccinated
