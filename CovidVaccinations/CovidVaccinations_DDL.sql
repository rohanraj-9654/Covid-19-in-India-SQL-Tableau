-----------------CovidVaccinations-DDL-----------------------

-- Here, we will drop some existing columns which are not very important.
-- Also, since the table consists of rolling sums for all vaccination data, we are going to create new columns that gives Per-Day Vaccine information.


USE CovidIndia;

SELECT * FROM vaccineIndia;
SELECT * FROM vaccineState;


--Dropping columns 'TotalSessions', 'TotalSites' and 'AEFI' as we are going to focus purely on vaccinations
ALTER TABLE vaccineState
	DROP COLUMN TotalSessions, TotalSites, AEFI;

--Create a Date column(this will act as our Primary Key for this table) based on Year, Month and Day
ALTER TABLE vaccineState
	ADD Dates Date;

UPDATE vaccineState 
	SET Dates = CONVERT(DATE,CAST(Year AS VARCHAR(4))+'-'+
							 CAST(Month AS VARCHAR(2))+'-'+
							 CAST(Day AS VARCHAR(2)));


--#Creating new columns for per-day Male/Female/TransgenderVaccinated, Covishield/Covaxin/Sputnik Doses, TotalVaccination, TotalDoses
ALTER TABLE vaccineState
	ADD PerDayTotalVaccinated int;

WITH v_vaccine AS
(
    SELECT  TotalVaccinated - LAG(TotalVaccinated,1) OVER (PARTITION BY State ORDER BY Dates) AS perDayVaccine, 
			Dates, 
			State 
	FROM vaccineState
)
UPDATE vaccineState SET vaccineState.PerDayTotalVaccinated = v_vaccine.perDayVaccine
FROM v_vaccine
WHERE vaccineState.Dates = v_vaccine.Dates 
AND vaccineState.State = v_vaccine.State;


ALTER TABLE vaccineState
	ADD PerDayMaleVaccinated int;

WITH v_vaccine AS
(
    SELECT	MaleVaccinated - LAG(MaleVaccinated,1) OVER (PARTITION BY State ORDER BY Dates) AS perDayMaleVaccine, 
			Dates, 
			State 
	FROM vaccineState
)
UPDATE vaccineState SET vaccineState.PerDayMaleVaccinated = v_vaccine.perDayMaleVaccine
FROM v_vaccine
WHERE vaccineState.Dates = v_vaccine.Dates 
AND vaccineState.State = v_vaccine.State;


ALTER TABLE vaccineState
	ADD PerDayFemaleVaccinated int;

WITH v_vaccine AS
(
    SELECT  FemaleVaccinated - LAG(FemaleVaccinated,1) OVER (PARTITION BY State ORDER BY Dates) AS perDayFemaleVaccine, 
			Dates, 
			State 
	FROM vaccineState
)
UPDATE vaccineState SET vaccineState.PerDayFemaleVaccinated = v_vaccine.perDayFemaleVaccine
FROM v_vaccine
WHERE vaccineState.Dates = v_vaccine.Dates 
AND vaccineState.State = v_vaccine.State;


ALTER TABLE vaccineState
	ADD PerDayTransVaccinated int;

WITH v_vaccine AS
(
    SELECT  TransgenderVaccinated - LAG(TransgenderVaccinated,1) OVER (PARTITION BY State ORDER BY Dates) AS perDayTransVaccine, 
			Dates, 
			State 
	FROM vaccineState
)
UPDATE vaccineState SET vaccineState.PerDayTransVaccinated = v_vaccine.perDayTransVaccine
FROM v_vaccine
WHERE vaccineState.Dates = v_vaccine.Dates 
AND vaccineState.State = v_vaccine.State;


ALTER TABLE vaccineState
	ADD PerDayDoses int;

WITH v_dose AS
(
    SELECT  TotalDoses - LAG(TotalDoses,1) OVER (PARTITION BY State ORDER BY Dates) AS totalDoses, 
			Dates, 
			State 
	FROM vaccineState
)
UPDATE vaccineState SET vaccineState.PerDayDoses = v_dose.totalDoses
FROM v_dose
WHERE vaccineState.Dates = v_dose.Dates 
AND vaccineState.State = v_dose.State;


ALTER TABLE vaccineState
	ADD PerDayCovaxinDoses int;

WITH v_dose AS
(
    SELECT  CovaxinDose - LAG(CovaxinDose,1) OVER (PARTITION BY State ORDER BY Dates) AS totalDoses, 
			Dates, 
			State 
	FROM vaccineState
)
UPDATE vaccineState SET vaccineState.PerDayCovaxinDoses = v_dose.totalDoses
FROM v_dose
WHERE vaccineState.Dates = v_dose.Dates 
AND vaccineState.State = v_dose.State;


ALTER TABLE vaccineState
	ADD PerDayCovishieldDoses int;

WITH v_dose AS
(
    SELECT  CoviShieldDose - LAG(CoviShieldDose,1) OVER (PARTITION BY State ORDER BY Dates) AS totalDoses, 
			Dates, 
			State 
	FROM vaccineState
)
UPDATE vaccineState SET vaccineState.PerDayCovishieldDoses = v_dose.totalDoses
FROM v_dose
WHERE vaccineState.Dates = v_dose.Dates 
AND vaccineState.State = v_dose.State;


ALTER TABLE vaccineState
	ADD PerDaySputnikDoses int;

WITH v_dose AS
(
    SELECT  SputnikDose - LAG(SputnikDose,1) OVER (PARTITION BY State ORDER BY Dates) AS totalDoses, 
			Dates, 
			State 
	FROM vaccineState
)
UPDATE vaccineState SET vaccineState.PerDaySputnikDoses = v_dose.totalDoses
FROM v_dose
WHERE vaccineState.Dates = v_dose.Dates 
AND vaccineState.State = v_dose.State;


--#Separate States and UnionTerritory(UT)
ALTER TABLE vaccineState
	ADD Region nvarchar(255);

UPDATE vaccineState 
	SET Region = CASE WHEN State in ('Lakshadweep','Andaman and Nicobar Islands','Ladakh','Dadra and Nagar Haveli and Daman and Diu','Puducherry','Chandigarh') THEN 'UT'
					ELSE 'State'
					END;