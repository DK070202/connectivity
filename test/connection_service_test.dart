import 'package:connectivity/connectivity_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'connection_service_test.mocks.dart';

@GenerateMocks([Connectivity])
void main() {
  late Connectivity mock;

  setUp(() {
    mock = MockConnectivity();
  });

  group('ConnectionService', () {
    group('has connection', () {
      test('true if initial connection is mobile', () async {
        when(mock.checkConnectivity()).thenAnswer(
            (realInvocation) => Future.value(ConnectivityResult.mobile));

        when(mock.onConnectivityChanged)
            .thenAnswer((realInvocation) => const Stream.empty());

        final connectionService = await ConnectivityService(mock).init();

        expect(connectionService.hasActiveConnection, isTrue);
      });

      test('true if initial connection is wifi', () async {
        when(mock.checkConnectivity()).thenAnswer(
            (realInvocation) => Future.value(ConnectivityResult.wifi));

        when(mock.onConnectivityChanged)
            .thenAnswer((realInvocation) => const Stream.empty());

        final connectionService = await ConnectivityService(mock).init();

        expect(connectionService.hasActiveConnection, isTrue);
      });

      test('false if initial connection is not mobile or wifi', () async {
        when(mock.checkConnectivity()).thenAnswer(
            (realInvocation) => Future.value(ConnectivityResult.other));

        when(mock.onConnectivityChanged)
            .thenAnswer((realInvocation) => const Stream.empty());

        final connectionService = await ConnectivityService(mock).init();

        expect(connectionService.hasActiveConnection, isFalse);
      });

      test('changes to false if onChange emits event to none', () async {
        when(mock.checkConnectivity()).thenAnswer(
            (realInvocation) => Future.value(ConnectivityResult.mobile));

        when(mock.onConnectivityChanged).thenAnswer(
          (realInvocation) => Stream.periodic(
                  const Duration(seconds: 2), (x) => ConnectivityResult.none)
              .take(1),
        );

        final connectionService = await ConnectivityService(mock).init();

        expect(connectionService.hasActiveConnection, isTrue);

        await Future.delayed(const Duration(seconds: 2));

        expect(connectionService.hasActiveConnection, isFalse);
      });

      test('changes to true if onChange emits event to mobile from none',
          () async {
        when(mock.checkConnectivity()).thenAnswer(
            (realInvocation) => Future.value(ConnectivityResult.none));

        when(mock.onConnectivityChanged).thenAnswer(
          (realInvocation) => Stream.periodic(
                  const Duration(seconds: 1), (x) => ConnectivityResult.mobile)
              .take(1),
        );

        final connectionService = await ConnectivityService(mock).init();

        expect(connectionService.hasActiveConnection, isFalse);

        await Future.delayed(const Duration(seconds: 1));

        expect(connectionService.hasActiveConnection, isTrue);
      });
    });

    group('onConnectivityChange', () {
      test('emits the event periodically to change connection state', () async {
        when(mock.checkConnectivity()).thenAnswer(
            (realInvocation) => Future.value(ConnectivityResult.none));

        when(mock.onConnectivityChanged).thenAnswer(
          (realInvocation) => Stream.fromIterable([
            ConnectivityResult.wifi,
            ConnectivityResult.none,
            ConnectivityResult.mobile
          ]),
        );

        final connectionService = await ConnectivityService(mock).init();

        expect(
          connectionService.onConnectivityChanged,
          emitsInOrder(
            [true, false, true],
          ),
        );
      });

      group('skips event if previous state if same as emitted', () {
        test('when initial is false', () async {
          when(mock.checkConnectivity()).thenAnswer(
              (realInvocation) => Future.value(ConnectivityResult.none));

          when(mock.onConnectivityChanged).thenAnswer(
            (realInvocation) => Stream.fromIterable([
              ConnectivityResult.none,
              ConnectivityResult.none,
            ]),
          );

          final connectionService = await ConnectivityService(mock).init();

          expect(
            connectionService.onConnectivityChanged,
            emitsInOrder([]),
          );
        });

        test('when initial is true', () async {
          when(mock.checkConnectivity()).thenAnswer(
              (realInvocation) => Future.value(ConnectivityResult.wifi));

          when(mock.onConnectivityChanged).thenAnswer(
            (realInvocation) => Stream.fromIterable([
              ConnectivityResult.mobile,
            ]),
          );

          final connectionService = await ConnectivityService(mock).init();

          expect(
            connectionService.onConnectivityChanged,
            emitsInOrder([]),
          );
        });
      });
    });
  });
}
