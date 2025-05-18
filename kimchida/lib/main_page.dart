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

  // _pages를 List<Widget?>로 선언하여 동적 초기화 가능하도록 수정
  late List<Widget?> _pages;

  @override
  void initState() {
    super.initState();
    // 세로 모드 고정
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // _pages 리스트 초기화 (처음에는 null로 설정)
    _pages = List<Widget?>.filled(3, null);
    // 첫 번째 탭(MainContent)만 즉시 초기화
    _pages[0] = const MainContent();
  }

  // 탭 전환 시 해당 페이지 동적 생성
  Widget _getPage(int index) {
    if (_pages[index] == null) {
      print('Initializing page for index: $index'); // 디버깅 로그 추가
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
    print('Tapped index: $index'); // 디버깅 로그 추가
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    print('Building MainPage...'); // 디버깅 로그 추가
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
            print('Generating route for IndexedStack with index: $_selectedIndex'); // 디버깅 로그 추가
            return MaterialPageRoute(
              builder: (context) {
                try {
                  return IndexedStack(
                    index: _selectedIndex,
                    children: List.generate(_pages.length, (index) => _getPage(index)),
                  );
                } catch (e) {
                  print('Error building IndexedStack: $e'); // 디버깅 로그 추가
                  return const Center(child: Text('Error loading page'));
                }
              },
            );
          },
        ),
        // 하단바: 탭 내비게이션을 위한 하단바, 페이지 전환 아이콘 버튼 포함
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
                    print('Error loading home.png: $error'); // 디버깅 로그 추가
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
                    print('Error loading cabbage.png: $error'); // 디버깅 로그 추가
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
                    print('Error loading user.png: $error'); // 디버깅 로그 추가
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
    print('Building MainContent...'); // 디버깅 로그 추가
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const double baseWidth = 1080;
    const double baseHeight = 2400;
    final widthRatio = screenWidth / baseWidth;
    final heightRatio = screenHeight / baseHeight;

    return Column(
      children: [
        // 상단바: 앱의 상단에 고정된 네비게이션 바, 로고 표시
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
        // 중단 섹션: 배경 이미지와 "Kimchida" 텍스트 표시 영역
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
                  '', // "앱 소개" 텍스트가 비어 있으므로 유지
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
        // 하단 섹션: 메뉴 항목들을 표시하는 섹션 (MenuSection 위젯 사용)
        Expanded(
          child: MenuSection(
            widthRatio: widthRatio,
            heightRatio: heightRatio,
            screenWidth: screenWidth,
          ),
        ),
      ],
    );
  }
}

class MenuSection extends StatelessWidget {
  final double widthRatio;
  final double heightRatio;
  final double screenWidth;

  const MenuSection({
    super.key,
    required this.widthRatio,
    required this.heightRatio,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    print('Building MenuSection...'); // 디버깅 로그 추가
    // 하단 섹션: "레시피 직접 만들기"와 "레시피 둘러보기" 메뉴 항목 표시
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
                fontSize: 60 * widthRatio,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 70),
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
                          fontSize: 36 * widthRatio,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 30 * heightRatio),
                      IconButton(
                        onPressed: () {
                          print('Navigating to UserRecipePage (photo)...'); // 디버깅 로그 추가
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
                          width: 400 * widthRatio,
                          height: 300 * heightRatio,
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
                              width: 150 * widthRatio,
                              height: 150 * heightRatio,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading photo.png: $error'); // 디버깅 로그 추가
                                return const Text(
                                  '이미지를 로드할 수 없습니다.',
                                  style: TextStyle(color: Colors.red),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 30 * heightRatio),
                      IconButton(
                        onPressed: () {
                          print('Navigating to UserRecipePage (text)...'); // 디버깅 로그 추가
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
                          width: 400 * widthRatio,
                          height: 300 * heightRatio,
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
                              width: 150 * widthRatio,
                              height: 150 * heightRatio,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading text.png: $error'); // 디버깅 로그 추가
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
                  height: 800 * heightRatio,
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
                          fontSize: 36 * widthRatio,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 30 * heightRatio),
                      IconButton(
                        onPressed: () {
                          print('Navigating to RecipePage...'); // 디버깅 로그 추가
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RecipePage()),
                          );
                        },
                        visualDensity: VisualDensity(
                          horizontal: -4,
                          vertical: -4,
                        ),
                        icon: Container(
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
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/images/recipe.png',
                                width: 200 * widthRatio,
                                height: 400 * heightRatio,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error loading recipe.png: $error'); // 디버깅 로그 추가
                                  return const Icon(Icons.error);
                                },
                              ),
                              SizedBox(height: 20 * heightRatio),
                              Container(
                                width: 400 * widthRatio,
                                height: 100 * heightRatio,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    '김치 레시피 보러가기',
                                    style: TextStyle(
                                      fontSize: 65 * widthRatio * 0.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 70 * heightRatio),
                            ],
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
}