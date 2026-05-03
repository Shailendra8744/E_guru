import 'dart:async';
import 'package:flutter/material.dart';

class StudyTimerCard extends StatefulWidget {
  final bool isDark;
  const StudyTimerCard({super.key, required this.isDark});

  @override
  State<StudyTimerCard> createState() => _StudyTimerCardState();
}

class _StudyTimerCardState extends State<StudyTimerCard> {
  int _secondsRemaining = 25 * 60; // 25 minutes default
  Timer? _timer;
  bool _isRunning = false;
  int _totalSeconds = 25 * 60;

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _timer?.cancel();
            _isRunning = false;
            _showCompleteDialog();
          }
        });
      });
    }
    setState(() {
      _isRunning = !_isRunning;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _secondsRemaining = _totalSeconds;
    });
  }

  void _updateDuration(int minutes) {
    if (_isRunning) return;
    setState(() {
      _totalSeconds = minutes * 60;
      _secondsRemaining = _totalSeconds;
    });
  }

  void _showSettings() {
    if (_isRunning) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pause the timer to change duration')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Set Study Duration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [15, 25, 45, 60].map((m) {
                final isSelected = _totalSeconds == m * 60;
                return ChoiceChip(
                  label: Text('$m min'),
                  selected: isSelected,
                  onSelected: (v) {
                    if (v) {
                      _updateDuration(m);
                      Navigator.pop(context);
                    }
                  },
                  selectedColor: Colors.purple.withAlpha(50),
                  labelStyle: TextStyle(color: isSelected ? Colors.purple : null, fontWeight: isSelected ? FontWeight.bold : null),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Great Job!'),
        content: const Text('You completed a study session. Time for a short break!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _secondsRemaining / _totalSeconds;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isDark 
            ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
            : [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.purple.withAlpha(widget.isDark ? 30 : 50)),
        boxShadow: widget.isDark ? [] : [
          BoxShadow(color: Colors.purple.withAlpha(20), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              onPressed: _showSettings,
              icon: Icon(Icons.settings_outlined, size: 20, color: widget.isDark ? Colors.white60 : Colors.purple.shade700),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: Colors.purple.withAlpha(30),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
                    ),
                  ),
                  Text(
                    _formatTime(_secondsRemaining),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: widget.isDark ? Colors.purple.shade200 : Colors.purple.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Study Focus',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: widget.isDark ? Colors.white : Colors.purple.shade900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Goal: ${_totalSeconds ~/ 60} mins focus',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDark ? Colors.white70 : Colors.purple.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _toggleTimer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            elevation: 0,
                          ),
                          child: Text(_isRunning ? 'Pause' : 'Start'),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _resetTimer,
                          icon: const Icon(Icons.refresh_rounded, color: Colors.purple),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.purple.withAlpha(20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
