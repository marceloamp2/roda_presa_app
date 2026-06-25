# Roda Presa App

App Flutter Android-first do Roda Presa.

## Configuração para publicar na Play Store

### 1. Application ID

O Android está configurado com o pacote:

```text
br.com.rodapresa
```

Esse identificador vira permanente depois do primeiro envio para a Play Store. Se quiser outro pacote, altere antes de publicar em `android/app/build.gradle.kts` e no pacote da `MainActivity`.

### 2. Chave de upload

Gere uma chave de upload localmente:

```bash
cd roda_presa_app/android
keytool -genkeypair \
  -v \
  -storetype JKS \
  -keystore app/upload-keystore.jks \
  -alias upload \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

Copie o arquivo de exemplo e preencha as senhas escolhidas:

```bash
cp key.properties.example key.properties
```

`android/key.properties` e `*.jks` são ignorados pelo git. Não envie esses arquivos para o repositório.

### 3. Google Sign-In

Antes de subir o release, configure no Google Cloud Console:

- um OAuth Client Android com package name `br.com.rodapresa`;
- o SHA-1 da chave de upload local;
- depois que a Play Store gerar a chave de assinatura do app, cadastre também o SHA-1 da Play App Signing;
- mantenha `GOOGLE_WEB_CLIENT_ID` em `.env` apontando para o Web Client usado pelo backend.

Para ver o SHA-1 da chave de upload:

```bash
cd roda_presa_app/android
keytool -list -v -keystore app/upload-keystore.jks -alias upload
```

### 4. Versão do app

A versão publicada vem de `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

Para cada novo envio à Play Store, aumente o número depois do `+` (`versionCode`).

### 5. Gerar o App Bundle

```bash
cd roda_presa_app
flutter pub get
flutter build appbundle --release
```

O arquivo para enviar no Play Console será gerado em:

```text
build/app/outputs/bundle/release/app-release.aab
```
