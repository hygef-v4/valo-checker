import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/skin_item.dart';
import '../../services/valorant_api_service.dart';

class SkinDetailModal extends StatefulWidget {
  final SkinItem skin;

  const SkinDetailModal({
    super.key,
    required this.skin,
  });

  static void show(BuildContext context, SkinItem skin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1B1B26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SkinDetailModal(skin: skin),
    );
  }

  @override
  State<SkinDetailModal> createState() => _SkinDetailModalState();
}

class _SkinDetailModalState extends State<SkinDetailModal> {
  late String _currentIcon;
  late String _currentVideo;

  @override
  void initState() {
    super.initState();
    _currentIcon = widget.skin.displayIcon;
    _currentVideo = widget.skin.videoUrl;
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
            Text(
              skin.parentName.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: 1.2,
              ),
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

            // Price Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CachedNetworkImage(
                  imageUrl: 'https://media.valorant-api.com/currencies/85ad13f7-3d1b-da12-a0a0-4e907616386c/displayicon.png',
                  width: 18,
                  height: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  skin.cost > 0 ? '${skin.cost} VP' : 'OWNED',
                  style: TextStyle(
                    color: skin.cost > 0 ? Colors.white : const Color(0xFF34D399),
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
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
