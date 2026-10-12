import 'package:mobile_app/helper/db_helper.dart';
import 'package:mobile_app/models/friend_model.dart';

class FriendService {
  final DatabaseHelper _db;

  FriendService({DatabaseHelper? dbHelper})
      : _db = dbHelper ?? DatabaseHelper();

  Future<List<PeerUser>> discoverPeers(int userId, {String query = ''}) async {
    final rows = await _db.getAllPeers(userId, query: query);
    return rows.map(PeerUser.fromMap).toList();
  }

  Future<List<PeerUser>> getFriends(int userId) async {
    final rows = await _db.getFriends(userId);
    return rows
        .map((m) => PeerUser.fromMap({...m, 'friendshipStatus': 'accepted'}))
        .toList();
  }

  Future<List<PeerUser>> getIncomingRequests(int userId) async {
    final rows = await _db.getIncomingRequests(userId);
    return rows
        .map((m) =>
            PeerUser.fromMap({...m, 'friendshipStatus': 'pending_received'}))
        .toList();
  }

  Future<List<PeerUser>> getOutgoingRequests(int userId) async {
    final rows = await _db.getOutgoingRequests(userId);
    return rows
        .map((m) =>
            PeerUser.fromMap({...m, 'friendshipStatus': 'pending_sent'}))
        .toList();
  }

  Future<int> friendsCount(int userId) => _db.getFriendsCount(userId);
  Future<int> pendingCount(int userId) =>
      _db.getPendingIncomingCount(userId);

  Future<bool> sendRequest(int userId, int peerId) =>
      _db.sendFriendRequest(userId, peerId);

  Future<bool> accept(int friendshipId, int currentUserId) =>
      _db.acceptFriendRequest(friendshipId, currentUserId);

  Future<bool> decline(int friendshipId, int currentUserId) =>
      _db.declineFriendRequest(friendshipId, currentUserId);

  Future<bool> cancel(int userId, int peerId) =>
      _db.cancelOutgoingRequest(userId, peerId);

  Future<bool> unfriend(int userId, int peerId) =>
      _db.removeFriend(userId, peerId);
}
