import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/camera_modes.dart';

const defaultScoreWeights = <String, double>{
  'subjectPosition': 0.23,
  'facePosition': 0.19,
  'eyeLine': 0.18,
  'horizon': 0.14,
  'footSafety': 0.10,
  'limbSafety': 0.09,
  'detectionConfidence': 0.07,
};

class CompositionRuleSet {
  const CompositionRuleSet({
    required this.guideType,
    required this.bodyCenterX,
    required this.faceCenterY,
    required this.eyeLineY,
    required this.footLineY,
    required this.headroom,
    required this.horizonY,
    required this.autoCaptureThreshold,
    this.scoreWeights = defaultScoreWeights,
    this.checklist = const [],
    this.guideAnchors = const [],
    this.captureAdvice = const [],
    this.teacherNotes = const [],
    this.sources = const [],
  });

  final String guideType;
  final double bodyCenterX;
  final double faceCenterY;
  final double eyeLineY;
  final double footLineY;
  final double headroom;
  final double horizonY;
  final int autoCaptureThreshold;
  final Map<String, double> scoreWeights;
  final List<String> checklist;
  final List<String> guideAnchors;
  final List<String> captureAdvice;
  final List<String> teacherNotes;
  final List<String> sources;

  factory CompositionRuleSet.fromJson(Map<String, dynamic> json) {
    return CompositionRuleSet(
      guideType: json['guideType'] as String? ?? 'people_eye_thirds',
      bodyCenterX: (json['bodyCenterX'] as num).toDouble(),
      faceCenterY: (json['faceCenterY'] as num).toDouble(),
      eyeLineY: (json['eyeLineY'] as num).toDouble(),
      footLineY: (json['footLineY'] as num).toDouble(),
      headroom: (json['headroom'] as num).toDouble(),
      horizonY: (json['horizonY'] as num).toDouble(),
      autoCaptureThreshold: (json['autoCaptureThreshold'] as num).toInt(),
      scoreWeights: _readScoreWeights(json['scoreWeights']),
      checklist: List<String>.from(json['checklist'] as List? ?? const []),
      guideAnchors: List<String>.from(
        json['guideAnchors'] as List? ?? const [],
      ),
      captureAdvice: List<String>.from(
        json['captureAdvice'] as List? ?? const [],
      ),
      teacherNotes: List<String>.from(
        json['teacherNotes'] as List? ?? const [],
      ),
      sources: List<String>.from(json['sources'] as List? ?? const []),
    );
  }

  double scoreWeight(String key) {
    final total = scoreWeights.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    if (total <= 0) return defaultScoreWeights[key] ?? 0;
    return (scoreWeights[key] ?? defaultScoreWeights[key] ?? 0) / total;
  }
}

Map<String, double> _readScoreWeights(Object? raw) {
  if (raw is! Map) return defaultScoreWeights;
  return {
    for (final entry in defaultScoreWeights.entries)
      entry.key: (raw[entry.key] as num?)?.toDouble() ?? entry.value,
  };
}

class CompositionRuleDocument {
  const CompositionRuleDocument({
    required this.version,
    required this.pipeline,
    required this.modes,
  });

  final int version;
  final String pipeline;
  final Map<ShotMode, CompositionRuleSet> modes;

  factory CompositionRuleDocument.fromJson(Map<String, dynamic> json) {
    final modesJson = json['modes'] as Map<String, dynamic>;
    return CompositionRuleDocument(
      version: (json['version'] as num?)?.toInt() ?? 1,
      pipeline: json['pipeline'] as String? ?? 'unknown',
      modes: modesJson.map((key, value) {
        return MapEntry(
          shotModeFromJsonKey(key),
          CompositionRuleSet.fromJson(value as Map<String, dynamic>),
        );
      }),
    );
  }
}

ShotMode shotModeFromJsonKey(String key) {
  return switch (key) {
    'portrait' || 'people' || 'date' => ShotMode.portrait,
    'selfie' => ShotMode.selfie,
    'group' || 'couple' || 'twoPerson' => ShotMode.group,
    'landscape' || 'travel' => ShotMode.landscape,
    'stillLife' || 'still_life' || 'food' || 'cafe' => ShotMode.stillLife,
    'object' || 'subject' => ShotMode.object,
    'candid' || 'street' || 'feature' => ShotMode.candid,
    'lowLight' || 'low_light' || 'night' => ShotMode.lowLight,
    _ => ShotMode.portrait,
  };
}

Future<CompositionRuleDocument> loadCompositionRuleDocumentFromAsset({
  String assetPath = 'assets/rules/composition_rules.json',
}) async {
  final raw = await rootBundle.loadString(assetPath);
  return CompositionRuleDocument.fromJson(
    jsonDecode(raw) as Map<String, dynamic>,
  );
}

