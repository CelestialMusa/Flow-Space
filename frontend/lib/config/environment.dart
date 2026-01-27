import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/foundation.dart' show kIsWeb;

class Environment {
  static String get apiBaseUrl => kIsWeb
      ? 'https://flow-space.onrender.com/api/v1'
      : 'https://flow-space.onrender.com/api/v1';
  static const int apiTimeout = 30000;
}