import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

void main() => runApp(const FitnessApp());

// ═══════════════════════════════════════════
//  APP ROOT
// ═══════════════════════════════════════════
class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF88FF00),
          secondary: Color(0xFF67B000),
          surface: Color(0xFF1C1C1E),
        ),
        fontFamily: 'SF Pro Display',
      ),
      home: const MainNavScreen(),
    );
  }
}

// ═══════════════════════════════════════════
//  DATA MODELS
// ═══════════════════════════════════════════
class WeightRecord {
  final double weight;
  final double bodyFat;
  final DateTime date;

  WeightRecord({
    required this.weight,
    required this.bodyFat,
    required this.date,
  });
}

class AppData extends ChangeNotifier {
  double goalWeight = 65.0;
  double heightCm = 170.0;

  List<WeightRecord> records = [
    WeightRecord(weight: 72.5, bodyFat: 23.0, date: DateTime.now().subtract(const Duration(days: 6))),
    WeightRecord(weight: 71.8, bodyFat: 22.8, date: DateTime.now().subtract(const Duration(days: 5))),
    WeightRecord(weight: 71.2, bodyFat: 22.5, date: DateTime.now().subtract(const Duration(days: 4))),
    WeightRecord(weight: 70.9, bodyFat: 22.3, date: DateTime.now().subtract(const Duration(days: 3))),
    WeightRecord(weight: 70.5, bodyFat: 22.1, date: DateTime.now().subtract(const Duration(days: 2))),
    WeightRecord(weight: 70.2, bodyFat: 22.0, date: DateTime.now().subtract(const Duration(days: 1))),
    WeightRecord(weight: 70.1, bodyFat: 22.0, date: DateTime.now()),
  ];

  double get currentWeight => records.last.weight;
  double get currentBodyFat => records.last.bodyFat;
  double get startWeight => records.first.weight;

  double get bmi => currentWeight / ((heightCm / 100) * (heightCm / 100));
  String get bmiCategory {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  Color get bmiColor {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25.0) return const Color(0xFF88FF00);
    if (bmi < 30.0) return Colors.orange;
    return Colors.red;
  }

  double get progressPercent {
    if (startWeight == goalWeight) return 1.0;
    double p = (startWeight - currentWeight) / (startWeight - goalWeight);
    return p.clamp(0.0, 1.0);
  }

  int get daysLeft {
    double remaining = currentWeight - goalWeight;
    return (remaining * 14).round().clamp(0, 999);
  }

  double get weightChange {
    if (records.length < 2) return 0;
    return records.last.weight - records[records.length - 2].weight;
  }

  void addRecord(double weight, double bodyFat) {
    records.add(WeightRecord(weight: weight, bodyFat: bodyFat, date: DateTime.now()));
    notifyListeners();
  }
}

// ═══════════════════════════════════════════
//  MAIN NAVIGATION — BOTTOM NAV BAR
// ═══════════════════════════════════════════
class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;
  final AppData _appData = AppData();

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(appData: _appData),
      ChartsScreen(appData: _appData),
      BMIScreen(appData: _appData),
      ProfileScreen(appData: _appData),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          border: Border(top: BorderSide(color: Color(0xFF2C2C2E), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF88FF00),
          unselectedItemColor: Colors.grey,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded, size: 22), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded, size: 22), label: 'Charts'),
            BottomNavigationBarItem(icon: Icon(Icons.monitor_weight_outlined, size: 22), label: 'BMI'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded, size: 22), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
