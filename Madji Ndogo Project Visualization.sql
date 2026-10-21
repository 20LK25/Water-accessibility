-- Start by joining location to visits. --
SELECT
	Loc.location_id,
    Loc.province_name,
    Loc.town_name,
    V.visit_count
FROM
	location AS Loc
JOIN
	visits AS V
    ON V.location_id = Loc.location_id;
    
    
-- Now,we can join the water_source table on the key shared between water_source and visits.And filter with WHERE cluase as visit_count = 1--  
SELECT
	Loc.location_id,
    Loc.province_name,
    Loc.town_name,
    V.visit_count,
    WS.type_of_water_source,
    WS.number_of_people_served
FROM
	location AS Loc
JOIN
	visits AS V
    ON V.location_id = Loc.location_id
JOIN
	water_source AS WS
    ON WS.source_id = V.source_id
WHERE 
	V.visit_count = 1;
    

-- Now remove the location_id and visit_count columns. --
SELECT
    Loc.province_name,
    Loc.town_name,
    WS.type_of_water_source,
    WS.number_of_people_served
FROM
	location AS Loc
JOIN
	visits AS V
    ON V.location_id = Loc.location_id
JOIN
	water_source AS WS
    ON WS.source_id = V.source_id
WHERE 
	V.visit_count = 1;
    
    

-- Add the location_type column from location and time_in_queue from visits to our results set.--    
SELECT
    Loc.province_name,
    Loc.town_name,
    Loc.location_type,
    V.time_in_queue,
    WS.type_of_water_source,
    WS.number_of_people_served
FROM
	location AS Loc
JOIN
	visits AS V
    ON V.location_id = Loc.location_id
JOIN
	water_source AS WS
    ON WS.source_id = V.source_id
WHERE 
	V.visit_count = 1;
    

/* Last one! Now we need to grab the results from the well_pollution table. The well_pollution table contained only data for well. If we just use JOIN, we will do an inner join, so that only records
that are in well_pollution AND visits will be joined. We have to use a LEFT JOIN to join theresults from the well_pollution table for well
sources, and will be NULL for all of the rest. */
SELECT
    Loc.province_name,
    Loc.town_name,
    Loc.location_type,
    V.time_in_queue,
    WS.type_of_water_source,
    WS.number_of_people_served,
    WP.results
FROM
	location AS Loc
JOIN
	visits AS V
    ON V.location_id = Loc.location_id
JOIN
	water_source AS WS
    ON WS.source_id = V.source_id
LEFT JOIN
	well_pollution AS WP
    ON WP.source_id = V.source_id
WHERE 
	V.visit_count = 1;
    
    
    
CREATE VIEW Combined_Analysis_Table AS 
-- This view assembles data from different tables into one to simplify analysis --
SELECT
    Loc.province_name,
    Loc.town_name,
    Loc.location_type,
    V.time_in_queue,
    WS.type_of_water_source,
    WS.number_of_people_served,
    WP.results
FROM
	location AS Loc
JOIN
	visits AS V
    ON V.location_id = Loc.location_id
JOIN
	water_source AS WS
    ON WS.source_id = V.source_id
LEFT JOIN
	well_pollution AS WP
    ON WP.source_id = V.source_id
WHERE 
	V.visit_count = 1;
    
    
