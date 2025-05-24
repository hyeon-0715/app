import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'recipe_page.dart';
import 'user_page.dart';
import 'user_recipe_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  late List<Widget?> _pages;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _pages = List<Widget?>.filled(3, null);
    _pages[0] = const MainContent();
  }

  Widget _getPage(int index) {
    if (_pages[index] == null) {
      print('Initializing page for index: $index');
      switch (index) {
        case 0:
          _pages[index] = const MainContent();
          break;
        case 1:
          _pages[index] = const RecipePage();
          break;
        case 2:
          _pages[index] = const UserPage();
          break;
      }
    }
    return _pages[index]!;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleBottomNavTap(int index) {
    print('Tapped index: $index');
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    print('Building MainPage...');
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const double baseWidth = 1080;
    const double baseHeight = 2400;
    final widthRatio = screenWidth / baseWidth;
    final heightRatio = screenHeight / baseHeight;

    return WillPopScope(
      onWillPop: () async {
        if (_navigatorKey.currentState!.canPop()) {
          _navigatorKey.currentState!.pop();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: Navigator(
          key: _navigatorKey,
          onGenerateRoute: (settings) {
            print('Generating route for IndexedStack with index: $_selectedIndex');
            return MaterialPageRoute(
              builder: (context) {
                try {
                  return IndexedStack(
                    index: _selectedIndex,
                    children: List.generate(_pages.length, (index) => _getPage(index)),
                  );
                } catch (e) {
                  print('Error building IndexedStack: $e');
                  return const Center(child: Text('Error loading page'));
                }
              },
            );
          },
        ),
        bottomNavigationBar: Container(
          width: screenWidth,
          height: 100 * heightRatio,
          color: Colors.grey[200],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () => _handleBottomNavTap(0),
                icon: Image.asset(
                  'assets/images/home.png',
                  width: 60 * widthRatio,
                  height: 60 * heightRatio,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading home.png: $error');
                    return const Icon(Icons.error);
                  },
                ),
              ),
              IconButton(
                onPressed: () => _handleBottomNavTap(1),
                icon: Image.asset(
                  'assets/images/cabbage.png',
                  width: 60 * widthRatio,
                  height: 60 * heightRatio,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading cabbage.png: $error');
                    return const Icon(Icons.error);
                  },
                ),
              ),
              IconButton(
                onPressed: () => _handleBottomNavTap(2),
                icon: Image.asset(
                  'assets/images/user.png',
                  width: 60 * widthRatio,
                  height: 60 * heightRatio,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading user.png: $error');
                    return const Icon(Icons.error);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainContent extends StatelessWidget {
  const MainContent({super.key});

  @override
  Widget build(BuildContext context) {
    print('Building MainContent...');
    return OrientationBuilder(
      builder: (context, orientation) {
        print('Orientation in MainContent: $orientation');
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        const double baseWidth = 1080;
        const double baseHeight = 2400;
        final widthRatio = screenWidth / baseWidth;
        final heightRatio = screenHeight / baseHeight;

        return orientation == Orientation.portrait
            ? _buildPortraitLayout(widthRatio, heightRatio, screenWidth, screenHeight, context)
            : _buildLandscapeLayout(widthRatio, heightRatio, screenWidth, screenHeight, context);
      },
    );
  }

  Widget _buildPortraitLayout(double widthRatio, double heightRatio, double screenWidth, double screenHeight, BuildContext context) {
    print('Rendering portrait layout in MainContent...');
    return Column(
      children: [
        Container(
          width: screenWidth,
          height: 60 * heightRatio,
          color: Colors.grey[800],
          child: Center(
            child: Text(
              'ㅁ',
              style: TextStyle(
                fontSize: 24 * widthRatio,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Container(
          width: screenWidth,
          height: 600 * heightRatio,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/kimchiback.png'),
              fit: BoxFit.cover,
              opacity: 0.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(255, 255, 243, 223),
                Color.fromARGB(255, 189, 180, 165),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 60 * widthRatio,
              top: 60 * heightRatio,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kimchida',
                  style: TextStyle(
                    fontSize: 90 * widthRatio,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    shadows: const [
                      Shadow(
                        color: Colors.white,
                        offset: Offset(2, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20 * heightRatio),
                Text(
                  '',
                  style: TextStyle(
                    fontSize: 30 * widthRatio,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: MenuSection(
            widthRatio: widthRatio,
            heightRatio: heightRatio,
            screenWidth: screenWidth,
            onNavigateToRecipePage: () {
              (context.findAncestorStateOfType<_MainPageState>())?._handleBottomNavTap(1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(double widthRatio, double heightRatio, double screenWidth, double screenHeight, BuildContext context) {
    print('Rendering landscape layout in MainContent...');
    return Row(
      children: [
        RotatedBox(
          quarterTurns: 3,
          child: Container(
            width: screenHeight,
            height: 180 * heightRatio,
            color: Colors.grey[800],
            child: Center(
              child: Text(
                'ㅁ',
                style: TextStyle(
                  fontSize: 24 * widthRatio,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Container(
                width: screenWidth,
                height: 600 * heightRatio,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/kimchiback.png'),
                    fit: BoxFit.cover,
                    opacity: 0.5,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromARGB(255, 255, 243, 223),
                      Color.fromARGB(255, 189, 180, 165),
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 60 * widthRatio,
                    top: 60 * heightRatio,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kimchida',
                        style: TextStyle(
                          fontSize: 60 * widthRatio,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          shadows: const [
                            Shadow(
                              color: Colors.white,
                              offset: Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20 * heightRatio),
                      Text(
                        '',
                        style: TextStyle(
                          fontSize: 30 * widthRatio,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: const Color(0xFFF5E9D6),
                  child: MenuSection(
                    widthRatio: widthRatio,
                    heightRatio: heightRatio,
                    screenWidth: screenWidth,
                    onNavigateToRecipePage: () {
                      (context.findAncestorStateOfType<_MainPageState>())?._handleBottomNavTap(1);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MenuSection extends StatefulWidget {
  final double widthRatio;
  final double heightRatio;
  final double screenWidth;
  final VoidCallback onNavigateToRecipePage;

  const MenuSection({
    super.key,
    required this.widthRatio,
    required this.heightRatio,
    required this.screenWidth,
    required this.onNavigateToRecipePage,
  });

  @override
  _MenuSectionState createState() => _MenuSectionState();
}

class _MenuSectionState extends State<MenuSection> {
  // 세로 모드 조정 변수 ("레시피 직접 만들기" 섹션)
  double portraitButtonWidth = 400;
  double portraitButtonHeight = 300;
  double portraitImageWidth = 150;
  double portraitImageHeight = 150;
  double portraitSpacing = 30;

  // 가로 모드 조정 변수 ("레시피 직접 만들기" 섹션)
  double landscapeButtonWidth = 300; // 버튼 너비 조정
  double landscapeButtonHeight = 300;
  double landscapeImageWidth = 150;
  double landscapeImageHeight = 150;
  double landscapeSpacing = 20; // 간격 조정

  // 세로 모드 조정 변수 ("레시피 둘러보기" 섹션)
  double portraitBrowseImageWidth = 200;
  double portraitBrowseImageHeight = 400;
  double portraitBrowseButtonWidth = 400;
  double portraitBrowseButtonHeight = 500;
  double portraitBrowseSpacing = 20;
  double portraitDividerHeight = 800;

  // 가로 모드 조정 변수 ("레시피 둘러보기" 섹션)
  double landscapeBrowseImageWidth = 200;
  double landscapeBrowseImageHeight = 200;
  double landscapeBrowseButtonWidth = 400;
  double landscapeBrowseButtonHeight = 300;
  double landscapeBrowseSpacing = 20;
  double landscapeDividerHeight = 400;

  @override
  Widget build(BuildContext context) {
    print('Building MenuSection...');
    return OrientationBuilder(
      builder: (context, orientation) {
        print('Orientation in MenuSection: $orientation');
        return orientation == Orientation.portrait
            ? _buildPortraitLayout(widget.widthRatio, widget.heightRatio, widget.screenWidth, context)
            : _buildLandscapeLayout(widget.widthRatio, widget.heightRatio, widget.screenWidth, context);
      },
    );
  }

  // 세로 모드 레이아웃 빌드 (MenuSection)
  Widget _buildPortraitLayout(double widthRatio, double heightRatio, double screenWidth, BuildContext context) {
    print('Rendering portrait layout in MenuSection...');
    print('Portrait "레시피 직접 만들기" button size: ${portraitButtonWidth * widthRatio}x${portraitButtonHeight * heightRatio}');
    print('Portrait "레시피 둘러보기" button size: ${portraitBrowseButtonWidth * widthRatio}x${portraitBrowseButtonHeight * heightRatio}');
    return Container(
      width: screenWidth,
      color: const Color(0xFFF5E9D6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: 60 * widthRatio,
              top: 60 * heightRatio,
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                fontSize: 90 * widthRatio,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(height: 300 * heightRatio),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 60 * widthRatio),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '레시피 직접 만들기',
                        style: TextStyle(
                          fontSize: 50 * widthRatio,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: portraitSpacing * heightRatio),
                      IconButton(
                        onPressed: () {
                          print('Navigating to UserRecipePage (photo)...');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserRecipePage(inputMode: 'photo'),
                            ),
                          );
                        },
                        visualDensity: VisualDensity(
                          horizontal: -4,
                          vertical: -4,
                        ),
                        icon: Container(
                          width: portraitButtonWidth * widthRatio,
                          height: portraitButtonHeight * heightRatio,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5E9D6),
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/images/photo.png',
                              width: portraitImageWidth * widthRatio,
                              height: portraitImageHeight * heightRatio,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading photo.png: $error');
                                return const Text(
                                  '이미지를 로드할 수 없습니다.',
                                  style: TextStyle(color: Colors.red),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: portraitSpacing * heightRatio),
                      IconButton(
                        onPressed: () {
                          print('Navigating to UserRecipePage (text)...');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserRecipePage(inputMode: 'text'),
                            ),
                          );
                        },
                        visualDensity: VisualDensity(
                          horizontal: -4,
                          vertical: -4,
                        ),
                        icon: Container(
                          width: portraitButtonWidth * widthRatio,
                          height: portraitButtonHeight * heightRatio,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5E9D6),
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/images/text.png',
                              width: portraitImageWidth * widthRatio,
                              height: portraitImageHeight * heightRatio,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading text.png: $error');
                                return const Icon(Icons.error);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 5 * widthRatio,
                  height: portraitDividerHeight * heightRatio,
                  color: Colors.black,
                  margin: EdgeInsets.symmetric(horizontal: 30 * widthRatio),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '레시피 둘러보기',
                        style: TextStyle(
                          fontSize: 50 * widthRatio,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: portraitSpacing * heightRatio),
                      IconButton(
                        onPressed: widget.onNavigateToRecipePage,
                        visualDensity: VisualDensity(
                          horizontal: -4,
                          vertical: -4,
                        ),
                        icon: Container(
                          width: portraitBrowseButtonWidth * widthRatio,
                          height: 220,
                          padding: EdgeInsets.all(10 * widthRatio),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5E9D6),
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/images/recipe.png',
                              width: portraitBrowseImageWidth * widthRatio,
                              height: portraitBrowseImageHeight * heightRatio,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading recipe.png in portrait mode: $error');
                                return const Icon(Icons.error);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 가로 모드 레이아웃 빌드 (MenuSection)
  Widget _buildLandscapeLayout(double widthRatio, double heightRatio, double screenWidth, BuildContext context) {
    print('Rendering landscape layout in MenuSection...');
    print('Landscape "레시피 직접 만들기" button size: ${landscapeButtonWidth * widthRatio}x${landscapeButtonHeight * heightRatio}');
    print('Landscape "레시피 둘러보기" button size: ${landscapeBrowseButtonWidth * widthRatio}x${landscapeBrowseButtonHeight * heightRatio}');
    return Container(
      width: screenWidth,
      color: const Color(0xFFF5E9D6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: 60 * widthRatio,
              top: 60 * heightRatio,
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                fontSize: 40 * widthRatio,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(height: 180 * heightRatio),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 60 * widthRatio),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '레시피 직접 만들기',
                          style: TextStyle(
                            fontSize: 36 * widthRatio,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: IconButton(
                                onPressed: () {
                                  print('Navigating to UserRecipePage (photo)...');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const UserRecipePage(inputMode: 'photo'),
                                    ),
                                  );
                                },
                                visualDensity: VisualDensity(
                                  horizontal: -4,
                                  vertical: -4,
                                ),
                                icon: Container(
                                  width: landscapeButtonWidth * widthRatio,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5E9D6),
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 8,
                                        offset: Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      'assets/images/photo.png',
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        print('Error loading photo.png: $error');
                                        return const Text(
                                          '이미지를 로드할 수 없습니다.',
                                          style: TextStyle(color: Colors.red),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: landscapeSpacing * widthRatio),
                            Expanded(
                              child: IconButton(
                                onPressed: () {
                                  print('Navigating to UserRecipePage (text)...');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const UserRecipePage(inputMode: 'text'),
                                    ),
                                  );
                                },
                                visualDensity: VisualDensity(
                                  horizontal: -4,
                                  vertical: -4,
                                ),
                                icon: Container(
                                  width: landscapeButtonWidth * widthRatio,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5E9D6),
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 8,
                                        offset: Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      'assets/images/text.png',
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        print('Error loading text.png: $error');
                                        return const Icon(Icons.error);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 5 * widthRatio,
                    height: 180,
                    color: Colors.black,
                    margin: EdgeInsets.symmetric(horizontal: landscapeSpacing * widthRatio),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '레시피 둘러보기',
                          style: TextStyle(
                            fontSize: 36 * widthRatio,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 20),
                        IconButton(
                          onPressed: widget.onNavigateToRecipePage,
                          visualDensity: VisualDensity(
                            horizontal: -4,
                            vertical: -4,
                          ),
                          icon: Container(
                            width: 200,
                            height: 120,
                            padding: EdgeInsets.all(10 * widthRatio),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5E9D6),
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/images/recipe.png',
                                width: 80,
                                height: 80,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error loading recipe.png in landscape mode: $error');
                                  return const Icon(Icons.error);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}