import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // 서버의 기본 URL (나중에 API 주소로 대체)
  static const String baseUrl = 'https://api.example.com';

  // GET 요청: 김치 목록 가져오기
  Future<List<Map<String, dynamic>>> fetchKimchiList() async {
    // 실제 API 호출 비활성화, 모의 데이터 반환
    print('Fetching kimchi list (mock data)'); // 디버깅 로그 추가
    return [
      {
        'name': '배추김치',
        'recipe_image_serial_num': 'assets/images/cabbagekimchi.png',
      },
      {
        'name': '오이김치',
        'recipe_image_serial_num': 'assets/images/cucumberkimchi.png',
      },
    ];
  }

  // GET 요청: 김치 레시피 세부 정보 가져오기
  Future<List<Map<String, dynamic>>> fetchKimchiRecipe(String recipeId) async {
    // 실제 API 호출 비활성화, 모의 데이터 반환
    print('Fetching kimchi recipe for recipeId: $recipeId (mock data)'); // 디버깅 로그 추가
    return [
      {
        'name': '배추김치',
        'recipe_detail': '1',
        'recipe_image_serial_num': 'assets/images/cabbagekimchi.png',
      },
      {
        'recipe_detail': '2',
        'recipe_image_serial_num': 'assets/images/cabbagekimchi.png',
      },
    ];
  }

  // POST 요청: 사용자 입력(이미지, 텍스트) 전송 및 레시피 생성
  Future<List<Map<String, dynamic>>> createUserRecipe({
    List<String>? imagePaths,
    String? title,
    String? content,
  }) async {
    // 실제 API 호출 비활성화, 모의 데이터 반환
    print('Creating user recipe (mock data)'); // 디버깅 로그 추가
    print('Image paths: $imagePaths, Title: $title, Content: $content');
    return [
      {
        'name': title ?? '김치',
        'recipe_detail': '1',
        'recipe_image_serial_num': 'assets/images/cabbagekimchi.png',
      },
      {
        'recipe_detail': '2',
        'recipe_image_serial_num': 'assets/images/cabbagekimchi.png',
      },
    ];
  }
}