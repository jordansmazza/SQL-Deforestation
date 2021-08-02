-- Creating main table
CREATE VIEW forestation AS (
SELECT  f.*,
  		l.total_area_sq_mi * 2.56 AS total_area_sqkm,
  		100 * forest_area_sqkm/(l.total_area_sq_mi * 2.59) pct_forest_area,
  		r.region,
  		r.income_group
FROM forest_area f
JOIN land_area l 
  ON f.country_code = l.country_code
  AND f.year = l.year
JOIN regions r
  ON f.country_code = r.country_code)

-- Finding to total forest area in 2016 and 1990
SELECT region, year, SUM(forest_area_sqkm) total_forest_area
FROM forestation
WHERE region = 'World' AND (year = '1990' OR year = '2016')
GROUP BY 1, 2
ORDER BY 2

-- Subquery to find the difference in forested area between 1990 and 2016
WITH forest_1990 AS (
SELECT SUM(forest_area_sqkm) total_forest_area, year, region
FROM forestation
WHERE region = 'World' AND year = '1990'
GROUP BY 2, 3
ORDER BY 2),

forest_2016 AS (
SELECT SUM(forest_area_sqkm) total_forest_area, year, region
FROM forestation
WHERE region = 'World' AND year = '2016'
GROUP BY 2, 3
ORDER BY 2)

SELECT forest_2016.total_forest_area - forest_1990.total_forest_area AS change_in_sqkm
FROM forest_1990
JOIN forest_2016
ON forest_1990.region = forest_2016.region

-- Finding the country with closest total land area (in sq km)
WITH forest_1990 AS (
SELECT SUM(forest_area_sqkm) total_forest_area, year, region
FROM forestation
WHERE region = 'World' AND year = '1990'
GROUP BY 2, 3
ORDER BY 2),

forest_2016 AS (
SELECT SUM(forest_area_sqkm) total_forest_area, year, region
FROM forestation
WHERE region = 'World' AND year = '2016'
GROUP BY 2, 3
ORDER BY 2)

SELECT country_code, country_name, year, total_area_sqkm
FROM forestation
WHERE year = '2016' AND total_area_sqkm <= (
    SELECT forest_1990.total_forest_area - forest_2016.total_forest_area AS change_in_sqkm
    FROM forest_1990
    JOIN forest_2016
    ON forest_1990.region = forest_2016.region)
ORDER BY 4 DESC

-- Creating regional outlook table
CREATE VIEW regional_outlook AS (
SELECT region, year, 100 * SUM(forest_area_sqkm)/SUM(total_area_sqkm) pct_forest_area
FROM forestation
WHERE year = '1990' OR year = '2016'
GROUP BY 1, 2)

-- Percent forest of entire world in 1990 and 2016
SELECT *
FROM regional_outlook
WHERE region = 'World'

-- Region with hightest forest percentage in 2016
SELECT *
FROM regional_outlook
WHERE year = '2016'
ORDER BY 3 DESC

-- Region with lowest in 2016
SELECT *
FROM regional_outlook
WHERE year = '2016'
ORDER BY 3

-- Region with hightest forest percentage in 1990
SELECT *
FROM regional_outlook
WHERE year = '1990'
ORDER BY 3 DESC

-- Region with lowest forest percentage in 1990
SELECT *
FROM regional_outlook
WHERE year = '1990'
ORDER BY 3

-- Regions that decreased in forest area?
WITH region_1990 AS (
    SELECT *
    FROM regional_outlook
    WHERE year = '1990'
    ORDER BY 3),

region_2016 AS (
    SELECT *
    FROM regional_outlook
    WHERE year = '2016'
    ORDER BY 3)

SELECT *
FROM region_1990
JOIN region_2016
ON region_1990.region = region_2016.region
WHERE region_1990.pct_forest_area > region_2016.pct_forest_area

-- Top 5 largest amount decrease in forest area
WITH t1990 AS (
SELECT SUM(forest_area_sqkm) total_forest_area_1990, year, country_name, region
FROM forestation
WHERE year = '1990' AND forest_area_sqkm IS NOT NULL
GROUP BY 2, 3, 4
ORDER BY 1 DESC),

t2016 AS (
SELECT SUM(forest_area_sqkm) total_forest_area_2016, year, country_name, region
FROM forestation
WHERE year = '2016' AND forest_area_sqkm IS NOT NULL
GROUP BY 2, 3, 4
ORDER BY 1 DESC)

SELECT t1990.country_name, t1990.region, t1990.total_forest_area_1990, t2016.total_forest_area_2016, t2016.total_forest_area_2016 - t1990.total_forest_area_1990 AS change_in_area
FROM t1990
JOIN t2016
ON t1990.country_name = t2016.country_name
WHERE t1990.country_name != 'World'
ORDER BY 5
LIMIT 5;

-- Top 5 largest percent decrease in forest area
WITH t1990 AS (
SELECT country_name, region, forest_area_sqkm AS total_forest_area_1990
FROM forestation
WHERE year = 1990 AND forest_area_sqkm IS NOT NULL
GROUP BY 1,2,3),

t2016 AS (
SELECT country_name, region, forest_area_sqkm AS total_forest_area_2016
FROM forestation
WHERE year = 2016 AND forest_area_sqkm IS NOT NULL
GROUP BY 1,2,3)

SELECT t1990.country_name,
    t1990.region,
    t1990.total_forest_area_1990,
    t2016.total_forest_area_2016,
    100*(t2016.total_forest_area_2016 - t1990.total_forest_area_1990)/t1990.total_forest_area_1990 pct_decrease
FROM t1990
JOIN t2016
ON t2016.country_name = t1990.country_name
WHERE t1990.country_name != 'World'
ORDER BY 5
LIMIT 5;

-- Percentile groupings in 2016
WITH quartiles AS (
  SELECT country_name,
        CASE WHEN pct_forest_area <= 25 THEN '0-25%'
        WHEN pct_forest_area <= 50 THEN '25-50%'
        WHEN pct_forest_area <= 75 THEN '50-75%'
        ELSE '>75%' END AS forestation_quartiles
FROM forestation
WHERE year = 2016 AND pct_forest_area IS NOT NULL
)
SELECT distinct(forestation_quartiles), COUNT(*) OVER (PARTITION BY forestation_quartiles)   
FROM quartiles

-- List all of the countries that were in the 4th quartile (percent forest > 75%) in 2016.
SELECT country_name, region, SUM(forest_area_sqkm)*100/SUM(total_area_sqkm) pct_forest_area
FROM forestation
WHERE pct_forest_area > 75 AND year = 2016
GROUP BY 1, 2
ORDER BY 3 DESC


-- Number of countries with a higher percent forestation than the United States in 2016
SELECT count(*)
FROM forestation 
WHERE YEAR = '2016' AND pct_forest_area > (SELECT pct_forest_area
			FROM forestation
			WHERE year = '2016' AND country_name = 'United States')

