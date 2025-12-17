#!/bin/bash

# Criar o bucket S3 para armazenar fotos
awslocal s3 mb s3://shopping-images

echo "Bucket shopping-images criado com sucesso!"

# Listar buckets para confirmar
awslocal s3 ls