//  SCREEN 1 — DASHBOARD
// ═══════════════════════════════════════════
class DashboardScreen extends StatefulWidget {
  final AppData appData;
  const DashboardScreen({super.key, required this.appData});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _progressAnim;
  String _selectedTab = 'Day';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _progressAnim = Tween<double>(begin: 0, end: widget.appData.progressPercent)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _refreshAnimation() {
    _progressAnim = Tween<double>(begin: _progressAnim.value, end: widget.appData.progressPercent)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
        ),
        title: const Text('Weight Tracker', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          GestureDetector(
            onTap: () => _showAddRecordDialog(context),
            child: Container(
              margin: const EdgeInsets.only(right: 15),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF88FF00),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('+ Add', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.appData,
        builder: (context, _) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildTabBar(),
                _buildMainCard(),
                _buildQuickStats(),
                _buildActionButtons(context),
                _buildStayFitCard(),
                _buildMiniChart(),
                const SizedBox(height: 16),
                _buildTopPicks(),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── TAB BAR ────────────────────────────────
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: ['Day', 'Week', 'Month', 'Year'].map((tab) {
          bool sel = tab == _selectedTab;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = tab),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFF88FF00) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(tab,
                  style: TextStyle(
                      color: sel ? Colors.black : Colors.grey,
                      fontSize: 12,
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── MAIN GREEN CARD ───────────────────────
  Widget _buildMainCard() {
    final data = widget.appData;
    final change = data.weightChange;
    final isUp = change >= 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2d4a00), Color(0xFF1a2e00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: const Color(0xFF88FF00).withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.calendar_today, color: Colors.white54, size: 11),
            const SizedBox(width: 5),
            Text(
              '${_weekdayName(data.records.last.date.weekday)} ${data.records.last.date.day} ${_monthName(data.records.last.date.month)}',
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ]),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(data.currentWeight.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white, height: 1.0)),
              const Text(' kg', style: TextStyle(fontSize: 16, color: Colors.white70, height: 2.2)),
              const SizedBox(width: 20),
              Container(width: 1, height: 30, color: Colors.white24),
              const SizedBox(width: 15),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isUp ? Colors.redAccent : const Color(0xFF88FF00), size: 14),
                  Text(' ${change.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                          color: isUp ? Colors.redAccent : const Color(0xFF88FF00),
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const Text(' vs last', style: TextStyle(color: Colors.white54, fontSize: 9)),
                ]),
                const SizedBox(height: 3),
                Text('Body fat ${data.currentBodyFat.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white54, fontSize: 10)),
              ]),
            ],
          ),
          const SizedBox(height: 4),
          Text('BMI ${data.bmi.toStringAsFixed(1)} — ${data.bmiCategory}',
              style: TextStyle(color: data.bmiColor, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Lose weight goal', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            RichText(
              text: TextSpan(children: [
                TextSpan(text: '${data.daysLeft} days left  ',
                    style: const TextStyle(color: Colors.white70, fontSize: 10)),
                TextSpan(text: '${(data.progressPercent * 100).toStringAsFixed(0)}% done',
                    style: const TextStyle(color: Color(0xFF88FF00), fontSize: 10, fontWeight: FontWeight.bold)),
              ]),
            ),
          ]),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _progressAnim,
            builder: (context, _) {
              return Stack(children: [
                Container(height: 8, decoration: BoxDecoration(color: const Color(0xFF4a7000), borderRadius: BorderRadius.circular(6))),
                FractionallySizedBox(
                  widthFactor: _progressAnim.value,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF88FF00), Color(0xFFCCFF00)]),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ]);
            },
          ),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${data.startWeight.toStringAsFixed(1)} kg',
                style: const TextStyle(color: Colors.white54, fontSize: 9)),
            Text('Goal: ${data.goalWeight.toStringAsFixed(1)} kg',
                style: const TextStyle(color: Color(0xFF88FF00), fontSize: 9)),
          ]),
        ],
      ),
    );
  }

  // ── QUICK STATS ROW ────────────────────────
  Widget _buildQuickStats() {
    final data = widget.appData;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Row(children: [
        _statCard('Lost', '${(data.startWeight - data.currentWeight).toStringAsFixed(1)} kg', Icons.trending_down, Colors.greenAccent),
        const SizedBox(width: 10),
        _statCard('Remaining', '${(data.currentWeight - data.goalWeight).toStringAsFixed(1)} kg', Icons.flag_rounded, const Color(0xFF88FF00)),
        const SizedBox(width: 10),
        _statCard('Days Left', '${data.daysLeft}', Icons.schedule_rounded, Colors.orangeAccent),
      ]),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 0.5),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9)),
        ]),
      ),
    );
  }

  // ── ACTION BUTTONS ─────────────────────────
  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      child: Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _showAddRecordDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF4C7D00), Color(0xFF3a6000)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_circle_outline, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Add Record', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF88FF00).withOpacity(0.3))),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.straighten, color: Color(0xFF88FF00), size: 16),
              SizedBox(width: 8),
              Text('Measure', style: TextStyle(color: Color(0xFF88FF00), fontSize: 12, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── STAY FIT CARD ──────────────────────────
  Widget _buildStayFitCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Stay Fit', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          Text('Diet Log ›', style: TextStyle(color: Colors.white38, fontSize: 10)),
        ]),
        const SizedBox(height: 20),
        Stack(alignment: Alignment.center, children: [
          CustomPaint(size: const Size(260, 130), painter: GaugePainter()),
          const Positioned(bottom: 20, child: Column(children: [
            Text('1,860', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            Text('kcal remaining', style: TextStyle(color: Colors.white54, fontSize: 9)),
          ])),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _kcalCol(Icons.local_fire_department, Colors.orange, 'Total Burns', '1,806 / 23,456 kcal'),
          _kcalCol(Icons.home_rounded, Colors.greenAccent, 'Total Consumed', '1,806 / 23,456 kcal'),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _mealBox('Breakfast', Icons.egg_alt_rounded),
          _mealBox('Lunch', Icons.lunch_dining_rounded),
          _mealBox('Dinner', Icons.dinner_dining_rounded),
        ]),
      ]),
    );
  }

  Widget _kcalCol(IconData icon, Color color, String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: color, size: 13), const SizedBox(width: 5), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9))]),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _mealBox(String label, IconData icon) {
    return Container(
      width: 95,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFF2A2A2C), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Stack(alignment: Alignment.bottomRight, children: [
          CircleAvatar(radius: 18, backgroundColor: const Color(0xFF67B000), child: Icon(icon, color: Colors.white, size: 17)),
          Container(decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.add_circle, color: Color(0xFF67B000), size: 13)),
        ]),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  // ── MINI INLINE CHART ─────────────────────
  Widget _buildMiniChart() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('This Week', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          Text('See all ›', style: TextStyle(color: Color(0xFF88FF00), fontSize: 10)),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: CustomPaint(
            size: const Size(double.infinity, 80),
            painter: MiniChartPainter(records: widget.appData.records),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: widget.appData.records.map((r) =>
            Text(_shortDay(r.date.weekday), style: const TextStyle(color: Colors.white38, fontSize: 8))).toList()),
      ]),
    );
  }

  // ── TOP PICKS ─────────────────────────────
  Widget _buildTopPicks() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 15),
        child: Text('Top Picks', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(height: 10),
      SizedBox(height: 120, child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _pickCard('Cardio — Fat Burning\n(Beginner)', 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=400'),
          _pickCard('Core — Strength\nTraining', 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400'),
          _pickCard('Yoga — Flexibility\n& Balance', 'https://images.unsplash.com/photo-1575052814086-f385e2e2ad1b?w=400'),
        ],
      )),
    ]);
  }

  Widget _pickCard(String title, String url) {
    return Container(
      width: 190,
      margin: const EdgeInsets.only(left: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken)),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, height: 1.3)),
        ),
      ),
    );
  }

  // ── ADD RECORD DIALOG ─────────────────────
  void _showAddRecordDialog(BuildContext context) {
    final weightCtrl = TextEditingController(text: widget.appData.currentWeight.toStringAsFixed(1));
    final fatCtrl = TextEditingController(text: widget.appData.currentBodyFat.toStringAsFixed(1));
    double sliderWeight = widget.appData.currentWeight;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Add Weight Record', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
              ]),
              const SizedBox(height: 20),

              // Weight slider
              const Text('Weight (kg)', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(ctx).copyWith(
                      activeTrackColor: const Color(0xFF88FF00),
                      inactiveTrackColor: const Color(0xFF3a3a3a),
                      thumbColor: const Color(0xFF88FF00),
                      overlayColor: const Color(0xFF88FF00).withOpacity(0.2),
                    ),
                    child: Slider(
                      value: sliderWeight,
                      min: 40.0,
                      max: 150.0,
                      divisions: 1100,
                      onChanged: (v) {
                        setModal(() {
                          sliderWeight = v;
                          weightCtrl.text = v.toStringAsFixed(1);
                        });
                      },
                    ),
                  ),
                ),
                Container(
                  width: 70,
                  margin: const EdgeInsets.only(left: 8),
                  child: TextField(
                    controller: weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      suffixText: 'kg',
                      suffixStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2E),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    onChanged: (v) {
                      final parsed = double.tryParse(v);
                      if (parsed != null && parsed >= 40 && parsed <= 150) {
                        setModal(() => sliderWeight = parsed);
                      }
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 16),

              // Body fat input
              const Text('Body Fat (%)', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: fatCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g. 22.0',
                  hintStyle: const TextStyle(color: Colors.white38),
                  suffixText: '%',
                  suffixStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF88FF00),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    final w = double.tryParse(weightCtrl.text) ?? sliderWeight;
                    final f = double.tryParse(fatCtrl.text) ?? widget.appData.currentBodyFat;
                    widget.appData.addRecord(w, f);
                    _refreshAnimation();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Record added!'),
                        backgroundColor: const Color(0xFF67B000),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  child: const Text('Save Record', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      ),
    );
  }

  String _weekdayName(int d) => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d - 1];
  String _monthName(int m) => ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];
  String _shortDay(int d) => ['M', 'T', 'W', 'T', 'F', 'S', 'S'][d - 1];
}

