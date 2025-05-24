import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'main_page.dart';
import 'recipe_page.dart';
import 'user_page.dart';
import 'recipe_page_detail.dart';
import 'kimchi_recipe.dart';
import '../utils/permission_helper.dart';

// 유저가 새로운 김치 레시피를 등록하는 페이지
// inputMode: 'photo' (사진 기반) 또는 'text' (텍스트 기반) 레시피 입력 모드
class UserRecipePage extends StatefulWidget {
  final String inputMode;

  const UserRecipePage({super.key, required this.inputMode});

  @override
  _UserRecipePageState createState() => _UserRecipePageState();
}

class _UserRecipePageState extends State<UserRecipePage> {
  List<XFile> _selectedImages = []; // 선택된 이미지 파일 리스트
  List<Map<String, String>> _imageDetails = []; // 이미지 메타데이터 (이름, 경로)
  static const int _maxImageCount = 10; // 최대 이미지 첨부 개수
  final TextEditingController _titleController = TextEditingController(); // 레시피 제목 입력 컨트롤러
  final TextEditingController _contentController = TextEditingController(); // 레시피 내용 입력 컨트롤러
  final FocusNode _titleFocusNode = FocusNode(); // 제목 입력 포커스 노드
  final FocusNode _contentFocusNode = FocusNode(); // 내용 입력 포커스 노드
  bool _showTitleHint = true; // 제목 힌트 텍스트 표시 여부
  bool _showContentHint = true; // 내용 힌트 텍스트 표시 여부
  bool isSubmitting = false; // 제출 진행 중 여부
  String? errorMessage; // 에러 메시지

