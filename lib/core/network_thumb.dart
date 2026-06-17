import 'package:flutter/material.dart';

import 'app_theme.dart';

/// 네트워크 이미지를 표시하되, URL이 없거나(null/빈 문자열) 로드 실패 시
/// 통일된 플레이스홀더를 보여준다.
/// 대표 이미지가 없을 때 무작위 외부 사진(picsum) 대신 일관된 빈 상태를 노출한다.
class NetworkThumb extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData placeholderIcon;

  const NetworkThumb({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.image_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final u = url;
    if (u == null || u.isEmpty) return _placeholder();
    return Image.network(
      u,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: AppColors.illustrationBox,
        alignment: Alignment.center,
        child: Icon(placeholderIcon, color: AppColors.secondaryPink, size: 28),
      );
}
