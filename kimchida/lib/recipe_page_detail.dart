import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main_page.dart';
import 'recipe_page.dart';
import 'user_page.dart';
import '../utils/permission_helper.dart';

class RecipePageDetail extends StatefulWidget {
  final List<Map<String, dynamic>> kimchiData;
  final String recipeId;

  const RecipePageDetail({
    super.key,
    required this.kimchiData,
    required this.recipeId,
  });

  @override
  _RecipePageDetailState createState() => _RecipePageDetailState();
}

class _RecipePageDetailState extends State<RecipePageDetail> {
  bool _isRecipeStarted = false;
  int _currentStep = 0;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _isCapturing = false;
  List<String>? _recipeSteps;
  List<String?>? _stepImages;
  String? _kimchiName;
  String? _initialImagePath;
  final Map<int, bool> _imageLoaded = {};
  Orientation? _lastOrientation; // 마지막으로 감지된 방향 저장

  @override
  void initState() {
    super.initState();
    // 가로/세로 모드 모두 허용하도록 초기 설정
    print('Initializing RecipePageDetail with all orientations allowed');
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]).then((_) {
      // 방향 설정이 적용된 후 UI 갱신 보장
      if (mounted) {
        setState(() {});
      }
    });

    // 김치 이름 초기화 (widget.kimchiData에서 가져옴)
    _kimchiName = widget.kimchiData.isNotEmpty ? widget.kimchiData[0]['name']?.toString() ?? '김치' : '김치';

    // widget.kimchiData에서 레시피 데이터 초기화
    if (widget.kimchiData.isNotEmpty) {
      _recipeSteps = widget.kimchiData.map((step) {
        String detail = step['recipe_detail']?.toString() ?? '레시피 단계 없음';
        // "숫자." 패턴이 여러 번 반복된 경우 모두 제거 (예: "1.", "1. 1.", "1. 1. 1.")
        return detail.replaceFirst(RegExp(r'(\d+\.\s*)+'), '').trim();
      }).toList();
      _stepImages = widget.kimchiData
          .map((step) => step['recipe_image_serial_num']?.toString() ?? 'assets/images/photo.png')
          .toList();
      _initialImagePath = _stepImages!.firstWhere(
        (image) => image != null && image.isNotEmpty,
        orElse: () => 'assets/images/photo.png',
      );

      for (int i = 0; i < _recipeSteps!.length && i < _stepImages!.length; i++) {
        _imageLoaded[i] = false;
        _preloadImage(i);
      }
    } else {
      _recipeSteps = ['레시피 데이터를 불러오지 못했습니다.'];
      _stepImages = ['assets/images/photo.png'];
    }

    print('Initialized _recipeSteps: $_recipeSteps');
    print('Initialized _stepImages: $_stepImages');
    print('Initialized _kimchiName: $_kimchiName');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // 페이지 종료 시 방향을 세로로 복원
    print('Disposing RecipePageDetail, restoring portrait orientation');
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _preloadImage(int step) async {
    if (_stepImages == null || step >= _stepImages!.length || _stepImages![step] == null || _stepImages![step]!.isEmpty) {
      setState(() {
        _imageLoaded[step] = true;
      });
      return;
    }

    try {
      print('Preloading image for step $step: ${_stepImages![step]}');
      final imageProvider = AssetImage(_stepImages![step]!);
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

  void _startRecipe() {
    print('Starting recipe...');
    if (_recipeSteps == null || _recipeSteps!.isEmpty) {
      print('Cannot start recipe: _recipeSteps is null or empty');
      return;
    }
    setState(() {
      _isRecipeStarted = true;
      _currentStep = 0;
    });
  }

  void _previousStep() {
    if (_currentStep > 0) {
      print('Going to previous step: ${_currentStep - 1}');
      setState(() {
        _currentStep--;
      });
      _scrollController.jumpTo(0);
    }
  }

  void _nextStep() {
    if (_recipeSteps != null && _recipeSteps!.isNotEmpty && _currentStep < _recipeSteps!.length - 1) {
      print('Going to next step: ${_currentStep + 1}');
      setState(() {
        _currentStep++;
      });
      _scrollController.jumpTo(0);
    }
  }

  Future<void> _captureRecipeImage() async {
    print('Capturing recipe image...');
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

    setState(() {
      _isCapturing = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _captureAndSaveImage();
      setState(() {
        _isCapturing = false;
      });
    });
  }

  Future<void> _captureAndSaveImage() async {
    try {
      print('Saving recipe image to gallery...');
      final RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/recipe_${DateTime.now().millisecondsSinceEpoch}.png').writeAsBytes(pngBytes);

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

  // 방향 변경 시 해당 방향으로 고정하는 메서드
  Future<void> _lockOrientation(Orientation orientation) async {
    if (_lastOrientation != orientation) {
      print('Locking orientation to: $orientation');
      _lastOrientation = orientation;
      if (orientation == Orientation.portrait) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      } else {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building RecipePageDetail...');
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
                print('Orientation changed to: $orientation');
                // 방향 변경 시 해당 방향으로 고정
                _lockOrientation(orientation);

                // 세로/가로 모드에 따라 적절한 UI 렌더링
                return orientation == Orientation.portrait
                    ? _buildPortraitLayout(widthRatio, heightRatio, screenWidth)
                    : _buildLandscapeLayout(widthRatio, heightRatio, screenWidth, screenHeight);
              },
            ),
            Positioned(
              left: -9999,
              child: Visibility(
                visible: _isCapturing,
                child: RepaintBoundary(
                  key: _repaintBoundaryKey,
                  child: Container(
                    color: Colors.white,
                    child: _recipeSteps != null && _recipeSteps!.isNotEmpty
                        ? Column(
                            children: List.generate(_recipeSteps!.length, (index) {
                              return Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Text(
                                      '${index + 1}. ${_recipeSteps![index]}',
                                      style: const TextStyle(fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 10),
                                    _stepImages != null &&
                                            index < _stepImages!.length &&
                                            _stepImages![index] != null &&
                                            _stepImages![index]!.isNotEmpty
                                        ? Image.asset(
                                            _stepImages![index]!,
                                            width: 300,
                                            height: 200,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) {
                                              print('Error loading capture image for step $index: $error');
                                              return const Text('이미지 없음');
                                            },
                                          )
                                        : const Text('이미지 없음'),
                                  ],
                                ),
                              );
                            }),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 세로 모드 UI를 렌더링하는 메서드
  Widget _buildPortraitLayout(double widthRatio, double heightRatio, double screenWidth) {
    print('Rendering portrait layout...');
    return Column(
      children: [
        // 상단바: 앱의 상단에 표시되는 네비게이션 바
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
        // 메인 콘텐츠: 초기 화면 또는 레시피 단계 화면 표시
        Expanded(
          child: Container(
            color: const Color(0xFFF5E9D6),
            child: _isRecipeStarted ? _buildRecipeStepsPortrait() : _buildInitialViewPortrait(),
          ),
        ),
      ],
    );
  }

  // 가로 모드 UI를 렌더링하는 메서드
  Widget _buildLandscapeLayout(double widthRatio, double heightRatio, double screenWidth, double screenHeight) {
    print('Rendering landscape layout...');
    return SingleChildScrollView(
      child: Row(
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
          // 메인 콘텐츠: 초기 화면 또는 레시피 단계 화면 표시
          Expanded(
            child: Container(
              color: const Color(0xFFF5E9D6),
              child: _isRecipeStarted ? _buildRecipeStepsLandscape() : _buildInitialViewPortrait(),
            ),
          ),
        ],
      ),
    );
  }

  // 세로 모드에서 초기 화면(김치 이름과 설명)을 렌더링
  Widget _buildInitialViewPortrait() {
    print('Building initial view (portrait)...');
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              print('Navigating back to MainPage...');
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
          const SizedBox(height: 10),
          Text(
            _kimchiName ?? '김치',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset(
                  _initialImagePath ?? 'assets/images/cabbagekimchi.png',
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading initial image $_initialImagePath: $error');
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
          Center(
            child: ElevatedButton(
              onPressed: (_recipeSteps != null && _recipeSteps!.isNotEmpty) ? _startRecipe : null,
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

  // 세로 모드에서 레시피 단계 화면을 렌더링
  Widget _buildRecipeStepsPortrait() {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthRatio = screenWidth / 1080;
    final heightRatio = MediaQuery.of(context).size.height / 2400;

    print('Building recipe steps (portrait)...');
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              print('Navigating back to MainPage from recipe steps...');
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
          const SizedBox(height: 10),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: (_stepImages != null &&
                      _stepImages!.isNotEmpty &&
                      _currentStep < _stepImages!.length &&
                      _stepImages![_currentStep] != null &&
                      _stepImages![_currentStep]!.isNotEmpty)
                  ? (_imageLoaded[_currentStep] == true
                      ? AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.asset(
                            _stepImages![_currentStep]!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading step image ${_stepImages![_currentStep]}: $error');
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
                  child: (_recipeSteps != null &&
                          _recipeSteps!.isNotEmpty &&
                          _currentStep < _recipeSteps!.length)
                      ? Text(
                          '${_currentStep + 1}. ${_recipeSteps![_currentStep]}',
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        )
                      : const Text(
                          '레시피 단계가 없습니다.',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
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
                onPressed: (_recipeSteps != null &&
                        _recipeSteps!.isNotEmpty &&
                        _currentStep < _recipeSteps!.length - 1)
                    ? _nextStep
                    : null,
                icon: const Icon(Icons.arrow_forward),
                color: (_recipeSteps != null &&
                        _recipeSteps!.isNotEmpty &&
                        _currentStep < _recipeSteps!.length - 1)
                    ? Colors.black
                    : Colors.grey,
              ),
            ],
          ),
          if (_recipeSteps != null &&
              _recipeSteps!.isNotEmpty &&
              _currentStep == _recipeSteps!.length - 1) ...[
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

  // 가로 모드에서 레시피 단계 화면을 렌더링
  Widget _buildRecipeStepsLandscape() {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthRatio = screenWidth / 1080;
    final heightRatio = MediaQuery.of(context).size.height / 2400;

    print('Building recipe steps (landscape)...');
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    print('Navigating back to MainPage from recipe steps (landscape)...');
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    width: MediaQuery.of(context).size.width - 68,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: (_stepImages != null &&
                              _stepImages!.isNotEmpty &&
                              _currentStep < _stepImages!.length &&
                              _stepImages![_currentStep] != null &&
                              _stepImages![_currentStep]!.isNotEmpty)
                          ? (_imageLoaded[_currentStep] == true
                              ? AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Image.asset(
                                    _stepImages![_currentStep]!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Error loading step image ${_stepImages![_currentStep]} (landscape): $error');
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _currentStep == 0 ? null : _previousStep,
                  icon: const Icon(Icons.arrow_back),
                  color: _currentStep == 0 ? Colors.grey : Colors.black,
                ),
                const SizedBox(width: 10),
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
                      child: (_recipeSteps != null &&
                              _recipeSteps!.isNotEmpty &&
                              _currentStep < _recipeSteps!.length)
                          ? Text(
                              '${_currentStep + 1}. ${_recipeSteps![_currentStep]}',
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            )
                          : const Text(
                              '레시피 단계가 없습니다.',
                              style: TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: (_recipeSteps != null &&
                          _recipeSteps!.isNotEmpty &&
                          _currentStep < _recipeSteps!.length - 1)
                      ? _nextStep
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  color: (_recipeSteps != null &&
                          _recipeSteps!.isNotEmpty &&
                          _currentStep < _recipeSteps!.length - 1)
                      ? Colors.black
                      : Colors.grey,
                ),
              ],
            ),
            if (_recipeSteps != null &&
                _recipeSteps!.isNotEmpty &&
                _currentStep == _recipeSteps!.length - 1) ...[
              const SizedBox(height: 10),
              Center(
                child: SizedBox(
                  width: 300 * widthRatio,
                  child: ElevatedButton(
                    onPressed: _captureRecipeImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 10 * heightRatio),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      '레시피 저장하기',
                      style: TextStyle(
                        fontSize: 24 * widthRatio,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}