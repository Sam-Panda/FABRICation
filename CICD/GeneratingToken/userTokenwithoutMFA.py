import msal
import requests
import pandas as pd
import time
# reading from the .env file 
from dotenv import load_dotenv
import os
load_dotenv()

# Your Azure Active Directory tenant ID
TENANT_ID = os.environ.get('CONTOSO_TENANT_ID')
# Your Azure AD registered application's client ID
CLIENT_ID = os.environ.get('CONTOSO_APPLICATION_ID')

# The UPN and password of the user
USERNAME = os.environ.get('CONTOSO_SERVICE_ACCOUNT_NAME')
PASSWORD = os.environ.get('CONTOSO_SERVICE_ACCOUNT_PASSWORD')
 
# The authority URL
AUTHORITY_URL = f'https://login.microsoftonline.com/{TENANT_ID}'
# The scope for the token
SCOPE = ['https://api.fabric.microsoft.com/.default']
 
# Create a public client application
app = msal.PublicClientApplication(CLIENT_ID, authority=AUTHORITY_URL, client_credential=None)
 
# Acquire token by username and password
result = app.acquire_token_by_username_password(USERNAME, PASSWORD, scopes=SCOPE)
 
# Check if the token was acquired successfully
if 'access_token' in result:
    access_token = result['access_token']
else:
    print(result.get('error_description'))
 
# Let's use the token to create the workspace
 
# The workspace name you are looking for
workspace_name = 'FABRIC-WORKSPACE-DEVELOPER1-FEATURE1'
 
# Create the headers dictionary
headers = {
    'Content-Type': 'application/json',
    'Authorization': f'Bearer {access_token}'
}

# CALL THE APi TO CREATE THE POWER bI WORKSPACE
response = requests.get(f'https://api.fabric.microsoft.com/v1/workspaces/', headers=headers)

pd.json_normalize(response.json(), 'value')