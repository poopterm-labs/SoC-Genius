# SoC Genius

SoC Genius is a jailbreak-first hardware information app for iPhone, iPad, and iPod touch. This repository contains both the classic 32-bit release, **SoC Genius**, and the ARM64 app, **SoC Genius 64**, with an updated interface and CPU-Z-inspired theme.

Maintained by [poopterm-labs](https://github.com/poopterm-labs).

## Builds

| Build | Architecture | Deployment target | Hardware scope |
| --- | --- | --- | --- |
| Classic | ARMv7 | iOS 6.0 | 32-bit iPhone, iPod touch, and iPad.|
| SoC Genius 64 | ARM64 | iOS 7.0 | 64-bit Apple devices; profiled iPhones through iPhone 15 Pro Max (A17 Pro), and iPads through M2 |

The variants have separate bundle and Debian package identifiers, so both apps can be installed together. Their Debian packages are kept in separate directories. The 64-bit app also runs on later iOS versions, including iOS 26, subject to device and jailbreak compatibility. An iOS 18+ IPA is a future distribution target; the current build is for jailbroken devices.

## Features

SoC Genius 64:

- Identifies the model, hardware identifier, display size, pixel resolution and density, installed RAM, iOS version, and OS build.
- Shows SoC, CPU architecture and core layout, CPU core count, GPU, process node, and reported clock for profiled devices.
- Reports OpenGL ES renderer information, total and per-core CPU load, and cache or CPU-frequency values when the kernel exposes them.
- Shows installed and available memory, app resident memory, battery state, thermal state when the OS exposes it, and data-volume capacity/free space on `/var`.
- Streams three-axis accelerometer readings while the Sensors page is open.
- Displays the app version and build number in the System section.
- Includes Blue, Dark, CPU-Z Classic, Purple, Green, and Red themes. CPU-Z Classic uses a black canvas, compact rows, lavender values, and a purple active-tab underline. The selected theme is saved on the device.

The classic build retains the original interface and feature set for 32-bit hardware. Missing kernel readings are shown as unavailable. Thermal state is not a temperature reading; iOS does not expose reliable CPU temperature to this app.

The classic app has been checked on an iPad 1 running iOS 6.1.3. A community report also confirms use on an iPad mini running iOS 9.3.5 and noted that the navigation header could cover the tabs. The classic layout now keeps its tab selector below the navigation bar on iOS 7 and later.

## Device profiles

The hardware database is keyed by `hw.machine` identifiers in [`SoCGenius64/main.m`](SoCGenius64/main.m). The iPhone profiles cover A7 through A17 Pro, including iPhone 11 and iPhone 15 Pro Max. iPad profiles include the 32-bit A-series generations and ARM64 M1 and M2 models. M2 is the highest M-series profile in this release.

| Devices | Profiled SoCs | Runs in SoC Genius 64 |
| --- | --- | --- |
| iPhone 5s through iPhone 6s family | Apple A7, A8, A9 | Yes |
| iPhone 7 through iPhone X | Apple A10 Fusion, A11 Bionic | Yes |
| iPhone XR through iPhone 11 family | Apple A12, A13 Bionic | Yes |
| iPhone 12 through iPhone 13 family | Apple A14, A15 Bionic | Yes |
| iPhone 14 through iPhone 15 family | Apple A15, A16 Bionic, A17 Pro | Yes; top profiled iPhone is iPhone 15 Pro Max |
| iPad Pro (2021) and iPad Air (5th generation) | Apple M1 | Yes |
| iPad Pro (2022) and iPad Air (M2) | Apple M2 | Yes |
| iPhone, iPhone 3G/3GS, iPhone 4 through iPhone 5 | Samsung S5L8900/S5PC100, Apple A4/A5/A6 | No; use the classic 32-bit build |
| iPod touch and earlier iPads | Samsung S5L8900/S5L8720/S5L8922, Apple A4/A5/A5X/A6X | No; use the classic 32-bit build |

Unknown models still show live kernel and system information, but their device and SoC details are not yet in the profile database. Newer iPhone/iPad models can run the ARM64 binary when their OS and jailbreak support it; model-specific SoC data is limited to the profiles above.

## Build

Build SoCGenius64 with Theos:

```sh
make clean package
```

Build the classic ARMv7 package:

```sh
make package32
```

Build both packages:

```sh
make clean-all package-all
```

The package files are written to `packages/64/` and `packages/32/`. SoCGenius64 uses `arm64` and an iOS 7.0 deployment minimum. The classic target uses `armv7` and an iOS 6.0 deployment minimum, which retains support for the iPad 1 on iOS 6.1.3. For a rootless ARM64 jailbreak package, build the 64-bit target with `THEOS_PACKAGE_SCHEME=rootless`.

## Install from Cydia

SoC Genius is distributed through the [Poop Labs APT repository](https://github.com/poopterm-labs/pooplabs-apt-repo). Add this source in Cydia under **Sources → Edit → Add**:

`https://poopterm-labs.github.io/pooplabs-apt-repo/`

The default SoC Genius 64 package targets rootful ARM64 jailbreaks. Rootless ARM64 packages can be built with `THEOS_PACKAGE_SCHEME=rootless`. The classic package is `com.socgenius.app`; the ARM64 package is `com.socgenius64.app`.

## Adding a device

Add the machine identifier and device name, SoC, reported clock, chip image, and screen diagonal to `DeviceProfile`. Add architecture, CPU layout, GPU, process node, and core count to `SoCSpecifications`, then add the stock OS range to `SupportedOSRange`. Include new images in the appropriate variant's Makefile and record their source and terms in [`ASSETS.md`](ASSETS.md).

## Assets and trademarks

Processor illustrations come from Wikimedia Commons. Authors, file-page links, and license information are recorded in [`ASSETS.md`](ASSETS.md). Each app's icon assets are stored in its `Resources/` directory.

Apple and iPhone are trademarks of Apple Inc. SoC Genius is an independent project and is not affiliated with or endorsed by Apple.

## License

The source code is licensed under the [MIT License](LICENSE). This license applies to project code, not third-party images or trademarks; see [`ASSETS.md`](ASSETS.md) for their separate terms.
