import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'main_page.dart';
import 'recipe_page.dart';
import 'user_page.dart';
import 'recipe_page_detail.dart'; // RecipePageDetail 임포트
import '../utils/permission_helper.dart'; // PermissionHelper 임포트

class UserRecipePage extends StatefulWidget {
  final String inputMode; // 입력 모드: 'photo' 또는 'text'

  const UserRecipePage({super.key, required this.inputMode});

  @override
  _UserRecipePageState createState() => _UserRecipePageState();
}

class _UserRecipePageState extends State<UserRecipePage> {
  List<XFile> _selectedImages = []; // 여러 장 이미지를 저장하기 위한 리스트 (photo 모드에서 사용)
  List<Map<String, String>> _imageDetails = []; // 첨부한 이미지의 이름과 경로를 저장하기 위한 리스트 (photo 모드에서 사용)
  static const int _maxImageCount = 10; // 최대 첨부 가능 이미지 수 (나중에 수정 가능)
  final TextEditingController _titleController = TextEditingController(); // 텍스트 모드: 레시피 제목 입력 컨트롤러
  final TextEditingController _contentController = TextEditingController(); // 텍스트 모드: 레시피 내용 입력 컨트롤러
  final FocusNode _titleFocusNode = FocusNode(); // 제목 입력 칸 포커스 노드
  final FocusNode _contentFocusNode = FocusNode(); // 내용 입력 칸 포커스 노드
  bool _showTitleHint = true; // 제목 입력 칸 힌트 텍스트 표시 여부
  bool _showContentHint = true; // 내용 입력 칸 힌트 텍스트 표시 여부

