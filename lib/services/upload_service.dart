import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Serviço responsável por fazer upload de fotos para o S3 via LocalStack
class UploadService {
  
  /// Retorna a URL do LocalStack baseado na plataforma
  static String get _localstackUrl {
    if (Platform.isAndroid) {
      return AppConfig.localstackUrlAndroid;
    }
    return AppConfig.localstackUrl;
  }
  
  /// Retorna a URL do endpoint de upload baseado na plataforma
  static String get uploadUrl {
    if (Platform.isAndroid) {
      return AppConfig.uploadEndpointAndroid;
    }
    return AppConfig.uploadEndpoint;
  }

  /// Faz upload de uma foto para o S3 via backend
  /// 
  /// [imagePath] - Caminho local da imagem
  /// [fileName] - Nome do arquivo (opcional, será gerado automaticamente se não fornecido)
  /// 
  /// Retorna um [UploadResult] com informações do upload
  static Future<UploadResult> uploadPhoto({
    required String imagePath,
    String? fileName,
  }) async {
    try {
      // Ler arquivo e converter para base64
      final file = File(imagePath);
      if (!await file.exists()) {
        return UploadResult(
          success: false,
          error: 'Arquivo não encontrado: $imagePath',
        );
      }

      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Gerar nome do arquivo se não fornecido
      final finalFileName = fileName ?? 
          'product-${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Determinar content type
      final contentType = _getContentType(imagePath);
      
      // Primeiro, tenta upload direto via S3 API (mais confiável)
      final directResult = await _uploadDirectToS3(
        bytes: bytes,
        fileName: finalFileName,
        contentType: contentType,
      );
      
      if (directResult.success) {
        return directResult;
      }

      // Se falhar, tenta via Lambda endpoint
      return await _uploadViaLambda(
        base64Image: base64Image,
        fileName: finalFileName,
        contentType: contentType,
      );
      
    } catch (e) {
      return UploadResult(
        success: false,
        error: 'Erro ao fazer upload: $e',
      );
    }
  }
  
  /// Upload direto para S3 via API do LocalStack
  static Future<UploadResult> _uploadDirectToS3({
    required List<int> bytes,
    required String fileName,
    required String contentType,
  }) async {
    try {
      final key = 'photos/${DateTime.now().millisecondsSinceEpoch}-$fileName';
      final url = '$_localstackUrl/${AppConfig.bucketName}/$key';
      
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': contentType,
        },
        body: bytes,
      ).timeout(
        Duration(seconds: AppConfig.requestTimeout),
        onTimeout: () => throw Exception('Timeout ao fazer upload'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return UploadResult(
          success: true,
          url: url,
          key: key,
          message: 'Upload direto para S3 realizado com sucesso!',
        );
      } else {
        return UploadResult(
          success: false,
          error: 'Erro no upload direto: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      return UploadResult(
        success: false,
        error: 'Falha no upload direto: $e',
      );
    }
  }
  
  /// Upload via endpoint Lambda
  static Future<UploadResult> _uploadViaLambda({
    required String base64Image,
    required String fileName,
    required String contentType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(uploadUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'base64Data': base64Image,
          'fileName': fileName,
          'contentType': contentType,
        }),
      ).timeout(
        Duration(seconds: AppConfig.requestTimeout),
        onTimeout: () => throw Exception('Timeout ao fazer upload via Lambda'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UploadResult(
          success: true,
          url: data['url'],
          key: data['key'],
          message: data['message'] ?? 'Upload via Lambda realizado com sucesso!',
        );
      } else {
        final errorData = jsonDecode(response.body);
        return UploadResult(
          success: false,
          error: errorData['error'] ?? 'Erro desconhecido',
        );
      }
    } catch (e) {
      return UploadResult(
        success: false,
        error: 'Erro ao fazer upload via Lambda: $e',
      );
    }
  }

  /// Determina o content type baseado na extensão do arquivo
  static String _getContentType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  /// Verifica se o backend está acessível
  static Future<bool> checkConnection() async {
    try {
      final testUrl = '$_localstackUrl/_localstack/health';
      
      final response = await http.get(Uri.parse(testUrl)).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// Lista as fotos no bucket S3
  static Future<List<String>> listPhotos() async {
    try {
      final url = '$_localstackUrl/${AppConfig.bucketName}?prefix=photos/';
      
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );
      
      if (response.statusCode == 200) {
        // Parse XML response (S3 retorna XML)
        final body = response.body;
        final keyRegex = RegExp(r'<Key>([^<]+)</Key>');
        final matches = keyRegex.allMatches(body);
        return matches.map((m) => m.group(1)!).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

/// Resultado de um upload
class UploadResult {
  final bool success;
  final String? url;
  final String? key;
  final String? message;
  final String? error;

  UploadResult({
    required this.success,
    this.url,
    this.key,
    this.message,
    this.error,
  });

  @override
  String toString() {
    if (success) {
      return 'UploadResult(success: true, url: $url, key: $key)';
    }
    return 'UploadResult(success: false, error: $error)';
  }
}
