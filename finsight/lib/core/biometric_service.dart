import 'package:local_auth/local_auth.dart';

class BiometricService{

	static final _auth = LocalAuthentication();

	static Future<bool> isAvailable() async => await _auth.canCheckBiometrics || await _auth.isDeviceSupported();

	static Future<bool> authenticate() async {
		try{
			return await _auth.authenticate(
				localizedReason : 'Authenticate to open FinSight',
				options         : const AuthenticationOptions(
										biometricOnly : false,
										stickyAuth    : true,
									),
			);
		}catch(_){
			return false;
		}
	}
}