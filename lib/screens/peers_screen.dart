import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/models/friend_model.dart';
import 'package:mobile_app/providers/friends_providers.dart';

class PeersScreen extends ConsumerStatefulWidget {
  final int userId;
  const PeersScreen({super.key, required this.userId});

  @override
  ConsumerState<PeersScreen> createState() => _PeersScreenState();
}

class _PeersScreenState extends ConsumerState<PeersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _query = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _refreshAll() {
    invalidateFriends(ref, widget.userId);
    setState(() {});
  }

  Future<void> _run(Future<bool> Function() action, String okMsg) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ok = await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? okMsg : 'Nothing changed',
              style: const TextStyle(color: Colors.white)),
          backgroundColor:
              ok ? Theme.of(context).primaryColor : Colors.grey,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
      _refreshAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showPeerDetail(PeerUser peer) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: accent.withValues(alpha: 0.1),
              backgroundImage: (peer.profilePath != null &&
                      File(peer.profilePath!).existsSync())
                  ? FileImage(File(peer.profilePath!))
                  : null,
              child: (peer.profilePath == null ||
                      !File(peer.profilePath!).existsSync())
                  ? Icon(Icons.person_rounded, color: accent, size: 32)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(peer.displayName,
                style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 16)),
            Text('@${peer.username}',
                style: TextStyle(color: theme.hintColor, fontSize: 12)),
            const SizedBox(height: 12),
            _detailRow('School', peer.school ?? 'Not set'),
            _detailRow('Course', peer.course ?? 'Not set'),
            _detailRow('Year', peer.yearLevel ?? 'Not set'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close',
                style:
                    TextStyle(color: accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
              width: 60,
              child: Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: theme.hintColor,
                      fontWeight: FontWeight.bold))),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final pendingCount =
        ref.watch(pendingRequestsCountProvider(widget.userId)).asData?.value ??
            0;
    final friendsCount =
        ref.watch(friendsListProvider(widget.userId)).asData?.value.length ??
            0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text('PEERS',
            style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 1.5)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search by name, school, course...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.cardColor.withValues(alpha: 0.6),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    isDense: true,
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: accent,
                unselectedLabelColor: theme.hintColor,
                indicatorColor: accent,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 12),
                tabs: [
                  const Tab(text: 'DISCOVER'),
                  Tab(text: 'FRIENDS ($friendsCount)'),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('REQUESTS',
                            style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 12)),
                        if (pendingCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(10)),
                            child: Text('$pendingCount',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDiscoverTab(accent),
          _buildFriendsTab(accent),
          _buildRequestsTab(accent),
        ],
      ),
    );
  }

  Widget _buildDiscoverTab(Color accent) {
    final theme = Theme.of(context);
    final peersAsync =
        ref.watch(peersProvider((userId: widget.userId, query: _query)));
    return peersAsync.when(
      data: (peers) {
        if (peers.isEmpty) {
          return _emptyState(
              Icons.group_outlined,
              _query.isEmpty
                  ? 'No other students yet.\nCreate another account on this device to test.'
                  : 'No peers match "$_query"');
        }
        return RefreshIndicator(
          onRefresh: () async => _refreshAll(),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            itemCount: peers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) => _peerCard(peers[i], accent, isDiscover: true),
          ),
        );
      },
      loading: () => Center(child: CircularProgressIndicator(color: accent)),
      error: (e, _) => Center(
          child: Text('Failed to load peers: $e',
              style: TextStyle(color: theme.hintColor))),
    );
  }

  Widget _buildFriendsTab(Color accent) {
    final friendsAsync = ref.watch(friendsListProvider(widget.userId));
    return friendsAsync.when(
      data: (friends) {
        if (friends.isEmpty) {
          return _emptyState(Icons.people_outline_rounded,
              'No friends yet.\nDiscover peers and send a request.');
        }
        return RefreshIndicator(
          onRefresh: () async => _refreshAll(),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            itemCount: friends.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) => _peerCard(friends[i], accent),
          ),
        );
      },
      loading: () => Center(child: CircularProgressIndicator(color: accent)),
      error: (e, _) => Center(child: Text('Failed: $e')),
    );
  }

  Widget _buildRequestsTab(Color accent) {
    final theme = Theme.of(context);
    final incomingAsync = ref.watch(incomingRequestsProvider(widget.userId));
    final outgoingAsync = ref.watch(outgoingRequestsProvider(widget.userId));
    return RefreshIndicator(
      onRefresh: () async => _refreshAll(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text('INCOMING',
              style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.2)),
          const SizedBox(height: 10),
          incomingAsync.when(
            data: (list) => list.isEmpty
                ? _miniEmpty('No incoming requests', theme)
                : Column(
                    children: list
                        .map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _peerCard(p, accent),
                            ))
                        .toList(),
                  ),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Failed: $e'),
          ),
          const SizedBox(height: 16),
          Text('SENT',
              style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.2)),
          const SizedBox(height: 10),
          outgoingAsync.when(
            data: (list) => list.isEmpty
                ? _miniEmpty('No sent requests', theme)
                : Column(
                    children: list
                        .map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _peerCard(p, accent),
                            ))
                        .toList(),
                  ),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Failed: $e'),
          ),
        ],
      ),
    );
  }

  Widget _miniEmpty(String msg, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: theme.dividerColor.withValues(alpha: 0.3))),
      child: Text(msg,
          textAlign: TextAlign.center,
          style: TextStyle(color: theme.hintColor, fontSize: 12)),
    );
  }

  Widget _emptyState(IconData icon, String msg) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.hintColor),
            const SizedBox(height: 12),
            Text(msg,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.hintColor, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _peerCard(PeerUser peer, Color accent, {bool isDiscover = false}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        onTap: () => _showPeerDetail(peer),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: accent.withValues(alpha: 0.12),
          backgroundImage: (peer.profilePath != null &&
                  File(peer.profilePath!).existsSync())
              ? FileImage(File(peer.profilePath!))
              : null,
          child: (peer.profilePath == null ||
                  !File(peer.profilePath!).existsSync())
              ? Text(peer.displayName.isNotEmpty
                  ? peer.displayName[0].toUpperCase()
                  : '?', style: TextStyle(color: accent, fontWeight: FontWeight.w900))
              : null,
        ),
        title: Text(peer.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: theme.colorScheme.onSurface)),
        subtitle: Text(peer.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: theme.hintColor, fontSize: 12)),
        trailing: _actionButton(peer, accent),
      ),
    );
  }

  Widget _actionButton(PeerUser peer, Color accent) {
    final service = ref.read(friendServiceProvider);
    switch (peer.friendshipStatus) {
      case 'accepted':
        return IconButton(
          tooltip: 'Remove friend',
          icon: const Icon(Icons.person_remove_outlined, size: 20),
          color: Colors.redAccent,
          onPressed: () => showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Remove ${peer.displayName}?'),
              content: const Text('You can send a new request later.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _run(() => service.unfriend(widget.userId, peer.id),
                        'Friend removed');
                  },
                  child: const Text('Remove',
                      style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          ),
        );
      case 'pending_sent':
        return TextButton(
          onPressed: () =>
              _run(() => service.cancel(widget.userId, peer.id), 'Request cancelled'),
          child: const Text('PENDING',
              style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w900,
                  fontSize: 11)),
        );
      case 'pending_received':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Accept',
              icon: const Icon(Icons.check_circle_rounded, size: 24),
              color: Colors.green,
              onPressed: peer.friendshipId == null
                  ? null
                  : () => _run(
                      () => service.accept(
                          peer.friendshipId!, widget.userId),
                      'Friend added'),
            ),
            IconButton(
              tooltip: 'Decline',
              icon: const Icon(Icons.cancel_rounded, size: 24),
              color: Colors.redAccent,
              onPressed: peer.friendshipId == null
                  ? null
                  : () => _run(
                      () => service.decline(
                          peer.friendshipId!, widget.userId),
                      'Request declined'),
            ),
          ],
        );
      default:
        return ElevatedButton(
          onPressed: () => _run(
              () => service.sendRequest(widget.userId, peer.id),
              'Request sent to ${peer.displayName}'),
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            minimumSize: const Size(64, 32),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('ADD',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11)),
        );
    }
  }
}
