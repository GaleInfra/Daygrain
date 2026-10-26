import 'dart:html';
class JsUtils {
  static Future<File> blobUrlToFile(String blobUrl, String fileName) async {
    final request = await HttpRequest.request(
      blobUrl,
      responseType: 'blob',
    );
    final blob = request.response as Blob;
    return File([blob], fileName);
  }
}