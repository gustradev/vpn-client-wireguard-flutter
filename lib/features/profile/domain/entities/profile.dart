import 'package:equatable/equatable.dart';

/// Ini model buat profil WireGuard VPN.
///
/// Di sini ada data penting (metadata, biasanya disimpan terenkripsi) dan field yang udah didekripsi,
/// jadi gampang buat ditampilkan atau diedit di aplikasi.
class Profile extends Equatable {
  /// ID unik buat profil ini
  final String id;

  /// Nama tampilan profil (biar gampang dikenali)
  final String name;

  /// Nama interface WireGuard (misal: wg0)
  final String interfaceName;

  /// Private key interface (udah didekripsi)
  final String privateKey;

  /// Public key interface (hasil dari private key)
  final String publicKey;

  /// Port yang dipakai buat listen
  final int? listenPort;

  /// MTU (ukuran paket maksimal)
  final int? mtu;

  /// Daftar DNS yang dipakai pas konek
  final List<String> dns;

  /// Daftar peer di profil ini
  final List<Peer> peers;

  /// Profil ini lagi aktif atau nggak
  final bool isActive;

  /// Kapan profil ini dibuat
  final DateTime createdAt;

  /// Kapan terakhir profil ini diubah
  final DateTime updatedAt;

  /// Catatan atau deskripsi tambahan (opsional)
  final String? notes;

  /// Raw config WireGuard (opsional, untuk restore/rekoneksi)
  final String? rawConfig;

  const Profile({
    required this.id,
    required this.name,
    required this.interfaceName,
    required this.privateKey,
    required this.publicKey,
    this.listenPort,
    this.mtu,
    this.dns = const [],
    this.peers = const [],
    this.isActive = false,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.rawConfig,
  });

  /// Creates a copy of this profile with some fields replaced
  Profile copyWith({
    String? id,
    String? name,
    String? interfaceName,
    String? privateKey,
    String? publicKey,
    int? listenPort,
    int? mtu,
    List<String>? dns,
    List<Peer>? peers,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    String? rawConfig,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      interfaceName: interfaceName ?? this.interfaceName,
      privateKey: privateKey ?? this.privateKey,
      publicKey: publicKey ?? this.publicKey,
      listenPort: listenPort ?? this.listenPort,
      mtu: mtu ?? this.mtu,
      dns: dns ?? this.dns,
      peers: peers ?? this.peers,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      rawConfig: rawConfig ?? this.rawConfig,
    );
  }

  /// Returns true if the profile has at least one peer configured
  bool get hasPeers => peers.isNotEmpty;

  /// Returns the number of peers in this profile
  int get peerCount => peers.length;

  /// Returns the first peer if available, null otherwise
  Peer? get firstPeer => peers.isNotEmpty ? peers.first : null;

  @override
  List<Object?> get props => [
        id,
        name,
        interfaceName,
        privateKey,
        publicKey,
        listenPort,
        mtu,
        dns,
        peers,
        isActive,
        createdAt,
        updatedAt,
        notes,
        rawConfig,
      ];
}

/// Represents a WireGuard peer configuration.
class Peer extends Equatable {
  /// Unique identifier for the peer
  final String id;

  /// Display name for the peer
  final String name;

  /// Public key of the peer
  final String publicKey;

  /// Pre-shared key (optional, for additional security)
  final String? presharedKey;

  /// Endpoint address (e.g., 192.168.1.1:51820)
  final String? endpoint;

  /// Allowed IPs for this peer (e.g., 0.0.0.0/0)
  final List<String> allowedIps;

  /// Persistent keepalive interval in seconds
  final int? persistentKeepalive;

  /// Whether this peer is currently connected
  final bool isConnected;

  /// Last handshake timestamp
  final DateTime? lastHandshake;

  /// Bytes received from this peer
  final int? rxBytes;

  /// Bytes sent to this peer
  final int? txBytes;

  const Peer({
    required this.id,
    required this.name,
    required this.publicKey,
    this.presharedKey,
    this.endpoint,
    this.allowedIps = const [],
    this.persistentKeepalive,
    this.isConnected = false,
    this.lastHandshake,
    this.rxBytes,
    this.txBytes,
  });

  /// Creates a copy of this peer with some fields replaced
  Peer copyWith({
    String? id,
    String? name,
    String? publicKey,
    String? presharedKey,
    String? endpoint,
    List<String>? allowedIps,
    int? persistentKeepalive,
    bool? isConnected,
    DateTime? lastHandshake,
    int? rxBytes,
    int? txBytes,
  }) {
    return Peer(
      id: id ?? this.id,
      name: name ?? this.name,
      publicKey: publicKey ?? this.publicKey,
      presharedKey: presharedKey ?? this.presharedKey,
      endpoint: endpoint ?? this.endpoint,
      allowedIps: allowedIps ?? this.allowedIps,
      persistentKeepalive: persistentKeepalive ?? this.persistentKeepalive,
      isConnected: isConnected ?? this.isConnected,
      lastHandshake: lastHandshake ?? this.lastHandshake,
      rxBytes: rxBytes ?? this.rxBytes,
      txBytes: txBytes ?? this.txBytes,
    );
  }

  /// Returns true if the peer has a pre-shared key configured
  bool get hasPresharedKey => presharedKey != null && presharedKey!.isNotEmpty;

  /// Returns true if the peer has an endpoint configured
  bool get hasEndpoint => endpoint != null && endpoint!.isNotEmpty;

  /// Returns true if the peer has allowed IPs configured
  bool get hasAllowedIps => allowedIps.isNotEmpty;

  /// Returns the total bytes transferred (rx + tx)
  int? get totalBytes {
    if (rxBytes == null && txBytes == null) return null;
    return (rxBytes ?? 0) + (txBytes ?? 0);
  }

  @override
  List<Object?> get props => [
        id,
        name,
        publicKey,
        presharedKey,
        endpoint,
        allowedIps,
        persistentKeepalive,
        isConnected,
        lastHandshake,
        rxBytes,
        txBytes,
      ];
}
