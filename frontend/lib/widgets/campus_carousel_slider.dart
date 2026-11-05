import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class CampusSlideItem {
  final String imagePath, tag1, tag2, title, description;
  const CampusSlideItem(this.imagePath, this.tag1, this.tag2, this.title, this.description);
}

/// Widget Hero Slider Foto Kampus POLTEKOM (Identik 100% dengan Web Dashboard Hero Carousel)
class CampusCarouselSlider extends StatefulWidget {
  const CampusCarouselSlider({super.key});

  @override
  State<CampusCarouselSlider> createState() => _CampusCarouselSliderState();
}

class _CampusCarouselSliderState extends State<CampusCarouselSlider> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _autoPlayTimer;

  static const List<CampusSlideItem> _slides = [
    CampusSlideItem(
      'assets/campus_1.jpg', 'Gedung Terpadu', 'Arsitektur Modern POLTEKOM',
      'Gedung Utama & Fakultas POLTEKOM',
      'Tampak perspektif modern kampus dengan aksen merah dan biru, menaungi ruang laboratorium dan perkuliahan vokasi terintegrasi.',
    ),
    CampusSlideItem(
      'assets/campus_2.jpg', 'Fasilitas Perkuliahan', 'Atrium Terbuka Asri',
      'Gedung Kuliah & Atrium Terbuka POLTEKOM',
      'Perspektif koridor dan atrium terbuka bertingkat di POLTEKOM yang sejuk dengan sirkulasi udara alami dan kolam asri.',
    ),
    CampusSlideItem(
      'assets/campus_3.jpg', 'Fasad Ikonik', 'Pusat Administrasi & Rektorat',
      'Gedung Rektorat & Gerbang Utama POLTEKOM',
      'Tampak depan simetris ikonik Politeknik Kota Malang dengan pilar gagah cerah serta sistem pemantauan terpusat.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.animateToPage(
        (_currentIndex + 1) % _slides.length,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 235,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardOutline, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (idx) {
                setState(() => _currentIndex = idx);
                _startAutoPlay();
              },
              itemBuilder: (context, idx) {
                final s = _slides[idx];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(s.imagePath, fit: BoxFit.cover),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.background.withValues(alpha: 0.45),
                            AppColors.background.withValues(alpha: 0.95),
                          ],
                          stops: const [0.35, 0.70, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14, right: 14, bottom: 22,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(children: [
                            _buildPill(s.tag1, isPrimary: true),
                            const SizedBox(width: 6),
                            _buildPill(s.tag2, isPrimary: false),
                          ]),
                          const SizedBox(height: 6),
                          Text(
                            s.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w800, color: Colors.white,
                              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            s.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10.5, color: Colors.white.withValues(alpha: 0.85), height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            Positioned(
              top: 12, left: 12, right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardOutline),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🏛️', style: TextStyle(fontSize: 12)),
                        SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('POLTEKOM', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white)),
                            Text('Galeri Kampus', style: TextStyle(fontSize: 8.5, color: AppColors.primaryLight, fontFamily: 'monospace')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.safeEmerald.withValues(alpha: 0.40)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.safeEmerald, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        const Text(
                          'Kampus Terpantau',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.safeEmerald, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 8, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (idx) {
                  final isActive = idx == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: isActive ? 22 : 6,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(String label, {required bool isPrimary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPrimary ? AppColors.safeEmerald.withValues(alpha: 0.45) : AppColors.cardOutline),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5, fontWeight: FontWeight.w700,
          color: isPrimary ? AppColors.safeEmerald : AppColors.primaryLight,
        ),
      ),
    );
  }
}
