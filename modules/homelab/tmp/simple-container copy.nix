{
  virtualisation.oci-containers.containers = {
    # База данных (запускается первой)
    database = {
      image = "docker.io/library/postgres:15-alpine";
      autoStart = true;
      ports = ["6789:5432"];
      environment = {
        POSTGRES_DB = "myapp";
        POSTGRES_USER = "myuser";
        POSTGRES_PASSWORD = "mypass";
      };
    };

    # Redis (независимый сервис)
    cache = {
      image = "docker.io/library/redis:7-alpine";
      autoStart = true;
      ports = ["6379:6379"];
    };

    # Приложение, которое зависит от database и cache
    application = {
      image = "docker.io/library/alpine:latest";
      autoStart = true;
      # Эти контейнеры должны существовать в той же конфигурации!
      dependsOn = ["database" "cache"];
      environment = {
        DB_HOST = "localhost";
        REDIS_HOST = "localhost";
      };
      cmd = ["sleep" "infinity"]; # Заглушка для примера
    };
  };
}
