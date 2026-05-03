/// Environment configuration for MoneyMate
/// 
/// This file defines different environment configurations
/// for development, staging, and production.

abstract class AppConfig {
  static const String apiBaseUrl = 'http://localhost:3000/api';
  static const int apiTimeout = 30000; // milliseconds
  static const bool enableDebugLogging = true;
}

class DevelopmentConfig implements AppConfig {
  @override
  String get apiBaseUrl => 'http://localhost:3000/api';
  
  @override
  int get apiTimeout => 30000;
  
  @override
  bool get enableDebugLogging => true;
}

class StagingConfig implements AppConfig {
  @override
  String get apiBaseUrl => 'https://staging-api.moneymate.com/api';
  
  @override
  int get apiTimeout => 30000;
  
  @override
  bool get enableDebugLogging => true;
}

class ProductionConfig implements AppConfig {
  @override
  String get apiBaseUrl => 'https://api.moneymate.com/api';
  
  @override
  int get apiTimeout => 30000;
  
  @override
  bool get enableDebugLogging => false;
}

/// Get the current environment configuration
/// 
/// Change this based on your build configuration
AppConfig get currentConfig {
  // TODO: Use build flags or environment variables to determine the environment
  // For now, defaulting to development
  return DevelopmentConfig();
}
