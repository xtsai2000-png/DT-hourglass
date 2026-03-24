import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const ProviderScope(child: DTHourglassApp()));
}

// ============================================================================
/// 主題設定
// ============================================================================

class AppTheme {
  static const darkBackground = Color(0xFF0D0D0F);
  static const cardBackground = Color(0xFF1A1A1E);
  static const accentBlue   = Color(0xFF4FC3F7);
  static const accentPurple = Color(0xFF9C27B0);
  static const accentPink   = Color(0xFFE91E63);

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: accentBlue,
      secondary: accentPurple,
      surface: cardBackground,
    ),
    fontFamily: 'Roboto',
  );
}

// ============================================================================
/// 情緒維度（Mood）— Part 2 的核心規則
// ============================================================================

enum Mood {
  serene,    // 寧靜 → 剔透藍 #64B5F6
  anxious,   // 焦慮 → 渾濁灰 #78909C
  focused,    // 專注 → 深邃紫 #7E57C2
  energetic,  // 活力 → 暖橘黃 #FFB74D
  resting,    // 休息 → 深藍綠 #26A69A
}

extension MoodExtension on Mood {
  Color get color {
    switch (this) {
      case Mood.serene:   return const Color(0xFF64B5F6);
      case Mood.anxious:  return const Color(0xFF78909C);
      case Mood.focused:  return const Color(0xFF7E57C2);
      case Mood.energetic:return const Color(0xFFFFB74D);
      case Mood.resting:  return const Color(0xFF26A69A);
    }
  }

  String get label {
    switch (this) {
      case Mood.serene:   return '平靜';
      case Mood.anxious:  return '焦慮';
      case Mood.focused:  return '專注';
      case Mood.energetic:return '活力';
      case Mood.resting:  return '休息';
    }
  }

  /// 顆粒質地（0.0 = 光滑凝膠, 1.0 = 粗糙砂粒）
  double get texture {
    switch (this) {
      case Mood.serene:   return 0.2;
      case Mood.anxious:  return 0.8;
      case Mood.focused:  return 0.9;
      case Mood.energetic:return 0.5;
      case Mood.resting:  return 0.3;
    }
  }
}

// ============================================================================
/// 沉積層（SedimentLayer）— 歷史記錄單位
// ============================================================================

class SedimentLayer {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final Mood mood;
  final String? aiSummary;

  SedimentLayer({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.mood,
    this.aiSummary,
  });

  Duration get duration => endTime.difference(startTime);

  Map<String, dynamic> toJson() => {
    'id': id,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'mood': mood.index,
    'aiSummary': aiSummary,
  };

  factory SedimentLayer.fromJson(Map<String, dynamic> json) => SedimentLayer(
    id: json['id'] as String,
    startTime: DateTime.parse(json['startTime'] as String),
    endTime: DateTime.parse(json['endTime'] as String),
    mood: Mood.values[json['mood'] as int],
    aiSummary: json['aiSummary'] as String?,
  );
}

// ============================================================================
/// 狀態管理（Riverpod）— Part 3 核心狀態
// ============================================================================

/// 當前情緒（模擬用，之後串接 HealthKit / Google Fit）
final currentMoodProvider = StateProvider<Mood>((ref) => Mood.serene);

/// 沉積層列表（歷史）
final sedimentLayersProvider = StateNotifierProvider<SedimentLayersNotifier, List<SedimentLayer>>((ref) {
  return SedimentLayersNotifier();
});

class SedimentLayersNotifier extends StateNotifier<List<SedimentLayer>> {
  SedimentLayersNotifier() : super([]);

  void addLayer(SedimentLayer layer) {
    state = [...state, layer];
  }

  void removeLast() {
    if (state.isNotEmpty) {
      state = state.sublist(0, state.length - 1);
    }
  }

  void clear() {
    state = [];
  }
}

/// 螢幕上的活躍粉塵粒子
final activeParticlesProvider = StateNotifierProvider<ActiveParticlesNotifier, List<Particle>>((ref) {
  return ActiveParticlesNotifier();
});

class Particle {
  final String id;
  final double x;          // 0.0 ~ 1.0 相對座標
  final double y;
  final double vx;         // 水平速度
  final double vy;         // 垂直速度（正=往下）
  final double size;       // 像素大小
  final Color color;
  final double texture;    // 0.0 ~ 1.0 粗糙度

  Particle({
    required this.id,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.texture,
  });

  Particle copyWith({double? x, double? y, double? vx, double? vy}) => Particle(
    id: id,
    x: x ?? this.x,
    y: y ?? this.y,
    vx: vx ?? this.vx,
    vy: vy ?? this.vy,
    size: size,
    color: color,
    texture: texture,
  );
}

class ActiveParticlesNotifier extends StateNotifier<List<Particle>> {
  ActiveParticlesNotifier() : super([]);
  int _counter = 0;

