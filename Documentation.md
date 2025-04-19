
# Documentation


## Authentication Methods.
### oAuth
One-click browser authentication, sufficient for most users
 - GitHub
 - Gitea
### Other
Manual arbitrary authentication methods for more advanced/self-hosting users
 - HTTP/S
     - Username and token for auth
 - SSH
     - Generated RSA ([only](https://github.com/ViscousPot/GitSync/issues/148)) token pair for auth

## Sync Mechanisms

### From quick tile

- Follow your OS-specific directions to add a quick tile
- Select the quick tile labeled `GitSync`
- Clicking the quick tile will trigger a sync (in the same way as the in-app sync button)

### When app opened or closed
![Application observer panel](https://github.com/user-attachments/assets/0943be2b-7e12-48f3-b362-366c8715b778)
- Enable the auto sync feature
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

## Resolve Merge Conflicts

### When a merge conflict occurs in your repository
- A notification is sent to the device
- Sync methods other than `Force Push` and `Force Pull` are disabled
- A `MERGE CONFLICT` entry is added to the recent commits

### Clicking on the `MERGE CONFLICT` entry will
- Take you to the resolution dialog
- Allow you to navigate between conflicts using the arrows
- Allow you to decide which changes to keep and discard
- Allow you to open any conflicting file in an editor for more control

![Merge conflict dialog](https://github.com/user-attachments/assets/37b8c5d3-27fe-434f-8a98-816a39c47763)

## Settings
### Sync Message
- Customise the commit message template that is used on sync
- Use `%s` to have the date and time inserted in the format `yyyy-MM-dd HH:mm:ss` (`1997-01-01 12:00:00`)

### Author Name & Email
- Customise the name and email of the author used for commits

### Default Remote
- Modify the default remote used for operations

### Gitignore
- Allows editing of the repository's gitignore file
- A list of files and folder paths that should not be synced
- [See here for more](https://git-scm.com/docs/gitignore)

### git/info/exclude
- Allows editing of the repository's local gitignore file
- A list of files and folder paths that should not be synced
- [See here for more](https://docs.github.com/en/get-started/getting-started-with-git/ignoring-files#excluding-local-files-without-creating-a-gitignore-file)

![Settings dialog](https://github.com/user-attachments/assets/50218268-9fa5-40ea-8229-f73aa60dea3d)

## Extra Settings

![Turn on/off notifications button](https://github.com/user-attachments/assets/f88c8db1-4ca7-4ded-a53d-acc37268725c)
- Turn on/off flashing a small popup message on screen when a sync happens
