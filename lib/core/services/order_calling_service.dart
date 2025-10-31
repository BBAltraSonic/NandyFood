import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';

import 'package:food_delivery_app/shared/models/order_conversation.dart';
import 'package:food_delivery_app/shared/models/order_call.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';

/// Provider for OrderCallingService
final orderCallingServiceProvider = Provider<OrderCallingService>((ref) {
  final supabase = Supabase.instance.client;
  return OrderCallingService(supabase);
});

/// Call event types
enum CallEventType {
  incoming,
  outgoing,
  connected,
  ended,
  missed,
  rejected,
  qualityUpdate,
}

/// Call event data
class CallEvent {
  final CallEventType type;
  final OrderCall? call;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  CallEvent({
    required this.type,
    this.call,
    this.errorMessage,
    this.metadata,
  });
}

/// Service for managing order-specific voice/video calling
class OrderCallingService {
  OrderCallingService(this._supabase);

  final SupabaseClient _supabase;
  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, StreamController<CallEvent>> _callControllers = {};
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, MediaStream> _localStreams = {};
  final Map<String, MediaStream> _remoteStreams = {};
  final Uuid _uuid = const Uuid();

  // WebRTC configuration
  final Map<String, dynamic> _rtcConfiguration = {
    'iceServers': [
      {
        'urls': ['stun:stun.l.google.com:19302', 'stun:stun1.l.google.com:19302'],
      },
    ],
    'iceCandidatePoolSize': 10,
  };

  /// Stream controller for call events
  final StreamController<CallEvent> _callEventController =
      StreamController<CallEvent>.broadcast();

  /// Stream of call events
  Stream<CallEvent> get callEvents => _callEventController.stream;

  /// Initialize calling service
  Future<void> initialize() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Subscribe to incoming calls for current user
      await _subscribeToIncomingCalls(currentUser.id);

