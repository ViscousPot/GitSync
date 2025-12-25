use crate::env;
use image::{imageops::overlay, DynamicImage, GenericImageView, Rgba, RgbaImage};
use serde_json::Value;
use std::{
    env::consts::OS,
    env::current_dir,
    fs,
    path::Path,
    process::{Command, Stdio},
    thread,
    time::Duration,
};

// iphone 16 pro max
// ipad air 13 inch
// Medium phone api 35

// const adjust: bool = false;

enum PlatformConstraint {
    AndroidOnly,
    IOSOnly,
    All,
}

struct ScreenshotConfig<'a> {
    platform: PlatformConstraint,
    yaml_name: &'a str,
    crop_ios: Option<(u32, u32, u32, u32)>,
    crop_android: Option<(u32, u32, u32, u32)>,
    triangle_size: Option<u32>,
    adjust: bool,
    is_android: Option<bool>,
}

fn generate_screenshot(config: ScreenshotConfig) {
    match config.platform {
        PlatformConstraint::AndroidOnly => {
            if config.is_android != Some(true) {
                return;
            }
        }
        PlatformConstraint::IOSOnly => {
            if config.is_android != Some(false) {
                return;
            }
        }
        PlatformConstraint::All => {}
    }

    if !config.adjust {
        Command::new("maestro")
            .arg("test")
            .arg(format!("generate_screenshots/{}.yaml", config.yaml_name))
            .stdout(Stdio::inherit())
            .output()
            .expect("Failed to execute command");
    }

    thread::sleep(Duration::from_secs(2));
    let raw_path = format!(
        "generate_screenshots/raw/screenshot_{}.png",
        config.yaml_name
    );
    let final_path = format!("generate_screenshots/screenshot_{}.png", config.yaml_name);
    let mut img = image::open(&raw_path).expect("Failed to open screenshot");

    let cropped = match config.is_android {
        Some(true) => config.crop_android.map(|(x, y, w, h)| img.crop(x, y, w, h)),
        Some(false) => config.crop_ios.map(|(x, y, w, h)| img.crop(x, y, w, h)),
        _ => None,
    }
    .unwrap_or(img);

    let output = if let Some(size) = config.triangle_size {
        add_triangles_to_image(cropped, size)
    } else {
        cropped
    };

    output
        .save(final_path)
        .expect("Failed to save final screenshot");
}

fn is_android() -> Option<bool> {
    let output = Command::new("flutter")
        .args(["devices", "--machine"])
        .output()
        .ok()?;

    if !output.status.success() {
        eprintln!("Flutter command failed.");
        return None;
    }

    let stdout = String::from_utf8_lossy(&output.stdout);
    let devices: Value = serde_json::from_str(&stdout).ok()?; // Return None if parse fails

    for device in devices.as_array()? {
        if let Some(platform) = device.get("targetPlatform").and_then(|p| p.as_str()) {
            match platform {
                "android" => return Some(true),
                "android-x64" => return Some(true),
                "ios" => return Some(false),
                _ => {}
            }
        }
    }

    None
}

fn add_triangles_to_image(img: DynamicImage, triangle_width: u32) -> DynamicImage {
    let (width, height) = img.dimensions();
    let mut cropped = img.to_rgba8();
    let red = Rgba([28, 28, 28, 255]);

    let mut add_triangle = |x_offset: u32, y_offset: u32, direction_x: i32, direction_y: i32| {
        for y in 0..triangle_width {
            for x in 0..=triangle_width - y {
                let px = (x_offset as i32 as i32 + x as i32 * direction_x as i32) as u32;
                let py = (y_offset as i32 as i32 + y as i32 * direction_y as i32) as u32;
                if px < width && py < height {
                    cropped.put_pixel(px, py, red);
                }
            }
        }
    };

    add_triangle(0, 0, 1, 1);
    add_triangle(width, 0, -1, 1);
    add_triangle(0, height, 1, -1);
    add_triangle(width, height, -1, -1);

    image::DynamicImage::ImageRgba8(cropped)
}

