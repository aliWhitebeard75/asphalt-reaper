# Asphalt Reaper

A mobile action game built with Godot 4.6.

## About

Asphalt Reaper is a fast-paced mobile game where players battle enemy vehicles on an endless road. Collect coins, upgrade your vehicle, and survive increasingly challenging waves of enemies.

## Features

- 🚗 Multiple enemy types (Grunt, Shooter, Speeder, Tank, Kamikaze, Boss)
- 💰 Coin collection and upgrade system
- 🎮 Touch controls optimized for mobile
- 🛠️ Garage system for vehicle customization
- 🎯 Perk system with upgradeable abilities
- 🎵 Background music and sound effects
- 📱 Android export ready
- 📢 Adivery ad integration for monetization

## Tech Stack

- **Engine:** Godot 4.6
- **Target Platform:** Mobile (Android)
- **Language:** GDScript
- **Ad Network:** Adivery

## Project Structure

```
asphalt-reaper-(4.6)/
├── addons/          # Adivery plugin
├── android/         # Android build configuration
├── assets/          # Game assets (sprites, sounds, etc.)
├── resources/       # Godot resource files
├── scenes/          # Game scenes (.tscn)
└── scripts/         # GDScript files
```

## Getting Started

### Prerequisites

- Godot 4.6 or later
- For Android builds: Android SDK configured in Godot

### Running the Project

1. Clone the repository:
   ```bash
   git clone https://github.com/aliWhitebeard75/asphalt-reaper.git
   ```

2. Open the project in Godot 4.6

3. Run the project (F5) or open `scenes/MainMenu.tscn`

### Building for Android

1. Configure Android build settings in Godot
2. Set up Adivery plugin with your app ID
3. Export using the Android export preset

## Game Systems

- **Player:** Controllable vehicle with health and shooting mechanics
- **Enemies:** Various enemy types with unique behaviors
- **Coins:** Collectible currency for upgrades
- **Perks:** In-game power-ups and permanent upgrades
- **Shop:** Purchase vehicle upgrades and customizations
- **Garage:** Manage vehicle collection
- **GameState:** Persistent save/load system

## License

All rights reserved.

## Contact

Developer: NoMore Games Studio
GitHub: [@aliWhitebeard75](https://github.com/aliWhitebeard75)
