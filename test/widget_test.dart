import 'package:flutter_test/flutter_test.dart';

import 'package:face_reco/app/vision_lab_app.dart';
import 'package:face_reco/features/face/latency_ledger.dart';
import 'package:face_reco/modules/model_catalog.dart';

void main() {
  testWidgets('home features the one ready model', (tester) async {
    await tester.pumpWidget(const VisionLabApp());

    expect(find.text('Vision Lab'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Object Detection'), findsOneWidget);
    expect(find.text('Digital Ink'), findsOneWidget);
    // Every model is built.
    expect(find.text('Soon'), findsNothing);
  });

  test('every model in the catalog is wired up', () {
    expect(modelCatalog, hasLength(4));
    expect(modelCatalog.every((m) => m.ready), isTrue);
    expect(modelCatalog.map((m) => m.accent).toSet(), hasLength(4));
    expect(modelCatalog.first.name, 'Face Detection');
  });

  group('LatencyLedger', () {
    test('reports nothing until both sides are measured', () {
      final ledger = LatencyLedger();
      const on = OptionBit.contours | OptionBit.landmarks;
      for (var i = 0; i < 20; i++) {
        ledger.record(on, 40);
      }
      expect(ledger.costOf(on, OptionBit.contours), isNull);
    });

    test('reports the measured difference once both sides exist', () {
      final ledger = LatencyLedger();
      const on = OptionBit.contours | OptionBit.landmarks;
      const off = OptionBit.landmarks;
      for (var i = 0; i < 20; i++) {
        ledger.record(on, 40);
        ledger.record(off, 22);
      }
      expect(ledger.costOf(on, OptionBit.contours), closeTo(18, 0.001));
    });

    test('never reports a cost for an option that is off', () {
      final ledger = LatencyLedger();
      for (var i = 0; i < 20; i++) {
        ledger.record(OptionBit.landmarks, 22);
      }
      expect(ledger.costOf(OptionBit.landmarks, OptionBit.contours), isNull);
    });
  });
}
