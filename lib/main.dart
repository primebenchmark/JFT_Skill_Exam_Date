import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JFT & Skill Exam Date',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const CountdownPage(),
    );
  }
}

class CountdownPage extends StatefulWidget {
  const CountdownPage({super.key});

  @override
  State<CountdownPage> createState() => _CountdownPageState();
}

class _CountdownPageState extends State<CountdownPage>
    with TickerProviderStateMixin {
  // Target date — 2-month window starts 60 days before this
  DateTime _targetDate = DateTime(2026, 4, 7);
  late Timer _timer;
  Duration _remaining = Duration.zero;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  StreamSubscription<DocumentSnapshot>? _firestoreSub;

  @override
  void initState() {
    super.initState();
    _listenToExamDate();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _listenToExamDate() {
    _firestoreSub = FirebaseFirestore.instance
        .collection('config')
        .doc('examDate')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        final ts = data['date'] as Timestamp?;
        if (ts != null) {
          setState(() {
            _targetDate = ts.toDate();
          });
          _updateRemaining();
        }
      }
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    setState(() {
      _remaining = _targetDate.difference(now);
      if (_remaining.isNegative) _remaining = Duration.zero;
    });
  }

  Future<void> _pickNewDate() async {
    final authorized = await _showPinDialog();
    if (!authorized) return;

    // Wait for keyboard & dialog animations to fully settle
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate.isAfter(now) ? _targetDate : now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: DateTime(2030),
      helpText: 'Set New Exam Date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFB71C1C),
              onPrimary: Colors.white,
              surface: Color(0xFF2E2E2E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (!mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_targetDate),
        helpText: 'Set Exam Time',
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFFB71C1C),
                onPrimary: Colors.white,
                surface: Color(0xFF2E2E2E),
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );
      if (pickedTime == null) return;
      final dateTime = DateTime(
        picked.year, picked.month, picked.day,
        pickedTime.hour, pickedTime.minute,
      );
      await FirebaseFirestore.instance
          .collection('config')
          .doc('examDate')
          .set({'date': Timestamp.fromDate(dateTime)});
    }
  }

  Future<bool> _showPinDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PinDialog(),
    );
    return result == true;
  }

  bool get _isExpired => _remaining == Duration.zero && DateTime.now().isAfter(_targetDate);

  /// Progress within a 2-month (60-day) window ending on _targetDate.
  double get _progress {
    final windowStart = _targetDate.subtract(const Duration(days: 60));
    final now = DateTime.now();
    if (now.isBefore(windowStart)) return 0.0;
    if (now.isAfter(_targetDate)) return 1.0;
    final elapsed = now.difference(windowStart).inSeconds;
    final total = _targetDate.difference(windowStart).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  String _formatTargetDate() {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '(${months[_targetDate.month]} ${_targetDate.day}, ${_targetDate.year})';
  }

  @override
  void dispose() {
    _firestoreSub?.cancel();
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8B1A1A),
              Color(0xFFB71C1C),
              Color(0xFF880E0E),
              Color(0xFF4A0000),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Calendar icon with tap to change date
                GestureDetector(
                  onTap: _pickNewDate,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _isExpired ? 1.0 : _pulseAnimation.value,
                        child: child,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isExpired
                            ? Colors.white.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: _isExpired
                            ? Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5)
                            : null,
                      ),
                      child: Icon(
                        _isExpired ? Icons.edit_calendar_rounded : Icons.calendar_today_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_isExpired)
                  Text(
                    'Tap to set new date',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                const SizedBox(height: 16),
                // Title
                const Text(
                  'Next JFT & Skill Exam Date',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTargetDate(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (!_isExpired) ...[
                  const SizedBox(height: 48),
                  // Countdown boxes
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(child: _CountdownUnit(value: days, label: 'DAYS')),
                        _buildSeparator(),
                        Expanded(child: _CountdownUnit(value: hours, label: 'HOURS')),
                        _buildSeparator(),
                        Expanded(child: _CountdownUnit(value: minutes, label: 'MINS')),
                        _buildSeparator(),
                        Expanded(child: _CountdownUnit(value: seconds, label: 'SECS')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Progress indicator (2-month window)
                  _buildProgressBar(),
                ],
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickNewDate,
        backgroundColor: const Color(0xFF8B1A1A),
        foregroundColor: Colors.white,
        tooltip: 'Change exam date',
        child: const Icon(Icons.edit_calendar_rounded),
      ),
    );
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final p = _progress;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: p,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFCDD2)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(p * 100).round()}%',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownUnit extends StatelessWidget {
  final int value;
  final String label;

  const _CountdownUnit({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 85,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2E2E2E), Color(0xFF1A1A1A)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.05),
                blurRadius: 1,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Container(
                  height: 1,
                  color: Colors.black.withValues(alpha: 0.4),
                ),
              ),
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    value.toString().padLeft(2, '0'),
                    key: ValueKey<int>(value),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _PinDialog extends StatefulWidget {
  const _PinDialog();

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _controller = TextEditingController();
  String _error = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text == '9963') {
      FocusScope.of(context).unfocus();
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'Incorrect PIN');
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2E2E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.lock_rounded, color: Color(0xFFFFCDD2), size: 20),
          SizedBox(width: 8),
          Text('Admin Access', style: TextStyle(color: Colors.white, fontSize: 18)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Enter PIN to change the exam date',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            autofocus: true,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 12),
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                letterSpacing: 12,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFB71C1C), width: 1.5),
              ),
              errorText: _error.isEmpty ? null : _error,
              errorStyle: const TextStyle(color: Color(0xFFFF8A80)),
            ),
            onChanged: (_) {
              if (_error.isNotEmpty) setState(() => _error = '');
            },
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB71C1C)),
          onPressed: _submit,
          child: const Text('Unlock'),
        ),
      ],
    );
  }
}
