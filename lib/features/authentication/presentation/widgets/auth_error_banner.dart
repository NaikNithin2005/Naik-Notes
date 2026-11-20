import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Reusable inline error notification component for authentication screens.
///
/// Features a subtle themed background, clear icon, legible typography,
/// and a dismiss button ('X') to ensure error states are never permanently stuck.
/// On desktop OAuth redirect configuration notices, surfaces 1-click helper buttons.
class AuthErrorBanner extends StatefulWidget {
  final String message;
  final VoidCallback? onDismiss;

  const AuthErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
  });

  @override
  State<AuthErrorBanner> createState() => _AuthErrorBannerState();
}

class _AuthErrorBannerState extends State<AuthErrorBanner> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorContainer = theme.colorScheme.errorContainer;
    final onErrorContainer = theme.colorScheme.onErrorContainer;
    final isOAuthRedirectNotice =
        widget.message.contains('http://127.0.0.1:8085/oauth2callback');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 18,
                  color: onErrorContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.message,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: onErrorContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (widget.onDismiss != null) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: widget.onDismiss,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: onErrorContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (isOAuthRedirectNotice) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      const ClipboardData(
                        text: 'http://127.0.0.1:8085/oauth2callback',
                      ),
                    );
                    if (mounted) {
                      setState(() => _copied = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Copied "http://127.0.0.1:8085/oauth2callback" to clipboard!',
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    _copied ? Icons.check : Icons.copy,
                    size: 14,
                    color: onErrorContainer,
                  ),
                  label: Text(
                    _copied ? 'Copied URI' : 'Copy Redirect URI',
                    style: TextStyle(fontSize: 12, color: onErrorContainer),
                  ),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(
                      color: onErrorContainer.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    final uri = Uri.parse(
                      'https://console.cloud.google.com/apis/credentials?project=naik-notes',
                    );
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text(
                    'Open Google Cloud Console',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
