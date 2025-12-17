const AWS = require('aws-sdk');

// Detectar se está rodando dentro do container ou externamente
const isRunningInContainer = process.env.LOCALSTACK_HOSTNAME || process.env.HOSTNAME?.includes('localstack');
const s3Endpoint = isRunningInContainer 
  ? 'http://localstack:4566' 
  : (process.env.LOCALSTACK_ENDPOINT || 'http://localhost:4566');

const s3 = new AWS.S3({
  endpoint: s3Endpoint,
  s3ForcePathStyle: true,
  accessKeyId: process.env.AWS_ACCESS_KEY_ID || 'test',
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || 'test',
  region: process.env.AWS_DEFAULT_REGION || 'us-east-1'
});

const BUCKET_NAME = 'shopping-images';

// Headers CORS padrão
const corsHeaders = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
  'Access-Control-Allow-Methods': 'POST,OPTIONS'
};

/**
 * Upload de foto para S3
 * Recebe: { base64Data, fileName }
 */
exports.handler = async (event) => {
  console.log('Upload handler called:', JSON.stringify(event, null, 2));
  console.log('S3 Endpoint:', s3Endpoint);

  // Handle CORS preflight
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers: corsHeaders,
      body: ''
    };
  }

  try {
    const body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
    
    if (!body || !body.base64Data || !body.fileName) {
      return {
        statusCode: 400,
        headers: corsHeaders,
        body: JSON.stringify({ error: 'base64Data e fileName são obrigatórios' })
      };
    }

    // Converter base64 para buffer
    const buffer = Buffer.from(body.base64Data, 'base64');
    const fileKey = `photos/${Date.now()}-${body.fileName}`;
    
    console.log('Uploading to S3:', { bucket: BUCKET_NAME, key: fileKey, size: buffer.length });
    
    // Fazer upload para S3
    const params = {
      Bucket: BUCKET_NAME,
      Key: fileKey,
      Body: buffer,
      ContentType: body.contentType || 'image/jpeg'
    };

    const result = await s3.upload(params).promise();
    console.log('Upload successful:', result);

    // Gerar URL pública acessível externamente
    const publicUrl = `http://localhost:4566/${BUCKET_NAME}/${fileKey}`;

    return {
      statusCode: 200,
      headers: corsHeaders,
      body: JSON.stringify({
        success: true,
        message: 'Foto enviada com sucesso!',
        url: publicUrl,
        key: fileKey,
        bucket: BUCKET_NAME
      })
    };

  } catch (error) {
    console.error('Erro ao fazer upload:', error);
    return {
      statusCode: 500,
      headers: corsHeaders,
      body: JSON.stringify({ 
        error: 'Erro ao fazer upload da foto',
        details: error.message 
      })
    };
  }
};
