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
CREATE PROCEDURE spPrintProductCursor AS
BEGIN
	DECLARE @product_name VARCHAR(MAX), @list_price DECIMAL;

	DECLARE cursor_product CURSOR FOR
		SELECT product_name, list_price FROM production.products WHERE list_price > 5000;

	OPEN cursor_product;

	FETCH NEXT FROM cursor_product INTO @product_name, @list_price;

	WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT @product_name + '______' + CAST(@list_price AS NVARCHAR) + '______' + CAST(@@FETCH_STATUS AS VARCHAR);
        FETCH NEXT FROM cursor_product INTO @product_name, @list_price;
    END;

	CLOSE cursor_product;

	DEALLOCATE cursor_product;
	
END;

EXEC spPrintProductCursor;
/*--------------------------------------------------------*/
CREATE PROCEDURE spPrintTryCatch(@dividedBy INT) AS
BEGIN
	BEGIN TRY
		SELECT 100/@dividedBy;
		PRINT 'TRY';
	END TRY
	BEGIN CATCH
		PRINT 'CATCH';
	END CATCH
END;

EXEC spPrintTryCatch 0;
EXEC spPrintTryCatch 10;
/*--------------------------------------------------------*/
CREATE PROCEDURE spTransaction(@id1 INT, @id2 INT) AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			 DELETE FROM sales.customers WHERE customer_id = @id1;
			 DELETE FROM sales.customers WHERE customer_id = @id2;
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
	END CATCH
END;

EXEC spTransaction 0, 1001;
/*--------------------------------------------------------*/
CREATE PROCEDURE spDynamicSQL(@table NVARCHAR(MAX)) AS 
BEGIN
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'SELECT * FROM ' + @table;
    EXEC sp_executesql @sql;
END;

EXEC spDynamicSQL @table = 'sales.customers';
EXEC spDynamicSQL @table = 'production.products';
/*--------------------------------------------------------*/
CREATE FUNCTION getFullName(@firstName NVARCHAR(MAX), @lastName NVARCHAR(MAX)) RETURNS NVARCHAR(MAX) AS
BEGIN
	return @firstName + ' ' + @lastName;
END

SELECT dbo.getFullName(first_name, last_name) FROM sales.customers;
/*--------------------------------------------------------*/
CREATE FUNCTION getCustomerByState(@state NVARCHAR(MAX)) RETURNS TABLE AS
	return SELECT * FROM sales.customers WHERE state = @state;

SELECT * FROM dbo.getCustomerByState('NY');
SELECT * FROM dbo.getCustomerByState('CA');
/*--------------------------------------------------------*/
CREATE TABLE production.product_audits(
    id INT IDENTITY PRIMARY KEY,
    product_id INT NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    brand_id INT NOT NULL,
    category_id INT NOT NULL,
    model_year SMALLINT NOT NULL,
    list_price DEC(10,2) NOT NULL,
    updated_at DATETIME NOT NULL,
    operation CHAR(3) NOT NULL,
);
/*--------------------------------------------------------*/
CREATE TRIGGER production.productTrigger 
ON production.products
AFTER INSERT,DELETE
AS
BEGIN
	INSERT INTO production.product_audits(
        product_id, 
        product_name,
        brand_id,
        category_id,
        model_year,
        list_price, 
        updated_at, 
        operation
    )
    SELECT
        i.product_id,
        product_name,
        brand_id,
        category_id,
        model_year,
        i.list_price,
        GETDATE(),
        'INS'
    FROM
        inserted i
    UNION ALL
    SELECT
        d.product_id,
        product_name,
        brand_id,
        category_id,
        model_year,
        d.list_price,
        GETDATE(),
        'DEL'
    FROM
        deleted d;
END;
/*--------------------------------------------------------*/
CREATE VIEW productDetailsView AS
	SELECT p.product_name, p.model_year, p.list_price, c.category_name, b.brand_name FROM production.products as p
	LEFT JOIN production.brands as b
	ON p.brand_id = b.brand_id
	LEFT JOIN production.categories as c
	ON c.category_id = p.category_id;

SELECT * FROM productDetailsView;
/*--------------------------------------------------------*/
CREATE TRIGGER productDetailsViewTrigger 
ON productDetailsView
INSTEAD OF INSERT AS
BEGIN
	INSERT INTO production.categories(category_name)
	SELECT DISTINCT i.category_name
	FROM inserted i
	WHERE NOT EXISTS (
		SELECT 1 FROM production.categories c
		WHERE c.category_name = i.category_name
	)

	INSERT INTO production.brands(brand_name)
	SELECT DISTINCT i.brand_name
	FROM inserted i
	WHERE NOT EXISTS (
		SELECT 1 FROM production.brands b
		WHERE b.brand_name = i.brand_name
	)

	INSERT INTO production.brands(brand_name)
	SELECT DISTINCT i.brand_name
	FROM inserted i
	WHERE NOT EXISTS (
		SELECT 1 FROM production.brands b
		WHERE b.brand_name = i.brand_name
	)

	INSERT INTO production.products
        (product_name, model_year, list_price, category_id, brand_id)
    SELECT
        i.product_name,
        i.model_year,
        i.list_price,
        c.category_id,
        b.brand_id
    FROM inserted i
    LEFT JOIN production.categories c
        ON c.category_name = i.category_name
    LEFT JOIN production.brands b
        ON b.brand_name = i.brand_name;
