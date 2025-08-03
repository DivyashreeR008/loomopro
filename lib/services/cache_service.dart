
import 'package:loomopro/models/artisan_model.dart';

class CacheService {
  // A simple in-memory cache for artisan profiles.
  // The key is the artisan's UID.
  static final Map<String, Artisan> _artisanCache = {};

  Artisan? getArtisan(String uid) {
    return _artisanCache[uid];
  }

  void setArtisan(Artisan artisan) {
    _artisanCache[artisan.uid] = artisan;
  }

  void clear() {
    _artisanCache.clear();
  }
}
