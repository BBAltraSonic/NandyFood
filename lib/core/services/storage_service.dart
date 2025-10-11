import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:food_delivery_app/core/services/database_service.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SupabaseClient _client;

  Future<void> initialize() async {
    _client = DatabaseService().client;
  }

  // Upload a file to a bucket
  Future<String> uploadFile({
    required String bucketName,
    required String filePath,
    required String fileName,
    required dynamic fileData,
  }) async {
    final fullPath = '$filePath/$fileName';
    await _client.storage.from(bucketName).upload(fullPath, fileData);
    return fullPath;
  }

  // Download a file from a bucket
  Future<Uint8List> downloadFile({
    required String bucketName,
    required String filePath,
  }) async {
    final response = await _client.storage.from(bucketName).download(filePath);
    return response;
  }

  // Get public URL for a file
  Future<String> getFileUrl({
    required String bucketName,
    required String filePath,
  }) async {
    final response = await _client.storage
        .from(bucketName)
        .getPublicUrl(filePath);
    return response;
  }

  // List files in a path
  Future<List<Map<String, dynamic>>> listFiles({
    required String bucketName,
    required String path,
  }) async {
    final files = await _client.storage.from(bucketName).list(path: path);
    return files
        .map(
          (file) => {
            'name': file.name,
            'id': file.id,
            'updated_at': file.updatedAt,
            'created_at': file.createdAt,
            'last_accessed_at': file.lastAccessedAt,
            'metadata': file.metadata,
          },
        )
        .toList();
  }

  // Delete a file
  Future<void> deleteFile({
    required String bucketName,
    required String filePath,
  }) async {
    await _client.storage.from(bucketName).remove([filePath]);
  }

  // Create a signed URL for a file (valid for a limited time)
  Future<String> createSignedUrl({
    required String bucketName,
    required String filePath,
    required int expiresIn,
  }) async {
    final signedUrl = await _client.storage
        .from(bucketName)
        .createSignedUrl(filePath, expiresIn);
    return signedUrl;
  }
}
