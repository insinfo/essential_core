import 'package:essential_core/essential_core.dart';

typedef BenchmarkCase = ({String name, String value});

const int _iterations = 100000;
const int _rounds = 7;

const List<BenchmarkCase> _cases = <BenchmarkCase>[
  (name: 'ascii short', value: 'Essential Core Utils'),
  (name: 'accent short', value: 'ação Útil'),
  (
    name: 'ascii paragraph',
    value:
        'Essential Core validates filters, data frames, strings, and document helpers without accents.',
  ),
  (
    name: 'accent paragraph',
    value:
        'Ação útil para validação, remoção de acentuação, informações públicas e integrações.',
  ),
];

void main() {
  print('Accent removal benchmark');
  print('Iterations per round: $_iterations');
  print('Rounds per case: $_rounds\n');

  for (final benchmarkCase in _cases) {
    _runCase(benchmarkCase);
  }
}

void _runCase(BenchmarkCase benchmarkCase) {
  var guard = 0;

  for (var i = 0; i < _iterations ~/ 10; i++) {
    guard += EssentialCoreUtils.removerAcentos(benchmarkCase.value).length;
  }

  final results = <double>[];
  for (var round = 0; round < _rounds; round++) {
    final stopwatch = Stopwatch()..start();
    for (var i = 0; i < _iterations; i++) {
      guard += EssentialCoreUtils.removerAcentos(benchmarkCase.value).length;
    }
    stopwatch.stop();
    results.add(stopwatch.elapsedMicroseconds * 1000 / _iterations);
  }

  results.sort();
  final best = results.first;
  final median = results[results.length ~/ 2];
  final worst = results.last;
  print(
    '${benchmarkCase.name.padRight(18)} '
    'best=${best.toStringAsFixed(1).padLeft(7)} ns/op '
    'median=${median.toStringAsFixed(1).padLeft(7)} ns/op '
    'worst=${worst.toStringAsFixed(1).padLeft(7)} ns/op '
    'guard=$guard',
  );
}