// ═══════════════════════════════════════════
//  SCREEN 2 — CHARTS
// ═══════════════════════════════════════════
class ChartsScreen extends StatefulWidget {
  final AppData appData;
  const ChartsScreen({super.key, required this.appData});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _drawAnim;
  String _chartType = 'Weight';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _drawAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        title: const Text('Charts & Progress', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: AnimatedBuilder(
        animation: widget.appData,
        builder: (_, __) => SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(children: [
            _buildChartTypeSelector(),
            _buildMainChart(),
            _buildStatsCards(),
            _buildBodyFatChart(),
            const SizedBox(height: 30),
          ]),
        ),
      ),
    );
  }

  Widget _buildChartTypeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Row(children: ['Weight', 'Body Fat', 'BMI'].map((t) {
        bool sel = t == _chartType;
        return GestureDetector(
          onTap: () {
            setState(() => _chartType = t);
            _animCtrl.reset();
            _animCtrl.forward();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? const Color(0xFF88FF00) : const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(t, style: TextStyle(
              color: sel ? Colors.black : Colors.white70,
              fontSize: 12,
              fontWeight: sel ? FontWeight.bold : FontWeight.normal,
            )),
          ),
        );
      }).toList()),
    );
  }

  Widget _buildMainChart() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_chartType, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Last 7 days', style: const TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: _drawAnim,
          builder: (_, __) => SizedBox(
            height: 180,
            child: CustomPaint(
              size: const Size(double.infinity, 180),
              painter: FullChartPainter(
                records: widget.appData.records,
                chartType: _chartType,
                progress: _drawAnim.value,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: widget.appData.records.map((r) {
            final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            return Text(days[r.date.weekday - 1], style: const TextStyle(color: Colors.white38, fontSize: 9));
          }).toList()),
      ]),
    );
  }

  Widget _buildStatsCards() {
    final data = widget.appData;
    final allWeights = data.records.map((r) => r.weight).toList();
    final minW = allWeights.reduce(math.min);
    final maxW = allWeights.reduce(math.max);
    final avgW = allWeights.reduce((a, b) => a + b) / allWeights.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      child: Row(children: [
        _chartStatCard('Min', '${minW.toStringAsFixed(1)} kg', Colors.greenAccent),
        const SizedBox(width: 10),
        _chartStatCard('Avg', '${avgW.toStringAsFixed(1)} kg', const Color(0xFF88FF00)),
        const SizedBox(width: 10),
        _chartStatCard('Max', '${maxW.toStringAsFixed(1)} kg', Colors.orangeAccent),
      ]),
    );
  }

  Widget _chartStatCard(String label, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25), width: 0.5),
        ),
        child: Column(children: [
          Text(val, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _buildBodyFatChart() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Body Fat Trend', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: _drawAnim,
          builder: (_, __) => SizedBox(
            height: 120,
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: FullChartPainter(
                records: widget.appData.records,
                chartType: 'Body Fat',
                progress: _drawAnim.value,
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════
//  SCREEN 3 — BMI CALCULATOR
// ═══════════════════════════════════════════
class BMIScreen extends StatefulWidget {
  final AppData appData;
  const BMIScreen({super.key, required this.appData});

  @override
  State<BMIScreen> createState() => _BMIScreenState();
}

class _BMIScreenState extends State<BMIScreen> with SingleTickerProviderStateMixin {
  late double _height;
  late double _weight;
  late AnimationController _needleCtrl;
  late Animation<double> _needleAnim;

  @override
  void initState() {
    super.initState();
    _height = widget.appData.heightCm;
    _weight = widget.appData.currentWeight;
    _needleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _needleAnim = CurvedAnimation(parent: _needleCtrl, curve: Curves.elasticOut);
    _needleCtrl.forward();
  }

  @override
  void dispose() {
    _needleCtrl.dispose();
    super.dispose();
  }

  double get _bmi => _weight / ((_height / 100) * (_height / 100));

  String get _category {
    if (_bmi < 18.5) return 'Underweight';
    if (_bmi < 25.0) return 'Normal';
    if (_bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  Color get _bmiColor {
    if (_bmi < 18.5) return Colors.blueAccent;
    if (_bmi < 25.0) return const Color(0xFF88FF00);
    if (_bmi < 30.0) return Colors.orange;
    return Colors.red;
  }

  double get _needleAngle {
    // Map BMI 10–40 to angle 0–1
    double normalized = (_bmi - 10) / 30;
    return normalized.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        title: const Text('BMI Calculator', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(15),
        child: Column(children: [
          // BMI Gauge
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(18)),
            child: Column(children: [
              AnimatedBuilder(
                animation: _needleAnim,
                builder: (_, __) => SizedBox(
                  height: 150,
                  child: CustomPaint(
                    size: const Size(double.infinity, 150),
                    painter: BMIGaugePainter(
                      bmiNormalized: _needleAngle * _needleAnim.value,
                      bmiColor: _bmiColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(_bmi.toStringAsFixed(1),
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: _bmiColor)),
              Text(_category,
                  style: TextStyle(fontSize: 18, color: _bmiColor, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text('Height: ${_height.toStringAsFixed(0)} cm  |  Weight: ${_weight.toStringAsFixed(1)} kg',
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ]),
          ),
          const SizedBox(height: 20),

          // Height slider
          _sliderCard('Height', _height, 100, 220, 'cm', (v) {
            setState(() {
              _height = v;
              widget.appData.heightCm = v;
            });
            _needleCtrl.reset();
            _needleCtrl.forward();
          }),
          const SizedBox(height: 12),

          // Weight slider
          _sliderCard('Weight', _weight, 30, 200, 'kg', (v) {
            setState(() => _weight = v);
            _needleCtrl.reset();
            _needleCtrl.forward();
          }),
          const SizedBox(height: 20),

          // BMI Scale
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('BMI Scale', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              _bmiScaleRow(Colors.blueAccent, 'Underweight', '< 18.5'),
              _bmiScaleRow(const Color(0xFF88FF00), 'Normal', '18.5 – 24.9'),
              _bmiScaleRow(Colors.orange, 'Overweight', '25.0 – 29.9'),
              _bmiScaleRow(Colors.red, 'Obese', '≥ 30.0'),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _sliderCard(String label, double value, double min, double max, String unit, ValueChanged<double> onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF2C2C2E), borderRadius: BorderRadius.circular(8)),
            child: Text('${value.toStringAsFixed(unit == 'cm' ? 0 : 1)} $unit',
                style: const TextStyle(color: Color(0xFF88FF00), fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ]),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF88FF00),
            inactiveTrackColor: const Color(0xFF3a3a3a),
            thumbColor: const Color(0xFF88FF00),
            overlayColor: const Color(0xFF88FF00).withOpacity(0.15),
            trackHeight: 4,
          ),
          child: Slider(value: value, min: min, max: max, divisions: ((max - min) * 2).toInt(), onChanged: onChanged),
        ),
      ]),
    );
  }

  Widget _bmiScaleRow(Color color, String label, String range) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))),
        Text(range, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════
//  SCREEN 4 — PROFILE
// ═══════════════════════════════════════════
class ProfileScreen extends StatefulWidget {
  final AppData appData;
  const ProfileScreen({super.key, required this.appData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final data = widget.appData;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Edit', style: TextStyle(color: Color(0xFF88FF00), fontSize: 13)),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: data,
        builder: (_, __) => SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(15),
          child: Column(children: [
            // Avatar
            Center(child: Column(children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF88FF00), Color(0xFF4C7D00)]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, color: Colors.black, size: 44),
              ),
              const SizedBox(height: 12),
              const Text('Fitness User', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const Text('Weight Loss Goal', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ])),
            const SizedBox(height: 24),

            // Stats summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(16)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _profileStat('Current', '${data.currentWeight.toStringAsFixed(1)} kg', const Color(0xFF88FF00)),
                _vDivider(),
                _profileStat('Goal', '${data.goalWeight.toStringAsFixed(1)} kg', Colors.orange),
                _vDivider(),
                _profileStat('BMI', data.bmi.toStringAsFixed(1), data.bmiColor),
              ]),
            ),
            const SizedBox(height: 16),

            // Goal settings
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Goal Settings', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                _settingRow('Target Weight', '${data.goalWeight.toStringAsFixed(1)} kg'),
                _settingRow('Height', '${data.heightCm.toStringAsFixed(0)} cm'),
                _settingRow('Records logged', '${data.records.length}'),
                _settingRow('Progress', '${(data.progressPercent * 100).toStringAsFixed(0)}%'),
              ]),
            ),
            const SizedBox(height: 16),

            // History list
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Weight History', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...data.records.reversed.take(7).map((r) => _historyRow(r)),
              ]),
            ),
            const SizedBox(height: 30),
          ]),
        ),
      ),
    );
  }

  Widget _profileStat(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
    ]);
  }

  Widget _vDivider() => Container(width: 1, height: 36, color: Colors.white12);

  Widget _settingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _historyRow(WeightRecord r) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: const Color(0xFF2C2C2E), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.monitor_weight_outlined, color: Color(0xFF88FF00), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${r.weight.toStringAsFixed(1)} kg', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          Text('Body fat: ${r.bodyFat.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ])),
        Text('${days[r.date.weekday - 1]}, ${r.date.day} ${months[r.date.month - 1]}',
            style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════
//  CUSTOM PAINTERS
// ═══════════════════════════════════════════

// Gauge Painter (Stay Fit Card)
class GaugePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
    final center = Offset(size.width / 2, size.height);

    final paint = Paint()
      ..shader = SweepGradient(
        colors: const [Colors.red, Colors.orange, Colors.yellow, Color(0xFF88FF00), Colors.teal],
        transform: const GradientRotation(math.pi),
      ).createShader(rect)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi, false, paint);

    // Tick marks
    final tickPaint = Paint()..color = Colors.white24..strokeWidth = 1.5..style = PaintingStyle.stroke;
    double innerR = size.width / 2 - 22;
    for (double i = math.pi; i <= math.pi * 2; i += 0.1) {
      canvas.drawLine(
        Offset(center.dx + innerR * math.cos(i), center.dy + innerR * math.sin(i)),
        Offset(center.dx + (innerR - 5) * math.cos(i), center.dy + (innerR - 5) * math.sin(i)),
        tickPaint,
      );
    }

    // Needle
    double needleAngle = math.pi + (math.pi * 0.15);
    double needleLen = innerR - 8;
    canvas.drawLine(
      center,
      Offset(center.dx + needleLen * math.cos(needleAngle), center.dy + needleLen * math.sin(needleAngle)),
      Paint()..color = Colors.white..strokeWidth = 3..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(CustomPainter old) => false;
}

