import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../community/community_post_detail_screen.dart';
import '../mypage_models.dart';

class PhotoGridTile extends StatefulWidget {
  final GridPhoto photo;
  final bool showAuthor;

  const PhotoGridTile({super.key, required this.photo, this.showAuthor = true});

  @override
  State<PhotoGridTile> createState() => _PhotoGridTileState();
}

class _PhotoGridTileState extends State<PhotoGridTile> {
  late bool _liked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _liked = widget.photo.liked;
    _likeCount = widget.photo.likeCount;
  }

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      _likeCount += _liked ? 1 : -1;
    });
  }

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityPostDetailScreen(photoId: widget.photo.photoId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                widget.photo.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) =>
                    Container(color: AppColors.illustrationBox),
              ),
              if (widget.showAuthor)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xBB000000), Colors.transparent],
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 7,
                          backgroundImage: NetworkImage(widget.photo.authorAvatarUrl),
                          backgroundColor: AppColors.illustrationBox,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            widget.photo.authorName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: _toggleLike,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _liked ? Icons.favorite : Icons.favorite_border,
                          color: _liked ? const Color(0xFFFF6B9D) : Colors.white,
                          size: 11,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '$_likeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          color: AppColors.background,
          padding: const EdgeInsets.fromLTRB(4, 3, 4, 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, size: 9, color: AppColors.primaryPink),
                  const SizedBox(width: 1),
                  Expanded(
                    child: Text(
                      widget.photo.location,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMain,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Text(
                widget.photo.hashtags.map((t) => '#$t').join(' '),
                style: const TextStyle(fontSize: 8, color: AppColors.textMuted),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    ),
    );
  }
}