let
  terra = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHyS/8OGr5KbM1PS7QO3qEwE1xN4JuEzI2SzkBWzks7c";
  hermes = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILkFAhZAMIcFMiOD8MaHZgQLANcDWy/wCFBaAQQ+TPE2";
  artemis = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL96LFIgKgNXAQPl9y/EtWwxBZtRatxGk535ZxDy/IU5";
  ash = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFqg4NlJu7u1pcCel3EZshVwUxIfwpsh2fxhaQlLAar";
  keys = [terra hermes artemis ash];
in {
  "gossipSecret.age".publicKeys = keys;
}
