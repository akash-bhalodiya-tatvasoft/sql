/*--------------------------------------------------------*/
CREATE PROCEDURE spProductList AS
BEGIN
	SELECT * FROM production.products;
END;

EXEC spProductList;
/*--------------------------------------------------------*/
CREATE PROCEDURE spProductListSorted AS
BEGIN
	SELECT * FROM production.products;
END;

EXEC spProductListSorted;
/*--------------------------------------------------------*/
DROP PROC spProductListSorted;    
/*--------------------------------------------------------*/
CREATE PROCEDURE spProductListSearch(@priceTHreshold AS INT) AS
BEGIN
	SELECT * FROM production.products WHERE list_price > @priceTHreshold;
END;

EXEC spProductListSearch 5000;
/*--------------------------------------------------------*/
CREATE PROCEDURE spProductListSearchByPriceRange(@minPrice AS INT, @maxPrice AS INT) AS
BEGIN
	SELECT * FROM production.products WHERE list_price >= @minPrice AND list_price <= @maxPrice;
END;

EXEC spProductListSearchByPriceRange 2000, 3000;

EXECUTE spProductListSearchByPriceRange @minPrice = 2000, @maxPrice = 3000;
/*--------------------------------------------------------*/
CREATE PROCEDURE spProductListSearchByName(@name AS VARCHAR(MAX)) AS
BEGIN
	SELECT * FROM production.products WHERE product_name LIKE '%' + @name + '%';
END;

EXEC spProductListSearchByName @name = 'Trek';
/*--------------------------------------------------------*/
CREATE PROCEDURE spProductListSearchOptional(@minPrice AS INT = 0, @maxPrice AS INT = 100000, @name AS VARCHAR(MAX)) AS
BEGIN
	SELECT * FROM production.products WHERE list_price >= @minPrice AND list_price <= @maxPrice AND product_name LIKE '%' + @name + '%';
END;

EXEC spProductListSearchOptional @minPrice = 5000, @name = 'Trek';
/*--------------------------------------------------------*/
CREATE PROCEDURE spGetProductCounts AS
BEGIN
	DECLARE @productCount INT;
	SET @productCount = (SELECT COUNT(*) FROM production.products);
	SELECT @productCount
END;

EXEC spGetProductCounts
/*--------------------------------------------------------*/
CREATE PROCEDURE spGetAProductOf2018 AS
BEGIN
	DECLARE @productList VARCHAR(MAX);
	SELECT @productList = product_name + '____' + CAST(model_year as NVARCHAR) FROM production.products WHERE model_year = 2018;
	SELECT @productList
END;

EXEC spGetAProductOf2018
/*--------------------------------------------------------*/
CREATE PROCEDURE spGetExpensiveProductCounts(@result INT OUTPUT) AS
BEGIN
	SELECT @result = COUNT(*) FROM production.products WHERE list_price > 5000;
END;

DECLARE @count INT;
EXEC spGetExpensiveProductCounts @result = @count OUTPUT;;
SELECT @count AS 'Number of products found';
/*--------------------------------------------------------*/
CREATE PROCEDURE spGetExpensiveProductMessage(@priceCut INT) AS
BEGIN
	DECLARE @result INT;
	SELECT @result = COUNT(*) FROM production.products WHERE list_price > @priceCut;

	IF @result > 10 
		BEGIN
			PRINT 'Too many products found';
		END;
	ELSE
		BEGIN
			PRINT 'Very few product found';
		END;
END;

EXEC spGetExpensiveProductMessage @priceCut = 6000;;
/*--------------------------------------------------------*/
CREATE PROCEDURE spPrintNumber(@count INT) AS
BEGIN
	DECLARE @counter INT = 1;

	WHILE @counter <= @count
	BEGIN
		PRINT @counter; 
		SET @counter = @counter + 1;
	END;
END;

EXEC spPrintNumber 10;
/*--------------------------------------------------------*/
CREATE PROCEDURE spPrintNumberBreak(@count INT) AS
BEGIN
	DECLARE @counter INT = 1;

	WHILE @counter <= @count
	BEGIN
		IF @counter = 5
			BREAK;
		PRINT @counter; 
		SET @counter = @counter + 1;
	END;
END;

EXEC spPrintNumberBreak 10;
/*--------------------------------------------------------*/
CREATE PROCEDURE spPrintNumberContinue(@count INT) AS
BEGIN
	DECLARE @counter INT = 1;

	WHILE @counter <= @count
	BEGIN
		SET @counter = @counter + 1;
		IF @counter = 5
			CONTINUE;
		PRINT @counter; 
	END;
END;

EXEC spPrintNumberContinue 10;
/*--------------------------------------------------------*/
