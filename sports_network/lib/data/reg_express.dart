class RegExpressions {
  //initializing patterns for textfield validation
  static RegExp emailPattern =
      RegExp(r'(^[0-9a-zA-Z_.]+\@[a-z]+\.[a-z]+(\.[a-z]+)?$)');
  static RegExp passwordPattern = RegExp(r'([0-9a-zA-Z_.@$^&]{1,12})');
  // static RegExp phoneNoPattern =
  //     RegExp(r'(^\+\d{1,3}\s?\d{1,4}(\-\s)?\d{1,3}(\-\s)?\d{1,4}$)');
}
