# Petanca 🎯

> A native iOS Petanque game with official rules, physics-driven throws and a polished, animated interface.

[![Report Bug](https://img.shields.io/badge/Report-Bug-red)](https://github.com/VidiPT89/iPetanque/issues)
[![Request Feature](https://img.shields.io/badge/Request-Feature-blue)](https://github.com/VidiPT89/iPetanque/issues)

## ✨ Features

- ✅ Official Petanque rules (singles, doubles, triples)
- ✅ Animated SpriteKit field with rolling, arcing throws
- ✅ AI opponent with 3 difficulty levels
- ✅ Automatic scoring per official "mene" rules, first to 13 points
- ✅ Bilingual: Portuguese (PT-PT) and English
- ✅ Dark mode, Light mode and System mode
- ✅ Animated splash screen with developer credits
- ✅ Sound effects and haptic feedback

## 🛠️ Tech Stack

| Category | Technology |
|----------|------------|
| Language | Swift 5.9 |
| UI | SwiftUI |
| Graphics | SpriteKit |
| Architecture | MVVM |
| Audio | AVFoundation |
| Min. iOS | 16.0 |

## 🚀 Quick Start

### Prerequisites

- macOS with Xcode 15+
- iOS 16+ Simulator or device

### Installation

```bash
git clone https://github.com/VidiPT89/iPetanque.git
cd iPetanque
open PetancaGame.xcodeproj
```

Build and run (`⌘R`) on the simulator or a connected device.

> The Xcode project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen) from `project.yml`. If you change the file structure, regenerate it with `xcodegen generate`.

## 📖 Usage

1. Choose a game mode: Singles, Doubles or Triples
2. Pick a difficulty for the AI opponent
3. Drag on the field to aim and throw
4. First team to reach 13 points wins

## 🧪 Testing

```bash
xcodebuild -project PetancaGame.xcodeproj -scheme PetancaGame -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

## 📄 License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.

## 👨‍💻 Author

**David Arsénio Martins**

- 🌐 Website: [ividi.dev](https://ividi.dev)
- 🐙 GitHub: [@VidiPT89](https://github.com/VidiPT89)

## 🤝 Contributing

Contributions, issues and feature requests are welcome. Feel free to check the [issues page](https://github.com/VidiPT89/iPetanque/issues).

---

<p align="center">Developed by <a href="https://ividi.dev">David Arsénio Martins</a></p>
<p align="center">⭐ If you like this project, give it a star!</p>
