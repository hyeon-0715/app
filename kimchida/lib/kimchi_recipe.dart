// kimchi_recipe.dart

// TODO: 차후 서버 API를 통해 김치 데이터를 가져오도록 수정 예정
// - API 엔드포인트: 예: 'https://api.example.com/kimchi-recipes'
// - 예상 응답 형식:
//   [
//     [
//       {
//         "kimchi_num": 1,
//         "name": "할머니 배추김치",
//         "recipe_order": 1,
//         "recipe_detail": "배추를 소금에 절인다.",
//         "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
//       },
//       {
//         "kimchi_num": 1,
//         "recipe_order": 2,
//         "recipe_detail": "소금에 절인 배추를 꺼낸다",
//         "recipe_image_serial_num": null
//       },
//       ...
//     ],
//     [
//       {
//         "kimchi_num": 2,
//         "name": "매운 깍두기",
//         "recipe_order": 1,
//         "recipe_detail": "레시피를 준비중입니다.",
//         "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
//       },
//       ...
//     ],
//     ...
//   ]
// - API 통신 함수 예시:
// Future<List<List<Map<String, dynamic>>>> fetchKimchiList() async {
//   final response = await http.get(Uri.parse('https://api.example.com/kimchi-recipes'));
//   if (response.statusCode == 200) {
//     List<dynamic> jsonList = jsonDecode(response.body);
//     return jsonList.map((kimchi) => List<Map<String, dynamic>>.from(kimchi)).toList();
//   } else {
//     throw Exception('Failed to load kimchi recipes');
//   }
// }

