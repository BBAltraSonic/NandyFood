import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:food_delivery_app/shared/models/order_call.dart';
import 'package:food_delivery_app/core/services/order_calling_service.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/shared/theme/app_theme.dart';

/// Call states for UI
enum CallUIState {
  incoming,
  outgoing,
  connecting,
  connected,
  ended,
}

/// Widget for in-order voice/video calling
class OrderCallWidget extends ConsumerStatefulWidget {
  final OrderCall call;
  final VoidCallback? onCallEnded;
  final bool isVideoCall;

  const OrderCallWidget({
    super.key,
    required this.call,
    this.onCallEnded,
    this.isVideoCall = false,
  });

  @override
  ConsumerState<OrderCallWidget> createState() => _OrderCallWidgetState();
}

class _OrderCallWidgetState extends ConsumerState<OrderCallWidget>
    with TickerProviderStateMixin {
  CallUIState _callState = CallUIState.outgoing;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  Timer? _callTimer;
  int _callDuration = 0;
  String? _connectionQuality;
  int? _signalStrength;

  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _determineCallState();
    _setupCallListener();
    _initializeCall();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
  }

  void _determineCallState() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    if (widget.call.isInitiatedByMe ?? false) {
      _callState = CallUIState.outgoing;
    } else if (widget.call.status == 'initiated' || widget.call.status == 'ringing') {
      _callState = CallUIState.incoming;
    } else if (widget.call.status == 'connected') {
      _callState = CallUIState.connected;
      _startCallTimer();
    } else if (widget.call.status == 'ended') {
      _callState = CallUIState.ended;
    }
  }

  void _setupCallListener() {
    final callingService = ref.read(orderCallingServiceProvider);

    callingService.callEvents.listen((event) {
      if (event.call?.id == widget.call.id) {
        _handleCallEvent(event);
      }
    });
  }

  void _handleCallEvent(CallEvent event) {
    if (!mounted) return;

    setState(() {
      switch (event.type) {
        case CallEventType.connected:
          _callState = CallUIState.connected;
          _startCallTimer();
          _initializeMediaStreams();
          break;
        case CallEventType.ended:
        case CallEventType.missed:
        case CallEventType.rejected:
          _callState = CallUIState.ended;
          _stopCallTimer();
          break;
        case CallEventType.qualityUpdate:
          if (event.metadata != null) {
            _connectionQuality = event.metadata!['connection_quality'];
            _signalStrength = event.metadata!['signal_strength'];
          }
          break;
        default:
          break;
      }
    });
  }

  Future<void> _initializeCall() async {
    try {
      final callingService = ref.read(orderCallingServiceProvider);

      if (widget.call.isInitiatedByMe ?? false) {
        _callState = CallUIState.connecting;
        // For outgoing calls, the service handles WebRTC initialization
      }
    } catch (e) {
      AppLogger.error('Failed to initialize call: $e');
    }
  }

  Future<void> _initializeMediaStreams() async {
    try {
      final callingService = ref.read(orderCallingServiceProvider);

      // Get local and remote streams from the calling service
      callingService.getLocalStream(widget.call.id);
      callingService.getRemoteStream(widget.call.id);

      // Note: For video rendering, you would typically use RTCVideoRenderer
      // but for simplicity in this implementation, we're focusing on voice calls
    } catch (e) {
      AppLogger.error('Failed to initialize media streams: $e');
    }
  }

  void _startCallTimer() {
    _callDuration = 0;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _callDuration++);
    });
  }

  void _stopCallTimer() {
    _callTimer?.cancel();
  }

  Future<void> _acceptCall() async {
    try {
      final callingService = ref.read(orderCallingServiceProvider);
      await callingService.acceptCall(widget.call.id);
      setState(() => _callState = CallUIState.connecting);
    } catch (e) {
      AppLogger.error('Failed to accept call: $e');
    }
  }

  Future<void> _rejectCall() async {
    try {
      final callingService = ref.read(orderCallingServiceProvider);
      await callingService.rejectCall(widget.call.id);
      _endCall();
    } catch (e) {
      AppLogger.error('Failed to reject call: $e');
    }
  }

  Future<void> _endCall() async {
    try {
      final callingService = ref.read(orderCallingServiceProvider);
      await callingService.endCall(widget.call.id);
      widget.onCallEnded?.call();
    } catch (e) {
      AppLogger.error('Failed to end call: $e');
      widget.onCallEnded?.call();
    }
  }

  Future<void> _toggleMute() async {
    try {
      final callingService = ref.read(orderCallingServiceProvider);
      setState(() => _isMuted = !_isMuted);
      await callingService.toggleMute(widget.call.id, _isMuted);
    } catch (e) {
      AppLogger.error('Failed to toggle mute: $e');
    }
  }

  Future<void> _toggleSpeaker() async {
    try {
      final callingService = ref.read(orderCallingServiceProvider);
      setState(() => _isSpeakerOn = !_isSpeakerOn);
      await callingService.toggleSpeakerphone(widget.call.id, _isSpeakerOn);
    } catch (e) {
      AppLogger.error('Failed to toggle speaker: $e');
    }
  }

  String _formatCallDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _getCallStateText() {
    switch (_callState) {
      case CallUIState.incoming:
        return 'Incoming Call';
      case CallUIState.outgoing:
        return 'Calling...';
      case CallUIState.connecting:
        return 'Connecting...';
      case CallUIState.connected:
        return _formatCallDuration(_callDuration);
      case CallUIState.ended:
        return 'Call Ended';
    }
  }

  Widget _buildCallInterface() {
    if (widget.isVideoCall) {
      return _buildVideoCallInterface();
    }
    return _buildVoiceCallInterface();
  }

  Widget _buildVoiceCallInterface() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAvatar(),
                  SizedBox(height: 24.h),
                  _buildCallInfo(),
                  SizedBox(height: 48.h),
                  if (_callState == CallUIState.connected) ...[
                    _buildCallQuality(),
                    SizedBox(height: 24.h),
                  ],
                ],
              ),
            ),
            _buildCallControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCallInterface() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Placeholder for remote video (full screen)
            Container(
              color: Colors.grey.shade900,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAvatar(),
                    SizedBox(height: 16.h),
                    Text(
                      'Video Call',
                      style: TextStyle(
                        fontSize: 18.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Video feature coming soon',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Call info overlay
            Positioned(
              top: 60.h,
              left: 20.w,
              right: 20.w,
              child: _buildCallInfo(),
            ),

            // Call controls
            Positioned(
              bottom: 40.h,
              left: 20.w,
              right: 20.w,
              child: _buildCallControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _callState == CallUIState.incoming ||
                  _callState == CallUIState.outgoing ||
                  _callState == CallUIState.connecting
              ? _pulseAnimation.value
              : 1.0,
          child: CircleAvatar(
            radius: 60.r,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            backgroundImage: widget.call.participantName(isInitiator: false) != 'Unknown'
                ? null
                : null,
            child: widget.call.participantName(isInitiator: false) != 'Unknown'
                ? Text(
                    widget.call.participantName(isInitiator: false)[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 48.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: 60.w,
                    color: AppTheme.primaryColor,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildCallInfo() {
    return Column(
      children: [
        Text(
          widget.call.participantName(isInitiator: false),
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          _getCallStateText(),
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        if (widget.isVideoCall)
          Text(
            'Video Call',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
  }

  Widget _buildCallQuality() {
    if (_connectionQuality == null) return const SizedBox.shrink();

    Color qualityColor;
    switch (_connectionQuality) {
      case 'excellent':
        qualityColor = Colors.black54;
        break;
      case 'good':
        qualityColor = Colors.lightGreen;
        break;
      case 'fair':
        qualityColor = Colors.black54;
        break;
      case 'poor':
        qualityColor = Colors.black87;
        break;
      default:
        qualityColor = Colors.grey;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.signal_cellular_alt,
          color: qualityColor,
          size: 20.w,
        ),
        SizedBox(width: 8.w),
        Text(
          _connectionQuality!.toUpperCase(),
          style: TextStyle(
            color: qualityColor,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (_signalStrength != null) ...[
          SizedBox(width: 16.w),
          Text(
            '$_signalStrength/5',
            style: TextStyle(
              color: qualityColor,
              fontSize: 14.sp,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCallControls() {
    switch (_callState) {
      case CallUIState.incoming:
        return _buildIncomingCallControls();
      case CallUIState.outgoing:
      case CallUIState.connecting:
        return _buildOutgoingCallControls();
      case CallUIState.connected:
        return _buildActiveCallControls();
      case CallUIState.ended:
        return _buildEndedCallControls();
    }
  }

  Widget _buildIncomingCallControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCallButton(
          icon: Icons.call_end,
          color: Colors.black87,
          onPressed: _rejectCall,
        ),
        _buildCallButton(
          icon: Icons.call,
          color: Colors.black54,
          onPressed: _acceptCall,
        ),
      ],
    );
  }

  Widget _buildOutgoingCallControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCallButton(
          icon: Icons.call_end,
          color: Colors.black87,
          onPressed: _endCall,
        ),
      ],
    );
  }

  Widget _buildActiveCallControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCallButton(
          icon: _isMuted ? Icons.mic_off : Icons.mic,
          color: _isMuted ? Colors.grey : Colors.white,
          onPressed: _toggleMute,
        ),
        if (!widget.isVideoCall)
          _buildCallButton(
            icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
            color: _isSpeakerOn ? AppTheme.primaryColor : Colors.white,
            onPressed: _toggleSpeaker,
          ),
        _buildCallButton(
          icon: Icons.call_end,
          color: Colors.black87,
          onPressed: _endCall,
        ),
      ],
    );
  }

  Widget _buildEndedCallControls() {
    return Column(
      children: [
        Text(
          'Call Duration: ${_formatCallDuration(_callDuration)}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 16.sp,
          ),
        ),
        SizedBox(height: 24.h),
        _buildCallButton(
          icon: Icons.close,
          color: Colors.grey,
          onPressed: widget.onCallEnded ?? () {},
        ),
      ],
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 64.w,
        height: 64.h,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28.w,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildCallInterface();
  }
}