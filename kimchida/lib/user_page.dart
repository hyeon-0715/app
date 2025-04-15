import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'main_page.dart';
import 'recipe_page.dart';
import 'login_page.dart';
import 'user_state.dart';
import '../utils/permission_helper.dart'; // PermissionHelper 임포트

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  // 이미지 선택 처리
  void _handleImageSelection() {
    PermissionHelper.showImageSourceDialog(
      context,
      onImageSourceSelected: (source, permissionType) async {
        XFile? image = await PermissionHelper.pickImage(context, source, onImagePicked: (pickedImage) {
          if (pickedImage != null) {
            Provider.of<UserState>(context, listen: false).setProfileImage(pickedImage.path);
          }
        });
        if (image != null && mounted) {
          Provider.of<UserState>(context, listen: false).setProfileImage(image.path);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const double baseWidth = 1080;
    const double baseHeight = 2400;
    final widthRatio = screenWidth / baseWidth;
    final heightRatio = screenHeight / baseHeight;

    return Consumer<UserState>(
      builder: (context, userState, child) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // 상단바 (RecipePage와 동일)
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
                // 중단 섹션 (RecipePage와 동일)
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
                    child: Text(
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
                  ),
                ),
                // 하단 섹션
                Expanded(
                  child: Container(
                    width: screenWidth,
                    color: const Color(0xFFF5E9D6),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 60 * widthRatio),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 60 * heightRatio),
                          // 프로필 사진 버튼과 사용자 정보
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 프로필 사진 버튼 (좌측 맨 끝)
                              GestureDetector(
                                onTap: () {
                                  if (userState.isLoggedIn) {
                                    _handleImageSelection(); // 이미지 선택 처리
                                  }
                                },
                                child: Container(
                                  width: 200 * widthRatio,
                                  height: 200 * widthRatio,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey[300],
                                  ),
                                  child: ClipOval(
                                    child: userState.profileImagePath.startsWith('assets/images/')
                                        ? Image.asset(
                                            userState.profileImagePath,
                                            width: 160 * widthRatio, // 200 * widthRatio * 0.8
                                            height: 160 * widthRatio,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.file(
                                            File(userState.profileImagePath),
                                            width: 160 * widthRatio,
                                            height: 160 * widthRatio,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Image.asset(
                                                'assets/images/user.png',
                                                width: 160 * widthRatio,
                                                height: 160 * widthRatio,
                                                fit: BoxFit.cover,
                                              );
                                            },
                                          ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 20 * widthRatio), // 사진과 텍스트 사이 간격
                              // 사용자 아이디 또는 로그인 필요 텍스트 (사진 중앙 우측)
                              Expanded(
                                child: Text(
                                  userState.isLoggedIn ? userState.userId : '로그인이 필요합니다',
                                  style: TextStyle(
                                    fontSize: 36 * widthRatio * 2, // 72 * widthRatio
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20 * heightRatio),
                          // 구분선 (사용자 아이디 아래)
                          Padding(
                            padding: EdgeInsets.only(
                              left: 200 * widthRatio, // 프로필 사진 버튼의 오른쪽 끝에서 시작
                              right: 10, // 하단 섹션 우측 끝에서 10포인트 띄움
                            ),
                            child: Container(
                              height: 2 * heightRatio,
                              color: Colors.black,
                            ),
                          ),
                          const Spacer(), // 하단으로 버튼 밀기
                          // 로그인/로그아웃 버튼 (하단 섹션 너비의 중앙)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center, // 수평 중앙 정렬
                            children: [
                              SizedBox(
                                width: 300 * widthRatio,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (userState.isLoggedIn) {
                                      userState.logout();
                                    }
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => const LoginPage()),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: userState.isLoggedIn ? Colors.red : Colors.green,
                                    padding: EdgeInsets.symmetric(vertical: 20 * heightRatio),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    userState.isLoggedIn ? '로그아웃' : '로그인',
                                    style: TextStyle(
                                      fontSize: 36 * widthRatio,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 60 * heightRatio), // 하단 여백 유지
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 하단바 (RecipePage와 동일)
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
                  onPressed: () {},
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
      },
    );
  }
}