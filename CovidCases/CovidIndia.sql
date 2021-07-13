----------------------------------------------------------------Covid Cases Analysis(India)-----------------------------------------------------------------------

--Table contains 5 columns - Date, State, Cured, Deaths, Confirmed
--Table used for this analysis contains data from beginning of Pandemic till 24th June, 2021.

--Cleaning of data is required as half of the dates were in 'Date' format and others were in 'Varchar' format.
--Handling the Date format data in Excel

--For Dates in Wrong Date format:
--Used =DATE(YEAR(Col),DAY(Col),MONTH(Col)) function to convert into proper format from DD/MM/YY to MM/DD/YY
--Then converted date into Excel number format by =DATEVALUE() function and used TEXT(datevalue,”YYYY”), TEXT(datevalue,”MMMM”), TEXT(datevalue,”DDDD”) 
--to extract year, month and day data from it.

--For Dates in General number format:
--separated each date value in DD/MM/YY, using delimiter ‘/’. Then used Excel concat function line =CONCAT(MM,’/’,DD,’/’,YY) to get the date format and 
--again used DATEVALUE() and TEXT() functions to get the exact date values.
--At last, used the =VLOOKUP() function to copy these year, month and day data(for both different date formats) at the required places after matching 
--with the main Date column in DD/MM/YY format, to form 3 new features with labels ‘YEAR’, ’MONTH’ and ‘DAY’, which will be very useful at later stages
--while analyzing and visualizing this Covid data.

--The SQL Queries are implemented in Microsoft SQL Server.

USE CovidIndia;

SELECT * FROM covidCase;

EXEC sp_help covidCase;
select Date, State, Cured, Deaths, Confirmed from covidCase;

--Data Cleaning
DELETE FROM covidCase where State = 'Cases being reassigned to states';
DELETE FROM covidCase where State = 'Daman & Diu';
DELETE FROM covidCase where State = 'Unassigned';
UPDATE covidCase 
	SET State = 'Dadra and Nagar Haveli and Daman and Diu' where State = 'Dadra and Nagar Haveli';
UPDATE covidCase 
	SET State = 'Bihar' where State = 'Bihar****';
UPDATE covidCase 
	SET State = 'Telangana' where State = 'Telengana';


--Creating New Column for Active Covid Cases
ALTER TABLE covidCase
	ADD Active int;

UPDATE covidCase 
	SET Active = (Confirmed-Deaths-Cured);

--1) Total State-wise Confirmed cases till date
SELECT  State,
		MAX(Confirmed) AS TotalCases 
FROM covidCase 
GROUP BY State 
ORDER BY TotalCases DESC;

----Most Corona Cases have appeared in Maharashtra and least in Andaman&Nicobar till date 


--2) State-Wise Maximum Active Cases in a day
WITH cte AS
(SELECT  Date,
		 State,
		 Month,
		 MAX(Active) OVER (PARTITION BY State) AS MaxActiveCasesInDay,
		 DENSE_RANK() OVER (PARTITION BY State ORDER BY Active desc) AS HighestActive
FROM covidCase)
SELECT State, Date, Month, MaxActiveCasesInDay 
FROM cte 
WHERE HighestActive = 1 
ORDER BY MaxActiveCasesInDay DESC;

----The count of highest Active cases at any time for most states appeared in May 2021, except for Maharashtra & Delhi where peak occurred early in April 2021, 
----while for Sikkim, Manipur, Mizoram the peak occurred in June 2021.


--Creating New Column for State-wise per day Confirmed Cases
ALTER TABLE covidCase
	ADD PerDayConfirmed int;

WITH v_confirmed AS
(
    SELECT  Confirmed - LAG(Confirmed,1) OVER (PARTITION BY State ORDER BY Date) AS perDayCase, 
			Date, 
			State 
	FROM covidCase
)
UPDATE covidCase SET covidCase.PerDayConfirmed = v_confirmed.perDayCase
FROM v_confirmed
WHERE covidCase.Date = v_confirmed.Date 
AND covidCase.State = v_confirmed.State; 


