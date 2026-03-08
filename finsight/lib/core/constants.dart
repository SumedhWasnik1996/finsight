class AppConstants {
    
    static const String tlAuthUrl     = 'https://auth.truelayer-sandbox.com';
    static const String tlApiUrl      = 'https://api.truelayer-sandbox.com';
    static const String tlClientId    = 'sandbox-finsight-efcfc5';
    static const String tlRedriectUri = 'finsight://callback';

    static const String dbName = 'finsight.db';

    static const String keyDbEncryption   = 'db_encryption_key';
    static const String keyTlAccessToken  = 'tl_access_token';
    static const String keyTlRefreshToekn = 'tl_refresh_token';

    static const String keyRetentionMonths = '9';

    static const int defaultRententionMonths = 9;

    static const String backupExtension = '.finsightbak';
}