-- Exploratory Data Analysis

-- 1. Percentage_laid_off is nothing I am gonna work with a lot because I do not know how many total employees they actually have.

SELECT *
FROM layoffs_staging2;

-- 1.1 Looking at what was the maximum layoff from the companies
-- 1.1.1 There were 1200 people laid off, and in one of the companies, the layoff percentage was 100%, meaning the entire company was laid off

SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

-- 1.2 Looking specifically at the companies that laid off their entire workforce and how many people they actually laid off

SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

-- 1.3 Looking at specifacally who were the companies who laid off the entire company and how much funding they had

SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- 1.4 Looking for a companies and how much they laid off people, order by 2 means that it will take the second table and do the descending order "total_laid_off"

SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- 1.5 Looking at what were the minimum and maximum dates when these lay offs happened

SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

-- 1.6 Looking for a industries and how much they laid off people
-- 1.6.1 Consumers and Retail got the biggest hit because of the coronavirus and because of people were not able to come to the shop in some period of time but this is just a assamption

SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

-- 1.7 Looking for a countries and how much they laid off people
-- 1.6.1 There was a lot of people from US who got laid off ca 256k people and the next one was India with 35k people

SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- 1.8 I am looking now for the data per year
-- 1.8.1 Interesting fact is that we did have 125k people laid off in 2023 and we only have 3 months of data for 2023 that is crazy

SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR (`date`)
ORDER BY 1 DESC;

-- 1.9 I am looking now what stage of companies had most lay off

SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

-- 1.10 So over here I am looking the total laid offs per year-month from March 2020 till March 2023

SELECT SUBSTRING(`date`,1,7) AS `month`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `month`
ORDER BY 1 ASC;

-- 1.11 Now we are looking for rolling total so that means we are taking from year-month and to the next year month we are adding the total lay off to see what is the rolling lay off from March 2020 till March 2023
-- 1.11.1 For that I am using CTE to look for rolling total

WITH Rolling_Total AS
(
SELECT SUBSTRING(`date`,1,7) AS `month`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `month`
ORDER BY 1 ASC
)
SELECT `month`, total_off
,SUM(total_off) OVER(ORDER BY `month`) AS rolling_total
FROM Rolling_Total;

-- 1.12 I would like to look company by year and how many they laid off
-- 1.12.1 I am looking for a company by year and how many people they laid off

SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;

-- 1.12.1 I am using the above query to make a CTE to get all of the companies ranking by year

WITH Company_Year (company, years, total_laid_off) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
)
SELECT *,
 DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM Company_Year
WHERE years IS NOT NULL
ORDER BY Ranking ASC;

-- 1.12.2 Breaking it down again:
-- 1.12.2.1 I am looking for a company by year and how many people they laid off, so this was our first CTE
-- 1.12.2.2 Since I did want to look for top 5 companies by year I did another CTE
-- 1.12.2.3 Finally I queryd from the last CTE to filter out the top 5 companies by year

WITH Company_Year (company, years, total_laid_off) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
), Company_Year_Rank AS
(SELECT *,
 DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM Company_Year
WHERE years IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5
;










