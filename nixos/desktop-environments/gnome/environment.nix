{
  pkgs,
  lib,
  ...
}: {
  environment = {
    gnome.excludePackages = with pkgs; [
      # gnome-control-center # Control Center (включая Manage Printing)
      gnome-console # Console
      gnome-characters # Редко используется
      gnomeExtensions.order-gnome-shell-extensions # Extensions
      gnome-shell-extensions # Extensions
      gnome-extension-manager # Extensions
      gnome-tour # Тур по Gnome
      gnome-contacts # Контакты
      gnome-music # Музыка
      gnome-photos # Фото
      gnome-software # Центр приложений
      gnome-boxes # Виртуальные машины
      gnome-builder # IDE для разработки
      gnome-font-viewer # Просмотр шрифтов
      gnome-terminal # Используем kitty
      gnome-tweaks # Настройки Gnome

      file-roller # Есть лучшие архиваторы
      simple-scan # Редко нужно
      seahorse # Используем KeePassXC
      epiphany # Используем Brave
      geary # Веб-клиенты лучше
      evolution # Thunderbird лучше
      totem # VLC лучше

      # Игры (не нужны для рабочего компьютера)
      aisleriot
      gnome-chess
      gnome-mahjongg
      iagno
      tali
      hitori
      atomix
      four-in-a-row
      gnome-robots
      gnome-sudoku
      gnome-taquin
      gnome-tetravex
      lightsoff

      # Документация (не нужна в GUI)
      yelp
      gnome-user-docs

      # Дополнительные приложения
      cheese # Камера - редко используется
      baobab # Анализатор дисков - есть альтернативы
    ];
  };
}
