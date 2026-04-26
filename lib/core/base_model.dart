/// Abstract base class for all model entities.
abstract class BaseModel<T> {
  final int? id;

  const BaseModel({this.id});

  Map<String, dynamic> toMap();

  factory BaseModel.fromMap(Map<String, dynamic> map) {
    throw UnimplementedError('Subclasses must implement fromMap');
  }

  T copyWith({int? id});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BaseModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}