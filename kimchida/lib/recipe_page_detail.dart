import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'user_page.dart';
import 'recipe_page.dart';
import 'main_page.dart';
import '../utils/permission_helper.dart'; // PermissionHelper 임포트

// 레시피 세부 정보를 표시하는 StatefulWidget
class RecipePageDetail extends StatefulWidget {
  final List<Map<String, dynamic>> kimchiData; // 김치 데이터를 전달받는 변수

  const RecipePageDetail({
    super.key,
    required this.kimchiData,
  });

  @override
  _RecipePageDetailState createState() => _RecipePageDetailState();
}

class _RecipePageDetailState extends State<RecipePageDetail> {
  // 레시피 진행 상태 관리 변수
  bool _isRecipeStarted = false; // 레시피가 시작되었는지 여부
  int _currentStep = 0; // 현재 레시피 단계

  // 스크롤 컨트롤러
  final ScrollController _scrollController = ScrollController();

  // 이미지 캡처를 위한 키
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  // 캡처를 위한 플래그
  bool _isCapturing = false;

  // 레시피 데이터와 이미지 관리 변수
  late List<String> _recipeSteps; // 레시피 단계별 설명 리스트
  late List<String?> _stepImages; // 단계별 이미지 경로 리스트
  late String _kimchiName; // 김치 이름
  late String _initialImagePath; // 초기 화면에 표시할 이미지 경로
  final Map<int, bool> _imageLoaded = {}; // 각 단계별 이미지 로딩 상태

  // 위젯 초기화 시 실행되는 메서드
  @override
  void initState() {
    super.initState();

    // kimchiData에서 필요한 데이터를 추출하여 초기화
    _kimchiName = widget.kimchiData[0]['name'] ?? '김치'; // 이름이 없으면 기본값
    _recipeSteps = widget.kimchiData.map((step) => step['recipe_detail'] as String).toList();
    _stepImages = widget.kimchiData.map((step) => step['recipe_image_serial_num'] as String?).toList();
    // 초기 이미지가 없으면 기본 이미지(cabbagekimchi.png) 사용
    _initialImagePath = _stepImages.firstWhere((image) => image != null && image.isNotEmpty, orElse: () => 'assets/images/cabbagekimchi.png')!;

    // 모든 단계의 이미지를 미리 로드
    for (int i = 0; i < _recipeSteps.length && i < _stepImages.length; i++) {
      _imageLoaded[i] = false;
      _preloadImage(i);
    }
  }

  // 위젯이 폐기될 때 실행되는 메서드
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 이미지를 미리 로드하는 메서드
  void _preloadImage(int step) async {
    if (step >= _stepImages.length || _stepImages[step] == null || _stepImages[step]!.isEmpty) {
      setState(() {
        _imageLoaded[step] = true;
      });
      return;
    }

    try {
      final imageProvider = AssetImage(_stepImages[step]!);
      await precacheImage(imageProvider, context);
      setState(() {
        _imageLoaded[step] = true;
      });
    } catch (e) {
      print('Error preloading image for step $step: $e');
      setState(() {
        _imageLoaded[step] = true;
      });
    }
  }

  // 레시피를 시작하는 메서드
  void _startRecipe() {
    setState(() {
      _isRecipeStarted = true;
      _currentStep = 0;
    });
  }

