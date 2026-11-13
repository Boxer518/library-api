const schemaVersion = 1;
const schemaVersionKey = 'library_schema_version';
const booksKey = 'books_v1';
const authorsKey = 'authors_v1';
const genresKey = 'genres_v1';
const publishersKey = 'publishers_v1';
const readersKey = 'readers_v1';

const collectionKeys = [
  booksKey,
  authorsKey,
  genresKey,
  publishersKey,
  readersKey,
];

const legacyKeys = ['books', 'authors', 'genres', 'publishers', 'readers'];

const storageResetMessage =
    'Формат хранилища изменился. Каталог загружен из начального набора, '
    'старые записи не использованы.';