  void spawnParticle(Mood mood, double centerX) {
    final id = 'p${_counter++}';
    final color = mood.color;
    final texture = mood.texture;
    final size = 4.0 + (texture * 6.0); // 粗糙 → 顆粒較大

    // 從沙漏上半部中間落下，帶隨機水平偏移
    final x = centerX + (DateTime.now().microsecond / 1000000.0 - 0.5) * 0.1;
    final y = 0.1;
    final vx = (DateTime.now().microsecond / 500000.0 - 1.0) * 0.002;
    final vy = 0.003 + (DateTime.now().microsecond / 1000000.0) * 0.002;

    state = [...state, Particle(
      id: id,
      x: x,
      y: y,
      vx: vx,
      vy: vy,
      size: size,
      color: color,
      texture: texture,
    )];
  }

  void updatePositions() {
    state = state.map((p) => p.copyWith(
      x: p.x + p.vx,
      y: p.y + p.vy,
    )).where((p) => p.y < 1.0).toList(); // 掉出畫面就移除
  }

  void clear() => state = [];
}

// ============================================================================
/// 主應用程式
// ============================================================================

class DTHourglassApp extends StatelessWidget {
  const DTHourglassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '沉光 DT-hourglass',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const HourglassScreen(),
    );
  }
}

// ============================================================================
/// 主畫面 — Part 3 視覺原型
// ============================================================================

class HourglassScreen extends ConsumerStatefulWidget {
  const HourglassScreen({super.key});

  @override
  ConsumerState<HourglassScreen> createState() => _HourglassScreenState();
}

