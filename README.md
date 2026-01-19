# SpookyID Multipass - Source Only

This is the **source code only** repository for the Multipass mobile app.

## What's Included
- `lib/` - Dart application source
- `pubspec.yaml` - Dependencies
- Core configuration files

## What's Excluded (for size)
- Android/iOS build scaffolding (regenerated via `flutter create`)
- Flutter SDK
- Build artifacts
- Native Rust compiled outputs

## Setup
```bash
flutter create .
flutter pub get
# Then restore android/ios platform-specific code from full repo if needed
```

## Full Repository
For the complete buildable project including platform code, see: [full multipass repo link]
