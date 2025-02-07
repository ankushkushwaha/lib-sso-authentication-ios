# lib-sso-authentication-ios

## Usage 

### Step 1: Initialize SSOAuthentication

```
        SSOAuthentication.initialize(
            clientId: clientId,
            issuerUrl: issuerUrl,
            redirectUri: redirectUri,
            postLogoutRedirectUri: redirectUri,
            authorizationEndpoint: authorizationEndpoint,
            tokenEndpoint: tokenEndpoint,
            logoutUrl: logoutUrl,
            scope: [clientId, OIDScopeOpenID, OIDScopeProfile, "offline_access"]
        )
```
