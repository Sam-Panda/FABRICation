# Generating Token by using username and password. ( not service principal)

This is a stop gap arrangement to generate the token by using the username and password. When Fabric APi will support SPN authentication, we will switch to SPN authentication.

## Here are some pre work is needed before running the script

1. The user account that is used to generate token should not have the MFA enabled.

- How to disable MFA for a user account?

There are various ways to disable the MFA, but the easiest way is to disable it from the entra.microsoft.com portal.

identity -> Overview -> Properties -> Manage Conditional Access -> Multifactor authentication for Microsoft partners and vendors -> Users -> exclude the user from MFA.


![alt text](./images/image.png)

2. Create a service principal for delegation and give API permission as it is required. I have given permission only for the workspace. If you would like to give more delegated permission, choose it from the Add a Permission -> search for Power BI Service -> delegated Permissions.


![alt text](./images/image-1.png)

3. Also enable Allow Public client flows in the Authentication -> Advanced settings -> Enable the Allow public client flows.

![alt text](./images/image-2.png)

4. We do not need the client secret for this script. So, do not create the client secret.
