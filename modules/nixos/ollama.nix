{ config, lib, pkgs, ... }:
{
  # Local model runtime, GPU-accelerated. AI CLIs can target http://127.0.0.1:11434.
  services.ollama = {
    enable = true;
    acceleration = "cuda"; # NVIDIA; pulls the CUDA closure (large first build).
    host = "127.0.0.1";
    port = 11434;
  };

  # open-webui is handy but optional; uncomment to get a local chat UI.
  # services.open-webui = {
  #   enable = true;
  #   host = "127.0.0.1";
  #   port = 8080;
  # };

  # Persist downloaded models across the wipe-on-boot root. (Verify ownership of
  # /var/lib/ollama matches the ollama service user after first switch.)
  environment.persistence."/persist".directories = [ "/var/lib/ollama" ];
}
