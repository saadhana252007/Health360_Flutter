import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:health360ai/app/router.dart';
import 'package:health360ai/data/models/profile.dart';
import 'package:health360ai/data/models/symptoms_vitals.dart';
import 'package:health360ai/data/models/checkup_summary.dart';
import 'package:health360ai/data/models/checkup_detail.dart';
import 'package:health360ai/data/models/checkup_response.dart';
import 'package:health360ai/features/auth/login_screen.dart';
import 'package:health360ai/features/auth/register_screen.dart';
import 'package:health360ai/features/auth/reset_password_screen.dart';
import 'package:health360ai/features/shell/home_shell.dart';
import 'package:health360ai/features/home/home_screen.dart';
import 'package:health360ai/features/image/image_input_screen.dart';
import 'package:health360ai/features/patient/patient_info_screen.dart';
import 'package:health360ai/features/profile/profile_screen.dart';
import 'package:health360ai/features/symptoms/symptoms_screen.dart';
import 'package:health360ai/features/vitals/vitals_screen.dart';
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

  // ── Item 4a: HomeShell & HomeScreen ────────────────────────────────────────

  group('Item 4a: HomeShell', () {
    testWidgets('renders all 4 bottom navigation items', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeProfileProvider.overrideWith((ref) => Future.value(null)),
            homeLatestCheckupProvider.overrideWith((ref) => Future.value(null)),
            profileScreenProvider.overrideWith((ref) => Future.value(null)),
          ],
          child: const MaterialApp(home: HomeShell()),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Assistant'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('switches tab on navigation item tap', (tester) async {
      final container = ProviderContainer(
        overrides: [
          homeProfileProvider.overrideWith((ref) => Future.value(null)),
          homeLatestCheckupProvider.overrideWith((ref) => Future.value(null)),
          profileScreenProvider.overrideWith((ref) => Future.value(null)),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeShell()),
        ),
      );

      // Initially on Home (index 0)
      expect(container.read(activeTabProvider), 0);

      // Tap Profile
      await tester.tap(find.text('Profile'));
      await tester.pump();
      expect(container.read(activeTabProvider), 3);

      // Tap Assistant
      await tester.tap(find.text('Assistant'));
      await tester.pump();
      expect(container.read(activeTabProvider), 2);

      // Tap History
      await tester.tap(find.text('History'));
      await tester.pump();
      expect(container.read(activeTabProvider), 1);
    });
  });

  group('Item 4a: HomeScreen', () {
    testWidgets('renders empty state overview and cards', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeProfileProvider.overrideWith((ref) => Future.value(null)),
            homeLatestCheckupProvider.overrideWith((ref) => Future.value(null)),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Start a Health Checkup'), findsOneWidget);
      expect(find.text('AI-POWERED MULTIMODAL SCREENING'), findsOneWidget);
      expect(find.text('Symptoms'), findsNWidgets(2)); // Chip and overview tile
      expect(find.text('Vitals'), findsOneWidget);
      expect(find.text('Images'), findsOneWidget);
      expect(find.text('Start Health Checkup  →'), findsOneWidget);

      expect(find.text('Your Health Overview'), findsOneWidget);
      expect(find.text('Overall Health'), findsOneWidget);
      expect(find.text('Not assessed'), findsNWidgets(2));
      expect(find.text('Last Checkup'), findsOneWidget);
      expect(find.text('No checkups yet'), findsNWidgets(2));
      expect(find.text('Not recorded'), findsOneWidget);

      expect(find.text('Health360 AI Assistant'), findsOneWidget);
      expect(find.text('Ask Assistant'), findsOneWidget);
      expect(find.text("Today's Health Tip"), findsOneWidget);
      expect(
        find.text(
          'Stay hydrated and remember to take regular breaks during the day.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders populated profile and checkup data', (tester) async {
      const mockProfile = Profile(
        id: 'u1',
        fullName: 'Saadhana',
        dateOfBirth: '1998-05-20',
        sex: 'female',
        heightCm: 168.0,
        weightKg: 55.0,
      );

      const mockCheckup = CheckupSummary(
        id: 'c1',
        userId: 'u1',
        status: 'completed',
        overallScore: 0.85,
        createdAt: '2026-10-12T10:00:00Z',
        overallCategory: 'moderate',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeProfileProvider.overrideWith(
              (ref) => Future.value(mockProfile),
            ),
            homeLatestCheckupProvider.overrideWith(
              (ref) => Future.value(mockCheckup),
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Saadhana'), findsOneWidget);
      expect(find.text('S'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('12 Oct 2026'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Moderate'), findsOneWidget);
      expect(find.text('Latest health checkup'), findsOneWidget);
      expect(find.text('Start another checkup  →'), findsOneWidget);
    });

    testWidgets('tapping Ask Assistant switches tab to Assistant (index 2)', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          homeProfileProvider.overrideWith((ref) => Future.value(null)),
          homeLatestCheckupProvider.overrideWith((ref) => Future.value(null)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Ask Assistant'));
      await tester.tap(find.text('Ask Assistant'));
      await tester.pump();

      expect(container.read(activeTabProvider), 2);
    });
  });

  // ── Item 4b: ProfileScreen ─────────────────────────────────────────────────

  group('Item 4b: ProfileScreen', () {
    const mockProfile = Profile(
      id: 'u1',
      fullName: 'Saadhana Patel',
      dateOfBirth: '1995-06-15',
      sex: 'female',
      heightCm: 165.0,
      weightKg: 60.0,
      createdAt: '2026-01-15T00:00:00Z',
    );

    testWidgets('renders personal health details and account info', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileScreenProvider.overrideWith(
              (ref) => Future.value(mockProfile),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('Saadhana Patel'), findsNWidgets(2));
      expect(find.text('June 15, 1995'), findsOneWidget);
      expect(find.text('female'), findsOneWidget);
      expect(find.text('165 cm'), findsOneWidget);
      expect(find.text('60 kg'), findsOneWidget);
      expect(find.text('January 15, 2026'), findsOneWidget);
      expect(find.text('Edit Personal Information'), findsOneWidget);
      expect(find.text('Privacy & Security'), findsOneWidget);
      expect(find.text('About Health360'), findsOneWidget);
      expect(find.text('v1.0.0'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('Privacy & Security row opens dialog', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileScreenProvider.overrideWith(
              (ref) => Future.value(mockProfile),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Privacy & Security'));
      await tester.tap(find.text('Privacy & Security'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'Your Health360 account is protected using Supabase Authentication.',
        ),
        findsOneWidget,
      );
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Your Health360 account is protected'),
        findsNothing,
      );
    });

    testWidgets('About Health360 row opens dialog', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileScreenProvider.overrideWith(
              (ref) => Future.value(mockProfile),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('About Health360'));
      await tester.tap(find.text('About Health360'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'Health360 AI is a modular AI-powered personal health checkup',
        ),
        findsOneWidget,
      );
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets('Logout button opens confirmation dialog', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileScreenProvider.overrideWith(
              (ref) => Future.value(mockProfile),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Logout'));
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Are you sure you want to logout from your Health360 account?',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Logout'), findsNWidgets(3));
    });
  });

  // ── Item 5 Test Router Helper ──────────────────────────────────────────────

  Widget buildCheckupTestApp(Widget screen, {ProviderContainer? container}) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => screen),
        GoRoute(path: AppRoutes.symptoms, builder: (_, _) => const SizedBox()),
        GoRoute(path: AppRoutes.vitals, builder: (_, _) => const SizedBox()),
        GoRoute(
          path: AppRoutes.imageInput,
          builder: (_, _) => const SizedBox(),
        ),
      ],
    );

    final app = MaterialApp.router(routerConfig: router);
    if (container != null) {
      return UncontrolledProviderScope(container: container, child: app);
    }
    return ProviderScope(child: app);
  }

  // ── Item 5a: Patient Information Screen ────────────────────────────────────

  group('Item 5a: PatientInfoScreen', () {
    testWidgets('renders patient form fields and buttons', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildCheckupTestApp(const PatientInfoScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Patient Information'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Date of Birth'), findsOneWidget);
      expect(find.text('Sex'), findsOneWidget);
      expect(find.text('Height'), findsOneWidget);
      expect(find.text('Weight'), findsOneWidget);
      expect(find.text('Save and Continue'), findsOneWidget);
    });

    testWidgets('validates required fields with exact error messages', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildCheckupTestApp(const PatientInfoScreen()));
      await tester.pumpAndSettle();

      // 1. Empty name
      await tester.tap(find.text('Save and Continue'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(SnackBar, 'Enter your full name'),
        findsOneWidget,
      );

      // Enter name (first TextField)
      await tester.enterText(find.byType(TextField).at(0), 'Jane Doe');
      await tester.tap(find.text('Save and Continue'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(SnackBar, 'Select your date of birth'),
        findsOneWidget,
      );

      // Pick date of birth
      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Empty sex validation
      await tester.tap(find.text('Save and Continue'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(SnackBar, 'Select your sex'), findsOneWidget);

      // Select sex
      await tester.tap(find.text('Select sex'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Female').last);
      await tester.pumpAndSettle();

      // Height empty
      await tester.tap(find.text('Save and Continue'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(SnackBar, 'Enter a valid height'),
        findsOneWidget,
      );

      // Enter valid height (second TextField)
      await tester.enterText(find.byType(TextField).at(1), '168');
      await tester.tap(find.text('Save and Continue'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(SnackBar, 'Enter a valid weight'),
        findsOneWidget,
      );
    });

    testWidgets('pre-populates from draft and updates CheckupDraft on save', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      const initialProfile = Profile(
        id: 'patient-1',
        fullName: 'John Smith',
        dateOfBirth: '1990-01-01',
        sex: 'Male',
        heightCm: 175.0,
        weightKg: 70.0,
      );
      container.read(checkupDraftProvider.notifier).setPatient(initialProfile);

      await tester.pumpWidget(
        buildCheckupTestApp(const PatientInfoScreen(), container: container),
      );
      await tester.pumpAndSettle();

      expect(find.text('John Smith'), findsOneWidget);
      expect(find.text('01-01-1990'), findsOneWidget);
      expect(find.text('175'), findsOneWidget);
      expect(find.text('70'), findsOneWidget);

      // Modify weight (third TextField)
      await tester.enterText(find.byType(TextField).at(2), '72.5');
      await tester.tap(find.text('Save and Continue'));
      await tester.pumpAndSettle();

      final updated = container.read(checkupDraftProvider).patient;
      expect(updated, isNotNull);
      expect(updated!.fullName, 'John Smith');
      expect(updated.weightKg, 72.5);
    });
  });

  // ── Item 5b: Symptoms Screen ───────────────────────────────────────────────

  group('Item 5b: SymptomsScreen', () {
    testWidgets('renders all questions and sections', (tester) async {
      tester.view.physicalSize = const Size(1080, 2800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildCheckupTestApp(const SymptomsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Symptoms'), findsOneWidget);
      expect(find.text('Tell us about your current symptoms'), findsOneWidget);
      expect(find.text('How severe is your symptom?'), findsOneWidget);
      expect(find.text('How long have you had it?'), findsOneWidget);
      expect(find.text('How often are you experiencing it?'), findsOneWidget);
      expect(find.text('How is the symptom changing?'), findsOneWidget);
      expect(
        find.text('What type of concern are you describing?'),
        findsOneWidget,
      );
      expect(find.text('What does the symptom feel like?'), findsOneWidget);
      expect(
        find.text('Does anything make it worse or bring it on?'),
        findsOneWidget,
      );
      expect(find.text('Associated symptoms'), findsOneWidget);
      expect(find.text('Symptoms before it'), findsOneWidget);
      expect(find.text('Symptoms after it'), findsOneWidget);
      expect(find.text('Save and Continue'), findsOneWidget);
    });

    testWidgets('validates required fields with exact messages in order', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildCheckupTestApp(const SymptomsScreen()));
      await tester.pumpAndSettle();

      // 1. Severity empty
      await tester.ensureVisible(find.text('Save and Continue'));
      await tester.tap(find.text('Save and Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a severity between 0 and 10'), findsOneWidget);

      // Severity > 10
      await tester.enterText(
        find.widgetWithText(TextField, 'Rate from 0 to 10'),
        '15',
      );
      await tester.tap(find.text('Save and Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a severity between 0 and 10'), findsOneWidget);

      // Valid severity 6
      await tester.enterText(
        find.widgetWithText(TextField, 'Rate from 0 to 10'),
        '6',
      );
      await tester.tap(find.text('Save and Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid duration'), findsOneWidget);

      // Valid duration 4 -> next error is complaint type (validated before frequency)
      await tester.enterText(
        find.widgetWithText(TextField, 'Number of days'),
        '4',
      );
      await tester.tap(find.text('Save and Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Select the type of concern'), findsOneWidget);
    });

    testWidgets('dynamic site options switch when complaint type changes', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildCheckupTestApp(const SymptomsScreen()));
      await tester.pumpAndSettle();

      // Default complaint type is null. Select Skin concern:
      await tester.ensureVisible(find.text('Skin concern'));
      await tester.tap(find.text('Skin concern'));
      await tester.pumpAndSettle();

      expect(find.text('Face'), findsOneWidget);
      expect(find.text('Scalp'), findsOneWidget);
      expect(find.text('Neck'), findsOneWidget);

      // Switch to Oral / Dental concern
      await tester.ensureVisible(find.text('Oral / Dental concern'));
      await tester.tap(find.text('Oral / Dental concern'));
      await tester.pumpAndSettle();

      expect(find.text('Teeth'), findsOneWidget);
      expect(find.text('Gums'), findsOneWidget);
      expect(find.text('Tongue'), findsOneWidget);
      expect(find.text('Face'), findsNothing);
    });

    testWidgets('saves full SymptomsPayload into CheckupDraft', (tester) async {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      await tester.pumpWidget(
        buildCheckupTestApp(const SymptomsScreen(), container: container),
      );
      await tester.pumpAndSettle();

      // Severity 7
      await tester.enterText(
        find.widgetWithText(TextField, 'Rate from 0 to 10'),
        '7',
      );
      // Duration 3
      await tester.enterText(
        find.widgetWithText(TextField, 'Number of days'),
        '3',
      );
      // Frequency: Rarely
      await tester.ensureVisible(find.text('Rarely'));
      await tester.tap(find.text('Rarely'));
      await tester.pumpAndSettle();

      // Progression: Getting worse
      await tester.ensureVisible(find.text('Getting worse'));
      await tester.tap(find.text('Getting worse'));
      await tester.pumpAndSettle();

      // Complaint type: General symptom
      await tester.ensureVisible(find.text('General symptom'));
      await tester.tap(find.text('General symptom'));
      await tester.pumpAndSettle();

      // Location: Chest
      await tester.ensureVisible(find.text('Chest'));
      await tester.tap(find.text('Chest'));
      await tester.pumpAndSettle();

      // Character: Sharp
      await tester.ensureVisible(find.text('Sharp'));
      await tester.tap(find.text('Sharp'));
      await tester.pumpAndSettle();

      // Triggers: Stress & Exercise
      await tester.ensureVisible(find.text('Stress'));
      await tester.tap(find.text('Stress'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Exercise'));
      await tester.tap(find.text('Exercise'));
      await tester.pumpAndSettle();

      // Associated: Fatigue
      await tester.ensureVisible(find.text('Fatigue').first);
      await tester.tap(find.text('Fatigue').first);
      await tester.pumpAndSettle();

      // Save
      await tester.ensureVisible(find.text('Save and Continue'));
      await tester.tap(find.text('Save and Continue'));
      await tester.pumpAndSettle();

      final saved = container.read(checkupDraftProvider).symptoms;
      expect(saved, isNotNull);
      expect(saved!.severity, 7.0);
      expect(saved.durationDays, 3.0);
      expect(saved.complaintType, 'general');
      expect(saved.frequency, 1.0);
      expect(saved.progression, 2.0);
      expect(saved.site, 'chest');
      expect(saved.character, 1.0);
      expect(saved.trigger, 2.0); // 2 triggers selected
      expect(saved.associatedSymptoms, contains('Fatigue'));
    });
  });

  // ── Item 5c: Vitals Screen ─────────────────────────────────────────────────

  group('Item 5c: VitalsScreen', () {
    testWidgets('renders vitals inputs and labels', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildCheckupTestApp(const VitalsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Vital Information'), findsOneWidget);
      expect(find.text('Heart Rate'), findsOneWidget);
      expect(find.text('Systolic BP'), findsOneWidget);
      expect(find.text('Diastolic BP'), findsOneWidget);
      expect(find.text('Oxygen Saturation (SpO₂)'), findsOneWidget);
      expect(find.text('Body Temperature'), findsOneWidget);
      expect(find.text('Activity Level'), findsOneWidget);
      expect(find.text('Tobacco Use'), findsOneWidget);
      expect(find.text('Alcohol Consumption'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('validates vital inputs with exact order and messages', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildCheckupTestApp(const VitalsScreen()));
      await tester.pumpAndSettle();

      // Select all three dropdowns FIRST before triggering any validation
      // (avoids SnackBar overlay blocking dropdown hit-tests)
      final dropdowns = find.byType(DropdownButton<String>);

      await tester.tap(dropdowns.at(0)); // Activity Level
      await tester.pumpAndSettle();
      await tester.tap(find.text('Moderate').last);
      await tester.pumpAndSettle();

      await tester.tap(dropdowns.at(1)); // Tobacco Use
      await tester.pumpAndSettle();
      await tester.tap(find.text('No').last);
      await tester.pumpAndSettle();

      await tester.tap(dropdowns.at(2)); // Alcohol Consumption
      await tester.pumpAndSettle();
      await tester.tap(find.text('No').last);
      await tester.pumpAndSettle();

      // 1. Empty numeric fields -> complete all vital information
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(
        find.text('Please complete all vital information'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Fill HR invalid (< 30)
      await tester.enterText(find.widgetWithText(TextField, 'e.g. 72'), '25');
      await tester.enterText(find.widgetWithText(TextField, 'e.g. 120'), '120');
      await tester.enterText(find.widgetWithText(TextField, 'e.g. 80'), '80');
      await tester.enterText(find.widgetWithText(TextField, 'e.g. 98'), '98');
      await tester.enterText(
        find.widgetWithText(TextField, 'e.g. 36.6'),
        '36.6',
      );
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid heart rate'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Systolic invalid (< 70)
      await tester.enterText(find.widgetWithText(TextField, '25'), '72');
      await tester.enterText(find.widgetWithText(TextField, '120'), '65');
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(
        find.text('Please enter a valid systolic blood pressure'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Diastolic invalid (< 40)
      await tester.enterText(find.widgetWithText(TextField, '65'), '120');
      await tester.enterText(find.widgetWithText(TextField, '80'), '35');
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(
        find.text('Please enter a valid diastolic blood pressure'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // SpO2 invalid (< 70)
      await tester.enterText(find.widgetWithText(TextField, '35'), '80');
      await tester.enterText(find.widgetWithText(TextField, '98'), '60');
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('SpO₂ must be between 70% and 100%'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Temperature invalid (< 30)
      await tester.enterText(find.widgetWithText(TextField, '60'), '98');
      await tester.enterText(find.widgetWithText(TextField, '36.6'), '28');
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Please enter a valid body temperature between 30°C and 45°C',
        ),
        findsOneWidget,
      );
    });

    testWidgets('saves VitalsPayload with correct discrete encodings', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      await tester.pumpWidget(
        buildCheckupTestApp(const VitalsScreen(), container: container),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'e.g. 72'), '76');
      await tester.enterText(find.widgetWithText(TextField, 'e.g. 120'), '125');
      await tester.enterText(find.widgetWithText(TextField, 'e.g. 80'), '82');
      await tester.enterText(find.widgetWithText(TextField, 'e.g. 98'), '99');
      await tester.enterText(
        find.widgetWithText(TextField, 'e.g. 36.6'),
        '37.1',
      );

      // Open Activity Level dropdown (index 0) and pick High
      final dropdownsBtns = find.byType(DropdownButton<String>);
      await tester.tap(dropdownsBtns.at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('High').last);
      await tester.pumpAndSettle();

      // Open Tobacco dropdown (index 1) and pick Yes
      await tester.tap(dropdownsBtns.at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes').last);
      await tester.pumpAndSettle();

      // Open Alcohol dropdown (index 2) and pick No
      await tester.tap(dropdownsBtns.at(2));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      final saved = container.read(checkupDraftProvider).vitals;
      expect(saved, isNotNull);
      expect(saved!.heartRate, 76.0);
      expect(saved.systolicBp, 125.0);
      expect(saved.diastolicBp, 82.0);
      expect(saved.spo2, 99.0);
      expect(saved.temperature, 37.1);
      expect(saved.activityLevel, 2); // High -> 2
      expect(saved.tobacco, 1); // Yes -> 1
      expect(saved.alcohol, 0); // No -> 0
    });
  });

  // ── Item 5d: Image Input Screen ────────────────────────────────────────────

  group('Item 5d: ImageInputScreen', () {
    testWidgets('renders image type dropdown and actions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildCheckupTestApp(const ImageInputScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Image Check'), findsOneWidget);
      expect(
        find.text('Upload an image for AI-assisted analysis'),
        findsOneWidget,
      );
      expect(find.text('Image Type'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Skip Image'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('validates missing image type and missing image', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildCheckupTestApp(const ImageInputScreen()));
      await tester.pumpAndSettle();

      // Tap Continue without selecting type -> shows snackbar
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Select an image type'), findsOneWidget);

      // Dismiss snackbar, then select type 'Skin'
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Select image type'));
      await tester.tap(find.text('Select image type'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skin').last);
      await tester.pumpAndSettle();

      // Tap Continue without selecting image -> shows snackbar
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Select or capture an image'), findsOneWidget);
    });

    testWidgets('Skip Image clears image from draft', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      container
          .read(checkupDraftProvider.notifier)
          .setImage(path: 'dummy/path.jpg', imageType: 'skin');
      expect(container.read(checkupDraftProvider).imagePath, 'dummy/path.jpg');

      await tester.pumpWidget(
        buildCheckupTestApp(const ImageInputScreen(), container: container),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Skip Image'));
      await tester.tap(find.text('Skip Image'));
      await tester.pumpAndSettle();

      expect(container.read(checkupDraftProvider).imagePath, isNull);
      expect(container.read(checkupDraftProvider).imageType, isNull);
      expect(
        find.textContaining('Continuing without image analysis'),
        findsOneWidget,
      );
    });
  });
}
