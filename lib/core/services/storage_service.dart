import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _preferences;

  static Future<StorageService> getInstance() async {
    _instance ??= StorageService();
    _preferences ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // Save last IP address
  Future<bool> saveLastIp(String ip) async {
    try {
      return await _preferences!.setString(AppConstants.lastIpKey, ip);
    } catch (e) {
      return false;
    }
  }

  // Get last IP address
  String? getLastIp() {
    try {
      return _preferences!.getString(AppConstants.lastIpKey);
    } catch (e) {
      return null;
    }
  }

  // Save last username
  Future<bool> saveLastUsername(String username) async {
    try {
      return await _preferences!.setString(AppConstants.lastUsernameKey, username);
    } catch (e) {
      return false;
    }
  }

  // Get last username
  String? getLastUsername() {
    try {
      return _preferences!.getString(AppConstants.lastUsernameKey);
    } catch (e) {
      return null;
    }
  }

  // Save connection details
  Future<bool> saveConnection(Map<String, dynamic> connection) async {
    try {
      List<String> connections = getSavedConnections();
      String connectionJson = jsonEncode(connection);
      
      // Remove if already exists (to avoid duplicates)
      connections.removeWhere((conn) {
        Map<String, dynamic> connMap = jsonDecode(conn);
        return connMap['ip'] == connection['ip'] && 
               connMap['username'] == connection['username'];
      });
      
      // Add to beginning of list
      connections.insert(0, connectionJson);
      
      // Keep only last 10 connections
      if (connections.length > 10) {
        connections = connections.take(10).toList();
      }
      
      return await _preferences!.setStringList(AppConstants.savedConnectionsKey, connections);
    } catch (e) {
      return false;
    }
  }

  // Get saved connections
  List<String> getSavedConnections() {
    try {
      return _preferences!.getStringList(AppConstants.savedConnectionsKey) ?? [];
    } catch (e) {
      return [];
    }
  }

  // Get saved connections as maps
  List<Map<String, dynamic>> getSavedConnectionsAsMap() {
    try {
      List<String> connections = getSavedConnections();
      return connections.map((conn) => jsonDecode(conn) as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  // Remove a saved connection
  Future<bool> removeConnection(String ip, String username) async {
    try {
      List<String> connections = getSavedConnections();
      connections.removeWhere((conn) {
        Map<String, dynamic> connMap = jsonDecode(conn);
        return connMap['ip'] == ip && connMap['username'] == username;
      });
      return await _preferences!.setStringList(AppConstants.savedConnectionsKey, connections);
    } catch (e) {
      return false;
    }
  }

  // Clear all saved connections
  Future<bool> clearAllConnections() async {
    try {
      return await _preferences!.remove(AppConstants.savedConnectionsKey);
    } catch (e) {
      return false;
    }
  }

  // Clear all stored data
  Future<bool> clearAll() async {
    try {
      return await _preferences!.clear();
    } catch (e) {
      return false;
    }
  }

  // Check if key exists
  bool hasKey(String key) {
    try {
      return _preferences!.containsKey(key);
    } catch (e) {
      return false;
    }
  }

  // Save generic string
  Future<bool> saveString(String key, String value) async {
    try {
      return await _preferences!.setString(key, value);
    } catch (e) {
      return false;
    }
  }

  // Get generic string
  String? getString(String key) {
    try {
      return _preferences!.getString(key);
    } catch (e) {
      return null;
    }
  }

  // Save generic boolean
  Future<bool> saveBool(String key, bool value) async {
    try {
      return await _preferences!.setBool(key, value);
    } catch (e) {
      return false;
    }
  }

  // Get generic boolean
  bool? getBool(String key) {
    try {
      return _preferences!.getBool(key);
    } catch (e) {
      return null;
    }
  }

  // Save generic int
  Future<bool> saveInt(String key, int value) async {
    try {
      return await _preferences!.setInt(key, value);
    } catch (e) {
      return false;
    }
  }

  // Get generic int
  int? getInt(String key) {
    try {
      return _preferences!.getInt(key);
    } catch (e) {
      return null;
    }
  }
}
