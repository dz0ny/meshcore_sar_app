import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter_avif/flutter_avif.dart';

/// Compresses and resizes an image for low-bandwidth mesh transmission.
///
/// Target: ≤256×256 pixels, grayscale AVIF at aggressive quality.
/// A typical 256×256 grayscale AVIF at quality 90 is highly compressed.
/// → 7–20 fragments at 152 bytes each.
class ImageCodecService {
  static const int _normalAvifSpeed = 6;
  static const int _ultraAvifSpeed = 4;

  /// Compress [rawBytes] (any decodable format: JPEG/PNG/WebP/AVIF) to a
  /// small grayscale AVIF suitable for mesh transmission.
  ///
  /// [maxDimension] caps width and height (default 256); aspect ratio is
  /// preserved and images smaller than the cap are not upscaled.
  /// [compression]  0 = lossless, 100 = smallest/worst (libavif CQ scale).
  ///
  /// Returns `(bytes, width, height)` or null if decoding or encoding fails.
  static Future<({Uint8List bytes, int width, int height})?> compress(
    Uint8List rawBytes, {
    int maxDimension = 256,
    int compression = 90,
    bool grayscale = true,
    bool ultraMode = false,
  }) async {
    try {
      final effectiveMaxDimension = maxDimension.clamp(32, 1024);
      final effectiveCompression = ultraMode
          ? (compression + 12).clamp(10, 100)
          : compression.clamp(10, 100);
      final forceGrayscale = ultraMode ? true : grayscale;

      // 1a. Probe original dimensions (no resize).
      final probeCodec = await ui.instantiateImageCodec(rawBytes);
      final probeFrame = await probeCodec.getNextFrame();
      final srcW = probeFrame.image.width;
      final srcH = probeFrame.image.height;
      probeFrame.image.dispose();

      // 1b. Compute contain dimensions: scale down only the limiting axis so
      //     the image fits within maxDimension×maxDimension without stretching.
      int dstW = srcW;
      int dstH = srcH;
      if (srcW > effectiveMaxDimension || srcH > effectiveMaxDimension) {
        if (srcW >= srcH) {
          dstW = effectiveMaxDimension;
          dstH = (srcH * effectiveMaxDimension / srcW).round().clamp(
            1,
            effectiveMaxDimension,
          );
        } else {
          dstH = effectiveMaxDimension;
          dstW = (srcW * effectiveMaxDimension / srcH).round().clamp(
            1,
            effectiveMaxDimension,
          );
        }
      }

      // 1c. Decode at the exact contain size (single axis constrained).
      final codec = await ui.instantiateImageCodec(
        rawBytes,
        targetWidth: dstW,
        targetHeight: dstH,
        allowUpscaling: false,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final w = image.width;
      final h = image.height;

      // 2. Export RGBA pixels.
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      image.dispose();
      if (byteData == null) return null;

      // 3. Optionally convert to grayscale in-place (luminance).
      final rgba = byteData.buffer.asUint8List();
      if (forceGrayscale) {
        for (var i = 0; i < rgba.length; i += 4) {
          final lum =
              (0.299 * rgba[i] + 0.587 * rgba[i + 1] + 0.114 * rgba[i + 2])
                  .round()
                  .clamp(0, 255);
          rgba[i] = lum;
          rgba[i + 1] = lum;
          rgba[i + 2] = lum;
          rgba[i + 3] = 255;
        }
      }

      // 4. Re-encode grayscale RGBA → PNG so encodeAvif can decode it.
      //    encodeAvif() takes an encoded image (PNG/JPEG), not raw RGBA.
      final buffer = await ui.ImmutableBuffer.fromUint8List(rgba);
      final descriptor = ui.ImageDescriptor.raw(
        buffer,
        width: w,
        height: h,
        pixelFormat: ui.PixelFormat.rgba8888,
      );
      final greyCodec = await descriptor.instantiateCodec();
      final greyFrame = await greyCodec.getNextFrame();
      final greyImage = greyFrame.image;
      final pngData = await greyImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      greyImage.dispose();
      if (pngData == null) return null;
      final pngBytes = pngData.buffer.asUint8List();

      // 5. Encode PNG → AVIF.
      //    maxQuantizer/minQuantizer: libavif CQ scale (0 = lossless, 63 = worst).
      //    compression=90 maps to maxQuantizer≈57, minQuantizer≈37.
      final maxQ = ((effectiveCompression / 100) * 63).round().clamp(0, 63);
      final minQ = (maxQ * 0.65).round().clamp(0, maxQ);
      final avif = await encodeAvif(
        pngBytes,
        maxThreads: 2,
        maxQuantizer: maxQ,
        minQuantizer: minQ,
        // We force fully opaque alpha, so alpha can be quantized aggressively.
        maxQuantizerAlpha: 63,
        minQuantizerAlpha: 63,
        // Slower speed improves compression efficiency at similar quality.
        speed: ultraMode ? _ultraAvifSpeed : _normalAvifSpeed,
        keepExif: false,
      );
      if (avif.isEmpty) return null;

      debugPrint(
        '📷 [ImageCodec] ${rawBytes.length}B → $w×$h grayscale AVIF '
        '${avif.length}B (${(avif.length * 100 / rawBytes.length).round()}%)',
      );
      return (bytes: avif, width: w, height: h);
    } catch (e, st) {
      debugPrint('❌ [ImageCodec] compress error: $e\n$st');
      return null;
    }
  }
}
