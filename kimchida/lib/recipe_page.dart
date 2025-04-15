import 'package:flutter/material.dart';
import 'main_page.dart';
import 'user_page.dart';
import 'recipe_page_detail.dart';
import 'kimchi_recipe.dart'; // kimchi_recipe.dart 임포트

class RecipePage extends StatefulWidget {
  const RecipePage({super.key});

  @override
  _RecipePageState createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  int currentPage = 1;
  late ScrollController _scrollController; // 스크롤 컨트롤러 추가
  double _middleSectionHeight = 0; // 중단 섹션의 동적 높이
  double _initialMiddleSectionHeight = 0; // 중단 섹션의 초기 높이
  double _minMiddleSectionHeight = 0; // 중단 섹션의 최소 높이 ("Kimchi" 텍스트 높이)

  // TODO: 차후 API를 통해 kimchiList를 비동기적으로 로드하도록 수정 예정
  // - 상태 변수 추가:
  //   List<List<Map<String, dynamic>>> kimchiList = [];
  //   bool isLoading = true;
  //   String? errorMessage;
  // - initState에서 데이터 로드:
  //   @override
  //   void initState() {
  //     super.initState();
  //     _scrollController = ScrollController();
  //     _scrollController.addListener(_updateMiddleSectionHeight);
  //     _loadKimchiList();
  //   }
  // - API 데이터 로드 함수:
  //   Future<void> _loadKimchiList() async {
  //     try {
  //       setState(() {
  //         isLoading = true;
  //         errorMessage = null;
  //       });
  //       final fetchedList = await fetchKimchiList(); // kimchi_recipe.dart에서 정의
  //       setState(() {
  //         kimchiList = fetchedList;
  //         isLoading = false;
  //       });
  //     } catch (e) {
  //       setState(() {
  //         isLoading = false;
  //         errorMessage = '김치 데이터를 로드하는 데 실패했습니다: $e';
  //       });
  //     }
  //   }
  // - UI에서 로딩/에러 상태 처리:
  //   if (isLoading) {
  //     return Center(child: CircularProgressIndicator());
  //   } else if (errorMessage != null) {
  //     return Center(child: Text(errorMessage!));
  //   }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // 스크롤 리스너 추가
    _scrollController.addListener(_updateMiddleSectionHeight);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateMiddleSectionHeight);
    _scrollController.dispose();
    super.dispose();
  }

  // 스크롤 시 중단 섹션 높이를 업데이트
  void _updateMiddleSectionHeight() {
    final offset = _scrollController.offset;
    // 스크롤 오프셋에 따라 중단 섹션 높이를 줄임
    double newHeight = (_initialMiddleSectionHeight - offset).clamp(
      _minMiddleSectionHeight,
      _initialMiddleSectionHeight,
    );
    setState(() {
      _middleSectionHeight = newHeight;
    });
  }

  // 페이지 변경 시 스크롤 위치를 맨 위로 이동
  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0); // 스크롤 위치를 맨 위로 이동
    }
  }

  List<Map<String, dynamic>> getCurrentKimchiList() {
    int startIndex = (currentPage - 1) * 10;
    int endIndex = startIndex + 10;
    if (endIndex > kimchiList.length) {
      endIndex = kimchiList.length;
    }

    // 새로운 kimchiList 구조에 맞게 데이터를 변환
    List<Map<String, dynamic>> currentList = [];
    for (int i = startIndex; i < endIndex; i++) {
      var kimchi = kimchiList[i];
      // kimchiList에서 name 직접 사용
      String name = kimchi[0]['name'];
      // 대표 이미지: 첫 번째 단계의 recipe_image_serial_num 사용
      String imagePath = kimchi[0]['recipe_image_serial_num'] ?? 'assets/images/cabbagekimchi.png';

      currentList.add({
        'name': name,
        'imagePath': imagePath,
        'kimchiData': kimchi, // RecipePageDetail로 전달할 전체 데이터
      });
    }
    return currentList;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const double baseWidth = 1080;
    const double baseHeight = 2400;
    final widthRatio = screenWidth / baseWidth;
    final heightRatio = screenHeight / baseHeight;

    // 중단 섹션의 초기 높이 설정
    _initialMiddleSectionHeight = 600 * heightRatio;
    if (_middleSectionHeight == 0) {
      _middleSectionHeight = _initialMiddleSectionHeight;
    }

    // "Kimchi" 텍스트의 높이를 계산하기 위해 TextPainter 사용
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
    _minMiddleSectionHeight = textPainter.height + (60 * heightRatio) + (60 * heightRatio); // 텍스트 높이 + 상단 패딩 + 하단 여백

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 상단바
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
            // 중단 섹션: 동적 높이 적용
            Container(
              width: screenWidth,
              height: _middleSectionHeight, // 동적으로 높이 변경
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
            // 하단 섹션: 중단 섹션이 줄어든 만큼 자동으로 늘어남
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController, // 스크롤 컨트롤러 연결
                child: Container(
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
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RecipePageDetail(
                                      kimchiData: kimchi['kimchiData'], // 새로운 데이터 구조 전달
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PaginationButton(
                            label: '1',
                            isSelected: currentPage == 1,
                            onTap: () {
                              setState(() {
                                currentPage = 1;
                                _scrollToTop(); // 페이지 변경 시 스크롤 맨 위로 이동
                              });
                            },
                          ),
                          SizedBox(width: 20 * widthRatio),
                          PaginationButton(
                            label: '2',
                            isSelected: currentPage == 2,
                            onTap: () {
                              setState(() {
                                currentPage = 2;
                                _scrollToTop(); // 페이지 변경 시 스크롤 맨 위로 이동
                              });
                            },
                          ),
                          SizedBox(width: 20 * widthRatio),
                          PaginationButton(
                            label: '3',
                            isSelected: currentPage == 3,
                            onTap: () {
                              setState(() {
                                currentPage = 3;
                                _scrollToTop(); // 페이지 변경 시 스크롤 맨 위로 이동
                              });
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 100 * heightRatio),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        width: screenWidth,
        height: 100 * heightRatio,
        color: Colors.grey[200],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MainPage()),
                );
              },
              icon: Image.asset(
                'assets/images/home.png',
                width: 60 * widthRatio,
                height: 60 * heightRatio,
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: Image.asset(
                'assets/images/cabbage.png',
                width: 60 * widthRatio,
                height: 60 * heightRatio,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserPage()),
                );
              },
              icon: Image.asset(
                'assets/images/user.png',
                width: 60 * widthRatio,
                height: 60 * heightRatio,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecipeItem extends StatelessWidget {
  final String imagePath;
  final String title;
  final VoidCallback onTap;

  const RecipeItem({
    super.key,
    required this.imagePath,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              child: Image.asset(
                imagePath,
                width: 300 * widthRatio,
                height: 300 * widthRatio,
                fit: BoxFit.cover,
              ),
              // TODO: API로 가져온 이미지 URL을 사용할 경우 NetworkImage로 변경 예정
              // child: Image.network(
              //   imagePath,
              //   width: 300 * widthRatio,
              //   height: 300 * widthRatio,
              //   fit: BoxFit.cover,
              //   errorBuilder: (context, error, stackTrace) {
              //     return const Center(
              //       child: Text(
              //         '이미지를 로드할 수 없습니다.',
              //         style: TextStyle(fontSize: 16),
              //       ),
              //     );
              //   },
              // ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(fontSize: 24 * widthRatio, color: Colors.black),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

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