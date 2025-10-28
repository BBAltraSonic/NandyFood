import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/shared/models/address.dart';
import 'package:food_delivery_app/features/profile/data/repositories/address_repository.dart';

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
  final AddressRepository _repo;
  AddressNotifier({AddressRepository? repo})
      : _repo = repo ?? AddressRepository(),
        super(const AddressState());

  Future<void> loadAddresses(String userId) async {
    state = state.copyWith(isLoading: true);

    try {
      final addresses = await _repo.fetchAddresses(userId);

      state = state.copyWith(
        addresses: addresses,
        defaultAddress: _findDefault(addresses),
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> addAddress(Address address) async {
    state = state.copyWith(isLoading: true);

    try {
      final created = await _repo.createAddress(
        userId: address.userId,
        type: address.type,
        street: address.street,
        city: address.city,
        state: address.state,
        zipCode: address.zipCode,
        country: address.country,
        apartment: address.apartment,
        deliveryInstructions: address.deliveryInstructions,
        isDefault: address.isDefault || state.addresses.isEmpty,
        latitude: address.latitude,
        longitude: address.longitude,
      );

      final updatedAddresses = state.addresses
          .map((a) => created.isDefault ? a.copyWith(isDefault: false) : a)
          .toList();
      updatedAddresses.add(created);

      state = state.copyWith(
        addresses: updatedAddresses,
        defaultAddress: _findDefault(updatedAddresses),
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> updateAddress(Address updated) async {
    state = state.copyWith(isLoading: true);

    try {
      final saved = await _repo.updateAddress(
        id: updated.id,
        userId: updated.userId,
        type: updated.type,
        street: updated.street,
        city: updated.city,
        state: updated.state,
        zipCode: updated.zipCode,
        country: updated.country,
        apartment: updated.apartment,
        deliveryInstructions: updated.deliveryInstructions,
        isDefault: updated.isDefault,
        latitude: updated.latitude,
        longitude: updated.longitude,
      );

      final updatedAddresses = state.addresses.map((address) {
        if (address.id == saved.id) {
          return saved;
        }
        return saved.isDefault ? address.copyWith(isDefault: false) : address;
      }).toList();

      state = state.copyWith(
        addresses: updatedAddresses,
        defaultAddress: _findDefault(updatedAddresses),
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> setDefaultAddress(String addressId) async {
    state = state.copyWith(isLoading: true);

    try {
      // Derive userId from current addresses list
      final target = state.addresses.firstWhere(
        (a) => a.id == addressId,
        orElse: () => state.addresses.first,
      );
      final userId = target.userId;

      await _repo.setDefaultAddress(userId, addressId);

      final updatedAddresses = state.addresses.map((address) {
        return address.copyWith(isDefault: address.id == addressId);
      }).toList();

      final defaultAddress = updatedAddresses.firstWhere(
        (address) => address.id == addressId,
        orElse: () => updatedAddresses.isNotEmpty
            ? updatedAddresses.first
            : throw StateError('No addresses available'),
      );

      state = state.copyWith(
        addresses: updatedAddresses,
        defaultAddress: defaultAddress,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> removeAddress(String addressId) async {
    state = state.copyWith(isLoading: true);

    try {
      await _repo.deleteAddress(addressId);

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
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
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


}
