<div align="center">
  <br/>
  <img 
    src="android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.webp" width="140" 
  />

  <h3>GitSync</h3>
  <h4>Mobile git client for syncing a repository between remote and a local directory</h4>
  
  <p align="center">
    <a href="#"><img src="https://img.shields.io/github/license/ViscousPot/GitSync?v=1" alt="license"></a>
    <a href="#"><img src="https://img.shields.io/github/last-commit/ViscousPot/GitSync?v=1" alt="last commit"></a>
    <a href="#"><img src="https://img.shields.io/github/downloads/ViscousPot/GitSync/total" alt="downloads"></a>
    <a href="#"><img src="https://img.shields.io/github/stars/ViscousPot/GitSync?v=1" alt="stars"></a>
    <a href="https://github.com/sponsors/ViscousPot"><img src="https://img.shields.io/static/v1?label=Sponsor&message=%E2%9D%A4&logo=GitHub&color=%23fe8e86" alt="sponsor"></a>
  </p>
    <img alt="2024 Gem of the Year (Obsidian Tools)" src="https://img.shields.io/badge/2024%20Gem%20of%20the%20Year%20(Obsidian%20Tools)-black?style=for-the-badge&logo=obsidian&logoColor=hotpink">
  <br />
  <br />

  <p align="center">
  <a href="https://play.google.com/store/apps/details?id=com.viscouspot.gitsync" target="_blank"><img src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg" alt="Get it on Google Play" style="height: 48px" ></a>  
  &nbsp;&nbsp;
  <a href="https://apps.apple.com/us/app/gitsync/id6744980427" target="_blank"><img src="https://upload.wikimedia.org/wikipedia/commons/9/91/Download_on_the_App_Store_RGB_blk.svg" alt="Get it on Google Play" style="height: 48px" ></a>
  &nbsp;&nbsp;
  <a href="https://apt.izzysoft.de/fdroid/index/apk/com.viscouspot.gitsync" target="_blank"><img src="https://gitlab.com/IzzyOnDroid/repo/-/raw/master/assets/IzzyOnDroidButtonGreyBorder_nofont.png" alt="Get it on Izzy On Droid" style="height: 48px" ></a>
  <!-- &nbsp;&nbsp; -->
  <!-- <a href="#" target="_blank"><img src="https://upload.wikimedia.org/wikipedia/commons/a/a3/Get_it_on_F-Droid_%28material_design%29.svg" alt="Get it on F-Droid" style="height: 48px" ></a> -->
  </p>

  <p align="center">
    <a href="https://gitsync.viscouspotenti.al/wiki"><img alt="Wiki" src="https://img.shields.io/badge/wiki-white?style=for-the-badge"></a>
  </p>
  <br />

</div>

GitSync is a cross-platform git client for Android and iOS that aims to simplify the process of syncing a folder between a git remote and a local directory. It works in the background to keep your files synced with a simple one-time setup and numerous options for activating manual syncs

- **Supports Android 6+ & iOS 12+**
- Authenticate with
  - **HTTP/S**
  - **SSH**
  - **OAuth**
    - **GitHub**
    - **Gitea**
    - **Gitlab**
- Clone a remote repository
- Sync repository
  - Fetch changes
  - Pull changes
  - Stage & commit changes
  - Push changes
  - Resolve merge conflicts
- Setup automated sync mechanisms
  - Automatically, when an app is opened or closed
  - Automatically, on a schedule
  - From a quick tile
  - From a custom intent (advanced)
- Repository Settings
  - Signed commits
  - Customisable sync commit messages
  - Author details
  - Edit .gitignore & .git/info/exclude files
  - Disable SSL

More information can be found at the [wiki](https://gitsync.viscouspotenti.al/wiki)
<br>
Give us a ⭐ if you like our work. Much appreciated!

## Support

For support, email bugs.viscouspotential@gmail.com or create an issue in this repository.

## Build Instructions

If you just want to try the app out, feel free to download a release from an official platform!

_Build instructions coming soon..._

<!-- ### 1. Setup

- Clone the project

```bash
  git clone https://github.com/ViscousPot/GitSync.git
```

- Go to the project directory

```bash
  cd GitSync
```
 -->

<!-- Check Your Entitlements File

Ensure that the .entitlements file contains the correct APS environment string:

<key>aps-environment</key>
<string>development</string>

    Use "development" for development builds.

    Use "production" for App Store or TestFlight builds.

If the file doesn’t exist, create one manually or let Xcode generate it when adding the capability. -->

<!-- - Open the project in Android Studio
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
- Build from within Android Studio -->

## Contributing

Your support means a lot! If you find GitSync useful, please:

- Star the repo to help others discover it
- Share it with friends or communities that might benefit
- Consider becoming a [GitHub Sponsor](https://github.com/sponsors/ViscousPot)

<br>
At this time, code contributions aren’t needed anywhere in particular, but I’d love your help improving <strong><a href="#localization-contributions">localization</a></strong>

<details>
<summary><h3 style="display:inline-block;">Localization Contributions</h3></summary>

If you’d like to contribute translations:

1. Locate the **English strings** in `lib/l10n/app_en.arb`
2. Find the corresponding language file (e.g. `lib/l10n/app_es.arb` for Spanish)
3. Add or refine translations in the appropriate file
4. Submit a pull request or open an issue with your suggestions

Currently supported languages:

- English (`app_en.arb`)
- Spanish (`app_es.arb`)
- Chinese (`app_zh.arb`)
- Russian (`app_ru.arb`)
- German (`app_de.arb`)

Even small improvements to wording or grammar are welcome.

</details>

## Acknowledgements

- [flutter_rust_bridge](https://github.com/fzyzcjy/flutter_rust_bridge)
- [git2-rs](https://github.com/rust-lang/git2-rs)

<!-- Find unstringed strings regex:
`^(?!.*\b(?:Logger\.log|Logger\.logError|Logger\.gmLog|import|static|invokeMethod|initLogger|GitManagerRs\.init|pragma)\b).*['"](?![^'"]*\$)(.{2,})['"]`

include
ui/
-->

<!-- ### Building Binaries

`flutter run -v`

#### Android

[ +100 ms] INFO: Building rust_lib_GitSync for aarch64-linux-android
[+65599 ms] INFO: Building rust_lib_GitSync for i686-linux-android
[+35800 ms] INFO: Building rust_lib_GitSync for x86_64-linux-android

for android builds??
export LIBGIT2_SYS_USE_PKG_CONFIG=0
export ZLIB_SRC=1 -->
