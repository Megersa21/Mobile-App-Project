class ApiConfig {
  ApiConfig._();

  // Android phone: use your PC's local network IP.
  // Android emulator: use http://10.0.2.2:5000/api
  // Physical phone: use your PC's current Wi-Fi IP address.
  //static const String baseUrl = 'http://192.168.137.5:5000/api';
  static const String baseUrl = 'http://localhost:5000/api';
  static const Duration requestTimeout = Duration(seconds: 20);

  static Uri endpoint(String path) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;

    return Uri.parse('$baseUrl/$normalizedPath');
  }
}
