import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:food_delivery_app/shared/models/restaurant_staff.dart';
import 'package:food_delivery_app/shared/models/user_profile.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';

/// Service for managing restaurant staff members
class StaffService {
  final SupabaseClient _supabase;

  StaffService() : _supabase = Supabase.instance.client;

  /// Get all staff members for a restaurant
  Future<List<RestaurantStaff>> getRestaurantStaff(String restaurantId) async {
    try {
      AppLogger.info('Fetching staff for restaurant: $restaurantId');

      final response = await _supabase
          .rpc('get_restaurant_staff_with_profiles', params: {
            'restaurant_id_param': restaurantId,
          });

      final data = response as List<dynamic>;

      final staffList = data.map((staffData) {
        // Create user profile if available
        UserProfile? userProfile;
        if (staffData['email'] != null) {
          userProfile = UserProfile(
            id: staffData['user_id'] as String,
            email: staffData['email'] as String,
            fullName: staffData['full_name'] as String?,
            phoneNumber: staffData['phone_number'] as String?,
            avatarUrl: staffData['avatar_url'] as String?,
            createdAt: DateTime.now(), // We don't have this from the join
            updatedAt: DateTime.now(), // We don't have this from the join
          );
        }

        return RestaurantStaff(
          id: staffData['id'] as String,
          userId: staffData['user_id'] as String,
          restaurantId: staffData['restaurant_id'] as String,
          role: StaffRoleType.values.firstWhere(
            (e) => e.name == staffData['role'],
            orElse: () => StaffRoleType.basicStaff,
          ),
          permissions: StaffPermissions.fromJson(
            staffData['permissions'] as Map<String, dynamic>,
          ),
          employmentType: EmploymentType.values.firstWhere(
            (e) => e.name == staffData['employment_type']?.replaceAll('-', '_'),
            orElse: () => EmploymentType.fullTime,
          ),
          status: StaffStatus.values.firstWhere(
            (e) => e.name == staffData['status'],
            orElse: () => StaffStatus.active,
          ),
          hiredDate: DateTime.parse(staffData['hired_date'] as String),
          terminationDate: staffData['termination_date'] != null
              ? DateTime.parse(staffData['termination_date'] as String)
              : null,
          hourlyRate: staffData['hourly_rate'] as double?,
          notes: staffData['notes'] as String?,
          createdAt: DateTime.parse(staffData['created_at'] as String),
          updatedAt: DateTime.parse(staffData['updated_at'] as String),
          userProfile: userProfile,
        );
      }).toList();

      AppLogger.success('Successfully fetched ${staffList.length} staff members');
      return staffList;
    } catch (e) {
      AppLogger.error('Failed to fetch restaurant staff: $e');
      throw Exception('Failed to fetch restaurant staff: ${e.toString()}');
    }
  }

  /// Get staff member by ID
  Future<RestaurantStaff?> getStaffById(String staffId) async {
    try {
      AppLogger.info('Fetching staff member: $staffId');

      final response = await _supabase
          .from('restaurant_staff')
          .select('''
            *,
            user_profiles!inner(
              id,
              email,
              full_name,
              phone_number,
              avatar_url,
              created_at,
              updated_at
            )
          ''')
          .eq('id', staffId)
          .single();

      final staffData = response as Map<String, dynamic>;

      // Extract user profile data
      final userProfileData = staffData['user_profiles'] as Map<String, dynamic>;
      final userProfile = UserProfile(
        id: userProfileData['id'] as String,
        email: userProfileData['email'] as String,
        fullName: userProfileData['full_name'] as String?,
        phoneNumber: userProfileData['phone_number'] as String?,
        avatarUrl: userProfileData['avatar_url'] as String?,
        createdAt: DateTime.parse(userProfileData['created_at'] as String),
        updatedAt: DateTime.parse(userProfileData['updated_at'] as String),
      );

      final staff = RestaurantStaff(
        id: staffData['id'] as String,
        userId: staffData['user_id'] as String,
        restaurantId: staffData['restaurant_id'] as String,
        role: StaffRoleType.values.firstWhere(
          (e) => e.name == staffData['role'],
          orElse: () => StaffRoleType.basicStaff,
        ),
        permissions: StaffPermissions.fromJson(
          staffData['permissions'] as Map<String, dynamic>,
        ),
        employmentType: EmploymentType.values.firstWhere(
          (e) => e.name == staffData['employment_type']?.replaceAll('-', '_'),
          orElse: () => EmploymentType.fullTime,
        ),
        status: StaffStatus.values.firstWhere(
          (e) => e.name == staffData['status'],
          orElse: () => StaffStatus.active,
        ),
        hiredDate: DateTime.parse(staffData['hired_date'] as String),
        terminationDate: staffData['termination_date'] != null
            ? DateTime.parse(staffData['termination_date'] as String)
            : null,
        hourlyRate: staffData['hourly_rate'] as double?,
        notes: staffData['notes'] as String?,
        createdAt: DateTime.parse(staffData['created_at'] as String),
        updatedAt: DateTime.parse(staffData['updated_at'] as String),
        userProfile: userProfile,
      );

      AppLogger.success('Successfully fetched staff member: $staffId');
      return staff;
    } catch (e) {
      AppLogger.error('Failed to fetch staff member: $e');
      throw Exception('Failed to fetch staff member: ${e.toString()}');
    }
  }

