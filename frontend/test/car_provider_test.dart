import 'package:flutter_test/flutter_test.dart';
import 'package:car_maintenance_app/providers/car_provider.dart';
import 'package:car_maintenance_app/models/car.dart';

void main() {
  group('CarProvider', () {
    test('isPlateNumberExists returns true when car exists', () {
      final provider = CarProvider();
      provider.selectCar(
        Car(plateNumber: 'ABC123', vin: 'VIN1234567890123'),
      );
      // After selecting, provider.selectedCar is set
      expect(provider.selectedCar?.plateNumber, 'ABC123');
      expect(provider.isPlateNumberExists('abc123'), isTrue);
    });

    test('clearSelectedCar resets selected car', () {
      final provider = CarProvider();
      provider.selectCar(Car(plateNumber: 'A', vin: 'V'));
      provider.clearSelectedCar();
      expect(provider.selectedCar, isNull);
    });
  });
}