      AppLogger.info('OrderCallingService initialized for user: ${currentUser.id}');
    } catch (e) {
      AppLogger.error('Failed to initialize OrderCallingService: $e');
      rethrow;
    }
  }

  /// Subscribe to incoming calls
  Future<void> _subscribeToIncomingCalls(String userId) async {
    final channelName = 'user_calls:$userId';

    final channel = _supabase.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'order_calls',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: userId,
          ),
          callback: (payload) {
            _handleIncomingCall(payload.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'order_calls',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: userId,
          ),
          callback: (payload) {
            _handleCallUpdate(payload.newRecord);
          },
        )
        .subscribe();

    _channels[channelName] = channel;
  }

  /// Handle incoming call
  void _handleIncomingCall(Map<String, dynamic> callData) {
    try {
      final call = OrderCall.fromJson(callData);

      // Add user context fields
      final currentUser = _supabase.auth.currentUser;
      callData['is_with_me'] = callData['receiver_id'] == currentUser?.id;

      final event = CallEvent(
        type: CallEventType.incoming,
        call: OrderCall.fromJson(callData),
      );

      _callEventController.add(event);
      AppLogger.info('Incoming call: ${call.id}');
    } catch (e) {
      AppLogger.error('Error handling incoming call: $e');
    }
  }

  /// Handle call update
  void _handleCallUpdate(Map<String, dynamic> callData) {
    try {
      final call = OrderCall.fromJson(callData);
      CallEventType eventType;

      switch (call.status) {
        case 'connected':
          eventType = CallEventType.connected;
          break;
        case 'ended':
          eventType = CallEventType.ended;
          break;
        case 'missed':
          eventType = CallEventType.missed;
          break;
        case 'failed':
          eventType = CallEventType.rejected;
          break;
        default:
          return; // Don't emit event for other status updates
      }

      final event = CallEvent(
        type: eventType,
        call: call,
      );

      _callEventController.add(event);
      AppLogger.info('Call update: ${call.id} - ${call.status}');
    } catch (e) {
      AppLogger.error('Error handling call update: $e');
    }
  }

  /// Initiate a voice/video call
  Future<OrderCall> initiateCall({
    required String conversationId,
    required String orderId,
    required String receiverId,
    required CallType callType,
    bool isVideoCall = false,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final callData = {
        'id': _uuid.v4(),
        'conversation_id': conversationId,
        'order_id': orderId,
        'initiator_id': currentUser.id,
        'receiver_id': receiverId,
        'call_type': isVideoCall ? 'video' : 'voice',
        'status': 'initiated',
        'duration': 0,
        'initiated_at': DateTime.now().toIso8601String(),
        'metadata': {
          'signaling_server': 'supabase',
          'webrtc_version': '1.0.0',
          'platform': defaultTargetPlatform.toString(),
        },
      };

      final newCall = await _supabase
          .from('order_calls')
          .insert(callData)
          .select('''
            *,
            user_profiles!initiator_id(
              full_name,
              avatar_url
            ),
            user_profiles!receiver_id(
              full_name,
              avatar_url
            )
          ''')
          .single();

      final call = OrderCall.fromJson(newCall);

      // Add user context
      callData['is_initiated_by_me'] = true;
      callData['is_with_me'] = false;

      // Send system message about the call
      await _sendCallSystemMessage(conversationId, orderId, call, 'call_started');

      // Emit outgoing call event
      _callEventController.add(CallEvent(
        type: CallEventType.outgoing,
        call: call,
      ));

      AppLogger.info('Outgoing call initiated: ${call.id}');
      return call;
    } catch (e) {
      AppLogger.error('Failed to initiate call: $e');
      rethrow;
    }
  }

  /// Accept an incoming call
  Future<void> acceptCall(String callId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Update call status to connected
      await _supabase
          .from('order_calls')
          .update({
            'status': 'connected',
            'connected_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', callId)
          .eq('receiver_id', currentUser.id);

      // Initialize WebRTC connection
      await _initializeWebRTCConnection(callId);

      AppLogger.info('Call accepted: $callId');
    } catch (e) {
      AppLogger.error('Failed to accept call: $e');
      rethrow;
    }
  }

  /// Reject an incoming call
  Future<void> rejectCall(String callId, {String reason = 'user_rejected'}) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('order_calls')
          .update({
            'status': 'failed',
            'ended_at': DateTime.now().toIso8601String(),
            'end_reason': reason,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', callId)
          .eq('receiver_id', currentUser.id);

      AppLogger.info('Call rejected: $callId');
    } catch (e) {
      AppLogger.error('Failed to reject call: $e');
      rethrow;
    }
  }

  /// End an active call
  Future<void> endCall(String callId, {String reason = 'user_hung_up'}) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Calculate call duration
      final callData = await _supabase
          .from('order_calls')
          .select('connected_at, initiated_at')
          .eq('id', callId)
          .single();

      final connectedAt = callData['connected_at'] != null
          ? DateTime.parse(callData['connected_at'])
          : null;
      final initiatedAt = DateTime.parse(callData['initiated_at']);
      final now = DateTime.now();

      final duration = connectedAt != null
          ? now.difference(connectedAt).inSeconds
          : 0;

      // Update call record
      await _supabase
          .from('order_calls')
          .update({
            'status': 'ended',
            'ended_at': now.toIso8601String(),
            'duration': duration,
            'end_reason': reason,
            'updated_at': now.toIso8601String(),
          })
          .eq('id', callId);

      // Clean up WebRTC resources
      await _cleanupWebRTCConnection(callId);

      // Send system message about call ending
      final call = await _getCall(callId);
      if (call != null) {
        await _sendCallSystemMessage(
          call.conversationId,
          call.orderId,
          call,
          'call_ended',
        );
      }

      AppLogger.info('Call ended: $callId, duration: ${duration}s');
    } catch (e) {
      AppLogger.error('Failed to end call: $e');
      rethrow;
    }
  }

  /// Initialize WebRTC connection
  Future<void> _initializeWebRTCConnection(String callId) async {
    try {
      // Create peer connection
      final peerConnection = await createPeerConnection(_rtcConfiguration);
      _peerConnections[callId] = peerConnection;

      // Get local media stream
      final localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false, // Start with voice only, can be upgraded to video
      });
      _localStreams[callId] = localStream;

      // Add local stream to peer connection
      await peerConnection.addStream(localStream);

      // Set up event handlers
      peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
        _handleIceCandidate(callId, candidate);
      };

      peerConnection.onAddStream = (MediaStream stream) {
        _handleRemoteStream(callId, stream);
      };

      peerConnection.onConnectionState = (dynamic state) {
        _handleConnectionStateChange(callId, state.toString());
      };

      // Start signaling process
      await _startSignalingProcess(callId);

      AppLogger.info('WebRTC connection initialized for call: $callId');
    } catch (e) {
      AppLogger.error('Failed to initialize WebRTC connection: $e');
      rethrow;
    }
  }

  /// Handle ICE candidate
  void _handleIceCandidate(String callId, RTCIceCandidate candidate) async {
    try {
      // Store ICE candidate in database for signaling
      await _supabase
          .from('call_signaling')
          .insert({
            'call_id': callId,
            'type': 'ice_candidate',
            'data': candidate.toMap(),
            'created_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      AppLogger.error('Failed to handle ICE candidate: $e');
    }
  }

  /// Handle remote stream
  void _handleRemoteStream(String callId, MediaStream stream) {
    _remoteStreams[callId] = stream;

    // Emit quality update event
    _callEventController.add(CallEvent(
      type: CallEventType.qualityUpdate,
      call: null,
      metadata: {'event': 'remote_stream_added', 'callId': callId},
    ));

    AppLogger.info('Remote stream received for call: $callId');
  }

  /// Handle connection state change
  void _handleConnectionStateChange(String callId, String state) {
    AppLogger.info('Connection state changed for call $callId: $state');

    Map<String, dynamic> qualityData = {
      'event': 'connection_state_change',
      'callId': callId,
      'state': state.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Add signal strength estimation
    if (state.contains('Connected')) {
      qualityData['signal_strength'] = _estimateSignalStrength();
      qualityData['connection_quality'] = _assessConnectionQuality();
    }

    _callEventController.add(CallEvent(
      type: CallEventType.qualityUpdate,
      metadata: qualityData,
    ));
  }

  /// Estimate signal strength (simplified)
  int _estimateSignalStrength() {
    // In a real implementation, you would use WebRTC stats
    // For now, return a random value between 3-5
    return 3 + Random().nextInt(3);
  }

  /// Assess connection quality (simplified)
  String _assessConnectionQuality() {
    final strength = _estimateSignalStrength();
    if (strength >= 5) return 'excellent';
    if (strength >= 4) return 'good';
    if (strength >= 3) return 'fair';
    return 'poor';
  }

  /// Start signaling process
  Future<void> _startSignalingProcess(String callId) async {
    try {
      // Create offer
      final offer = await _peerConnections[callId]?.createOffer();
      if (offer != null) {
        await _peerConnections[callId]?.setLocalDescription(offer);

        // Store offer in database
        await _supabase
            .from('call_signaling')
            .insert({
              'call_id': callId,
              'type': 'offer',
              'data': offer.toMap(),
              'created_at': DateTime.now().toIso8601String(),
            });
      }
    } catch (e) {
      AppLogger.error('Failed to start signaling process: $e');
    }
  }

  /// Clean up WebRTC connection
  Future<void> _cleanupWebRTCConnection(String callId) async {
    try {
      // Close peer connection
      final peerConnection = _peerConnections[callId];
      if (peerConnection != null) {
        await peerConnection.close();
        _peerConnections.remove(callId);
      }

      // Stop local stream
      final localStream = _localStreams[callId];
      if (localStream != null) {
        localStream.getTracks().forEach((track) => track.stop());
        await localStream.dispose();
        _localStreams.remove(callId);
      }

      // Dispose remote stream
      final remoteStream = _remoteStreams[callId];
      if (remoteStream != null) {
        await remoteStream.dispose();
        _remoteStreams.remove(callId);
      }

      AppLogger.info('WebRTC connection cleaned up for call: $callId');
    } catch (e) {
      AppLogger.error('Failed to cleanup WebRTC connection: $e');
    }
  }

  /// Get call by ID
  Future<OrderCall?> _getCall(String callId) async {
    try {
      final callData = await _supabase
          .from('order_calls')
          .select('*')
          .eq('id', callId)
          .maybeSingle();

      return callData != null ? OrderCall.fromJson(callData) : null;
    } catch (e) {
      AppLogger.error('Failed to get call: $e');
      return null;
    }
  }

  /// Send system message about call
  Future<void> _sendCallSystemMessage(
    String conversationId,
    String orderId,
    OrderCall call,
    String messageType,
  ) async {
    try {
      String content;
      Map<String, dynamic> metadata;

      if (messageType == 'call_started') {
        content = call.isVideoCall ? '📹 Video call started' : '📞 Voice call started';
        metadata = {
          'call_id': call.id,
          'call_type': call.callType.toString(),
          'initiated_by': call.initiatorId,
        };
      } else {
        final duration = call.getFormattedDuration();
        content = call.isVideoCall
            ? '📹 Video call ended ($duration)'
            : '📞 Voice call ended ($duration)';
        metadata = {
          'call_id': call.id,
          'call_type': call.callType.toString(),
          'duration': call.duration,
          'end_reason': call.endReason,
        };
      }

      await _supabase
          .from('order_messages')
          .insert({
            'id': _uuid.v4(),
            'conversation_id': conversationId,
            'order_id': orderId,
            'sender_id': 'system', // System message
            'content': content,
            'message_type': messageType,
            'status': 'sent',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'metadata': metadata,
          });
    } catch (e) {
      AppLogger.error('Failed to send call system message: $e');
    }
  }

  /// Get local media stream for a call
  MediaStream? getLocalStream(String callId) {
    return _localStreams[callId];
  }

  /// Get remote media stream for a call
  MediaStream? getRemoteStream(String callId) {
    return _remoteStreams[callId];
  }

  /// Toggle microphone mute state
  Future<void> toggleMute(String callId, bool isMuted) async {
    try {
      final localStream = _localStreams[callId];
      if (localStream != null) {
        final audioTracks = localStream.getAudioTracks();
        for (final track in audioTracks) {
          track.enabled = !isMuted;
        }
      }
    } catch (e) {
      AppLogger.error('Failed to toggle mute: $e');
    }
  }

  /// Toggle speakerphone
  Future<void> toggleSpeakerphone(String callId, bool isSpeakerOn) async {
    try {
      final localStream = _localStreams[callId];
      if (localStream != null) {
        final audioTracks = localStream.getAudioTracks();
        for (final track in audioTracks) {
          // Note: Speaker control is platform-specific
          // This is a simplified implementation
          await track.applyConstraints({
            'echoCancellation': !isSpeakerOn,
            'noiseSuppression': !isSpeakerOn,
          });
        }
      }
    } catch (e) {
      AppLogger.error('Failed to toggle speakerphone: $e');
    }
  }

  /// Dispose the service
  void dispose() {
    // Clean up all WebRTC connections
    for (final callId in _peerConnections.keys.toList()) {
      _cleanupWebRTCConnection(callId);
    }

    // Unsubscribe from all channels
    for (final channel in _channels.values) {
      _supabase.removeChannel(channel);
    }
    _channels.clear();

    // Close controllers
    for (final controller in _callControllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _callControllers.clear();

    if (!_callEventController.isClosed) {
      _callEventController.close();
    }
  }
}