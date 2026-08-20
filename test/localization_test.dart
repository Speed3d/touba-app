import 'package:flutter_test/flutter_test.dart';
import 'package:popular_football/core/constants/iraq_regions.dart';
import 'package:popular_football/data/models/city_model.dart';
import 'package:popular_football/data/models/district_model.dart';

void main() {
  group('IraqRegions Localization Tests', () {
    test('all 18 governorates have valid AR, EN, and KU names', () {
      expect(IraqRegions.all.length, 18);
      for (final g in IraqRegions.all) {
        expect(g.nameAr.isNotEmpty, isTrue);
        expect(g.nameEn.isNotEmpty, isTrue);
        expect(g.nameKu.isNotEmpty, isTrue);

        expect(g.localizedName('ar'), g.nameAr);
        expect(g.localizedName('en'), g.nameEn);
        expect(g.localizedName('ku'), g.nameKu);
        expect(g.localizedName('fr'), g.nameAr); // Fallback
      }
    });

    test('all districts have valid AR, EN, and KU names', () {
      for (final g in IraqRegions.all) {
        expect(g.districts.isNotEmpty, isTrue);
        for (final d in g.districts) {
          expect(d.nameAr.isNotEmpty, isTrue);
          expect(d.nameEn.isNotEmpty, isTrue);
          expect(d.nameKu.isNotEmpty, isTrue);

          expect(d.localizedName('ar'), d.nameAr);
          expect(d.localizedName('en'), d.nameEn);
          expect(d.localizedName('ku'), d.nameKu);
        }
      }
    });

    test('CityModel and DistrictModel localize names properly', () {
      final city = CityModel(
        id: 'c1',
        nameAr: 'بغداد',
        nameEn: 'Baghdad',
        nameKu: 'بەغدا',
      );
      expect(city.localizedName('ar'), 'بغداد');
      expect(city.localizedName('en'), 'Baghdad');
      expect(city.localizedName('ku'), 'بەغدا');

      final district = DistrictModel(
        id: 'd1',
        nameAr: 'الكرخ',
        nameEn: 'Al-Karkh',
        nameKu: 'کەرخ',
        cityId: 'c1',
      );
      expect(district.localizedName('ar'), 'الكرخ');
      expect(district.localizedName('en'), 'Al-Karkh');
      expect(district.localizedName('ku'), 'کەرخ');
    });
  });
}