  /// Create a new staff member
  Future<RestaurantStaff> createStaffMember(
    String restaurantId,
    CreateStaffRequest request,
  ) async {
    try {
      AppLogger.info('Creating staff member: ${request.email} for restaurant: $restaurantId');

      // First, try to find existing user or create a new one
      String userId;

      try {
        // Try to find existing user by email
        final existingUsers = await _supabase
            .from('user_profiles')
            .select('id')
            .eq('email', request.email)
            .maybeSingle();

        if (existingUsers != null) {
          userId = existingUsers['id'] as String;
          AppLogger.info('Found existing user: $userId');
        } else {
          // Create new user profile (note: this would typically require user registration)
          // For now, we'll throw an error requiring the user to exist
          throw Exception('User with email ${request.email} does not exist. Please ask them to register first.');
        }
      } catch (e) {
        if (e.toString().contains('does not exist')) {
          throw e; // Re-throw the user not found error
        }
        throw Exception('Failed to check for existing user: ${e.toString()}');
      }

      // Check if user is already staff at this restaurant
      final existingStaff = await _supabase
          .from('restaurant_staff')
          .select('id')
          .eq('user_id', userId)
          .eq('restaurant_id', restaurantId)
          .maybeSingle();

      if (existingStaff != null) {
        throw Exception('User is already a staff member at this restaurant.');
      }

      // Create staff member record
      final staffData = {
        'user_id': userId,
        'restaurant_id': restaurantId,
        'role': request.role.name,
        'permissions': request.permissions.toJson(),
        'employment_type': request.employmentType.name,
        'hourly_rate': request.hourlyRate,
        'notes': request.notes,
      };

      final response = await _supabase
          .from('restaurant_staff')
          .insert(staffData)
          .select()
          .single();

      final createdStaff = RestaurantStaff(
        id: response['id'] as String,
        userId: response['user_id'] as String,
        restaurantId: response['restaurant_id'] as String,
        role: StaffRoleType.values.firstWhere(
          (e) => e.name == response['role'],
          orElse: () => StaffRoleType.basicStaff,
        ),
        permissions: StaffPermissions.fromJson(
          response['permissions'] as Map<String, dynamic>,
        ),
        employmentType: EmploymentType.values.firstWhere(
          (e) => e.name == response['employment_type']?.replaceAll('-', '_'),
          orElse: () => EmploymentType.fullTime,
        ),
        status: StaffStatus.active,
        hiredDate: DateTime.parse(response['hired_date'] as String),
        terminationDate: response['termination_date'] != null
            ? DateTime.parse(response['termination_date'] as String)
            : null,
        hourlyRate: response['hourly_rate'] as double?,
        notes: response['notes'] as String?,
        createdAt: DateTime.parse(response['created_at'] as String),
        updatedAt: DateTime.parse(response['updated_at'] as String),
      );

      // Assign restaurant_staff role to user if not already assigned
      try {
        await _supabase
            .from('user_roles')
            .upsert({
              'user_id': userId,
              'role': 'restaurant_staff',
              'is_primary': false,
            }, onConflict: 'user_id,role');
      } catch (e) {
        AppLogger.warning('Failed to assign staff role to user: $e');
        // Don't throw error here as staff record was created successfully
      }

      AppLogger.success('Successfully created staff member: ${createdStaff.id}');
      return createdStaff;
    } catch (e) {
      AppLogger.error('Failed to create staff member: $e');
      throw Exception('Failed to create staff member: ${e.toString()}');
    }
  }

  /// Update staff member
  Future<RestaurantStaff> updateStaffMember(
    String staffId,
    UpdateStaffRequest request,
  ) async {
    try {
      AppLogger.info('Updating staff member: $staffId');

      final updateData = request.toJson();

      final response = await _supabase
          .from('restaurant_staff')
          .update(updateData)
          .eq('id', staffId)
          .select()
          .single();

      // Fetch the updated staff with user profile
      final updatedStaff = await getStaffById(staffId);
      if (updatedStaff == null) {
        throw Exception('Failed to fetch updated staff member');
      }

      AppLogger.success('Successfully updated staff member: $staffId');
      return updatedStaff;
    } catch (e) {
      AppLogger.error('Failed to update staff member: $e');
      throw Exception('Failed to update staff member: ${e.toString()}');
    }
  }

