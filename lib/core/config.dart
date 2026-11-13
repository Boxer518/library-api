/// Адрес учебного API. На занятии, дома и после публикации он разный,
/// поэтому в код его не зашивают.
///
/// `flutter run -d chrome --web-port=5555 --dart-define=API_BASE_URL=http://192.168.1.10:8080/api`
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080/api',
);

/// Учётка из учебного сервера. `admin` умеет и править каталог, и восстанавливать записи.
const apiUsername = String.fromEnvironment(
  'API_USERNAME',
  defaultValue: 'admin',
);

const apiPassword = String.fromEnvironment(
  'API_PASSWORD',
  defaultValue: 'admin123',
);
