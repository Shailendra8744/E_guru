import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A simple Riverpod provider that holds the current ThemeMode.
/// Defaults to light. Toggle between light and dark.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
