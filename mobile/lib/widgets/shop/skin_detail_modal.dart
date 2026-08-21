import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/skin_item.dart';
import '../../services/valorant_api_service.dart';

class SkinDetailModal extends StatefulWidget {
  final SkinItem skin;
  final bool isWishlisted;
  final bool isOwned;
  final VoidCallback? onToggleWishlist;

  const SkinDetailModal({
    super.key,
    required this.skin,
    this.isWishlisted = false,
    this.isOwned = false,
    this.onToggleWishlist,
  });

  static void show(
    BuildContext context,
    SkinItem skin, {
    bool isWishlisted = false,
    bool isOwned = false,
    VoidCallback? onToggleWishlist,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1B1B26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SkinDetailModal(
        skin: skin,
        isWishlisted: isWishlisted,
        isOwned: isOwned,
        onToggleWishlist: onToggleWishlist,
      ),
    );
  }

  @override
  State<SkinDetailModal> createState() => _SkinDetailModalState();
}

class _SkinDetailModalState extends State<SkinDetailModal> {
  late String _currentIcon;
  late String _currentVideo;
  late bool _isWishlisted;

  @override
  void initState() {
    super.initState();
    _currentIcon = widget.skin.displayIcon;
    _currentVideo = widget.skin.videoUrl;
    _isWishlisted = widget.isWishlisted;
  }

  void _playDemoVideo(BuildContext context, String title, String videoUrl) {
    if (videoUrl.isEmpty) return;

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF121218))
      ..loadHtmlString('''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0;
      padding: 0;
      background-color: #121218;
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      height: 100vh;
      overflow: hidden;
    }
    video {
      width: 100%;
      max-height: 80vh;
      border-radius: 12px;
      outline: none;
    }
  </style>
</head>
<body>
  <video autoplay loop controls playsinline muted>
    <source src="$videoUrl" type="video/mp4">
    Your browser does not support HTML5 video.
  </video>
</body>
</html>
''');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121218),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.70,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$title DEMO',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: WebViewWidget(controller: controller),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final skin = widget.skin;
    final fullData = ValorantApiService.getSkinFullData(skin.uuid);
    final chromas = (fullData?['chromas'] as List? ?? []);
    final levels = (fullData?['levels'] as List? ?? []);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 32),
                Expanded(
                  child: Text(
                    skin.parentName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isWishlisted = !_isWishlisted;
                    });
                    widget.onToggleWishlist?.call();
                  },
                  icon: Icon(
                    _isWishlisted ? Icons.favorite : Icons.favorite_border,
                    color: _isWishlisted ? const Color(0xFFFF4655) : Colors.white38,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_currentIcon.isNotEmpty)
              CachedNetworkImage(
                imageUrl: _currentIcon,
                height: 130,
                fit: BoxFit.contain,
                errorWidget: (context, url, error) => const Icon(Icons.shield, color: Colors.white24, size: 60),
              )
            else
              const Icon(Icons.shield, color: Colors.white24, size: 60),
            const SizedBox(height: 16),

            // Color Variants (Chromas) Swatches
            if (chromas.length > 1) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'COLOR VARIANTS',
                  style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: chromas.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final c = chromas[index];
                    final icon = (c['swatch'] ?? c['displayIcon'] ?? c['fullRender'] ?? '').toString();
                    final vid = (c['streamedVideo'] ?? skin.videoUrl).toString();
                    final cImage = (c['fullRender'] ?? c['displayIcon'] ?? skin.displayIcon).toString();
                    final isSelected = cImage == _currentIcon;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentIcon = cImage;
                          _currentVideo = vid;
                        });
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFF4655) : Colors.white12,
                            width: isSelected ? 2.0 : 1.0,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: icon.isNotEmpty
                              ? CachedNetworkImage(imageUrl: icon, fit: BoxFit.cover)
                              : const Icon(Icons.color_lens, color: Colors.white54, size: 20),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Skin Levels & Upgrades
            if (levels.length > 1) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'UPGRADES & LEVELS',
                  style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: levels.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final l = levels[index];
                    final lvlName = (l['displayName'] ?? 'Level ${index + 1}').toString();
                    final vid = (l['streamedVideo'] ?? _currentVideo).toString();

                    return GestureDetector(
                      onTap: () {
                        if (vid.isNotEmpty) {
                          setState(() {
                            _currentVideo = vid;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Text(
                          lvlName,
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Price / Ownership Pill
            if (widget.isOwned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'OWNED',
                      style: TextStyle(
                        color: Color(0xFF34D399),
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              )
            else if (skin.cost > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CachedNetworkImage(
                    imageUrl: 'https://media.valorant-api.com/currencies/85ad13f7-3d1b-5128-9eb2-7cd8ee0b5741/displayicon.png',
                    width: 18,
                    height: 18,
                    errorWidget: (context, url, error) => const Icon(Icons.monetization_on_outlined, color: Colors.white70, size: 16),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${skin.cost} VP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline_rounded, color: Colors.white54, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'NOT OWNED',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Watch Demo Video Button
            if (_currentVideo.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4655),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    _playDemoVideo(context, skin.parentName, _currentVideo);
                  },
                  icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                  label: const Text('WATCH DEMO VIDEO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