// Mini inline chart for dashboard
class MiniChartPainter extends CustomPainter {
  final List<WeightRecord> records;
  MiniChartPainter({required this.records});

  @override
  void paint(Canvas canvas, Size size) {
    if (records.isEmpty) return;
    final weights = records.map((r) => r.weight).toList();
    final minW = weights.reduce(math.min) - 0.5;
    final maxW = weights.reduce(math.max) + 0.5;
    final range = maxW - minW;

    double xStep = size.width / (records.length - 1);

    Offset toOffset(int i) {
      double x = i * xStep;
      double y = size.height - ((weights[i] - minW) / range) * size.height;
      return Offset(x, y);
    }

    // Fill area
    final fillPath = Path();
    fillPath.moveTo(0, size.height);
    for (int i = 0; i < records.length; i++) fillPath.lineTo(toOffset(i).dx, toOffset(i).dy);
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF88FF00).withOpacity(0.3), const Color(0xFF88FF00).withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill);

    // Line
    final linePath = Path();
    linePath.moveTo(toOffset(0).dx, toOffset(0).dy);
    for (int i = 1; i < records.length; i++) linePath.lineTo(toOffset(i).dx, toOffset(i).dy);
    canvas.drawPath(linePath, Paint()
      ..color = const Color(0xFF88FF00)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);

    // Dots
    for (int i = 0; i < records.length; i++) {
      canvas.drawCircle(toOffset(i), 4, Paint()..color = const Color(0xFF88FF00));
      canvas.drawCircle(toOffset(i), 2.5, Paint()..color = const Color(0xFF0D0D0D));
    }
  }

  @override
  bool shouldRepaint(MiniChartPainter old) => old.records != records;
}

