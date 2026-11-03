import 'dart:async';

import 'package:petani/auth/services/auth_service.dart';
import 'package:petani/sync/services/local_snapshot_store.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum DataSyncResult {
  skipped,
  unchanged,
  uploaded,
  downloaded,
  replacedAndUploaded,
}

class DataSyncService {
  const DataSyncService({required this.authService, required this.localStore});

  final SupabaseAuthService authService;
  final LocalSnapshotStore localStore;

  Future<DataSyncResult> synchronize() async {
    final client = authService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return DataSyncResult.skipped;

    final metadata = await localStore.getMetadata();
    final remote = await _getRemoteSnapshot(client, user.id);

    final belongsToAnotherUser =
        metadata.linkedUserId != null && metadata.linkedUserId != user.id;
    if (belongsToAnotherUser) {
      if (remote != null) return _download(remote: remote, userId: user.id);

      // Never upload the previous account's local snapshot into a newly
      // authenticated account on the same device.
      final emptySnapshotChangedAt = await localStore
          .replaceWithEmptyDataForUser(user.id);
      await _upload(
        client: client,
        userId: user.id,
        localChangedAt: emptySnapshotChangedAt,
      );
      return DataSyncResult.replacedAndUploaded;
    }

    if (remote == null) {
      return _upload(
        client: client,
        userId: user.id,
        localChangedAt: metadata.localChangedAt,
      );
    }

    final isNewUserLink = metadata.linkedUserId == null;
    final localHasChanges =
        metadata.lastSyncedLocalChangedAt == null ||
        metadata.localChangedAt.isAfter(metadata.lastSyncedLocalChangedAt!);
    final remoteHasChanges =
        metadata.lastRemoteUpdatedAt == null ||
        remote.updatedAt.isAfter(metadata.lastRemoteUpdatedAt!);

    if (!isNewUserLink && !localHasChanges && !remoteHasChanges) {
      await localStore.recordNoChanges(
        userId: user.id,
        localChangedAt: metadata.localChangedAt,
        remoteUpdatedAt: remote.updatedAt,
      );
      return DataSyncResult.unchanged;
    }

    if (isNewUserLink && !await localStore.hasUserData()) {
      return _download(remote: remote, userId: user.id);
    }

    if (localHasChanges &&
        (!remoteHasChanges ||
            metadata.localChangedAt.isAfter(remote.clientUpdatedAt))) {
      return _upload(
        client: client,
        userId: user.id,
        localChangedAt: metadata.localChangedAt,
      );
    }

    return _download(remote: remote, userId: user.id);
  }

  Future<_RemoteSnapshot?> _getRemoteSnapshot(
    SupabaseClient client,
    String userId,
  ) async {
    final response = await client
        .from('user_data_snapshots')
        .select('snapshot, client_updated_at, updated_at')
        .eq('user_id', userId)
        .maybeSingle();
    if (response == null) return null;
    return _RemoteSnapshot.fromJson(response);
  }

  Future<DataSyncResult> _upload({
    required SupabaseClient client,
    required String userId,
    required DateTime localChangedAt,
  }) async {
    final snapshot = await localStore.exportSnapshot();
    final response = await client
        .from('user_data_snapshots')
        .upsert({
          'user_id': userId,
          'snapshot': snapshot,
          'client_updated_at': localChangedAt.toUtc().toIso8601String(),
        }, onConflict: 'user_id')
        .select('updated_at')
        .single();
    final remoteUpdatedAt = DateTime.parse(
      response['updated_at'] as String,
    ).toUtc();
    await localStore.recordSuccessfulPush(
      userId: userId,
      localChangedAt: localChangedAt,
      remoteUpdatedAt: remoteUpdatedAt,
    );
    return DataSyncResult.uploaded;
  }

  Future<DataSyncResult> _download({
    required _RemoteSnapshot remote,
    required String userId,
  }) async {
    await localStore.applyRemoteSnapshot(
      snapshot: remote.snapshot,
      userId: userId,
      remoteClientUpdatedAt: remote.clientUpdatedAt,
      remoteUpdatedAt: remote.updatedAt,
    );
    return DataSyncResult.downloaded;
  }
}

class _RemoteSnapshot {
  const _RemoteSnapshot({
    required this.snapshot,
    required this.clientUpdatedAt,
    required this.updatedAt,
  });

  factory _RemoteSnapshot.fromJson(Map<String, dynamic> json) {
    return _RemoteSnapshot(
      snapshot: Map<String, dynamic>.from(json['snapshot'] as Map),
      clientUpdatedAt: DateTime.parse(
        json['client_updated_at'] as String,
      ).toUtc(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
    );
  }

  final Map<String, dynamic> snapshot;
  final DateTime clientUpdatedAt;
  final DateTime updatedAt;
}
