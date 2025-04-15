/*
import 'package:flutter/material.dart';
import 'main.dart'; // AppBarWidget을 가져오기 위해

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 상단바
              const AppBarWidget(),
              // 중단
              Container(
                width: screenWidth,
                height: 250,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('images/kimchiback.png'), // 추가: 배경 이미지
                    fit: BoxFit.cover, // 전체를 채우도록 설정
                    opacity: 0.5, // 이미지 투명도 조정                    
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
                child: const Center(
                  child: Text(
                    '소개',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      shadows: [
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
              // 하단
              Container(
                width: screenWidth,
                color: const Color(0xFFF5E9D6),
                padding: const EdgeInsets.symmetric(horizontal: 200, vertical: 50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // About us
                    const Text(
                      'About us',
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        shadows: [
                          Shadow(
                            color: Colors.white,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '안녕하세요! 김치다 팀입니다.\n\n'
                            '저희는 김치에 대한 모든 것을 사랑하는 팀으로, 김치의 역사와 문화를 알리고자 합니다.\n'
                            '김치는 단순한 음식이 아니라 한국의 전통과 정서가 담긴 소중한 유산입니다.\n'
                            '저희 팀은 김치의 다양한 레시피를 공유하고, 김치 담그는 과정을 쉽게 배울 수 있도록 돕고자 합니다.\n'
                            '또한, 김치에 대한 궁금증을 해결해 줄 챗봇 "배추다"를 통해 여러분과 소통하고자 합니다.\n'
                            '김치다와 함께 김치의 매력을 더 깊이 알아가 보세요!',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.black,
                              shadows: [
                                Shadow(
                                  color: Colors.white,
                                  offset: Offset(2, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            maxLines: 10,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 50),
                        Image.asset(
                          'images/kimchiicon.png',
                          width: 300,
                          height: 300,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                    const SizedBox(height: 300),
                    // "개선할 점이 있으면 알려주세요" (중앙 배치)
                    const Center(
                      child: Text(
                        '개선할 점이 있으면 알려주세요',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 80),
                    // Contact us (입력 칸 배경색 하얀색으로 변경)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Contact us',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // 성과 이름
                            Row(
                              children: [
                                SizedBox(
                                  width: 200,
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: '성',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true, // 수정: 배경색 채우기 활성화
                                      fillColor: Colors.white, // 수정: 하얀색 배경
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                SizedBox(
                                  width: 200,
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: '이름',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true, // 수정: 배경색 채우기 활성화
                                      fillColor: Colors.white, // 수정: 하얀색 배경
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // 이메일
                            SizedBox(
                              width: 420,
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: '이메일',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true, // 수정: 배경색 채우기 활성화
                                  fillColor: Colors.white, // 수정: 하얀색 배경
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // 의견
                            SizedBox(
                              width: 420,
                              child: TextField(
                                maxLines: 5,
                                decoration: InputDecoration(
                                  labelText: '의견',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true, // 수정: 배경색 채우기 활성화
                                  fillColor: Colors.white, // 수정: 하얀색 배경
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        // 제출 버튼
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          ),
                          child: const Text(
                            '제출',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 300),
                    // Member
                    const Text(
                      'Member',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              '전진만',
                              style: TextStyle(fontSize: 16, color: Colors.black),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'email: email@gmail.com\n'
                              'tel: 010-0000-0000\n',
                              style: TextStyle(fontSize: 16, color: Colors.black),
                            ),
                          ],
                        ),
                        const SizedBox(width: 50),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              '김종현',
                              style: TextStyle(fontSize: 16, color: Colors.black),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'email: email@gmail.com\n'
                              'tel: 010-0000-0000\n',
                              style: TextStyle(fontSize: 16, color: Colors.black),
                            ),
                          ],
                        ),
                        const SizedBox(width: 50),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              '이재현',
                              style: TextStyle(fontSize: 16, color: Colors.black),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'email: han697333@gmail.com\n'
                              'tel: 010-0000-0000\n',
                              style: TextStyle(fontSize: 16, color: Colors.black),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/