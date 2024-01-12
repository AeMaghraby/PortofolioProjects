select * from CovidDeath where continent is not null order by 3, 4
select * from CovidVaccinations order by  3, 4

--Select Data that we are going to be using
select location, date, total_cases, new_cases, total_deaths, population 
from CovidDeath 
where continent is not null
order by 1, 2

--Looking at Total Cases vs Total Deaths at Specific Location
select location, date, total_cases, total_deaths, 
(cast(total_deaths as float)/cast(total_cases as float)) * 100 as DeathPercentage
from CovidDeath 
where location like '%states%' 
order by 1, 2

--Looking at Total Cases vs Population
--Shows what Percentage of Population infected with Covid
select location, date, population, total_cases,
(cast(total_cases as float)/cast(population as float))*100 as DeathPercentage
from CovidDeath 
where location like '%states%' 
order by 1, 2

--Countries with Highest Infection Rate Compared to Population
select location, population, max(total_cases) as HighestInfectionCount, max((total_cases/population))*100 as PercentPopulationInfected
from CovidDeath
group by location, population
order by 4 desc

--Breaking Things Down By Continent

--Sowing Continents with the Highest Death Count Per Population
select continent , max(cast(total_deaths as int)) as totalDeathCount 
from CovidDeath
where continent is  not null
group by continent
order by totalDeathCount desc

-- GLOBAL NUMBERS
select  sum(new_cases) as TotalCases , SUM(new_deaths) as TotalDeath, (sum(new_deaths)/sum(new_cases))*100 as DeahPercentage  
from CovidDeath
where continent is not null
order by 1, 2

--TOTAL VACCINATION VS POPULATION
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) RollingPeopleVaccinated
FROM CovidVaccinations vac
join CovidDeath dea on 
 dea.location=vac.location 
 and dea.date=vac.date
where dea.continent is not null 
order by 2,3

 --Use CTE to Perform Calculation on Partition by in Pervious Query
	WITH PopVsVac (continent, location, date, population,new_vaccinations, RollingPeopleVaccinated) 
as
	(
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) RollingPeopleVaccinated
	FROM CovidVaccinations vac
	join CovidDeath dea 
	on dea.location=vac.location 
	and dea.date=vac.date
	where dea.continent is not null 
	)
	select *,(RollingPeopleVaccinated/population)*100 from PopVsVac

--Using Temp Table to perform Calculation on Partition By in previous query
drop table if exists #PercentPopulationVaccinated
	CREATE TABLE #PercentPopulationVaccinated 
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric, 
RollingPeopleVaccinated numeric
)
insert into #PercentPopulationVaccinated

	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) RollingPeopleVaccinated
	FROM CovidVaccinations vac
	join CovidDeath dea 
on dea.location=vac.location 
and dea.date=vac.date

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeath dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 