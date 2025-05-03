import 'package:flutter/material.dart';
import 'dart:async';
import 'RoleSelectionScreen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _outerCircleOpacity;
  late Animation<double> _middleCircleOpacity;
  late Animation<double> _innerCircleOpacity;
  late Animation<double> _outerCircleSize;
  late Animation<double> _middleCircleSize;
  late Animation<double> _innerCircleSize;
  
  List<bool> _dotVisibility = [true, false, false, false, false];
  int _currentDotIndex = 0;
  Timer? _dotTimer;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller for the circles
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    
    // Create animations for opacity (to make them appear sequentially)
    _innerCircleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );
    
    _middleCircleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 0.5, curve: Curves.easeIn),
      ),
    );
    
    _outerCircleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.4, 0.7, curve: Curves.easeIn),
      ),
    );
    
    // Create animations for size (all start small and grow)
    _innerCircleSize = Tween<double>(begin: 10.0, end: 120.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    _middleCircleSize = Tween<double>(begin: 10.0, end: 160.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );
    
    _outerCircleSize = Tween<double>(begin: 10.0, end: 200.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.4, 0.9, curve: Curves.easeOut),
      ),
    );

    // Start the animation and set up the loop
    _animationController.forward();
    
    // Set up continuous pulse after initial expansion
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Start a subtle pulse animation
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            _animationController.reset();
            _animationController.forward();
          }
        });
      }
    });
    
    // Setup dots animation
    _dotTimer = Timer.periodic(Duration(milliseconds: 300), (timer) {
      if (mounted) {
        setState(() {
          // Reset all dots
          _dotVisibility = List.generate(5, (_) => false);
          
          // Make the current dot visible
          _dotVisibility[_currentDotIndex] = true;
          
          // Move to next dot
          _currentDotIndex = (_currentDotIndex + 1) % 5;
        });
      }
    });
    
    // Navigate to next screen after delay
    Timer(Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => CombinedRoleLoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _dotTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 6, 63, 1),
      body: SafeArea(
        child: Column(
          children: [
            // Status bar placeholder
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    " ",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  Row(),
                ],
              ),
            ),
            
            // Fixed size container for animations to prevent layout shifts
            Expanded(
              flex: 3,
              child: Center(
                child: Container(
                  width: 200, // Set fixed width for animation container
                  height: 200, // Set fixed height for animation container
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Animated builder for circles
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer circle with size and opacity animation
                              Opacity(
                                opacity: _outerCircleOpacity.value,
                                child: Container(
                                  width: _outerCircleSize.value,
                                  height: _outerCircleSize.value,
                                  decoration: BoxDecoration(
                                    color: Color.fromARGB(255, 250, 115, 4).withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              // Middle circle with size and opacity animation
                              Opacity(
                                opacity: _middleCircleOpacity.value,
                                child: Container(
                                  width: _middleCircleSize.value,
                                  height: _middleCircleSize.value,
                                  decoration: BoxDecoration(
                                    color: Color.fromARGB(255, 250, 115, 4).withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              // Inner circle with size and opacity animation
                              Opacity(
                                opacity: _innerCircleOpacity.value,
                                child: Container(
                                  width: _innerCircleSize.value,
                                  height: _innerCircleSize.value,
                                  decoration: BoxDecoration(
                                    color: Color.fromARGB(255, 250, 115, 4),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              // Center white circle with icon (fixed)
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.school,
                                    color: Color.fromARGB(242, 235, 86, 0),
                                    size: 40,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Fixed space for text content
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  // Study text
                  Text(
                    "Study",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  
                  SizedBox(height: 5),
                  
                  // Subtitle
                  Text(
                    "The Complete Learning Solutions",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            
            // Fixed bottom section for dots
            Container(
              height: 80,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Row(
                      children: [
                        _buildDot(_dotVisibility[index]),
                        index < 4 ? SizedBox(width: 8) : SizedBox(),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Loading dot with animation
  Widget _buildDot(bool isActive) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
    );
  }
}