import '../models/reference.dart';

/// Город сужается до города выбранного издательства.
List<String> narrowCities({
  required List<String> cities,
  required String? selectedPublisherCity,
}) {
  if (selectedPublisherCity == null) {
    return List<String>.of(cities);
  }
  return [selectedPublisherCity];
}

/// Список издательств сужается до выбранного города.
List<Publisher> narrowPublishers({
  required List<Publisher> publishers,
  required String? city,
}) {
  if (city == null) {
    return List<Publisher>.of(publishers);
  }
  return publishers.where((publisher) => publisher.city == city).toList();
}
