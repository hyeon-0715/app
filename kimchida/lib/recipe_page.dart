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
  // 현재 표시할 페이지 번호 (페이지네이션用)
  int currentPage = 1;
  // 스크롤 동작을 관리하는 컨트롤러
  late ScrollController _scrollController;
  // 중단 섹션의 현재 높이 (스크롤에 따라 동적으로 변경)
  double _middleSectionHeight = 0;
  // 중단 섹션의 초기 높이
  double _initialMiddleSectionHeight = 0;
  // 중단 섹션의 최소 높이 ("Kimchi" 텍스트와 패딩 포함)
  double _minMiddleSectionHeight = 0;
  // API 통신 상태 관리
  bool isLoading = true;
  String? errorMessage;
  // 김치 목록 데이터를 저장하는 리스트
  List<List<Map<String, dynamic>>> kimchiList = [];

  @override
  void initState() {
    super.initState();
    // 세로 모드 고정: 디바이스 방향을 세로로만 제한
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // 스크롤 컨트롤러 초기화 및 리스너 추가 (스크롤 시 중단 섹션 높이 업데이트)
    _scrollController = ScrollController();
    _scrollController.addListener(_updateMiddleSectionHeight);
    // 김치 목록 데이터 로드
    _loadKimchiList();
  }

  // 김치 목록 데이터를 비동기적으로 로드하는 메서드
  Future<void> _loadKimchiList() async {
    print('Loading kimchi list...');
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // 김치 목록 API 요청
      final response = await http.get(
        Uri.parse('http://ec2-47-130-90-43.ap-southeast-1.compute.amazonaws.com:8080/kimchiData'),
      );

      if (response.statusCode == 200) {
        // JSON 파싱
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> rows = jsonResponse['rows'];

        // 김치 목록을 순회하며 각 김치의 레시피 데이터를 가져옴
        List<List<Map<String, dynamic>>> fetchedList = [];
        for (var row in rows) {
          int kimchiNum = row['kimchi_num'] as int;
          String name = row['kimchi_name'] as String;

          // 레시피 데이터 API 요청
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
            // 레시피 데이터를 가져오지 못한 경우 기본값 설정
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
        setState(() {
          kimchiList = fetchedList;
          isLoading = false;
        });
      } else {
        throw Exception('API 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading kimchi list: $e');
      setState(() {
        isLoading = false;
        errorMessage = '김치 데이터를 로드하는 데 실패했습니다: $e';
      });
    }
  }

  @override
  void dispose() {
    // 스크롤 리스너 제거 및 컨트롤러 해제
    _scrollController.removeListener(_updateMiddleSectionHeight);
    _scrollController.dispose();
    super.dispose();
  }

  // 스크롤 시 중단 섹션의 높이를 동적으로 업데이트하는 메서드
  void _updateMiddleSectionHeight() {
    final offset = _scrollController.offset;
    // 스크롤 오프셋에 따라 중단 섹션 높이를 줄임 (최소 높이와 초기 높이 사이에서 클램핑)
    double newHeight = (_initialMiddleSectionHeight - offset).clamp(
      _minMiddleSectionHeight,
      _initialMiddleSectionHeight,
    );
    setState(() {
      _middleSectionHeight = newHeight;
    });
  }

  // 페이지 변경 시 스크롤 위치를 맨 위로 이동하는 메서드
  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  // 현재 페이지에 해당하는 김치 레시피 목록을 반환하는 메서드
  List<Map<String, dynamic>> getCurrentKimchiList() {
    print('Getting current kimchi list for page: $currentPage');
    int startIndex = (currentPage - 1) * 10;
    int endIndex = startIndex + 10;
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

  @override
  Widget build(BuildContext context) {
    print('Building RecipePage...');
    // 화면 크기 및 비율 계산
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const double baseWidth = 1080;
    const double baseHeight = 2400;
    final widthRatio = screenWidth / baseWidth;
    final heightRatio = screenHeight / baseHeight;

    // 중단 섹션의 초기 높이 설정 및 동적 높이 초기화
    _initialMiddleSectionHeight = 600 * heightRatio;
    if (_middleSectionHeight == 0) {
      _middleSectionHeight = _initialMiddleSectionHeight;
    }

    // "Kimchi" 텍스트 높이 계산 (최소 높이 설정用)
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

    return Container(
      width: screenWidth,
      color: const Color(0xFFF5E9D6),
      child: Column(
        children: [
          // 상단바: 앱의 상단에 고정된 네비게이션 바
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
          // 중단 섹션: 스크롤에 따라 높이가 동적으로 변하는 배경 이미지와 "Kimchi" 텍스트 표시 영역
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
          // 하단 섹션: 김치 레시피 목록과 페이지네이션 버튼이 포함된 스크롤 가능한 영역
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Container(
                width: screenWidth,
                color: const Color(0xFFF5E9D6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 로딩 중일 때 표시
                    if (isLoading)
                      const Center(child: CircularProgressIndicator())
                    // 에러 발생 시 표시
                    else if (errorMessage != null)
                      Center(child: Text(errorMessage!))
                    // 데이터 로드 성공 시 표시
                    else ...[
                      // 김치 설명: 김치에 대한 간단한 설명 텍스트
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
                      // 레시피 목록: 현재 페이지에 해당하는 김치 레시피를 그리드 형태로 표시
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
                      // 페이지네이션 버튼: 레시피 목록 페이지 전환을 위한 버튼 (1~8)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          8, // 총 8개의 페이지네이션 버튼 생성
                          (index) {
                            final page = index + 1;
                            return Row(
                              children: [
                                PaginationButton(
                                  label: page.toString(),
                                  isSelected: currentPage == page,
                                  onTap: () {
                                    print('Pagination button $page tapped');
                                    setState(() {
                                      currentPage = page;
                                      _scrollToTop();
                                    });
                                  },
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
}

// 레시피 항목 위젯: 개별 김치 레시피를 표시하는 카드 (이미지와 제목 포함)
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
              child: Image.asset(
                imagePath,
                width: 300 * widthRatio,
                height: 300 * widthRatio,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading image $imagePath: $error');
                  return const Icon(Icons.error);
                },
              ),
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

// 페이지네이션 버튼 위젯: 페이지 전환을 위한 원형 버튼
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