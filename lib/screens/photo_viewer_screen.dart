import 'dart:io';

import 'package:flutter/material.dart';

import '../data/media_storage.dart';

/// Affichage plein écran des photos d'une fiche, avec zoom.
class PhotoViewerScreen extends StatefulWidget {
  const PhotoViewerScreen({
    super.key,
    required this.paths,
    this.initialIndex = 0,
  });

  final List<String> paths;
  final int initialIndex;

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_index + 1} / ${widget.paths.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.paths.length,
        onPageChanged: (index) => setState(() => _index = index),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(child: _FullPhoto(path: widget.paths[index])),
          );
        },
      ),
    );
  }
}

class _FullPhoto extends StatefulWidget {
  const _FullPhoto({required this.path});

  final String path;

  @override
  State<_FullPhoto> createState() => _FullPhotoState();
}

class _FullPhotoState extends State<_FullPhoto> {
  late final Future<File> _file = MediaStorage.file(widget.path);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File>(
      future: _file,
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null) {
          return const CircularProgressIndicator(color: Colors.white);
        }
        return Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stack) => const Icon(
            Icons.broken_image_outlined,
            color: Colors.white54,
            size: 64,
          ),
        );
      },
    );
  }
}