--Creating New Column for State-wise per day Cured Cases
ALTER TABLE covidCase
	ADD PerDayCured int;

WITH v_cured AS
(
    SELECT  Cured - LAG(Cured,1) OVER (PARTITION BY State ORDER BY Date) AS perDayCase, 
			Date, 
			State 
	FROM covidCase
)
UPDATE covidCase SET covidCase.PerDayCured = v_cured.perDayCase
FROM v_cured
WHERE covidCase.Date = v_cured.Date
AND covidCase.State = v_cured.State; 


--Creating New Column for State-wise per day Deaths Cases
ALTER TABLE covidCase
	ADD PerDayDeaths int;

WITH v_deaths AS
(
    SELECT  Deaths - LAG(Deaths,1) OVER (PARTITION BY State ORDER BY Date) AS perDayCase, 
			Date, 
			State
	FROM covidCase
)
UPDATE covidCase SET covidCase.PerDayDeaths = v_deaths.perDayCase
FROM v_deaths
WHERE covidCase.Date = v_deaths.Date
AND covidCase.State = v_deaths.State; 


--3) Maximum Per-Day Confirmed case per State
SELECT  State,
		MaxPerDayConfirmed,
		Date,
		Month
FROM
(SELECT  Date,
		 State,
		 Month,
		 MAX(PerDayConfirmed) OVER (PARTITION BY State) AS MaxPerDayConfirmed,
		 DENSE_RANK() OVER (PARTITION BY State ORDER BY PerDayConfirmed desc) AS HighestConfirmed
FROM covidCase) cte
WHERE HighestConfirmed = 1 
ORDER BY MaxPerDayConfirmed DESC;

--Maharashtra(68631) recorded the highest number of cases in a single day on 19th April,2021 followed by Karnataka(50112) on 6th May,2021 and Kerala(43529) on 13th May,2021
--while Andaman&Nicobar(149) recorded the minimum number of per day Max confirmed cases on 15th Aug, 2020


--4) Maximum Per-Day Deaths case per State
SELECT  State,
		MaxPerDayDeaths,
		Date,
		Month
FROM
(SELECT  Date,
		 State,
		 Month,
		 MAX(PerDayDeaths) OVER (PARTITION BY State) AS MaxPerDayDeaths,
		 DENSE_RANK() OVER (PARTITION BY State ORDER BY PerDayDeaths desc) AS HighestDeaths
FROM covidCase) cte
WHERE HighestDeaths = 1 
ORDER BY MaxPerDayDeaths DESC;

--Bihar(3971) registered most number of Deaths in any single day on 10th June,2021 followed by Maharashtra(2771) on 14th June, 2021 and Karnataka(624) on 24th May, 2021.


--5) Maximum Per-Day Cured case per State
SELECT  State,
		Date,
		Month,
		CAST(MaxPerDayCure AS int) AS MaxPerDayCured
FROM
(SELECT  State,
		 Date,
		 Month,
		 MAX(PerDayCured) OVER (PARTITION BY State) AS MaxPerDayCure,
		 DENSE_RANK() OVER (PARTITION BY State ORDER BY PerDayDeaths desc) AS HighestCured
FROM covidCase) cte
WHERE HighestCured = 1 
ORDER BY MaxPerDayCured DESC;

--Highest number of cured cases per day was recorded in Kerala(99651) on 7th June, 2021 followed by Maharashtra(82266) and Karnataka(61766).


--6) Calculating the State-wise Mortality Rate
WITH cte AS
(SELECT  State,
		Max(Deaths) as Deaths,
		Max(Confirmed) as CovidCases
FROM covidCase
GROUP BY STATE)
SELECT  State, 
		CAST(Round((Deaths/CovidCases)*100, 2) as nvarchar(10)) + '%' AS DeathRate
FROM cte
ORDER BY DeathRate DESC;

--This shows till now, Punjab(2.68%) has the highest Patient Mortality Rate in the country followed by Uttarakhand(2.08%) and Maharashtra(1.99%), while state of
--Kerala(0.44%) and Odisha(0.42%) are among the lowest.

