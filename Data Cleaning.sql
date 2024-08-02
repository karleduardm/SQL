-- DATA Cleaning


SELECT * 
FROM layoffs;

-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Null VAlues layoffsor Blank Values
-- 4. Remove any Columns

CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT * 
FROM layoffs_staging;

INSERT layoffs_staging
SELECT * 
FROM layoffs;

-- 1. Remove Duplicates

-- 1.1 Looking for duplicates based on the different rows 

SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 'date') AS row_num
FROM layoffs_staging;

-- 1.2 Using CTE to look for the duplicates


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

-- 1.4 In order to delete duplicates I need to create a new table

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

-- 1.5 Inserting the data to the new table

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

-- 2.1 TRIM - takes out the white spaces
SELECT company, TRIM(company) 
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

SELECT DISTINCT country
FROM layoffs_staging2;

-- 2.1 We found out that there was a Industry called Cypto that is with different name so we would like them to be same

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- 2.2 We fixed so basically we are updating table to Crypto where industry is Crypto...

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- 2.3 We found that there was country with . at the end. So the TRIM with TRAILING will take from the back, so there was "United States." so it took out the .

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- 2.4 The date was with wrong format so we fixed it and that STR TO DATE can do this, we just have to say in what order is it - in our example month, day and year.

SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

SELECT `date`
FROM layoffs_staging2;

-- 2.4 After putting date to right format we changed the date colum from text to date

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


-- 3. Null VAlues layoffsor Blank Values

-- 3.1 We are looking for null values

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- 3.2 We found out that there is a lot of nulls in industry but there is for example Airbnb who had industry on so we can use the same industry

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

-- 3.3 So we are using join to add the industry where the industry is null. So we are joining same tables just adding different names for them and we are joining the industrys where it is null and industry table 2 where it is not null

SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- 3.4 We are setting industry null where it is blank

UPDATE  layoffs_staging2 t1
SET industry = NULL
WHERE industry = '';

-- 3.5 We are updating table where industry is null from the table where industry is not null. So there was Airbnb who had three different rows and one had industry on and other two did not so we just added industry from the on that had industry on.

UPDATE  layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- 3.6 Looking at the total laid off and percentage laid off null rows to see what we can do

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- 3.7 We are deleting the nulls rows where there is total_laid off and percentage laid off is both null because we can not trust that they are correct

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- 3.8 Finally we are going to delete the row_num row because we do not need it

SELECT *
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;
