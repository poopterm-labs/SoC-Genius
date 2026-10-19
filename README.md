# SoC Genius

SoC Genius is a jailbreak-only hardware information app for legacy 32-bit iPhones, iPads, and iPod touch devices. It uses an iOS 6-inspired interface and runs locally on the device.

## Features

- Identifies the device, board identifier, display resolution, iOS version, and OS build.
- Shows SoC, CPU architecture and microarchitecture, core count, GPU, process node, and nominal clock for profiled devices.
- Reports OpenGL ES renderer information, total and per-core CPU load, and cache or CPU-frequency values when the kernel exposes them.
- Shows installed and available memory, app resident memory, battery state, and storage capacity/free space on `/var`.
- Streams three-axis accelerometer readings while the Sensors page is open.
- Displays the app version and build number in the System section.

Missing kernel readings are shown as unavailable. iOS does not provide a reliable CPU-temperature reading across these devices.

## Device profiles

The database is keyed by `hw.machine` identifiers in [`SoCGenius/main.m`](SoCGenius/main.m).

| Devices | Profiled SoCs | Current ARMv7 build |
| --- | --- | --- |
| iPhone, iPhone 3G | Samsung S5L8900 | No; ARMv6 only |
| iPhone 3GS | Samsung S5PC100 | Yes |
| iPhone 4 | Apple A4 | Yes |
| iPhone 4S | Apple A5 | Yes |
| iPhone 5 | Apple A6 | Yes |
| iPod touch (1st, 2nd generation) | Samsung S5L8900, S5L8720 | No; ARMv6 only |
| iPod touch (3rd, 4th, 5th generation) | Samsung S5L8922, Apple A4, Apple A5 | Yes |
| iPad, iPad 2, iPad (3rd generation), iPad (4th generation), iPad mini | Apple A4, A5, A5X, A6X | Yes |

The current Theos target produces an ARMv7 binary with an iOS 4.0 deployment minimum. The original iPhone, iPhone 3G, and first two iPod touch profiles are included as reference data; running the app on those ARMv6 devices requires a separate ARMv6-capable toolchain and binary slice. Maximum supported iOS depends on the exact device. The app has been installed and checked on an iPhone 5 running iOS 6.1.4; other models still need testing on hardware.

## GitHub Actions

Pushes to `main` build the Debian package and attach it as a 30-day workflow artifact. Pushing a version tag such as `v1.0.0` builds the package and publishes a GitHub release with the `.deb` attached. The workflow uses a GitHub-hosted Linux runner with Theos's Linux cross-toolchain and downloads the iOS 9.3 SDK during the build; these build dependencies are not committed to this repository. You can also start a build from the Actions tab with **Build and release** → **Run workflow**.

## Adding a device

Add the machine identifier and device name, SoC, nominal clock, and optional image to `DeviceProfile`. Add architecture, microarchitecture, GPU, process node, and core count to `SoCSpecifications`, then add the stock OS range to `SupportedOSRange`. Include any new image in `SoCGenius_RESOURCE_FILES` in the Makefile and document its source and terms in [`ASSETS.md`](ASSETS.md).

## Assets and trademarks

The bundled processor illustrations are from Wikimedia Commons. Authors, file-page links, and license information are recorded in [`ASSETS.md`](ASSETS.md). The app icon uses a PureDarwin boot/panic screenshot; the 1024×1024 master and legacy icon-size exports are in `SoCGenius/Resources/`.

Apple and iPhone are trademarks of Apple Inc. SoC Genius is an independent project and is not affiliated with or endorsed by Apple.

## License

The source code is licensed under the [MIT License](LICENSE). This license applies to project code, not third-party images, logo components, or trademarks; see [`ASSETS.md`](ASSETS.md) for their separate terms.
