# Row Level Security (RLS) in Datawarehouse from the mapping table

## Overview

Row-level security (RLS) in Fabric Warehouse and SQL analytics endpoint allows you to control access to rows in a database table based on user roles and predicates. For example, you can ensure that users can only access the rows in a table that are assigned to their sales region. RLS is a great way to implement security in your datawarehouse.
In this document, we will explain how to implement RLS in your datawarehouse using the mapping table.

![alt text](https://github.com/Sam-Panda/FABRICation/main/datawarehouse/rls/.media/image.png)

## Setup

Step by Step guide on how to setup RLS in your datawarehouse. [[link](https://learn.microsoft.com/en-us/fabric/data-warehouse/tutorial-row-level-security)]

Here are the main steps to setup RLS in your datawarehouse for this example:
1. Create a mapping table
``` sql

CREATE TABLE sales.SalesRepCountryMapping (
    SalesRep VARCHAR(100),
    SalesEmailId VARCHAR(100),
    CountryCode CHAR(2)
);
-- Insert sample data
INSERT INTO sales.SalesRepCountryMapping (SalesRep, SalesEmailId, CountryCode)
VALUES
    ('LeeG', 'LeeG@CONTOSO.OnMicrosoft.com', 'US'),
    ('AlexW', 'AlexW@CONTOSO.OnMicrosoft.com', 'CA')

-- provide access to the Admin

INSERT INTO sales.SalesRepCountryMapping (SalesRep, SalesEmailId, CountryCode)
VALUES
    ('ADMIN', 'admin@CONTOSO.onmicrosoft.com', 'UK'),
    ('ADMIN', 'admin@CONTOSO.onmicrosoft.com', 'US'),
    ('ADMIN', 'admin@CONTOSO.onmicrosoft.com', 'CA'),
    ('ADMIN', 'admin@CONTOSO.onmicrosoft.com', 'IN')

```
2. create 2 transactional table where we would like to implement RLS

    Creating the SalesByCountry 
``` sql
CREATE TABLE sales.SalesByCountry (
    CountryCode CHAR(2),
    SalesDate DATE,
    ProductID INT,
    QuantitySold INT,
    Revenue DECIMAL(10, 2)
);

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

```
 Creating the salesTargetData

``` sql

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
```

3. Creating a function for the **SalesByCountry** &  **salesTargetData** evaluation

Here we are mapping the SalesEmailId with the CountryCode and then using the mapping table to evaluate the SalesByCountry and salesTargetData table.

``` sql

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

```
4. Creating a security policy for the **SalesByCountry** &  **salesTargetData** table

Row-level security in Fabric Synapse Data Warehouse supports predicate-based security. Filter predicates silently filter the rows available to read operations.

More information on how to create a security policy can be found [here](https://learn.microsoft.com/en-us/fabric/data-warehouse/row-level-security#predicate-based-row-level-security15)

``` sql

-- Creating a security policy for the SalesByCountry table
CREATE SECURITY POLICY sales.SalesByCountryFilter
ADD FILTER PREDICATE Security.fn_security_predicateSales_by_country_code(CountryCode)
ON sales.SalesByCountry
WITH (STATE = ON);
GO

-- Creating a security policy for the SalesTargetDataFilter table
CREATE SECURITY POLICY sales.SalesTargetDataFilter
ADD FILTER PREDICATE Security.fn_security_predicate_SalesTargetData_by_country(CountryCode)
ON sales.salesTargetData
WITH (STATE = ON);
GO


```
## Output

After setting up the RLS in your datawarehouse, you can now test the RLS by running the following query:
### Testing the RLS when User is executing the query including admin, and normal user. 

Here is the mapping table:
![alt text](https://github.com/Sam-Panda/FABRICation/main/datawarehouse/rls/.media/image-3.png)

``` sql

-- Please note that the Admin/ Normal user can only see the countries which are specified in the mapping table
select USER_NAME(), * from sales.SalesByCountry
```

when user: admin is exceuting the query:
![alt text](https://github.com/Sam-Panda/FABRICation/main/datawarehouse/rls/.media/image-1.png)
when Alex is executing the query:
![alt text](https://github.com/Sam-Panda/FABRICation/main/datawarehouse/rls/.media/image-2.png)