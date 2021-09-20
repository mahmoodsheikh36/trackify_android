String validatePasswordInput(String password) {
  if (password.isEmpty)
    return 'password cant be empty';
  if (password.length > 93)
    return 'password too long';
  return null;
}

String validateUsernameInput(String username) {
  if (username.isEmpty)
    return 'username cant be empty';
  if (username.length > 29) {
    return 'username too long';
  }
  return null;
}

String validateEmailInput(String email) {
  bool valid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  if (!valid)
    return 'email not valid';
  return null;
}
