// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_call_box.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VideoCallBoxAdapter extends TypeAdapter<VideoCallBox> {
  @override
  final int typeId = 1;

  @override
  VideoCallBox read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VideoCallBox(
      id: fields[0] as int?,
      channelName: fields[1] as String,
      userId: fields[2] as String,
      nickname: fields[3] as String,
      avatar: fields[4] as String,
      callType: fields[5] as String,
      endTime: fields[6] as int,
      duration: fields[7] as int,
      isFromMatch: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, VideoCallBox obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.channelName)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.nickname)
      ..writeByte(4)
      ..write(obj.avatar)
      ..writeByte(5)
      ..write(obj.callType)
      ..writeByte(6)
      ..write(obj.endTime)
      ..writeByte(7)
      ..write(obj.duration)
      ..writeByte(8)
      ..write(obj.isFromMatch);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoCallBoxAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
