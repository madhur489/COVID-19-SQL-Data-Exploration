-- Find the highest total number of COVID-19 cases reported by each country.

select location,  max
(total_cases) as cases
from covid_death
where continent IS NOT NULL
group by location
order by cases desc;

-- Find the highest total number of COVID-19 deaths reported by each country.

select location,  max
(cast(total_deaths as int)) as deaths
from covid_death
where continent IS NOT NULL
group by location
order by deaths desc;

--Top 10 countries with highest infection percentage.

select top 10 location, (max(total_cases) * 100.0 / population) as infection_rate
from covid_death
where continent is not null
group by location, population
order by infection_rate desc;

--Find the highest total death count for each continent.

select continent, max
(cast(total_deaths as int)) as deaths
from covid_death
where continent IS NOT NULL
group by continent
order by deaths desc;

----Calculate the following global statistics:

---- Total Cases
-- Total Deaths
-- Death Percentage

SELECT
    SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS INT)) AS total_deaths,
    SUM(CAST(new_deaths AS INT)) * 100.0 / SUM(new_cases) AS death_percentage
FROM covid_death
WHERE continent IS NOT NULL;

--Join the CovidDeaths and CovidVaccinations tables and display:

--* Continent m
--* Country m 
--* Date m 
--* Population
--* New Vaccinations m 

select Covid_Vaccinations.continent, Covid_Vaccinations.location,
Covid_Vaccinations.date, covid_death.population, 
Covid_Vaccinations.new_vaccinations
from Covid_Vaccinations join covid_death
on covid_death.location = Covid_Vaccinations.location
and covid_death.date = Covid_Vaccinations.date
where covid_death.continent is not null;

--Calculate the running total of vaccinations for each country.

select location, date, new_vaccinations, 
sum(cast(new_vaccinations as int)) over 
(partition by location 
order by date) as running_total
from Covid_Vaccinations;

--Calculate the percentage of the population
--vaccinated using the running total vaccinations.

select covid_death.location, covid_death.date, covid_vaccinations.new_vaccinations,
covid_death.population,
sum(cast(new_vaccinations as int)) over 
(partition by covid_death.location 
order by covid_death.date) as running_total, 
(sum(cast(new_vaccinations as int)) over 
(partition by covid_death.location 
order by covid_death.date)* 100.0 / covid_death.population) as percentage
from Covid_Vaccinations 
join covid_death
on covid_death.location = covid_vaccinations.location
and covid_death.date = covid_vaccinations.date
where covid_death.continent is not null;

-- Simplify the cumulative vaccination analysis 
-- by using a Common Table Expression (CTE) to 
-- calculate the vaccination percentage for each country.

with covidcte as
(select covid_death.location, covid_death.date, covid_vaccinations.new_vaccinations,
covid_death.population,
sum(cast(new_vaccinations as int)) over 
(partition by covid_death.location 
order by covid_death.date) as running_total
from Covid_Vaccinations 
join covid_death
on covid_death.location = covid_vaccinations.location
and covid_death.date = covid_vaccinations.date
where covid_death.continent is not null)

select location, date, new_vaccinations, population, running_total, 
(running_total * 100.0 / population) as VaccinationPercentage
from covidcte;

--Store the cumulative vaccination data in a temporary table
--and calculate the vaccination percentage for each country.

create table pvacpercent
(location NVARCHAR(255),
date date,
new_vaccinations int,
population bigint,
runningtotal bigint);

insert into pvacpercent
select dea.location, dea.date, vac.new_vaccinations,
dea.population,
sum(cast(vac.new_Vaccinations as int)) over 
(partition by dea.location 
order by dea.date) as runningtotal
from Covid_Vaccinations as vac
join covid_death as dea
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null;

select location, date, population, new_vaccinations, runningtotal, 
(runningtotal * 100.0 / population) as vacpercent
from pvacpercent;

--Create a SQL View to store the vaccination analysis 
--for future reporting and dashboard development.

create view covidview as
select covid_death.location, covid_death.date, covid_vaccinations.new_vaccinations,
covid_death.population,
sum(cast(new_vaccinations as int)) over 
(partition by covid_death.location 
order by covid_death.date) as running_total
from Covid_Vaccinations 
join covid_death
on covid_death.location = covid_vaccinations.location
and covid_death.date = covid_vaccinations.date
where covid_death.continent is not null;

select location, date, new_vaccinations, population, running_total, 
(running_total * 100.0 / population) as VaccinationPercentage
from covidview;

--Find the top 10 countries with the highest vaccination percentage.

with vacpercentcte as
(select covid_death.location, covid_death.date,
covid_vaccinations.new_vaccinations,
covid_death.population,
sum(cast(Covid_Vaccinations.new_vaccinations as int)) over 
(partition by covid_death.location 
order by covid_death.date) as running_total
from Covid_Vaccinations 
join covid_death
on covid_death.location = covid_vaccinations.location
and covid_death.date = covid_vaccinations.date
where covid_death.continent is not null)

select top 10 location, population, max(running_total), 
max(running_total * 100.0 / population) as VaccinationPercentage
from vacpercentcte
group by location, population
order by VaccinationPercentage desc;

--Calculate the average vaccination
--percentage for each continent.

with vacpercentcte as
(select covid_death.continent,
covid_death.location,
covid_death.date,
covid_vaccinations.new_vaccinations,
covid_death.population,
sum(cast(Covid_Vaccinations.new_vaccinations as int)) over 
(partition by covid_death.location 
order by covid_death.date) as running_total
from Covid_Vaccinations 
join covid_death
on covid_death.location = covid_vaccinations.location
and covid_death.date = covid_vaccinations.date
where covid_death.continent is not null),

