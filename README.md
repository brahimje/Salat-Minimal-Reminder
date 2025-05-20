# SalatMac

A minimal macOS menu bar application that shows Islamic prayer times (Adhan times) for a specific location and plays the Adhan sound when it's time for prayer.

## Features

- Displays prayer times in the macOS menu bar
- Plays Adhan sound at prayer times
- Allows selecting your location
- Supports different prayer time calculation methods
- Minimal and lightweight design

## Requirements

- macOS 12.0 or later
- Xcode 15.0 or later (for development)
- Swift 6.0 or later (for development)

## Building the App

1. Clone or download this repository
2. Navigate to the project directory in Terminal
3. Run the build script:

```bash
cd SalatMac
swift build       # Build the executable
./build.sh        # Create the app bundle (debug build)
```

4. Once the build is complete, you can run the app by opening the generated app bundle:

```bash
open .build/debug/SalatMac.app
```

### Creating a Release Build

To create a release build for distribution:

```bash
./build.sh release  # Creates a release build
```

The release build will have optimizations enabled for better performance. This will create:
- A distributable app bundle at `.build/release/SalatMac.app`
- A ZIP archive in the `dist` directory named `SalatMac-YYYYMMDD.zip`
- A DMG file in the `dist` directory named `SalatMac-YYYYMMDD.dmg`

Users can download the DMG file from the releases page, double-click to mount it, and drag the app to their Applications folder.

### Publishing to GitHub

If you want to push your changes to GitHub:

```bash
git add .
git commit -m "Your commit message"
git push origin main  # Or the appropriate branch
```

To create a new release with the built DMG file:
1. Push your changes to GitHub
2. Go to your GitHub repository page
3. Click on "Releases" in the right sidebar
4. Click "Create a new release"
5. Upload the DMG file from the `dist` directory

## Troubleshooting

If you encounter any issues:

1. **Menu bar icon doesn't appear**: Make sure no other instances of the app are running. You can check with `ps aux | grep SalatMac` and kill any existing instances.
2. **Prayer times not showing**: Open settings and verify your location is properly set.
3. **No adhan sound**: Check that the "Play Adhan Sound" option is enabled in settings, and verify that the sound file exists in the Resources directory.
4. **"The application cannot be opened because its executable is missing"**: This could happen if the build process didn't complete correctly. Try running `./build.sh` again to ensure the app bundle is properly created.
5. **Build errors**: Make sure you have the latest Xcode and Swift version installed.

## License

This project is open source and available under the MIT License.
