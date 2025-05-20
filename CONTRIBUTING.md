# Contributing to Salat-Minimal-Reminder

Thank you for your interest in contributing to Salat-Minimal-Reminder! This document provides guidelines and instructions for contributing to the project.

## Development Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/Salat-Minimal-Reminder.git
   cd Salat-Minimal-Reminder
   ```
3. Make your changes
4. Test your changes by building the app:
   ```bash
   cd SalatMac
   ./build.sh
   open .build/debug/SalatMac.app
   ```
5. Commit your changes and submit a pull request

## Project Structure

- `SalatMac/Sources/SalatMac`: Core application code
  - `SalatApp.swift`: Main application class
  - `PrayerTimeManager.swift`: Prayer time calculation and management
  - `SettingsView.swift`: SwiftUI view for settings
  - `SettingsWindowController.swift`: Window controller for settings
  - `Extensions.swift`: Swift extensions
  - `Resources/`: Application resources (adhan sound file, etc.)
- `SalatMac/Package.swift`: Swift Package Manager configuration
- `SalatMac/build.sh`: Build script for creating the app bundle
- `SalatMac/SalatMac.entitlements`: App entitlements file

## Guidelines

1. Keep the app minimal and focused on its core functionality
2. Ensure compatibility with macOS 12.0 and later
3. Follow Swift best practices and coding conventions
4. Test your changes on different macOS versions if possible
5. Document any new features or significant changes

## Report Issues

If you find a bug or have a feature request, please open an issue on GitHub. Provide as much information as possible:

- Steps to reproduce the bug
- Expected vs. actual behavior
- Screenshots if applicable
- macOS version
- Any relevant logs or error messages

Thank you for contributing!
