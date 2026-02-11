import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class PortsUtils {
  static final DatabaseHelper _dbHelper = DatabaseHelper();

  // Get all ports (default + custom)
  static Future<List<String>> getAllPorts() async {
    try {
      return await _dbHelper.getAllPorts();
    } catch (e) {
      print('Error getting all ports: $e');
      return [];
    }
  }

  // Get only custom ports
  static Future<List<Map<String, dynamic>>> getCustomPorts() async {
    try {
      return await _dbHelper.getOnlyCustomPorts();
    } catch (e) {
      print('Error getting custom ports: $e');
      return [];
    }
  }

  // Get default ports
  static Future<List<Map<String, dynamic>>> getDefaultPorts() async {
    try {
      return await _dbHelper.getDefaultPorts();
    } catch (e) {
      print('Error getting default ports: $e');
      return [];
    }
  }

  // Check if port exists
  static Future<bool> portExists(String portName) async {
    try {
      return await _dbHelper.checkPortExists(portName);
    } catch (e) {
      print('Error checking port: $e');
      return false;
    }
  }

  // Add custom port
  static Future<int> addCustomPort(String portName) async {
    try {
      final newPort = {
        'port_name': portName,
        'is_custom': 1,
        'created_at': DateTime.now().toIso8601String(),
      };
      return await _dbHelper.addCustomPort(newPort);
    } catch (e) {
      print('Error adding custom port: $e');
      return 0;
    }
  }

  // Delete custom port
  static Future<int> deleteCustomPort(int portId) async {
    try {
      return await _dbHelper.deleteCustomPort(portId);
    } catch (e) {
      print('Error deleting custom port: $e');
      return 0;
    }
  }

  // Get port statistics
  static Future<Map<String, dynamic>> getPortStatistics() async {
    try {
      final allPorts = await getAllPorts();
      final customPorts = await getCustomPorts();
      final defaultPorts = await getDefaultPorts();

      return {
        'total': allPorts.length,
        'custom': customPorts.length,
        'default': defaultPorts.length,
      };
    } catch (e) {
      print('Error getting port statistics: $e');
      return {'total': 0, 'custom': 0, 'default': 0};
    }
  }

  // Port color based on name (consistent across the app)
  static Color getPortColor(String portName) {
    final colors = [
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.red.shade600,
      Colors.teal.shade600,
      Colors.indigo.shade600,
      Colors.pink.shade600,
    ];

    // Generate a consistent hash based on port name
    int hash = 0;
    for (int i = 0; i < portName.length; i++) {
      hash = portName.codeUnitAt(i) + ((hash << 5) - hash);
    }

    final index = hash.abs() % colors.length;
    return colors[index];
  }

  // Get port icon
  static IconData getPortIcon(String portName) {
    // You can customize icons based on port names
    if (portName.toLowerCase().contains('island') || portName.toLowerCase().contains('port')) {
      return Icons.anchor;
    } else if (portName.toLowerCase().contains('beach')) {
      return Icons.beach_access;
    } else {
      return Icons.location_on;
    }
  }
}