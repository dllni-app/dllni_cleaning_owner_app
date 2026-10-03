import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

import '../app_config.dart';
import '../theme/worker_app_colors.dart';

class WorkerAvatar extends StatelessWidget {
  const WorkerAvatar({
    super.key,
    required this.url,
    required this.name,
    required this.size,
    this.backgroundColor = WorkerAppColors.brandPrimarySoft,
    this.foregroundColor = WorkerAppColors.brandPrimary,
  });

  final String? url;
  final String name;
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = resolveWorkerAvatarUrl(url);
    final fallback = _buildFallback(context);

    if (avatarUrl == null) {
      return fallback;
    }

    return AppImage.network(
      avatarUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(size),
      errorWidget: fallback,
    );
  }

  Widget _buildFallback(BuildContext context) {
    final trimmedName = name.trim();
    final initial = trimmedName.isEmpty ? 'ع' : trimmedName.characters.first;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String? resolveWorkerAvatarUrl(String? rawUrl) {
  final value = rawUrl?.trim();
  if (value == null || value.isEmpty) {
    return null;
  }

  final baseUri = Uri.parse(AppConfig.baseUrl);

  if (value.startsWith('//')) {
    return '${baseUri.scheme}:$value';
  }

  final parsed = Uri.tryParse(value);
  if (parsed != null && parsed.hasScheme && parsed.host.isNotEmpty) {
    if (parsed.scheme == 'http' &&
        baseUri.scheme == 'https' &&
        parsed.host == baseUri.host) {
      return parsed.replace(scheme: 'https').toString();
    }
    return parsed.toString();
  }

  return baseUri.resolve(value).toString();
}
