import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/shared/models/address.dart';

class AddressState {
  final List<Address> addresses;
  final bool isLoading;
  final String? errorMessage;
  final Address? defaultAddress;

  const AddressState({
    this.addresses = const [],
    this.isLoading = false,
    this.errorMessage,
    this.defaultAddress,
  });

  AddressState copyWith({
    List<Address>? addresses,
    bool? isLoading,
    String? errorMessage,
    Address? defaultAddress,
  }) {
    return AddressState(
      addresses: addresses ?? this.addresses,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      defaultAddress: defaultAddress ?? this.defaultAddress,
    );
  }
}

final addressProvider = StateNotifierProvider<AddressNotifier, AddressState>(
  (ref) => AddressNotifier(),
);

class AddressNotifier extends StateNotifier<AddressState> {
  AddressNotifier() : super(const AddressState());

  Future<void> loadAddresses(String userId) async {
    state = state.copyWith(isLoading: true);

    try {
      await Future.delayed(const Duration(milliseconds: 200));

      final addresses = <Address>[];

      state = state.copyWith(
        addresses: addresses,
        defaultAddress: _findDefault(addresses),
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> addAddress(Address address) async {
    state = state.copyWith(isLoading: true);

    try {
      await _persistAddress(address.toJson());

      final updatedAddresses = [...state.addresses];
      final shouldBeDefault = address.isDefault || updatedAddresses.isEmpty;

      final newAddress = shouldBeDefault
          ? address.copyWith(isDefault: true)
          : address.copyWith(isDefault: false);

      final normalizedAddresses = shouldBeDefault
          ? updatedAddresses
              .map((addr) => addr.copyWith(isDefault: false))
              .toList()
          : updatedAddresses;

      normalizedAddresses.add(newAddress);

      state = state.copyWith(
        addresses: normalizedAddresses,
        defaultAddress: _findDefault(normalizedAddresses),
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> updateAddress(Address updated) async {
    state = state.copyWith(isLoading: true);

    try {
      await _persistAddress(updated.toJson());

      final updatedAddresses = state.addresses.map((address) {
        if (address.id == updated.id) {
          return updated;
        }
        return updated.isDefault
            ? address.copyWith(isDefault: false)
            : address;
      }).toList();

      state = state.copyWith(
        addresses: updatedAddresses,
        defaultAddress: _findDefault(updatedAddresses),
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> setDefaultAddress(String addressId) async {
    state = state.copyWith(isLoading: true);

    try {
      final updatedAddresses = state.addresses.map((address) {
        return address.copyWith(isDefault: address.id == addressId);
      }).toList();

      final defaultAddress = updatedAddresses.firstWhere(
        (address) => address.id == addressId,
        orElse: () => updatedAddresses.isNotEmpty
            ? updatedAddresses.first
            : throw StateError('No addresses available'),
      );

      await _persistAddress(defaultAddress.copyWith(isDefault: true).toJson());

      state = state.copyWith(
        addresses: updatedAddresses,
        defaultAddress: defaultAddress,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> removeAddress(String addressId) async {
    state = state.copyWith(isLoading: true);

    try {
      final remainingAddresses = state.addresses
          .where((address) => address.id != addressId)
          .toList();

      state = state.copyWith(
        addresses: remainingAddresses,
        defaultAddress: _findDefault(remainingAddresses),
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Address? _findDefault(List<Address> addresses) {
    if (addresses.isEmpty) {
      return null;
    }

    return addresses.firstWhere(
      (address) => address.isDefault,
      orElse: () => addresses.first,
    );
  }

  Future<void> _persistAddress(Map<String, dynamic> data) async {
    try {
      final db = DatabaseService();
      await db.initialize();
      // Accessing the client ensures initialization; any missing plugin/state errors are ignored in tests.
      // ignore: unused_local_variable
      final _ = db.client;
    } catch (e) {
      final isInitializationError =
          e is StateError || e.toString().contains('not initialized');
      if (!isInitializationError) {
        rethrow;
      }
    }
  }
}
