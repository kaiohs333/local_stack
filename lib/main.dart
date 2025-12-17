import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'services/upload_service.dart';

void main() {
  runApp(const ShoppingImagesApp());
}

class ShoppingImagesApp extends StatelessWidget {
  const ShoppingImagesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shopping Images - S3 Upload',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const PhotoUploadPage(),
    );
  }
}

class PhotoUploadPage extends StatefulWidget {
  const PhotoUploadPage({super.key});

  @override
  State<PhotoUploadPage> createState() => _PhotoUploadPageState();
}

class _PhotoUploadPageState extends State<PhotoUploadPage> {
  final ImagePicker _picker = ImagePicker();
  final List<PhotoItem> _photos = [];
  bool _isUploading = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    final connected = await UploadService.checkConnection();
    setState(() {
      _isConnected = connected;
    });
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (photo != null) {
        await _processAndUploadPhoto(photo);
      }
    } catch (e) {
      _showError('Erro ao acessar câmera: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (photo != null) {
        await _processAndUploadPhoto(photo);
      }
    } catch (e) {
      _showError('Erro ao acessar galeria: $e');
    }
  }

  Future<void> _processAndUploadPhoto(XFile photo) async {
    // Adiciona foto à lista local primeiro
    final photoItem = PhotoItem(
      localPath: photo.path,
      fileName: 'product-${DateTime.now().millisecondsSinceEpoch}.jpg',
      status: UploadStatus.pending,
    );

    setState(() {
      _photos.insert(0, photoItem);
      _isUploading = true;
    });

    // Faz upload para S3
    final result = await UploadService.uploadPhoto(
      imagePath: photo.path,
      fileName: photoItem.fileName,
    );

    setState(() {
      _isUploading = false;
      photoItem.status = result.success ? UploadStatus.success : UploadStatus.failed;
      photoItem.s3Url = result.url;
      photoItem.s3Key = result.key;
      photoItem.errorMessage = result.error;
    });

    if (result.success) {
      _showSuccess('Foto enviada para S3!\nKey: ${result.key}');
    } else {
      _showError('Falha no upload: ${result.error}');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Images'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Indicador de conexão
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(
                  _isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: _isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  _isConnected ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: _isConnected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkConnection,
            tooltip: 'Verificar conexão',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header com instruções
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📷 Upload de Fotos para S3',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tire uma foto ou selecione da galeria. A imagem será salva no bucket S3 "shopping-images" via LocalStack.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          // Lista de fotos
          Expanded(
            child: _photos.isEmpty
                ? _buildEmptyState()
                : _buildPhotoList(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Botão da galeria
          FloatingActionButton(
            heroTag: 'gallery',
            onPressed: _isUploading ? null : _pickFromGallery,
            backgroundColor: Colors.purple,
            child: const Icon(Icons.photo_library, color: Colors.white),
          ),
          const SizedBox(height: 16),
          // Botão da câmera
          FloatingActionButton.large(
            heroTag: 'camera',
            onPressed: _isUploading ? null : _takePhoto,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: _isUploading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.camera_alt, color: Colors.white, size: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma foto ainda',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no botão da câmera para começar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        return _buildPhotoCard(_photos[index]);
      },
    );
  }

  Widget _buildPhotoCard(PhotoItem photo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagem
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.file(
              File(photo.localPath),
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          
          // Informações
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status
                Row(
                  children: [
                    _buildStatusIcon(photo.status),
                    const SizedBox(width: 8),
                    Text(
                      _getStatusText(photo.status),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(photo.status),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Nome do arquivo
                Text(
                  '📁 ${photo.fileName}',
                  style: const TextStyle(fontSize: 13),
                ),
                
                // S3 Key (se upload foi sucesso)
                if (photo.s3Key != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '☁️ S3 Key: ${photo.s3Key}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                
                // Mensagem de erro (se falhou)
                if (photo.errorMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '❌ ${photo.errorMessage}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(UploadStatus status) {
    switch (status) {
      case UploadStatus.pending:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case UploadStatus.success:
        return const Icon(Icons.check_circle, color: Colors.green, size: 20);
      case UploadStatus.failed:
        return const Icon(Icons.error, color: Colors.red, size: 20);
    }
  }

  String _getStatusText(UploadStatus status) {
    switch (status) {
      case UploadStatus.pending:
        return 'Enviando...';
      case UploadStatus.success:
        return 'Salvo no S3!';
      case UploadStatus.failed:
        return 'Falha no upload';
    }
  }

  Color _getStatusColor(UploadStatus status) {
    switch (status) {
      case UploadStatus.pending:
        return Colors.orange;
      case UploadStatus.success:
        return Colors.green;
      case UploadStatus.failed:
        return Colors.red;
    }
  }
}

/// Status do upload de uma foto
enum UploadStatus { pending, success, failed }

/// Representa uma foto na lista
class PhotoItem {
  final String localPath;
  final String fileName;
  UploadStatus status;
  String? s3Url;
  String? s3Key;
  String? errorMessage;

  PhotoItem({
    required this.localPath,
    required this.fileName,
    required this.status,
    this.s3Url,
    this.s3Key,
    this.errorMessage,
  });
}
