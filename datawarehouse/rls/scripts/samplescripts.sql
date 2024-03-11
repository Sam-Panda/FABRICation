CREATE SCHEMA sales;
GO

-- Create a table to store sales data
CREATE TABLE sales.Orders (
    SaleID INT,
    SalesRep VARCHAR(100),
    ProductName VARCHAR(50),
    SaleAmount DECIMAL(10, 2),
    SaleDate DATE
);

-- Insert sample data
INSERT INTO sales.Orders (SaleID, SalesRep, ProductName, SaleAmount, SaleDate)
VALUES
    (1, 'LeeG@M365x64901087.OnMicrosoft.com', 'Smartphone', 500.00, '2023-08-01'),
    (2, 'AlexW@M365x64901087.OnMicrosoft.com', 'Laptop', 1000.00, '2023-08-02'),
    (3, 'LeeG@M365x64901087.OnMicrosoft.com', 'Headphones', 120.00, '2023-08-03'),
    (4, 'AlexW@M365x64901087.OnMicrosoft.com', 'Tablet', 800.00, '2023-08-04'),
    (5, 'LeeG@M365x64901087.OnMicrosoft.com', 'Smartwatch', 300.00, '2023-08-05'),
    (6, 'AlexW@M365x64901087.OnMicrosoft.com', 'Gaming Console', 400.00, '2023-08-06'),
    (7, 'LeeG@M365x64901087.OnMicrosoft.com', 'TV', 700.00, '2023-08-07'),
    (8, 'AlexW@M365x64901087.OnMicrosoft.com', 'Wireless Earbuds', 150.00, '2023-08-08'),
    (9, 'LeeG@M365x64901087.OnMicrosoft.com', 'Fitness Tracker', 80.00, '2023-08-09'),
    (10, 'AlexW@M365x64901087.OnMicrosoft.com', 'Camera', 600.00, '2023-08-10');


    -- Creating schema for Security
CREATE SCHEMA Security;
GO
 
-- Creating a function for the SalesRep evaluation
CREATE FUNCTION Security.tvf_securitypredicate(@SalesRep AS nvarchar(50))
    RETURNS TABLE
WITH SCHEMABINDING
AS
    RETURN SELECT 1 AS tvf_securitypredicate_result
WHERE @SalesRep = USER_NAME() OR USER_NAME() = 'manager@contoso.com';
GO
 
-- Using the function to create a Security Policy
CREATE SECURITY POLICY SalesFilter
ADD FILTER PREDICATE Security.tvf_securitypredicate(SalesRep)
ON sales.Orders
WITH (STATE = ON);
GO