const Map<ShotMode, CompositionRuleSet> compositionRules = {
  ShotMode.portrait: CompositionRuleSet(
    guideType: 'people_eye_thirds',
    bodyCenterX: 0.42,
    faceCenterY: 0.30,
    eyeLineY: 0.34,
    footLineY: 0.92,
    headroom: 0.08,
    horizonY: 0.48,
    autoCaptureThreshold: 86,
    scoreWeights: {
      'subjectPosition': 0.18,
      'facePosition': 0.22,
      'eyeLine': 0.22,
      'horizon': 0.08,
      'footSafety': 0.10,
      'limbSafety': 0.12,
      'detectionConfidence': 0.08,
    },
    captureAdvice: ['카메라를 눈높이에 맞춰요', '머리 위 여백을 조금 줄여요', '손발이 잘리지 않게 뒤로 빼요'],
  ),
  ShotMode.selfie: CompositionRuleSet(
    guideType: 'people_eye_thirds',
    bodyCenterX: 0.50,
    faceCenterY: 0.38,
    eyeLineY: 0.34,
    footLineY: 0.76,
    headroom: 0.10,
    horizonY: 0.52,
    autoCaptureThreshold: 84,
    scoreWeights: {
      'subjectPosition': 0.16,
      'facePosition': 0.28,
      'eyeLine': 0.24,
      'horizon': 0.06,
      'footSafety': 0.04,
      'limbSafety': 0.08,
      'detectionConfidence': 0.14,
    },
    captureAdvice: ['카메라를 눈보다 살짝 위로', '아래로 살짝 기울여요', '턱 아래에서 올려찍지 않게'],
  ),
  ShotMode.group: CompositionRuleSet(
    guideType: 'group_people',
    bodyCenterX: 0.50,
    faceCenterY: 0.32,
    eyeLineY: 0.35,
    footLineY: 0.88,
    headroom: 0.10,
    horizonY: 0.50,
    autoCaptureThreshold: 86,
    scoreWeights: {
      'subjectPosition': 0.24,
      'facePosition': 0.20,
      'eyeLine': 0.18,
      'horizon': 0.08,
      'footSafety': 0.08,
      'limbSafety': 0.12,
      'detectionConfidence': 0.10,
    },
    captureAdvice: ['두 얼굴 높이를 맞춰요', '두 사람이 조금 더 붙어요', '카메라를 두 사람 중앙에 맞춰요'],
  ),
  ShotMode.landscape: CompositionRuleSet(
    guideType: 'horizon_thirds',
    bodyCenterX: 0.50,
    faceCenterY: 0.30,
    eyeLineY: 0.33,
    footLineY: 0.92,
    headroom: 0.08,
    horizonY: 0.38,
    autoCaptureThreshold: 88,
    scoreWeights: {
      'subjectPosition': 0.18,
      'facePosition': 0.08,
      'eyeLine': 0.08,
      'horizon': 0.38,
      'footSafety': 0.06,
      'limbSafety': 0.04,
      'detectionConfidence': 0.18,
    },
    captureAdvice: ['카메라 각도를 바로 세워요', '지평선을 위아래 1/3에 맞춰요', '길이나 선이 안쪽으로 이어지게 해요'],
  ),
  ShotMode.stillLife: CompositionRuleSet(
    guideType: 'subject_thirds',
    bodyCenterX: 0.50,
    faceCenterY: 0.46,
    eyeLineY: 0.46,
    footLineY: 0.86,
    headroom: 0.12,
    horizonY: 0.50,
    autoCaptureThreshold: 84,
    scoreWeights: {
      'subjectPosition': 0.36,
      'facePosition': 0.22,
      'eyeLine': 0.10,
      'horizon': 0.06,
      'footSafety': 0.06,
      'limbSafety': 0.00,
      'detectionConfidence': 0.20,
    },
    captureAdvice: ['피사체가 주인공처럼 보이게 해요', '카메라를 살짝 위에서 내려봐요', '주변 소품을 덜어내요'],
  ),
  ShotMode.object: CompositionRuleSet(
    guideType: 'subject_viewpoint',
    bodyCenterX: 0.46,
    faceCenterY: 0.44,
    eyeLineY: 0.44,
    footLineY: 0.86,
    headroom: 0.12,
    horizonY: 0.50,
    autoCaptureThreshold: 85,
    scoreWeights: {
      'subjectPosition': 0.38,
      'facePosition': 0.22,
      'eyeLine': 0.08,
      'horizon': 0.06,
      'footSafety': 0.06,
      'limbSafety': 0.00,
      'detectionConfidence': 0.20,
    },
    captureAdvice: ['사물이 프레임을 더 채우게 해요', '배경 여백을 깨끗하게 비워요', '정면이나 45도로 각도를 정리해요'],
  ),
  ShotMode.candid: CompositionRuleSet(
    guideType: 'candid_people',
    bodyCenterX: 0.42,
    faceCenterY: 0.32,
    eyeLineY: 0.35,
    footLineY: 0.86,
    headroom: 0.10,
    horizonY: 0.48,
    autoCaptureThreshold: 86,
    scoreWeights: {
      'subjectPosition': 0.22,
      'facePosition': 0.18,
      'eyeLine': 0.14,
      'horizon': 0.08,
      'footSafety': 0.08,
      'limbSafety': 0.12,
      'detectionConfidence': 0.18,
    },
    captureAdvice: ['움직이는 방향 앞을 비워요', '표정이나 손동작이 보이게 해요', '배경이 복잡하면 한 걸음 옮겨요'],
  ),
  ShotMode.lowLight: CompositionRuleSet(
    guideType: 'stable_level',
    bodyCenterX: 0.44,
    faceCenterY: 0.33,
    eyeLineY: 0.36,
    footLineY: 0.90,
    headroom: 0.10,
    horizonY: 0.48,
    autoCaptureThreshold: 90,
    scoreWeights: {
      'subjectPosition': 0.18,
      'facePosition': 0.16,
      'eyeLine': 0.12,
      'horizon': 0.22,
      'footSafety': 0.06,
      'limbSafety': 0.08,
      'detectionConfidence': 0.18,
    },
    captureAdvice: ['카메라를 몸에 붙여 고정해요', '밝은 간판은 얼굴 뒤에서 빼요', '수평을 맞춘 뒤 잠깐 멈춰요'],
  ),
};
