import 'dart:io';

import 'package:flutter/material.dart';

import '../data/media_storage.dart';

/// Vignette d'une photo enregistrée dans le dossier privé de l'app.
class PhotoThumb extends StatefulWidget {
  const PhotoThumb({
    super.key,
    required this.path,
    this.width = 76,
    this.height = 76,
    this.borderRadius = 14,
    this.onTap,
    this.onRemove,
  });

  final String path;
  final double width;
  final double height;
  final double borderRadius;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  State<PhotoThumb> createState() => _PhotoThumbState();
}

class _PhotoThumbState extends State<PhotoThumb> {
  late Future<File> _file;

  @override
  void initState() {
    super.initState();
    _file = MediaStorage.file(widget.path);
  }

  @override
  void didUpdateWidget(PhotoThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _file = MediaStorage.file(widget.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: Material(
                color: const Color(0xFFF4EAE5),
                child: InkWell(
                  onTap: widget.onTap,
                  child: FutureBuilder<File>(
                    future: _file,
                    builder: (context, snapshot) {
                      final file = snapshot.data;
                      if (file == null) {
                        return const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      return Image.file(
                        file,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Color(0xFFB7A39B),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          if (widget.onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: widget.onRemove,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 13, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
