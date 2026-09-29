// Shorten Path: simplify a Unix path (handles '.', '..', repeated '/', absolute vs relative).
// Stack of directory tokens. O(n) time and space.

String shortenPath(String path) {
  final isAbsolute = path.startsWith('/');
  final stack = <String>[];
  for (final token in path.split('/')) {
    if (token.isEmpty || token == '.') continue;
    if (token == '..') {
      if (stack.isEmpty || stack.last == '..') {
        // Relative paths keep leading '..'; absolute paths cannot go above root.
        if (!isAbsolute) stack.add('..');
      } else {
        stack.removeLast();
      }
    } else {
      stack.add(token);
    }
  }
  final joined = stack.join('/');
  return isAbsolute ? '/$joined' : (joined.isEmpty ? '.' : joined);
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(shortenPath('/foo/../test/../test/../foo//bar/./baz'), '/foo/bar/baz');
  check(shortenPath('foo/../..'), '..');
  check(shortenPath('/../..'), '/');
  check(shortenPath('../../foo/bar/..'), '../../foo');
  check(shortenPath('./.'), '.');
}
