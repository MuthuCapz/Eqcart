import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../../utils/colors.dart';
import '../main_category_content/ShopWiseCategoriesPage.dart';
import 'search_shop_functions.dart';

class SearchShopPage extends StatefulWidget {
  @override
  _SearchShopPageState createState() => _SearchShopPageState();
}

class _SearchShopPageState extends State<SearchShopPage> {
  late SearchShopController controller;

  @override
  void initState() {
    super.initState();
    controller = SearchShopController(context, onUpdate);
    controller.init();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Search Shops', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 6),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: AppColors.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller.searchController,
                      focusNode: controller.searchFocus,
                      decoration: InputDecoration(
                        hintText: 'Search food, groceries & more...',
                        border: InputBorder.none,
                      ),
                      onChanged: (_) => controller.runSearch(),
                    ),
                  ),
                  if (controller.isSearching)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, right: 4),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (controller.searchController.text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Showing Results for "${controller.searchController.text.trim()}" this shops',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryColor,
                ),
              ),
            ),

          Expanded(
            child: controller.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryColor))
                : controller.filteredShops.isEmpty
                    ? Center(
                        child: Text(
                          'No products and shops found',
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: controller.filteredShops.length,
                        itemBuilder: (context, index) {
                          final shop = controller.filteredShops[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildShopCard(shop, context),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopCard(Map<String, dynamic> shop, BuildContext context) {
    final isActive = shop['isActive'] == true;

    return AbsorbPointer(
      absorbing: !isActive,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              if (isActive) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShopCategoriesPage(
                      shopId: shop['shop_id'],
                      shopName: shop['shop_name'],
                    ),
                  ),
                );
              }
            },
            child: Opacity(
              opacity: isActive ? 1.0 : 0.5,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.green.shade100, width: 1),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: shop['shop_logo'] ?? '',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey.shade200,
                          child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.store,
                              size: 30, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop['shop_name'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            shop['description'] ?? 'Top rated shop',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 14, color: Colors.redAccent),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  shop['city'] ?? '',
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!isActive)
            Positioned.fill(
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "Temporarily Closed",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
