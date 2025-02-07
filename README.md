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

### Step 2: Call Login and logout

```
// Login
               SSOAuthentication.shared.startAuthenticationProcess(from: viewController, username: nil, completion: { [weak self] accessToken, error in 
               
               })
```