countrypercent as
(select continent, location, population, max(running_total) as running_total, 
max(running_total * 100.0 / population) as VaccinationPercentage
from vacpercentcte
group by continent, location, population)

select continent,
avg(VaccinationPercentage) as avgVaccinationPercentage
from countrypercent
group by continent
order by avgVaccinationPercentage desc;

--Find the first date on which each country crossed 1 million total COVID-19 cases 

select 
location, min(date) as firstdateM
from covid_death
where continent is not null
and total_cases >= 1000000
group by location
order by firstdateM;

--Identify the month with the highest number of new COVID-19 cases globally

SELECT top 1
YEAR(date) as year,
month(date) as month,
sum(new_cases) as totalnewcases
from covid_death
where continent is not null
group by year(date), month(date)
order by totalnewcases desc;

--Find the peak COVID-19 day (highest number of new cases) for each country.

with peakday as
(select 
location, date, new_cases,
row_number() over (partition by location order by new_cases desc)
as rn 
from covid_death
where continent is not null)

select 
location, date, new_cases as peakcases
from peakday
where rn = 1
order by peakcases desc;

--Rank countries by total deaths using a Window Function.

with deathcount as
(select location, max(cast(total_deaths as int)) as totaldeath
from covid_death 
where continent is not null
group by location)

select 
location,
totaldeath,
rank() over(order by totaldeath desc) as deathrank
from deathcount
order by deathrank;

--Within each continent, rank countries by 
--total deaths and return only the top 3 countries

with deathcount as
(select continent, location, max(cast(total_deaths as int)) as totaldeaths
from covid_death 
where continent is not null
group by continent, location),

rankcountries as
(select 
continent,
location,
totaldeaths,
rank() over(partition by continent 
order by totaldeaths desc) as deathrank
from deathcount) 

select
continent,
location,
totaldeaths,
deathrank
from rankcountries
where deathrank <= 3
order by continent, deathrank;

--Calculate the 7-day moving average
--of new COVID-19 cases for each country.

select
location,
date,
new_cases,
avg(cast(new_cases as float)) over
(partition by location
order by date
rows between 6 preceding
and current row) as moving7dayavg
from covid_death
where continent is not null
order by location, date;

--Create a single query that returns:

--* Country
--* Population
--* Total Cases
--* Total Deaths
--* Infection Percentage
--* Death Percentage
--* Running Total Vaccinations
--* Vaccination Percentage

 with ctea as
 (select 
 dea.location,
 dea.population,
 dea.total_cases,
 dea.total_deaths,
 vac.new_vaccinations,
 sum(cast(vac.new_vaccinations as bigint)) over 
 (partition by dea.location order by dea.date) as runningtotalvac
 from covid_death as dea
 join covid_vaccinations as vac
 on dea.location = vac.location
 and dea.date = vac.date
 where dea.continent is not null),

 cteb as
 (select
 location,
 population,
 max(total_cases) as totalcases,
 max(cast(total_deaths as bigint)) as totaldeaths,
 max(runningtotalvac) as runningtotalvacc
 from ctea
 group by location, population)

 select 
 location as country,
 population,
 totalcases,
 totaldeaths,
 totalcases * 100 / population as InfectionPercentage,
 totaldeaths * 100 / totalcases as deathpercentage,
 runningtotalvacc,
 runningtotalvacc * 100 / population as vaccinationpercentage
 from cteb
 order by country;
 


 --creating view for powerbi

CREATE VIEW View_CountryDashboard AS

SELECT
    location AS Country,
    continent,
    population,
    MAX(total_cases) AS TotalCases,
    MAX(CAST(total_deaths AS BIGINT)) AS TotalDeaths,
    MAX(total_cases) * 100.0 / population AS InfectionPercentage,
    MAX(CAST(total_deaths AS BIGINT)) * 100.0 / MAX(total_cases) AS DeathPercentage,
    MAX(RunningTotalVaccinations) AS RunningTotalVaccinations,
    MAX(RunningTotalVaccinations) * 100.0 / population AS VaccinationPercentage
FROM
(
    SELECT
        dea.location,
        dea.continent,
        dea.population,
        dea.total_cases,
        dea.total_deaths,
        dea.date,
        SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER
        (
            PARTITION BY dea.location
            ORDER BY dea.date
        ) AS RunningTotalVaccinations
    FROM covid_death AS dea
    JOIN covid_vaccinations AS vac
        ON dea.location = vac.location
       AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
) AS VaccinationData

GROUP BY
location,
continent,
population;


CREATE VIEW View_DailyTrend AS

SELECT

location,

continent,

date,

new_cases,

new_deaths,

AVG(CAST(new_cases AS FLOAT)) OVER
(
PARTITION BY location
ORDER BY date
ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
) AS MovingAverage7Days

FROM covid_death

WHERE continent IS NOT NULL;


CREATE VIEW View_CountryRanking AS

SELECT

continent,

location,

TotalDeaths,

RANK() OVER
(
PARTITION BY continent
ORDER BY TotalDeaths DESC
) AS DeathRank

FROM
(
SELECT

continent,

location,

MAX(CAST(total_deaths AS BIGINT)) AS TotalDeaths

FROM covid_death

WHERE continent IS NOT NULL

GROUP BY
continent,
location

) AS DeathData;


use covid_project
CREATE VIEW View_VaccinationTrend AS
SELECT
    dea.continent,
    dea.location AS Country,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS bigint)) OVER (
        PARTITION BY dea.location
        ORDER BY dea.date
    ) AS RunningTotalVaccinations
FROM Covid_Death dea
JOIN Covid_Vaccinations vac
    ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;