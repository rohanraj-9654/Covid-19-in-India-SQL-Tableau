-----------------CovidVaccinations-Analysis-----------------------

-- Here, we are going to analyse vaccinations data, first in terms of total vaccinations with respect to India and individual states, and finally
-- with respect to per day Vaccination data of each state.
-- Also, the insights drawn from analysis are given just below each SQL Query.

USE CovidIndia;

SELECT * FROM vaccineIndia;
SELECT * FROM vaccineState;

--DATA ANALYSIS--

--1) Top Vaccinated States
SELECT  State,
		MAX(TotalVaccinated) AS TotalVaccinations
FROM vaccineState
WHERE Region = 'UT'
GROUP BY State
ORDER BY TotalVaccinations DESC;

--Uttar Pradesh(23918186) administered most number of vaccinations in India, followed by Maharashtra(23663198) and Rajasthan(18905925) among Indian States
--and Chandigarh(397301) highest among UTs.


--2) Proportion of CoviShield, Covaxin, Sputnik Administered State-wise
SELECT 
		State,
		CAST(Round((MAX(CoviShieldDose)/MAX(TotalDoses))*100, 2) as nvarchar(10)) + '%' AS PercentCovishield,
		CAST(Round((MAX(CovaxinDose)/MAX(TotalDoses))*100, 2) as nvarchar(10)) + '%' AS PercentCovaxin,
		CAST(Round((MAX(SputnikDose)/MAX(TotalDoses))*100, 2) as nvarchar(10)) + '%' AS PercentSputnik
FROM vaccineState
GROUP BY STATE;

--All the States and UT'S have mostly been vaccinated with Covishield doses, with Delhi using the highest proportion of Covaxin(30%) among all.


--3) Ratio of Male and Female vaccination in the country in %
SELECT 
		'INDIA' AS Place,
		CAST(Round((MAX(MaleVaccinated)/MAX(TotalVaccinated))*100, 2) as nvarchar(10)) + '%' AS PercentMaleVaccinated,
		CAST(Round((MAX(FemaleVaccinated)/MAX(TotalVaccinated))*100, 2) as nvarchar(10)) + '%' AS PercentFemaleVaccinated
FROM vaccineIndia
GROUP BY STATE
UNION ALL
SELECT 
		State,
		CAST(Round((MAX(MaleVaccinated)/MAX(TotalVaccinated))*100, 2) as nvarchar(10)) + '%' AS PercentMaleVaccinated,
		CAST(Round((MAX(FemaleVaccinated)/MAX(TotalVaccinated))*100, 2) as nvarchar(10)) + '%' AS PercentFemaleVaccinated
FROM vaccineState
GROUP BY STATE;

--In India, among those vaccinated, 53.86% are Males and 46.12% are Females. Almost same ratio has been maintained by all states, except in Andhra Pradesh
--where 54.03% vaccinated are females and 45.95% Males.


--4) Vaccination proportion among different Age groups
SELECT 
		'INDIA' AS Place,
		CAST(Round((MAX([Age(18-45)])/MAX(TotalVaccinated))*100, 2) as nvarchar(10)) + '%' AS YoungVaccinated,
		CAST(Round((MAX([Age(45-60)])/MAX(TotalVaccinated))*100, 2) as nvarchar(10)) + '%' AS SeniorVaccinated,
		CAST(Round((MAX([Age(60+)])/MAX(TotalVaccinated))*100, 2) as nvarchar(10)) + '%' AS OldAgeVaccinated
FROM vaccineIndia
GROUP BY STATE
UNION ALL
SELECT 
		State,
		CAST(Round((MAX([Age(18-45)])/MAX(TotalVaccinated))*100, 2) as nvarchar(10)) + '%' AS YoungVaccinated,
		CAST(Round((MAX([Age(45-60)])/MAX(TotalVaccinated))*100, 2) as nvarchar(10)) + '%' AS SeniorVaccinated,
		CAST(Round((MAX([Age(60+)])/MAX(TotalVaccinated))*100, 2) as nvarchar(10)) + '%' AS OldAgeVaccinated
FROM vaccineState
GROUP BY STATE;

--In India, majority people vaccinated are in agr group 45-60 years(36.72%)


--5) Covid Doses wasted in country
SELECT 
		'INDIA' AS Place,
		CAST(Round((1-(MAX(TotalVaccinated)/MAX(TotalDoses)))*100, 2) as nvarchar(10)) + '%' AS DosesWasted
FROM vaccineIndia
GROUP BY STATE
UNION ALL
SELECT 
		State,
		CAST(Round((1-(MAX(TotalVaccinated)/MAX(TotalDoses)))*100, 2) as nvarchar(10)) + '%' AS DosesWasted
FROM vaccineState
GROUP BY STATE;

--Till 23rd June 2021, 17.5% of the doses have been wasted in India, and among states, maximum dose wastage been made in Delhi(23.91%).


--6) Percent of First Dose recpients who are also done with their 2nd Dose State-Wise
SELECT 
		'INDIA' AS Place,
		CAST(Round((MAX(SecondDose)/MAX(FirstDose))*100, 2) as nvarchar(10)) + '%' AS CompleteDose
FROM vaccineIndia
GROUP BY STATE
UNION ALL
SELECT 
		State,
		CAST(Round((MAX(SecondDose)/MAX(FirstDose))*100, 2) as nvarchar(10)) + '%' AS CompleteDose
FROM vaccineState
GROUP BY STATE;

--In India, 21.21% of people vaccinated have completed their both Covid doses, and Delhi(31.43%) has the highest percent of complete dosed popluation out
--of those vaccinated.


--7) Which MONTH maximum Doses were wasted State wise
WITH dose_wastage AS
	(SELECT 
			State,
			Month,
			Waste,
			DENSE_RANK() OVER (PARTITION BY State ORDER BY Waste DESC) AS RankWaste
	FROM
		(SELECT  
			State,
			Month,
			(1-(AVG(PerDayTotalVaccinated)/AVG(PerDayDoses)))*100 AS Waste
		FROM vaccineState
		GROUP BY State, Month) cte)
SELECT 
	State, 
	Month, 
	ROUND(Waste,2) AS PercentWaste
FROM dose_wastage 
WHERE RankWaste = 1
ORDER BY PercentWaste DESC;

--Acc to given Data, maximum Dose wastage occurred in Chattisgarh(57.94%) in the month of May followed by Telangana(49.33%)


--8) Which MONTH Maximum Doses were administered State-wise
WITH max_Dose AS
(SELECT 
	State,
	Month,
	Round(AVG(PerDayTotalVaccinated),0) AS AvgVaccinated
FROM vaccineState
GROUP BY State,Month),
rank_Dose AS
(SELECT 
	State,
	Month,
	AvgVaccinated,
	DENSE_RANK() OVER (PARTITION BY State ORDER BY AvgVaccinated DESC) AS rankVaccinated
FROM max_Dose)
SELECT State, Month, AvgVaccinated
FROM rank_Dose
WHERE rankVaccinated = 1
ORDER BY AvgVaccinated DESC;

--UttarPradesh(394070/day on avg) administered highest number of vaccinations to its population in month of June 2021, followed by MadhyaPradesh(278155) and Karnataka(269421) in June.