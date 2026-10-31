import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum StreetlightStatus { functional, warning, failed, offline }

extension StreetlightStatusX on StreetlightStatus {
  String get label {
    switch (this) {
      case StreetlightStatus.functional:
        return 'Reporting';
      case StreetlightStatus.warning:
        return 'Warning';
      case StreetlightStatus.failed:
        return 'Failed';
      case StreetlightStatus.offline:
        return 'Offline';
    }
  }

  Color get color {
    switch (this) {
      case StreetlightStatus.functional:
        return AppTheme.statusGreen;
      case StreetlightStatus.warning:
        return AppTheme.statusYellow;
      case StreetlightStatus.failed:
        return AppTheme.statusRed;
      case StreetlightStatus.offline:
        return Colors.grey;
    }
  }
}

class Streetlight {
  final String id; // e.g. "UNIT #47"
  final String location;
  final StreetlightStatus status;
  final int brightnessPercent; // current LED output, 0-100
  final double? energyTodayKwh;
  final bool? dark;
  final bool? ledOn;
  final bool? motionDetected;
  final String statusReason;
  final DateTime? lastObservedAt;
  final bool currentTelemetry;
  final String lastMaintenance;
  final List<String> tags; // e.g. "Low Light", "Motion Detected"

  const Streetlight({
    required this.id,
    required this.location,
    required this.status,
    required this.brightnessPercent,
    this.energyTodayKwh,
    this.dark,
    this.ledOn,
    required this.motionDetected,
    this.lastMaintenance = 'Not recorded',
    this.statusReason = '',
    this.lastObservedAt,
    this.currentTelemetry = false,
    required this.tags,
  });
}

class MonitoringAlert {
  final String title;
  final String detail;
  final StreetlightStatus status;
  final int? unitIndex;
  const MonitoringAlert(this.title, this.detail, this.status, {this.unitIndex});
}
