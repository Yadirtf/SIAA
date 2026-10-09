// certificados_prueba.dart — Certificados X.509 reales (autofirmados) para probar el pinning.
// Generados con openssl; los pines esperados se calcularon con el comando de
// mobile/docs/certificate-pinning.md, de modo que la prueba valida contra openssl.
import 'dart:convert';
import 'dart:typed_data';

/// Certificado EC P-256 con CN=api.siaa.test.
final Uint8List certificadoEc = base64.decode(
  'MIIBhTCCASugAwIBAgIUb/fN45JUstLXFUr6lfoX9v25L7UwCgYIKoZIzj0EAwIw'
  'GDEWMBQGA1UEAwwNYXBpLnNpYWEudGVzdDAeFw0yNjEwMDkwNzAzMzRaFw0zNjEw'
  'MDYwNzAzMzRaMBgxFjAUBgNVBAMMDWFwaS5zaWFhLnRlc3QwWTATBgcqhkjOPQIB'
  'BggqhkjOPQMBBwNCAAQtzKIR49bJgjFNc3UQKT8yvRgfzIwGTFUrjsteX1DOBInf'
  'Xb0PZNW8t5x4QjCT7h9GcbWZwpXF5Ob5HII0esAfo1MwUTAdBgNVHQ4EFgQUq5BT'
  '6EglJzFyZyl/IlPcymA813swHwYDVR0jBBgwFoAUq5BT6EglJzFyZyl/IlPcymA8'
  '13swDwYDVR0TAQH/BAUwAwEB/zAKBggqhkjOPQQDAgNIADBFAiEA9s//3QpMKkfG'
  'lbZTThtf4FGU+YcM5XwTMOypEtuzLEsCID3ZHw7y4BX8LMCqVNfQh8l573DrhiXi'
  'q3N9EWH7qlgB',
);

/// Pin SPKI de [certificadoEc] según openssl.
const pinCertificadoEc = 'k9msxTKKK/XjwCskCyerTUjS7KttUHLmPXD4gHUhWbM=';

/// Certificado RSA 2048 con CN=otro (simula un certificado ajeno o de un atacante).
final Uint8List certificadoRsa = base64.decode(
  'MIIC/zCCAeegAwIBAgIUdm6LHa//SAu4osKTVvOf81DCvZswDQYJKoZIhvcNAQEL'
  'BQAwDzENMAsGA1UEAwwEb3RybzAeFw0yNjEwMDkwNzAzMzRaFw0zNjEwMDYwNzAz'
  'MzRaMA8xDTALBgNVBAMMBG90cm8wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK'
  'AoIBAQCu3wDHOrWiMAvfxykUTQM2eZ/17/I9I52K2+MMcuJB/KEwAWi+4BvGwRiC'
  'cZ3sfVCOUtYaF3PaGlW0iGSXKbfia5hw1DVNikxAxW2lFFEOsC7mq6HJApMVcTj/'
  'bO3XN3iGFwoQk5wTvr58zdXrVifAz5/4seu8utt6Rj6sl+fHV68iTfkTovrP9xHP'
  '/MK3w1sR6tag+45SvuSD6RE72LlBhgzqEE8wQN7n1WrO2b39yAQzYi8f45lzJaB7'
  'iqTMGgXlINGJZJUiW0JN4rDUyMaCccOAAi49WaWD8GxX/OoN+uyoXUTfCrFCigxx'
  'RRXF+EEMlqRkj0wmkZaFf66MXsKxAgMBAAGjUzBRMB0GA1UdDgQWBBRxNNDOVzJz'
  'QlclKo0wuo8LFhpHgDAfBgNVHSMEGDAWgBRxNNDOVzJzQlclKo0wuo8LFhpHgDAP'
  'BgNVHRMBAf8EBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQBUoKLdaaNWSwl/Iy3Y'
  'qXmzQeWTfp34F5i3VkLzkRaFd+ODV5OcT2SRxlgytPJHh7w78cC933CZuAlhI6El'
  '/5QjcUbuin/Tzi8jX8EFICfhfswHiH+ElxyzyQdjo6v6LV2CC1Y8hg5Q2nviYwiF'
  'VZQGi4o2ZzoRBTLQkKX9Nl3SsykAENuZCp5tD3/H27n2NbLaf0mV4XeO0cynK1Po'
  'Cv8sGGNmoxm8VXArFMd5C87Cw/nXQ+goZVh5OSnA49mv/3mq2ZI+qUmG9Zha4jU7'
  'QrD9/URh37LnUmQTjdE2s9kxckAT+Ob0C6q4VvRRYVnm45pMhdveK9tgeElgIJrc'
  'APzK',
);

/// Pin SPKI de [certificadoRsa] según openssl.
const pinCertificadoRsa = 'j2l9of4JbrLC7Kq2GgrE6MVRexKSuOEZAyn0/5v3L5A=';
