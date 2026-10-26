class UploadOssModel {
  UploadOssModel({
    this.filename,
    this.size,
    this.mimeType,
    this.width,
    this.height,
  });

  UploadOssModel.fromJson(dynamic json) {
    filename = json['filename'];
    size = json['size'];
    mimeType = json['mimeType'];
    width = json['width'];
    height = json['height'];
  }

  String? filename;
  String? size;
  String? mimeType;
  String? width;
  String? height;

  UploadOssModel copyWith({
    String? filename,
    String? size,
    String? mimeType,
    String? width,
    String? height,
  }) =>
      UploadOssModel(
        filename: filename ?? this.filename,
        size: size ?? this.size,
        mimeType: mimeType ?? this.mimeType,
        width: width ?? this.width,
        height: height ?? this.height,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['filename'] = filename;
    map['size'] = size;
    map['mimeType'] = mimeType;
    map['width'] = width;
    map['height'] = height;
    return map;
  }
}
