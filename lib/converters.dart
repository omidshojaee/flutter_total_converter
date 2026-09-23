import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

typedef Fn = double Function(double);

class Unit {
  Unit(this.key, this.fa, this.sym, double f)
    : toBase = ((v) => v * f),
      fromBase = ((v) => v / f);
  Unit.fn(this.key, this.fa, this.sym, this.toBase, this.fromBase);

  final String key, fa, sym;
  final Fn toBase, fromBase;
}

class Category {
  Category(this.key, this.fa, this.icon, this.units);
  final String key, fa;
  final IconData icon;
  List<Unit> units;

  bool loading = false;
  String? error;

  Unit unit(String k) =>
      units.firstWhere((u) => u.key == k, orElse: () => units.first);
}

double convert(double v, Unit from, Unit to) => to.fromBase(from.toBase(v));

// ───────────────────────── number helpers ─────────────────────────

const _faDigits = '۰۱۲۳۴۵۶۷۸۹';
const _arDigits = '٠١٢٣٤٥٦٧٨٩';

String toFa(String s) => s
    .replaceAllMapped(RegExp(r'\d'), (m) => _faDigits[int.parse(m[0]!)])
    .replaceAll(',', '٬')
    .replaceAll('.', '٫');

double? parseNum(String s) {
  var t = s.trim();
  for (var i = 0; i < 10; i++) {
    t = t.replaceAll(_faDigits[i], '$i').replaceAll(_arDigits[i], '$i');
  }
  t = t.replaceAll('٫', '.').replaceAll('٬', '').replaceAll(',', '');
  return double.tryParse(t);
}