const List<List<Map<String, dynamic>>> kimchiList = [
  // 김치 1: 배추김치 1 → 할머니 배추김치
  [
    {
      "kimchi_num": 1,
      "name": "할머니 배추김치", // 고유 이름 추가
      "recipe_order": 1,
      "recipe_detail": "배추를 소금에 절인다.ㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇ",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 1,
      "recipe_order": 2,
      "recipe_detail": "소금에 절인 배추를 꺼낸다",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 1,
      "recipe_order": 3,
      "recipe_detail": "김치 속을 만든다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 1,
      "recipe_order": 4,
      "recipe_detail": "절인 배추와 김치 속을 비빈다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 1,
      "recipe_order": 5,
      "recipe_detail": "이렇게 만들어진 배추를 숙성시킨다",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 1,
      "recipe_order": 6,
      "recipe_detail": "이렇게 만들어진 배추를 숙성시킨다",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 1,
      "recipe_order": 7,
      "recipe_detail": "이렇게 만들어진 배추를 숙성시킨다",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 1,
      "recipe_order": 8,
      "recipe_detail": "이렇게 만들어진 배추를 숙성시킨다",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
  ],
  // 김치 2: 깍두기 1 → 매운 깍두기
  [
    {
      "kimchi_num": 2,
      "name": "매운 깍두기",
      "recipe_order": 1,
      "recipe_detail": "레시피를 준비중입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 2,
      "recipe_order": 2,
      "recipe_detail": "다음 레시피 이미지입니다.",
      "recipe_image_serial_num": "assets/images/kkakdugi.png"
    },
  ],
  // 김치 3: 겉절이 1 → 새콤한 겉절이
  [
    {
      "kimchi_num": 3,
      "name": "새콤한 겉절이",
      "recipe_order": 1,
      "recipe_detail": "레시피를 준비중입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 3,
      "recipe_order": 2,
      "recipe_detail": "다음 레시피 이미지입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
  ],
  // 김치 4: 깻잎김치 1 → 향긋한 깻잎김치
  [
    {
      "kimchi_num": 4,
      "name": "향긋한 깻잎김치",
      "recipe_order": 1,
      "recipe_detail": "레시피를 준비중입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 4,
      "recipe_order": 2,
      "recipe_detail": "다음 레시피 이미지입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
  ],
  // 김치 5: 백김치 1 → 시원한 백김치
  [
    {
      "kimchi_num": 5,
      "name": "시원한 백김치",
      "recipe_order": 1,
      "recipe_detail": "레시피를 준비중입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 5,
      "recipe_order": 2,
      "recipe_detail": "다음 레시피 이미지입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
  ],
  // 김치 6: 겉절이 2 → 아삭한 겉절이
  [
    {
      "kimchi_num": 6,
      "name": "아삭한 겉절이",
      "recipe_order": 1,
      "recipe_detail": "레시피를 준비중입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 6,
      "recipe_order": 2,
      "recipe_detail": "다음 레시피 이미지입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
  ],
  // 김치 7: 보쌈김치 1 → 고소한 보쌈김치
  [
    {
      "kimchi_num": 7,
      "name": "고소한 보쌈김치",
      "recipe_order": 1,
      "recipe_detail": "레시피를 준비중입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 7,
      "recipe_order": 2,
      "recipe_detail": "다음 레시피 이미지입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
  ],
  // 김치 8: 총각김치 1 → 알싸한 총각김치
  [
    {
      "kimchi_num": 8,
      "name": "알싸한 총각김치",
      "recipe_order": 1,
      "recipe_detail": "레시피를 준비중입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 8,
      "recipe_order": 2,
      "recipe_detail": "다음 레시피 이미지입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
  ],
  // 김치 9: 부추김치 1 → 싱싱한 부추김치
  [
    {
      "kimchi_num": 9,
      "name": "싱싱한 부추김치",
      "recipe_order": 1,
      "recipe_detail": "레시피를 준비중입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 9,
      "recipe_order": 2,
      "recipe_detail": "다음 레시피 이미지입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
  ],
  // 김치 10: 배추김치 2 → 전통 배추김치
  [
    {
      "kimchi_num": 10,
      "name": "전통 배추김치",
      "recipe_order": 1,
      "recipe_detail": "레시피를 준비중입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 10,
      "recipe_order": 2,
      "recipe_detail": "다음 레시피 이미지입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
  ],
  // 김치 11: 깍두기 2 → 아삭 깍두기
  [
    {
      "kimchi_num": 11,
      "name": "아삭 깍두기",
      "recipe_order": 1,
      "recipe_detail": "레시피를 준비중입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 11,
      "recipe_order": 2,
      "recipe_detail": "다음 레시피 이미지입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
  ],
  // 김치 12: 겉절이 3 → 매콤 겉절이
  [
    {
      "kimchi_num": 12,
      "name": "매콤 겉절이",
      "recipe_order": 1,
      "recipe_detail": "레시피를 준비중입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 12,
      "recipe_order": 2,
      "recipe_detail": "다음 레시피 이미지입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
  ],
  // 김치 13: 깻잎김치 2 → 매운 깻잎김치
  [
    {
      "kimchi_num": 13,
      "name": "매운 깻잎김치",
      "recipe_order": 1,
      "recipe_detail": "레시피를 준비중입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 13,
      "recipe_order": 2,
      "recipe_detail": "다음 레시피 이미지입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
  ],
  // 김치 14: 백김치 2 → 깔끔 백김치
  [
    {
      "kimchi_num": 14,
      "name": "깔끔 백김치",
      "recipe_order": 1,
      "recipe_detail": "레시피를 준비중입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 14,
      "recipe_order": 2,
      "recipe_detail": "다음 레시피 이미지입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
  ],
  // 김치 15: 겉절이 4 → 달콤 겉절이
  [
    {
      "kimchi_num": 15,
      "name": "달콤 겉절이",
      "recipe_order": 1,
      "recipe_detail": "레시피를 준비중입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 15,
      "recipe_order": 2,
      "recipe_detail": "다음 레시피 이미지입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
  ],
  // 김치 16: 보쌈김치 2 → 짭짤 보쌈김치
  [
    {
      "kimchi_num": 16,
      "name": "짭짤 보쌈김치",
      "recipe_order": 1,
      "recipe_detail": "레시피를 준비중입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 16,
      "recipe_order": 2,
      "recipe_detail": "다음 레시피 이미지입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
  ],
  // 김치 17: 총각김치 2 → 매콤 총각김치
  [
    {
      "kimchi_num": 17,
      "name": "매콤 총각김치",
      "recipe_order": 1,
      "recipe_detail": "레시피를 준비중입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 17,
      "recipe_order": 2,
      "recipe_detail": "다음 레시피 이미지입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
  ],
  // 김치 18: 부추김치 2 → 매운 부추김치
  [
    {
      "kimchi_num": 18,
      "name": "매운 부추김치",
      "recipe_order": 1,
      "recipe_detail": "레시피를 준비중입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 18,
      "recipe_order": 2,
      "recipe_detail": "다음 레시피 이미지입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
  ],
  // 김치 19: 배추김치 3 → 얼큰 배추김치
  [
    {
      "kimchi_num": 19,
      "name": "얼큰 배추김치",
      "recipe_order": 1,
      "recipe_detail": "레시피를 준비중입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 19,
      "recipe_order": 2,
      "recipe_detail": "다음 레시피 이미지입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
  ],
  // 김치 20: 깍두기 3 → 시원 깍두기
  [
    {
      "kimchi_num": 20,
      "name": "시원 깍두기",
      "recipe_order": 1,
      "recipe_detail": "레시피를 준비중입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 20,
      "recipe_order": 2,
      "recipe_detail": "다음 레시피 이미지입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
  ],
  // 김치 21: 겉절이 5 → 고소한 겉절이
  [
    {
      "kimchi_num": 21,
      "name": "고소한 겉절이",
      "recipe_order": 1,
      "recipe_detail": "레시피를 준비중입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 21,
      "recipe_order": 2,
      "recipe_detail": "다음 레시피 이미지입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
  ],
  // 김치 22: 깻잎김치 3 → 짭짤 깻잎김치
  [
    {
      "kimchi_num": 22,
      "name": "짭짤 깻잎김치",
      "recipe_order": 1,
      "recipe_detail": "레시피를 준비중입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 22,
      "recipe_order": 2,
      "recipe_detail": "다음 레시피 이미지입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
  ],
  // 김치 23: 백김치 3 → 담백 백김치
  [
    {
      "kimchi_num": 23,
      "name": "담백 백김치",
      "recipe_order": 1,
      "recipe_detail": "레시피를 준비중입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 23,
      "recipe_order": 2,
      "recipe_detail": "다음 레시피 이미지입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
  ],
  // 김치 24: 겉절이 6 → 상큼 겉절이
  [
    {
      "kimchi_num": 24,
      "name": "상큼 겉절이",
      "recipe_order": 1,
      "recipe_detail": "레시피를 준비중입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 24,
      "recipe_order": 2,
      "recipe_detail": "다음 레시피 이미지입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
  ],
  // 김치 25: 보쌈김치 3 → 달콤 보쌈김치
  [
    {
      "kimchi_num": 25,
      "name": "달콤 보쌈김치",
      "recipe_order": 1,
      "recipe_detail": "레시피를 준비중입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 25,
      "recipe_order": 2,
      "recipe_detail": "다음 레시피 이미지입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
  ],
  // 김치 26: 총각김치 3 → 아삭 총각김치
  [
    {
      "kimchi_num": 26,
      "name": "아삭 총각김치",
      "recipe_order": 1,
      "recipe_detail": "레시피를 준비중입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 26,
      "recipe_order": 2,
      "recipe_detail": "다음 레시피 이미지입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
  ],
  // 김치 27: 부추김치 3 → 향긋 부추김치
  [
    {
      "kimchi_num": 27,
      "name": "향긋 부추김치",
      "recipe_order": 1,
      "recipe_detail": "레시피를 준비중입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
    {
      "kimchi_num": 27,
      "recipe_order": 2,
      "recipe_detail": "다음 레시피 이미지입니다.",
      "recipe_image_serial_num": "assets/images/cabbagekimchi.png"
    },
  ],
];