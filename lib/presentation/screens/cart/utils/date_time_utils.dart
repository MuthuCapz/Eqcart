class DateTimeUtils {
  static bool isDeliveryNowDisabled() {
    final now = DateTime.now();
    final hour = now.hour;
    return (hour >= 13 || hour < 6); // 1 PM to 6 AM
  }
}
