# 🎬 GoodTime Media Player (PlayIt)

<div align="center">
  <img src="lib/assets/favicon.png" alt="GoodTime Logo" width="120" />
</div>

<h3 align="center">A premium, Netflix-inspired desktop media player built with Flutter.</h3>

<div align="center">

  [![Flutter](https://img.shields.io/badge/Flutter-3.12-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
  [![Dart](https://img.shields.io/badge/Dart-3.0-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
  [![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)](#-download--install)
  [![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=for-the-badge)](https://makeapullrequest.com)
  
</div>

---

**GoodTime** (also known as PlayIt) is a production-ready Windows desktop application designed to provide a cinematic, immersive media viewing experience for your local files. Featuring a stunning Netflix-inspired UI, cinematic radial gradients, and minimalist controls, GoodTime makes watching your local video library feel like a premium streaming service.

## ✨ Features

- **📺 Netflix-Inspired UI**: A cinematic interface with dark mode, smooth transitions, and dynamic layouts.
- **📂 Automatic Folder Scanning**: Quickly scan and organize your local video courses, movies, and series.
- **🎞️ Advanced Video Playback**: Powered by `media_kit` for robust, hardware-accelerated playback of all major video formats.
- **⚙️ Playback Controls**: Granular control over playback speed, volume, and seamless seeking.
- **🧠 Smart Autoplay & Caching**: Seamlessly transition between episodes and remember where you left off.
- **🎨 Custom Aesthetics**: Minimalist, theme-aware controls with premium micro-animations.

## 📥 Download & Install

You can easily download and install GoodTime on your Windows machine!

1. Go to the [**Releases**](../../releases/latest) page of this repository.
2. Download the latest `goodtimes.msix` file.
3. Double-click the downloaded `.msix` file to install it on your Windows PC.
4. Launch **GoodTime** from your Start menu and enjoy!

## 🚀 How to Use

1. **Launch the App**: Open GoodTime Media Player.
2. **Add Content**: Go to the **Folders** or **Settings** section to select the directories where your videos are stored. 
3. **Scan**: Let the app scan and organize your media.
4. **Play**: Click on any video to start the cinematic player. Use the intuitive on-screen controls to adjust playback speed, volume, or skip forward/backward.

## 🛠️ Built With

* **[Flutter](https://flutter.dev/)** - UI Toolkit for building beautiful, natively compiled applications.
* **[MediaKit](https://github.com/media-kit/media-kit)** - Video & audio playback library.
* **[Riverpod](https://riverpod.dev/)** - Reactive state management framework.
* **[Hive](https://pub.dev/packages/hive)** - Lightweight and blazing fast key-value database.

## 🤝 Contributing

We love open source! Contributions are what make the open-source community such an amazing place to learn, inspire, and create. 

**GoodTime is fully open for contributions!** If you have ideas for new features, UI enhancements, or bug fixes, feel free to contribute:

1. **Fork the Project**
2. **Create your Feature Branch** (`git checkout -b feature/AmazingFeature`)
3. **Commit your Changes** (`git commit -m 'Add some AmazingFeature'`)
4. **Push to the Branch** (`git push origin feature/AmazingFeature`)
5. **Open a Pull Request**

Please make sure your code follows the existing style and that you've tested your changes.

## 💻 Development Setup

If you want to run the app locally or contribute to the code:

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.12.1 or higher)
- Windows 10/11 with Visual Studio 2022 (with "Desktop development with C++" workload) for Windows desktop support.

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/playit.git
   ```
2. Navigate to the project directory:
   ```bash
   cd playit
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run -d windows
   ```

### Building the MSIX (For Release)
If you are making a release build, run the following command to generate the `.msix` Windows installer:
```bash
flutter pub run msix:create
```
This will create an installer in `build\windows\x64\runner\Release\goodtimes.msix`.

## 📜 License

Distributed under the MIT License. See `LICENSE` for more information.

---
<div align="center">
  <b>Made with ❤️ for beautiful UI and seamless playback.</b>
</div>
