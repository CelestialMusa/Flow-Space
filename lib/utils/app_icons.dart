import 'package:flutter/material.dart';

class AppIcons {
  // Navigation icons
  static const IconData dashboard = Icons.dashboard;
  static const IconData projects = Icons.folder;
  static const IconData deliverables = Icons.assignment;
  static const IconData sprints = Icons.timer;
  static const IconData reports = Icons.description;
  static const IconData users = Icons.people;
  static const IconData settings = Icons.settings;
  static const IconData logout = Icons.logout;
  
  // Action icons
  static const IconData add = Icons.add;
  static const IconData edit = Icons.edit;
  static const IconData delete = Icons.delete;
  static const IconData save = Icons.save;
  static const IconData cancel = Icons.cancel;
  static const IconData search = Icons.search;
  static const IconData filter = Icons.filter;
  static const IconData refresh = Icons.refresh;
  
  // Status icons
  static const IconData success = Icons.check_circle;
  static const IconData warning = Icons.warning;
  static const IconData error = Icons.error;
  static const IconData info = Icons.info;
  
  // File icons
  static const IconData file = Icons.insert_drive_file;
  static const IconData folder = Icons.folder;
  static const IconData upload = Icons.upload;
  static const IconData download = Icons.download;
  
  // User icons
  static const IconData person = Icons.person;
  static const IconData group = Icons.group;
  static const IconData admin = Icons.admin_panel_settings;
  static const IconData client = Icons.business;
  
  // System icons
  static const IconData system = Icons.computer;
  static const IconData database = Icons.storage;
  static const IconData network = Icons.wifi;
  static const IconData security = Icons.security;
  
  // Helper method to get icon widget
  static Widget getIconWidget(dynamic icon, {double? size, Color? color, IconData? fallbackIcon, bool? isActive}) {
    IconData iconData;
    
    if (icon is IconData) {
      iconData = icon;
    } else if (icon is String) {
      // Map string names to IconData
      iconData = _getIconFromString(icon);
    } else {
      iconData = fallbackIcon ?? Icons.help;
    }
    
    return Icon(
      iconData,
      size: size,
      color: color ?? (isActive == true ? Colors.blue : Colors.grey),
    );
  }
  
  // Helper method to convert string to IconData
  static IconData _getIconFromString(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'dashboard':
        return dashboard;
      case 'projects':
        return projects;
      case 'deliverables':
        return deliverables;
      case 'sprints':
        return sprints;
      case 'reports':
        return reports;
      case 'users':
        return users;
      case 'settings':
        return settings;
      case 'logout':
        return logout;
      case 'add':
        return add;
      case 'edit':
        return edit;
      case 'delete':
        return delete;
      case 'save':
        return save;
      case 'cancel':
        return cancel;
      case 'search':
        return search;
      case 'filter':
        return filter;
      case 'refresh':
        return refresh;
      case 'success':
        return success;
      case 'warning':
        return warning;
      case 'error':
        return error;
      case 'info':
        return info;
      case 'file':
        return file;
      case 'folder':
        return folder;
      case 'upload':
        return upload;
      case 'download':
        return download;
      case 'person':
        return person;
      case 'group':
        return group;
      case 'admin':
        return admin;
      case 'client':
        return client;
      case 'system':
        return system;
      case 'database':
        return database;
      case 'network':
        return network;
      case 'security':
        return security;
      default:
        return Icons.help;
    }
  }
}
