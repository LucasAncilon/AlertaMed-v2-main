class Patient {
  final int? id;
  final String name;
  final int age;
  final String? bloodType;
  final String? allergies;
  final String? emergencyContact;
  final String? caregiverName;
  final String? caregiverPhone;
  final String? notes;
  final bool isDemo;

  const Patient({
    this.id,
    required this.name,
    required this.age,
    this.bloodType,
    this.allergies,
    this.emergencyContact,
    this.caregiverName,
    this.caregiverPhone,
    this.notes,
    this.isDemo = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'age': age,
        'blood_type': bloodType,
        'allergies': allergies,
        'emergency_contact': emergencyContact,
        'caregiver_name': caregiverName,
        'caregiver_phone': caregiverPhone,
        'notes': notes,
        'is_demo': isDemo ? 1 : 0,
      };

  factory Patient.fromMap(Map<String, dynamic> map) => Patient(
        id: map['id'] as int?,
        name: map['name'] as String,
        age: map['age'] as int,
        bloodType: map['blood_type'] as String?,
        allergies: map['allergies'] as String?,
        emergencyContact: map['emergency_contact'] as String?,
        caregiverName: map['caregiver_name'] as String?,
        caregiverPhone: map['caregiver_phone'] as String?,
        notes: map['notes'] as String?,
        isDemo: (map['is_demo'] as int? ?? 0) == 1,
      );
}
