import 'package:flutter/material.dart';

class AppTheme {
  // Couleurs primaires
  static const Color primaryColor = Color(0xFF1E67BE);
  static const Color primaryLightColor = Color(0xFF3F84DC);
  static const Color primaryDarkColor = Color(0xFF184E8E);
  
  // Couleurs secondaires
  static const Color secondaryColor = Color(0xFF2ECC71);
  static const Color secondaryLightColor = Color(0xFF55D98B);
  static const Color secondaryDarkColor = Color(0xFF25A85E);
  
  // Couleurs d'alerte
  static const Color alertColor = Color(0xFFE74C3C);
  static const Color warningColor = Color(0xFFF39C12);
  
  // Couleurs neutres
  static const Color textColor = Color(0xFF2C3E50);
  static const Color textSecondaryColor = Color(0xFF7F8C8D);
  static const Color borderColor = Color(0xFFBDC3C7);
  static const Color backgroundColor = Color(0xFFEAEAEA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  
  // Couleurs spécifiques aux fonctionnalités
  static const Color locationColor = Color(0xFF3498DB);
  static const Color messagesColor = Color(0xFF9B59B6);
  static const Color callsColor = Color(0xFF1ABC9C);
  static const Color mediaColor = Color(0xFFE67E22);
  static const Color emergencyColor = Color(0xFFC0392B);

  // Thème clair
  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      error: alertColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textColor,
      onError: Colors.white,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
      displayMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: textColor),
      displaySmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor),
      headlineMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
      bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: textColor),
      bodyMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: textSecondaryColor),
      bodySmall: TextStyle(fontSize: 10, fontWeight: FontWeight.normal, color: textSecondaryColor),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        elevation: 2,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: const BorderSide(color: primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        minimumSize: const Size(double.infinity, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: alertColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: Colors.white,
    ),
    cardTheme: CardTheme(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    dividerTheme: const DividerThemeData(
      thickness: 0.5,
      color: borderColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
  );
  
  // Thème sombre
  static final ThemeData darkTheme = ThemeData(
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: Color(0xFF242424),
      error: alertColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onError: Colors.white,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1A1A),
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      displayMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white),
      displaySmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
      headlineMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.white),
      bodyMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70),
      bodySmall: TextStyle(fontSize: 10, fontWeight: FontWeight.normal, color: Colors.white70),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        elevation: 2,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: const BorderSide(color: primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        minimumSize: const Size(double.infinity, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFF444444)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFF444444)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: alertColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
    ),
    cardTheme: CardTheme(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      color: const Color(0xFF2A2A2A),
    ),
    dividerTheme: const DividerThemeData(
      thickness: 0.5,
      color: Color(0xFF444444),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
  );
  
  // Obtenir le style d'un badge d'état
  static BoxDecoration getStatusPillDecoration(Color color) {
    return BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.5)),
    );
  }
  
  // Obtenir le style d'un bouton d'action
  static BoxDecoration getActionButtonDecoration() {
    return BoxDecoration(
      color: primaryLightColor.withOpacity(0.2),
      borderRadius: BorderRadius.circular(8),
    );
  }
  
  // Obtenir la couleur d'un niveau de batterie
  static Color getBatteryColor(int? batteryLevel) {
    if (batteryLevel == null) return textSecondaryColor;
    
    if (batteryLevel <= 20) {
      return alertColor;
    } else if (batteryLevel <= 40) {
      return warningColor;
    } else {
      return secondaryColor;
    }
  }
  
  // Obtenir l'icône d'un niveau de batterie
  static IconData getBatteryIcon(int? batteryLevel, bool isCharging) {
    if (isCharging) {
      return Icons.battery_charging_full;
    }
    
    if (batteryLevel == null) return Icons.battery_unknown;
    
    if (batteryLevel <= 10) {
      return Icons.battery_alert;
    } else if (batteryLevel <= 30) {
      return Icons.battery_1_bar;
    } else if (batteryLevel <= 50) {
      return Icons.battery_3_bar;
    } else if (batteryLevel <= 80) {
      return Icons.battery_5_bar;
    } else {
      return Icons.battery_full;
    }
  }
}