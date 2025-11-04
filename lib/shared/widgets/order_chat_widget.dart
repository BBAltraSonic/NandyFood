import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
// import 'package:record/record.dart'; // Temporarily disabled
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

import 'package:food_delivery_app/shared/models/order_conversation.dart';
import 'package:food_delivery_app/shared/models/order_message.dart';
import 'package:food_delivery_app/core/services/order_chat_service.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/shared/theme/app_theme.dart';

/// Compact chat widget for order-specific communication
class OrderChatWidget extends ConsumerStatefulWidget {
  final String orderId;
  final String conversationId;
  final VoidCallback? onClose;
  final bool showHeader;
  final double? height;
  final double? width;

  const OrderChatWidget({
    super.key,
    required this.orderId,
    required this.conversationId,
    this.onClose,
    this.showHeader = true,
    this.height,
    this.width,
  });

  @override
  ConsumerState<OrderChatWidget> createState() => _OrderChatWidgetState();
}

class _OrderChatWidgetState extends ConsumerState<OrderChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  // final AudioRecorder _audioRecorder = AudioRecorder(); // Temporarily disabled

  List<OrderMessage> _messages = [];
  bool _isLoading = true;
  bool _isRecording = false;
  bool _isUploading = false;
  Timer? _recordingTimer;
  int _recordingDuration = 0;
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _recordingTimer?.cancel();
    _stopRecording();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    try {
      final chatService = ref.read(orderChatServiceProvider);

      // Subscribe to messages
      chatService.subscribeToMessages(widget.conversationId).listen(
        (messages) {
          if (mounted) {
            setState(() {
              _messages = messages;
              _isLoading = false;
            });
            _scrollToBottom();
          }
        },
        onError: (error) {
          AppLogger.error('Error in message subscription: $error');
          if (mounted) {
            setState(() => _isLoading = false);
          }
        },
      );
    } catch (e) {
      AppLogger.error('Failed to initialize chat: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      setState(() => _isUploading = true);
      _messageController.clear();

      final chatService = ref.read(orderChatServiceProvider);
      await chatService.sendTextMessage(widget.conversationId, text);

      _scrollToBottom();
    } catch (e) {
      AppLogger.error('Failed to send message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.black87,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _sendImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        setState(() => _isUploading = true);

        final chatService = ref.read(orderChatServiceProvider);
        await chatService.sendImageMessage(widget.conversationId, file);

        _scrollToBottom();
      }
    } catch (e) {
      AppLogger.error('Failed to send image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image: $e'),
            backgroundColor: Colors.black87,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      // if (await _audioRecorder.hasPermission()) { // Temporarily disabled
        // setState(() => _isRecording = true);

        // // Start recording timer
        // _recordingDuration = 0;
        // _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        //   setState(() => _recordingDuration++);
        // });

        /* // Voice recording temporarily disabled
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: 'voice_message_${DateTime.now().millisecondsSinceEpoch}.m4a',
        );
        */
      // }
    } catch (e) {
      AppLogger.error('Failed to start recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: Colors.black87,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      if (_isRecording) {
        _recordingTimer?.cancel();

        // final recording = await _audioRecorder.stop(); // Temporarily disabled
        /* if (recording != null) {
          final file = File(recording);

          setState(() {
            _isRecording = false;
            _isUploading = true;
          });

          // Generate simple waveform data (in a real app, you'd analyze the audio)
          final waveform = List.generate(20, (i) => (i % 3 + 1) * 0.3);

          final chatService = ref.read(orderChatServiceProvider);
          await chatService.sendVoiceMessage(
            widget.conversationId,
            file,
            _recordingDuration,
            waveform,
          );

          _scrollToBottom();
        }
        */
      }
    } catch (e) {
      AppLogger.error('Failed to stop recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send voice message: $e'),
            backgroundColor: Colors.black87,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isUploading = false;
          _recordingDuration = 0;
        });
      }
    }
  }

  void _onEmojiSelected(Emoji emoji) {
    final text = _messageController.text + emoji.emoji;
    _messageController.value = TextEditingValue(
      text: text,
      selection: TextSelection.fromPosition(
        TextPosition(offset: text.length),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final chatHeight = widget.height ?? screenSize.height * 0.6;
    final chatWidth = widget.width ?? (screenSize.width > 600 ? 400 : double.infinity);

    return Container(
      width: chatWidth,
      height: chatHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Column(
          children: [
            if (widget.showHeader) _buildHeader(),
            _buildMessageList(),
            _buildMessageInput(),
            if (_showEmojiPicker) _buildEmojiPicker(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${widget.orderId.substring(0, 8)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Chat Support',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onClose != null)
            IconButton(
              onPressed: widget.onClose,
              icon: const Icon(Icons.close, color: Colors.white),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_isLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_messages.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 48.w,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: 16.h),
              Text(
                'No messages yet',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Start a conversation about your order',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          return _buildMessageBubble(message);
        },
      ),
    );
  }

  Widget _buildMessageBubble(OrderMessage message) {
    final isFromMe = message.isFromCurrentUser;
    final isSystemMessage = message.isSystemMessage;

    if (isSystemMessage) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(
        bottom: 12.h,
        left: isFromMe ? 48.w : 0,
        right: isFromMe ? 0 : 48.w,
      ),
      child: Column(
        crossAxisAlignment: isFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isFromMe && message.senderName != null)
            Padding(
              padding: EdgeInsets.only(bottom: 4.h, left: 12.w),
              child: Text(
                message.senderName!,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: isFromMe ? AppTheme.primaryColor : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(18.r).copyWith(
                      bottomLeft: isFromMe ? Radius.circular(18.r) : Radius.circular(4.r),
                      bottomRight: isFromMe ? Radius.circular(4.r) : Radius.circular(18.r),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMessageContent(message),
                      SizedBox(height: 4.h),
                      Text(
                        message.getFormattedTime(),
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: isFromMe
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(OrderMessage message) {
    if (message.isTextMessage) {
      return Text(
        message.content,
        style: TextStyle(
          fontSize: 14.sp,
          color: message.isFromCurrentUser ? Colors.white : Colors.black87,
        ),
      );
    }

    if (message.isImageMessage) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📷 Image',
            style: TextStyle(
              fontSize: 14.sp,
              color: message.isFromCurrentUser ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (message.fileName != null)
            Text(
              message.fileName!,
              style: TextStyle(
                fontSize: 12.sp,
                color: message.isFromCurrentUser
                    ? Colors.white.withOpacity(0.8)
                    : Colors.grey.shade600,
              ),
            ),
        ],
      );
    }

    if (message.isVoiceMessage) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mic,
            size: 16.w,
            color: message.isFromCurrentUser ? Colors.white : Colors.black87,
          ),
          SizedBox(width: 8.w),
          Text(
            message.getFormattedVoiceDuration(),
            style: TextStyle(
              fontSize: 14.sp,
              color: message.isFromCurrentUser ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    if (message.isCallMessage) {
      return Text(
        message.content,
        style: TextStyle(
          fontSize: 14.sp,
          color: message.isFromCurrentUser ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Text(
      message.getDisplayText(),
      style: TextStyle(
        fontSize: 14.sp,
        color: message.isFromCurrentUser ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildMessageInput() {
    if (_isRecording) {
      return _buildRecordingInput();
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _isUploading ? null : _sendImage,
            icon: Icon(
              Icons.image,
              color: _isUploading ? Colors.grey : AppTheme.primaryColor,
            ),
          ),
          IconButton(
            onPressed: _isUploading ? null : () {
              setState(() => _showEmojiPicker = !_showEmojiPicker);
            },
            icon: Icon(
              Icons.emoji_emotions_outlined,
              color: _isUploading ? Colors.grey : AppTheme.primaryColor,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !_isUploading,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: 8.w),
          if (_messageController.text.trim().isEmpty)
            GestureDetector(
              onLongPressStart: (_) => _startRecording(),
              onLongPressEnd: (_) => _stopRecording(),
              child: CircleAvatar(
                backgroundColor: _isUploading ? Colors.grey : AppTheme.primaryColor,
                radius: 20.r,
                child: Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 20.w,
                ),
              ),
            )
          else
            CircleAvatar(
              backgroundColor: _isUploading ? Colors.grey : AppTheme.primaryColor,
              radius: 20.r,
              child: _isUploading
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : IconButton(
                      onPressed: _sendMessage,
                      icon: Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20.w,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecordingInput() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.black87,
            radius: 20.r,
            child: Icon(
              Icons.mic,
              color: Colors.white,
              size: 20.w,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recording... (${_recordingDuration}s)',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade100,
                  ),
                ),
                Text(
                  'Release to send',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade100,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Center(
              child: Container(
                width: 16.w,
                height: 16.w,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return Container(
      height: 250.h,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) => _onEmojiSelected(emoji),
        config: const Config(
          height: 250,
          checkPlatformCompatibility: true,
        ),
      ),
    );
  }
}