WITH province_totals AS ( 
SELECT
province_name,
SUM(number_of_people_served) AS total_ppl_serv
FROM
combined_analysis_table
GROUP BY
province_name
)
SELECT
ct.province_name,
ROUND((SUM(CASE WHEN type_of_water_source = 'river'
THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap'
THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home'
THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN type_of_water_source  = 'tap_in_home_broken'
THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN type_of_water_source = 'well'
THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN
province_totals pt ON ct.province_name = pt.province_name
GROUP BY
ct.province_name
ORDER BY
ct.province_name;



 /* This CTE calculates the population of each town
Since there are two Harare towns, we have to group by province_name and town_name*/

WITH town_totals AS (
SELECT 
	province_name, 
    town_name, 
    SUM(number_of_people_served) AS total_ppl_serv
FROM combined_analysis_table
GROUP BY province_name, town_name
)
SELECT
ct.province_name,
ct.town_name,
ROUND((SUM(CASE WHEN type_of_water_source = 'river'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN type_of_water_source = 'well'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
 -- Since the town names are not unique, we have to join on a composite key--
JOIN 
	town_totals tt ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
 -- We group by province first, then by town.--
GROUP BY
	ct.province_name,
	ct.town_name
ORDER BY
ct.town_name;

CREATE TEMPORARY TABLE town_aggregated_water_access
WITH town_totals AS (
	SELECT 
	province_name, 
    town_name, 
    SUM(number_of_people_served) AS total_ppl_serv
FROM combined_analysis_table
GROUP BY province_name, town_name
)
SELECT
ct.province_name,
ct.town_name,
ROUND((SUM(CASE WHEN type_of_water_source = 'river'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN type_of_water_source = 'well'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
 -- Since the town names are not unique, we have to join on a composite key--
JOIN 
	town_totals tt ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
 -- We group by province first, then by town.--
 
GROUP BY
	ct.province_name,
	ct.town_name
ORDER BY
ct.town_name;

SELECT 
	*
FROM
	town_aggregated_water_access
ORDER BY province_name DESC;

SELECT
province_name,
town_name,
river,
ROUND(tap_in_home_broken / (tap_in_home_broken + tap_in_home) *

100,0) AS Pct_broken_taps
FROM
town_aggregated_water_access
JOIN md_water_services.well_pollution
WHERE province_name = 'Amanzi';



-- CREATING PROJECT PROGRESS TO HELP MANAGE AND MONITOR THE PROJECT.--
-- THIS IS ALSO GIVEN TO ENGINEERS TO HELP THEM UPDATE THE TEAM ON THE PROJECT--

CREATE TABLE Project_progress (
Project_id SERIAL PRIMARY KEY,
source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,
Address VARCHAR(50),
Town VARCHAR(30),
Province VARCHAR(30),
Source_type VARCHAR(50),
Improvement VARCHAR(50),
Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),
Date_of_completion DATE,
Comments TEXT
);


SELECT
water_source.source_id,
location.address,
location.town_name,
location.province_name,
water_source.type_of_water_source,
well_pollution.results
FROM
water_source
LEFT JOIN
well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
visits ON water_source.source_id = visits.source_id
INNER JOIN
location ON location.location_id = visits.location_id
WHERE
visits.visit_count = 1  -- This must always be true --
AND ( well_pollution.results != 'Clean'
OR water_source.type_of_water_source IN ('tap_in_home_broken','river')
OR ( water_source.type_of_water_source = 'shared_tap' AND time_in_queue >= 30)
);

-- Update project progress Step.1 --
INSERT INTO project_progress(source_id, address, town, province, source_type)
SELECT
water_source.source_id,
location.address,
location.town_name,
location.province_name,
water_source.type_of_water_source
FROM
water_source
LEFT JOIN
well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
visits ON water_source.source_id = visits.source_id
INNER JOIN
location ON location.location_id = visits.location_id
WHERE
visits.visit_count = 1  -- This must always be true --
AND ( well_pollution.results != 'Clean'
OR water_source.type_of_water_source IN ('tap_in_home_broken','river')
OR ( water_source.type_of_water_source = 'shared_tap' AND time_in_queue >= 30)
);


-- Update the project progress Step.2 --
UPDATE md_water_services.project_progress pp
JOIN well_pollution wp
    ON pp.source_id = wp.source_id
SET pp.Improvement = CASE
    WHEN wp.results = 'Contaminated: Biological' THEN 'Install UV filter'
    WHEN wp.results = 'Contaminated: Chemical' THEN 'Install RO filter'
    ELSE NULL  -- For any other cases, set the Improvement column to NULL
END;

-- UPDATE THE PROJECT PROGRESS Step.3 --
UPDATE md_water_services.project_progress pp
SET pp.Improvement = 'Drill well'
    WHERE Source_type = 'river';
    

-- Update the project progress Step.4 --
UPDATE md_water_services.project_progress pp
JOIN md_water_services.visits V
	ON V.source_id = PP.source_id
SET pp.Improvement = CASE
WHEN V.time_in_queue >= 30 AND pp.source_type = 'shared_tap' THEN CONCAT("Install ", FLOOR(V.time_in_queue >= 30/30), " taps nearby")
ELSE NULL
END
WHERE pp.Improvement IS NULL;



UPDATE md_water_services.project_progress pp
SET pp.Improvement = CASE
    WHEN pp.source_type = 'tap_in_home_broken' THEN 'Diagnose local infrastructure'  -- If tap is broken
    ELSE NULL
END
WHERE pp.Improvement IS NULL;



