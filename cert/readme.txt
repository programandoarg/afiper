openssl genrsa -out programandoHomologacion2024.key 2048
openssl req -new -key programandoHomologacion2024.key -subj "/C=AR/O=programandoHomologacion2024/CN=programando/serialNumber=CUIT 20351404478" -out programandoHomologacion2024.csr
