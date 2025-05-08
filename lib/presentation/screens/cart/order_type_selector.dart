import 'package:eqcart/presentation/screens/cart/utils/date_time_utils.dart';
import 'package:flutter/material.dart';
import '../../../utils/colors.dart';

class OrderTypeSelector extends StatelessWidget {
  final String orderType;
  final List<String> dateSlots;
  final List<String> timeSlots;
  final String selectedDate;
  final String selectedTime;
  final Function(String) onOrderTypeChanged;
  final Function(String) onDateSelected;
  final Function(String) onTimeSelected;
  final bool isDeliveryNowEnabled;
  final bool isTodayEnabled;

  const OrderTypeSelector({
    super.key,
    required this.orderType,
    required this.dateSlots,
    required this.timeSlots,
    required this.selectedDate,
    required this.selectedTime,
    required this.onOrderTypeChanged,
    required this.onDateSelected,
    required this.onTimeSelected,
    required this.isDeliveryNowEnabled,
    required this.isTodayEnabled,
  });

  bool _isDeliveryNowDisabled() {
    return DateTimeUtils.isDeliveryNowDisabled();
  }

  @override
  Widget build(BuildContext context) {
    final isDeliveryNowDisabled = _isDeliveryNowDisabled();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Order Type',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildOrderTypeButton('Delivery Now',
                  isDisabled: isDeliveryNowDisabled),
              const SizedBox(width: 10),
              _buildOrderTypeButton('Schedule Order', isDisabled: false),
            ],
          ),
          if (orderType == 'Schedule Order') ...[
            const SizedBox(height: 20),
            const Text(
              'Select Delivery Date',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: dateSlots.length,
                itemBuilder: (context, index) {
                  final date = dateSlots[index];
                  final isToday = date == 'Today';
                  final isTodayDisabled = isToday && isDeliveryNowDisabled;

                  return GestureDetector(
                    onTap: (date == 'Today' && !isTodayEnabled)
                        ? null
                        : () => onDateSelected(date),
                    child: Opacity(
                      opacity: isTodayDisabled ? 0.4 : 1.0,
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selectedDate == date
                              ? AppColors.secondaryColor
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            date,
                            style: TextStyle(
                              color: (selectedDate == date)
                                  ? Colors.white
                                  : (date == 'Today' && !isTodayEnabled
                                      ? Colors.grey
                                      : Colors.black),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Delivery Time Slot',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: timeSlots.length,
                itemBuilder: (context, index) {
                  final time = timeSlots[index];
                  final isTodaySelected = selectedDate == 'Today';
                  final isTodayDisabled =
                      isTodaySelected && _isDeliveryNowDisabled();

                  final isDisabled = isTodayDisabled;
                  return GestureDetector(
                    onTap: isDisabled ? null : () => onTimeSelected(time),
                    child: Opacity(
                      opacity: isDisabled ? 0.4 : 1.0,
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selectedTime == time
                              ? AppColors.secondaryColor
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            time,
                            style: TextStyle(
                              color: selectedTime == time
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderTypeButton(String type, {required bool isDisabled}) {
    final isSelected = orderType == type;

    return Expanded(
      child: ElevatedButton(
        onPressed: isDisabled ? null : () => onOrderTypeChanged(type),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? AppColors.secondaryColor : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(
          type,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDisabled ? Colors.grey : null, // Grey out text if disabled
          ),
        ),
      ),
    );
  }
}