  @override
  void initState() {
    super.initState();
    print('UserRecipePage initState called, inputMode: ${widget.inputMode}');
    if (widget.inputMode == 'text') {
      _titleController.text = '';
      _contentController.text = '';
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (isSubmitting) {
      setState(() {
        isSubmitting = false;
        errorMessage = null;
      });
    }
  }

  @override
  void dispose() {
    print('UserRecipePage dispose called');
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  // 이미지 소스 선택 다이얼로그 표시 (갤러리 또는 카메라)
  void _showImageSourceDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const double baseWidth = 1080;
    const double baseHeight = 2400;
    final widthRatio = screenWidth / baseWidth;
    final heightRatio = screenHeight / baseHeight;

    print('Showing image source dialog...');
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
                    print('Gallery button pressed');
                    Navigator.pop(dialogContext);
                    _pickMultipleImages();
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
                    print('Camera button pressed');
                    Navigator.pop(dialogContext);
                    _pickImageFromCamera();
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
                    print('Cancel button pressed');
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

  // 다중 이미지 선택 처리: 권한 확인 후 다이얼로그 표시
  void _handleMultiImageSelection() async {
    print('Handling multi image selection...');
    bool allPermissionsGranted = await PermissionHelper.checkPermissions();
    if (allPermissionsGranted) {
      _showImageSourceDialog();
    } else {
      await PermissionHelper.requestPermissions(
        context,
        onPermissionsGranted: () {
          _showImageSourceDialog();
        },
      );
    }
  }

  // 갤러리에서 다중 이미지 선택
  void _pickMultipleImages() async {
    try {
      print('Picking multiple images...');
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

  // 카메라로 이미지 촬영
  void _pickImageFromCamera() async {
    try {
      print('Picking image from camera...');
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

  // 선택된 이미지 삭제
  void _removeImage(int index) {
    print('Removing image at index: $index');
    setState(() {
      _imageDetails.removeAt(index);
      _selectedImages.removeAt(index);
      print('이미지 삭제 후 남은 이미지 정보: $_imageDetails');
    });
  }

  // 완료 버튼 클릭 시 레시피 제출 처리
  void _onComplete() async {
    if (widget.inputMode == 'photo' && _selectedImages.isNotEmpty) {
      print('Submitting photo recipe...');
      setState(() {
        isSubmitting = true;
        errorMessage = null;
      });

      try {
        List<Map<String, dynamic>> recipeData = [
          {'recipe_order': 1, 'recipe_detail': '사진 레시피가 제출되었습니다.'}
        ];

        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoadingPage(
                inputMode: 'photo',
                recipeData: recipeData,
                selectedImages: _selectedImages,
                onReturn: () {
                  setState(() {
                    isSubmitting = false;
                    errorMessage = null;
                  });
                },
              ),
            ),
          );
        }
      } catch (e) {
        print('Error in _onComplete (photo): $e');
        setState(() {
          isSubmitting = false;
          errorMessage = '서버 통신 중 오류 발생: $e';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('서버 통신 중 오류 발생: $e')),
          );
        }
      }
    } else if (widget.inputMode == 'text' &&
        _titleController.text.isNotEmpty &&
        _contentController.text.isNotEmpty) {
      print('Submitting text recipe...');
      setState(() {
        isSubmitting = true;
        errorMessage = null;
      });

      try {
        final stepsContent = _contentController.text.split('\n');
        List<Map<String, dynamic>> recipeData = [];
        List<Map<String, dynamic>> steps = [];
        int kimchiNum = DateTime.now().millisecondsSinceEpoch;

        for (int i = 0; i < stepsContent.length; i++) {
          String stepDetail = stepsContent[i].trim();
          if (stepDetail.isNotEmpty) {
            String cleanedStepDetail = stepDetail.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
            recipeData.add({
              'kimchi_num': kimchiNum,
              'name': _titleController.text,
              'recipe_order': i + 1,
              'recipe_detail': cleanedStepDetail,
              'recipe_image_serial_num': '',
            });
            steps.add({
              'recipe_order': i + 1,
              'recipe_detail': stepDetail,
            });
          }
        }

        print('Processed recipeData (for display): $recipeData');
        print('Processed steps (for server): $steps');

        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TextProcessingPage(
                title: _titleController.text,
                steps: steps,
                recipeData: recipeData,
                onReturn: () {
                  setState(() {
                    isSubmitting = false;
                    errorMessage = null;
                  });
                },
              ),
            ),
          );
        }
      } catch (e) {
        print('Error in _onComplete (text): $e');
        setState(() {
          isSubmitting = false;
          errorMessage = '서버 통신 중 오류 발생: $e';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('서버 통신 중 오류 발생: $e')),
          );
        }
      }
    }
  }

  // 사진 레시피를 서버에 제출
  Future<http.Response> _submitPhotoRecipe() async {
    const String url = 'http://ec2-47-130-90-43.ap-southeast-1.compute.amazonaws.com:8080/userRecipe/photo';
    var request = http.MultipartRequest('POST', Uri.parse(url));

    for (int i = 0; i < _selectedImages.length; i++) {
      final image = _selectedImages[i];
      final file = await http.MultipartFile.fromPath(
        'images[$i]',
        image.path,
        filename: image.name,
      );
      request.files.add(file);
    }

    request.fields['recipe_type'] = 'photo';
    request.fields['timestamp'] = DateTime.now().toIso8601String();

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('Server response status: ${response.statusCode}');
    print('Server response body: ${response.body}');

    return response;
  }

  // 텍스트 레시피를 서버에 제출
  Future<http.Response> _submitTextRecipe(List<Map<String, dynamic>> steps) async {
    const String url = 'http://ec2-47-130-90-43.ap-southeast-1.compute.amazonaws.com:8080/MadeKimchi/';
    final data = {
      'recipe_type': 'text',
      'title': _titleController.text,
      'steps': steps,
      'timestamp': DateTime.now().toIso8601String(),
    };

    print('Sending text recipe to server: $data');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    print('Server response status: ${response.statusCode}');
    print('Server response body: ${response.body}');

    return response;
  }

  @override
  Widget build(BuildContext context) {
    print('Building UserRecipePage...');
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const double baseWidth = 1080;
    const double baseHeight = 2400;
    final widthRatio = screenWidth / baseWidth;
    final heightRatio = screenHeight / baseHeight;

    final containerWidth = screenWidth * 0.6;
    final previewWidth = containerWidth * 0.4;
    final previewHeight = (400 * heightRatio) * 0.4;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF5E9D6),
      body: SafeArea(
        child: Column(
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
                                  height: widget.inputMode == 'photo' ? 400 * heightRatio : 600 * heightRatio,
                                  decoration: BoxDecoration(
                                    color: widget.inputMode == 'photo' ? Colors.white : const Color(0xFFE5D9C6),
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
                                            if (_selectedImages.isNotEmpty) ...[
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
                                                    child: Stack(
                                                      children: [
                                                        ClipRRect(
                                                          borderRadius: BorderRadius.circular(5),
                                                          child: Image.file(
                                                            File(image.path),
                                                            width: previewWidth,
                                                            height: previewHeight,
                                                            fit: BoxFit.cover,
                                                            errorBuilder: (context, error, stackTrace) {
                                                              print('Error loading selected image ${image.path}: $error');
                                                              return const Icon(Icons.error);
                                                            },
                                                          ),
                                                        ),
                                                        Positioned(
                                                          top: 5,
                                                          right: 5,
                                                          child: GestureDetector(
                                                            onTap: () => _removeImage(index),
                                                            child: Container(
                                                              padding: EdgeInsets.all(5 * widthRatio),
                                                              decoration: const BoxDecoration(
                                                                color: Colors.red,
                                                                shape: BoxShape.circle,
                                                              ),
                                                              child: Icon(
                                                                Icons.close,
                                                                size: 30 * widthRatio,
                                                                color: Colors.white,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }).toList().reversed.toList(),
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
                                                    borderRadius: BorderRadius.circular(10),
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
                                                    enableInteractiveSelection: true, // 선택 및 붙여넣기 활성화
                                                    contextMenuBuilder: (context, editableTextState) {
                                                      return AdaptiveTextSelectionToolbar.editableText(
                                                        editableTextState: editableTextState,
                                                      );
                                                    },
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
                              if (errorMessage != null)
                                Center(
                                  child: Text(
                                    errorMessage!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              Center(
                                child: SizedBox(
                                  width: 300 * widthRatio,
                                  child: ElevatedButton(
                                    onPressed: (widget.inputMode == 'photo' && _selectedImages.isNotEmpty) ||
                                            (widget.inputMode == 'text' &&
                                                _titleController.text.isNotEmpty &&
                                                _contentController.text.isNotEmpty)
                                        ? (isSubmitting ? null : _onComplete)
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
                                    child: isSubmitting
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : Text(
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
    );
  }
}

// 텍스트 레시피 처리 페이지: 서버에 레시피 제출 및 처리 상태 표시
class TextProcessingPage extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> steps;
  final List<Map<String, dynamic>> recipeData;
  final VoidCallback? onReturn;

  const TextProcessingPage({
    super.key,
    required this.title,
    required this.steps,
    required this.recipeData,
    this.onReturn,
  });

  @override
  _TextProcessingPageState createState() => _TextProcessingPageState();
}

class _TextProcessingPageState extends State<TextProcessingPage> {
  bool _isProcessing = true; // 서버 요청 처리 중 여부
  String? _errorMessage; // 에러 메시지

  @override
  void initState() {
    super.initState();
    print('TextProcessingPage initState called');
    // 텍스트 레시피 제출 시작
    _submitTextRecipe();
  }

  // 텍스트 레시피를 서버에 제출하고 응답 처리
  Future<void> _submitTextRecipe() async {
    try {
      final response = await _sendRequestToServer();
      print('Server response received: status=${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        print('Server response body parsed: $responseData');

        if (responseData.containsKey('success') && responseData['success'] == '이미지 저장 완료') {
          print('Server confirmed success: ${responseData['success']}');
          if (mounted) {
            // 서버 응답에서 result_data 추출
            List<dynamic> resultData = responseData['body']['result_data'] ?? [];
            if (resultData.isEmpty) {
              throw Exception('서버 응답에서 result_data가 비어 있습니다.');
            }

            // 성공 시 LoadingPage로 이동, resultData 전달
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoadingPage(
                  inputMode: 'text',
                  recipeData: widget.recipeData,
                  selectedImages: [],
                  serverResponseData: resultData,
                  onReturn: widget.onReturn,
                ),
              ),
            );
          }
        } else {
          throw Exception('서버 응답에서 success 필드가 예상과 다릅니다: ${responseData['success']}');
        }
      } else {
        throw Exception('서버 응답 실패: 상태 코드 ${response.statusCode}');
      }
    } catch (e) {
      print('Error during text recipe submission: $e');
      setState(() {
        _isProcessing = false;
        // 사용자 친화적인 에러 메시지 설정
        if (e.toString().contains('ClientException') && e.toString().contains('Connection closed')) {
          _errorMessage = '서버에 연결할 수 없습니다. 네트워크를 확인하거나 나중에 다시 시도해주세요.';
        } else if (e.toString().contains('TimeoutException')) {
          _errorMessage = '서버 응답 시간이 초과되었습니다. 나중에 다시 시도해주세요.';
        } else {
          _errorMessage = '서버 통신 중 오류 발생: $e';
        }
      });
    }
  }

  // 서버에 텍스트 레시피 요청 전송
  Future<http.Response> _sendRequestToServer() async {
    const String url = 'http://ec2-47-130-90-43.ap-southeast-1.compute.amazonaws.com:8080/MadeKimchi/';
    final data = {
      'recipe_type': 'text',
      'title': widget.title,
      'steps': widget.steps,
      'timestamp': DateTime.now().toIso8601String(),
    };

    print('Preparing to send request to $url with data: $data');

    // HTTP 클라이언트 생성 및 타임아웃 설정
    final client = http.Client();
    try {
      final response = await client
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(
            const Duration(seconds: 3000), // 3000초 타임아웃
            onTimeout: () {
              throw TimeoutException('서버 응답 시간이 초과되었습니다.');
            },
          );

      return response;
    } finally {
      client.close(); // 클라이언트 리소스 정리
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building TextProcessingPage...');
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
            Expanded(
              child: Container(
                color: const Color(0xFFF5E9D6),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '이미지를 생성하고 있습니다. 잠시만 기다려주세요!',
                        style: TextStyle(
                          fontSize: 36 * widthRatio,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 20 * heightRatio),
                      if (_isProcessing) const CircularProgressIndicator(),
                      if (_errorMessage != null) ...[
                        SizedBox(height: 20 * heightRatio),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 24 * widthRatio,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      SizedBox(height: 20 * heightRatio),
                      SizedBox(
                        width: 300 * widthRatio,
                        child: OutlinedButton(
                          onPressed: () {
                            print('Returning from TextProcessingPage');
                            widget.onReturn?.call();
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.green),
                            padding: EdgeInsets.symmetric(vertical: 20 * heightRatio),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            '돌아가기',
                            style: TextStyle(
                              fontSize: 36 * widthRatio,
                              color: Colors.green,
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
    );
  }
}

class LoadingPage extends StatefulWidget {
  final String inputMode;
  final List<Map<String, dynamic>> recipeData;
  final List<XFile> selectedImages;
  final List<dynamic>? serverResponseData; // 서버 응답 데이터 추가
  final VoidCallback? onReturn;

  const LoadingPage({
    super.key,
    required this.inputMode,
    required this.recipeData,
    required this.selectedImages,
    this.serverResponseData,
    this.onReturn,
  });

  @override
  _LoadingPageState createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> with TickerProviderStateMixin {
  late AnimationController _controller; // 로딩 애니메이션 컨트롤러
  bool _isLoadingImages = true; // 이미지 로딩 진행 중 여부
  String? _errorMessage; // 에러 메시지
  Timer? _retryTimer; // 이미지 요청 재시도 타이머
  bool _isMounted = true; // 비동기 작업 중 상태 추적

  @override
  void initState() {
    super.initState();
    print('LoadingPage initState called');
    // 로딩 애니메이션 초기화
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // 빌드 완료 후 _fetchImages 호출
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchImages();
    });
  }

  // 서버 응답 데이터를 사용하여 최종 이미지 URL을 생성하는 메서드
  Future<void> _fetchImages() async {
    try {
      if (widget.inputMode == 'text') {
        // TextProcessingPage에서 전달받은 서버 응답 데이터 사용
        final List<dynamic> stepsWithImagePaths = widget.serverResponseData ?? [];
        if (stepsWithImagePaths.isEmpty) {
          throw Exception('서버 응답 데이터가 비어 있습니다.');
        }
        print('Steps with image paths received: $stepsWithImagePaths');

        List<Map<String, dynamic>> updatedRecipeData = [];
        const String baseImageUrl = 'http://ec2-47-130-90-43.ap-southeast-1.compute.amazonaws.com:8080/findImage/';
        print('Base Image API URL set in _fetchImages: $baseImageUrl'); // 기본 이미지 API 주소 로그

        // 각 레시피 단계에 대해 서버에서 받은 imagepath를 사용하여 최종 이미지 URL을 생성
        for (var recipeStep in widget.recipeData) {
          var matchingStep = stepsWithImagePaths.firstWhere(
            (step) => step['recipe_order'] == recipeStep['recipe_order'],
            orElse: () => null,
          );

          if (matchingStep != null && matchingStep['recipe_image_path'] != null) {
            // imagepath를 기본 URL에 붙여 최종 이미지 URL 생성
            String imagePath = matchingStep['recipe_image_path'];
            String fullImageUrl = baseImageUrl + imagePath.replaceFirst(RegExp(r'^/'), '');

            updatedRecipeData.add({
              'kimchi_num': matchingStep['kimchi_num'] ?? recipeStep['kimchi_num'],
              'name': matchingStep['kimchi_name'] ?? recipeStep['name'],
              'recipe_order': recipeStep['recipe_order'],
              'recipe_detail': recipeStep['recipe_detail'],
              'recipe_image_serial_num': fullImageUrl,
            });
            print('Step ${recipeStep['recipe_order']} image URL assigned: $fullImageUrl');
          } else {
            // imagepath가 없는 경우 기본 이미지 사용
            updatedRecipeData.add({
              'kimchi_num': recipeStep['kimchi_num'],
              'name': recipeStep['name'],
              'recipe_order': recipeStep['recipe_order'],
              'recipe_detail': recipeStep['recipe_detail'],
              'recipe_image_serial_num': 'assets/images/photo.png',
            });
            print('Step ${recipeStep['recipe_order']} assigned default image: assets/images/photo.png');
          }
        }

        // 모든 단계에 이미지가 할당되었는지 확인
        bool allImagesAssigned = updatedRecipeData.every((step) => step['recipe_image_serial_num'] != '');

        if (allImagesAssigned) {
          if (_isMounted) {
            setState(() {
              _isLoadingImages = false;
            });
            print('All images assigned. Moving to LoadingCompletePage with updated recipe data: $updatedRecipeData');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => LoadingCompletePage(recipeData: updatedRecipeData),
              ),
            );
          }
        } else {
          throw Exception('일부 단계에 이미지가 할당되지 않았습니다.');
        }
      } else {
        // 사진 모드 처리 (현재 구현 유지)
        final response = await _requestImagePathsFromServer();
        print('Server response received: status=${response.statusCode}');

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          print('Server response parsed: $responseData');

          if (responseData.containsKey('success') && responseData['success']) {
            final List<dynamic> stepsWithImagePaths = responseData['body']['result_data'] ?? [];
            print('Steps with image paths received: $stepsWithImagePaths');

            List<Map<String, dynamic>> updatedRecipeData = [];
            const String baseImageUrl = 'http://ec2-47-130-90-43.ap-southeast-1.compute.amazonaws.com:8080/findImage/';
            print('Base Image API URL set in _fetchImages: $baseImageUrl');

            for (var recipeStep in widget.recipeData) {
              var matchingStep = stepsWithImagePaths.firstWhere(
                (step) => step['recipe_order'] == recipeStep['recipe_order'],
                orElse: () => null,
              );

              if (matchingStep != null && matchingStep['recipe_image_path'] != null) {
                String imagePath = matchingStep['recipe_image_path'];
                String fullImageUrl = baseImageUrl + imagePath.replaceFirst(RegExp(r'^/'), '');

                updatedRecipeData.add({
                  'kimchi_num': matchingStep['kimchi_num'] ?? recipeStep['kimchi_num'],
                  'name': matchingStep['kimchi_name'] ?? recipeStep['name'],
                  'recipe_order': recipeStep['recipe_order'],
                  'recipe_detail': recipeStep['recipe_detail'],
                  'recipe_image_serial_num': fullImageUrl,
                });
                print('Step ${recipeStep['recipe_order']} image URL assigned: $fullImageUrl');
              } else {
                updatedRecipeData.add({
                  'kimchi_num': recipeStep['kimchi_num'],
                  'name': recipeStep['name'],
                  'recipe_order': recipeStep['recipe_order'],
                  'recipe_detail': recipeStep['recipe_detail'],
                  'recipe_image_serial_num': 'assets/images/photo.png',
                });
                print('Step ${recipeStep['recipe_order']} assigned default image: assets/images/photo.png');
              }
            }

            bool allImagesAssigned = updatedRecipeData.every((step) => step['recipe_image_serial_num'] != '');

            if (allImagesAssigned) {
              if (_isMounted) {
                setState(() {
                  _isLoadingImages = false;
                });
                print('All images assigned. Moving to LoadingCompletePage with updated recipe data: $updatedRecipeData');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoadingCompletePage(recipeData: updatedRecipeData),
                  ),
                );
              }
            } else {
              throw Exception('일부 단계에 이미지가 할당되지 않았습니다.');
            }
          } else {
            throw Exception('서버 응답에서 success 필드가 예상과 다릅니다: ${responseData['success']}');
          }
        } else {
          throw Exception('이미지 경로 요청 실패: 상태 코드 ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error fetching image paths: $e');
      if (_isMounted) {
        setState(() {
          _isLoadingImages = false;
          _errorMessage = '이미지 로드 중 오류가 발생했습니다: $e';
        });
      }
    }
  }

  // "건너뛰기" 버튼 클릭 시 동작
  void _skipLoading() {
    _retryTimer?.cancel();
    setState(() {
      _isLoadingImages = false;
    });

    // 모든 레시피 단계에 기본 이미지를 설정
    List<Map<String, dynamic>> updatedRecipeData = widget.recipeData.map((step) {
      return {
        'kimchi_num': step['kimchi_num'],
        'name': step['name'],
        'recipe_order': step['recipe_order'],
        'recipe_detail': step['recipe_detail'],
        'recipe_image_serial_num': 'assets/images/photo.png',
      };
    }).toList();

    if (mounted) {
      print('Skipping image loading, moving to LoadingCompletePage with default images: $updatedRecipeData');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoadingCompletePage(recipeData: updatedRecipeData),
        ),
      );
    }
  }

  // 사진 모드에서만 호출되는 메서드 (현재는 사용되지 않으므로 최소 구현)
  Future<http.Response> _requestImagePathsFromServer() async {
    const String url = 'http://ec2-47-130-90-43.ap-southeast-1.compute.amazonaws.com:8080/MadeKimchi/images';
    print('Image API URL for requesting paths in _requestImagePathsFromServer: $url');

    var request = http.MultipartRequest('POST', Uri.parse(url));
    for (int i = 0; i < widget.selectedImages.length; i++) {
      final image = widget.selectedImages[i];
      final file = await http.MultipartFile.fromPath(
        'images[$i]',
        image.path,
        filename: image.name,
      );
      request.files.add(file);
      print('Adding image to request: ${image.name}, path: ${image.path}');
    }
    request.fields['recipe_type'] = 'photo';
    request.fields['timestamp'] = DateTime.now().toIso8601String();
    print('Photo mode request fields: ${request.fields}');

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    print('Photo mode response status: ${response.statusCode}');
    print('Photo mode response body: ${response.body}');
    return response;
  }

  @override
  void dispose() {
    print('LoadingPage dispose called');
    _isMounted = false;
    _controller.dispose();
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('Building LoadingPage...');
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
            Expanded(
              child: Container(
                color: const Color(0xFFF5E9D6),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '레시피 생성 중입니다',
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
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading gear.png: $error');
                            return const Icon(Icons.error);
                          },
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        SizedBox(height: 20 * heightRatio),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 24 * widthRatio,
                            color: Colors.red,
                          ),
                        ),
                      ],
                      SizedBox(height: 20 * heightRatio),
                      SizedBox(
                        width: 300 * widthRatio,
                        child: OutlinedButton(
                          onPressed: () {
                            widget.onReturn?.call();
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.green),
                            padding: EdgeInsets.symmetric(vertical: 20 * heightRatio),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            '돌아가기',
                            style: TextStyle(
                              fontSize: 36 * widthRatio,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10 * heightRatio),
                      SizedBox(
                        width: 300 * widthRatio,
                        child: OutlinedButton(
                          onPressed: _skipLoading,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.green),
                            padding: EdgeInsets.symmetric(vertical: 20 * heightRatio),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            '건너뛰기',
                            style: TextStyle(
                              fontSize: 36 * widthRatio,
                              color: Colors.green,
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
    );
  }
}

class LoadingCompletePage extends StatelessWidget {
  final List<Map<String, dynamic>> recipeData;

  const LoadingCompletePage({super.key, required this.recipeData});

  @override
  Widget build(BuildContext context) {
    print('Building LoadingCompletePage...');
    // recipeData의 이미지 URL 로그 출력
    for (var step in recipeData) {
      print('LoadingCompletePage - Step ${step['recipe_order']}: image URL=${step['recipe_image_serial_num']}');
    }

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
            Expanded(
              child: Container(
                color: const Color(0xFFF5E9D6),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '레시피 생성 완료',
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
                            print('Navigating to RecipePageDetail from LoadingCompletePage...');
                            // recipeData를 그대로 전달하며, 이미지 URL 로그 출력
                            for (var step in recipeData) {
                              print('Navigating to RecipePageDetail - Step ${step['recipe_order']}: image URL=${step['recipe_image_serial_num']}');
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecipePageDetail(
                                  kimchiData: recipeData,
                                  recipeId: 'user_recipe_${recipeData[0]['kimchi_num']}',
                                ),
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
                      SizedBox(height: 20 * heightRatio),
                      SizedBox(
                        width: 300 * widthRatio,
                        child: OutlinedButton(
                          onPressed: () {
                            print('Navigating to MainPage from LoadingCompletePage...');
                            // 모든 이전 스택 제거하고 MainPage로 이동
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const MainPage()),
                              (Route<dynamic> route) => false, // 모든 경로 제거
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.green),
                            padding: EdgeInsets.symmetric(vertical: 20 * heightRatio),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            '메인페이지로 돌아가기',
                            style: TextStyle(
                              fontSize: 36 * widthRatio,
                              color: Colors.green,
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
    );
  }
}