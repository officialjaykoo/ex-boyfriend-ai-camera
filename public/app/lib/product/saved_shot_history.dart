import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/camera_modes.dart';

class SavedShotRecord {
  const SavedShotRecord({
    required this.id,
    required this.path,
    required this.shotMode,
    required this.capturedAt,
    required this.compositionScore,
    required this.compositionCue,
    required this.hadReliableEstimate,
    this.bodyCenterX,
    this.faceCenterY,
    this.eyeLineY,
    this.footLineY,
    this.horizonTiltDeg,
    this.subjectConfidence,
    this.poseConfidence,
    this.autoCaptured = false,
    this.liked,
  });

  final String id;
  final String path;
  final ShotMode shotMode;
  final DateTime capturedAt;
  final int? compositionScore;
  final String compositionCue;
  final bool hadReliableEstimate;
  final double? bodyCenterX;
  final double? faceCenterY;
  final double? eyeLineY;
  final double? footLineY;
  final double? horizonTiltDeg;
  final double? subjectConfidence;
  final double? poseConfidence;
  final bool autoCaptured;
  final bool? liked;

  SavedShotRecord copyWith({bool? liked}) {
    return SavedShotRecord(
      id: id,
      path: path,
      shotMode: shotMode,
      capturedAt: capturedAt,
      compositionScore: compositionScore,
      compositionCue: compositionCue,
      hadReliableEstimate: hadReliableEstimate,
      bodyCenterX: bodyCenterX,
      faceCenterY: faceCenterY,
      eyeLineY: eyeLineY,
      footLineY: footLineY,
      horizonTiltDeg: horizonTiltDeg,
      subjectConfidence: subjectConfidence,
      poseConfidence: poseConfidence,
      autoCaptured: autoCaptured,
      liked: liked ?? this.liked,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'path': path,
      'shotMode': shotMode.name,
      'capturedAt': capturedAt.toIso8601String(),
      'compositionScore': compositionScore,
      'compositionCue': compositionCue,
      'hadReliableEstimate': hadReliableEstimate,
      'bodyCenterX': bodyCenterX,
      'faceCenterY': faceCenterY,
      'eyeLineY': eyeLineY,
      'footLineY': footLineY,
      'horizonTiltDeg': horizonTiltDeg,
      'subjectConfidence': subjectConfidence,
      'poseConfidence': poseConfidence,
      'autoCaptured': autoCaptured,
      'liked': liked,
    };
  }

  static SavedShotRecord? fromJson(Map<String, Object?> json) {
    final id = json['id'] as String?;
    final path = json['path'] as String?;
    final modeName = json['shotMode'] as String?;
    final capturedAtText = json['capturedAt'] as String?;
    if (id == null ||
        path == null ||
        modeName == null ||
        capturedAtText == null) {
      return null;
    }
    ShotMode? shotMode;
    for (final mode in ShotMode.values) {
      if (mode.name == modeName) {
        shotMode = mode;
        break;
      }
    }
    final capturedAt = DateTime.tryParse(capturedAtText);
    if (shotMode == null || capturedAt == null) return null;

    return SavedShotRecord(
      id: id,
      path: path,
      shotMode: shotMode,
      capturedAt: capturedAt,
      compositionScore: (json['compositionScore'] as num?)?.toInt(),
      compositionCue: json['compositionCue'] as String? ?? '',
      hadReliableEstimate: json['hadReliableEstimate'] == true,
      bodyCenterX: (json['bodyCenterX'] as num?)?.toDouble(),
      faceCenterY: (json['faceCenterY'] as num?)?.toDouble(),
      eyeLineY: (json['eyeLineY'] as num?)?.toDouble(),
      footLineY: (json['footLineY'] as num?)?.toDouble(),
      horizonTiltDeg: (json['horizonTiltDeg'] as num?)?.toDouble(),
      subjectConfidence: (json['subjectConfidence'] as num?)?.toDouble(),
      poseConfidence: (json['poseConfidence'] as num?)?.toDouble(),
      autoCaptured: json['autoCaptured'] == true,
      liked: json['liked'] as bool?,
    );
  }
}

class SavedShotHistoryStore {
  const SavedShotHistoryStore({
    this.preferenceKey = 'exbf.camera.savedShotHistory',
    this.maxRecords = 60,
  });

  final String preferenceKey;
  final int maxRecords;

  Future<List<SavedShotRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(preferenceKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map(
          (item) => SavedShotRecord.fromJson(Map<String, Object?>.from(item)),
        )
        .whereType<SavedShotRecord>()
        .toList(growable: false);
  }

  Future<void> add(SavedShotRecord record) async {
    final records = [record, ...await load()].take(maxRecords).toList();
    await _save(records);
  }

  Future<void> markFeedback(String id, {required bool liked}) async {
    final records = await load();
    await _save([
      for (final record in records)
        if (record.id == id) record.copyWith(liked: liked) else record,
    ]);
  }

  Future<void> _save(List<SavedShotRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      preferenceKey,
      jsonEncode(records.map((record) => record.toJson()).toList()),
    );
  }
}
