{
  description = "My personal NUR repository";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  outputs = { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
      # callPackage aborts (uncatchably, so tryEval is no help) when a
      # required argument is missing, which lets one package whose
      # dependencies only an overlay provides poison the whole set. Wrap it
      # to check satisfiability up front and return null instead, which the
      # isDerivation filter below then drops.
      allPackages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          satisfiable = fn: args:
            let
              f = if lib.isFunction fn then fn else import fn;
              required = lib.attrNames (lib.filterAttrs (_: hasDefault: !hasDefault) (lib.functionArgs f));
            in
            lib.all (a: (pkgs ? ${a}) || (args ? ${a})) required;
          safeCallPackage = fn: args: if satisfiable fn args then pkgs.callPackage fn args else null;
        in
        import ./default.nix { pkgs = pkgs // { callPackage = safeCallPackage; }; });
    in
    {
      packages = forAllSystems (system: lib.filterAttrs (_: v: lib.isDerivation v) allPackages.${system});
    };
}
