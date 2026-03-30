class EssentialCoreUtils {
  static String hidePartsOfString(String string,
      {int visibleCharacters = 2, String trail = '*'}) {
    if (string.length < visibleCharacters) {
      return string;
    }
    return string.substring(0, visibleCharacters) +
        (trail * (string.length - visibleCharacters));
  }

  static String removerAcentos(String s) {
    var map = <String, String>{
      'â': 'a',
      'Â': 'A',
      'à': 'a',
      'À': 'A',
      'á': 'a',
      'Á': 'A',
      'ã': 'a',
      'Ã': 'A',
      'ê': 'e',
      'Ê': 'E',
      'è': 'e',
      'È': 'E',
      'é': 'e',
      'É': 'E',
      'î': 'i',
      'Î': 'I',
      'ì': 'i',
      'Ì': 'I',
      'í': 'i',
      'Í': 'I',
      'õ': 'o',
      'Õ': 'O',
      'ô': 'o',
      'Ô': 'O',
      'ò': 'o',
      'Ò': 'O',
      'ó': 'o',
      'Ó': 'O',
      'ü': 'u',
      'Ü': 'U',
      'û': 'u',
      'Û': 'U',
      'ú': 'u',
      'Ú': 'U',
      'ù': 'u',
      'Ù': 'U',
      'ç': 'c',
      'Ç': 'C'
    };
    var result = s;
    map.forEach((key, value) {
      result = result.replaceAll(key, value);
    });

    return result;
  }
}