// Full animated chart for Charts screen
class FullChartPainter extends CustomPainter {
  final List<WeightRecord> records;
  final String chartType;
  final double progress;

  FullChartPainter({required this.records, required this.chartType, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (records.isEmpty) return;

    List<double> values = chartType == 'Body Fat'
        ? records.map((r) => r.bodyFat).toList()
        : chartType == 'BMI'
            ? records.map((r) => r.weight / ((170 / 100) * (170 / 100))).toList()
            : records.map((r) => r.weight).toList();

    final minV = values.reduce(math.min) - 0.5;
    final maxV = values.reduce(math.max) + 0.5;
    final range = maxV - minV;
    double xStep = size.width / (records.length - 1);

    Offset toOffset(int i) {
      double x = i * xStep;
      double y = size.height - ((values[i] - minV) / range) * (size.height - 20);
      return Offset(x, y + 10);
    }

    int visibleCount = (records.length * progress).ceil().clamp(2, records.length);

    // Grid lines
    final gridPaint = Paint()..color = Colors.white12..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      double y = (size.height / 4) * i + 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Y-axis labels
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i <= 4; i++) {
      double val = maxV - ((maxV - minV) / 4) * i;
      tp.text = TextSpan(text: val.toStringAsFixed(1), style: const TextStyle(color: Colors.white38, fontSize: 8));
      tp.layout();
      double y = (size.height / 4) * i + 5;
      tp.paint(canvas, Offset(0, y - 5));
    }

    // Fill
    final fillPath = Path();
    fillPath.moveTo(toOffset(0).dx, size.height);
    for (int i = 0; i < visibleCount; i++) fillPath.lineTo(toOffset(i).dx, toOffset(i).dy);
    fillPath.lineTo(toOffset(visibleCount - 1).dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF88FF00).withOpacity(0.25), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill);

