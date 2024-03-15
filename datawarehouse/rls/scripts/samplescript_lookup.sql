-- create the table 
DROP TABLE sales.SalesByCountry;

CREATE TABLE sales.SalesByCountry (
    CountryCode CHAR(2),
    SalesDate DATE,
    ProductID INT,
    QuantitySold INT,
    Revenue DECIMAL(10, 2)
);

Select * from sales.SalesByCountry

-- Insert sample data
INSERT INTO sales.SalesByCountry (CountryCode, SalesDate, ProductID, QuantitySold, Revenue)
VALUES
    ('US', '2024-02-27', 101, 50, 2500.00),
    ('US', '2024-02-27', 102, 30, 1800.00),
    ('CA', '2024-02-27', 101, 20, 1000.00),
    ('CA', '2024-02-27', 103, 15, 750.00),
    ('UK', '2024-02-27', 102, 25, 1500.00),
    ('UK', '2024-02-27', 104, 10, 500.00),
    ('DE', '2024-02-27', 101, 40, 2000.00),
    ('DE', '2024-02-27', 103, 18, 900.00),
    ('FR', '2024-02-27', 102, 22, 1320.00),
    ('FR', '2024-02-27', 105, 12, 720.00);

-- Creating table mapping between country and sales representative
DROP Table sales.SalesRepCountryMapping;

CREATE TABLE sales.SalesRepCountryMapping (
    SalesRep VARCHAR(100),
    SalesEmailId VARCHAR(100),
    CountryCode CHAR(2)
);

select * from sales.SalesRepCountryMapping


-- Insert sample data
INSERT INTO sales.SalesRepCountryMapping (SalesRep, SalesEmailId, CountryCode)
VALUES
    ('LeeG', 'LeeG@CONTOSO.OnMicrosoft.com', 'US'),
    ('AlexW', 'AlexW@CONTOSO.OnMicrosoft.com', 'CA')

-- Creating a function for the SalesByCountry evaluation
CREATE FUNCTION Security.fn_security_predicateSales_by_country_code(@country_code AS varchar(50))
    RETURNS TABLE
WITH SCHEMABINDING
AS
    RETURN SELECT 1 AS fn_security_predicateSales_by_country_code_result
    FROM
        sales.SalesRepCountryMapping as mapping
        inner join sales.SalesByCountry as sales on mapping.CountryCode = sales.CountryCode
        WHERE mapping.SalesEmailId = USER_NAME()
        AND sales.CountryCode = @country_code

-- Using the function to create a Security Policy
CREATE SECURITY POLICY sales.SalesByCountryFilter
ADD FILTER PREDICATE Security.fn_security_predicateSales_by_country_code(CountryCode)
ON sales.SalesByCountry
WITH (STATE = ON);
GO


-- Lets create more table 
CREATE TABLE sales.salesTargetData (
    CountryCode NVARCHAR(2), -- e.g., 'US', 'CA', 'UK'
    SalesDate DATE,
    ProductID INT,
    QuantitySold INT,
    Revenue DECIMAL(18, 2),
    Target DECIMAL(18, 2),
    Achievement DECIMAL(18, 2)
);


INSERT INTO sales.salesTargetData (CountryCode, SalesDate, ProductID, QuantitySold, Revenue, Target, Achievement)
VALUES
    ('US', '2024-02-27', 101, 50, 2500.00, 3000.00, 0.83),
    ('US', '2024-02-27', 102, 30, 1800.00, 2000.00, 0.90),
    ('CA', '2024-02-27', 101, 20, 1000.00, 1200.00, 0.83),
    ('CA', '2024-02-27', 103, 15, 750.00, 900.00, 0.83),
    ('UK', '2024-02-27', 102, 25, 1500.00, 1800.00, 0.83),
    ('UK', '2024-02-27', 104, 10, 500.00, 600.00, 0.83),
    ('DE', '2024-02-27', 101, 40, 2000.00, 2400.00, 0.83),
    ('DE', '2024-02-27', 103, 18, 900.00, 1080.00, 0.83),
    ('FR', '2024-02-27', 102, 22, 1320.00, 1600.00, 0.83),
    ('FR', '2024-02-27', 105, 12, 720.00, 900.00, 0.80);

-- Creating a function for the SalesTargetData  evaluation
CREATE FUNCTION Security.fn_security_predicate_SalesTargetData_by_country(@country_code AS varchar(50))
    RETURNS TABLE
WITH SCHEMABINDING
AS
    RETURN SELECT 1 AS fn_security_predicate_SalesTargetData_by_country_result
    FROM
        sales.SalesRepCountryMapping as mapping
        inner join sales.SalesTargetData as sales on mapping.CountryCode = sales.CountryCode
        WHERE mapping.SalesEmailId = USER_NAME()
        AND sales.CountryCode = @country_code

-- Using the function to create a Security Policy
CREATE SECURITY POLICY sales.SalesTargetDataFilter
ADD FILTER PREDICATE Security.fn_security_predicate_SalesTargetData_by_country(CountryCode)
ON sales.salesTargetData
WITH (STATE = ON);
GO

-- provide access to the Admin

INSERT INTO sales.SalesRepCountryMapping (SalesRep, SalesEmailId, CountryCode)
VALUES
    ('ADMIN', 'admin@CONTOSO.onmicrosoft.com', 'UK'),
    ('ADMIN', 'admin@CONTOSO.onmicrosoft.com', 'US'),
    ('ADMIN', 'admin@CONTOSO.onmicrosoft.com', 'CA'),
    ('ADMIN', 'admin@CONTOSO.onmicrosoft.com', 'IN')