END
/*--------------------------------------------------------*/
INSERT INTO productDetailsView(product_name, model_year, list_price, category_name, brand_name)
VALUES('Test', 2022, 4999, 'Test Category 1', 'Test Brand 1')
/*--------------------------------------------------------*/
SELECT * FROM productDetailsView;
/*--------------------------------------------------------*/
SELECT *
FROM production.products p
JOIN sales.order_items oi
  ON oi.product_id = p.product_id
JOIN sales.orders o
  ON oi.order_id = o.order_id
WHERE p.product_name = 'Electra Moto 1 - 2016';
/*--------------------------------------------------------*/
CREATE INDEX productNameIndex
ON production.products(product_name);
/*--------------------------------------------------------*/
CREATE INDEX productNameIndex
ON production.products(product_name)
INCLUDE (product_id, brand_id, category_id, model_year, list_price);
/*--------------------------------------------------------*/
SELECT product_id, product_name, list_price FROM production.products;
/*--------------------------------------------------------*/
SELECT * FROM production.products ORDER BY list_price DESC;
/*--------------------------------------------------------*/
SELECT * FROM production.products ORDER BY list_price OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;
/*--------------------------------------------------------*/
SELECT TOP 3 * FROM production.products ORDER BY list_price DESC;
/*--------------------------------------------------------*/
SELECT DISTINCT city FROM sales.customers;
/*--------------------------------------------------------*/
SELECT * FROM production.products WHERE list_price > 5000;
/*--------------------------------------------------------*/
SELECT * FROM production.products WHERE list_price > 500 AND model_year = 2018;
/*--------------------------------------------------------*/
SELECT * FROM production.products WHERE model_year = 2017 OR model_year = 2018;
/*--------------------------------------------------------*/
SELECT * FROM production.products WHERE model_year IN (2017, 2018);
/*--------------------------------------------------------*/
SELECT * FROM production.products WHERE product_name LIKE '%Trek%';
/*--------------------------------------------------------*/
SELECT p.product_name, c.category_name FROM production.products p
INNER JOIN production.categories c
ON p.category_id = c.category_id;
/*--------------------------------------------------------*/
SELECT c.customer_id, o.order_id FROM sales.customers c
LEFT JOIN sales.orders o
ON c.customer_id = o.customer_id;
/*--------------------------------------------------------*/
SELECT c.customer_id, o.order_id FROM sales.customers c
FULL OUTER JOIN sales.orders o
ON c.customer_id = o.customer_id;
/*--------------------------------------------------------*/
SELECT s.store_name, c.category_name FROM sales.stores s
CROSS JOIN production.categories c;
/*--------------------------------------------------------*/
SELECT category_id, COUNT(*) FROM production.products GROUP BY category_id;
/*--------------------------------------------------------*/
SELECT category_id, COUNT(*) FROM production.products GROUP BY category_id HAVING COUNT(*) > 5;
/*--------------------------------------------------------*/
SELECT category_id, brand_id, COUNT(*) AS total FROM production.products
GROUP BY GROUPING SETS (
  (category_id, brand_id),
  (category_id),
  (brand_id),
  ()
);
/*--------------------------------------------------------*/
SELECT category_id, brand_id, COUNT(*) AS total FROM production.products
GROUP BY CUBE (category_id, brand_id);
/*--------------------------------------------------------*/
SELECT category_id, brand_id, COUNT(*) AS total FROM production.products
GROUP BY ROLLUP (category_id, brand_id);
/*--------------------------------------------------------*/
SELECT product_name FROM production.products
WHERE list_price > (SELECT AVG(list_price) FROM production.products);
/*--------------------------------------------------------*/
SELECT p.product_name FROM production.products p
WHERE p.list_price > (
	   SELECT AVG(list_price) FROM production.products c WHERE c.category_id = p.category_id
);
/*--------------------------------------------------------*/
SELECT * FROM sales.customers c
WHERE EXISTS (
  SELECT 1 FROM sales.orders o WHERE o.customer_id = c.customer_id
);
/*--------------------------------------------------------*/
SELECT * FROM production.products
WHERE list_price > ANY(SELECT list_price FROM production.products WHERE model_year = 2018);
/*--------------------------------------------------------*/
SELECT * FROM production.products
WHERE list_price > ALL(SELECT list_price FROM production.products WHERE model_year = 2016);
/*--------------------------------------------------------*/
SELECT * FROM sales.orders o
CROSS APPLY (SELECT * FROM sales.order_items oi WHERE oi.order_id = o.order_id) oi;
/*--------------------------------------------------------*/
SELECT * FROM sales.orders o
OUTER APPLY (SELECT * FROM sales.order_items oi WHERE oi.order_id = o.order_id) oi;
/*--------------------------------------------------------*/
SELECT city FROM sales.customers
UNION
SELECT city FROM sales.stores;
/*--------------------------------------------------------*/
SELECT city FROM sales.customers
INTERSECT
SELECT city FROM sales.stores;
/*--------------------------------------------------------*/
SELECT city FROM sales.customers
EXCEPT
SELECT city FROM sales.stores;
/*--------------------------------------------------------*/
WITH ProductCTE AS (
  SELECT product_name, list_price
  FROM production.products
)

SELECT * FROM ProductCTE WHERE list_price > 1000;
/*--------------------------------------------------------*/
SELECT * FROM (
  SELECT model_year, category_id
  FROM production.products
) AS src
PIVOT (
  COUNT(category_id)
  FOR model_year IN ([2016], [2017], [2018])
) AS pvt;
/*--------------------------------------------------------*/
