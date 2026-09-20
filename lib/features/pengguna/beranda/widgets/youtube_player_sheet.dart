import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../../models/youtube_video_model.dart';

/// Modal bottom sheet untuk memutar video YouTube di dalam aplikasi
/// dengan kontrol pemutar yang ramah anak dan opsi fallback ke aplikasi YouTube/browser.
class YoutubePlayerSheet extends StatefulWidget {
  final YoutubeVideoModel video;

  const YoutubePlayerSheet({super.key, required this.video});

  /// Menampilkan modal pemutar video secara elegan
  static Future<void> show(BuildContext context, YoutubeVideoModel video) {
    // Di lingkungan desktop selain Android & iOS (misal Windows/Linux/macOS),
    // webview native tidak selalu tersedia, jadi sediakan opsi dialog langsung dengan launcher
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    if (!isMobile) {
      return showDialog(
        context: context,
        builder: (ctx) => _DesktopFallbackDialog(video: video),
      );
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => YoutubePlayerSheet(video: video),
    );
  }

  @override
  State<YoutubePlayerSheet> createState() => _YoutubePlayerSheetState();
}

class _YoutubePlayerSheetState extends State<YoutubePlayerSheet> {
  YoutubePlayerController? _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    try {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: widget.video.id,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showFullscreenButton: false,
          mute: false,
          enableCaption: true,
          showControls: true,
        ),
      );
    } catch (e) {
      setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  Future<void> _launchExternalYoutube() async {
    final uri = Uri.parse(widget.video.youtubeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag indicator bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header: Judul & tombol tutup
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0000).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.play_circle_filled_rounded,
                    color: Color(0xFFFF0000),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Video Edukasi Anak',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Tutup',
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Video Player Container
          if (_hasError || _controller == null) ...[
            Container(
              height: 210,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFEF4444)),
                  const SizedBox(height: 8),
                  Text(
                    'Tidak dapat memuat player in-app',
                    style: GoogleFonts.lato(fontSize: 14, color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _launchExternalYoutube,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF0000),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Buka di YouTube'),
                  ),
                ],
              ),
            ),
          ] else ...[
            ClipRRect(
              borderRadius: BorderRadius.zero,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: YoutubePlayer(
                  controller: _controller!,
                  aspectRatio: 16 / 9,
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Info Video & Tombol Buka di YouTube
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.video.title,
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      widget.video.channelTitle,
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.video.duration,
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _launchExternalYoutube,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E293B),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18, color: Color(0xFFFF0000)),
                  label: Text(
                    'Tonton di Aplikasi YouTube',
                    style: GoogleFonts.lato(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog fallback untuk environment non-mobile (Desktop/Web)
class _DesktopFallbackDialog extends StatelessWidget {
  final YoutubeVideoModel video;
  const _DesktopFallbackDialog({required this.video});

  Future<void> _launch() async {
    final uri = Uri.parse(video.youtubeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFFF0000), size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Video Edukasi Anak',
              style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              video.thumbnailUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 160,
                color: const Color(0xFFF1F5F9),
                child: const Icon(Icons.videocam_rounded, size: 48, color: Color(0xFF94A3B8)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            video.title,
            style: GoogleFonts.lato(fontSize: 14.5, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            'Durasi: ${video.duration} • ${video.channelTitle}',
            style: GoogleFonts.lato(fontSize: 12.5, color: const Color(0xFF64748B)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Tutup', style: GoogleFonts.lato(color: const Color(0xFF64748B))),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            _launch();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF0000),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Tonton di YouTube'),
        ),
      ],
    );
  }
}
