# 따옴 (Ddaom) — Frontend

> 핫플 포토 가이드 앱. 인기 장소의 "포토존"을 찾고, 원조 사진의 포즈를 ML 가이드로 따라 찍어 공유한다.

Flutter로 만든 모바일 앱(iOS·Android)입니다. 지도에서 핫플을 탐색하고, 장소마다 등록된 포토존과 그곳에서 찍은 사진들을 둘러보며, 카메라로 원조 사진의 포즈를 실시간으로 따라 찍을 수 있습니다.

## 핵심 기능

- **지도 기반 탐색** — 네이버 지도 위에서 인기 장소를 탐색하고 현재 위치를 표시
- **지역 검색** — 네이버 지역검색으로 원하는 동네로 이동
- **장소·포토존** — 장소 상세에서 포토존 목록과 각 포토존의 사진 모아보기, 장소 등록
- **따오기 카메라 (가이드 카메라)** — 원조 사진을 ML Kit Pose Detection으로 분석해, 같은 포즈를 잡도록 실시간 오버레이 가이드 제공
- **내맘대로 카메라** — 가이드 없이 자유 촬영, 여러 장 누적 후 선택 일괄 등록
- **커뮤니티 / 마이페이지** — 사진 좋아요·팔로우, 프로필 사진 업로드, 내가 올린 사진·저장한 장소 관리
- **Google 로그인** — Google OAuth 기반 인증(JWT)

## 기술 스택

| 영역        | 사용 기술                                                 |
| ----------- | --------------------------------------------------------- |
| 프레임워크  | Flutter (Dart SDK ^3.11.5)                                |
| 상태관리    | provider                                                  |
| 네트워크    | dio (`ApiClient` 인터셉터로 JWT 주입·응답 래퍼 처리)      |
| 지도        | flutter_naver_map                                         |
| 카메라·ML   | camera, google_mlkit_pose_detection, google_mlkit_commons |
| 인증·저장소 | google_sign_in, flutter_secure_storage                    |
| 기타        | image_picker, permission_handler, geolocator, gal         |

## 프로젝트 구조

```
lib/
├── main.dart              # 앱 진입점, NaverMap init, Provider 트리 구성
├── core/                  # 공통 인프라
│   ├── api_client.dart        # dio 래퍼: baseUrl·JWT·응답 래퍼({code,message,data}) 처리
│   ├── app_theme.dart
│   ├── naver_map_config.dart  # 지도 클라이언트 ID (gitignore)
│   ├── place_repository.dart
│   ├── network_thumb.dart     # 대표이미지 placeholder
│   └── secure_storage.dart    # JWT 토큰 보관
├── features/
│   ├── auth/              # Google 로그인, 인증 상태
│   ├── home/             # 홈 지도 뷰, 지역 선택
│   ├── place/            # 장소 등록·상세·검색, 포토존, 네이버 검색 프록시 클라이언트
│   ├── photo/            # 따오기/일반 카메라, 사진 선택·메타데이터·업로드
│   ├── community/        # 피드, 사진 상세
│   ├── mypage/           # 내 프로필, 내 사진·저장
│   ├── saved/            # 저장(북마크)한 장소
│   ├── user/            # 타 유저 프로필, 팔로우
│   ├── search/
│   └── shell/           # 하단 탭 내비게이션(MainShell)
└── screens/             # camera_screen(홈 카메라), home_screen
```

## 시작하기

### 사전 준비

- Flutter SDK (Dart ^3.11.5)
- iOS: Xcode / Android: Android SDK
- `lib/core/naver_map_config.dart` — 네이버 지도 클라이언트 ID (gitignore 대상, 별도 발급 필요)
- 백엔드 서버 주소를 `lib/core/api_client.dart`의 `baseUrl`에 설정

### 실행

```bash
flutter pub get

# 개발(디버그) — 케이블 연결 상태에서 핫리로드
flutter run

# 실기기 독립 실행(릴리스)
flutter build ios --release
flutter install --release -d <device-id>
```

> ⚠️ `flutter run`은 디버그 빌드라 케이블을 뽑으면 종료됩니다. 케이블 없이 독립 실행하려면 릴리스 빌드를 설치하세요.

### 검증

```bash
flutter analyze
flutter test
```

## 백엔드

이 앱은 Spring Boot 백엔드(`Ddaom-backend`)와 통신합니다. API 명세는 백엔드 레포의 `API.md`를 참고하세요. 네이버 지역검색·지오코딩·이미지 업로드(S3)는 모두 백엔드 프록시를 경유합니다.
