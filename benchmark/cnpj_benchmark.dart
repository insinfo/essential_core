import 'package:essential_core/essential_core.dart';

typedef BenchmarkCase = ({String name, String? value});

const int _iterations = 1000000;
const int _rounds = 7;

const List<BenchmarkCase> _cases = <BenchmarkCase>[
  (name: 'numeric raw valid', value: '54550752000155'),
  (name: 'numeric formatted valid', value: '54.550.752/0001-55'),
  (name: 'alphanumeric raw valid', value: '12ABC34501DE35'),
  (name: 'alphanumeric formatted valid', value: '12.ABC.345/01DE-35'),
  (name: 'lowercase/spaces valid', value: ' 12 abc 345 01de 35 '),
  (name: 'invalid check digits', value: '12ABC34501DE36'),
  (name: 'malformed invalid char', value: '12_ABC34501DE35'),
  (name: 'blacklisted numeric', value: '11.111.111/1111-11'),
  (name: 'null', value: null),
];

void main() {
  print('CNPJ validator benchmark');
  print('Iterations per round: $_iterations');
  print('Rounds per case: $_rounds\n');

  for (final benchmarkCase in _cases) {
    _runCase(benchmarkCase);
  }
}

void _runCase(BenchmarkCase benchmarkCase) {
  var guard = 0;

  for (var i = 0; i < _iterations ~/ 10; i++) {
    if (EssentialCoreUtils.validarCnpj(benchmarkCase.value)) {
      guard++;
    }
  }

  final results = <double>[];
  for (var round = 0; round < _rounds; round++) {
    final stopwatch = Stopwatch()..start();
    for (var i = 0; i < _iterations; i++) {
      if (EssentialCoreUtils.validarCnpj(benchmarkCase.value)) {
        guard++;
      }
    }
    stopwatch.stop();
    results.add(stopwatch.elapsedMicroseconds * 1000 / _iterations);
  }

  results.sort();
  final best = results.first;
  final median = results[results.length ~/ 2];
  final worst = results.last;
  print(
    '${benchmarkCase.name.padRight(28)} '
    'best=${best.toStringAsFixed(1).padLeft(7)} ns/op '
    'median=${median.toStringAsFixed(1).padLeft(7)} ns/op '
    'worst=${worst.toStringAsFixed(1).padLeft(7)} ns/op '
    'guard=$guard',
  );
}
