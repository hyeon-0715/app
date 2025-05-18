import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main_page.dart';
import 'recipe_page.dart';

// 앱 설명을 표시하는 페이지
class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 디바이스 방향을 세로로 고정
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

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
            // 중단 섹션: 배경 이미지와 "About App" 텍스트 표시 영역
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
                      'About App',
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
            // 하단 섹션: 앱 설명 텍스트 표시
            Expanded(
              child: Container(
                color: const Color(0xFFF5E9D6),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 60 * widthRatio,
                      vertical: 60 * heightRatio,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 앱 설명 텍스트
                        Text(
                          'Kimchi App에 오신 것을 환영합니다!\n\n'
                          '이 앱은 다양한 김치 레시피를 탐색하고, 직접 레시피를 만들어 볼 수 있는 공간입니다.\n\n'
                          '- **레시피 탐색**: 다양한 김치 레시피를 확인하고 단계별로 따라할 수 있습니다.\n'
                          '- **레시피 등록**: 사진 또는 텍스트로 나만의 레시피를 등록하고 만들어보실 수 있습니다..\n',
                          style: TextStyle(
                            fontSize: 40 * widthRatio,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 40 * heightRatio),
                        // 메인페이지로 돌아가기 버튼
                        Center(
                          child: SizedBox(
                            width: 300 * widthRatio,
                            child: ElevatedButton(
                              onPressed: () {
                                print('Navigating to MainPage from UserPage...');
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => const MainPage()),
                                  (Route<dynamic> route) => route.isFirst,
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
                                '메인페이지로 돌아가기',
                                style: TextStyle(
                                  fontSize: 36 * widthRatio,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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
}