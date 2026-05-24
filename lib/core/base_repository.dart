
abstract class BaseRepository<T> {
  Future<List<T>> getAll(int userId);
  Future<T?> getById(int id);
  Future<int> create(int userId, T model);
  Future<void> update(T model);
  Future<void> delete(int id);
  Future<List<T>> search(int userId, String query);
}