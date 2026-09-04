import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'services/tiktok_service.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TikTok Downloader',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF111111),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _urlController = TextEditingController();
  bool _loading = false;
  String? _error;
  TiktokResult? _result;

  Future<void> _fetch() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final result = await TiktokService.fetch(url);
      setState(() => _result = result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<File> _downloadToTemp(String fileUrl, String filename) async {
    final res = await http.get(Uri.parse(fileUrl));
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(res.bodyBytes);
    return file;
  }

  Future<void> _downloadAndShare(String fileUrl, String filename) async {
    try {
      final file = await _downloadToTemp(fileUrl, filename);
      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal download: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TikTok Downloader')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Tempel link TikTok',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading ? null : _fetch,
              child: Text(_loading ? 'Memproses...' : 'Ambil Video/Foto'),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_result != null) Expanded(child: _buildResult(_result!)),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(TiktokResult result) {
    if (result.type == TiktokType.video) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(result.title ?? 'Video TikTok',
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Download Video'),
              onPressed: () => _downloadAndShare(
                result.videoNoWatermark!,
                'tiktok_video_${DateTime.now().millisecondsSinceEpoch}.mp4',
              ),
            ),
          ],
        ),
      );
    }

    if (result.type == TiktokType.slide) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: result.images.length,
        itemBuilder: (context, i) {
          final imgUrl = result.images[i];
          return GestureDetector(
            onTap: () => _downloadAndShare(imgUrl, 'tiktok_slide_$i.jpg'),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(imgUrl, fit: BoxFit.cover),
                const Positioned(
                  right: 4,
                  bottom: 4,
                  child: Icon(Icons.download, color: Colors.white),
                ),
              ],
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}
