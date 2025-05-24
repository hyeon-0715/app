import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main_page.dart';
import 'user_page.dart';
import 'recipe_page_detail.dart';
import 'kimchi_recipe.dart';

class RecipePage extends StatefulWidget {
  const RecipePage({super.key});

  @override
  _RecipePageState createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  int currentPage = 1;
  late ScrollController _scrollController;
  double _middleSectionHeight = 0;
  double _initialMiddleSectionHeight = 0;
  double _minMiddleSectionHeight = 0;
  bool isLoading = true;
  String? errorMessage;
  List<List<Map<String, dynamic>>> kimchiList = [];
  final Map<String, bool> _imageLoaded = {};
  bool _isMounted = true; // 비동기 작업 중 상태 추적

  @override
  void initState() {
    super.initState();
    // 가로/세로 모드를 모두 허용 (화면 자동 회전에 따라 동작)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // 스크롤 컨트롤러 초기화 및 리스너 추가
    _scrollController = ScrollController();
    _scrollController.addListener(_updateMiddleSectionHeight);

    // 김치 목록 데이터 로드
    _loadKimchiList();
  }

  Future<void> _loadKimchiList() async {
    print('Loading kimchi list...');
    try {
      if (!_isMounted) return; // 이미 dispose된 경우 중단

      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await http.get(
        Uri.parse('http://ec2-47-130-90-43.ap-southeast-1.compute.amazonaws.com:8080/kimchiData'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> rows = jsonResponse['rows'];

        List<List<Map<String, dynamic>>> fetchedList = [];
        for (var row in rows) {
          if (!_isMounted) break; // 중간에 dispose된 경우 루프 중단

          int kimchiNum = row['kimchi_num'] as int;
          String name = row['kimchi_name'] as String;

          final recipeResponse = await http.get(
            Uri.parse('http://ec2-47-130-90-43.ap-southeast-1.compute.amazonaws.com:8080/kimchiRecipe/$kimchiNum'),
          );

          if (recipeResponse.statusCode == 200) {
            final List<dynamic> recipeData = jsonDecode(recipeResponse.body);
            fetchedList.add(recipeData.map((step) {
              return {
                'kimchi_num': kimchiNum,
                'name': name,
                'recipe_order': step['recipe_order'] as int,
                'recipe_detail': step['recipe_detail']?.toString() ?? '레시피 단계 없음',
                'recipe_image_serial_num': step['recipe_image_serial_num']?.toString() ?? 'assets/images/cabbagekimchi.png',
              };
            }).toList());
          } else {
            fetchedList.add([
              {
                'kimchi_num': kimchiNum,
                'name': name,
                'recipe_order': 1,
                'recipe_detail': '레시피 데이터를 불러오지 못했습니다.',
                'recipe_image_serial_num': 'assets/images/cabbagekimchi.png',
              }
            ]);
          }
        }

        print('Fetched kimchi list: $fetchedList');
        if (_isMounted) {
          setState(() {
            kimchiList = fetchedList;
            isLoading = false;
          });

          // 이미지 프리로딩
          WidgetsBinding.instance.addPostFrameCallback((_) {
            for (var kimchi in kimchiList) {
              if (!_isMounted) break; // 중간에 dispose된 경우 중단
              String imagePath = kimchi[0]['recipe_image_serial_num'] as String;
              _preloadImage(imagePath);
            }
          });
        }
      } else {
        throw Exception('API 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading kimchi list: $e');
      if (_isMounted) {
        setState(() {
          isLoading = false;
          errorMessage = '서버와 연결하는데 실패했습니다. 잠시 후에 다시 시도해주세요';
        });
      }
    }
  }

  void _preloadImage(String imagePath) async {
    if (_imageLoaded.containsKey(imagePath) && _imageLoaded[imagePath]!) return;

    try {
      print('Preloading image: $imagePath');
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        await precacheImage(NetworkImage(imagePath), context);
      } else {
        await precacheImage(AssetImage(imagePath), context);
      }
      if (_isMounted) {
        setState(() {
          _imageLoaded[imagePath] = true;
        });
      }
    } catch (e) {
      print('Error preloading image $imagePath: $e');
      if (_isMounted) {
        setState(() {
          _imageLoaded[imagePath] = true;
        });
      }
    }
  }

  @override
  void dispose() {
    print('Disposing RecipePage...');
    _isMounted = false; // 비동기 작업 중단 플래그
    _scrollController.removeListener(_updateMiddleSectionHeight);
    _scrollController.dispose();
    // 방향 설정 복원 (필요한 경우 MainPage의 기본 설정으로 복원)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _updateMiddleSectionHeight() {
    final offset = _scrollController.offset;
    double newHeight = (_initialMiddleSectionHeight - offset).clamp(
      _minMiddleSectionHeight,
      _initialMiddleSectionHeight,
    );
    if (_isMounted) {
      setState(() {
        _middleSectionHeight = newHeight;
      });
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  List<Map<String, dynamic>> getCurrentKimchiList() {
    print('Getting current kimchi list for page: $currentPage');
    const int itemsPerPage = 10;
    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    if (endIndex > kimchiList.length) {
      endIndex = kimchiList.length;
    }

    List<Map<String, dynamic>> currentList = [];
    for (int i = startIndex; i < endIndex; i++) {
      var kimchi = kimchiList[i];
      String name = kimchi[0]['name'] as String;
      String imagePath = kimchi[0]['recipe_image_serial_num'] ?? 'assets/images/cabbagekimchi.png';
      int kimchiNum = kimchi[0]['kimchi_num'] as int;

      currentList.add({
        'name': name,
        'imagePath': imagePath,
        'kimchiData': kimchi,
        'kimchi_num': kimchiNum,
      });
    }
    print('Current kimchi list: $currentList');
    return currentList;
  }

  int getTotalPages() {
    const int itemsPerPage = 10;
    return (kimchiList.length / itemsPerPage).ceil();
  }

  void _goToPage(int page) {
    print('Going to page: $page');
    setState(() {
      currentPage = page;
      _scrollToTop();
    });
  }

  @override
  Widget build(BuildContext context) {
    print('Building RecipePage...');
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const double baseWidth = 1080;
    const double baseHeight = 2400;
    final widthRatio = screenWidth / baseWidth;
    final heightRatio = screenHeight / baseHeight;

    _initialMiddleSectionHeight = 600 * heightRatio;
    if (_middleSectionHeight == 0) {
      _middleSectionHeight = _initialMiddleSectionHeight;
    }

    final textSpan = TextSpan(
      text: 'Kimchi',
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
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    _minMiddleSectionHeight = textPainter.height + (60 * heightRatio) + (60 * heightRatio);

    return Scaffold(
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            print('Orientation in RecipePage: $orientation');
            return orientation == Orientation.portrait
                ? _buildPortraitLayout(widthRatio, heightRatio, screenWidth)
                : _buildLandscapeLayout(widthRatio, heightRatio, screenWidth, screenHeight);
          },
        ),
      ),
    );
  }

  // 세로 모드 레이아웃 빌드
  Widget _buildPortraitLayout(double widthRatio, double heightRatio, double screenWidth) {
    print('Rendering portrait layout in RecipePage...');
    return Container(
      width: screenWidth,
      color: const Color(0xFFF5E9D6),
      child: Column(
        children: [
          // 상단바: 앱 로고 또는 아이콘 표시
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
          // 중단 섹션: 스크롤에 따라 높이가 변하는 섹션, 배경 이미지와 "Kimchi" 텍스트 표시
          Container(
            width: screenWidth,
            height: _middleSectionHeight,
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
              child: Text(
                'Kimchi',
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
            ),
          ),
          // 하단 섹션: 김치 레시피 목록과 페이지네이션 버튼 표시
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Container(
                width: screenWidth,
                color: const Color(0xFFF5E9D6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (errorMessage != null)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(errorMessage!),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _loadKimchiList,
                              child: const Text('재시도'),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Padding(
                        padding: EdgeInsets.only(
                          left: 60 * widthRatio,
                          top: 60 * heightRatio,
                        ),
                        child: Text(
                          '한국의 전통 발효식품으로 소금에 절인 배추나 부 등을\n고춧가루, 파 등의 양념에 버무린 뒤 발효시켜 만드는\n한국의 국민 음식 중 하나',
                          style: TextStyle(
                            fontSize: 40 * widthRatio,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 60 * widthRatio),
                        child: GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 20 * widthRatio,
                          mainAxisSpacing: 20 * heightRatio,
                          childAspectRatio: 1.0,
                          children: getCurrentKimchiList().map((kimchi) {
                            return RecipeItem(
                              imagePath: kimchi['imagePath']!,
                              title: kimchi['name']!,
                              isImageLoaded: _imageLoaded[kimchi['imagePath']] ?? false,
                              onTap: () {
                                print('Navigating to RecipePageDetail for ${kimchi['name']}');
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RecipePageDetail(
                                      kimchiData: kimchi['kimchiData'] as List<Map<String, dynamic>>,
                                      recipeId: 'mock_recipe_id_${kimchi['kimchi_num']}',
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // 페이지네이션 버튼: 총 페이지 수에 따라 동적으로 생성
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          getTotalPages(),
                          (index) {
                            final page = index + 1;
                            return Row(
                              children: [
                                PaginationButton(
                                  label: page.toString(),
                                  isSelected: currentPage == page,
                                  onTap: () => _goToPage(page),
                                ),
                                SizedBox(width: 10 * widthRatio), // 버튼 간 간격 조정
                              ],
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 100 * heightRatio),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 가로 모드 레이아웃 빌드
  Widget _buildLandscapeLayout(double widthRatio, double heightRatio, double screenWidth, double screenHeight) {
    print('Rendering landscape layout in RecipePage...');
    return Row(
      children: [
        // 상단바: 가로 모드에서 회전된 상태로 표시
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
        // 메인 콘텐츠: 김치 레시피 목록 표시
        Expanded(
          child: Container(
            color: const Color(0xFFF5E9D6),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      left: 60 * widthRatio,
                      top: 60 * heightRatio,
                    ),
                    child: Text(
                      'Kimchi',
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
                  ),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (errorMessage != null)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(errorMessage!),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _loadKimchiList,
                            child: const Text('재시도'),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Padding(
                      padding: EdgeInsets.only(
                        left: 60 * widthRatio,
                        top: 20 * heightRatio,
                      ),
                      child: Text(
                        '한국의 전통 발효식품으로 소금에 절인 배추나 부 등을\n고춧가루, 파 등의 양념에 버무린 뒤 발효시켜 만드는\n한국의 국민 음식 중 하나',
                        style: TextStyle(
                          fontSize: 30 * widthRatio,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 80 * widthRatio),
                      child: GridView.count(
                        crossAxisCount: 2, // 가로 모드에서는 2열로 표시
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 20 * widthRatio,
                        mainAxisSpacing: 20 * heightRatio,
                        childAspectRatio: 1.0,
                        children: getCurrentKimchiList().map((kimchi) {
                          return RecipeItem(
                            imagePath: kimchi['imagePath']!,
                            title: kimchi['name']!,
                            isImageLoaded: _imageLoaded[kimchi['imagePath']] ?? false,
                            onTap: () {
                              print('Navigating to RecipePageDetail for ${kimchi['name']}');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RecipePageDetail(
                                    kimchiData: kimchi['kimchiData'] as List<Map<String, dynamic>>,
                                    recipeId: 'mock_recipe_id_${kimchi['kimchi_num']}',
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // 페이지네이션 버튼: 총 페이지 수에 따라 동적으로 생성
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        getTotalPages(),
                        (index) {
                          final page = index + 1;
                          return Row(
                            children: [
                              PaginationButton(
                                label: page.toString(),
                                isSelected: currentPage == page,
                                onTap: () => _goToPage(page),
                              ),
                              SizedBox(width: 10 * widthRatio),
                            ],
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 100 * heightRatio),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class RecipeItem extends StatelessWidget {
  final String imagePath;
  final String title;
  final bool isImageLoaded;
  final VoidCallback onTap;

  const RecipeItem({
    super.key,
    required this.imagePath,
    required this.title,
    required this.isImageLoaded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    print('Building RecipeItem for $title');
    final screenWidth = MediaQuery.of(context).size.width;
    const double baseWidth = 1080;
    final widthRatio = screenWidth / baseWidth;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 300 * widthRatio,
            height: 300 * widthRatio,
            decoration: BoxDecoration(
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: isImageLoaded
                  ? (imagePath.startsWith('http://') || imagePath.startsWith('https://')
                      ? Image.network(
                          imagePath,
                          width: 300 * widthRatio,
                          height: 300 * widthRatio,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading network image $imagePath: $error');
                            return Image.asset(
                              'assets/images/cabbagekimchi.png',
                              width: 300 * widthRatio,
                              height: 300 * widthRatio,
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Image.asset(
                          imagePath,
                          width: 300 * widthRatio,
                          height: 300 * widthRatio,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading asset image $imagePath: $error');
                            return const Icon(Icons.error);
                          },
                        ))
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(fontSize: 40 * widthRatio, color: Colors.black),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// 페이지네이션 버튼 위젯: 페이지 번호를 표시하는 원형 버튼
class PaginationButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const PaginationButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    print('Building PaginationButton for label: $label');
    final screenWidth = MediaQuery.of(context).size.width;
    const double baseWidth = 1080;
    final widthRatio = screenWidth / baseWidth;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60 * widthRatio,
        height: 60 * widthRatio,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? Colors.black : Colors.grey[300],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 24 * widthRatio,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}