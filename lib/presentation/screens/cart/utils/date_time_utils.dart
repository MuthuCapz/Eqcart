class DateTimeUtils {
  static bool isDeliveryNowDisabled() {
    final now = DateTime.now();
    final hour = now.hour;
    return (hour >= 19 || hour < 6); // 2 PM to 6 AM
  }
}
