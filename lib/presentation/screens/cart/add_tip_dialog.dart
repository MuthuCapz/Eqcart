import 'package:flutter/material.dart';

import '../../../utils/colors.dart';

class AddTipDialog extends StatefulWidget {
  final double initialTip;

  const AddTipDialog({super.key, this.initialTip = 0});

  @override
  State<AddTipDialog> createState() => _AddTipDialogState();
}

class _AddTipDialogState extends State<AddTipDialog> {
  int? selectedTip;
  final TextEditingController _customTipController = TextEditingController();

  void _selectTip(int amount) {
    setState(() {
      selectedTip = amount;
      _customTipController.clear();
    });
  }

  void _selectOther() {
    setState(() {
      selectedTip = null;
    });
  }

  String _getButtonText() {
    if (selectedTip == 0) {
      return 'Add Tip';
    } else if (selectedTip != null) {
      return '₹${selectedTip!}';
    } else if (_customTipController.text.isNotEmpty) {
      final value = double.tryParse(_customTipController.text) ?? 0;
      if (value > 0) {
        return '₹${value.toStringAsFixed(0)}';
      } else {
        return 'Add Tip';
      }
    } else {
      return 'Add Tip';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Say Thanks with a Tip',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'A small tip, a big gesture! Show appreciation for your delivery partner.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primaryColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                _NoTipButton(
                  isSelected: selectedTip == 0,
                  onTap: () => _selectTip(0),
                ),
                _TipAmountButton(
                  amount: 10,
                  isSelected: selectedTip == 10,
                  onTap: () => _selectTip(10),
                ),
                _TipAmountButton(
                  amount: 20,
                  isMostTipped: true,
                  isSelected: selectedTip == 20,
                  onTap: () => _selectTip(20),
                ),
                _TipAmountButton(
                  amount: 30,
                  isSelected: selectedTip == 30,
                  onTap: () => _selectTip(30),
                ),
                _OtherTipButton(
                  isSelected: selectedTip == null,
                  onTap: _selectOther,
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _customTipController,
              decoration: InputDecoration(
                hintText: 'Enter custom tip amount (₹)',
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.secondaryColor, width: 2),
                ),
              ),
              keyboardType: TextInputType.number,
              onTap: _selectOther,
              onChanged: (_) {
                setState(() {}); // update button text live
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  double finalTip = 0.0;
                  if (selectedTip != null) {
                    finalTip = selectedTip!.toDouble();
                  } else if (_customTipController.text.isNotEmpty) {
                    finalTip =
                        double.tryParse(_customTipController.text) ?? 0.0;
                  }
                  Navigator.pop(context, finalTip);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedTip == 0
                      ? Colors.grey[300]
                      : AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  _getButtonText(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: selectedTip == 0 ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoTipButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _NoTipButton({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[300] : Colors.white,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No Tip',
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _TipAmountButton extends StatelessWidget {
  final int amount;
  final bool isMostTipped;
  final bool isSelected;
  final VoidCallback onTap;

  const _TipAmountButton({
    required this.amount,
    this.isMostTipped = false,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 72,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryColor : Colors.white,
              border: Border.all(color: AppColors.primaryColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '₹$amount',
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        if (isMostTipped) const SizedBox(height: 4),
        if (isMostTipped)
          Text(
            'Most Tipped',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.secondaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _OtherTipButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _OtherTipButton({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.white,
          border: Border.all(color: AppColors.primaryColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Other',
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