  // 이전 단계로 이동하는 메서드
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _scrollController.jumpTo(0);
    }
  }

  // 다음 단계로 이동하는 메서드
  void _nextStep() {
    if (_currentStep < _recipeSteps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _scrollController.jumpTo(0);
    }
  }

  // 전체 레시피 이미지를 캡처하고 저장하는 메서드
  Future<void> _captureRecipeImage() async {
    bool allPermissionsGranted = await PermissionHelper.checkPermissions();
    if (!allPermissionsGranted) {
      await PermissionHelper.requestPermissions(
        context,
        onPermissionsGranted: () async {
          await _captureAndSaveImage();
        },
      );
      return;
    }

    // 캡처 플래그 활성화
    setState(() {
      _isCapturing = true;
    });

    // 렌더링이 완료될 때까지 대기
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _captureAndSaveImage();
      setState(() {
        _isCapturing = false;
      });
    });
  }

  Future<void> _captureAndSaveImage() async {
    try {
      final RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // 임시 디렉토리에 이미지 저장
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/recipe_${DateTime.now().millisecondsSinceEpoch}.png').writeAsBytes(pngBytes);

      // 갤러리에 저장
      final result = await ImageGallerySaverPlus.saveFile(file.path);
      if (result['isSuccess']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('레시피 이미지가 갤러리에 저장되었습니다.')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미지 저장에 실패했습니다.')),
          );
        }
      }
    } catch (e) {
      print('Error capturing recipe image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 생성 중 오류 발생: $e')),
        );
      }
    }
  }

  // UI를 빌드하는 메서드
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const double baseWidth = 1080;
    const double baseHeight = 2400;
    final widthRatio = screenWidth / baseWidth;
    final heightRatio = screenHeight / baseHeight;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            OrientationBuilder(
              builder: (context, orientation) {
                if (orientation == Orientation.portrait) {
                  // 세로 모드 UI
                  return Column(
                    children: [
                      // 상단바: 앱 이름 표시
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
                      // 하단 섹션: 레시피 시작 전/후 화면 표시
                      Expanded(
                        child: Container(
                          color: const Color(0xFFF5E9D6),
                          child: _isRecipeStarted ? _buildRecipeStepsPortrait() : _buildInitialViewPortrait(),
                        ),
                      ),
                      // 하단 내비게이션 바 (세로 모드)
                      _buildBottomNavigationBarPortrait(widthRatio, heightRatio),
                    ],
                  );
                } else {
                  // 가로 모드 UI
                  return Row(
                    children: [
                      // 상단바: 화면 왼쪽 끝에 세로로 표시
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
                      // 하단 섹션: 레시피 시작 전/후 화면 표시
                      Expanded(
                        child: Container(
                          color: const Color(0xFFF5E9D6),
                          child: _isRecipeStarted ? _buildRecipeStepsLandscape() : _buildInitialViewPortrait(),
                        ),
                      ),
                      // 하단 내비게이션 바 (가로 모드)
                      RotatedBox(
                        quarterTurns: 1,
                        child: _buildBottomNavigationBarLandscape(widthRatio, heightRatio),
                      ),
                    ],
                  );
                }
              },
            ),
            // 캡처를 위한 위젯 (화면에 보이지 않도록 위치 조정)
            Positioned(
              left: -9999, // 화면 밖으로 이동
              child: Visibility(
                visible: _isCapturing, // 캡처 중일 때만 렌더링
                child: RepaintBoundary(
                  key: _repaintBoundaryKey,
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: List.generate(_recipeSteps.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              // 단계별 텍스트
                              Text(
                                '${index + 1}. ${_recipeSteps[index]}',
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              // 단계별 이미지
                              _stepImages[index] != null && _stepImages[index]!.isNotEmpty
                                  ? Image.asset(
                                      _stepImages[index]!,
                                      width: 300,
                                      height: 200,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => const Text('이미지 없음'),
                                    )
                                  : const Text('이미지 없음'),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 세로 모드: 레시피 시작 전 화면 UI
  Widget _buildInitialViewPortrait() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 뒤로가기 버튼: 이전 페이지로 이동
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 10),
          // 김치 이름 표시
          Text(
            _kimchiName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          // 김치 설명 표시
          const Text(
            '해당 김치 설명',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          // 초기 이미지 표시
          Expanded(
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset(
                  _initialImagePath,
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text(
                        '이미지를 로드할 수 없습니다.',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Start Recipe 버튼: 레시피 시작
          Center(
            child: ElevatedButton(
              onPressed: _startRecipe,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('Start Recipe'),
            ),
          ),
        ],
      ),
    );
  }

  // 세로 모드: 레시피 진행 중 화면 UI
  Widget _buildRecipeStepsPortrait() {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthRatio = screenWidth / 1080;
    final heightRatio = MediaQuery.of(context).size.height / 2400;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 뒤로가기 버튼: 이전 페이지로 이동
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 10),
          // 단계별 이미지 표시
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: _currentStep < _stepImages.length && _stepImages[_currentStep] != null && _stepImages[_currentStep]!.isNotEmpty
                  ? (_imageLoaded[_currentStep] == true
                      ? AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.asset(
                            _stepImages[_currentStep]!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Text(
                                  '이미지를 로드할 수 없습니다.',
                                  style: TextStyle(fontSize: 16),
                                ),
                              );
                            },
                          ),
                        )
                      : const Text(
                          '이미지가 준비중입니다',
                          style: TextStyle(fontSize: 16),
                        ))
                  : const Text(
                      '이미지가 없습니다',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          // 단계 설명: 현재 단계의 설명 표시
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: 50,
                  ),
                  child: Text(
                    '${_currentStep + 1}. ${_recipeSteps[_currentStep]}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // 컨트롤 버튼: 이전 단계, 다음 단계
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _currentStep == 0 ? null : _previousStep,
                icon: const Icon(Icons.arrow_back),
                color: _currentStep == 0 ? Colors.grey : Colors.black,
              ),
              const SizedBox(width: 20),
              IconButton(
                onPressed: _currentStep == _recipeSteps.length - 1 ? null : _nextStep,
                icon: const Icon(Icons.arrow_forward),
                color: _currentStep == _recipeSteps.length - 1 ? Colors.grey : Colors.black,
              ),
            ],
          ),
          // 마지막 단계에서 "레시피 저장하기" 버튼 표시
          if (_currentStep == _recipeSteps.length - 1) ...[
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 300 * widthRatio,
                child: ElevatedButton(
                  onPressed: _captureRecipeImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 20 * heightRatio),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    '레시피 저장하기',
                    style: TextStyle(
                      fontSize: 36 * widthRatio,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 가로 모드: 레시피 진행 중 화면 UI
  Widget _buildRecipeStepsLandscape() {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthRatio = screenWidth / 1080;
    final heightRatio = MediaQuery.of(context).size.height / 2400;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 뒤로가기 버튼과 이미지: 좌우 배치
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 뒤로가기 버튼: 왼쪽 상단에 유지
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(width: 10),
              // 레시피 과정 이미지: 뒤로가기 버튼 우측, 양쪽 여백 균형 맞춤
              Expanded(
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  width: MediaQuery.of(context).size.width - 68,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: _currentStep < _stepImages.length && _stepImages[_currentStep] != null && _stepImages[_currentStep]!.isNotEmpty
                        ? (_imageLoaded[_currentStep] == true
                            ? AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Image.asset(
                                  _stepImages[_currentStep]!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Text(
                                        '이미지를 로드할 수 없습니다.',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    );
                                  },
                                ),
                              )
                            : const Text(
                                '이미지가 준비중입니다',
                                style: TextStyle(fontSize: 16),
                              ))
                        : const Text(
                            '이미지가 없습니다',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 58),
            ],
          ),
          const SizedBox(height: 20),
          // 레시피 내용과 이전/다음 버튼
          Expanded(
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 이전 버튼
                  IconButton(
                    onPressed: _currentStep == 0 ? null : _previousStep,
                    icon: const Icon(Icons.arrow_back),
                    color: _currentStep == 0 ? Colors.grey : Colors.black,
                  ),
                  const SizedBox(width: 10),
                  // 레시피 내용 컨테이너
                  Container(
                    width: MediaQuery.of(context).size.width * 0.6,
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: 50,
                        ),
                        child: Text(
                          '${_currentStep + 1}. ${_recipeSteps[_currentStep]}',
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 다음 버튼
                  IconButton(
                    onPressed: _currentStep == _recipeSteps.length - 1 ? null : _nextStep,
                    icon: const Icon(Icons.arrow_forward),
                    color: _currentStep == _recipeSteps.length - 1 ? Colors.grey : Colors.black,
                  ),
                ],
              ),
            ),
          ),
          // 마지막 단계에서 "레시피 저장하기" 버튼 표시
          if (_currentStep == _recipeSteps.length - 1) ...[
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 300 * widthRatio,
                child: ElevatedButton(
                  onPressed: _captureRecipeImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 20 * heightRatio),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    '레시피 저장하기',
                    style: TextStyle(
                      fontSize: 36 * widthRatio,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 세로 모드: 하단 내비게이션 바 UI
  Widget _buildBottomNavigationBarPortrait(double widthRatio, double heightRatio) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 100 * heightRatio,
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 홈 버튼: MainPage로 이동
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
          // 김치 버튼: RecipePage로 돌아감
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Image.asset(
              'assets/images/cabbage.png',
              width: 60 * widthRatio,
              height: 60 * heightRatio,
            ),
          ),
          // 사용자 버튼: UserPage로 이동
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
    );
  }

  // 가로 모드: 하단 내비게이션 바 UI
  Widget _buildBottomNavigationBarLandscape(double widthRatio, double heightRatio) {
    return Container(
      width: MediaQuery.of(context).size.height,
      height: 200 * heightRatio,
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 홈 버튼: MainPage로 이동
          RotatedBox(
            quarterTurns: 3,
            child: IconButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MainPage()),
                );
              },
              icon: Image.asset(
                'assets/images/home.png',
                width: 80 * widthRatio,
                height: 80 * heightRatio,
              ),
            ),
          ),
          // 김치 버튼: RecipePage로 돌아감
          RotatedBox(
            quarterTurns: 3,
            child: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Image.asset(
                'assets/images/cabbage.png',
                width: 80 * widthRatio,
                height: 80 * heightRatio,
              ),
            ),
          ),
          // 사용자 버튼: UserPage로 이동
          RotatedBox(
            quarterTurns: 3,
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserPage()),
                );
              },
              icon: Image.asset(
                'assets/images/user.png',
                width: 80 * widthRatio,
                height: 80 * heightRatio,
              ),
            ),
          ),
        ],
      ),
    );
  }
}