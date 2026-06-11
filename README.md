<div align="center">
  <img src="lib/assets/icon.png" alt="GoodTime Logo" width="120" style="margin-bottom: 20px;"/>
  <h1>GoodTime Media Player</h1>
  <p><strong>A beautiful, Netflix-inspired desktop media player specifically designed for organizing, managing, and watching your offline downloaded lectures, courses, and educational content.</strong></p>
  <p>
    <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
    <img src="https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white" alt="Windows" />
    <img src="https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge" alt="License" />
  </p>
</div>

<br/>

With an emphasis on a premium, cinematic user experience, GoodTime transforms disorganized folders of downloaded videos into a sleek, professional streaming-platform-like interface—completely offline.

## ✨ Features

- **Netflix-Inspired UI:** A cinematic, premium interface featuring dynamic gradients, smooth hover effects, royal color palettes, and auto-generated dynamic thumbnails.
- **Smart Folder Scanning:** Simply point the application to your root directory containing your downloaded courses. GoodTime automatically parses the folder structure and neatly organizes everything into Courses, Modules, and Episodes.
- **Intelligent "Continue Watching":** Automatically tracks your exact watch progress and position. The home screen presents a dynamic "Continue Watching" section that lets you resume right where you left off.
- **Autoplay & Binge-Watching:** Seamlessly jumps to the next lecture—even across different modules—once the current episode finishes.
- **Adjustable Playback Speed:** Essential for lectures and educational content; easily adjust playback speeds (0.5x, 0.75x, 1.0x, 1.25x, 1.5x, 2.0x) on the fly.
- **Custom Window Controls:** A sleek, borderless, frameless window experience with custom minimize, maximize, and close controls built seamlessly into the UI.
- **100% Offline First:** Built entirely for local media consumption. No internet connection required. All watch history and metadata are securely stored locally on your machine.

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your system.
- Windows Desktop development requirements (Visual Studio with C++ workload).

### Installation & Build

1. Clone this repository to your local machine.
2. Navigate to the project directory and fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application in development mode:
   ```bash
   flutter run -d windows
   ```
4. To build the final release executable:
   ```bash
   flutter build windows --release
   ```
   The generated executable will be located in `build/windows/x64/runner/Release/playit.exe` (or `goodtime.exe` depending on your executable name configuration).

## 🛠 Built With

- **[Flutter](https://flutter.dev/)** - UI Toolkit for crafting natively compiled applications.
- **[Riverpod](https://riverpod.dev/)** - Reactive caching and data-binding framework for state management.
- **[MediaKit](https://github.com/media-kit/media-kit)** - High-performance video playback engine.
- **[Hive](https://docs.hivedb.dev/)** - Lightweight and blazing fast local NoSQL database.
- **[Window Manager](https://pub.dev/packages/window_manager)** - For custom frameless desktop window management.

## 📁 Recommended Folder Structure

To get the most out of GoodTime's automatic scanner, structure your offline downloads like this:
```text
Root Folder/
│
├── Course 1/
│   ├── Module 1/
│   │   ├── 01 - Introduction.mp4
│   │   └── 02 - Basics.mp4
│   └── Module 2/
│       └── 01 - Advanced.mp4
│
└── Course 2/
    └── Module 1/
        └── 01 - Welcome.mp4
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
