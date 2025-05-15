import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import 'addresses_page/address_page.dart';
import 'wellat_page/wallet_page.dart';

class SettingsPage extends StatelessWidget {
  final List<_SettingItem> items = [
    _SettingItem(
      icon: Icons.account_balance_wallet,
      iconBg: Color(0xFFBDF4C0),
      title: 'Wallet',
      onTap: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => WalletPage()),
      ),
    ),
    _SettingItem(
      icon: Icons.location_on_outlined,
      iconBg: Color(0xFFD5E8C9),
      title: 'Addresses',
      onTap: (context) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddressPage(userId: currentUserId),
          ),
        );
      },
    ),
    _SettingItem(
      icon: Icons.delete_forever_outlined,
      iconBg: Color(0xFFF8D7DA),
      title: 'Delete Account',
      onTap: (context) {
        // TODO: Confirm and delete account
      },
    ),
    _SettingItem(
      icon: Icons.logout,
      iconBg: Color(0xFFE0ECF8),
      title: 'Logout',
      onTap: (context) {
        // TODO: Logout logic
      },
    ),
  ];

  static get currentUserId => FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) =>
            _buildSettingCard(context, items[index]),
      ),
    );
  }

  Widget _buildSettingCard(BuildContext context, _SettingItem item) {
    return InkWell(
      onTap: () => item.onTap(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item.iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: AppColors.primaryColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 18, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String title;
  final Color iconBg;
  final void Function(BuildContext context) onTap;

  _SettingItem({
    required this.icon,
    required this.title,
    required this.iconBg,
    required this.onTap,
  });
}
