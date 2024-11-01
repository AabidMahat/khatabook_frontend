import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:khatabook_project/ModifyOrganisation.dart';
import 'package:khatabook_project/organisation_logic.dart';

class MockOrganisationService extends Mock implements OrganisationService {
  @override
  Future<bool> updateOrganisation(
    String orgId,
    String name,
    String email,
    String phone,
    String address,
    String description,
  ) async {
    return super.noSuchMethod(
      Invocation.method(#updateOrganisation, [orgId, name, email, phone, address, description]),
      returnValue: Future.value(true),
    );
  }

  @override
  Future<Map<String, dynamic>> getOrganisationDetails(String orgId) async {
    return super.noSuchMethod(
      Invocation.method(#getOrganisationDetails, [orgId]),
      returnValue: Future.value({
        'name': 'Test Organisation',
        'email': 'org@example.com',
        'phone': '1234567890',
        'address': 'Test Address',
        'description': 'Test Description'
      }),
    );
  }
}

@GenerateMocks([])
void main() {
  group('Organisation Modification Logic Tests', () {
    late OrganisationLogic organisationLogic;
    late MockOrganisationService mockService;
    const String testOrgId = 'test_org_id';

    setUp(() {
      mockService = MockOrganisationService();
      organisationLogic = OrganisationLogic(service: mockService);
    });

    test('loads existing organisation details successfully', () async {
      when(mockService.getOrganisationDetails(testOrgId)).thenAnswer((_) async => {
        'name': 'Test Organisation',
        'email': 'org@example.com',
        'phone': '1234567890',
        'address': 'Test Address',
        'description': 'Test Description'
      });

      final result = await organisationLogic.loadOrganisationDetails(testOrgId);

      expect(result.success, true);
      expect(result.data?['name'], 'Test Organisation');
      expect(result.data?['email'], 'org@example.com');
      expect(result.data?['phone'], '1234567890');
      expect(result.data?['address'], 'Test Address');
      expect(result.data?['description'], 'Test Description');
    });

    test('handles organisation details loading error', () async {
      when(mockService.getOrganisationDetails(testOrgId))
          .thenThrow(Exception('Failed to load organisation details'));

      final result = await organisationLogic.loadOrganisationDetails(testOrgId);

      expect(result.success, false);
      expect(result.error, isNotNull);
    });

    test('validates updated email format', () {
      expect(organisationLogic.isValidEmail('updated@example.com'), true);
      expect(organisationLogic.isValidEmail('invalid-email'), false);
      expect(organisationLogic.isValidEmail(''), false);
    });

    test('validates updated phone number format', () {
      expect(organisationLogic.isValidPhone('9876543210'), true);
      expect(organisationLogic.isValidPhone('123'), false);
      expect(organisationLogic.isValidPhone(''), false);
      expect(organisationLogic.isValidPhone('abcdefghij'), false);
    });

    test('validates updated organisation name', () {
      expect(organisationLogic.isValidName('Updated Org Name'), true);
      expect(organisationLogic.isValidName(''), false);
      expect(organisationLogic.isValidName('   '), false);
    });

    test('validates address', () {
      expect(organisationLogic.isValidAddress('New Test Address'), true);
      expect(organisationLogic.isValidAddress(''), false);
      expect(organisationLogic.isValidAddress('   '), false);
    });

    test('validates description', () {
      expect(organisationLogic.isValidDescription('New Description'), true);
      // Description can be empty as it's optional
      expect(organisationLogic.isValidDescription(''), true);
      expect(organisationLogic.isValidDescription('   '), true);
    });

    test('validates complete updated organisation data', () {
      final validData = {
        'orgId': testOrgId,
        'name': 'Updated Organisation',
        'email': 'updated@example.com',
        'phone': '9876543210',
        'address': 'New Address',
        'description': 'New Description'
      };

      expect(organisationLogic.isValidOrganisationData(validData), true);

      final invalidData = {
        'orgId': testOrgId,
        'name': '',
        'email': 'updated@example.com',
        'phone': '9876543210',
        'address': 'New Address',
        'description': 'New Description'
      };

      expect(organisationLogic.isValidOrganisationData(invalidData), false);
    });

    test('updates organisation successfully with valid data', () async {
      when(mockService.updateOrganisation(
        testOrgId,
        'Updated Organisation',
        'updated@example.com',
        '9876543210',
        'New Address',
        'New Description',
      )).thenAnswer((_) async => true);

      final result = await organisationLogic.updateOrganisation(
        testOrgId,
        'Updated Organisation',
        'updated@example.com',
        '9876543210',
        'New Address',
        'New Description',
      );

      expect(result.success, true);
      expect(result.error, null);

      verify(mockService.updateOrganisation(
        testOrgId,
        'Updated Organisation',
        'updated@example.com',
        '9876543210',
        'New Address',
        'New Description',
      )).called(1);
    });

    test('handles update API errors gracefully', () async {
      when(mockService.updateOrganisation(
        testOrgId,
        'Updated Organisation',
        'updated@example.com',
        '9876543210',
        'New Address',
        'New Description',
      )).thenThrow(Exception('API Error'));

      final result = await organisationLogic.updateOrganisation(
        testOrgId,
        'Updated Organisation',
        'updated@example.com',
        '9876543210',
        'New Address',
        'New Description',
      );

      expect(result.success, false);
      expect(result.error, isNotNull);
    });

    test('prevents duplicate update submission while request is in progress', () async {
      when(mockService.updateOrganisation(
        testOrgId,
        'Updated Organisation',
        'updated@example.com',
        '9876543210',
        'New Address',
        'New Description',
      )).thenAnswer((_) async {
        await Future.delayed(Duration(seconds: 1));
        return true;
      });

      final firstRequest = organisationLogic.updateOrganisation(
        testOrgId,
        'Updated Organisation',
        'updated@example.com',
        '9876543210',
        'New Address',
        'New Description',
      );

      expect(organisationLogic.isSubmitting, true);

      expect(
        () => organisationLogic.updateOrganisation(
          testOrgId,
          'Updated Organisation',
          'updated@example.com',
          '9876543210',
          'New Address',
          'New Description',
        ),
        throwsA(isA<Exception>()),
      );

      await firstRequest; // Wait for first request to complete
      expect(organisationLogic.isSubmitting, false);
    });

    test('detects if organisation data has changed', () {
      final originalData = {
        'name': 'Test Organisation',
        'email': 'org@example.com',
        'phone': '1234567890',
        'address': 'Test Address',
        'description': 'Test Description'
      };

      final sameData = {
        'name': 'Test Organisation',
        'email': 'org@example.com',
        'phone': '1234567890',
        'address': 'Test Address',
        'description': 'Test Description'
      };

      final changedData = {
        'name': 'Updated Organisation',
        'email': 'org@example.com',
        'phone': '1234567890',
        'address': 'Test Address',
        'description': 'Test Description'
      };

      expect(organisationLogic.hasDataChanged(originalData, sameData), false);
      expect(organisationLogic.hasDataChanged(originalData, changedData), true);
    });
  });
}
