import 'package:flutter/material.dart';

Future<void> showTimelineExplanationDialog({
  required BuildContext context,
  required String title,
  required String explanation,
  String? localAssetImage,
  String? imageUrl,
  String? sourcePage,
  String? imageLicense,
  String? imageLicenseUrl,
  String? imageAuthor,
  String? imageCredit,
}) {
  if (explanation.trim().isEmpty) {
    return Future.value();
  }
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TimelineDialogImage(
                localAssetImage: localAssetImage,
                imageUrl: imageUrl,
              ),
              if ((localAssetImage != null &&
                      localAssetImage.trim().isNotEmpty) ||
                  (imageUrl != null && imageUrl.trim().isNotEmpty))
                const SizedBox(height: 12),
              Text(explanation),
              _ImageAttributionBlock(
                sourcePage: sourcePage,
                imageLicense: imageLicense,
                imageLicenseUrl: imageLicenseUrl,
                imageAuthor: imageAuthor,
                imageCredit: imageCredit,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

class _ImageAttributionBlock extends StatelessWidget {
  const _ImageAttributionBlock({
    this.sourcePage,
    this.imageLicense,
    this.imageLicenseUrl,
    this.imageAuthor,
    this.imageCredit,
  });

  final String? sourcePage;
  final String? imageLicense;
  final String? imageLicenseUrl;
  final String? imageAuthor;
  final String? imageCredit;

  @override
  Widget build(BuildContext context) {
    final rows = <String>[
      if (sourcePage != null && sourcePage!.trim().isNotEmpty)
        'Source: ${sourcePage!.trim()}',
      if (imageLicense != null && imageLicense!.trim().isNotEmpty)
        'License: ${imageLicense!.trim()}',
      if (imageLicenseUrl != null && imageLicenseUrl!.trim().isNotEmpty)
        'License URL: ${imageLicenseUrl!.trim()}',
      if (imageAuthor != null && imageAuthor!.trim().isNotEmpty)
        'Author: ${imageAuthor!.trim()}',
      if (imageCredit != null && imageCredit!.trim().isNotEmpty)
        'Credit: ${imageCredit!.trim()}',
    ];
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }
    final labelStyle = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700);
    final bodyStyle = Theme.of(context).textTheme.bodySmall;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Image Attribution', style: labelStyle),
          const SizedBox(height: 6),
          for (var i = 0; i < rows.length; i++) ...[
            SelectableText(rows[i], style: bodyStyle),
            if (i < rows.length - 1) const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _TimelineDialogImage extends StatelessWidget {
  const _TimelineDialogImage({this.localAssetImage, this.imageUrl});

  final String? localAssetImage;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final trimmedAsset = localAssetImage?.trim();
    final trimmedUrl = imageUrl?.trim();
    if ((trimmedAsset == null || trimmedAsset.isEmpty) &&
        (trimmedUrl == null || trimmedUrl.isEmpty)) {
      return const SizedBox.shrink();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 320,
        height: 180,
        child: _buildImage(trimmedAsset, trimmedUrl),
      ),
    );
  }

  Widget _buildImage(String? assetPath, String? url) {
    if (assetPath != null && assetPath.isNotEmpty) {
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildNetwork(url),
      );
    }
    return _buildNetwork(url);
  }

  Widget _buildNetwork(String? url) {
    if (url == null || url.isEmpty) {
      return const SizedBox.shrink();
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}
