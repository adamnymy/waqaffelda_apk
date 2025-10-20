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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Zikir',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
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
                color: const Color(0xFFFFF4E6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    _currentZikir,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                      fontFamily: 'Arabic',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentZikirTranslation,
                    style: TextStyle(fontSize: 14, color: Colors.orange[700]),
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
                        color: Colors.grey[200],
                      ),
                      child: Center(
                        child: Text(
                          _counter.toString(),
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
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
                          Colors.green[700]!,
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
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildZikirButton(
                          'Alhamdulillah',
                          'ٱلْحَمْدُ لِلّٰهِ',
                          'Segala puji bagi Allah',
                          const Color(0xFFFFF4E6),
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
                          const Color(0xFFFFF4E6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildZikirButton(
                          'La ilaha illallah',
                          'لَا إِلٰهَ إِلَّا ٱللّٰهُ',
                          'Tiada Tuhan melainkan Allah',
                          const Color(0xFFFFF4E6),
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
          color: isSelected ? Colors.green[600] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          value.toString(),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
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
    Color bgColor,
  ) {
    return GestureDetector(
      onTap: () => _selectZikir(arabic, translation),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: bgColor == Colors.green ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
