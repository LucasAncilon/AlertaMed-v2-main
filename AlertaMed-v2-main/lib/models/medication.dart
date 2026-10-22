class Medication {
  final int? id;
  final int patientId;
  final String name;
  final String dosage;
  final String schedule;
  final String frequency;
  final String notes;
  final String photoPath;
  final String notificationTime;
  final bool voiceReminder;

  const Medication({
    this.id,
    this.patientId = 1,
    required this.name,
    required this.dosage,
    required this.schedule,
    this.frequency = '',
    this.notes = '',
    this.photoPath = '',
    this.notificationTime = '',
    this.voiceReminder = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'patient_id': patientId,
        'name': name,
        'dosage': dosage,
        'schedule': schedule,
        'frequency': frequency,
        'notes': notes,
        'photo_path': photoPath,
        'notification_time': notificationTime,
        'voice_reminder': voiceReminder ? 1 : 0,
      };

  factory Medication.fromMap(Map<String, dynamic> map) => Medication(
        id: map['id'] as int?,
        patientId: (map['patient_id'] as int?) ?? 1,
        name: map['name'] as String,
        dosage: map['dosage'] as String,
        schedule: map['schedule'] as String,
        frequency: (map['frequency'] as String?) ?? '',
        notes: (map['notes'] as String?) ?? '',
        photoPath: (map['photo_path'] as String?) ?? '',
        notificationTime: (map['notification_time'] as String?) ?? '',
        voiceReminder: ((map['voice_reminder'] as int?) ?? 0) == 1,
      );
}
