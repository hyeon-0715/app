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
class UserRecipePage extends StatefulWidget {
  // 입력 모드 ('photo' 또는 'text')를 지정하여 사진 또는 텍스트로 레시피를 등록할지 결정
  final String inputMode;

  const UserRecipePage({super.key, required this.inputMode});

  @override
  _UserRecipePageState createState() => _UserRecipePageState();
}

class _UserRecipePageState extends State<UserRecipePage> {
  // 사용자가 선택한 이미지 파일 리스트 (사진 모드에서 사용)
  List<XFile> _selectedImages = [];
  // 선택한 이미지의 세부 정보 (이름과 경로)를 저장하는 리스트
  List<Map<String, String>> _imageDetails = [];
  // 최대 허용 이미지 개수 상수
  static const int _maxImageCount = 10;
  // 텍스트 모드에서 제목 입력을 위한 컨트롤러
  final TextEditingController _titleController = TextEditingController();
  // 텍스트 모드에서 레시피 내용을 입력하기 위한 컨트롤러
  final TextEditingController _contentController = TextEditingController();
  // 제목 입력 필드의 포커스 상태를 관리하는 노드
  final FocusNode _titleFocusNode = FocusNode();
  // 내용 입력 필드의 포커스 상태를 관리하는 노드
  final FocusNode _contentFocusNode = FocusNode();
  // 제목 입력 필드의 힌트 텍스트 표시 여부를 관리
  bool _showTitleHint = true;
  // 내용 입력 필드의 힌트 텍스트 표시 여부를 관리
  bool _showContentHint = true;
  // 레시피 제출 중인지 상태를 관리 (중복 제출 방지)
  bool isSubmitting = false;
  // 제출 중 발생한 에러 메시지를 저장
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    // 디버깅 로그: 페이지 초기화 확인
    print('UserRecipePage initState called, inputMode: ${widget.inputMode}');
    // 텍스트 입력 모드일 경우 초기 설정
    if (widget.inputMode == 'text') {
      _titleController.text = '';
      _contentController.text = '';
      // 제목 입력 필드 포커스 변경 시 힌트 표시 상태 업데이트
      _titleFocusNode.addListener(() {
        setState(() {
          if (!_titleFocusNode.hasFocus && _titleController.text.isEmpty) {
            _showTitleHint = true;
          }
        });
      });
      // 내용 입력 필드 포커스 변경 시 힌트 표시 상태 업데이트
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
    // 페이지가 다시 활성화될 때 isSubmitting 초기화
    if (isSubmitting) {
      setState(() {
        isSubmitting = false;
        errorMessage = null;
      });
    }
  }

