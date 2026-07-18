import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthHelper {
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user_data');
    if (raw == null) return null;
    try {
      return json.decode(raw) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  static Future<String> getCurrentRole() async {
    final user = await getCurrentUser();
    if (user == null) return '';
    return (user['role_user'] ?? '').toString().toLowerCase();
  }

  static Future<bool> isAdmin() async => (await getCurrentRole()) == 'admin';
  static Future<bool> isStaff() async => (await getCurrentRole()) == 'staff';
  static Future<bool> isTeknisi() async => (await getCurrentRole()) == 'teknisi';

  // Staff & admin boleh kelola lori (tambah/hapus/edit). Teknisi hanya input + inspeksi.
  static Future<bool> canManageLori() async {
    final r = await getCurrentRole();
    return r == 'admin' || r == 'staff';
  }

  // Hanya admin yang kelola factory & station.
  static Future<bool> canManageFactoryStation() async => await isAdmin();

  // Semua role login boleh menambah lori (teknisi utama input lori + inspeksi).
  static Future<bool> canAddLori() async {
    final r = await getCurrentRole();
    return r == 'admin' || r == 'staff' || r == 'teknisi';
  }

  // Hapus lori: staff & admin. Teknisi tidak.
  static Future<bool> canDeleteLori() async {
    final r = await getCurrentRole();
    return r == 'admin' || r == 'staff';
  }

  // Edit inspeksi: keistimewaan staff (+admin). Teknisi tidak boleh edit.
  static Future<bool> canEditInspection() async {
    final r = await getCurrentRole();
    return r == 'admin' || r == 'staff';
  }
}