pub fn main(args: &[String]) {
    let adjust = args.iter().any(|arg| arg == "--adjust");

    let is_android = is_android();

    if !adjust {
        if (is_android == None) {
            if OS == "macos" {
                Command::new("xcrun")
                    .args(&["simctl", "boot", "iPhone 16 Pro Max"])
                    .status()
                    .expect("failed to boot iPhone simulator");
                Command::new("open")
                    .arg("-a")
                    .arg("Simulator")
                    .status()
                    .expect("failed to open Simulator");
            } else {
                let local_props_path = Path::new("../android/local.properties");
                let props =
                    fs::read_to_string(local_props_path).expect("failed to read local.properties");
                let sdk_dir = props
                    .lines()
                    .find(|l| l.starts_with("sdk.dir="))
                    .map(|l| l.trim_start_matches("sdk.dir=").replace("\\", "/"))
                    .expect("sdk.dir not found in local.properties");

                // let emulator_path = format!("{}/emulator/emulator", sdk_dir);
                // Command::new(&emulator_path)
                //     .args(&["-avd", "Medium_Phone_API_35"])
                //     .stdout(Stdio::null())
                //     .stderr(Stdio::null())
                //     .spawn()
                //     .expect("failed to launch Android emulator");

                let adb_path = format!("{}/platform-tools/adb", sdk_dir);

                Command::new(&adb_path)
                    .arg("wait-for-device")
                    .stdout(Stdio::null())
                    .stderr(Stdio::null())
                    .status()
                    .expect("failed to wait for device");

                loop {
                    let output = Command::new(&adb_path)
                        .args(&["shell", "getprop", "sys.boot_completed"])
                        .stdout(Stdio::piped())
                        .stderr(Stdio::null())
                        .output()
                        .expect("failed to run adb");
                    if String::from_utf8_lossy(&output.stdout).trim() == "1" {
                        break;
                    }
                    thread::sleep(Duration::from_secs(2));
                }
            }
        }
    }

    if !adjust {
        let path = "../lib/global.dart";
        let content = fs::read_to_string(&path).unwrap();
        let new_content = content.replace("const demo = false;", "const demo = true;");
        fs::write(&path, new_content).unwrap();

        let command = "flutter run; exit;";
        let package = "com.viscouspot.gitsync";
        let bundle_id = "com.viscouspot.git-sync";

        if is_android == Some(true) {
            let local_props_path = Path::new("../android/local.properties");
            let props =
                fs::read_to_string(local_props_path).expect("failed to read local.properties");
            let sdk_dir = props
                .lines()
                .find(|l| l.starts_with("sdk.dir="))
                .map(|l| l.trim_start_matches("sdk.dir=").replace("\\", "/"))
                .expect("sdk.dir not found in local.properties");
            let adb_path = format!("{}/platform-tools/adb", sdk_dir);

            Command::new(&adb_path)
                .args(&["shell", "am", "force-stop", package])
                .stdout(Stdio::null())
                .stderr(Stdio::null())
                .status()
                .ok();
        }

        if is_android == Some(false) {
            Command::new("xcrun")
                .args(&["simctl", "terminate", "booted", bundle_id])
                .stdout(Stdio::null())
                .stderr(Stdio::null())
                .status()
                .ok();
        }

        #[cfg(target_os = "windows")]
        Command::new("cmd")
            .args(&["/C", "start", "cmd", "/K", command])
            .spawn()
            .unwrap();

        #[cfg(target_os = "macos")]
        {
            let current_dir = current_dir().unwrap();
            let current_dir_str = current_dir.to_str().unwrap();

            Command::new("osascript")
                .arg("-e")
                .arg(format!(
                    "tell application \"Terminal\" to do script \"cd '{}' && {}\"",
                    current_dir_str, command
                ))
                .spawn()
                .unwrap();
        }

        #[cfg(target_os = "linux")]
        Command::new("gnome-terminal")
            .arg("--")
            .arg("bash")
            .arg("-c")
            .arg(command)
            .spawn()
            .unwrap();

        if is_android == Some(true) {
            let local_props_path = Path::new("../android/local.properties");
            let props = fs::read_to_string(local_props_path).unwrap();
            let sdk_dir = props
                .lines()
                .find(|l| l.starts_with("sdk.dir="))
                .map(|l| l.trim_start_matches("sdk.dir=").replace("\\", "/"))
                .unwrap();
            let adb_path = format!("{}/platform-tools/adb", sdk_dir);

            loop {
                let output = Command::new(&adb_path)
                    .args(&["shell", "pidof", package])
                    .stdout(Stdio::piped())
                    .stderr(Stdio::null())
                    .output()
                    .unwrap();
                if !String::from_utf8_lossy(&output.stdout).trim().is_empty() {
                    break;
                }
                thread::sleep(Duration::from_secs(2));
            }
        }

        if is_android == Some(false) {
            loop {
                let output = Command::new("xcrun")
                    .args(&["simctl", "spawn", "booted", "launchctl", "list"])
                    .stdout(Stdio::piped())
                    .stderr(Stdio::null())
                    .output()
                    .unwrap();
                if String::from_utf8_lossy(&output.stdout).contains(bundle_id) {
                    break;
                }
                thread::sleep(Duration::from_secs(2));
            }

            Command::new("xcrun")
                .arg("simctl")
                .arg("status_bar")
                .arg("booted")
                .arg("override")
                .arg("--time")
                .arg("2025-05-25T23:00:00.123Z")
                .spawn()
                .unwrap();
        }

        thread::sleep(Duration::from_secs(5));
    }

    generate_screenshot(ScreenshotConfig {
        platform: PlatformConstraint::All,
        yaml_name: "homepage",
        crop_ios: None,
        crop_android: Some((0, 54, 1080, 2309)),
        triangle_size: None,
        adjust: adjust,
        is_android: is_android,
    });

    generate_screenshot(ScreenshotConfig {
        platform: PlatformConstraint::AndroidOnly,
        yaml_name: "auth",
        crop_ios: None,
        crop_android: Some((96, 720, 909, 1048)),
        triangle_size: Some(40),
        adjust: adjust,
        is_android: is_android,
    });

    generate_screenshot(ScreenshotConfig {
        platform: PlatformConstraint::AndroidOnly,
        yaml_name: "auto_sync_settings",
        crop_ios: None,
        crop_android: Some((39, 926, 1002, 796)),
        triangle_size: Some(40),
        adjust: adjust,
        is_android: is_android,
    });

    generate_screenshot(ScreenshotConfig {
        platform: PlatformConstraint::AndroidOnly,
        yaml_name: "select_apps",
        crop_ios: None,
        crop_android: Some((79, 560, 922, 1291)),
        triangle_size: None,
        adjust: adjust,
        is_android: is_android,
    });

    generate_screenshot(ScreenshotConfig {
        platform: PlatformConstraint::AndroidOnly,
        yaml_name: "scheduled_sync_settings",
        crop_ios: None,
        crop_android: Some((39, 1473, 1002, 441)),
        triangle_size: Some(40),
        adjust: adjust,
        is_android: is_android,
    });

    generate_screenshot(ScreenshotConfig {
        platform: PlatformConstraint::AndroidOnly,
        yaml_name: "quick_sync_settings",
        crop_ios: None,
        crop_android: Some((39, 963, 1002, 1115)),
        triangle_size: Some(40),
        adjust: adjust,
        is_android: is_android,
    });

    if (is_android == Some(true)) {
        if (!adjust) {
            // Settings
            Command::new("maestro")
                .arg("test")
                .arg("generate_screenshots/settings_top.yaml")
                .stdout(Stdio::inherit())
                .output()
                .expect("Failed to execute command");

            Command::new("adb")
                .args([
                    "shell",
                    "screencap",
                    "-p",
                    "/sdcard/screenshot_settings_top.png",
                ])
                .status()
                .unwrap();
        }

        Command::new("adb")
            .args([
                "pull",
                "/sdcard/screenshot_settings_top.png",
                "generate_screenshots/screenshot_settings_top.png",
            ])
            .status()
            .unwrap();

        let mut img = image::open("generate_screenshots/screenshot_settings_top.png").unwrap();
        let cropped_top = img.crop(0, 54, 1080, 2143);

        cropped_top
            .save("generate_screenshots/screenshot_settings_top.png")
            .unwrap();

        if (!adjust) {
            Command::new("maestro")
                .arg("test")
                .arg("generate_screenshots/settings_bottom.yaml")
                .stdout(Stdio::inherit())
                .output()
                .expect("Failed to execute command");

            Command::new("adb")
                .args([
                    "shell",
                    "screencap",
                    "-p",
                    "/sdcard/screenshot_settings_bottom.png",
                ])
                .status()
                .unwrap();
        }

        Command::new("adb")
            .args([
                "pull",
                "/sdcard/screenshot_settings_bottom.png",
                "generate_screenshots/screenshot_settings_bottom.png",
            ])
            .status()
            .unwrap();

        let mut img = image::open("generate_screenshots/screenshot_settings_bottom.png").unwrap();
        let cropped_bottom = img.crop(0, 466, 1080, 1983);

        cropped_bottom
            .save("generate_screenshots/screenshot_settings_bottom.png")
            .unwrap();

        let (width, _) = cropped_top.dimensions();
        let (_, height1) = cropped_top.dimensions();
        let (_, height2) = cropped_bottom.dimensions();
        let mut new_image = RgbaImage::new(width, height1 + height2);
        overlay(&mut new_image, &cropped_top, 0, 0);
        overlay(&mut new_image, &cropped_bottom, 0, height1 as i64);
        new_image
            .save("generate_screenshots/screenshot_settings.png")
            .unwrap();

        if (!adjust) {
            fs::remove_file("generate_screenshots/screenshot_settings_top.png").unwrap();
            fs::remove_file("generate_screenshots/screenshot_settings_bottom.png").unwrap();
        }
    } else if is_android == Some(false) {
        generate_screenshot(ScreenshotConfig {
            platform: PlatformConstraint::IOSOnly,
            yaml_name: "settings",
            crop_ios: None,
            crop_android: None,
            triangle_size: None,
            adjust: adjust,
            is_android: is_android,
        });
    }

    generate_screenshot(ScreenshotConfig {
        platform: PlatformConstraint::All,
        yaml_name: "manual_sync",
        crop_ios: None,
        crop_android: Some((0, 54, 1080, 2309)),
        triangle_size: None,
        adjust: adjust,
        is_android: is_android,
    });

    generate_screenshot(ScreenshotConfig {
        platform: PlatformConstraint::All,
        yaml_name: "merge_conflict",
        crop_ios: None,
        crop_android: Some((0, 54, 1080, 2309)),
        triangle_size: None,
        adjust: adjust,
        is_android: is_android,
    });

    // ----------------------------------------------------------------

    if (!adjust) {
        let path = "../lib/global.dart";
        let content = fs::read_to_string(&path).unwrap();
        let new_content = content.replace("const demo = true;", "const demo = false;");
        fs::write(&path, new_content).unwrap();
    }

    // ----------------------------------------------------------------

    let screenshot_export_paths = env::get_screenshot_export_paths();

    for path in &screenshot_export_paths {
        Command::new("sh")
            .arg("-c")
            .arg(format!("cp -r generate_screenshots/*.png {}", path))
            .status()
            .expect("Failed to execute cp command");
    }
}