  @override
  void dispose() {
    // 디버깅 로그: 페이지 소멸 확인
    print('UserRecipePage dispose called');
    // 리소스 해제: 텍스트 컨트롤러와 포커스 노드 정리
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

    // 디버깅 로그: 다이얼로그 표시 확인
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
              // 갤러리에서 이미지 선택 버튼
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
              // 카메라로 사진 촬영 버튼
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
              // 다이얼로그 취소 버튼
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

  // 이미지 선택을 위한 권한 확인 및 다이얼로그 표시
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

  // 갤러리에서 여러 이미지를 선택하는 메서드
  void _pickMultipleImages() async {
    try {
      print('Picking multiple images...');
      final List<XFile> images = await ImagePicker().pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          int remainingSlots = _maxImageCount - _selectedImages.length;
          if (images.length > remainingSlots) {
            // 최대 이미지 개수 초과 시 경고 메시지 표시
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
      // 이미지 선택 중 오류 발생 시 처리
      print('Error picking multiple images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 선택 중 오류 발생: $e')),
        );
      }
    }
  }

  // 카메라로 사진을 촬영하여 이미지를 선택하는 메서드
  void _pickImageFromCamera() async {
    try {
      print('Picking image from camera...');
      final XFile? image = await ImagePicker().pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          if (_selectedImages.length >= _maxImageCount) {
            // 최대 이미지 개수 초과 시 경고 메시지 표시
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
      // 카메라 촬영 중 오류 발생 시 처리
      print('Error picking image from camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('카메라 촬영 중 오류 발생: $e')),
        );
      }
    }
  }

  // 선택한 이미지를 제거하는 메서드
  void _removeImage(int index) {
    print('Removing image at index: $index');
    setState(() {
      _imageDetails.removeAt(index);
      _selectedImages.removeAt(index);
      print('이미지 삭제 후 남은 이미지 정보: $_imageDetails');
    });
  }

  // 레시피 제출 처리 메서드
  void _onComplete() async {
    // 사진 모드에서 이미지 제출 처리
    if (widget.inputMode == 'photo' && _selectedImages.isNotEmpty) {
      print('Submitting photo recipe...');
      setState(() {
        isSubmitting = true;
        errorMessage = null;
      });

      try {
        // 로딩 페이지로 이동 (이미지 데이터를 전달)
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
                  // "돌아가기" 버튼을 눌렀을 때 호출
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
        // 제출 중 오류 발생 시 처리
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
    } 
    // 텍스트 모드에서 레시피 제출 처리
    else if (widget.inputMode == 'text' &&
        _titleController.text.isNotEmpty &&
        _contentController.text.isNotEmpty) {
      print('Submitting text recipe...');
      setState(() {
        isSubmitting = true;
        errorMessage = null;
      });

      try {
        // 사용자 입력 데이터를 기반으로 recipeData 생성 (김치 목록 형식)
        final stepsContent = _contentController.text.split('\n');
        List<Map<String, dynamic>> recipeData = [];
        List<Map<String, dynamic>> steps = [];
        int kimchiNum = DateTime.now().millisecondsSinceEpoch; // 고유 번호 생성

        for (int i = 0; i < stepsContent.length; i++) {
          String stepDetail = stepsContent[i].trim();
          if (stepDetail.isNotEmpty) {
            // recipeData에서는 "숫자." 제거
            String cleanedStepDetail = stepDetail.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
            recipeData.add({
              'kimchi_num': kimchiNum,
              'name': _titleController.text,
              'recipe_order': i + 1,
              'recipe_detail': cleanedStepDetail,
              'recipe_image_serial_num': '', // 이미지는 서버에서 할당
            });

            // 서버 전송용 steps에서는 원본 데이터 유지
            steps.add({
              'recipe_order': i + 1,
              'recipe_detail': stepDetail,
            });
          }
        }

        print('Processed recipeData (for display): $recipeData');
        print('Processed steps (for server): $steps');

        // 서버로 텍스트 데이터 전송
        final response = await _submitTextRecipe(steps);

        if (response.statusCode == 200) {
          // 서버 응답 파싱
          final Map<String, dynamic> responseData = jsonDecode(response.body);

          // 서버 응답에서 'success' 필드 확인
          if (responseData.containsKey('success')) {
            print('서버 응답에서 성공적으로 저장됨: ${responseData['success']}');
          } else {
            throw Exception('서버 응답에서 success 필드가 누락되었습니다.');
          }

          if (mounted) {
            // 로딩 페이지로 이동 (recipeData 전달)
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoadingPage(
                  inputMode: 'text',
                  recipeData: recipeData,
                  selectedImages: [],
                  onReturn: () {
                    // "돌아가기" 버튼을 눌렀을 때 호출
                    setState(() {
                      isSubmitting = false;
                      errorMessage = null;
                    });
                  },
                ),
              ),
            );
          }
        } else {
          throw Exception('서버 응답 실패: ${response.statusCode}');
        }
      } catch (e) {
        // 제출 중 오류 발생 시 처리
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

  // 사진 모드에서 서버로 이미지 데이터를 전송하는 메서드
  Future<http.Response> _submitPhotoRecipe() async {
    // 서버 엔드포인트 URL (가정)
    const String url = 'http://ec2-47-130-90-43.ap-southeast-1.compute.amazonaws.com:8080/userRecipe/photo';

    // MultipartRequest 생성
    var request = http.MultipartRequest('POST', Uri.parse(url));

    // 이미지 파일 추가
    for (int i = 0; i < _selectedImages.length; i++) {
      final image = _selectedImages[i];
      final file = await http.MultipartFile.fromPath(
        'images[$i]', // 서버에서 기대하는 필드 이름 (예: images[0], images[1], ...)
        image.path,
        filename: image.name,
      );
      request.files.add(file);
    }

    // 추가 메타데이터 (필요 시)
    request.fields['recipe_type'] = 'photo';
    request.fields['timestamp'] = DateTime.now().toIso8601String();

    // 요청 전송
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('Server response status: ${response.statusCode}');
    print('Server response body: ${response.body}');

    return response;
  }

  // 텍스트 모드에서 서버로 텍스트 데이터를 전송하는 메서드
  Future<http.Response> _submitTextRecipe(List<Map<String, dynamic>> steps) async {
    // 서버 엔드포인트 URL (지정된 URL)
    const String url = 'http://ec2-47-130-90-43.ap-southeast-1.compute.amazonaws.com:8080/MadeKimchi/';

    // JSON 데이터 생성
    final data = {
      'recipe_type': 'text',
      'title': _titleController.text,
      'steps': steps,
      'timestamp': "2025-05-18T01:21:00.000+09:00", // 고정된 timestamp 값
    };

    print('Sending text recipe to server: $data');

    // POST 요청 전송
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

    // 전체 UI를 구성하는 스캐폴드
    return Scaffold(
      resizeToAvoidBottomInset: true, // 키보드 표시 시 화면 크기 조정
      backgroundColor: const Color(0xFFF5E9D6),
      body: SafeArea(
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
            // 중단 섹션: 배경 이미지와 "User recipe" 텍스트 표시 영역
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
            // 하단 섹션: 레시피 입력 및 제출 UI가 포함된 스크롤 가능한 영역
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: screenWidth,
                  color: const Color(0xFFF5E9D6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 입력 모드 표시 ("사진" 또는 "텍스트")
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
                              // 입력 안내 메시지
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
                                            // 이미지가 선택되지 않았을 때 표시되는 추가 버튼
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
                                            // 선택된 이미지 미리보기
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
                                                        // 이미지 제거 버튼
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
                                              // 추가 이미지 선택 버튼
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
                                              // 선택된 이미지 개수 표시
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
                                          ],
                                        )
                                      : Padding(
                                          padding: EdgeInsets.all(20 * widthRatio),
                                          child: Column(
                                            children: [
                                              // 제목 입력 필드
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
                                              // 내용 입력 필드 (멀티라인)
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
                              // 에러 메시지 표시
                              if (errorMessage != null)
                                Center(
                                  child: Text(
                                    errorMessage!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              // 제출 버튼
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

// 레시피 제출 중 표시되는 로딩 페이지
class LoadingPage extends StatefulWidget {
  final String inputMode;
  final List<Map<String, dynamic>> recipeData;
  final List<XFile> selectedImages;
  final VoidCallback? onReturn; // "돌아가기" 버튼 콜백

  const LoadingPage({
    super.key,
    required this.inputMode,
    required this.recipeData,
    required this.selectedImages,
    this.onReturn,
  });

  @override
  _LoadingPageState createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> with TickerProviderStateMixin {
  late AnimationController _controller;
  bool _isLoadingImages = true;
  String? _errorMessage;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    // 디버깅 로그: 페이지 초기화 확인
    print('LoadingPage initState called');
    // 로딩 애니메이션 컨트롤러 초기화 (2초 주기로 회전)
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // 주기적으로 이미지 요청 시작
    _startImageFetchRetry();
  }

  // 주기적으로 이미지 요청을 시도하는 메서드
  void _startImageFetchRetry() {
    _retryTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!_isLoadingImages) {
        timer.cancel();
        return;
      }

      try {
        final response = await _requestImagesFromServer();

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);

          if (responseData.containsKey('success')) {
            final List<dynamic> stepsWithImages = responseData['steps'];
            List<Map<String, dynamic>> updatedRecipeData = [];

            // recipeData와 서버 응답 데이터를 매핑
            for (var recipeStep in widget.recipeData) {
              var matchingStep = stepsWithImages.firstWhere(
                (step) => step['recipe_order'] == recipeStep['recipe_order'],
                orElse: () => null,
              );

              if (matchingStep != null) {
                updatedRecipeData.add({
                  'kimchi_num': recipeStep['kimchi_num'],
                  'name': recipeStep['name'],
                  'recipe_order': recipeStep['recipe_order'],
                  'recipe_detail': recipeStep['recipe_detail'],
                  'recipe_image_serial_num': matchingStep['recipe_image_serial_num'] ?? 'assets/images/photo.png',
                });
              } else {
                updatedRecipeData.add({
                  'kimchi_num': recipeStep['kimchi_num'],
                  'name': recipeStep['name'],
                  'recipe_order': recipeStep['recipe_order'],
                  'recipe_detail': recipeStep['recipe_detail'],
                  'recipe_image_serial_num': 'assets/images/photo.png',
                });
              }
            }

            // 모든 단계에 이미지가 할당되었는지 확인
            bool allImagesAssigned = updatedRecipeData.every((step) => step['recipe_image_serial_num'] != '');

            if (allImagesAssigned) {
              // 모든 이미지가 할당되었으므로 로딩 완료 페이지로 이동
              setState(() {
                _isLoadingImages = false;
              });
              timer.cancel();
              if (mounted) {
                print('Moving to LoadingCompletePage with server images: $updatedRecipeData');
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
            throw Exception('서버 응답에서 success 필드가 누락되었습니다.');
          }
        } else {
          print('이미지 요청 실패 (재시도 중): ${response.statusCode}');
          setState(() {
            _errorMessage = '이미지를 생성 중입니다. 잠시만 기다려주세요.: ${response.statusCode}';
          });
        }
      } catch (e) {
        print('Error fetching images (재시도 중): $e');
        setState(() {
          _errorMessage = '이미지 로드 중 오류: $e (재시도 중)';
        });
      }
    });
  }

  // "건너뛰기" 버튼 클릭 시 동작
  void _skipLoading() {
    // 타이머 중지
    _retryTimer?.cancel();
    setState(() {
      _isLoadingImages = false;
    });

    // recipeData 복사 후 기본 이미지 설정
    List<Map<String, dynamic>> updatedRecipeData = widget.recipeData.map((step) {
      return {
        'kimchi_num': step['kimchi_num'],
        'name': step['name'],
        'recipe_order': step['recipe_order'],
        'recipe_detail': step['recipe_detail'],
        'recipe_image_serial_num': 'assets/images/photo.png', // 기본 이미지 설정
      };
    }).toList();

    // 로딩 완료 페이지로 이동
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

  // 서버에 이미지 요청을 보내는 메서드 (가정)
  Future<http.Response> _requestImagesFromServer() async {
    const String url = 'http://ec2-47-130-90-43.ap-southeast-1.compute.amazonaws.com:8080/MadeKimchi/images';

    if (widget.inputMode == 'photo') {
      // 사진 모드: Multipart 요청으로 이미지 전송
      var request = http.MultipartRequest('POST', Uri.parse(url));

      // 이미지 파일 추가
      for (int i = 0; i < widget.selectedImages.length; i++) {
        final image = widget.selectedImages[i];
        final file = await http.MultipartFile.fromPath(
          'images[$i]',
          image.path,
          filename: image.name,
        );
        request.files.add(file);
      }

      request.fields['recipe_type'] = 'photo';
      request.fields['timestamp'] = "2025-05-18T01:21:00.000+09:00";

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Image request response status: ${response.statusCode}');
      print('Image request response body: ${response.body}');

      return response;
    } else {
      // 텍스트 모드: JSON 요청으로 steps 전송
      final data = {
        'recipe_type': 'text',
        'steps': widget.recipeData.map((step) => {
          'recipe_order': step['recipe_order'],
          'recipe_detail': step['recipe_detail'],
        }).toList(),
        'timestamp': "2025-05-18T01:21:00.000+09:00",
      };

      print('Requesting images for text recipe: $data');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      print('Image request response status: ${response.statusCode}');
      print('Image request response body: ${response.body}');

      return response;
    }
  }

  @override
  void dispose() {
    // 디버깅 로그: 페이지 소멸 확인
    print('LoadingPage dispose called');
    // 리소스 해제: 애니메이션 컨트롤러 및 타이머 정리
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
            // 중단 섹션: 배경 이미지와 "User recipe" 텍스트 표시 영역
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
            // 하단 섹션: 로딩 애니메이션과 메시지 표시
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
                      // 회전하는 기어 아이콘 애니메이션
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
                      // 돌아가기 버튼
                      SizedBox(
                        width: 300 * widthRatio,
                        child: OutlinedButton(
                          onPressed: () {
                            widget.onReturn?.call(); // 콜백 호출
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
                      // 건너뛰기 버튼
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

// 레시피 제출 완료 후 결과를 표시하는 페이지
class LoadingCompletePage extends StatelessWidget {
  final List<Map<String, dynamic>> recipeData;

  const LoadingCompletePage({super.key, required this.recipeData});

  @override
  Widget build(BuildContext context) {
    print('Building LoadingCompletePage...');
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
            // 중단 섹션: 배경 이미지와 "User recipe" 텍스트 표시 영역
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
            // 하단 섹션: 제출 완료 메시지와 버튼 표시
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
                      // 레시피 확인 버튼
                      SizedBox(
                        width: 300 * widthRatio,
                        child: ElevatedButton(
                          onPressed: () {
                            print('Navigating to RecipePageDetail from LoadingCompletePage...');
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
                      // 메인페이지로 돌아가기 버튼
                      SizedBox(
                        width: 300 * widthRatio,
                        child: OutlinedButton(
                          onPressed: () {
                            print('Navigating to MainPage from LoadingCompletePage...');
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const MainPage()),
                              (Route<dynamic> route) => route.isFirst,
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