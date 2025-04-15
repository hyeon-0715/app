/*
import 'package:flutter/material.dart';
import 'main.dart'; // AppBarWidget을 가져오기 위해

class BaechudaPage extends StatelessWidget {
  const BaechudaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
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
                  image: AssetImage('images/kimchiback.png'),
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
              child: const Center(
                child: Text(
                  '배추다',
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
            // 하단 (Contact us 제거, 창 맨 아래까지 확장)
            Expanded(
              child: Container(
                width: screenWidth,
                color: const Color(0xFFF5E9D6),
                // 내용이 없으므로 빈 컨테이너로 유지
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/