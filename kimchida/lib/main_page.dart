import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'recipe_page.dart';
import 'user_page.dart';
import 'login_page.dart';
import 'user_state.dart';
import 'user_recipe_page.dart'; // 새로 추가된 UserRecipePage 임포트

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
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
                        SizedBox(height: 20 * heightRatio),
                        Text(
                          '앱 소개',
                          style: TextStyle(
                            fontSize: 30 * widthRatio,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
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
                            'Menu',
                            style: TextStyle(
                              fontSize: 60 * widthRatio,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 70),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 60 * widthRatio),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '레시피 직접 만들기',
                                      style: TextStyle(
                                        fontSize: 36 * widthRatio,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 30 * heightRatio),
                                    // photo.png 버튼: 이미지 첨부 모드로 UserRecipePage로 이동
                                    IconButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const UserRecipePage(inputMode: 'photo'),
                                          ),
                                        );
                                      },
                                      visualDensity: VisualDensity(
                                        horizontal: -4,
                                        vertical: -4,
                                      ),
                                      icon: Container(
                                        width: 400 * widthRatio,
                                        height: 300 * heightRatio,
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
                                        child: Center(
                                          child: Image.asset(
                                            'assets/images/photo.png',
                                            width: 150 * widthRatio,
                                            height: 150 * heightRatio,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Text(
                                                '이미지를 로드할 수 없습니다.',
                                                style: TextStyle(color: Colors.red),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 30 * heightRatio),
                                    // text.png 버튼: 텍스트 입력 모드로 UserRecipePage로 이동
                                    IconButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const UserRecipePage(inputMode: 'text'),
                                          ),
                                        );
                                      },
                                      visualDensity: VisualDensity(
                                        horizontal: -4,
                                        vertical: -4,
                                      ),
                                      icon: Container(
                                        width: 400 * widthRatio,
                                        height: 300 * heightRatio,
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
                                        child: Center(
                                          child: Image.asset(
                                            'assets/images/text.png',
                                            width: 150 * widthRatio,
                                            height: 150 * heightRatio,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 5 * widthRatio,
                                height: 800 * heightRatio,
                                color: Colors.black,
                                margin: EdgeInsets.symmetric(horizontal: 30 * widthRatio),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '레시피 둘러보기',
                                      style: TextStyle(
                                        fontSize: 36 * widthRatio,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 30 * heightRatio),
                                    IconButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const RecipePage()),
                                        );
                                      },
                                      visualDensity: VisualDensity(
                                        horizontal: -4,
                                        vertical: -4,
                                      ),
                                      icon: Container(
                                        padding: EdgeInsets.all(10 * widthRatio),
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
                                          children: [
                                            Image.asset(
                                              'assets/images/recipe.png',
                                              width: 200 * widthRatio,
                                              height: 400 * heightRatio,
                                              fit: BoxFit.contain,
                                            ),
                                            SizedBox(height: 20 * heightRatio),
                                            Container(
                                              width: 400 * widthRatio,
                                              height: 100 * heightRatio,
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '김치 레시피 보러가기',
                                                  style: TextStyle(
                                                    fontSize: 65 * widthRatio * 0.5,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 70 * heightRatio),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                  onPressed: () {},
                  icon: Image.asset(
                    'assets/images/home.png',
                    width: 60 * widthRatio,
                    height: 60 * heightRatio,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
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
      },
    );
  }
}