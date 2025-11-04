import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

/// Provider for connectivity status
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  // connectivity_plus v5.0+ uses List<ConnectivityResult>
  return Connectivity().onConnectivityChanged;
});

/// Banner widget that shows connection status
/// 
/// Displays at the top of screens when the device goes offline,
/// and shows a success message when connection is restored.
class OfflineBanner extends ConsumerStatefulWidget {
  final Widget child;

  const OfflineBanner({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends ConsumerState<OfflineBanner>
    with SingleTickerProviderStateMixin {
  bool _wasOffline = false;
  bool _showReconnectedMessage = false;
  Timer? _reconnectedTimer;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _reconnectedTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _showReconnected() {
    setState(() {
      _showReconnectedMessage = true;
    });
    _animationController.forward();
    
    // Hide after 3 seconds
    _reconnectedTimer?.cancel();
    _reconnectedTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _animationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _showReconnectedMessage = false;
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectivityAsync = ref.watch(connectivityProvider);

    return connectivityAsync.when(
      data: (results) {
        final isOffline = results.contains(ConnectivityResult.none);
        
        // Handle state changes
        if (isOffline && !_wasOffline) {
          // Just went offline
          _wasOffline = true;
          _showReconnectedMessage = false;
          _animationController.forward();
        } else if (!isOffline && _wasOffline) {
          // Just came back online
          _wasOffline = false;
          _showReconnected();
        } else if (!isOffline) {
          _wasOffline = false;
        }

        return Stack(
          children: [
            widget.child,
            if (isOffline || _showReconnectedMessage)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _showReconnectedMessage
                      ? _buildReconnectedBanner(context)
                      : _buildOfflineBanner(context),
                ),
              ),
          ],
        );
      },
      loading: () => widget.child,
      error: (_, __) => widget.child,
    );
  }

  Widget _buildOfflineBanner(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.black87,
      elevation: 4,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.wifi_off,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'No Internet Connection',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'You can still browse cached content',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReconnectedBanner(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.black87,
      elevation: 4,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.wifi,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Back Online',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
