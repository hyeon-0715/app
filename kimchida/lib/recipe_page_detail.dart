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
  Orientation? _lastOrientation;

  @override
  void initState() {
    super.initState();
    print('Initializing RecipePageDetail with all orientations allowed');

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]).then((_) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {});
        });
      }
    });

    _kimchiName = widget.kimchiData.isNotEmpty ? widget.kimchiData[0]['name']?.toString() ?? '김치' : '김치';

    if (widget.kimchiData.isNotEmpty) {
      _recipeSteps = widget.kimchiData.map((step) {
        String detail = step['recipe_detail']?.toString() ?? '레시피 단계 없음';
        return detail.replaceFirst(RegExp(r'(\d+\.\s*)+'), '').trim();
      }).toList();
      _stepImages = widget.kimchiData
          .map((step) => step['recipe_image_serial_num']?.toString() ?? 'assets/images/photo.png')
          .toList();
      _initialImagePath = _stepImages!.firstWhere(
        (image) => image != null && image.isNotEmpty,
        orElse: () => 'assets/images/photo.png',
      );

      print('Initialized _recipeSteps: $_recipeSteps');
      print('Initialized _stepImages: $_stepImages');
      print('Initialized _kimchiName: $_kimchiName');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (int i = 0; i < _recipeSteps!.length && i < _stepImages!.length; i++) {
          _imageLoaded[i] = false;
          _preloadImage(i);
        }
      });
    } else {
      _recipeSteps = ['레시피 데이터를 불러오지 못했습니다.'];
      _stepImages = ['assets/images/photo.png'];
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    print('Disposing RecipePageDetail, restoring portrait orientation');
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _preloadImage(int step) async {
    if (_stepImages == null || step >= _stepImages!.length || _stepImages![step] == null || _stepImages![step]!.isEmpty) {
      if (mounted) {
        setState(() {
          _imageLoaded[step] = true;
        });
      }
      return;
    }

    try {
      print('Preloading image for step $step: ${_stepImages![step]}');
      if (_stepImages![step]!.startsWith('http://') || _stepImages![step]!.startsWith('https://')) {
        await precacheImage(NetworkImage(_stepImages![step]!), context);
      } else {
        await precacheImage(AssetImage(_stepImages![step]!), context);
      }
      if (mounted) {
        setState(() {
          _imageLoaded[step] = true;
        });
      }
    } catch (e) {
      print('Error preloading image for step $step: $e');
      if (mounted) {
        setState(() {
          _imageLoaded[step] = true;
        });
      }
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
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
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

  Future<void> _lockOrientation(Orientation orientation) async {
    if (_lastOrientation != orientation) {
      print('Locking orientation to: $orientation');
      _lastOrientation = orientation;
      if (orientation == Orientation.portrait) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
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
    const double baseWidth = 2400;
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
                _lockOrientation(orientation);

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
                                        ? (_stepImages![index]!.startsWith('http://') ||
                                                _stepImages![index]!.startsWith('https://')
                                            ? Image.network(
                                                _stepImages![index]!,
                                                width: 300,
                                                height: 200,
                                                fit: BoxFit.contain,
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) return child;
                                                  return const Center(child: CircularProgressIndicator());
                                                },
                                                errorBuilder: (context, error, stackTrace) {
                                                  print('Error loading capture network image for step $index: $error');
                                                  return Image.asset(
                                                    'assets/images/photo.png',
                                                    width: 300,
                                                    height: 200,
                                                    fit: BoxFit.contain,
                                                  );
                                                },
                                              )
                                            : Image.asset(
                                                _stepImages![index]!,
                                                width: 300,
                                                height: 200,
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) {
                                                  print('Error loading capture asset image for step $index: $error');
                                                  return const Text('이미지 없음');
                                                },
                                              ))
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

  Widget _buildPortraitLayout(double widthRatio, double heightRatio, double screenWidth) {
    print('Rendering portrait layout...');
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
        Expanded(
          child: Container(
            color: const Color(0xFFF5E9D6),
            child: _isRecipeStarted ? _buildRecipeStepsPortrait() : _buildInitialViewPortrait(),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(double widthRatio, double heightRatio, double screenWidth, double screenHeight) {
    print('Rendering landscape layout...');
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
          child: Container(
            color: const Color(0xFFF5E9D6),
            child: _isRecipeStarted ? _buildRecipeStepsLandscape() : _buildInitialViewLandscape(),
          ),
        ),
      ],
    );
  }

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
              print('Navigating back to RecipePage...');
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 10),
          Text(
            _kimchiName ?? '김치',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _initialImagePath != null && _initialImagePath!.isNotEmpty
                    ? (_initialImagePath!.startsWith('http://') || _initialImagePath!.startsWith('https://')
                        ? Image.network(
                            _initialImagePath!,
                            width: MediaQuery.of(context).size.width,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator());
                            },
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading initial network image $_initialImagePath: $error');
                              return Image.asset(
                                'assets/images/cabbagekimchi.png',
                                width: MediaQuery.of(context).size.width,
                                fit: BoxFit.contain,
                              );
                            },
                          )
                        : Image.asset(
                            _initialImagePath!,
                            width: MediaQuery.of(context).size.width,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading initial asset image $_initialImagePath: $error');
                              return const Center(
                                child: Text(
                                  '이미지를 로드할 수 없습니다.',
                                  style: TextStyle(fontSize: 16),
                                ),
                              );
                            },
                          ))
                    : Image.asset(
                        'assets/images/cabbagekimchi.png',
                        width: MediaQuery.of(context).size.width,
                        fit: BoxFit.contain,
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

  Widget _buildInitialViewLandscape() {
    print('Building initial view (landscape)...');
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
                    print('Navigating back to RecipePage from initial view (landscape)...');
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    width: MediaQuery.of(context).size.width - 68,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: _initialImagePath != null && _initialImagePath!.isNotEmpty
                          ? (_initialImagePath!.startsWith('http://') || _initialImagePath!.startsWith('https://')
                              ? Image.network(
                                  _initialImagePath!,
                                  fit: BoxFit.contain,
                                  height: 200,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(child: CircularProgressIndicator());
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Error loading initial network image $_initialImagePath (landscape): $error');
                                    return Image.asset(
                                      'assets/images/cabbagekimchi.png',
                                      fit: BoxFit.contain,
                                      height: 200,
                                    );
                                  },
                                )
                              : Image.asset(
                                  _initialImagePath!,
                                  fit: BoxFit.contain,
                                  height: 200,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Error loading initial asset image $_initialImagePath (landscape): $error');
                                    return const Center(
                                      child: Text(
                                        '이미지를 로드할 수 없습니다.',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    );
                                  },
                                ))
                          : Image.asset(
                              'assets/images/cabbagekimchi.png',
                              fit: BoxFit.contain,
                              height: 200,
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
                const SizedBox(width: 10),
                Container(
                  width: 300,
                  height: 50,
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      _kimchiName ?? '김치',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
            const SizedBox(height: 20),
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
      ),
    );
  }

  Widget _buildRecipeStepsPortrait() {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthRatio = screenWidth / 1080;
    final heightRatio = MediaQuery.of(context).size.height / 2400;

    const double containerHeight = 300;
    final containerWidth = screenWidth - 32.0;

    const double recipeTextFontSize = 25;

    const double recipeContainerWidth = 300;
    const double recipeContainerHeight = 120;

    print('Building recipe steps (portrait)...');
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              print('Navigating back to RecipePage from recipe steps...');
              Navigator.pop(context);
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: containerWidth,
                  height: containerHeight,
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
                            ? _stepImages![_currentStep]!.startsWith('http://') ||
                                    _stepImages![_currentStep]!.startsWith('https://')
                                ? Image.network(
                                    _stepImages![_currentStep]!,
                                    fit: BoxFit.contain,
                                    height: containerHeight,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(child: CircularProgressIndicator());
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Error loading step network image ${_stepImages![_currentStep]}: $error');
                                      return Image.asset(
                                        'assets/images/photo.png',
                                        fit: BoxFit.contain,
                                        height: containerHeight,
                                      );
                                    },
                                  )
                                : Image.asset(
                                    _stepImages![_currentStep]!,
                                    fit: BoxFit.contain,
                                    height: containerHeight,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Error loading step asset image ${_stepImages![_currentStep]}: $error');
                                      return const Center(
                                        child: Text(
                                          '이미지를 로드할 수 없습니다.',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      );
                                    },
                                  )
                            : const Center(child: CircularProgressIndicator()))
                        : const Text(
                            '이미지가 없습니다',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: recipeContainerWidth,
                  height: recipeContainerHeight,
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: (_recipeSteps != null &&
                            _recipeSteps!.isNotEmpty &&
                            _currentStep < _recipeSteps!.length)
                        ? Text(
                            '${_currentStep + 1}. ${_recipeSteps![_currentStep]}',
                            style: TextStyle(fontSize: recipeTextFontSize),
                            textAlign: TextAlign.center,
                          )
                        : const Text(
                            '레시피 단계가 없습니다.',
                            style: TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),
                const SizedBox(height: 10),
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
                  const SizedBox(height: 10),
                  SizedBox(
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
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 가로모드 레시피 내용
  Widget _buildRecipeStepsLandscape() {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthRatio = screenWidth / 1080;
    final heightRatio = MediaQuery.of(context).size.height / 2400;

    const double containerHeight = 200;
    final containerWidth = screenWidth - 68;

    const double recipeTextFontSize = 28;

    const double recipeContainerWidth = 450;
    const double recipeContainerHeight = 80;

    print('Building recipe steps (landscape)...');
    return Padding(
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
                  print('Navigating back to RecipePage from recipe steps (landscape)...');
                  Navigator.pop(context);
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  width: containerWidth,
                  height: containerHeight,
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
                            ? _stepImages![_currentStep]!.startsWith('http://') ||
                                    _stepImages![_currentStep]!.startsWith('https://')
                                ? Image.network(
                                    _stepImages![_currentStep]!,
                                    fit: BoxFit.contain,
                                    height: containerHeight,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(child: CircularProgressIndicator());
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Error loading step network image ${_stepImages![_currentStep]} (landscape): $error');
                                      return Image.asset(
                                        'assets/images/photo.png',
                                        fit: BoxFit.contain,
                                        height: containerHeight,
                                      );
                                    },
                                  )
                                : Image.asset(
                                    _stepImages![_currentStep]!,
                                    fit: BoxFit.contain,
                                    height: containerHeight,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Error loading step asset image ${_stepImages![_currentStep]} (landscape): $error');
                                      return const Center(
                                        child: Text(
                                          '이미지를 로드할 수 없습니다.',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      );
                                    },
                                  )
                            : const Center(child: CircularProgressIndicator()))
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
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                      width: recipeContainerWidth,
                      height: recipeContainerHeight,
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: (_recipeSteps != null &&
                                _recipeSteps!.isNotEmpty &&
                                _currentStep < _recipeSteps!.length)
                            ? Text(
                                '${_currentStep + 1}. ${_recipeSteps![_currentStep]}',
                                style: TextStyle(fontSize: recipeTextFontSize),
                                textAlign: TextAlign.center,
                              )
                            : const Text(
                                '레시피 단계가 없습니다.',
                                style: TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
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
                  SizedBox(
                    width: 250 * widthRatio,
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
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}