SELECT*
FROM PortfolioProject.dbo.NashvilleHousing

                  --DATA CLEANING WITH SQL--


-- Standardize Date format
-- The field "SaleDate" is in a datetime format
-- We want to get rid of the time portion and be left with just the date

SELECT SaleDate, CONVERT(Date, SaleDate)
FROM PortfolioProject.dbo.NashvilleHousing -- Preview of what we are looking for

UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

--For some reasons, the server would not allow the update to take effect
-- So, I had to create a new column that will store the new date format

ALTER TABLE NashvilleHousing
ADD SaleDateNewFormat date

UPDATE NashvilleHousing
SET SaleDateNewFormat = CONVERT(date, SaleDate)

SELECT SaleDateNewFormat, CONVERT(Date, SaleDate)
FROM PortfolioProject.dbo.NashvilleHousing


--Populate the "PropertyAddress" field
--There are some values in the fiedl that are blank

SELECT PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing
WHERE PropertyAddress is null

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
WHERE PropertyAddress is null-- Not very sure why there is null values
ORDER BY ParcelID-- Ordering by ParcelID, reveals some kind of patterns in the data
                 -- The null in the "PropertyAddress" field is tied to a parcelID that appears more than once
				 --and is tied to the same property address.

-- Now that we know that the parcelID referenced more than once belongs to the same property address
-- We are going to create that condition to populate the null values existing in the "PropertyAddress" field


--The purpoose of this block of code down below will allow us to see what are these Properties addresses
-- that are tied to a double ParcelID so we can set our condition

SELECT x.ParcelID, x.PropertyAddress, y.ParcelID, y.PropertyAddress, ISNULL(x.PropertyAddress, y.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing x
JOIN PortfolioProject.dbo.NashvilleHousing y
    ON x.ParcelID = y.ParcelID
	AND x.[UniqueID ] <> y.[UniqueID ]
WHERE x.PropertyAddress is null

UPDATE x
SET PropertyAddress = ISNULL(x.PropertyAddress, y.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing x
JOIN PortfolioProject.dbo.NashvilleHousing y
    ON x.ParcelID = y.ParcelID
	AND x.[UniqueID ] <> y.[UniqueID ]
WHERE x.PropertyAddress is null

--SELECT ParcelID, PropertyAddress
--FROM PortfolioProject.dbo.NashvilleHousing
--WHERE PropertyAddress is null


--Separate address, city, and state from the "PropertyAddress", and "OwnerAddress" fields

SELECT PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing

                                         -- The SUBSTRING function
--In SQL Server, the SUBSTRING function is used to extract a substring from a string, starting at a specified position and for a certain length. 
--It's a very useful function for manipulating and transforming text data within your SQL queries.
-- Basic syntax: SUBSTRING(expression, start, length)

--expression: The string expression from which to extract the substring. 
--This can be a literal string, a column name, or a more complex expression.
--start: The starting position in the expression from where the substring will begin. The first character in the string is considered position 1.
--length: The number of characters to extract from the expression, starting at the start position.

--Extracting a Substring from a Literal String
--Suppose you want to extract the word 'SQL' from the string 'Microsoft SQL Server'.

SELECT SUBSTRING('Microsoft SQL Server', 11, 3) AS ExtractedString

--Extracting a Substring from a Column
--Consider a table NashvilleHousing with a column PropertAddress. If you want to extract the address part of the PropertyAddress (the part after the ',')

SELECT --PropertyAddress, 
       SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
	   SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS Address
FROM PortfolioProject.dbo.NashvilleHousing --This query uses CHARINDEX to find the position of the ',' PropertyAddress and then extracts the substring from the beginning of the string up to (but not including) the ','.


ALTER TABLE NashvilleHousing
ADD PropertySplitAddress nvarchar(225)

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity nvarchar(225)

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))




                                        --THE PARSENAME FUNCTION
--The PARSENAME function in SQL Server is used to split a fully qualified object name into its individual components, such as the server name, database name, schema name, and object name. 
--This is particularly useful when working with dot-separated identifiers.
--Basic syntax: PARSENAME('object_name', part)
--object_name is the fully qualified name you want to parse. It can be a four-part name maximum (server.database.schema.object).
--part is the part of the object_name you want to extract. It accepts a value from 1 to 4, where:
--1 returns the rightmost part (e.g., object name).
--2 returns the second part from the right (e.g., schema name).
--3 returns the third part from the right (e.g., database name).
--4 returns the leftmost part (e.g., server name).
SELECT
  PARSENAME('ServerName.DatabaseName.SchemaName.TableName', 4) AS ServerName,
  PARSENAME('ServerName.DatabaseName.SchemaName.TableName', 3) AS DatabaseName,
  PARSENAME('ServerName.DatabaseName.SchemaName.TableName', 2) AS SchemaName,
  PARSENAME('ServerName.DatabaseName.SchemaName.TableName', 1) AS TableName

--Separate the OwnerAddress field using the PARSENAME function

SELECT OwnerAddress
FROM PortfolioProject.dbo.NashvilleHousing

SELECT
  PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),--Address
  PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),--City
  PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)--State
FROM PortfolioProject.dbo.NashvilleHousing


ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress nvarchar(225)

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity nvarchar(225)

UPDATE NashvilleHousing
SET OwnerSplitCity =  PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState nvarchar(225)

UPDATE NashvilleHousing
SET OwnerSplitState =   PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

--Replace Y and N with Yes and No in the "SoldAsVacant" field
--This is to resolve the data entry inconsistency issue and ease the analysis


SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
   CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
   WHEN SoldAsVacant = 'N' THEN 'No'
   ELSE SoldAsVacant
   END
FROM PortfolioProject.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant =   CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
                     WHEN SoldAsVacant = 'N' THEN 'No'
                     ELSE SoldAsVacant
                     END


--Remove duplicates

                                                    --WINDOW FUNCTIONS: the PARTITION BY CLAUSE

--In SQL Server the PARTITION BY clause is part of the window function syntax rather than a standalone function. 
--It's used to divide the result set into partitions (or groups) that the window function can then operate on. 
--Essentially, PARTITION BY allows you to perform calculations across sets of rows that share something in common without collapsing them into a single output row, as a GROUP BY would do.
--Ranking Functions: ROW_NUMBER(), RANK(), DENSE_RANK(), NTILE(n)
--Aggregate Functions: SUM()AVG(),MIN(), MAX(), COUNT()
--Analytic Functions: LEAD(), LAG(), FIRST_VALUE(), LAST_VALUE()

--The query is particularly useful when you need to identify and possibly manipulate duplicate records.
--The row_num column, generated by ROW_NUMBER(), can help in scenarios where I might want to:
     --Keep only the first occurrence of each duplicate record based on the partitioning columns,
	 --Perform further analysis or filtering based on the sequence of records within each partition.

WITH RowNumCTE AS(
SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference, YearBuilt, Acreage, TaxDistrict
ORDER BY UniqueID
) row_num
FROM PortfolioProject.dbo.NashvilleHousing
--ORDER BY ParcelID
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
--ORDER BY PropertyAddress-- This sorts out all the duplicates


--Delete unused columns

SELECT*
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