  /// Update staff status
  Future<bool> updateStaffStatus(String staffId, StaffStatus status) async {
    try {
      AppLogger.info('Updating staff status: $staffId to $status');

      final updateData = {
        'status': status.name,
        if (status == StaffStatus.terminated)
          'termination_date': DateTime.now().toIso8601String().split('T')[0],
      };

      await _supabase
          .from('restaurant_staff')
          .update(updateData)
          .eq('id', staffId);

      AppLogger.success('Successfully updated staff status: $staffId');
      return true;
    } catch (e) {
      AppLogger.error('Failed to update staff status: $e');
      throw Exception('Failed to update staff status: ${e.toString()}');
    }
  }

  /// Remove staff member (soft delete by updating status to terminated)
  Future<bool> removeStaffMember(String staffId, {String? reason}) async {
    try {
      AppLogger.info('Removing staff member: $staffId');

      final updateData = {
        'status': 'terminated',
        'termination_date': DateTime.now().toIso8601String().split('T')[0],
        if (reason != null) 'notes': reason,
      };

      await _supabase
          .from('restaurant_staff')
          .update(updateData)
          .eq('id', staffId);

      AppLogger.success('Successfully removed staff member: $staffId');
      return true;
    } catch (e) {
      AppLogger.error('Failed to remove staff member: $e');
      throw Exception('Failed to remove staff member: ${e.toString()}');
    }
  }

  /// Check if user has specific permission in restaurant
  Future<bool> hasPermission(
    String userId,
    String restaurantId,
    String permission,
  ) async {
    try {
      final response = await _supabase
          .rpc('has_staff_permission', params: {
            'user_id_param': userId,
            'restaurant_id_param': restaurantId,
            'permission_param': permission,
          });

      return response as bool? ?? false;
    } catch (e) {
      AppLogger.error('Failed to check permission: $e');
      return false;
    }
  }

  /// Get current user's staff record for a restaurant
  Future<RestaurantStaff?> getCurrentUserStaff(String restaurantId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return null;
      }

      final response = await _supabase
          .from('restaurant_staff')
          .select('''
            *,
            user_profiles!inner(
              id,
              email,
              full_name,
              phone_number,
              avatar_url,
              created_at,
              updated_at
            )
          ''')
          .eq('user_id', userId)
          .eq('restaurant_id', restaurantId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      final staffData = response as Map<String, dynamic>;

      // Extract user profile data
      final userProfileData = staffData['user_profiles'] as Map<String, dynamic>;
      final userProfile = UserProfile(
        id: userProfileData['id'] as String,
        email: userProfileData['email'] as String,
        fullName: userProfileData['full_name'] as String?,
        phoneNumber: userProfileData['phone_number'] as String?,
        avatarUrl: userProfileData['avatar_url'] as String?,
        createdAt: DateTime.parse(userProfileData['created_at'] as String),
        updatedAt: DateTime.parse(userProfileData['updated_at'] as String),
      );

      return RestaurantStaff(
        id: staffData['id'] as String,
        userId: staffData['user_id'] as String,
        restaurantId: staffData['restaurant_id'] as String,
        role: StaffRoleType.values.firstWhere(
          (e) => e.name == staffData['role'],
          orElse: () => StaffRoleType.basicStaff,
        ),
        permissions: StaffPermissions.fromJson(
          staffData['permissions'] as Map<String, dynamic>,
        ),
        employmentType: EmploymentType.values.firstWhere(
          (e) => e.name == staffData['employment_type']?.replaceAll('-', '_'),
          orElse: () => EmploymentType.fullTime,
        ),
        status: StaffStatus.values.firstWhere(
          (e) => e.name == staffData['status'],
          orElse: () => StaffStatus.active,
        ),
        hiredDate: DateTime.parse(staffData['hired_date'] as String),
        terminationDate: staffData['termination_date'] != null
            ? DateTime.parse(staffData['termination_date'] as String)
            : null,
        hourlyRate: staffData['hourly_rate'] as double?,
        notes: staffData['notes'] as String?,
        createdAt: DateTime.parse(staffData['created_at'] as String),
        updatedAt: DateTime.parse(staffData['updated_at'] as String),
        userProfile: userProfile,
      );
    } catch (e) {
      AppLogger.error('Failed to get current user staff: $e');
      return null;
    }
  }
}