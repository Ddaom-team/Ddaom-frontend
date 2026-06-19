import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import 'auth_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _handleGoogleLogin(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithGoogle();
    if (!context.mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const _Logo(),
              const SizedBox(height: 14),
              const Text(
                '따옴',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '핫플에서 인생샷 실패하지 말자!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '어디서, 어떻게 찍어야 잘나오는지\n알려주는 실시간 포토 가이드',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              const _LoginIllustration(),
              const SizedBox(height: 24),
              _GoogleLoginButton(
                loading: loading,
                onTap: loading ? null : () => _handleGoogleLogin(context),
              ),
              const SizedBox(height: 12),
              const _FooterNotice(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/images/Logo.png',
        width: 72,
        height: 72,
      ),
    );
  }
}

class _LoginIllustration extends StatelessWidget {
  const _LoginIllustration();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        'assets/images/login_illustration.png',
        height: 160,
        fit: BoxFit.cover,
        alignment: Alignment.center,
      ),
    );
  }
}

class _GoogleLoginButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onTap;
  const _GoogleLoginButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.divider),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primaryPink,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  _GoogleGLogo(size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Google 계정으로 로그인',
                    style: TextStyle(
                      color: AppColors.textMain,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Google 공식 G 로고에 가까운 간단 표현. 실서비스에서는
/// 공식 PNG/SVG 자산으로 교체 권장 (브랜드 가이드 준수).
class _GoogleGLogo extends StatelessWidget {
  final double size;
  const _GoogleGLogo({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.22;
    final innerRect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    void arc(double startDeg, double sweepDeg, Color color) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        innerRect,
        startDeg * 3.1415926 / 180,
        sweepDeg * 3.1415926 / 180,
        false,
        paint,
      );
    }

    arc(-20, -70, const Color(0xFFEA4335));
    arc(-90, -90, const Color(0xFFFBBC05));
    arc(180, -90, const Color(0xFF34A853));
    arc(90, -110, const Color(0xFF4285F4));

    final barPaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx,
        center.dy - strokeWidth / 2,
        radius - strokeWidth * 0.2,
        strokeWidth,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FooterNotice extends StatelessWidget {
  const _FooterNotice();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.check_circle_outline,
            size: 14, color: AppColors.textMuted),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            '로그인 시 서비스 개인정보 추가 기능을 사용할 수 있어요',
            style: TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ),
      ],
    );
  }
}
