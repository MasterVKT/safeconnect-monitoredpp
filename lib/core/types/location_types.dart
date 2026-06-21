// Location data types and structures for monitoring app

import 'dart:math' as math;

enum LocationProvider {
  gps,
  network,
  passive,
  fused,
}

enum ActivityType {
  unknown,
  still,
  walking,
  running,
  driving,
  cycling,
  onFoot,
  inVehicle,
  tilting,
}

enum LocationAccuracyLevel {
  lowest,
  low,
  medium,
  high,
  best,
  navigation,
}

class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? altitude;
  final double? altitudeAccuracy;
  final double? speed;
  final double? speedAccuracy;
  final double? heading;
  final double? headingAccuracy;
  final DateTime timestamp;
  final LocationProvider provider;
  final ActivityType activityType;
  final int? batteryLevel;
  final String deviceId;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.altitude,
    this.altitudeAccuracy,
    this.speed,
    this.speedAccuracy,
    this.heading,
    this.headingAccuracy,
    required this.timestamp,
    required this.provider,
    this.activityType = ActivityType.unknown,
    this.batteryLevel,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'altitude_accuracy': altitudeAccuracy,
      'speed': speed,
      'speed_accuracy': speedAccuracy,
      'heading': heading,
      'heading_accuracy': headingAccuracy,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'provider': provider.name,
      'activity_type': activityType.name,
      'battery_level': batteryLevel,
      'device_id': deviceId,
    };
  }

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      accuracy: json['accuracy'] as double,
      altitude: json['altitude'] as double?,
      altitudeAccuracy: json['altitude_accuracy'] as double?,
      speed: json['speed'] as double?,
      speedAccuracy: json['speed_accuracy'] as double?,
      heading: json['heading'] as double?,
      headingAccuracy: json['heading_accuracy'] as double?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      provider: LocationProvider.values.firstWhere(
        (e) => e.name == json['provider'],
        orElse: () => LocationProvider.gps,
      ),
      activityType: ActivityType.values.firstWhere(
        (e) => e.name == json['activity_type'],
        orElse: () => ActivityType.unknown,
      ),
      batteryLevel: json['battery_level'] as int?,
      deviceId: json['device_id'] as String,
    );
  }

  // Calculate distance between two locations in meters
  double distanceTo(LocationData other) {
    const double earthRadius = 6371000; // Earth radius in meters

    final lat1Rad = latitude * (3.14159 / 180);
    final lat2Rad = other.latitude * (3.14159 / 180);
    final deltaLatRad = (other.latitude - latitude) * (3.14159 / 180);
    final deltaLngRad = (other.longitude - longitude) * (3.14159 / 180);

    final a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) *
            math.sin(deltaLngRad / 2);
    final c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }
}

class LocationEvent {
  final String eventType;
  final LocationData locationData;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const LocationEvent({
    required this.eventType,
    required this.locationData,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'event_type': eventType,
      'location_data': locationData.toJson(),
      'timestamp': timestamp.toUtc().toIso8601String(),
      'metadata': metadata,
    };
  }
}

class GeofenceArea {
  final String id;
  final String name;
  final double centerLatitude;
  final double centerLongitude;
  final double radius; // in meters
  final bool isActive;

  const GeofenceArea({
    required this.id,
    required this.name,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.radius,
    this.isActive = true,
  });

  bool contains(LocationData location) {
    final center = LocationData(
      latitude: centerLatitude,
      longitude: centerLongitude,
      accuracy: 0,
      timestamp: DateTime.now(),
      provider: LocationProvider.gps,
      deviceId: location.deviceId,
    );

    return center.distanceTo(location) <= radius;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'center_latitude': centerLatitude,
      'center_longitude': centerLongitude,
      'radius': radius,
      'is_active': isActive,
    };
  }
}
