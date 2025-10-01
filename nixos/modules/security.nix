{
  security = {
    sudo = {
      enable = true;

      wheelNeedsPassword = true; # true - требует пароль для выполнения sudo.
      execWheelOnly = true; # true - позволяет только пользователям из группы wheel выполнять sudo.
    };
  };
}
