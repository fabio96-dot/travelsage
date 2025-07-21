import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_background/animated_background.dart';
import 'package:travel_sage/main.dart';

// Provider per messaggi di caricamento
final loadingMessagesProvider = Provider<List<String>>((ref) => const [
  'Stiamo preparando la tua avventura...',
  'Caricamento destinazioni...',
  'Accendiamo la bussola...',
  'Controllo del meteo...',
  'Impostazione del budget...',
  'Verifica bagagli virtuali...',
  'Pronto a partire!',
]);

final currentMessageIndexProvider = StateProvider<int>((ref) => 0);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<Color?> _colorShift;

  late AnimationController _exitController;
  late Animation<double> _fadeOut;
  late Animation<double> _slideUp;

  late AnimationController _messageController;
  late Animation<double> _messageFade;

  Timer? _messageTimer;
  bool _isTransitioning = false;


  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeIn = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeInOutCubic,
    );

    _scaleIn = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOutBack,
      ),
    );

    _colorShift = ColorTween(
      begin: const Color(0xFF3EC8F6),
      end: const Color(0xFF6D5DF6),
    ).animate(_entryController);

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeInOut,
      ),
    );

    _slideUp = Tween<double>(begin: 0.0, end: -0.1).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeIn,
      ),
    );

    _messageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _messageFade = CurvedAnimation(
      parent: _messageController,
      curve: Curves.easeInOut,
    );

    _entryController.forward();
    _messageController.forward();

    _startMessageCycle();
    _startExitTimer();

  }

  void _startMessageCycle() {
    final messages = ref.read(loadingMessagesProvider);
    _messageTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _messageController.reverse().then((_) {
        if (mounted && !_isTransitioning) {
          final currentIndex = ref.read(currentMessageIndexProvider);
          final nextIndex = (currentIndex + 1) % messages.length;
          ref.read(currentMessageIndexProvider.notifier).state = nextIndex;
          _messageController.forward();
        }
      });
    });
  }

  void _startExitTimer() {
    Future.delayed(const Duration(seconds: 3), () async {
      if (mounted) {
        setState(() {
          _isTransitioning = true;
        });
        await _exitController.forward();
        _navigateToNextScreen();
      }
    });
  }

  void _navigateToNextScreen() {
    final route = PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const TravelSageApp(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.fastOutSlowIn,
            )),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 1000),
    );

    Navigator.of(globalNavigatorKey.currentContext!).pushReplacement(route);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _exitController.dispose();
    _messageController.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  double _calculateLogoSize(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    if (shortestSide > 600) return 250;
    if (shortestSide > 400) return 180;
    return 140;
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = _calculateLogoSize(context);
    final screenHeight = MediaQuery.of(context).size.height;

    final currentMessageIndex = ref.watch(currentMessageIndexProvider);
    final messages = ref.watch(loadingMessagesProvider);

    return AnimatedBuilder(
      animation: Listenable.merge([_entryController, _exitController]),
      builder: (context, child) {
        return Scaffold(
          body: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _colorShift.value ?? const Color(0xFF3EC8F6),
                      const Color(0xFF6D5DF6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              AnimatedBackground(
                behaviour: RandomParticleBehaviour(
                  options: ParticleOptions(
                    baseColor: Colors.white.withOpacity(0.2),
                    spawnOpacity: 0.0,
                    opacityChangeRate: 0.25,
                    minOpacity: 0.1,
                    maxOpacity: 0.4,
                    spawnMinSpeed: 30.0,
                    spawnMaxSpeed: 70.0,
                    particleCount: 40,
                    spawnMaxRadius: 30.0,
                    spawnMinRadius: 10.0,
                  ),
                ),
                vsync: this,
                child: Container(),
              ),
              Transform.translate(
                offset: Offset(0, _slideUp.value * screenHeight),
                child: Opacity(
                  opacity: _fadeOut.value,
                  child: Center(
                    child: FadeTransition(
                      opacity: _fadeIn,
                      child: ScaleTransition(
                        scale: _scaleIn,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              Container(
                                width: logoSize * 1.5,
                                height: logoSize * 1.5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.4),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/Travelsage.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 40),
                            SizedBox(
                              width: logoSize * 0.4,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),

                            const SizedBox(height: 40),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.1),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: Text(
                                messages[currentMessageIndex],
                                key: ValueKey(messages[currentMessageIndex]),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10,
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(1, 1),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

