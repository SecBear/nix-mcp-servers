{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  # Additional metadata is provided by Snowfall Lib.
  # The system architecture for this host (eg. `x86_64-linux`).
  system,
  # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  target,
  # A normalized name for the system target (eg. `iso`).
  format,
  # A boolean to determine whether this system is a virtual target using nixos-generators.
  virtual,
  # An attribute map of your defined hosts.
  systems,
  # All other arguments come from the module system.
  config,
  ...
}: let
  namespace = "nix-mcp-servers";
  cfg = config.${namespace};
in {
  # config.${namespace}.default

  _file = ./default.nix;


  imports = [
    ./clients
    ./servers
  ];

  options.${namespace} = with lib.types; {
    enable = lib.mkEnableOption "Enable MCP Servers";

    configPath = lib.mkOption {
      type = str;
      description = "Path where to store MCP configuration files";
      default = "~/Library/Application Support/mcp";
    };
  };

 config = {
    # First add the lib extension piece
    _module.args.lib = lib.extend (self: super: {
      ${namespace} = import ../../../lib {
        lib = super;
        inherit inputs;
        snowfall-inputs = inputs;
      };
    });
    
    # Then add the conditional pieces if enabled
    system = lib.mkIf cfg.enable {
      activationScripts.postUserActivation.text = ''
        mkdir -p "${cfg.configPath}"
      '';
    };
    
    assertions = lib.mkIf cfg.enable [
      {
        assertion = !(cfg.clients.claude.enable && cfg.clients.claude.useFilesystemServer) || cfg.servers.filesystem.enable;
        message = "When Claude is configured to use the filesystem server, the filesystem server must be enabled.";
      }
    ];
  };
}