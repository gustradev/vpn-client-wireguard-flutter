import 'package:flutter/material.dart';
import 'package:vpn_client_wireguard_flutter/features/profile/domain/entities/profile.dart';

// Widget kartu buat nampilin info singkat profile WireGuard.
// Bisa tap buat detail, connect/disconnect, dan hapus.
class ProfileCard extends StatelessWidget {
  // Data profile yang mau ditampilkan
  final Profile profile;
  // Callback kalau kartu di-tap (biasanya buat buka detail)
  final VoidCallback? onTap;
  // Callback buat connect/disconnect VPN
  final VoidCallback? onConnect;
  // Callback buat hapus profile
  final VoidCallback? onDelete;

  const ProfileCard({
    super.key,
    required this.profile,
    this.onTap,
    this.onConnect,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Kartu profile, bisa tap buat detail, tombol connect/disconnect, dan hapus
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon profile
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.vpn_key,
                  color: Colors.indigo,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Info utama: nama, endpoint, interface
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (profile.firstPeer?.endpoint != null)
                      Text(
                        profile.firstPeer!.endpoint!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      'Interface: ${profile.interfaceName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Tombol connect/disconnect dan hapus
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (onConnect != null)
                    IconButton(
                      icon: Icon(
                        profile.isActive ? Icons.stop : Icons.play_arrow,
                        color: profile.isActive ? Colors.red : Colors.green,
                      ),
                      onPressed: onConnect,
                      tooltip: profile.isActive ? 'Disconnect' : 'Connect',
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: onDelete,
                      tooltip: 'Delete',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
