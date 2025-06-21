<div align="center">
  <img src="app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.webp" width="140" />

  <h3>GitSync</h3>
  <h4>Mobile git client for syncing a repository between remote and a local directory</h4>
  
  <p align="center">
    <a href="#"><img src="https://img.shields.io/github/license/ViscousPot/GitSync?v=1" alt="license"></a>
    <a href="#"><img src="https://img.shields.io/github/last-commit/ViscousPot/GitSync?v=1" alt="last commit"></a>
    <a href="#"><img src="https://img.shields.io/github/downloads/ViscousPot/GitSync/total" alt="downloads"></a>
    <a href="https://github.com/sponsors/ViscousPot"><img src="https://img.shields.io/static/v1?label=Sponsor&message=%E2%9D%A4&logo=GitHub&color=%23fe8e86" alt="sponsor"></a>
    <a href="#"><img src="https://img.shields.io/github/stars/ViscousPot/GitSync?v=1" alt="stars"></a>
  </p>
    <a href="#"><img alt="2024 Gem of the Year (Obsidian Tools)" src="https://img.shields.io/badge/2024%20Gem%20of%20the%20Year%20(Obsidian%20Tools)-grey?style=for-the-badge&logo=obsidian&logoColor=pink"></a>

  <br />
  <br />

  <p align="center">
  <a href="https://play.google.com/store/apps/details?id=com.viscouspot.gitsync" target="_blank"><img src="https://github.com/user-attachments/assets/168cb841-392d-493a-bc47-a9e3e8a61a62" alt="Get it on Google Play" style="width: 174px !important;box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;-webkit-box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;" ></a>
  &nbsp;&nbsp;
  <a href="https://apt.izzysoft.de/fdroid/index/apk/com.viscouspot.gitsync" target="_blank"><img src="https://gitlab.com/IzzyOnDroid/repo/-/raw/master/assets/IzzyOnDroidButtonGreyBorder_nofont.png" alt="Get it on Izzy On Droid" style="width: 174px !important;box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;-webkit-box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;" ></a>
  </p>

  <p align="center">
    <a href="https://gitsync.viscouspotenti.al/wiki/">Documentation</a>
  </p>
  <br />

</div>


GitSync is a cross-platform git client that aims to simplify the process of syncing a folder between a git remote and a local directory. It works in the background to keep your files synced with a simple one-time setup and numerous options for activating manual syncs.

- **Supports Android 5+ & iOS 12+**
- Authenticate with
    - **GitHub**
    - **Gitea**
    - **Gitlab**
    - **HTTP/S**
    - **SSH**
- Clone a remote repository
- Sync repository
    - Fetch changes
    - Pull changes
    - Commit new changes
    - Push changes
    - Resolve merge conflicts
- Sync mechanisms
    - From a quick tile
    - When an app is opened or closed
    - On a schedule
    - From a custom intent (advanced)
- Settings
    - Customise sync message
    - Edit .gitignore file
  
Give us a ⭐ if you like our work. Much appreciated!

## Build Instructions

**Coming soon with the open-source release of the cross-platform codebase!**
<!---
If you just want to try the app out, feel free to use a pre-built release from the [Releases](https://github.com/ViscousPot/GitSync/releases) page

### 1. Setup 
- Clone the project
```bash
  git clone https://github.com/ViscousPot/GitSync.git
```


- Go to the project directory

```bash
  cd GitSync
```

- Open the project in Android Studio
- Sync the gradle project

### 2. Secrets 
- Rename `Secrets.kt.template` to `Secrets.kt`
- Visit `https://github.com/settings/developers`
- Select `OAuth Apps`
- Select `New OAuth App`
  - Application Name: GitSync
  - Homepage URL: `https://github.com/ViscousPot/GitSync`
  - Authorization callback URL: `gitsync://auth`
  - Enable Device Flow: `leave unchecked` 
- Fill `Secrets.kt` with the new OAuth App ID and SECRET

### 3. Build & Run
- Build from within Android Studio
--->
## Support

For support, email bugs.viscouspotential@gmail.com.

Consider [sponsoring](https://github.com/sponsors/ViscousPot)! Any help is hugely appreciated!


## Authors

- [@ViscousPot](https://github.com/ViscousPot)


## Acknowledgements

 - [JGit](https://github.com/eclipse-jgit/jgit)

