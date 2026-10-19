# Colima VM sized for this Mac (10 CPUs, 24 GiB): enough for a few services
# while leaving most memory to macOS. Rosetta runs amd64 images at near-native speed.
{
  services.colima.profiles.default.settings = {
    cpu = 4;
    memory = 8;
    rosetta = true;
  };
}
