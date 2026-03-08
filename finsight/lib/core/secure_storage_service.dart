import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService{
	static const _s = FlutterSecureStorage(
		aOptions: AndroidOptions( encryptedSharedPreferences: true),
		iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
	);

	static Future<void>    write(String key, String value) => _s.write(key: key, value: value);
	static Future<String?> read(String key)                => _s.read(key: key);
	static Future<void>    delete(String key)              => _s.delete(key: key);
	static Future<void>    deleteAll()                     => _s.deleteAll();

}