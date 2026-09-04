import 'dart:convert';
import 'package:http/http.dart' as http;

/// Tipe konten hasil fetch TikTok
enum TiktokType { video, slide, unknown }

class TiktokResult {
  final TiktokType type;
  final String? videoNoWatermark; // untuk mode video
  final String? musicUrl;
  final List<String> images; // untuk mode slide (foto)
  final String? title;

  TiktokResult({
    required this.type,
    this.videoNoWatermark,
    this.musicUrl,
    this.images = const [],
    this.title,
  });
}

class TiktokService {
  static const _endpoint = "https://www.tikwm.com/api/";

  /// Ambil data video/slide TikTok dari URL.
  /// Melempar Exception kalau gagal fetch atau data kosong.
  static Future<TiktokResult> fetch(String url) async {
    final res = await http.post(
      Uri.parse(_endpoint),
      body: {"url": url},
    );

    if (res.statusCode != 200) {
      throw Exception("Gagal fetch data TikTok (status ${res.statusCode})");
    }

    final json = jsonDecode(res.body);
    final data = json["data"];

    if (data == null) {
      throw Exception("Gagal fetch data TikTok: data kosong");
    }

    // tikwm balikin field "images" (list URL foto) khusus untuk post slide.
    final List? imagesRaw = data["images"];

    if (imagesRaw != null && imagesRaw.isNotEmpty) {
      return TiktokResult(
        type: TiktokType.slide,
        images: imagesRaw.map((e) => e.toString()).toList(),
        musicUrl: data["music"],
        title: data["title"],
      );
    }

    final play = data["play"];
    if (play != null) {
      return TiktokResult(
        type: TiktokType.video,
        videoNoWatermark: play,
        musicUrl: data["music"],
        title: data["title"],
      );
    }

    throw Exception("Format data TikTok tidak dikenali");
  }
}
