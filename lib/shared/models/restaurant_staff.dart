import 'package:json_annotation/json_annotation.dart';
import 'package:food_delivery_app/shared/models/user_profile.dart';

part 'restaurant_staff.g.dart';

/// Enum for staff role types within a restaurant
enum StaffRoleType {
  @JsonValue('manager')
  manager,
  @JsonValue('chef')
  chef,
  @JsonValue('cashier')
  cashier,
  @JsonValue('server')
  server,
  @JsonValue('delivery_coordinator')
  deliveryCoordinator,
  @JsonValue('basic_staff')
  basicStaff,
}

/// Enum for staff status
enum StaffStatus {
  @JsonValue('active')
  active,
  @JsonValue('on_leave')
  onLeave,
  @JsonValue('suspended')
  suspended,
  @JsonValue('terminated')
  terminated,
  @JsonValue('pending')
  pending,
}

/// Enum for employment type
enum EmploymentType {
  @JsonValue('full-time')
  fullTime,
  @JsonValue('part-time')
  partTime,
  @JsonValue('contractor')
  contractor,
}

/// Class to define staff permissions
class StaffPermissions {
  final bool viewOrders;
  final bool updateOrders;
  final bool viewMenu;
  final bool updateMenu;
  final bool manageStaff;
  final bool viewAnalytics;
  final bool manageSettings;
  final bool processPayments;
  final bool viewReports;

  const StaffPermissions({
    this.viewOrders = true,
    this.updateOrders = false,
    this.viewMenu = true,
    this.updateMenu = false,
    this.manageStaff = false,
    this.viewAnalytics = false,
    this.manageSettings = false,
    this.processPayments = false,
    this.viewReports = false,
  });

  factory StaffPermissions.fromJson(Map<String, dynamic> json) {
    return StaffPermissions(
      viewOrders: json['view_orders'] as bool? ?? true,
      updateOrders: json['update_orders'] as bool? ?? false,
      viewMenu: json['view_menu'] as bool? ?? true,
      updateMenu: json['update_menu'] as bool? ?? false,
      manageStaff: json['manage_staff'] as bool? ?? false,
      viewAnalytics: json['view_analytics'] as bool? ?? false,
      manageSettings: json['manage_settings'] as bool? ?? false,
      processPayments: json['process_payments'] as bool? ?? false,
      viewReports: json['view_reports'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'view_orders': viewOrders,
      'update_orders': updateOrders,
      'view_menu': viewMenu,
      'update_menu': updateMenu,
      'manage_staff': manageStaff,
      'view_analytics': viewAnalytics,
      'manage_settings': manageSettings,
      'process_payments': processPayments,
      'view_reports': viewReports,
    };
  }

  /// Create a copy with updated permissions
  StaffPermissions copyWith({
    bool? viewOrders,
    bool? updateOrders,
    bool? viewMenu,
    bool? updateMenu,
    bool? manageStaff,
    bool? viewAnalytics,
    bool? manageSettings,
    bool? processPayments,
    bool? viewReports,
  }) {
    return StaffPermissions(
      viewOrders: viewOrders ?? this.viewOrders,
      updateOrders: updateOrders ?? this.updateOrders,
      viewMenu: viewMenu ?? this.viewMenu,
      updateMenu: updateMenu ?? this.updateMenu,
      manageStaff: manageStaff ?? this.manageStaff,
      viewAnalytics: viewAnalytics ?? this.viewAnalytics,
      manageSettings: manageSettings ?? this.manageSettings,
      processPayments: processPayments ?? this.processPayments,
      viewReports: viewReports ?? this.viewReports,
    );
  }

  /// Get default permissions for a specific role
  factory StaffPermissions.forRole(StaffRoleType role) {
    switch (role) {
      case StaffRoleType.manager:
        return const StaffPermissions(
          viewOrders: true,
          updateOrders: true,
          viewMenu: true,
          updateMenu: true,
          manageStaff: true,
          viewAnalytics: true,
          manageSettings: false, // Only owners can manage restaurant settings
          processPayments: true,
          viewReports: true,
        );
      case StaffRoleType.chef:
        return const StaffPermissions(
          viewOrders: true,
          updateOrders: true, // Can update order status to preparing/ready
          viewMenu: true,
          updateMenu: false,
          manageStaff: false,
          viewAnalytics: false,
          manageSettings: false,
          processPayments: false,
          viewReports: false,
        );
      case StaffRoleType.cashier:
        return const StaffPermissions(
          viewOrders: true,
          updateOrders: true,
          viewMenu: true,
          updateMenu: false,
          manageStaff: false,
          viewAnalytics: false,
          manageSettings: false,
          processPayments: true,
          viewReports: false,
        );
      case StaffRoleType.server:
        return const StaffPermissions(
          viewOrders: true,
          updateOrders: false,
          viewMenu: true,
          updateMenu: false,
          manageStaff: false,
          viewAnalytics: false,
          manageSettings: false,
          processPayments: false,
          viewReports: false,
        );
      case StaffRoleType.deliveryCoordinator:
        return const StaffPermissions(
          viewOrders: true,
          updateOrders: true,
          viewMenu: false,
          updateMenu: false,
          manageStaff: false,
          viewAnalytics: false,
          manageSettings: false,
          processPayments: false,
          viewReports: false,
        );
      case StaffRoleType.basicStaff:
        return const StaffPermissions(
          viewOrders: true,
          updateOrders: false,
          viewMenu: true,
          updateMenu: false,
          manageStaff: false,
          viewAnalytics: false,
          manageSettings: false,
          processPayments: false,
          viewReports: false,
        );
    }
  }
}

@JsonSerializable()
class RestaurantStaff {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'restaurant_id')
  final String restaurantId;
  final StaffRoleType role;
  final StaffPermissions permissions;
  @JsonKey(name: 'employment_type')
  final EmploymentType employmentType;
  final StaffStatus status;
  @JsonKey(name: 'hired_date')
  final DateTime hiredDate;
  @JsonKey(name: 'termination_date')
  final DateTime? terminationDate;
  @JsonKey(name: 'hourly_rate')
  final double? hourlyRate;
  final String? notes;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  // Joined user profile data
  final UserProfile? userProfile;

