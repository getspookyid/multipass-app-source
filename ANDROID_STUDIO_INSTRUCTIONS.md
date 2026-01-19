# Debugging Multipass in Android Studio

Since we've repaired the Gradle configuration (`settings.gradle.kts` and `app/build.gradle.kts`), you can now use Android Studio for a much better debugging experience.

## Prerequisites
Ensure the `android/settings.gradle.kts` file is clean (I have just fixed it for you).

## Steps

1.  **Open Android Studio**.
2.  **Select "Open"** from the welcome screen or **File > Open**.
3.  **Navigate to**: `C:\spookyos\SpookyID\Multipass\android`
    *   **IMPORTANT**: Select the `android` directory, NOT the root `Multipass` directory. This is crucial for Android Studio to recognize the Gradle project structure.
4.  **Wait for Gradle Sync**:
    *   Android Studio will start "Importing Project" and "Syncing".
    *   Watch the **Build** tab at the bottom.
    *   If it asks to "Trust Project", say **Yes**.
5.  **Verify Rust Integration**:
    *   In the **Project** view (left pane), verify you see a module named `rust_builder` (or it might be nested under `android`).
    *   This confirms the native bridge hooks are active.
6.  **Run the App**:
    *   In the top toolbar, ensure the run configuration defaults to `app`.
    *   Select your device (`motorola razr 2024`).
    *   Click the green **Run** (Play) icon or **Debug** (Bug) icon.

## Troubleshooting
*   **"Framework not found"**: If you see errors about Flutter framework, allow usage of the Flutter SDK location defined in `local.properties`.
*   **"NDK not found"**: Open `File > Project Structure > SDK Location` and ensure the NDK path matches what's used in `build.gradle` (or let Android Studio download the side-by-side version).

## Why this works now
The command-line build was failing because of a corrupted `settings.gradle.kts` file (nested plugins blocks) which prevented the `rust_builder` project from being included. I completely rewrote that file to the correct standard configuration. The Flutter build tools should now work, and Android Studio will pick up this correct configuration.