  @override
  void initState() {
    super.initState();
    // 텍스트 모드일 때 초기 설정
    if (widget.inputMode == 'text') {
      _titleController.text = '';
      _contentController.text = '';
      // 포커스 노드 리스너 추가
      _titleFocusNode.addListener(() {
        setState(() {
          if (!_titleFocusNode.hasFocus && _titleController.text.isEmpty) {
            _showTitleHint = true;
          }
        });
      });
      _contentFocusNode.addListener(() {
        setState(() {
          if (!_contentFocusNode.hasFocus && _contentController.text.isEmpty) {
            _showContentHint = true;
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  // 이미지 소스 선택 다이얼로그 표시
  void _showImageSourceDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const double baseWidth = 1080;
    const double baseHeight = 2400;
    final widthRatio = screenWidth / baseWidth;
    final heightRatio = screenHeight / baseHeight;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF5E9D6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: EdgeInsets.all(20 * widthRatio),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '사진 선택',
                style: TextStyle(
                  fontSize: 36 * widthRatio,
                  color: Colors.black,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40 * heightRatio),
              SizedBox(
                width: 300 * widthRatio,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _pickMultipleImages(); // 갤러리에서 선택
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 20 * heightRatio),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    '갤러리',
                    style: TextStyle(
                      fontSize: 36 * widthRatio,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20 * heightRatio),
              SizedBox(
                width: 300 * widthRatio,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _pickImageFromCamera(); // 카메라로 촬영
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 20 * heightRatio),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    '카메라',
                    style: TextStyle(
                      fontSize: 36 * widthRatio,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20 * heightRatio),
              SizedBox(
                width: 300 * widthRatio,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.green),
                    padding: EdgeInsets.symmetric(vertical: 20 * heightRatio),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    '취소',
                    style: TextStyle(
                      fontSize: 36 * widthRatio,
                      color: Colors.green,
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

  // 이미지 소스 선택 다이얼로그 표시
  void _handleMultiImageSelection() async {
    bool allPermissionsGranted = await PermissionHelper.checkPermissions();
    if (allPermissionsGranted) {
      _showImageSourceDialog(); // 권한이 허용된 경우 다이얼로그 표시
    } else {
      await PermissionHelper.requestPermissions(
        context,
        onPermissionsGranted: () {
          _showImageSourceDialog(); // 권한 요청 후 다이얼로그 표시
        },
      );
    }
  }

  // `image_picker` 패키지를 사용하여 갤러리에서 여러 장 이미지를 선택
  void _pickMultipleImages() async {
    try {
      final List<XFile> images = await ImagePicker().pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          int remainingSlots = _maxImageCount - _selectedImages.length;
          if (images.length > remainingSlots) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('최대 $_maxImageCount장까지 첨부 가능합니다.')),
            );
            _selectedImages.addAll(images.take(remainingSlots));
            for (var image in images.take(remainingSlots)) {
              _imageDetails.add({
                'name': image.name,
                'path': image.path,
              });
              print('첨부된 이미지 정보 - 이름: ${image.name}, 경로: ${image.path}');
            }
          } else {
            _selectedImages.addAll(images);
            for (var image in images) {
              _imageDetails.add({
                'name': image.name,
                'path': image.path,
              });
              print('첨부된 이미지 정보 - 이름: ${image.name}, 경로: ${image.path}');
            }
          }
        });
      }
    } catch (e) {
      print('Error picking multiple images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 선택 중 오류 발생: $e')),
        );
      }
    }
  }

  // `image_picker` 패키지를 사용하여 카메라로 사진 촬영
  void _pickImageFromCamera() async {
    try {
      final XFile? image = await ImagePicker().pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          if (_selectedImages.length >= _maxImageCount) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('최대 $_maxImageCount장까지 첨부 가능합니다.')),
            );
            return;
          }
          _selectedImages.add(image);
          _imageDetails.add({
            'name': image.name,
            'path': image.path,
          });
          print('첨부된 이미지 정보 - 이름: ${image.name}, 경로: ${image.path}');
        });
      }
    } catch (e) {
      print('Error picking image from camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('카메라 촬영 중 오류 발생: $e')),
        );
      }
    }
  }

  // 특정 인덱스의 이미지를 삭제하는 메서드
  void _removeImage(int index) {
    setState(() {
      _imageDetails.removeAt(index);
      _selectedImages.removeAt(index);
      print('이미지 삭제 후 남은 이미지 정보: $_imageDetails');
    });
  }

  // 서버로 이미지를 보내고 레시피 데이터를 받아오는 모의 메서드
  Future<List<Map<String, dynamic>>> _sendImagesToServer(List<XFile> images) async {
    // 서버 통신 시뮬레이션 (3초 지연)
    await Future.delayed(const Duration(seconds: 3));

    // 모의 레시피 데이터 반환
    return [
      {
        'name': '김치',
        'recipe_detail': '1',
        'recipe_image_serial_num': 'assets/images/cabbagekimchi.png',
      },
      {
        'recipe_detail': '2',
        'recipe_image_serial_num': 'assets/images/cabbagekimchi.png',
      },
    ];
  }

  // 서버로 텍스트를 보내고 레시피 데이터를 받아오는 모의 메서드
  Future<List<Map<String, dynamic>>> _sendTextToServer(String title, String content) async {
    // 서버 통신 시뮬레이션 (3초 지연)
    await Future.delayed(const Duration(seconds: 3));

    // 모의 레시피 데이터 반환
    return [
      {
        'name': title,
        'recipe_detail': '1',
        'recipe_image_serial_num': 'assets/images/cabbagekimchi.png',
      },
      {
        'recipe_detail': '2',
        'recipe_image_serial_num': 'assets/images/cabbagekimchi.png',
      },
    ];
  }

  // 완료 버튼 동작
  void _onComplete() async {
    if (widget.inputMode == 'photo' && _selectedImages.isNotEmpty) {
      // 로딩 페이지로 이동
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoadingPage()),
      );

      try {
        // 서버로 이미지 전송 및 레시피 데이터 수신
        final recipeData = await _sendImagesToServer(_selectedImages);

        // 로딩 완료 페이지로 이동
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoadingCompletePage(recipeData: recipeData),
            ),
          );
        }
      } catch (e) {
        // 에러 처리
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('서버 통신 중 오류 발생: $e')),
          );
          Navigator.pop(context); // 로딩 페이지 종료
        }
      }
    } else if (widget.inputMode == 'text' &&
        _titleController.text.isNotEmpty &&
        _contentController.text.isNotEmpty) {
      // 로딩 페이지로 이동
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoadingPage()),
      );

      try {
        // 서버로 텍스트 전송 및 레시피 데이터 수신
        final recipeData = await _sendTextToServer(_titleController.text, _contentController.text);

        // 로딩 완료 페이지로 이동
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoadingCompletePage(recipeData: recipeData),
            ),
          );
        }
      } catch (e) {
        // 에러 처리
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('서버 통신 중 오류 발생: $e')),
          );
          Navigator.pop(context); // 로딩 페이지 종료
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const double baseWidth = 1080;
    const double baseHeight = 2400;
    final widthRatio = screenWidth / baseWidth;
    final heightRatio = screenHeight / baseHeight;

    // 이미지 첨부 컨테이너의 너비를 화면 너비의 60%로 계산
    final containerWidth = screenWidth * 0.6;
    // 이미지 미리보기 크기: 컨테이너 크기의 40%
    final previewWidth = containerWidth * 0.4;
    final previewHeight = (400 * heightRatio) * 0.4;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF5E9D6),
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
            // 중단 섹션
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
                      'User recipe',
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
                  ],
                ),
              ),
            ),
            // 하단 섹션
            Expanded(
              child: SingleChildScrollView(
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
                          widget.inputMode == 'photo' ? '사진' : '텍스트',
                          style: TextStyle(
                            fontSize: 60 * widthRatio,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      SizedBox(height: 30 * heightRatio),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 60 * widthRatio),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20 * widthRatio),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.inputMode == 'photo'
                                    ? '사용하시고 싶으신 레시피 사진을 올려주세요'
                                    : '사용하시고 싶으신 레시피를 작성해주세요',
                                style: TextStyle(
                                  fontSize: 36 * widthRatio,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 20 * heightRatio),
                              Center(
                                child: Container(
                                  width: containerWidth,
                                  height: widget.inputMode == 'photo'
                                      ? 400 * heightRatio
                                      : 600 * heightRatio,
                                  decoration: BoxDecoration(
                                    color: widget.inputMode == 'photo'
                                        ? Colors.white
                                        : const Color(0xFFE5D9C6),
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(10),
                                    image: widget.inputMode == 'photo'
                                        ? const DecorationImage(
                                            image: AssetImage('assets/images/void.png'),
                                            fit: BoxFit.cover,
                                            opacity: 0.2,
                                          )
                                        : null,
                                  ),
                                  child: widget.inputMode == 'photo'
                                      ? Stack(
                                          children: [
                                            if (_selectedImages.isEmpty)
                                              GestureDetector(
                                                onTap: _handleMultiImageSelection,
                                                child: Center(
                                                  child: Icon(
                                                    Icons.add,
                                                    size: 100 * widthRatio,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ),
                                            if (_selectedImages.isNotEmpty)
                                              Stack(
                                                children: [
                                                  ..._selectedImages.asMap().entries.map((entry) {
                                                    int index = entry.key;
                                                    XFile image = entry.value;
                                                    double offset = (_selectedImages.length - 1 - index) * 10.0;
                                                    return Center(
                                                      child: Container(
                                                        margin: EdgeInsets.only(right: offset),
                                                        width: previewWidth,
                                                        height: previewHeight,
                                                        decoration: BoxDecoration(
                                                          border: Border.all(color: Colors.grey),
                                                          borderRadius: BorderRadius.circular(5),
                                                          boxShadow: const [
                                                            BoxShadow(
                                                              color: Colors.black26,
                                                              blurRadius: 4,
                                                              offset: Offset(2, 2),
                                                            ),
                                                          ],
                                                        ),
                                                        child: ClipRRect(
                                                          borderRadius: BorderRadius.circular(5),
                                                          child: Image.file(
                                                            File(image.path),
                                                            width: previewWidth,
                                                            height: previewHeight,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  }).toList().reversed.toList(),
                                                  Positioned(
                                                    top: 5,
                                                    right: 5,
                                                    child: GestureDetector(
                                                      onTap: () => _removeImage(0),
                                                      child: Container(
                                                        padding: EdgeInsets.all(5 * widthRatio),
                                                        decoration: const BoxDecoration(
                                                          color: Colors.red,
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: Icon(
                                                          Icons.close,
                                                          size: 60 * widthRatio,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    bottom: 5,
                                                    left: 5,
                                                    child: GestureDetector(
                                                      onTap: _handleMultiImageSelection,
                                                      child: Container(
                                                        padding: EdgeInsets.all(5 * widthRatio),
                                                        decoration: const BoxDecoration(
                                                          color: Colors.green,
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: Icon(
                                                          Icons.add,
                                                          size: 60 * widthRatio,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    bottom: 5,
                                                    right: 5,
                                                    child: Container(
                                                      width: 30 * widthRatio,
                                                      height: 30 * widthRatio,
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        border: Border.all(color: Colors.grey),
                                                        borderRadius: BorderRadius.circular(5),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          '${_selectedImages.length}',
                                                          style: TextStyle(
                                                            fontSize: 16 * widthRatio,
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        )
                                      : Padding(
                                          padding: EdgeInsets.all(20 * widthRatio),
                                          child: Column(
                                            children: [
                                              TextField(
                                                controller: _titleController,
                                                focusNode: _titleFocusNode,
                                                decoration: InputDecoration(
                                                  hintText: _showTitleHint ? '레시피 제목을 적어주세요' : null,
                                                  hintStyle: TextStyle(
                                                    color: Colors.grey[400],
                                                    fontSize: 36 * widthRatio,
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                    borderSide: const BorderSide(color: Colors.grey),
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 36 * widthRatio,
                                                  color: Colors.black,
                                                ),
                                                onChanged: (value) {
                                                  setState(() {
                                                    _showTitleHint = value.isEmpty;
                                                  });
                                                },
                                              ),
                                              SizedBox(height: 20 * heightRatio),
                                              Expanded(
                                                child: SingleChildScrollView(
                                                  child: TextField(
                                                    controller: _contentController,
                                                    focusNode: _contentFocusNode,
                                                    decoration: InputDecoration(
                                                      hintText: _showContentHint
                                                          ? '1. 겉절이 채소는 양상추, 치커리, 샐러드채소를 준비하여 물에 씻어 먹기 좋은 크기로 썬다.\n2. 당근 양념을 만든다...'
                                                          : null,
                                                      hintStyle: TextStyle(
                                                        color: Colors.grey[400],
                                                        fontSize: 36 * widthRatio,
                                                      ),
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(10),
                                                        borderSide: const BorderSide(color: Colors.grey),
                                                      ),
                                                      filled: true,
                                                      fillColor: Colors.white,
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 36 * widthRatio,
                                                      color: Colors.black,
                                                    ),
                                                    maxLines: null,
                                                    keyboardType: TextInputType.multiline,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        _showContentHint = value.isEmpty;
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                              SizedBox(height: 20 * heightRatio),
                              Center(
                                child: SizedBox(
                                  width: 300 * widthRatio,
                                  child: ElevatedButton(
                                    onPressed: (widget.inputMode == 'photo' && _selectedImages.isNotEmpty) ||
                                            (widget.inputMode == 'text' &&
                                                _titleController.text.isNotEmpty &&
                                                _contentController.text.isNotEmpty)
                                        ? _onComplete
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: (widget.inputMode == 'photo' && _selectedImages.isNotEmpty) ||
                                              (widget.inputMode == 'text' &&
                                                  _titleController.text.isNotEmpty &&
                                                  _contentController.text.isNotEmpty)
                                          ? Colors.green
                                          : Colors.grey,
                                      padding: EdgeInsets.symmetric(vertical: 20 * heightRatio),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      '완료',
                                      style: TextStyle(
                                        fontSize: 36 * widthRatio,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                height: 20 * heightRatio,
                                color: const Color(0xFFF5E9D6),
                              ),
                            ],
                          ),
                        ),
                      ),
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
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const RecipePage()),
                );
              },
              icon: Image.asset(
                'assets/images/cabbage.png',
                width: 60 * widthRatio,
                height: 60 * heightRatio,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.pushReplacement(
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

// 로딩 페이지
class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  _LoadingPageState createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // AnimationController 초기화: 2초마다 한 바퀴 회전
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(); // 계속 회전
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const double baseWidth = 1080;
    const double baseHeight = 2400;
    final widthRatio = screenWidth / baseWidth;
    final heightRatio = screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: const Color(0xFFF5E9D6),
      body: SafeArea(
        child: Column(
          children: [
            // 상단바: UserRecipePage와 동일
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
            // 중단 섹션: UserRecipePage와 동일
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
                      'User recipe',
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
                  ],
                ),
              ),
            ),
            // 하단 섹션: 로딩 내용
            Expanded(
              child: Container(
                color: const Color(0xFFF5E9D6),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '레시피와 이미지 생성 중',
                        style: TextStyle(
                          fontSize: 36 * widthRatio,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 20 * heightRatio),
                      RotationTransition(
                        turns: _controller,
                        child: Image.asset(
                          'assets/images/gear.png',
                          width: 100 * widthRatio,
                          height: 100 * heightRatio,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // 하단바: UserRecipePage와 동일
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
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const RecipePage()),
                );
              },
              icon: Image.asset(
                'assets/images/cabbage.png',
                width: 60 * widthRatio,
                height: 60 * heightRatio,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.pushReplacement(
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

// 로딩 완료 페이지
class LoadingCompletePage extends StatelessWidget {
  final List<Map<String, dynamic>> recipeData; // 서버에서 받은 레시피 데이터

  const LoadingCompletePage({super.key, required this.recipeData});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const double baseWidth = 1080;
    const double baseHeight = 2400;
    final widthRatio = screenWidth / baseWidth;
    final heightRatio = screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: const Color(0xFFF5E9D6),
      body: SafeArea(
        child: Column(
          children: [
            // 상단바: UserRecipePage와 동일
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
            // 중단 섹션: UserRecipePage와 동일
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
                      'User recipe',
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
                  ],
                ),
              ),
            ),
            // 하단 섹션: 로딩 완료 내용
            Expanded(
              child: Container(
                color: const Color(0xFFF5E9D6),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/chatbot.png',
                        width: 150 * widthRatio,
                        height: 150 * heightRatio,
                      ),
                      SizedBox(height: 20 * heightRatio),
                      Text(
                        '생성 완료',
                        style: TextStyle(
                          fontSize: 36 * widthRatio,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 20 * heightRatio),
                      SizedBox(
                        width: 300 * widthRatio,
                        child: ElevatedButton(
                          onPressed: () {
                            // RecipePageDetail로 이동
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecipePageDetail(kimchiData: recipeData),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(vertical: 20 * heightRatio),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            '레시피 확인',
                            style: TextStyle(
                              fontSize: 36 * widthRatio,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // 하단바: UserRecipePage와 동일
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
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const RecipePage()),
                );
              },
              icon: Image.asset(
                'assets/images/cabbage.png',
                width: 60 * widthRatio,
                height: 60 * heightRatio,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.pushReplacement(
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