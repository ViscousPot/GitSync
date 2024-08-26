
# Documentation

## Quick Start

### Authenticate

![Auth button](https://i.postimg.cc/44M75jd1/auth.png)
- Click on the auth button and follow the authentication procedure on Github.com

### Setup repository

![Repository setup screen](https://i.postimg.cc/43CjQ4kT/clone.jpg)

- Clone a remote repository from your account or from a direct link
OR
- Select a local git repository fom your filesystem
## Sync Mechanisms

### From quick tile

- Follow your OS-specific directions to add a quick tile
- Select the quick tile labeled `GitSync`
- Clicking the quick tile will trigger a sync (in the same way as the in-app sync button)

### When app opened or closed

![Application observer panel](https://i.postimg.cc/5yGs9pfM/app.png)

- Enable the application observer feature
    - This will prompt you to enable the `Git Sync Accessibility Service`
    - This service is used to watch for the selected app being opened and closed (ignoring keyboards)
    - No data is collected or stored
- Select an application to watch
- Turn on/off sync on application opened or closed


### From custom intent (advanced)

- You can trigger a sync using a custom intent (e.g. from Tasker or other automation apps)
- Intent details
    - Target: `Service`
    - Package: `com.viscouspot.gitsync`
    - Class: `com.viscouspot.gitsync.GitSyncService`
    - Action: `INTENT_SYNC`

## Extra Settings

![Turn on/off notifications button](https://i.postimg.cc/fRHh7QWz/Screenshot-20240826-Sync-2.png)
Turn on/off flashing a small popup message on screen when a sync happens
