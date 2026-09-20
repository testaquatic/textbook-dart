import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:todo_server_shelf/middleware/injection_middlewae.dart';

extension RequestTodoServerExt on Request {
  Future<Map<String, dynamic>> json() async {
    return jsonDecode(await readAsString()) as Map<String, dynamic>;
  }

  T readState<T extends Object>() {
    return getState<T>(this);
  }

  Request provideState<T extends Object>(T value) {
    final valueTypeString = value.runtimeType.toString();
    final request = change(context: {...context, valueTypeString: value});

    return request;
  }
}
