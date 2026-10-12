import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/models/friend_model.dart';
import 'package:mobile_app/services/friend_service.dart';

final friendServiceProvider = Provider<FriendService>((ref) {
  return FriendService();
});

final peersProvider =
    FutureProvider.family<List<PeerUser>, ({int userId, String query})>(
        (ref, args) async {
  final service = ref.watch(friendServiceProvider);
  return service.discoverPeers(args.userId, query: args.query);
});

final friendsListProvider =
    FutureProvider.family<List<PeerUser>, int>((ref, userId) async {
  final service = ref.watch(friendServiceProvider);
  return service.getFriends(userId);
});

final incomingRequestsProvider =
    FutureProvider.family<List<PeerUser>, int>((ref, userId) async {
  final service = ref.watch(friendServiceProvider);
  return service.getIncomingRequests(userId);
});

final outgoingRequestsProvider =
    FutureProvider.family<List<PeerUser>, int>((ref, userId) async {
  final service = ref.watch(friendServiceProvider);
  return service.getOutgoingRequests(userId);
});

final friendsCountProvider =
    FutureProvider.family<int, int>((ref, userId) async {
  final service = ref.watch(friendServiceProvider);
  return service.friendsCount(userId);
});

final pendingRequestsCountProvider =
    FutureProvider.family<int, int>((ref, userId) async {
  final service = ref.watch(friendServiceProvider);
  return service.pendingCount(userId);
});

void invalidateFriends(WidgetRef ref, int userId) {
  ref.invalidate(friendsListProvider(userId));
  ref.invalidate(incomingRequestsProvider(userId));
  ref.invalidate(outgoingRequestsProvider(userId));
  ref.invalidate(friendsCountProvider(userId));
  ref.invalidate(pendingRequestsCountProvider(userId));
  ref.invalidate(peersProvider);
}
