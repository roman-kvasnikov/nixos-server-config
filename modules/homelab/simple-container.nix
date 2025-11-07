{
  virtualisation.oci-containers.containers.test-container = {
    autoStart = true; # контейнер стартует вместе с системой
    image = "docker.io/library/alpine:latest"; # минимальный образ
    command = ["sh"]; # запускаем оболочку внутри контейнера
  };
}
