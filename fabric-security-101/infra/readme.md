# Deployment Instructions

From the command prompt or PowerShell, navigate to the root directory of the project and run the following command:

```bash
cd fabric-security-101/infra
az deployment create --location 'westus2'  --template-file  main.bicep --parameter location='westus2' environmentName='dev' sqlAdministratorLogin=<SQLuserName> sqlAdministratorLoginPassword=<SQL Password>
```