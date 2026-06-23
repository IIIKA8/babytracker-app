import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {

  static Future<void> saveSelectedChild(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_child_id', id);
  }

  static Future<String?> getSelectedChild() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_child_id');
  }
}