import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ZikirCounterPage extends StatefulWidget {
  const ZikirCounterPage({Key? key}) : super(key: key);

  @override
  State<ZikirCounterPage> createState() => _ZikirCounterPageState();
}

class _ZikirCounterPageState extends State<ZikirCounterPage>
    with TickerProviderStateMixin {
  int _counter = 0;
  int _target = 33;
  String _currentZikir = 'سُبْحَانَ اللّٰهِ';
  String _currentZikirTranslation = 'Maha suci Allah';

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _updateProgress();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _incrementCounter() {
    HapticFeedback.vibrate();
    HapticFeedback.lightImpact();
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    setState(() {
      _counter++;
    });
    _updateProgress();

    if (_counter == _target) {
      _showCompletionDialog();
    }
  }

  void _selectZikir(String zikir, String translation) {
    setState(() {
      _currentZikir = zikir;
      _currentZikirTranslation = translation;
      _counter = 0;
    });
    _updateProgress();
  }

  void _updateProgress() {
    double progress = _target > 0 ? _counter / _target : 0.0;
    if (progress > 1.0) progress = 1.0;
    _progressController.animateTo(progress);
  }

  void _resetCounter() {
    setState(() {
      _counter = 0;
    });
    _updateProgress();
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Kiraan?'),
          content: const Text(
            'Adakah anda pasti mahu menetapkan semula kiraan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetCounter();
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  void _showCompletionDialog() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🎉 Tahniah!'),
          content: Text('Anda telah mencapai sasaran $_target zikir!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetCounter();
              },
              child: const Text('Mula Semula'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Teruskan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Zikir',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Arabic Text Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    _currentZikir,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                      fontFamily: 'Arabic',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentZikirTranslation,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Target Selection Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTargetChip(33),
                  _buildTargetChip(100),
                  _buildTargetChip(500),
                  _buildTargetChip(1000),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Counter Circle
            GestureDetector(
              onTap: _incrementCounter,
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary.withOpacity(0.1),
                        border: Border.all(
                          color: colorScheme.primary,
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _counter.toString(),
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Reset Button
            ElevatedButton(
              onPressed: _counter > 0 ? _confirmReset : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Set semula'),
            ),

            const SizedBox(height: 20),

            // Progress Text
            Text(
              '$_counter/$_target',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),

            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Column(
                    children: [
                      LinearProgressIndicator(
                        value: _progressAnimation.value,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary,
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${((_counter / _target) * 100).toInt()}% Selesai',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            // Zikir Quick Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildZikirButton(
                          'Subhanallah',
                          'سُبْحَانَ اللّٰهِ',
                          'Maha suci Allah',
                          colorScheme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildZikirButton(
                          'Alhamdulillah',
                          'ٱلْحَمْدُ لِلّٰهِ',
                          'Segala puji bagi Allah',
                          colorScheme,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildZikirButton(
                          'Allahu Akbar',
                          'ٱللّٰهُ أَكْبَرُ',
                          'Allah Maha Besar',
                          colorScheme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildZikirButton(
                          'La ilaha illallah',
                          'لَا إِلٰهَ إِلَّا ٱللّٰهُ',
                          'Tiada Tuhan melainkan Allah',
                          colorScheme,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetChip(int value) {
    final colorScheme = Theme.of(context).colorScheme;
    bool isSelected = value == _target;
    return GestureDetector(
      onTap: () {
        setState(() {
          _target = value;
        });
        _updateProgress();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          value.toString(),
          style: TextStyle(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildZikirButton(
    String label,
    String arabic,
    String translation,
    ColorScheme colorScheme,
  ) {
    bool isSelected = _currentZikir == arabic;
    return GestureDetector(
      onTap: () => _selectZikir(arabic, translation),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? colorScheme.primary
                  : colorScheme.secondary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
