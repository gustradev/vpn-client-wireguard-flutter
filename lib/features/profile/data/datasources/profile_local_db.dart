import 'package:hive/hive.dart';
import 'package:vpn_client_wireguard_flutter/core/result.dart';
import 'package:vpn_client_wireguard_flutter/features/profile/domain/entities/profile.dart';

/// Adapter Hive buat entity Profile.
class ProfileAdapter extends TypeAdapter<Profile> {
  @override
  final int typeId = 0;

  @override
  Profile read(BinaryReader reader) {
    return Profile(
      id: reader.readString(),
      name: reader.readString(),
      interfaceName: reader.readString(),
      privateKey: reader.readString(),
      publicKey: reader.readString(),
      listenPort: reader.readBool() ? reader.readInt() : null,
      mtu: reader.readBool() ? reader.readInt() : null,
      dns: reader.readStringList(),
      peers: reader.readList().cast<Peer>(),
      isActive: reader.readBool(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      notes: reader.readBool() ? reader.readString() : null,
    );
  }

  @override
  void write(BinaryWriter writer, Profile obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.interfaceName);
    writer.writeString(obj.privateKey);
    writer.writeString(obj.publicKey);
    writer.writeBool(obj.listenPort != null);
    if (obj.listenPort != null) writer.writeInt(obj.listenPort!);
    writer.writeBool(obj.mtu != null);
    if (obj.mtu != null) writer.writeInt(obj.mtu!);
    writer.writeStringList(obj.dns);
    writer.writeList(obj.peers);
    writer.writeBool(obj.isActive);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.updatedAt.millisecondsSinceEpoch);
    writer.writeBool(obj.notes != null);
    if (obj.notes != null) writer.writeString(obj.notes!);
  }
}

/// Adapter Hive buat entity Peer.
class PeerAdapter extends TypeAdapter<Peer> {
  @override
  final int typeId = 1;

  @override
  Peer read(BinaryReader reader) {
    return Peer(
      id: reader.readString(),
      name: reader.readString(),
      publicKey: reader.readString(),
      presharedKey: reader.readBool() ? reader.readString() : null,
      endpoint: reader.readBool() ? reader.readString() : null,
      allowedIps: reader.readStringList(),
      persistentKeepalive: reader.readBool() ? reader.readInt() : null,
      isConnected: reader.readBool(),
      lastHandshake: reader.readBool()
          ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
          : null,
      rxBytes: reader.readBool() ? reader.readInt() : null,
      txBytes: reader.readBool() ? reader.readInt() : null,
    );
  }

  @override
  void write(BinaryWriter writer, Peer obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.publicKey);
    writer.writeBool(obj.presharedKey != null);
    if (obj.presharedKey != null) {
      writer.writeString(obj.presharedKey!);
    }
    writer.writeBool(obj.endpoint != null);
    if (obj.endpoint != null) {
      writer.writeString(obj.endpoint!);
    }
    writer.writeStringList(obj.allowedIps);
    writer.writeBool(obj.persistentKeepalive != null);
    if (obj.persistentKeepalive != null) {
      writer.writeInt(obj.persistentKeepalive!);
    }
    writer.writeBool(obj.isConnected);
    writer.writeBool(obj.lastHandshake != null);
    if (obj.lastHandshake != null) {
      writer.writeInt(obj.lastHandshake!.millisecondsSinceEpoch);
    }
    writer.writeBool(obj.rxBytes != null);
    if (obj.rxBytes != null) writer.writeInt(obj.rxBytes!);
    writer.writeBool(obj.txBytes != null);
    if (obj.txBytes != null) writer.writeInt(obj.txBytes!);
  }
}

/// Data source buat nyimpen metadata profile di database lokal.
///
/// Di sini pakai Hive biar nyimpen data profile cepet dan bisa offline.
/// Data sensitif kayak private key disimpen terpisah di secure storage.
class ProfileLocalDB {
  static const String _boxName = 'profiles';
  late Box<Profile> _box;

  /// Bikin instance ProfileLocalDB baru
  ProfileLocalDB();

