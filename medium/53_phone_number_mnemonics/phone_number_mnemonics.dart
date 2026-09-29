// Phone Number Mnemonics: all letter strings for a digit string ('0' and '1' map to themselves).
// Backtracking over digits. O(4^n * n) time and space.

const _keypad = {
  '0': ['0'],
  '1': ['1'],
  '2': ['a', 'b', 'c'],
  '3': ['d', 'e', 'f'],
  '4': ['g', 'h', 'i'],
  '5': ['j', 'k', 'l'],
  '6': ['m', 'n', 'o'],
  '7': ['p', 'q', 'r', 's'],
  '8': ['t', 'u', 'v'],
  '9': ['w', 'x', 'y', 'z'],
};

List<String> phoneNumberMnemonics(String phoneNumber) {
  final result = <String>[];
  final current = List<String>.filled(phoneNumber.length, '');

  void build(int i) {
    if (i == phoneNumber.length) {
      result.add(current.join());
      return;
    }
    for (final letter in _keypad[phoneNumber[i]]!) {
      current[i] = letter; // overwriting slot i is the "undo"
      build(i + 1);
    }
  }

  build(0);
  return result;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(phoneNumberMnemonics('1905'), ['1w0j', '1w0k', '1w0l', '1x0j', '1x0k', '1x0l', '1y0j', '1y0k', '1y0l', '1z0j', '1z0k', '1z0l']);
  check(phoneNumberMnemonics('23').length, 9);
}
