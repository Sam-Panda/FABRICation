# Deployment Guideline for Power BI Directlake Model in Microsoft Fabric

## Background
At the time of writing this blog, Power Bi directlake mode is not supported in the Deployment Pipeline. Here are the [current supported items](https://learn.microsoft.com/en-us/fabric/cicd/deployment-pipelines/intro-to-deployment-pipelines#supported-items) for Deployment Pipeline. This blog provides a guideline to deploy the Power BI Directlake model manually using the Tabular Editor.

## Overview
This blog post provides a step-by-step guide to deploy the Power BI Directlake model using the Tabular Editor. The deployment process involves creating a deployment model, importing it into Tabular Editor, and deploying it to the target workspace in the Microsoft Fabric .

## Prerequisites
- [Tabular Editor 2.x ](https://tabulareditor.github.io/TabularEditor/) should be installed on the local machine.
- 2 workspace should be created in the Microsoft Fabric. One for Development and another for Production. In this example, we have created two workspaces named `WSFabricDevelopment` and `WSfabricProduction`.
- One Lakehouse should be created in the both the workspaces preferably with the same name. In this example, we have created a Lakehouse named `LH1` in both the workspaces.
- We have created a table called `salesbycountry` in the Lakehouse `LH1` in the workspace `WSFabricDevelopment`. We will create this table to the workspace `WSfabricProduction`.




## Deployment Steps
Outline the step-by-step process for deploying the Power BI Directlake model. Include any configuration or setup steps that need to be performed.

1. Step 1: Move the lakehouse and notebook artifacts using the deployment pipeline from the development workspace to the production workspace.

    - (1): Create a new deployment pipeline in the Azure DevOps project.
    - (2): Add the lakehouse and notebook artifacts to the deployment pipeline.
    - (3): Configure the deployment pipeline to move the artifacts from the development workspace to the production workspace.
    - (4): Trigger the deployment pipeline to move the artifacts.

    ![alt text](https://github.com/Sam-Panda/FABRICation/blob/main/fabric-ci-cd/DirectlakeDeployment/.images/DeploymentPipeline_image.png)

    Here is the notebook script for creating the table `salesbycountry` in the Lakehouse `LH1`.

    ```python

    %%sql
    CREATE TABLE SalesByCountry (
        CountryCode CHAR(2),
        SalesDate DATE,
        ProductID INT,
        QuantitySold INT,
        Revenue DECIMAL(10, 2)
    )USING DELTA ;


    ```
    ```python
    %%sql
    INSERT INTO SalesByCountry (CountryCode, SalesDate, ProductID, QuantitySold, Revenue)
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
2. Step 2: Load the Development Model in the Tabular Editor
    - (1): provide the connection string of the development workspace in the Tabular Editor. Connection String can be found from `Workspace Settings -> Premium -> Workspace Connection`.

    ![alt text](https://github.com/Sam-Panda/FABRICation/blob/main/fabric-ci-cd/DirectlakeDeployment/.images/Workspace_connection_image.png)
    - (2): Connect to the workspace and tabular model in the Tabular Editor.

    ![alt text](https://github.com/Sam-Panda/FABRICation/blob/main/fabric-ci-cd/DirectlakeDeployment/.images/TabularModelLoad_image.png)


3. Step 3: change the connection string of the workspace in the Tabular Editor to the production workspace.

    The semantic model is a logical layer created on top of the physical tables that we have in the Lakehouse or Datawarehouse. When we move the semantic model from workspace to another workspace, we need to change the connection string of the development Lakehouse in the Tabular Editor to the production Lakehouse.

    **Where to find the connection string of the Semantic Model?**
    - (1): Go to the settings of the semantic model in the workspace, and look at the gateway Connection.

    ![alt text](https://github.com/Sam-Panda/FABRICation/blob/main/fabric-ci-cd/DirectlakeDeployment/.images/Gateway_connection_image.png)

    **Where to find the connection string of the Lakehouse?**
    - (1): Go to the Lakehouse and then change the view to the SQL Endpoint
    - (2): Go to the settings of the SQL Endpoint in the workspace, and look at server name details. and from the URL notedown the database name.
    

    ![alt text](https://github.com/Sam-Panda/FABRICation/blob/main/fabric-ci-cd/DirectlakeDeployment/.images/server_deltails_image.png)
    
    **How to change the connections string in the Tabular Editor?**
    
    Now for the DirectLake enabled mode, the connection string is kept in the expression name `DatabaseQuery`. We just need to change the connection string pointing to the production workspace lakehouse details. In the below screenshot, we have provided the details of the production workspace lakehouse.

    ![alt text](https://github.com/Sam-Panda/FABRICation/blob/main/fabric-ci-cd/DirectlakeDeployment/.images/Production_connection_string_lakehouse_image.png)

    The connection string is not dependent on the Lakehouse name, it is dependent on the GUID of the Lakehouse SQL Endpoint. So, even if we have the different Lakehouse name in the production environment, we can still deploy the semantic model in the production workspace by providing the valid database GUID.

    Even if we have a different table in the development Lakehouse and production Lakehouse, we can still do the deployment by mapping the correct source table from the semantic model table partition.  In the below screenshot, we have mapped the source table `salesbycountry` from production Lakehouse.

    ![alt text](https://github.com/Sam-Panda/FABRICation/blob/main/fabric-ci-cd/DirectlakeDeployment/.images/table_selection_image.png)

4. Step 4: Deploy the semantic model to the production workspace.

    Once the connection string is changed to the production Lakehouse, we can deploy the semantic model to the production workspace. We can do this by clicking on the `Deploy` button in the Tabular Editor. In the Destination Server setting, we need to provide the connection details of the Production workspace. We can give any name to the semantic model while deploying, however keeping the same name as the development workspace is preferred.

    ![alt text](https://github.com/Sam-Panda/FABRICation/blob/main/fabric-ci-cd/DirectlakeDeployment/.images/Model_production_deployment_image.png)

5. Step 5: Validate the deployment in the production workspace.

    If we go the production workspace, we can see the semantic model is deployed successfully. We can validate the deployment by checking the tables and measures in the semantic model.

    ![alt text](https://github.com/Sam-Panda/FABRICation/blob/main/fabric-ci-cd/DirectlakeDeployment/.images/Deployment_successful_image.png)


    Hope this helps! 

