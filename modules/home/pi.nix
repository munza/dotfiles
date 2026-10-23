# Pi coding agent. Pi writes to its own settings.json (model picks, changelog),
# so it stays writable: programs.pi-coding-agent.settings is merged into it on
# rebuild and wins; everything else is kept. When `packages` changes, pi
# installs or removes them itself.
{ flake, inputs, ... }:
flake.lib.mkModule {
  name = "pi";
  description = "the Pi coding agent";
  enable = false;

  glue =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.pi-coding-agent;
      file = "${cfg.configDir}/settings.json";
      settings = (pkgs.formats.json { }).generate "pi-settings.json" cfg.settings;
      jq = lib.getExe pkgs.jq;
    in
    {
      programs.pi-coding-agent = {
        enable = true;
        package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi;
      };

      # home-manager would link a read-only settings.json; merge into it instead.
      home.file.${file}.enable = lib.mkForce false;

      home.activation.piSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        before=$(${jq} -c '.packages // []' "${file}" 2>/dev/null || echo '[]')
        tmp=$(mktemp)
        if [[ -f "${file}" ]]; then
          ${jq} -s '.[0] * .[1]' "${file}" ${settings} > "$tmp"
        else
          cp ${settings} "$tmp"
        fi
        after=$(${jq} -c '.packages // []' "$tmp")
        run mkdir -p "${cfg.configDir}"
        run mv "$tmp" "${file}"
        # Pi installs packages with npm, which needs node on PATH.
        if [[ "$before" != "$after" ]]; then
          PATH="${pkgs.nodejs}/bin:$PATH" run ${lib.getExe cfg.package} update --extensions
        fi
      '';
    };
}
