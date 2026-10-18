# Market Taking Trainer

An iPhone speed-training game for aspiring quant traders. You see a hand of mostly hidden playing cards and a market maker's quote ("Bid at Ask"), work out the expected value in your head, and Buy, Sell or Skip before the timer runs out. The full product spec is in [SPEC.md](SPEC.md); design choices are in [DECISIONS.md](DECISIONS.md).

It is built on Windows + WSL2 with [xtool](https://github.com/xtool-org/xtool), with no Mac or Xcode project.

## Layout

```text
Package.swift          SwiftPM package (one library product: the app)
xtool.yml              xtool config (bundle ID)
Sources/GameCore/      pure Swift game logic, tested on Linux
Sources/TrainerApp/    SwiftUI app
Tests/GameCoreTests/   swift test
scripts/check.sh       tests, optionally followed by xtool dev
```

## One-time setup (Windows + WSL2 Ubuntu)

These steps follow the [xtool Linux installation guide](https://xtool.sh/documentation/xtooldocs/installation-linux); check it if anything below has drifted.

### 1. Swift 6.4 in WSL

Install the Swift 6.4 toolchain for Ubuntu from <https://swift.org/install/linux> (the `swiftly` installer is easiest), then confirm:

```bash
swift --version   # Swift version 6.4.x
```

### 2. usbmuxd in WSL

```bash
sudo apt-get install usbmuxd libimobiledevice-utils
```

### 3. USB passthrough from Windows (usbipd)

In **PowerShell as Administrator** on Windows:

```powershell
winget install usbipd
usbipd list                                  # find the iPhone's BUSID, e.g. 2-3
usbipd bind --busid 2-3                      # once per device
usbipd attach --wsl --busid 2-3 --auto-attach
```

Leave `--auto-attach` running: the iPhone disconnects and reconnects when you tap **Trust**, and it is re-attached automatically.

Then in WSL, make sure usbmuxd is running and sees the phone:

```bash
sudo usbmuxd -f -v &     # or: sudo systemctl start usbmuxd  (if systemd is on)
idevice_id -l            # should print your phone's UDID
```

Unlock the phone and tap **Trust This Computer** when asked.

### 4. Xcode.xip (for the iOS SDK)

In a browser, download the Xcode version the xtool guide names (currently Xcode 27) from <https://developer.apple.com/download/all/?q=Xcode>. It needs an Apple ID sign-in, so `curl` won't work. Note where the `.xip` is saved; from WSL, your Windows Downloads folder is `/mnt/c/Users/<you>/Downloads`.

### 5. xtool

```bash
curl -fL "https://github.com/xtool-org/xtool/releases/latest/download/xtool-$(uname -m).AppImage" -o xtool
chmod +x xtool
sudo mv xtool /usr/local/bin/
xtool --help
```

```bash
xtool setup
```

- Login mode: choose **1: Password** (free Apple ID). Consider a throwaway Apple ID, since this uses private Apple APIs.
- When asked for `Path to Xcode.xip`, give the path from step 4. Extraction takes a while.
- Confirm with `swift sdk list`; it should list `darwin`.

### 6. iPhone settings

- **Developer Mode**: Settings → Privacy & Security → Developer Mode → On, then restart. The toggle often only appears after the first install attempt.
- **Trust the developer profile** after the first install: Settings → General → VPN & Device Management → your Apple ID → Trust.

## Build and run

```bash
swift test               # run the GameCore tests
xtool devices            # your iPhone should be listed
xtool dev                # build, sign, install and launch on the phone
scripts/check.sh --dev   # tests, then xtool dev
```

If the bundle ID `dev.pxpatel.MarketTakingTrainer` is rejected as taken, change `bundleID` in `xtool.yml` to something unique to you.

**Free Apple ID limits:** the install expires after **7 days** (run `xtool dev` again to reinstall), you can have up to 3 sideloaded apps at once, and only about 10 new app IDs per week.

## When the device step fails

Work down this list:

1. Phone unlocked, cable connected, **Trust** tapped?
2. `usbipd list` on Windows shows the phone as **Attached**? If not, run `usbipd attach --wsl --busid <BUSID> --auto-attach` again.
3. `idevice_id -l` in WSL prints a UDID? If not, restart usbmuxd: `sudo pkill usbmuxd; sudo usbmuxd -f -v &`.
4. `xtool devices` lists the phone?
5. `AFCClient.Error.muxError`: see [this xtool issue comment](https://github.com/xtool-org/xtool/issues/19#issuecomment-2898986718), which relays the connection through iTunes on Windows instead of usbipd.
6. App installed but won't open ("Untrusted Developer"): trust the profile (step 6).
7. App opens then immediately quits after a week: the 7-day signature expired; run `xtool dev` again.
8. Developer Mode missing: try one install first, then look again in Privacy & Security.
