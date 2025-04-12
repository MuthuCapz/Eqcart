import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

class BannerProvider with ChangeNotifier {
  List<String> _bannerUrls = [];
  bool _isLoading = true;
  String? _error;

  List<String> get bannerUrls => _bannerUrls;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadBanners() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final ListResult result =
          await FirebaseStorage.instance.ref('banners').listAll();
      _bannerUrls =
          await Future.wait(result.items.map((ref) => ref.getDownloadURL()));
    } catch (e) {
      _error = 'Failed to load banners: ${e.toString()}';
      _bannerUrls = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