    // Line
    final linePath = Path();
    linePath.moveTo(toOffset(0).dx, toOffset(0).dy);
    for (int i = 1; i < visibleCount; i++) linePath.lineTo(toOffset(i).dx, toOffset(i).dy);
    canvas.drawPath(linePath, Paint()
      ..color = const Color(0xFF88FF00)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);

    // Dots + value labels
    for (int i = 0; i < visibleCount; i++) {
      canvas.drawCircle(toOffset(i), 5, Paint()..color = const Color(0xFF88FF00));
      canvas.drawCircle(toOffset(i), 3, Paint()..color = const Color(0xFF1C1C1E));
      tp.text = TextSpan(text: values[i].toStringAsFixed(1), style: const TextStyle(color: Colors.white60, fontSize: 8));
      tp.layout();
      canvas.save();
      canvas.translate(toOffset(i).dx - tp.width / 2, toOffset(i).dy - 18);
      tp.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(FullChartPainter old) => old.progress != progress || old.chartType != chartType;
}

// BMI Gauge Painter
class BMIGaugePainter extends CustomPainter {
  final double bmiNormalized;
  final Color bmiColor;

  BMIGaugePainter({required this.bmiNormalized, required this.bmiColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.85);
    final radius = size.width * 0.38;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background arc
    canvas.drawArc(rect, math.pi, math.pi, false,
        Paint()..color = Colors.white12..strokeWidth = 18..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);

    // Colored segments
    final segments = [Colors.blueAccent, const Color(0xFF88FF00), Colors.orange, Colors.red];
    for (int i = 0; i < 4; i++) {
      canvas.drawArc(rect, math.pi + (math.pi / 4) * i, math.pi / 4 - 0.05, false,
          Paint()..color = segments[i].withOpacity(0.7)..strokeWidth = 18..style = PaintingStyle.stroke..strokeCap = StrokeCap.butt);
    }

    // Needle
    double angle = math.pi + (math.pi * bmiNormalized);
    double needleLen = radius - 10;
    canvas.drawLine(
      center,
      Offset(center.dx + needleLen * math.cos(angle), center.dy + needleLen * math.sin(angle)),
      Paint()..color = Colors.white..strokeWidth = 3..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 7, Paint()..color = bmiColor);
    canvas.drawCircle(center, 4, Paint()..color = Colors.white);

    // Labels
    final tp = TextPainter(textDirection: TextDirection.ltr);
    final labels = ['10', '18.5', '25', '30', '40'];
    for (int i = 0; i < 5; i++) {
      double a = math.pi + (math.pi / 4) * i;
      double labelR = radius + 18;
      tp.text = TextSpan(text: labels[i], style: const TextStyle(color: Colors.white38, fontSize: 9));
      tp.layout();
      tp.paint(canvas, Offset(center.dx + labelR * math.cos(a) - tp.width / 2, center.dy + labelR * math.sin(a) - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(BMIGaugePainter old) => old.bmiNormalized != bmiNormalized;
}
