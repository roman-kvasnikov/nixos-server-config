{
  security = {
    # Sudo настройки для удобства
    sudo = {
      enable = true;

      wheelNeedsPassword = false; # Отключить пароль для wheel (удобно)
      execWheelOnly = true; # Только wheel может использовать sudo
    };
  };
}
