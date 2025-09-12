# Radio Sangam (Flutter)

A minimal Flutter app for streaming audio with `just_audio`.  
This README documents the **single fix** that made playback work.

## The Problem

We were seeing a mix of issues:

- Compilation errors like:
  - `Error: The method 'playEpisode' isn't defined for the type 'RadioService'.`
- At runtime, audio was flaky / not playing.
- Analyzer warnings weren’t the root cause.

## Root Cause

**The same library was imported via two different URIs**, creating two distinct types in Dart:

```dart
// ❌ Problem: two imports of the same file
import '../services/radio_service.dart'; // relative
import 'package:radiosangam_flutter/src/services/radio_service.dart'; // package
