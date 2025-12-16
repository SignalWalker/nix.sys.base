{
  lib,
  ...
}:
{
  imports = lib.listFilePaths ./src;
  config = { };
}

