import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  // valori curente (cu default-uri)
  static String backendHost = "10.0.7.26:5001";
  static double threshold = 27.0;
  static int refreshSeconds = 3;
  static bool darkMode = true;

  // URL-urile construite din host
  static String get temperatureUrl => "http://$backendHost/temperature";
  static String get historyUrl => "http://$backendHost/history";

  // incarca setarile salvate la pornirea aplicatiei
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    backendHost = prefs.getString("backendHost") ?? backendHost;
    threshold = prefs.getDouble("threshold") ?? threshold;
    refreshSeconds = prefs.getInt("refreshSeconds") ?? refreshSeconds;
    darkMode = prefs.getBool("darkMode") ?? darkMode;
  }

  // salveaza setarile curente
  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("backendHost", backendHost);
    await prefs.setDouble("threshold", threshold);
    await prefs.setInt("refreshSeconds", refreshSeconds);
    await prefs.setBool("darkMode", darkMode);
  }
}
