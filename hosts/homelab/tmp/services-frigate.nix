# Example configuration for using the Frigate module with two cameras
# Add this to your NixOS configuration
{
  config,
  pkgs,
  ...
}: {
  # Import the module
  imports = [
    ./frigatectl.nix # Path to the module file
  ];

  # Enable and configure Frigate
  homelab.services.frigatectl = {
    enable = true;

    # Optional: customize the domain
    # host = "cctv.yourdomain.com";

    # Configure first camera
    camera1 = {
      enable = true;
      name = "entrance"; # Camera name as shown in your screenshot
      streamUrl = "rtsp://admin:password@192.168.1.30:554/Streaming/Channels/101";

      detectResolution = {
        width = 1920;
        height = 1080;
      };

      recordEnabled = true;
      snapshotsEnabled = true;

      # Optional: define motion mask to ignore certain areas
      # motionMask = ["0,0,300,0,300,200,0,200"];
    };

    # Configure second camera
    camera2 = {
      enable = true;
      name = "backyard"; # Camera name as shown in your screenshot
      streamUrl = "rtsp://admin:password@192.168.1.31:554/Streaming/Channels/101";

      detectResolution = {
        width = 1920;
        height = 1080;
      };

      recordEnabled = true;
      snapshotsEnabled = true;
    };

    # Detection settings
    detection = {
      enabled = true;
      fps = 5;
      objects = ["person" "car" "cat" "dog" "bicycle"];

      # Optional: Enable Coral TPU for better performance
      # coralDevice = "usb";  # or "pci" for M.2 Coral
    };

    # Recording retention
    recording = {
      retainDays = 7; # Keep recordings for 7 days
      events = {
        retainDays = 14; # Keep event recordings for 14 days
        preCapture = 5; # Record 5 seconds before event
        postCapture = 10; # Record 10 seconds after event
      };
    };

    # Snapshots retention
    snapshots = {
      enabled = true;
      retainDays = 30; # Keep snapshots for 30 days
    };

    # Optional: Enable MQTT for Home Assistant integration
    # mqtt = {
    #   enabled = true;
    #   host = "192.168.1.10";
    #   port = 1883;
    #   user = "frigate";
    #   password = "mqtt_password";
    # };

    # Homepage widget configuration
    homepage = {
      name = "Frigate NVR";
      description = "AI-powered video surveillance";
      icon = "frigate.svg";
      category = "Security";
    };
  };

  # Optional: Open firewall port if not using nginx
  # networking.firewall.allowedTCPPorts = [ 5000 ];

  # Optional: Mount external storage for recordings
  # fileSystems."/var/lib/frigate/recordings" = {
  #   device = "/dev/disk/by-uuid/your-disk-uuid";
  #   fsType = "ext4";
  #   options = [ "defaults" "nofail" ];
  # };
}
