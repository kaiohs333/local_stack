/// Configurações do aplicativo
class AppConfig {
  AppConfig._();

  /// URL base do LocalStack
  static const String localstackUrl = 'http://localhost:4566';
  
  /// URL base para emulador Android (usa 10.0.2.2 para acessar localhost do host)
  static const String localstackUrlAndroid = 'http://10.0.2.2:4566';
  
  /// Nome do bucket S3
  static const String bucketName = 'shopping-images';
  
  /// URL do endpoint de upload
  /// Ajuste esta URL conforme a saída do 'serverless deploy --stage local'
  /// O formato típico é: http://localhost:4566/restapis/{apiId}/local/_user_request_/photos/upload
  static const String uploadEndpoint = 'http://localhost:4566/restapis/local/local/_user_request_/photos/upload';
  
  /// URL do endpoint para Android
  static const String uploadEndpointAndroid = 'http://10.0.2.2:4566/restapis/local/local/_user_request_/photos/upload';
  
  /// Timeout para requisições (segundos)
  static const int requestTimeout = 30;
  
  /// Qualidade de compressão das imagens (0-100)
  static const int imageQuality = 85;
  
  /// Largura máxima das imagens
  static const int maxImageWidth = 1920;
  
  /// Altura máxima das imagens
  static const int maxImageHeight = 1080;
}
