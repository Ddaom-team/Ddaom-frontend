import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import 'core/api_client.dart';
import 'core/naver_map_config.dart';
import 'core/app_theme.dart';
import 'core/secure_storage.dart';
import 'features/auth/auth_provider.dart';
import 'core/place_repository.dart';
import 'features/home/home_provider.dart';
import 'features/mypage/mypage_provider.dart';
import 'features/auth/auth_service.dart';
import 'features/community/community_service.dart';
import 'features/photo/photo_service.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/main_shell.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterNaverMap().init(clientId: naverMapClientId);
  runApp(const DdaomApp());
}

class DdaomApp extends StatelessWidget {
  const DdaomApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = SecureStorage();
    final api = ApiClient(storage)
      ..onUnauthorized = () {
        rootNavigatorKey.currentState
            ?.pushNamedAndRemoveUntil('/login', (_) => false);
      };
    final authService = AuthService(api, storage);
    final authProvider = AuthProvider(authService, storage);

    return MultiProvider(
      providers: [
        Provider<SecureStorage>.value(value: storage),
        Provider<ApiClient>.value(value: api),
        Provider<CommunityService>(create: (ctx) => CommunityService(ctx.read<ApiClient>())),
        Provider<PhotoService>(create: (ctx) => PhotoService(ctx.read<ApiClient>())),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<HomeProvider>(
          create: (ctx) => HomeProvider(ApiPlaceRepository(ctx.read<ApiClient>())),
        ),
        ChangeNotifierProvider<MyPageProvider>(
          create: (ctx) => MyPageProvider(ctx.read<ApiClient>()),
        ),
      ],
      child: MaterialApp(
        title: '따옴',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        navigatorKey: rootNavigatorKey,
        home: _Bootstrap(authProvider: authProvider),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const MainShell(),
        },
      ),
    );
  }
}

class _Bootstrap extends StatefulWidget {
  final AuthProvider authProvider;
  const _Bootstrap({required this.authProvider});

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await widget.authProvider.bootstrap();
    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryPink),
        ),
      );
    }
    return widget.authProvider.isAuthenticated
        ? const MainShell()
        : const LoginScreen();
  }
}
