class DateTimeUtils {
  static bool isDeliveryNowDisabled() {
    final now = DateTime.now();
    final hour = now.hour;
    return (hour >= 14 || hour < 6); // 1 PM to 6 AM
  }
}
