import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DateTimeUtils {
  static Stream<bool> isDeliveryNowDisabledStream() {
    return FirebaseFirestore.instance
        .collection('deliver_disble_time')
        .doc('delivery_time')
        .snapshots()
        .map((doc) {
      final data = doc.data();
      if (data == null) return false;

      final now = TimeOfDay.now();
      final start = _parseTimeOfDay(data['start_time']);
      final end = _parseTimeOfDay(data['end_time']);

      return _isTimeWithinRange(now, start, end);
    });
  }

  static TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static bool _isTimeWithinRange(
      TimeOfDay now, TimeOfDay start, TimeOfDay end) {
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes < endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    }
  }
}
