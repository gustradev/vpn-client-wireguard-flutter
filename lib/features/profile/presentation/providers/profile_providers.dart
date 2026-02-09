import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_client_wireguard_flutter/features/profile/domain/entities/profile.dart';
import 'package:vpn_client_wireguard_flutter/features/profile/domain/services/wg_config_parser.dart';

// State sederhana buat nyimpen list profile di memori (MVP)
class ProfileState {
  final List<Profile> profiles;

  const ProfileState({this.profiles = const []});

  ProfileState copyWith({List<Profile>? profiles}) {
    return ProfileState(profiles: profiles ?? this.profiles);
  }
}

// Notifier buat ngatur list profile
class ProfileStateNotifier extends StateNotifier<ProfileState> {
  ProfileStateNotifier() : super(const ProfileState());

  void addProfile(Profile profile) {
    state = state.copyWith(profiles: [...state.profiles, profile]);
  }

  void updateProfile(Profile profile) {
    final updated =
        state.profiles.map((p) => p.id == profile.id ? profile : p).toList();
    state = state.copyWith(profiles: updated);
  }

  void removeProfile(String profileId) {
    final updated = state.profiles.where((p) => p.id != profileId).toList();
    state = state.copyWith(profiles: updated);
  }

  void toggleActive(String profileId) {
    final updated = state.profiles.map((p) {
      if (p.id == profileId) {
        return p.copyWith(isActive: !p.isActive);
      }
      if (p.isActive) {
        return p.copyWith(isActive: false);
      }
      return p;
    }).toList();
    state = state.copyWith(profiles: updated);
  }
}

// Provider list profile
final profileListProvider =
    StateNotifierProvider<ProfileStateNotifier, ProfileState>((ref) {
  return ProfileStateNotifier();
});

// Provider buat ambil list doang
final profilesProvider = Provider<List<Profile>>((ref) {
  return ref.watch(profileListProvider).profiles;
});

// Provider buat ambil profile by id
final profileByIdProvider = Provider.family<Profile?, String>((ref, id) {
  final profiles = ref.watch(profilesProvider);
  for (final profile in profiles) {
    if (profile.id == id) return profile;
  }
  return null;
});

// Provider parser config WireGuard
final wgConfigParserProvider = Provider<WgConfigParser>((ref) {
  return WgConfigParser();
});

// Bootstrap default profile dari assets (gusTra.conf)
final defaultProfileBootstrapProvider = FutureProvider<void>((ref) async {
  final profiles = ref.read(profilesProvider);
  if (profiles.isNotEmpty) return;

  final config = await rootBundle.loadString('assets/gusTra.conf');
  final parser = ref.read(wgConfigParserProvider);
  final result = parser.parse(config, name: 'gusTra');
  if (!result.isSuccess) return;

  final profile = result.valueOrThrow;
  final exists = profiles.any((p) => p.name == profile.name);
  if (exists) return;
  ref.read(profileListProvider.notifier).addProfile(profile);
});