String fmt(double v, {int digits = 6, bool persian = true}) {
  if (v.isNaN || v.isInfinite) return '—';
  final a = v.abs();
  String s;
  if (a != 0 && (a >= 1e15 || a < 1e-7)) {
    s = v.toStringAsExponential(digits.clamp(0, 10));
    s = s.replaceFirstMapped(RegExp(r'\.?0+e'), (_) => 'e');
  } else {
    final extra = (a > 0 && a < 1) ? (-(math.log(a) / math.ln10)).floor() : 0;
    s = v.toStringAsFixed(math.min(digits + extra, 20));
    if (s.contains('.')) s = s.replaceFirst(RegExp(r'\.?0+$'), '');
    final p = s.split('.');
    p[0] = p[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    s = p.join('.');
  }
  return persian ? toFa(s) : s;
}

// ───────────────────────── currency (live rates only, no fallback) ─────────────────────────

class Currency {
  static const names = {
    'USD': 'دلار آمریکا',
    'EUR': 'یورو',
    'GBP': 'پوند انگلیس',
    'AED': 'درهم امارات',
    'TRY': 'لیر ترکیه',
    'CNY': 'یوان چین',
    'JPY': 'ین ژاپن',
    'CAD': 'دلار کانادا',
    'AUD': 'دلار استرالیا',
    'CHF': 'فرانک سوئیس',
    'RUB': 'روبل روسیه',
    'INR': 'روپیه هند',
    'SAR': 'ریال عربستان',
    'IRR': 'ریال ایران',
  };

  static Future<void> fetch(Category c) async {
    c.loading = true;
    c.error = null;
    try {
      final r = await http
          .get(Uri.parse('https://open.er-api.com/v6/latest/USD'))
          .timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final rates = (jsonDecode(r.body)['rates'] as Map)
          .cast<String, dynamic>();
      final units = <Unit>[];
      for (final e in names.entries) {
        final rate = rates[e.key];
        if (rate is num && rate > 0) {
          units.add(Unit(e.key, e.value, e.key, 1 / rate.toDouble()));
        }
      }
      if (units.length < 2) throw Exception('Incomplete rate data');
      c.units = units;
    } catch (_) {
      c.units = [];
      c.error = 'خطا در دریافت نرخ‌های زنده. اتصال اینترنت را بررسی کنید.';
    } finally {
      c.loading = false;
    }
  }
}

final categories = <Category>[
  Category('currency', 'ارز', Icons.currency_exchange, []),
  Category('mass', 'جرم', Icons.scale, [
    Unit('kg', 'کیلوگرم', 'kg', 1),
    Unit('lb', 'پوند', 'lb', 0.45359237),
    Unit('g', 'گرم', 'g', 1e-3),
    Unit('mg', 'میلی‌گرم', 'mg', 1e-6),
    Unit('µg', 'میکروگرم', 'µg', 1e-9),
    Unit('t', 'تن متریک', 't', 1000),
    Unit('oz', 'اونس', 'oz', 0.028349523125),
    Unit('st', 'استون', 'st', 6.35029318),
    Unit('ton (US)', 'تن آمریکایی', 'ton (US)', 907.18474),
    Unit('ton (UK)', 'تن انگلیسی', 'ton (UK)', 1016.0469088),
    Unit('ct', 'قیراط', 'ct', 2e-4),
  ]),
  Category('length', 'طول', Icons.straighten, [
    Unit('m', 'متر', 'm', 1),
    Unit('ft', 'فوت', 'ft', 0.3048),
    Unit('km', 'کیلومتر', 'km', 1000),
    Unit('cm', 'سانتی‌متر', 'cm', 0.01),
    Unit('mm', 'میلی‌متر', 'mm', 0.001),
    Unit('in', 'اینچ', 'in', 0.0254),
    Unit('mi', 'مایل', 'mi', 1609.344),
    Unit('yd', 'یارد', 'yd', 0.9144),
    Unit('µm', 'میکرومتر', 'µm', 1e-6),
    Unit('nm', 'نانومتر', 'nm', 1e-9),
    Unit('nmi', 'مایل دریایی', 'nmi', 1852),
  ]),
  Category('temperature', 'دما', Icons.thermostat, [
    Unit.fn('°C', 'سانتی‌گراد', '°C', (v) => v + 273.15, (k) => k - 273.15),
    Unit.fn(
      '°F',
      'فارنهایت',
      '°F',
      (v) => (v - 32) * 5 / 9 + 273.15,
      (k) => (k - 273.15) * 9 / 5 + 32,
    ),
    Unit('K', 'کلوین', 'K', 1),
  ]),
  Category('area', 'مساحت', Icons.square_foot, [
    Unit('m²', 'متر مربع', 'm²', 1),
    Unit('ft²', 'فوت مربع', 'ft²', 0.09290304),
    Unit('km²', 'کیلومتر مربع', 'km²', 1e6),
    Unit('cm²', 'سانتی‌متر مربع', 'cm²', 1e-4),
    Unit('mm²', 'میلی‌متر مربع', 'mm²', 1e-6),
    Unit('ha', 'هکتار', 'ha', 1e4),
    Unit('ac', 'ایکر', 'ac', 4046.8564224),
    Unit('in²', 'اینچ مربع', 'in²', 0.00064516),
    Unit('yd²', 'یارد مربع', 'yd²', 0.83612736),
    Unit('mi²', 'مایل مربع', 'mi²', 2589988.110336),
  ]),
  Category('volume', 'حجم', Icons.view_in_ar, [
    Unit('L', 'لیتر', 'L', 1),
    Unit('mL', 'میلی‌لیتر', 'mL', 1e-3),
    Unit('m³', 'متر مکعب', 'm³', 1000),
    Unit('cm³', 'سانتی‌متر مکعب', 'cm³', 1e-3),
    Unit('gal (US)', 'گالن آمریکا', 'gal (US)', 3.785411784),
    Unit('gal (UK)', 'گالن انگلیس', 'gal (UK)', 4.54609),
    Unit('qt', 'کوارت', 'qt', 0.946352946),
    Unit('pt', 'پاینت', 'pt', 0.473176473),
    Unit('cup', 'فنجان', 'cup', 0.2365882365),
    Unit('fl oz', 'اونس مایع', 'fl oz', 0.0295735295625),
    Unit('tbsp', 'قاشق غذاخوری', 'tbsp', 0.01478676478125),
    Unit('tsp', 'قاشق چای‌خوری', 'tsp', 0.00492892159375),
    Unit('ft³', 'فوت مکعب', 'ft³', 28.316846592),
    Unit('in³', 'اینچ مکعب', 'in³', 0.016387064),
  ]),
  Category('digital', 'دیجیتال', Icons.sd_storage, [
    Unit('MB', 'مگابایت', 'MB', 8e6),
    Unit('GB', 'گیگابایت', 'GB', 8e9),
    Unit('KB', 'کیلوبایت', 'KB', 8e3),
    Unit('TB', 'ترابایت', 'TB', 8e12),
    Unit('PB', 'پتابایت', 'PB', 8e15),
    Unit('B', 'بایت', 'B', 8),
    Unit('bit', 'بیت', 'bit', 1),
    Unit('Kb', 'کیلوبیت', 'Kb', 1e3),
    Unit('Mb', 'مگابیت', 'Mb', 1e6),
    Unit('Gb', 'گیگابیت', 'Gb', 1e9),
    Unit('Tb', 'ترابیت', 'Tb', 1e12),
    Unit('KiB', 'کیبی‌بایت', 'KiB', 8192),
    Unit('MiB', 'مبی‌بایت', 'MiB', 8388608),
    Unit('GiB', 'گیبی‌بایت', 'GiB', 8589934592),
    Unit('TiB', 'تبی‌بایت', 'TiB', 8796093022208),
  ]),
  Category('time', 'زمان', Icons.schedule, [
    Unit('min', 'دقیقه', 'min', 60),
    Unit('h', 'ساعت', 'h', 3600),
    Unit('s', 'ثانیه', 's', 1),
    Unit('d', 'روز', 'd', 86400),
    Unit('ms', 'میلی‌ثانیه', 'ms', 1e-3),
    Unit('µs', 'میکروثانیه', 'µs', 1e-6),
    Unit('wk', 'هفته', 'wk', 604800),
    Unit('mo', 'ماه (میانگین)', 'mo', 2629800),
    Unit('yr', 'سال (۳۶۵٫۲۵ روز)', 'yr', 31557600),
  ]),
  Category('parts-per', 'درصد و ppm', Icons.percent, [
    Unit('%', 'درصد', '%', 0.01),
    Unit('ppm', 'قسمت در میلیون', 'ppm', 1e-6),
    Unit('‰', 'در هزار', '‰', 1e-3),
    Unit('ppb', 'قسمت در میلیارد', 'ppb', 1e-9),
    Unit('ppt', 'قسمت در تریلیون', 'ppt', 1e-12),
    Unit('ratio', 'کسر', 'ratio', 1),
  ]),
  Category('speed', 'سرعت', Icons.speed, [
    Unit('km/h', 'کیلومتر بر ساعت', 'km/h', 1 / 3.6),
    Unit('mph', 'مایل بر ساعت', 'mph', 0.44704),
    Unit('m/s', 'متر بر ثانیه', 'm/s', 1),
    Unit('kn', 'گره دریایی', 'kn', 0.514444444),
    Unit('ft/s', 'فوت بر ثانیه', 'ft/s', 0.3048),
    Unit('Mach', 'ماخ', 'Mach', 340.29),
  ]),
  Category('pace', 'آهنگ دویدن', Icons.directions_run, [
    Unit.fn(
      'min/km',
      'دقیقه بر کیلومتر',
      'min/km',
      (p) => 1000 / (p * 60),
      (v) => 1000 / (v * 60),
    ),
    Unit.fn(
      'min/mi',
      'دقیقه بر مایل',
      'min/mi',
      (p) => 1609.344 / (p * 60),
      (v) => 1609.344 / (v * 60),
    ),
    Unit.fn(
      's/100m',
      'ثانیه بر ۱۰۰ متر',
      's/100m',
      (p) => 100 / p,
      (v) => 100 / v,
    ),
  ]),
  Category('pressure', 'فشار', Icons.compress, [
    Unit('bar', 'بار', 'bar', 1e5),
    Unit('psi', 'پوند بر اینچ مربع', 'psi', 6894.757293168),
    Unit('Pa', 'پاسکال', 'Pa', 1),
    Unit('kPa', 'کیلوپاسکال', 'kPa', 1e3),
    Unit('MPa', 'مگاپاسکال', 'MPa', 1e6),
    Unit('mbar', 'میلی‌بار', 'mbar', 100),
    Unit('atm', 'اتمسفر', 'atm', 101325),
    Unit('mmHg', 'میلی‌متر جیوه', 'mmHg', 133.322387415),
    Unit('Torr', 'تور', 'Torr', 133.32236842),
    Unit('inHg', 'اینچ جیوه', 'inHg', 3386.389),
  ]),
  Category('current', 'جریان الکتریکی', Icons.electric_bolt, [
    Unit('A', 'آمپر', 'A', 1),
    Unit('mA', 'میلی‌آمپر', 'mA', 1e-3),
    Unit('µA', 'میکروآمپر', 'µA', 1e-6),
    Unit('kA', 'کیلوآمپر', 'kA', 1e3),
  ]),
  Category('voltage', 'ولتاژ', Icons.bolt, [
    Unit('V', 'ولت', 'V', 1),
    Unit('mV', 'میلی‌ولت', 'mV', 1e-3),
    Unit('µV', 'میکروولت', 'µV', 1e-6),
    Unit('kV', 'کیلوولت', 'kV', 1e3),
    Unit('MV', 'مگاولت', 'MV', 1e6),
  ]),
  Category('power', 'توان', Icons.power, [
    Unit('W', 'وات', 'W', 1),
    Unit('kW', 'کیلووات', 'kW', 1e3),
    Unit('hp', 'اسب بخار', 'hp', 745.69987158),
    Unit('mW', 'میلی‌وات', 'mW', 1e-3),
    Unit('MW', 'مگاوات', 'MW', 1e6),
    Unit('GW', 'گیگاوات', 'GW', 1e9),
    Unit('PS', 'اسب بخار متریک', 'PS', 735.49875),
    Unit('BTU/h', 'بی‌تی‌یو بر ساعت', 'BTU/h', 0.29307107),
  ]),
  Category('reactive-power', 'توان راکتیو', Icons.power_input, [
    Unit('var', 'وار', 'var', 1),
    Unit('kvar', 'کیلووار', 'kvar', 1e3),
    Unit('Mvar', 'مگاوار', 'Mvar', 1e6),
    Unit('mvar', 'میلی‌وار', 'mvar', 1e-3),
  ]),
  Category('apparent-power', 'توان ظاهری', Icons.electrical_services, [
    Unit('VA', 'ولت‌آمپر', 'VA', 1),
    Unit('kVA', 'کیلوولت‌آمپر', 'kVA', 1e3),
    Unit('MVA', 'مگاولت‌آمپر', 'MVA', 1e6),
    Unit('mVA', 'میلی‌ولت‌آمپر', 'mVA', 1e-3),
  ]),
  Category('energy', 'انرژی', Icons.battery_charging_full, [
    Unit('kWh', 'کیلووات‌ساعت', 'kWh', 3.6e6),
    Unit('J', 'ژول', 'J', 1),
    Unit('kJ', 'کیلوژول', 'kJ', 1e3),
    Unit('MJ', 'مگاژول', 'MJ', 1e6),
    Unit('cal', 'کالری', 'cal', 4.184),
    Unit('kcal', 'کیلوکالری', 'kcal', 4184),
    Unit('Wh', 'وات‌ساعت', 'Wh', 3600),
    Unit('BTU', 'بی‌تی‌یو', 'BTU', 1055.05585),
    Unit('eV', 'الکترون‌ولت', 'eV', 1.602176634e-19),
    Unit('ft·lb', 'فوت‌پوند', 'ft·lb', 1.3558179483),
  ]),
  Category('reactive-energy', 'انرژی راکتیو', Icons.battery_std, [
    Unit('varh', 'وار‌ساعت', 'varh', 1),
    Unit('kvarh', 'کیلووار‌ساعت', 'kvarh', 1e3),
    Unit('Mvarh', 'مگاوار‌ساعت', 'Mvarh', 1e6),
  ]),
  // Base = L/s
  Category('volume-flow-rate', 'دبی حجمی', Icons.water, [
    Unit('L/min', 'لیتر بر دقیقه', 'L/min', 1 / 60),
    Unit('L/s', 'لیتر بر ثانیه', 'L/s', 1),
    Unit('L/h', 'لیتر بر ساعت', 'L/h', 1 / 3600),
    Unit('m³/h', 'متر مکعب بر ساعت', 'm³/h', 1000 / 3600),
    Unit('m³/s', 'متر مکعب بر ثانیه', 'm³/s', 1000),
    Unit('mL/s', 'میلی‌لیتر بر ثانیه', 'mL/s', 1e-3),
    Unit('gal/min', 'گالن بر دقیقه', 'gal/min', 3.785411784 / 60),
    Unit('ft³/s', 'فوت مکعب بر ثانیه', 'ft³/s', 28.316846592),
    Unit('ft³/min', 'فوت مکعب بر دقیقه', 'ft³/min', 28.316846592 / 60),
  ]),
  Category('illuminance', 'روشنایی', Icons.light_mode, [
    Unit('lx', 'لوکس', 'lx', 1),
    Unit('fc', 'فوت‌کندل', 'fc', 10.7639104167),
    Unit('klx', 'کیلولوکس', 'klx', 1e3),
    Unit('ph', 'فوت (phot)', 'ph', 1e4),
  ]),
  Category('frequency', 'فرکانس', Icons.graphic_eq, [
    Unit('Hz', 'هرتز', 'Hz', 1),
    Unit('kHz', 'کیلوهرتز', 'kHz', 1e3),
    Unit('MHz', 'مگاهرتز', 'MHz', 1e6),
    Unit('GHz', 'گیگاهرتز', 'GHz', 1e9),
    Unit('mHz', 'میلی‌هرتز', 'mHz', 1e-3),
    Unit('rpm', 'دور بر دقیقه', 'rpm', 1 / 60),
  ]),
  // Base = radian
  Category('angle', 'زاویه', Icons.architecture, [
    Unit('°', 'درجه', '°', math.pi / 180),
    Unit('rad', 'رادیان', 'rad', 1),
    Unit('grad', 'گراد', 'grad', math.pi / 200),
    Unit('arcmin', 'دقیقه قوسی', 'arcmin', math.pi / 10800),
    Unit('arcsec', 'ثانیه قوسی', 'arcsec', math.pi / 648000),
    Unit('turn', 'دور', 'turn', 2 * math.pi),
  ]),
];

Category catByKey(String k) => categories.firstWhere((c) => c.key == k);