  /// Inisialisasi database.
  ///
  /// Harus dipanggil dulu sebelum method lain.
  ///
  /// Return [Result] true kalau sukses, atau error kalau gagal.
  Future<Result<bool>> init() async {
    try {
      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ProfileAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PeerAdapter());
      }

      // Open the box
      _box = await Hive.openBox<Profile>(_boxName);
      return Result.success(true);
    } catch (e) {
      return Result.failure('Failed to initialize database: ${e.toString()}');
    }
  }

  /// Saves a profile to the database.
  ///
  /// [profile] - The profile to save
  ///
  /// Returns a [Result] containing the saved [Profile] on success,
  /// or an error message on failure.
  Future<Result<Profile>> saveProfile(Profile profile) async {
    try {
      await _box.put(profile.id, profile);
      return Result.success(profile);
    } catch (e) {
      return Result.failure('Failed to save profile: ${e.toString()}');
    }
  }

  /// Gets a profile by its ID.
  ///
  /// [id] - The ID of the profile
  ///
  /// Returns a [Result] containing the [Profile] on success,
  /// or an error message if not found.
  Future<Result<Profile>> getProfileById(String id) async {
    try {
      final profile = _box.get(id);

      if (profile == null) {
        return Result.failure('Profile not found: $id');
      }

      return Result.success(profile);
    } catch (e) {
      return Result.failure('Failed to get profile: ${e.toString()}');
    }
  }

  /// Gets all profiles from the database.
  ///
  /// Returns a [Result] containing a list of all [Profile] objects.
  Future<Result<List<Profile>>> getAllProfiles() async {
    try {
      final profiles = _box.values.toList();
      return Result.success(profiles);
    } catch (e) {
      return Result.failure('Failed to get all profiles: ${e.toString()}');
    }
  }

  /// Deletes a profile by its ID.
  ///
  /// [id] - The ID of the profile to delete
  ///
  /// Returns a [Result] containing true on success,
  /// or an error message on failure.
  Future<Result<bool>> deleteProfile(String id) async {
    try {
      await _box.delete(id);
      return Result.success(true);
    } catch (e) {
      return Result.failure('Failed to delete profile: ${e.toString()}');
    }
  }

  /// Deletes multiple profiles by their IDs.
  ///
  /// [ids] - The list of profile IDs to delete
  ///
  /// Returns a [Result] containing the number of deleted profiles on success,
  /// or an error message on failure.
  Future<Result<int>> deleteProfiles(List<String> ids) async {
    try {
      await _box.deleteAll(ids);
      return Result.success(ids.length);
    } catch (e) {
      return Result.failure('Failed to delete profiles: ${e.toString()}');
    }
  }

  /// Updates a profile in the database.
  ///
  /// [profile] - The profile to update
  ///
  /// Returns a [Result] containing the updated [Profile] on success,
  /// or an error message on failure.
  Future<Result<Profile>> updateProfile(Profile profile) async {
    try {
      // Check if profile exists
      if (!_box.containsKey(profile.id)) {
        return Result.failure('Profile not found: ${profile.id}');
      }

      await _box.put(profile.id, profile);
      return Result.success(profile);
    } catch (e) {
      return Result.failure('Failed to update profile: ${e.toString()}');
    }
  }

  /// Gets the count of profiles in the database.
  ///
  /// Returns a [Result] containing the number of profiles.
  Future<Result<int>> getProfileCount() async {
    try {
      final count = _box.length;
      return Result.success(count);
    } catch (e) {
      return Result.failure('Failed to get profile count: ${e.toString()}');
    }
  }

  /// Checks if a profile exists in the database.
  ///
  /// [id] - The ID of the profile to check
  ///
  /// Returns a [Result] containing true if the profile exists,
  /// false otherwise.
  Future<Result<bool>> profileExists(String id) async {
    try {
      final exists = _box.containsKey(id);
      return Result.success(exists);
    } catch (e) {
      return Result.failure(
          'Failed to check profile existence: ${e.toString()}');
    }
  }

  /// Clears all profiles from the database.
  ///
  /// This is a destructive operation and cannot be undone.
  ///
  /// Returns a [Result] containing true on success,
  /// or an error message on failure.
  Future<Result<bool>> clearAll() async {
    try {
      await _box.clear();
      return Result.success(true);
    } catch (e) {
      return Result.failure('Failed to clear all profiles: ${e.toString()}');
    }
  }

  /// Searches for profiles by name.
  ///
  /// [query] - The search query string
  ///
  /// Returns a [Result] containing a list of matching [Profile] objects.
  Future<Result<List<Profile>>> searchProfiles(String query) async {
    try {
      final lowerQuery = query.toLowerCase();
      final results = _box.values
          .where((profile) =>
              profile.name.toLowerCase().contains(lowerQuery) ||
              profile.interfaceName.toLowerCase().contains(lowerQuery))
          .toList();
      return Result.success(results);
    } catch (e) {
      return Result.failure('Failed to search profiles: ${e.toString()}');
    }
  }

  /// Gets profiles by interface name.
  ///
  /// [interfaceName] - The interface name to filter by
  ///
  /// Returns a [Result] containing a list of matching [Profile] objects.
  Future<Result<List<Profile>>> getProfilesByInterfaceName(
      String interfaceName) async {
    try {
      final lowerInterfaceName = interfaceName.toLowerCase();
      final results = _box.values
          .where((profile) =>
              profile.interfaceName.toLowerCase() == lowerInterfaceName)
          .toList();
      return Result.success(results);
    } catch (e) {
      return Result.failure(
          'Failed to get profiles by interface name: ${e.toString()}');
    }
  }

  /// Gets active profiles.
  ///
  /// Returns a [Result] containing a list of active [Profile] objects.
  Future<Result<List<Profile>>> getActiveProfiles() async {
    try {
      final results = _box.values.where((profile) => profile.isActive).toList();
      return Result.success(results);
    } catch (e) {
      return Result.failure('Failed to get active profiles: ${e.toString()}');
    }
  }

  /// Gets inactive profiles.
  ///
  /// Returns a [Result] containing a list of inactive [Profile] objects.
  Future<Result<List<Profile>>> getInactiveProfiles() async {
    try {
      final results =
          _box.values.where((profile) => !profile.isActive).toList();
      return Result.success(results);
    } catch (e) {
      return Result.failure('Failed to get inactive profiles: ${e.toString()}');
    }
  }

  /// Gets profiles sorted by creation date.
  ///
  /// [ascending] - Whether to sort in ascending order
  ///
  /// Returns a [Result] containing a sorted list of [Profile] objects.
  Future<Result<List<Profile>>> getProfilesSortedByDate(
      {bool ascending = false}) async {
    try {
      final profiles = _box.values.toList();
      profiles.sort((a, b) => ascending
          ? a.createdAt.compareTo(b.createdAt)
          : b.createdAt.compareTo(a.createdAt));
      return Result.success(profiles);
    } catch (e) {
      return Result.failure('Failed to sort profiles by date: ${e.toString()}');
    }
  }

  /// Gets profiles sorted by name.
  ///
  /// [ascending] - Whether to sort in ascending order
  ///
  /// Returns a [Result] containing a sorted list of [Profile] objects.
  Future<Result<List<Profile>>> getProfilesSortedByName(
      {bool ascending = true}) async {
    try {
      final profiles = _box.values.toList();
      profiles.sort((a, b) => ascending
          ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
          : b.name.toLowerCase().compareTo(a.name.toLowerCase()));
      return Result.success(profiles);
    } catch (e) {
      return Result.failure('Failed to sort profiles by name: ${e.toString()}');
    }
  }

  /// Closes the database.
  ///
  /// Returns a [Result] containing true on success,
  /// or an error message on failure.
  Future<Result<bool>> close() async {
    try {
      await _box.close();
      return Result.success(true);
    } catch (e) {
      return Result.failure('Failed to close database: ${e.toString()}');
    }
  }

  /// Compacts the database to reclaim space.
  ///
  /// Returns a [Result] containing true on success,
  /// or an error message on failure.
  Future<Result<bool>> compact() async {
    try {
      await _box.compact();
      return Result.success(true);
    } catch (e) {
      return Result.failure('Failed to compact database: ${e.toString()}');
    }
  }
}