class _HourglassScreenState extends ConsumerState<HourglassScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    // 每 100ms 更新一次粒子
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(_onTick);
    _animController.repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTick() {
    final mood = ref.read(currentMoodProvider);
    final screenW = MediaQuery.of(context).size.width;

    // 根據視窗大小計算沙漏中心位置（相對座標）
    final centerX = 0.5;
    ref.read(activeParticlesProvider.notifier).spawnParticle(mood, centerX);
    ref.read(activeParticlesProvider.notifier).updatePositions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          // ── 1. 背景：漸層聚光燈效果 ──
          _buildSpotlightBackground(),

          // ── 2. 沙漏容器 ──
          const Positioned.fill(child: HourglassPainter()),

          // ── 3. 左側資料卡 ──
          Positioned(
            left: 16,
            top: MediaQuery.of(context).padding.top + 16,
            child: _buildDataCards(),
          ),

          // ── 4. 右側資料卡 ──
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 16,
            child: _buildSleepCard(),
          ),

          // ── 5. 底部導航列 ──
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 8,
            child: _buildBottomNav(),
          ),

          // ── 6. 情緒切換（模擬用）──
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 80,
            left: 0,
            right: 0,
            child: _buildMoodSimulator(),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotlightBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.2,
          colors: [
            Colors.white.withOpacity(0.04),
            AppTheme.darkBackground,
          ],
        ),
      ),
    );
  }

  Widget _buildDataCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI 晶片
        _DataCard(
          icon: Icons.memory,
          iconColor: AppTheme.accentBlue,
          label: 'AI 晶片',
          value: '運行中',
        ),
        const SizedBox(height: 8),
        // 心率
        _DataCard(
          icon: Icons.favorite,
          iconColor: Colors.redAccent,
          label: '心率',
          value: '72 bpm',
        ),
        const SizedBox(height: 8),
        // 步數
        _DataCard(
          icon: Icons.directions_walk,
          iconColor: AppTheme.accentBlue,
          label: '步數',
          value: '12,345',
        ),
        const SizedBox(height: 8),
        // 環境光線
        _DataCard(
          icon: Icons.wb_sunny,
          iconColor: Colors.amber,
          label: '環境光線',
          value: '350 lux',
        ),
      ],
    );
  }

  Widget _buildSleepCard() {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.nightlight_round, color: Colors.indigo.shade300, size: 18),
              const SizedBox(width: 6),
              const Text('睡眠監測', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 10),
          // 模擬睡眠圖
          SizedBox(
            height: 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(12, (i) {
                final h = 10.0 + (i % 3) * 8.0 + (i * 1.5);
                return Expanded(
                  child: Container(
                    height: h,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: i % 2 == 0
                          ? Colors.indigo.shade300
                          : Colors.deepPurple.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18), onPressed: () {}),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentPurple.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, size: 14, color: Colors.white70),
                SizedBox(width: 4),
                Text('AI', style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.settings_outlined, size: 18), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildMoodSimulator() {
    return Consumer(
      builder: (context, ref, _) {
        final mood = ref.watch(currentMoodProvider);
        return Column(
          children: [
            Text(
              '目前情緒：${mood.label}',
              style: TextStyle(color: mood.color, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: Mood.values.map((m) {
                final isActive = m == mood;
                return GestureDetector(
                  onTap: () => ref.read(currentMoodProvider.notifier).state = m,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? m.color.withOpacity(0.3) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isActive ? m.color : Colors.grey.shade600),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            color: m.color, shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(m.label, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
/// 沙漏視覺元件（CustomPainter）— 尚未實作，等待 Part 3 下一版
// ============================================================================

class HourglassPainter extends ConsumerWidget {
  const HourglassPainter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final centerX = constraints.maxWidth / 2;
        final centerY = constraints.maxHeight / 2;
        final hourglassH = constraints.maxHeight * 0.65;
        final hourglassW = hourglassH * 0.38;

        return Stack(
          children: [
            // 沙漏玻璃外框
            Positioned(
              left: centerX - hourglassW / 2,
              top: centerY - hourglassH / 2,
              child: CustomPaint(
                size: Size(hourglassW, hourglassH),
                painter: _HourglassGlassPainter(),
              ),
            ),

            // 粉塵粒子（Canvas）
            Positioned.fill(
              child: CustomPaint(
                painter: _ParticleCanvasPainter(
                  particles: ref.watch(activeParticlesProvider),
                  hourglassLeft: centerX - hourglassW / 2,
                  hourglassTop: centerY - hourglassH / 2,
                  hourglassWidth: hourglassW,
                  hourglassHeight: hourglassH,
                ),
              ),
            ),

            // 沉積層（底部）
            Positioned(
              left: centerX - hourglassW / 2 + 4,
              bottom: centerY - hourglassH / 2 + 4,
              child: SedimentStack(
                layers: ref.watch(sedimentLayersProvider),
                maxWidth: hourglassW - 8,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HourglassGlassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 左半部沙漏
    final leftPath = Path()
      ..moveTo(size.width * 0.2, 0)
      ..quadraticBezierTo(size.width * 0.0, size.height * 0.25,
                           size.width * 0.5, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.0, size.height * 0.75,
                           size.width * 0.2, size.height);

    // 右半部（水平翻轉）
    final rightPath = Path()
      ..moveTo(size.width * 0.8, 0)
      ..quadraticBezierTo(size.width * 1.0, size.height * 0.25,
                           size.width * 0.5, size.height * 0.5)
      ..quadraticBezierTo(size.width * 1.0, size.height * 0.75,
                           size.width * 0.8, size.height);

    canvas.drawPath(leftPath, paint);
    canvas.drawPath(rightPath, paint);

    // 中心束口
    final neckPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.47),
      Offset(size.width * 0.5, size.height * 0.53),
      neckPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ParticleCanvasPainter extends CustomPainter {
  final List<Particle> particles;
  final double hourglassLeft;
  final double hourglassTop;
  final double hourglassWidth;
  final double hourglassHeight;

  _ParticleCanvasPainter({
    required this.particles,
    required this.hourglassLeft,
    required this.hourglassTop,
    required this.hourglassWidth,
    required this.hourglassHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // 轉換相對座標 → 絕對座標
      final absX = hourglassLeft + p.x * hourglassWidth;
      final absY = hourglassTop + p.y * hourglassHeight;

      // 越接近底部（y越大），粒子越小（透視感）
      final scaleY = 0.3 + (p.y * 0.7);
      final radius = (p.size / 2) * scaleY;

      // 粗糙粒子：畫十字光芒
      if (p.texture > 0.6) {
        final starPaint = Paint()
          ..color = p.color.withOpacity(0.4)
          ..strokeWidth = 1;
        canvas.drawLine(
          Offset(absX - radius, absY),
          Offset(absX + radius, absY),
          starPaint,
        );
        canvas.drawLine(
          Offset(absX, absY - radius),
          Offset(absX, absY + radius),
          starPaint,
        );
      }

      // 主粒子
      final paint = Paint()
        ..color = p.color.withOpacity(0.85)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(absX, absY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleCanvasPainter oldDelegate) => true;
}

// ============================================================================
/// 沉積層堆疊視覺
// ============================================================================

class SedimentStack extends StatelessWidget {
  final List<SedimentLayer> layers;
  final double maxWidth;

  const SedimentStack({super.key, required this.layers, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    if (layers.isEmpty) {
      return Container(
        width: maxWidth,
        height: 8,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    return SizedBox(
      width: maxWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: layers.reversed.take(5).map((layer) {
          return Container(
            width: maxWidth,
            height: 12,
            margin: const EdgeInsets.only(bottom: 1),
            decoration: BoxDecoration(
              color: layer.mood.color.withOpacity(0.7),
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [
                  layer.mood.color.withOpacity(0.5),
                  layer.mood.color,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================================
/// 資料卡元件
// ============================================================================

class _DataCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _DataCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.75),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