--7) Calculating the State-wise Cured Ratio
WITH cte AS
(SELECT  State,
		Max(Cured) as Cured,
		Max(Confirmed) as CovidCases
FROM covidCase
GROUP BY STATE)
SELECT  State, 
		CAST(Round((Cured/CovidCases)*100, 2) as nvarchar(10)) + '%' AS CuredRate
FROM cte
ORDER BY CuredRate DESC;

--This shows till now, Dadra and Nagar Haveli and Daman and Diu(99.39%) has the highest Patient Cured ratio in the country followed by Rajasthan(98.84%) and Madhya Pradesh(98.69%),
--while Mizoram(75.69%) has the lowest.


--8) Calculating day-wise highest PerDayConfirmed Cases
SELECT  DAY,
		SUM(PerDayConfirmed) AS TotalCases
FROM covidCase
GROUP BY DAY
ORDER BY TotalCases DESC;

--Maximum Total number of cases all over India arose on Thursday


--9) Finding the 'Time' when Covid Waves attacked the capital city 'Delhi'
WITH monthlySpike AS
(SELECT  State,
		 Date,
		 Year,
		 Month,
		 PerDayConfirmed,
		 AVG(PerDayConfirmed) OVER (PARTITION BY Month) as Spike,
		 DENSE_RANK() OVER (PARTITION BY Month ORDER BY PerDayConfirmed DESC) AS rnk
FROM covidCase
WHERE State = 'Delhi')
SELECT  State,
		Year,
		Month,
		ROUND(Spike,2) as AvgSpikeInCases
FROM monthlySpike
WHERE rnk = 1 AND PerDayConfirmed >3000
ORDER BY Date;

--From this we can conclude, in Delhi, the 1st Wave came around in June,2020, 2nd Wave in November and 3rd Wave in April which was the most severe of all.


--10) Finding the 'Time' when Mortality Rate was highest in the capital 'Delhi'
WITH monthlySpike AS
(SELECT  State,
		 Date,
		 Year,
		 Month,
		 PerDayDeaths,
		 SUM(PerDayDeaths) OVER (PARTITION BY Month) as Spike,
		 DENSE_RANK() OVER (PARTITION BY Month ORDER BY PerDayDeaths DESC) AS rnk
FROM covidCase
WHERE State = 'Delhi')
SELECT  State,
		Year,
		Month,
		ROUND(Spike,2) as TotalSpikeInDeaths
FROM monthlySpike
WHERE rnk = 1
ORDER BY Date;

--As different Waves attacked Delhi, so did increase the Total Death Count month-wise with 1st(June), 2nd(November) and 3rd(April) waves respectively.


--#One can also try finding the Spike Rate compared to previous day cases(as done below), but this can give a slight wrong impression of severity of cases
--since with prev case 10 and present case 20, spike is 100% but with prev case 1000 and present case 500, spike is 50% although the total increased cases is much bigger this time. 
WITH perDayRise AS
(SELECT  State,
		 Date,
		 Month,
		 PerDayConfirmed,
		 LAG(PerDayConfirmed,1) OVER (PARTITION BY State ORDER BY Date) AS prevCase,
		 PerDayConfirmed-LAG(PerDayConfirmed,1) OVER (PARTITION BY State ORDER BY Date) AS perDayCase	
FROM covidCase
WHERE State = 'Delhi'),
HnadleNull as
(SELECT State,
		Date,
		prevCase,
		PerDayConfirmed,
		Month,
		perDayCase,
		(CASE 
			WHEN prevCase = 0 OR prevCase IS NULL THEN 1
		ELSE
			prevCase
		END) AS handle
FROM perDayRise
WHERE prevCase > 200 AND perDayCase > 200)
SELECT  State,
		Date,
		PerDayConfirmed,
		prevCase,
		perDayCase,
		Month,
		CEILING((perDayCase/handle) *100) AS PercentSpike
FROM HnadleNull
ORDER BY PercentSpike DESC;


--11) Last 5 day Active cases from each date for state 'DELHI'
SELECT  Date,
		Active,
		sum(Active) over (order by Date Rows 4 preceding) as Last5dayActiveCases
FROM covidCase 
where State='Delhi';