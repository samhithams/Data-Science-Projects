---Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

SELECT * from Covid.dbo.CovidDeaths$
order by 3,4


---Select data you need
---Percentage of Deaths from all the cases 
SELECT Location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercent
from Covid.dbo.CovidDeaths$
where location like '%states%'
order by 1,2

---Total cases among population

Select Location, date, total_cases, population, (total_cases/population)*100 as Casespercentage 
from Covid.dbo.CovidDeaths$
where location like '%states%'
order by 1,2

--Infection Rate by population in all countries
Select Location, Population, MAX( total_cases) as InfectionCount,  (MAX(total_cases/population))*100 as InfectedPercentinPopul 
from Covid.dbo.CovidDeaths$
--where location like '%states%'
group by Location,Population
order by InfectedPercentinPopul desc

--Death Count in countries
--Use cast( .. as int) to get valid results for your numerical columns
Select Location, Max(cast(total_deaths as int)) as DeathCount
from Covid.dbo.CovidDeaths$
where continent is not null
group by Location
order by DeathCount desc

--Global Numbers

--Death count by continents
Select continent, Max(cast(total_deaths as int)) as DeathCount
from Covid.dbo.CovidDeaths$
where continent is not null
group by continent
order by DeathCount desc

--New cases with infected percentage
Select date, sum(new_cases) as ToalNewcases,sum(cast(new_deaths as int)) as Totalnewdeaths, (sum(cast(new_deaths as int))/SUM(new_cases))*100 as InfectedPercentage
from Covid.dbo.CovidDeaths$
where continent is not null
group by date
order by 1,2

--Total New Cases, New Deaths
Select  sum(new_cases) as ToalNewcases,sum(cast(new_deaths as int)) as Totalnewdeaths, (sum(cast(new_deaths as int))/SUM(new_cases))*100 as InfectedPercentage
from Covid.dbo.CovidDeaths$
where continent is not null
order by 1,2

--Covid deaths and Vaccination analysis
-- As we are considering day-to-day data, we can find the rolling sum of new vac per day through sum over partition

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from Covid..CovidDeaths$ dea
Join Covid..CovidVaccinations$ vac 
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3

--We could not use the column RollingPeopleVaccinated to create another column of percentage, so we use Common Table Expression(CTE)

With PopsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from Covid..CovidDeaths$ dea
Join Covid..CovidVaccinations$ vac 
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null)

Select * , (RollingPeopleVaccinated/population)*100 as RollingPeopleVaccPercent
from PopsVac

--Same process by using TEMP Table

DROP TABLE if exists #PercentPopulVaccinated

Create Table #PercentPopulVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric)

Insert into #PercentPopulVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from Covid..CovidDeaths$ dea
Join Covid..CovidVaccinations$ vac 
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null

Select * , (RollingPeopleVaccinated/population)*100 as RollingPeopleVaccPercent
from #PercentPopulVaccinated

-- Creating View for later visualizations

Create VIEW
PercentPopulVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from Covid..CovidDeaths$ dea
Join Covid..CovidVaccinations$ vac 
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null

DROP VIEW PercentPopulVaccinated