  RestaurantStaff({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.role,
    required this.permissions,
    required this.employmentType,
    required this.status,
    required this.hiredDate,
    this.terminationDate,
    this.hourlyRate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.userProfile,
  });

  factory RestaurantStaff.fromJson(Map<String, dynamic> json) =>
      _$RestaurantStaffFromJson(json);

  Map<String, dynamic> toJson() => _$RestaurantStaffToJson(this);

  RestaurantStaff copyWith({
    String? id,
    String? userId,
    String? restaurantId,
    StaffRoleType? role,
    StaffPermissions? permissions,
    EmploymentType? employmentType,
    StaffStatus? status,
    DateTime? hiredDate,
    DateTime? terminationDate,
    double? hourlyRate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserProfile? userProfile,
  }) {
    return RestaurantStaff(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      restaurantId: restaurantId ?? this.restaurantId,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      employmentType: employmentType ?? this.employmentType,
      status: status ?? this.status,
      hiredDate: hiredDate ?? this.hiredDate,
      terminationDate: terminationDate ?? this.terminationDate,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userProfile: userProfile ?? this.userProfile,
    );
  }

  /// Helper getters
  bool get isActive => status == StaffStatus.active;
  bool get isManager => role == StaffRoleType.manager;
  bool get canManageStaff => permissions.manageStaff;
  bool get canViewAnalytics => permissions.viewAnalytics;
  bool get canUpdateMenu => permissions.updateMenu;
  bool get canProcessPayments => permissions.processPayments;

  /// Get display name for role
  String get roleDisplayName {
    switch (role) {
      case StaffRoleType.manager:
        return 'Manager';
      case StaffRoleType.chef:
        return 'Chef';
      case StaffRoleType.cashier:
        return 'Cashier';
      case StaffRoleType.server:
        return 'Server';
      case StaffRoleType.deliveryCoordinator:
        return 'Delivery Coordinator';
      case StaffRoleType.basicStaff:
        return 'Staff';
    }
  }

  /// Get display name for status
  String get statusDisplayName {
    switch (status) {
      case StaffStatus.active:
        return 'Active';
      case StaffStatus.onLeave:
        return 'On Leave';
      case StaffStatus.suspended:
        return 'Suspended';
      case StaffStatus.terminated:
        return 'Terminated';
      case StaffStatus.pending:
        return 'Pending';
    }
  }

  /// Get display name for employment type
  String get employmentTypeDisplayName {
    switch (employmentType) {
      case EmploymentType.fullTime:
        return 'Full Time';
      case EmploymentType.partTime:
        return 'Part Time';
      case EmploymentType.contractor:
        return 'Contractor';
    }
  }

  /// Get color for status
  String getStatusColor() {
    switch (status) {
      case StaffStatus.active:
        return '#4CAF50'; // Green
      case StaffStatus.onLeave:
        return '#FF9800'; // Orange
      case StaffStatus.suspended:
        return '#F44336'; // Red
      case StaffStatus.terminated:
        return '#9E9E9E'; // Grey
      case StaffStatus.pending:
        return '#2196F3'; // Blue
    }
  }

  /// Check if staff member has specific permission
  bool hasPermission(String permission) {
    switch (permission) {
      case 'view_orders':
        return permissions.viewOrders;
      case 'update_orders':
        return permissions.updateOrders;
      case 'view_menu':
        return permissions.viewMenu;
      case 'update_menu':
        return permissions.updateMenu;
      case 'manage_staff':
        return permissions.manageStaff;
      case 'view_analytics':
        return permissions.viewAnalytics;
      case 'manage_settings':
        return permissions.manageSettings;
      case 'process_payments':
        return permissions.processPayments;
      case 'view_reports':
        return permissions.viewReports;
      default:
        return false;
    }
  }
}

/// Model for creating a new staff member
class CreateStaffRequest {
  final String email;
  final String fullName;
  final String? phoneNumber;
  final StaffRoleType role;
  final EmploymentType employmentType;
  final StaffPermissions permissions;
  final double? hourlyRate;
  final String? notes;

  CreateStaffRequest({
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.role,
    required this.employmentType,
    StaffPermissions? permissions,
    this.hourlyRate,
    this.notes,
  }) : permissions = permissions ?? StaffPermissions.forRole(role);

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'role': role.name,
      'employment_type': employmentType.name,
      'permissions': permissions.toJson(),
      'hourly_rate': hourlyRate,
      'notes': notes,
    };
  }
}

/// Model for updating staff member
class UpdateStaffRequest {
  final StaffRoleType? role;
  final StaffPermissions? permissions;
  final EmploymentType? employmentType;
  final StaffStatus? status;
  final double? hourlyRate;
  final String? notes;

  UpdateStaffRequest({
    this.role,
    this.permissions,
    this.employmentType,
    this.status,
    this.hourlyRate,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      if (role != null) 'role': role!.name,
      if (permissions != null) 'permissions': permissions!.toJson(),
      if (employmentType != null) 'employment_type': employmentType!.name,
      if (status != null) 'status': status!.name,
      if (hourlyRate != null) 'hourly_rate': hourlyRate,
      if (notes != null) 'notes': notes,
    };
  }
}