import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_app/shared/models/restaurant_staff.dart';

void main() {
  group('RestaurantStaff', () {
    test('should create StaffPermissions with default values', () {
      const permissions = StaffPermissions();

      expect(permissions.viewOrders, true);
      expect(permissions.updateOrders, false);
      expect(permissions.viewMenu, true);
      expect(permissions.updateMenu, false);
      expect(permissions.manageStaff, false);
      expect(permissions.viewAnalytics, false);
      expect(permissions.manageSettings, false);
      expect(permissions.processPayments, false);
      expect(permissions.viewReports, false);
    });

    test('should create StaffPermissions for manager role', () {
      final permissions = StaffPermissions.forRole(StaffRoleType.manager);

      expect(permissions.viewOrders, true);
      expect(permissions.updateOrders, true);
      expect(permissions.viewMenu, true);
      expect(permissions.updateMenu, true);
      expect(permissions.manageStaff, true);
      expect(permissions.viewAnalytics, true);
      expect(permissions.manageSettings, false);
      expect(permissions.processPayments, true);
      expect(permissions.viewReports, true);
    });

    test('should create StaffPermissions for chef role', () {
      final permissions = StaffPermissions.forRole(StaffRoleType.chef);

      expect(permissions.viewOrders, true);
      expect(permissions.updateOrders, true);
      expect(permissions.viewMenu, true);
      expect(permissions.updateMenu, false);
      expect(permissions.manageStaff, false);
      expect(permissions.viewAnalytics, false);
      expect(permissions.manageSettings, false);
      expect(permissions.processPayments, false);
      expect(permissions.viewReports, false);
    });

    test('should create StaffPermissions for cashier role', () {
      final permissions = StaffPermissions.forRole(StaffRoleType.cashier);

      expect(permissions.viewOrders, true);
      expect(permissions.updateOrders, true);
      expect(permissions.viewMenu, true);
      expect(permissions.updateMenu, false);
      expect(permissions.manageStaff, false);
      expect(permissions.viewAnalytics, false);
      expect(permissions.manageSettings, false);
      expect(permissions.processPayments, true);
      expect(permissions.viewReports, false);
    });

    test('should copy StaffPermissions with updates', () {
      const permissions = StaffPermissions();
      final updated = permissions.copyWith(updateOrders: true);

      expect(updated.viewOrders, true);
      expect(updated.updateOrders, true);
      expect(updated.viewMenu, true);
      expect(updated.updateMenu, false);
    });

    test('should convert StaffPermissions to JSON and back', () {
      const permissions = StaffPermissions(
        viewOrders: true,
        updateOrders: true,
        viewMenu: false,
        updateMenu: false,
        manageStaff: true,
        viewAnalytics: false,
        manageSettings: false,
        processPayments: false,
        viewReports: true,
      );

      final json = permissions.toJson();
      final fromJson = StaffPermissions.fromJson(json);

      expect(fromJson.viewOrders, permissions.viewOrders);
      expect(fromJson.updateOrders, permissions.updateOrders);
      expect(fromJson.viewMenu, permissions.viewMenu);
      expect(fromJson.updateMenu, permissions.updateMenu);
      expect(fromJson.manageStaff, permissions.manageStaff);
      expect(fromJson.viewAnalytics, permissions.viewAnalytics);
      expect(fromJson.manageSettings, permissions.manageSettings);
      expect(fromJson.processPayments, permissions.processPayments);
      expect(fromJson.viewReports, permissions.viewReports);
    });

    test('should return correct role display name', () {
      final managerStaff = RestaurantStaff(
        id: '1',
        userId: 'user1',
        restaurantId: 'restaurant1',
        role: StaffRoleType.manager,
        permissions: const StaffPermissions(),
        employmentType: EmploymentType.fullTime,
        status: StaffStatus.active,
        hiredDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final chefStaff = managerStaff.copyWith(role: StaffRoleType.chef);
      final cashierStaff = managerStaff.copyWith(role: StaffRoleType.cashier);
      final serverStaff = managerStaff.copyWith(role: StaffRoleType.server);
      final deliveryStaff = managerStaff.copyWith(role: StaffRoleType.deliveryCoordinator);
      final basicStaff = managerStaff.copyWith(role: StaffRoleType.basicStaff);

      expect(managerStaff.roleDisplayName, 'Manager');
      expect(chefStaff.roleDisplayName, 'Chef');
      expect(cashierStaff.roleDisplayName, 'Cashier');
      expect(serverStaff.roleDisplayName, 'Server');
      expect(deliveryStaff.roleDisplayName, 'Delivery Coordinator');
      expect(basicStaff.roleDisplayName, 'Staff');
    });

    test('should return correct status display name', () {
      final activeStaff = RestaurantStaff(
        id: '1',
        userId: 'user1',
        restaurantId: 'restaurant1',
        role: StaffRoleType.basicStaff,
        permissions: const StaffPermissions(),
        employmentType: EmploymentType.fullTime,
        status: StaffStatus.active,
        hiredDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final onLeaveStaff = activeStaff.copyWith(status: StaffStatus.onLeave);
      final suspendedStaff = activeStaff.copyWith(status: StaffStatus.suspended);
      final terminatedStaff = activeStaff.copyWith(status: StaffStatus.terminated);
      final pendingStaff = activeStaff.copyWith(status: StaffStatus.pending);

      expect(activeStaff.statusDisplayName, 'Active');
      expect(onLeaveStaff.statusDisplayName, 'On Leave');
      expect(suspendedStaff.statusDisplayName, 'Suspended');
      expect(terminatedStaff.statusDisplayName, 'Terminated');
      expect(pendingStaff.statusDisplayName, 'Pending');
    });

    test('should return correct employment type display name', () {
      final fullTimeStaff = RestaurantStaff(
        id: '1',
        userId: 'user1',
        restaurantId: 'restaurant1',
        role: StaffRoleType.basicStaff,
        permissions: const StaffPermissions(),
        employmentType: EmploymentType.fullTime,
        status: StaffStatus.active,
        hiredDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final partTimeStaff = fullTimeStaff.copyWith(employmentType: EmploymentType.partTime);
      final contractorStaff = fullTimeStaff.copyWith(employmentType: EmploymentType.contractor);

      expect(fullTimeStaff.employmentTypeDisplayName, 'Full Time');
      expect(partTimeStaff.employmentTypeDisplayName, 'Part Time');
      expect(contractorStaff.employmentTypeDisplayName, 'Contractor');
    });

    test('should check staff member permissions', () {
      const permissions = StaffPermissions(
        viewOrders: true,
        updateOrders: false,
        manageStaff: true,
      );

      final staff = RestaurantStaff(
        id: '1',
        userId: 'user1',
        restaurantId: 'restaurant1',
        role: StaffRoleType.manager,
        permissions: permissions,
        employmentType: EmploymentType.fullTime,
        status: StaffStatus.active,
        hiredDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(staff.hasPermission('view_orders'), true);
      expect(staff.hasPermission('update_orders'), false);
      expect(staff.hasPermission('manage_staff'), true);
      expect(staff.hasPermission('nonexistent_permission'), false);
    });

    test('should check staff member status', () {
      final activeStaff = RestaurantStaff(
        id: '1',
        userId: 'user1',
        restaurantId: 'restaurant1',
        role: StaffRoleType.basicStaff,
        permissions: const StaffPermissions(),
        employmentType: EmploymentType.fullTime,
        status: StaffStatus.active,
        hiredDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final terminatedStaff = RestaurantStaff(
        id: '2',
        userId: 'user2',
        restaurantId: 'restaurant1',
        role: StaffRoleType.basicStaff,
        permissions: const StaffPermissions(),
        employmentType: EmploymentType.fullTime,
        status: StaffStatus.terminated,
        hiredDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(activeStaff.isActive, true);
      expect(activeStaff.isManager, false);
      expect(activeStaff.canManageStaff, false);

      expect(terminatedStaff.isActive, false);
      expect(terminatedStaff.isManager, false);
      expect(terminatedStaff.canManageStaff, false);
    });

    test('should get status color', () {
      final activeStaff = RestaurantStaff(
        id: '1',
        userId: 'user1',
        restaurantId: 'restaurant1',
        role: StaffRoleType.basicStaff,
        permissions: const StaffPermissions(),
        employmentType: EmploymentType.fullTime,
        status: StaffStatus.active,
        hiredDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(activeStaff.getStatusColor(), '#4CAF50'); // Green

      final suspendedStaff = activeStaff.copyWith(status: StaffStatus.suspended);
      expect(suspendedStaff.getStatusColor(), '#F44336'); // Red
    });

    test('should copy RestaurantStaff with updates', () {
      final original = RestaurantStaff(
        id: '1',
        userId: 'user1',
        restaurantId: 'restaurant1',
        role: StaffRoleType.basicStaff,
        permissions: const StaffPermissions(),
        employmentType: EmploymentType.fullTime,
        status: StaffStatus.active,
        hiredDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = original.copyWith(
        role: StaffRoleType.manager,
        status: StaffStatus.onLeave,
      );

      expect(updated.id, original.id);
      expect(updated.role, StaffRoleType.manager);
      expect(updated.status, StaffStatus.onLeave);
      expect(updated.userId, original.userId);
      expect(updated.restaurantId, original.restaurantId);
    });
  });

  group('CreateStaffRequest', () {
    test('should create CreateStaffRequest with default permissions', () {
      final request = CreateStaffRequest(
        email: 'test@example.com',
        fullName: 'Test User',
        role: StaffRoleType.chef,
        employmentType: EmploymentType.fullTime,
      );

      expect(request.email, 'test@example.com');
      expect(request.fullName, 'Test User');
      expect(request.role, StaffRoleType.chef);
      expect(request.employmentType, EmploymentType.fullTime);
      expect(request.permissions.updateOrders, true); // Chef can update orders
      expect(request.permissions.updateMenu, false); // Chef cannot update menu
    });

    test('should convert CreateStaffRequest to JSON', () {
      final request = CreateStaffRequest(
        email: 'test@example.com',
        fullName: 'Test User',
        phoneNumber: '+1234567890',
        role: StaffRoleType.cashier,
        employmentType: EmploymentType.partTime,
        hourlyRate: 15.50,
        notes: 'Test notes',
      );

      final json = request.toJson();

      expect(json['email'], 'test@example.com');
      expect(json['full_name'], 'Test User');
      expect(json['phone_number'], '+1234567890');
      expect(json['role'], 'cashier');
      expect(json['employment_type'], 'partTime');
      expect(json['hourly_rate'], 15.50);
      expect(json['notes'], 'Test notes');
      expect(json['permissions'], isNotNull);
    });
  });

  group('UpdateStaffRequest', () {
    test('should create UpdateStaffRequest with some fields', () {
      final request = UpdateStaffRequest(
        role: StaffRoleType.manager,
        status: StaffStatus.onLeave,
        hourlyRate: 20.00,
      );

      expect(request.role, StaffRoleType.manager);
      expect(request.status, StaffStatus.onLeave);
      expect(request.hourlyRate, 20.00);
      expect(request.employmentType, isNull);
      expect(request.notes, isNull);
    });

    test('should convert UpdateStaffRequest to JSON', () {
      final request = UpdateStaffRequest(
        role: StaffRoleType.chef,
        employmentType: EmploymentType.fullTime,
        hourlyRate: 18.75,
        notes: 'Updated notes',
      );

      final json = request.toJson();

      expect(json['role'], 'chef');
      expect(json['employment_type'], 'fullTime');
      expect(json['hourly_rate'], 18.75);
      expect(json['notes'], 'Updated notes');
      expect(json['status'], isNull); // Not provided
    });
  });
}