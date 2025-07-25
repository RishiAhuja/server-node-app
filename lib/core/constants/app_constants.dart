class AppConstants {
  // App Info
  static const String appName = 'SSH Terminal';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String lastIpKey = 'last_ip_address';
  static const String lastUsernameKey = 'last_username';
  static const String savedConnectionsKey = 'saved_connections';
  
  // SSH Default Values
  static const int defaultSshPort = 22;
  static const int connectionTimeout = 30; // seconds
  
  // UI Constants
  static const double defaultPadding = 8.0;
  static const double smallPadding = 4.0;
  static const double largePadding = 12.0;
  static const double borderRadius = 8.0;
  static const double terminalFontSize = 12.0;
  
  // Terminal Constants
  static const String defaultTerminalPrompt = '\$';
  static const int maxTerminalHistory = 1000;
  static const String terminalWelcomeMessage = 'Welcome to SSH Terminal\nType commands to execute on remote server.\n';
  
  // Regex Patterns
  static const String ipAddressPattern = r'^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$';
  static const String hostNamePattern = r'^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$';
}
