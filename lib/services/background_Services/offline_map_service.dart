// lib/services/offline_map_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';

/// Single source of truth for all offline-map operations.
///
/// Every map in the app MUST use [OfflineMapService.buildTileLayer].
/// This guarantees:
///   1. The FMTC backend is initialized exactly once (idempotent).
///   2. The correct store name is used everywhere.
///   3. If the DB is corrupted, it self-heals (deletes + recreates).
///   4. Online + offline modes both work through the same code path.
class OfflineMapService {
  /// ⚠️ MUST be identical everywhere in the app.
  static const String storeName = 'fishing_app_cache';

  /// Hardcoded to match everywhere.
  static const String tileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String userAgent =
      'com.example.fvm_system.fishing_voyage_manag_sys';

  static final FMTCStore _store = FMTCStore(storeName);

  static bool _initialized = false;
  static bool _initFailed = false;

  // ─────────────────────────────────────────────────────────────
  //  PUBLIC API — call init() once in main(), use buildTileLayer()
  //  everywhere else.
  // ─────────────────────────────────────────────────────────────

  /// Initialize FMTC. Safe to call multiple times.
  /// Self-heals the DB if corrupted.
  static Future<void> init() async {
    if (_initialized) return;
    if (_initFailed) return;   // don't spam retries

    try {
      // 1. Backend
      await FMTCObjectBoxBackend().initialise();
      // 2. Store
      await _store.manage.create();
      _initialized = true;
      debugPrint('✅ [OfflineMap] FMTC initialized, store="$storeName"');
    } catch (e) {
      debugPrint('⚠️ [OfflineMap] Init failed: $e');

      // Self-heal: delete the corrupted cache folder, then retry ONCE.
      try {
        await _deleteCorruptedCache();
        await FMTCObjectBoxBackend().initialise();
        await _store.manage.create();
        _initialized = true;
        debugPrint('✅ [OfflineMap] FMTC re-initialized after self-heal');
      } catch (e2) {
        debugPrint('❌ [OfflineMap] Self-heal failed: $e2');
        _initFailed = true;   // give up cleanly — app still works online
      }
    }
  }

  /// The ONLY tile layer every map should use.
  /// Falls back gracefully to network if FMTC is unavailable.
  static TileLayer buildTileLayer() {
    if (_initialized && !_initFailed) {
      try {
        return TileLayer(
          urlTemplate: tileUrlTemplate,
          userAgentPackageName: userAgent,
          tileProvider: FMTCTileProvider(
            stores: {storeName: BrowseStoreStrategy.readUpdateCreate},
          ),
          // Don't throw on tile errors
          errorTileCallback: (tile, error, stackTrace) {
            debugPrint('⚠️ [OfflineMap] Tile error: $error');
          },
        );
      } catch (e) {
        debugPrint('⚠️ [OfflineMap] FMTC provider unavailable, '
            'falling back to network-only: $e');
      }
    }

    // Fallback: pure network. Still works, just no cache.
    return TileLayer(
      urlTemplate: tileUrlTemplate,
      userAgentPackageName: userAgent,
    );
  }

  /// Download the Lakshadweep region into cache.
  static Future<void> downloadLakshadweepTiles({
    required Function(double progress) onProgress,
  }) async {
    // Ensure FMTC is ready first.
    await init();
    if (!_initialized || _initFailed) {
      throw Exception('Offline map is not available on this device.');
    }

    // Cover Kerala coast + Lakshadweep
    final bounds = LatLngBounds(
      const LatLng(7.5, 71.0),   // south-west
      const LatLng(13.5, 75.5),  // north-east
    );

    await _store.manage.create();

    final region = RectangleRegion(bounds).toDownloadable(
      minZoom: 5,
      maxZoom: 16,
      options: TileLayer(
        urlTemplate: tileUrlTemplate,
        userAgentPackageName: userAgent,
      ),
    );

    final stream = _store.download.startForeground(region: region);
    await for (final progress in stream.downloadProgress) {
      onProgress(progress.percentageProgress / 100.0);
      if (progress.percentageProgress >= 100) break;
    }
  }

  /// Whether any tiles are cached.
  static Future<bool> hasDownloadedTiles() async {
    if (!_initialized || _initFailed) return false;
    try {
      final size = await _store.stats.size;
      return size > 0;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  INTERNAL — self-healing
  // ─────────────────────────────────────────────────────────────

  /// Deletes the FMTC cache folder so a fresh one can be created.
  /// Called automatically when initialization fails.
  static Future<void> _deleteCorruptedCache() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final fmtcDir = Directory('${docsDir.path}/fmtc');
      if (await fmtcDir.exists()) {
        await fmtcDir.delete(recursive: true);
        debugPrint('🗑️ [OfflineMap] Deleted corrupted FMTC folder');
      }
      // Also check support dir (some Android versions use it)
      try {
        final supportDir = await getApplicationSupportDirectory();
        final supportFmtc = Directory('${supportDir.path}/fmtc');
        if (await supportFmtc.exists()) {
          await supportFmtc.delete(recursive: true);
          debugPrint('🗑️ [OfflineMap] Deleted FMTC folder in support dir');
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('⚠️ [OfflineMap] Could not delete FMTC folder: $e');
    }
  }
}
