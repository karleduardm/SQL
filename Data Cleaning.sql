-- Data Cleaning


SELECT * 
FROM layoffs;

-- What am I going to do?
-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Null Values
-- 4. Remove any Columns

-- 0. Creating a new table for the working sheet to save the raw data

CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT * 
FROM layoffs_staging;

INSERT layoffs_staging
SELECT * 
FROM layoffs;

-- 1. Remove Duplicates

-- 1.1 Looking for duplicates based on different rows.

SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 'date') AS row_num
FROM layoffs_staging;

-- 1.2 Using CTE to look for duplicates

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- 1.3 Testing to see one of the duplicates

SELECT * 
FROM layoffs_staging
WHERE company = 'Casper'
;

-- 1.4 In order to delete duplicates, I need to create a new table

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 1.5 Inserting the data into the new table

SELECT * 
FROM layoffs_staging2;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging; 

-- 1.6 Deleting all the duplicates from the table

DELETE
FROM layoffs_staging2
WHERE row_num > 1;


-- 2. Standardize the Data

-- 2.1 TRIM - removes the white spaces

SELECT company, TRIM(company) 
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

SELECT DISTINCT country
FROM layoffs_staging2;

-- 2.1 I found out that there was an industry called "Cypto" that is spelled differently, so I would like them to be the same

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- 2.2 I fixed it, so basically, we are updating the table to "Crypto" where the industry is "Cypto..."

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- 2.3 I found that there was a country with a period at the end. So, the TRIM with TRAILING will take it from the back; for example, "United States." was changed to "United States"

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- 2.4 The date was in the wrong format, so I fixed it. STR_TO_DATE can do this; I just have to specify the order, which in this example is month, day, and year

SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

SELECT `date`
FROM layoffs_staging2;

-- 2.4 After putting the date in the right format, I changed the date column from text to date

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


-- 3. Null values, layoffs, or blank values

-- 3.1 I am looking for null values

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- 3.2 I found out that there are a lot of nulls in the industry column, but for example, Airbnb had an industry listed, so I can use the same industry

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';

-- 3.3 I am using a join to add the industry where the industry is null. So, I am joining the same tables, just giving them different names, and I am joining the industries where it is null with the industry table where it is not null.

SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- 3.4 I am setting industry to null where it is blank

UPDATE  layoffs_staging2 t1
SET industry = NULL
WHERE industry = '';

-- 3.5 I am updating the table where the industry is null from the table where the industry is not null. For example, Airbnb had three different rows, one with the industry listed and the other two without, so I just added the industry from the one that had it listed

UPDATE  layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- 3.6 Looking at the "total laid off" and "percentage laid off" null rows to see what we can do

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- 3.7 I am deleting the null rows where both "total_laid_off" and "percentage_laid_off" are null because we cannot trust that data

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- 4. Finally, we are going to delete the "row_num" because we do not need it

SELECT *
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;
