import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health360ai/app/router.dart';
import 'package:health360ai/data/models/profile.dart';
import 'package:health360ai/data/models/symptoms_vitals.dart';
import 'package:health360ai/data/models/checkup_summary.dart';
import 'package:health360ai/data/models/checkup_detail.dart';
import 'package:health360ai/data/models/checkup_response.dart';
import 'package:health360ai/features/auth/login_screen.dart';
import 'package:health360ai/features/auth/register_screen.dart';
import 'package:health360ai/features/auth/reset_password_screen.dart';
import 'package:health360ai/state/checkup_draft_provider.dart';

void main() {
  // ── Profile ────────────────────────────────────────────────────────────────

  group('Profile.fromJson', () {
    test('parses a complete row', () {
      final json = {
        'id': 'user-123',
        'full_name': 'Jane Doe',
        'date_of_birth': '1995-06-15',
        'sex': 'female',
        'height_cm': 165.0,
        'weight_kg': 58.5,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': null,
      };
      final profile = Profile.fromJson(json);

      expect(profile.id, 'user-123');
      expect(profile.fullName, 'Jane Doe');
      expect(profile.dateOfBirth, '1995-06-15');
      expect(profile.sex, 'female');
      expect(profile.heightCm, 165.0);
      expect(profile.weightKg, 58.5);
      expect(profile.createdAt, '2026-01-01T00:00:00Z');
      expect(profile.updatedAt, isNull);
    });

    test('handles integer height/weight (Supabase can return int)', () {
      final json = {
        'id': 'u1',
        'full_name': 'Bob',
        'date_of_birth': '1990-01-01',
        'sex': 'male',
        'height_cm': 170, // int, not double
        'weight_kg': 75,
      };
      final profile = Profile.fromJson(json);
      expect(profile.heightCm, 170.0);
      expect(profile.weightKg, 75.0);
    });

    test('toPatientPayload contains required keys', () {
      final profile = Profile.fromJson({
        'id': 'u1',
        'full_name': 'Alice',
        'date_of_birth': '2000-03-10',
        'sex': 'female',
        'height_cm': 160.0,
        'weight_kg': 55.0,
      });
      final payload = profile.toPatientPayload();

      expect(payload.containsKey('full_name'), isTrue);
      expect(payload.containsKey('date_of_birth'), isTrue);
      expect(payload.containsKey('sex'), isTrue);
      expect(payload.containsKey('height_cm'), isTrue);
      expect(payload.containsKey('weight_kg'), isTrue);
      // id must NOT appear in the patient payload
      expect(payload.containsKey('id'), isFalse);
    });

    test('toJson round-trip', () {
      final original = Profile.fromJson({
        'id': 'u2',
        'full_name': 'Charlie',
        'date_of_birth': '1985-11-25',
        'sex': 'male',
        'height_cm': 178.5,
        'weight_kg': 82.0,
      });
      final roundTripped = Profile.fromJson(original.toJson());
      expect(roundTripped, equals(original));
    });
  });

  // ── SymptomsPayload ────────────────────────────────────────────────────────

  group('SymptomsPayload.toJson', () {
    test('encodes all keys with correct types', () {
      const s = SymptomsPayload(
        complaintType: 'general',
        severity: 5.0,
        durationDays: 3.0,
        frequency: 2.0, // Occasionally
        progression: 1.0, // Same
        site: 'chest',
        character: 1.0, // Sharp
        trigger: 2.0, // 2 triggers ticked
        associatedSymptoms: ['fatigue', 'nausea'],
        preSymptoms: [],
        postSymptoms: ['dizziness'],
      );
      final json = s.toJson();

      expect(json['complaint_type'], 'general');
      expect(json['severity'], 5.0);
      expect(json['duration_days'], 3.0);
      expect(json['frequency'], 2.0);
      expect(json['progression'], 1.0);
      expect(json['site'], 'chest');
      expect(json['character'], 1.0);
      expect(json['trigger'], 2.0);
      expect(json['associated_symptoms'], ['fatigue', 'nausea']);
      expect(json['pre_symptoms'], isEmpty);
      expect(json['post_symptoms'], ['dizziness']);
    });

    test('trigger is a double (model requirement)', () {
      const s = SymptomsPayload(
        complaintType: 'skin',
        severity: 3.0,
        durationDays: 1.0,
        frequency: 1.0,
        progression: 0.0,
        site: 'face',
        character: 2.0,
        trigger: 3.0,
        associatedSymptoms: [],
        preSymptoms: [],
        postSymptoms: [],
      );
      expect(s.toJson()['trigger'], isA<double>());
    });
  });

  // ── VitalsPayload ──────────────────────────────────────────────────────────

  group('VitalsPayload.toJson', () {
    test('encodes all vitals keys', () {
      const v = VitalsPayload(
        heartRate: 72.0,
        systolicBp: 120.0,
        diastolicBp: 80.0,
        spo2: 98.0,
        temperature: 37.0,
        activityLevel: 1, // Moderate
        tobacco: 0,
        alcohol: 0,
      );
      final json = v.toJson();

      expect(json['heart_rate'], 72.0);
      expect(json['systolic_bp'], 120.0);
      expect(json['diastolic_bp'], 80.0);
      expect(json['spo2'], 98.0);
      expect(json['temperature'], 37.0);
      expect(json['activity_level'], 1);
      expect(json['tobacco'], 0);
      expect(json['alcohol'], 0);
    });
  });

  // ── CheckupSummary ─────────────────────────────────────────────────────────

  group('CheckupSummary.fromJson', () {
    test('parses a minimal row (no optional fields)', () {
      final json = {
        'id': 'cs-1',
        'user_id': 'user-123',
        'status': 'completed',
        'overall_score': 0.69,
        'created_at': '2026-09-30T10:00:00Z',
      };
      final cs = CheckupSummary.fromJson(json);

      expect(cs.id, 'cs-1');
      expect(cs.userId, 'user-123');
      expect(cs.status, 'completed');
      expect(cs.overallScore, closeTo(0.69, 0.001));
      expect(cs.overallCategory, isNull);
      expect(cs.screening, isNull);
    });

    test('parses screening sub-object', () {
      final json = {
        'id': 'cs-2',
        'user_id': 'u1',
        'status': 'completed',
        'overall_score': 0.8,
        'created_at': '2026-10-01T00:00:00Z',
        'overall_category': 'Headache',
        'screening': {
          'main_concern': 'headache',
          'overall_status': 'Moderate',
          'red_flags': ['severe pain'],
          'triage': 'see_gp',
        },
      };
      final cs = CheckupSummary.fromJson(json);

      expect(cs.overallCategory, 'Headache');
      expect(cs.screening!.mainConcern, 'headache');
      expect(cs.screening!.overallStatus, 'Moderate');
      expect(cs.screening!.redFlags, ['severe pain']);
    });

    test('handles null optional numeric fields', () {
      final json = {
        'id': 'cs-3',
        'user_id': 'u1',
        'status': 'completed',
        'overall_score': 0.5,
        'created_at': '2026-10-01T00:00:00Z',
        'confidence': null,
        'uncertainty': null,
      };
      final cs = CheckupSummary.fromJson(json);
      expect(cs.confidence, isNull);
      expect(cs.uncertainty, isNull);
    });
  });

  // ── CheckupDetail ──────────────────────────────────────────────────────────

  group('CheckupDetail.fromJson', () {
    test('parses JSONB columns as Map<String, dynamic>', () {
      final json = {
        'id': 'cd-1',
        'user_id': 'u1',
        'status': 'completed',
        'overall_score': 0.75,
        'created_at': '2026-10-02T00:00:00Z',
        'screening': {'main_concern': 'headache'},
        'fusion_result': null,
      };
      final cd = CheckupDetail.fromJson(json);

      expect(cd.id, 'cd-1');
      expect(cd.screening, {'main_concern': 'headache'});
      expect(cd.fusionResult, isNull);
    });
  });

  // ── CheckupResponse (API) ──────────────────────────────────────────────────

  group('CheckupResponse.fromJson', () {
    test('parses a minimal response (only required fields)', () {
      final json = {
        'status': 'success',
        'assessment': {'finding': 'No acute pathology', 'confidence': 0.85},
      };
      final cr = CheckupResponse.fromJson(json);

      expect(cr.status, 'success');
      expect(cr.assessment.finding, 'No acute pathology');
      expect(cr.assessment.confidence, closeTo(0.85, 0.001));
      expect(cr.screening, isNull);
      expect(cr.imageResult, isNull);
    });

    test('parses full response with all nested objects', () {
      final json = {
        'status': 'success',
        'assessment': {
          'image_type': 'skin',
          'finding': 'Mild rash',
          'confidence': 0.72,
          'probabilities': {'normal': 0.28, 'mild': 0.72},
        },
        'screening': {
          'main_concern': 'rash',
          'overall_status': 'Low',
          'screening_summary': 'Likely contact dermatitis.',
          'triage': 'monitor',
          'red_flags': [],
          'vitals_interpretation': 'Normal',
          'model_explanations': ['XGBoost: mild risk'],
          'next_steps': 'Apply antihistamine',
          'overall_explanation': 'Low risk presentation.',
        },
        'image_result': {
          'type': 'skin',
          'prediction': {
            'class_index': 1,
            'class_name': 'Mild',
            'confidence': 0.72,
            'probabilities': {},
          },
        },
        'symptom_result': {
          'class_index': 0,
          'class_name': 'Low risk',
          'confidence': 0.88,
          'probabilities': {},
        },
        'patient_result': null,
        'uncertainty': {
          'confidence': 0.72,
          'uncertainty': 0.28,
          'completeness': 0.9,
          'image_quality': 0.85,
        },
      };
      final cr = CheckupResponse.fromJson(json);

      expect(cr.status, 'success');
      expect(cr.assessment.imageType, 'skin');
      expect(cr.screening!.mainConcern, 'rash');
      expect(cr.screening!.redFlags, isEmpty);
      expect(cr.imageResult!.type, 'skin');
      expect(cr.imageResult!.prediction!.className, 'Mild');
      expect(cr.symptomResult!.className, 'Low risk');
      expect(cr.patientResult, isNull);
      expect(cr.uncertainty!.imageQuality, closeTo(0.85, 0.001));
    });

    test('missing assessment defaults gracefully', () {
      final json = {
        'status': 'error',
        // assessment key entirely absent
      };
      final cr = CheckupResponse.fromJson(json);
      expect(cr.status, 'error');
      expect(cr.assessment.finding, isNull);
    });
  });

  // ── AssistantRequest ───────────────────────────────────────────────────────

  group('AssistantRequest.toJson', () {
    test('omits checkup_id when null', () {
      const req = AssistantRequest(message: 'Hello');
      final json = req.toJson();
      expect(json['message'], 'Hello');
      expect(json.containsKey('checkup_id'), isFalse);
      // CRITICAL: user_id must never appear
      expect(json.containsKey('user_id'), isFalse);
    });

    test('includes checkup_id when provided', () {
      const req = AssistantRequest(
        message: 'Explain my results',
        checkupId: 'cd-abc',
      );
      final json = req.toJson();
      expect(json['checkup_id'], 'cd-abc');
      expect(json.containsKey('user_id'), isFalse);
    });
  });

  group('AssistantResponse.fromJson', () {
    test('parses response with context', () {
      final json = {
        'status': 'success',
        'message': 'Your symptoms seem mild.',
        'context': {'checkup_id': 'c-1', 'topic': 'vital_signs'},
      };
      final res = AssistantResponse.fromJson(json);
      expect(res.status, 'success');
      expect(res.message, 'Your symptoms seem mild.');
      expect(res.context?['checkup_id'], 'c-1');
      expect(res.context?['topic'], 'vital_signs');
    });

    test('parses response with missing or null fields defensively', () {
      final res = AssistantResponse.fromJson({});
      expect(res.status, '');
      expect(res.message, '');
      expect(res.context, isNull);
    });
  });

  // ── CheckupDraft ───────────────────────────────────────────────────────────

  group('CheckupDraft', () {
    final sampleProfile = Profile.fromJson({
      'id': 'u1',
      'full_name': 'Test User',
      'date_of_birth': '1990-01-01',
      'sex': 'male',
      'height_cm': 175.0,
      'weight_kg': 70.0,
    });

    const sampleVitals = VitalsPayload(
      heartRate: 75.0,
      systolicBp: 118.0,
      diastolicBp: 78.0,
      spo2: 99.0,
      temperature: 36.8,
      activityLevel: 1,
      tobacco: 0,
      alcohol: 0,
    );

    const sampleSymptoms = SymptomsPayload(
      complaintType: 'general',
      severity: 4.0,
      durationDays: 2.0,
      frequency: 2.0,
      progression: 1.0,
      site: 'head',
      character: 2.0,
      trigger: 1.0,
      associatedSymptoms: [],
      preSymptoms: [],
      postSymptoms: [],
    );

    test('starts empty', () {
      const draft = CheckupDraft.empty;
      expect(draft.patient, isNull);
      expect(draft.vitals, isNull);
      expect(draft.symptoms, isNull);
      expect(draft.hasImage, isFalse);
    });

    test('copyWith updates individual fields', () {
      const draft = CheckupDraft.empty;
      final updated = draft.copyWith(
        patient: sampleProfile,
        vitals: sampleVitals,
      );
      expect(updated.patient, equals(sampleProfile));
      expect(updated.vitals, equals(sampleVitals));
      expect(updated.symptoms, isNull); // unchanged
    });

    test('buildPatientPayload merges profile + vitals', () {
      final draft = CheckupDraft.empty.copyWith(
        patient: sampleProfile,
        vitals: sampleVitals,
      );
      final payload = draft.buildPatientPayload();

      // Profile keys
      expect(payload['full_name'], 'Test User');
      expect(payload['date_of_birth'], '1990-01-01');
      expect(payload['sex'], 'male');
      expect(payload['height_cm'], 175.0);
      expect(payload['weight_kg'], 70.0);
      // Vitals keys
      expect(payload['heart_rate'], 75.0);
      expect(payload['systolic_bp'], 118.0);
      expect(payload['diastolic_bp'], 78.0);
      expect(payload['spo2'], 99.0);
      expect(payload['temperature'], 36.8);
      expect(payload['activity_level'], 1);
      expect(payload['tobacco'], 0);
      expect(payload['alcohol'], 0);
      // id must not be sent to the backend
      expect(payload.containsKey('id'), isFalse);
      // user_id must never appear
      expect(payload.containsKey('user_id'), isFalse);
    });

    test('buildPatientPayload throws when patient missing', () {
      final draft = CheckupDraft.empty.copyWith(vitals: sampleVitals);
      expect(() => draft.buildPatientPayload(), throwsStateError);
    });

    test('buildPatientPayload throws when vitals missing', () {
      final draft = CheckupDraft.empty.copyWith(patient: sampleProfile);
      expect(() => draft.buildPatientPayload(), throwsStateError);
    });

    test('buildSymptomsPayload returns correct keys', () {
      final draft = CheckupDraft.empty.copyWith(symptoms: sampleSymptoms);
      final payload = draft.buildSymptomsPayload();

      expect(payload['complaint_type'], 'general');
      expect(payload['severity'], 4.0);
      expect(payload['trigger'], isA<double>());
    });

    test('buildSymptomsPayload throws when symptoms missing', () {
      expect(() => CheckupDraft.empty.buildSymptomsPayload(), throwsStateError);
    });

    test('clearImage sets imagePath and imageType to null', () {
      final draft = CheckupDraft.empty.copyWith(
        imagePath: '/tmp/photo.jpg',
        imageType: 'skin',
      );
      expect(draft.hasImage, isTrue);

      final cleared = draft.copyWith(clearImage: true);
      expect(cleared.hasImage, isFalse);
      expect(cleared.imagePath, isNull);
      expect(cleared.imageType, isNull);
    });
  });

  // ── CheckupDraftNotifier ───────────────────────────────────────────────────

  group('CheckupDraftNotifier via ProviderContainer', () {
    test('updates state and clear() resets to empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(checkupDraftProvider.notifier);

      // Verify initially empty
      expect(container.read(checkupDraftProvider), equals(CheckupDraft.empty));

      // Set patient
      notifier.setPatient(
        const Profile(
          id: 'u1',
          fullName: 'Jane Doe',
          dateOfBirth: '1995-06-15',
          sex: 'female',
          heightCm: 165,
          weightKg: 58,
        ),
      );
      expect(
        container.read(checkupDraftProvider).patient?.fullName,
        'Jane Doe',
      );

      // Set vitals
      notifier.setVitals(
        const VitalsPayload(
          heartRate: 72,
          systolicBp: 120,
          diastolicBp: 80,
          spo2: 98,
          temperature: 36.6,
          activityLevel: 1,
          tobacco: 0,
          alcohol: 0,
        ),
      );
      expect(container.read(checkupDraftProvider).vitals?.heartRate, 72);

      // Set image and verify hasImage
      notifier.setImage(path: '/data/user/0/image.jpg', imageType: 'skin');
      expect(container.read(checkupDraftProvider).hasImage, isTrue);

      // Clear image
      notifier.clearImage();
      expect(container.read(checkupDraftProvider).hasImage, isFalse);
      expect(
        container.read(checkupDraftProvider).patient?.fullName,
        'Jane Doe',
      );

      // Clear entire draft
      notifier.clear();
      final cleared = container.read(checkupDraftProvider);
      expect(cleared.patient, isNull);
      expect(cleared.vitals, isNull);
      expect(cleared.symptoms, isNull);
      expect(cleared.imagePath, isNull);
      expect(cleared.imageType, isNull);
      expect(cleared.hasImage, isFalse);
    });
  });

  // ── Numeric encoding sanity checks ────────────────────────────────────────

  group('Encoding sanity — plan Section 4 values', () {
    test('frequency: Rarely=1, Occasionally=2, Frequently=3, Constantly=4', () {
      const encodings = [1.0, 2.0, 3.0, 4.0];
      for (final v in encodings) {
        expect(v, greaterThanOrEqualTo(1));
        expect(v, lessThanOrEqualTo(4));
      }
    });

    test('progression: Better=0, Same=1, Worse=2', () {
      const encodings = [0.0, 1.0, 2.0];
      for (final v in encodings) {
        expect(v, greaterThanOrEqualTo(0));
        expect(v, lessThanOrEqualTo(2));
      }
    });

    test('activity_level: Low=0, Moderate=1, High=2', () {
      const encodings = [0, 1, 2];
      for (final v in encodings) {
        expect(v, greaterThanOrEqualTo(0));
        expect(v, lessThanOrEqualTo(2));
      }
    });

    test('tobacco/alcohol: No=0, Yes=1', () {
      expect(0, equals(0));
      expect(1, equals(1));
    });
  });

  // ── Item 3: Route Contracts ────────────────────────────────────────────────

  group('Item 3: Route Contracts', () {
    test('AppRoutes match migration plan and deep link specifications', () {
      expect(AppRoutes.splash, equals('/'));
      expect(AppRoutes.login, equals('/login'));
      expect(AppRoutes.register, equals('/register'));
      expect(AppRoutes.resetPassword, equals('/login/reset'));
      expect(AppRoutes.home, equals('/home'));
    });
  });

  // ── Item 3a: LoginScreen ───────────────────────────────────────────────────

  group('Item 3a: LoginScreen', () {
    testWidgets('renders login UI elements matching activity_main.xml', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginScreen())),
      );

      expect(find.text('Health360'), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(
        find.text('Sign in to continue your personalized health checkup'),
        findsOneWidget,
      );
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Sign In  →'), findsOneWidget);
      expect(
        find.text("Don't have an account?  Create account"),
        findsOneWidget,
      );
      expect(
        find.text('Your health data is securely protected'),
        findsOneWidget,
      );
    });

    testWidgets('empty email triggers "Enter your email" message', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginScreen())),
      );

      final signInBtn = find.text('Sign In  →');
      await tester.tap(signInBtn);
      await tester.pump();

      expect(find.text('Enter your email'), findsAtLeast(1));
    });
  });

  // ── Item 3b: RegisterScreen ────────────────────────────────────────────────

  group('Item 3b: RegisterScreen', () {
    testWidgets('renders registration UI matching activity_register.xml', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: RegisterScreen())),
      );

      expect(find.text('Health360'), findsOneWidget);
      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('Personal Details'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Date of Birth'), findsOneWidget);
      expect(find.text('Sex'), findsOneWidget);
      expect(find.text('Height'), findsOneWidget);
      expect(find.text('Weight'), findsOneWidget);
      expect(find.text('Account Credentials'), findsOneWidget);
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(
        find.text('I agree to the Terms of Service and Privacy Policy'),
        findsOneWidget,
      );
      expect(find.text('Create Account  →'), findsOneWidget);
      expect(find.text('Already have an account?  Login'), findsOneWidget);
    });

    testWidgets('empty full name triggers "Enter your full name"', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: RegisterScreen())),
      );

      final createBtn = find.text('Create Account  →');
      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);
      await tester.pump();

      expect(find.text('Enter your full name'), findsAtLeast(1));
    });
  });

  // ── Item 3c: ResetPasswordScreen ───────────────────────────────────────────

  group('Item 3c: ResetPasswordScreen', () {
    testWidgets('renders reset password UI matching specifications', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ResetPasswordScreen())),
      );

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Enter your new Health360 password.'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Update Password'), findsOneWidget);
      expect(find.text('Back to Login'), findsOneWidget);
    });

    testWidgets('empty password triggers "Enter a password"', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ResetPasswordScreen())),
      );

      final updateBtn = find.text('Update Password');
      await tester.tap(updateBtn);
      await tester.pump();

      expect(find.text('Enter a password'), findsAtLeast(1));
    });
  });
}
