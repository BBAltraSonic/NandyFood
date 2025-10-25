import 'dart:io';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:food_delivery_app/core/utils/app_logger.dart';

/// Service for handling image uploads to Supabase Storage
class ImageUploadService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) {
        return null;
      }

      return File(image.path);
    } catch (e) {
      AppLogger.error('Error picking image from gallery', error: e);
      rethrow;
    }
  }

  /// Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) {
        return null;
      }

      return File(image.path);
    } catch (e) {
      AppLogger.error('Error taking photo', error: e);
      rethrow;
    }
  }

  /// Pick multiple images (for reviews)
  Future<List<File>> pickMultipleImages({int maxImages = 5}) async {
    try {
      final List<XFile> images = await _picker.pickMultipleMedia(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isEmpty) {
        return [];
      }

      // Limit number of images
      final selectedImages = images.take(maxImages).toList();
      
      return selectedImages.map((xfile) => File(xfile.path)).toList();
    } catch (e) {
      AppLogger.error('Error picking multiple images', error: e);
      rethrow;
    }
  }

  /// Upload user avatar to Supabase Storage
  Future<String> uploadAvatar(File imageFile, String userId) async {
    try {
      AppLogger.info('Uploading avatar for user: $userId');

      final fileExt = path.extension(imageFile.path);
      final fileName = '$userId${DateTime.now().millisecondsSinceEpoch}$fileExt';
      final filePath = 'avatars/$fileName';

      // Upload to Supabase Storage
      final String fullPath = await _supabase.storage
          .from('user-avatars')
          .upload(filePath, imageFile);

      // Get public URL
      final String publicUrl = _supabase.storage
          .from('user-avatars')
          .getPublicUrl(filePath);

      AppLogger.success('Avatar uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      AppLogger.error('Error uploading avatar', error: e);
      rethrow;
    }
  }

  /// Upload review photo to Supabase Storage
  Future<String> uploadReviewPhoto(File imageFile, String reviewId) async {
    try {
      AppLogger.info('Uploading review photo for review: $reviewId');

      final fileExt = path.extension(imageFile.path);
      final fileName = '$reviewId-${DateTime.now().millisecondsSinceEpoch}$fileExt';
      final filePath = 'reviews/$fileName';

      // Upload to Supabase Storage
      final String fullPath = await _supabase.storage
          .from('review-photos')
          .upload(filePath, imageFile);

      // Get public URL
      final String publicUrl = _supabase.storage
          .from('review-photos')
          .getPublicUrl(filePath);

      AppLogger.success('Review photo uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      AppLogger.error('Error uploading review photo', error: e);
      rethrow;
    }
  }

  /// Upload menu item image to Supabase Storage
  Future<String> uploadMenuItemImage(File imageFile, String menuItemId) async {
    try {
      AppLogger.info('Uploading menu item image for: $menuItemId');

      final fileExt = path.extension(imageFile.path);
      final fileName = '$menuItemId-${DateTime.now().millisecondsSinceEpoch}$fileExt';
      final filePath = 'menu-items/$fileName';

      // Upload to Supabase Storage
      final String fullPath = await _supabase.storage
          .from('menu-items')
          .upload(filePath, imageFile);

      // Get public URL
      final String publicUrl = _supabase.storage
          .from('menu-items')
          .getPublicUrl(filePath);

      AppLogger.success('Menu item image uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      AppLogger.error('Error uploading menu item image', error: e);
      rethrow;
    }
  }

  /// Upload restaurant image to Supabase Storage
  Future<String> uploadRestaurantImage(File imageFile, String restaurantId) async {
    try {
      AppLogger.info('Uploading restaurant image for: $restaurantId');

      final fileExt = path.extension(imageFile.path);
      final fileName = '$restaurantId-${DateTime.now().millisecondsSinceEpoch}$fileExt';
      final filePath = 'restaurants/$fileName';

      // Upload to Supabase Storage
      final String fullPath = await _supabase.storage
          .from('restaurant-images')
          .upload(filePath, imageFile);

      // Get public URL
      final String publicUrl = _supabase.storage
          .from('restaurant-images')
          .getPublicUrl(filePath);

      AppLogger.success('Restaurant image uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      AppLogger.error('Error uploading restaurant image', error: e);
      rethrow;
    }
  }

  /// Delete image from Supabase Storage
  Future<void> deleteImage(String bucketName, String filePath) async {
    try {
      await _supabase.storage.from(bucketName).remove([filePath]);
      AppLogger.success('Image deleted successfully: $filePath');
    } catch (e) {
      AppLogger.error('Error deleting image', error: e);
      rethrow;
    }
  }

  /// Delete old avatar when uploading new one
  Future<void> deleteOldAvatar(String oldAvatarUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(oldAvatarUrl);
      final segments = uri.pathSegments;
      
      if (segments.length >= 3 && segments[segments.length - 3] == 'user-avatars') {
        final filePath = 'avatars/${segments.last}';
        await deleteImage('user-avatars', filePath);
      }
    } catch (e) {
      AppLogger.warning('Could not delete old avatar', error: e);
      // Don't throw - it's not critical if old avatar deletion fails
    }
  }

  /// Show image picker dialog (camera or gallery)
  Future<File?> showImageSourceDialog({
    required BuildContext context,
  }) async {
    return await showModalBottomSheet<File>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final file = await pickImageFromGallery();
                if (context.mounted && file != null) {
                  Navigator.pop(context, file);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a Photo'),
              onTap: () async {
                Navigator.pop(context);
                final file = await pickImageFromCamera();
                if (context.mounted && file != null) {
                  Navigator.pop(context, file);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
