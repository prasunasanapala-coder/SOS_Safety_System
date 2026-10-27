import 'package:flutter/foundation.dart';

import '../models/safety_tip.dart';
import '../services/local_storage_service.dart';
import '../services/tips_api_service.dart';

enum TipsStatus { idle, loading, loaded, empty, error }

/// Safety tips from the REST API, with category filter and favourites.
class TipsProvider extends ChangeNotifier {
   TipsProvider({
    required this._api,
    required LocalStorageService storage,
  })  : _storage = storage,
        _favorites = storage.favoriteTipIds;

  final TipsApiService _api;
  final LocalStorageService _storage;

  TipsStatus _status = TipsStatus.idle;
  List<SafetyTip> _tips = const [];
  Set<String> _favorites;
  String? _error;
  String? _category; // null = all categories
  bool _favoritesOnly = false;

  TipsStatus get status => _status;
  String? get error => _error;
  String? get selectedCategory => _category;
  bool get favoritesOnly => _favoritesOnly;

  List<String> get categories {
    final names = _tips.map((t) => t.category).toSet().toList()..sort();
    return names;
  }

  List<SafetyTip> get visibleTips => _tips.where((t) {
        if (_category != null && t.category != _category) return false;
        if (_favoritesOnly && !_favorites.contains(t.id)) return false;
        return true;
      }).toList();

  bool isFavorite(String id) => _favorites.contains(id);

  Future<void> load() async {
    _status = TipsStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _tips = await _api.fetchTips();
      _status = _tips.isEmpty ? TipsStatus.empty : TipsStatus.loaded;
    } on TipsApiException catch (e) {
      _tips = const [];
      _error = e.message;
      _status = TipsStatus.error;
    }
    notifyListeners();
  }

  void selectCategory(String? category) {
    _category = category;
    notifyListeners();
  }

  void setFavoritesOnly(bool value) {
    _favoritesOnly = value;
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    final updated = {..._favorites};
    if (!updated.remove(id)) updated.add(id);
    _favorites = updated;
    notifyListeners();
    await _storage.setFavoriteTipIds(updated);
  }

  /// Called after "clear local data" in Settings.
  void resetLocalState() {
    _favorites = {};
    _category = null;
    _favoritesOnly = false;
    notifyListeners();
  }
}