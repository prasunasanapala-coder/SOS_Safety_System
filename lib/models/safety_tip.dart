/// A safety tip delivered by the (mock) REST API.
class SafetyTip {
  const SafetyTip({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
  });

  final String id;
  final String category;
  final String title;
  final String body;

  /// Returns null when the JSON item is malformed, so one bad item does not
  /// break the whole list.
  static SafetyTip? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final id = json['id'];
    final category = json['category'];
    final title = json['title'];
    final body = json['body'];
    if (id is! String || category is! String || title is! String || body is! String) {
      return null;
    }
    return SafetyTip(id: id, category: category, title: title, body: body);
  }
}