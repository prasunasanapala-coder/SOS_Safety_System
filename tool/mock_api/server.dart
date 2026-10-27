// ignore_for_file: avoid_print
// Tiny mock REST server for Experiment 9.
//
// Run from the project root:   dart run tool/mock_api/server.dart [port]
// Example:                     dart run tool/mock_api/server.dart 8787
// Then open:                   http://localhost:8787/tips.json
//
// It serves mock_api/tips.json with CORS enabled so Flutter Web (Chrome) can
// call it. Use the "/empty", "/error" and "/slow" paths to demo the empty,
// error and loading states.
import 'dart:convert';
import 'dart:io';

Future<HttpServer> _bind(int port) async {
  try {
    return await HttpServer.bind(InternetAddress.anyIPv4, port);
  } on SocketException {
    // Some Windows setups block listening on all interfaces. Localhost-only
    // is enough for Chrome and the Android emulator (10.0.2.2).
    print('Could not listen on all interfaces, trying localhost only...');
    return HttpServer.bind(InternetAddress.loopbackIPv4, port);
  }
}

Future<void> main(List<String> args) async {
  final port = args.isNotEmpty ? int.tryParse(args.first) ?? 8080 : 8080;

  final file = File('mock_api/tips.json');
  if (!file.existsSync()) {
    stderr.writeln('Run this from the project root: mock_api/tips.json not found.');
    exit(1);
  }

  final HttpServer server;
  try {
    server = await _bind(port);
  } on SocketException catch (e) {
    stderr.writeln('Cannot use port $port: ${e.message}');
    stderr.writeln('Try another port, for example: dart run tool/mock_api/server.dart 8787');
    exit(1);
  }

  stdout.writeln('Mock tips API listening on http://localhost:$port');
  stdout.writeln('  /tips.json  normal response');
  stdout.writeln('  /empty      empty list');
  stdout.writeln('  /error      HTTP 500');
  stdout.writeln('  /slow       responds after 3 seconds');

  await for (final request in server) {
    final response = request.response;
    response.headers
      ..set('Access-Control-Allow-Origin', '*')
      ..set('Access-Control-Allow-Headers', '*')
      ..contentType = ContentType.json;

    if (request.method == 'OPTIONS') {
      response.statusCode = HttpStatus.noContent;
      await response.close();
      continue;
    }

    switch (request.uri.path) {
      case '/tips.json':
        response.write(await file.readAsString());
      case '/slow':
        await Future<void>.delayed(const Duration(seconds: 3));
        response.write(await file.readAsString());
      case '/empty':
        response.write(jsonEncode({'tips': <Object>[]}));
      case '/error':
        response.statusCode = HttpStatus.internalServerError;
        response.write(jsonEncode({'error': 'Simulated server error'}));
      default:
        response.statusCode = HttpStatus.notFound;
        response.write(jsonEncode({'error': 'Not found'}));
    }
    await response.close();
  }
}