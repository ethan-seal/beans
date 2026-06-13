{
  description = "Beans - an agentic-first issue tracker";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          version = self.shortRev or self.dirtyShortRev or "dev";

          frontend = pkgs.stdenv.mkDerivation {
            pname = "beans-frontend";
            version = "0.0.1";
            src = ./frontend;

            pnpmDeps = pkgs.fetchPnpmDeps {
              pname = "beans-frontend";
              version = "0.0.1";
              src = ./frontend;
              hash = "sha256-jvvI97UXo5V4NcoiDUAA3/jRngrce+AZAluRXKJnJAw=";
              fetcherVersion = 3;
            };

            nativeBuildInputs = [
              pkgs.nodejs
              pkgs.pnpm_10
              pkgs.pnpmConfigHook
            ];

            buildPhase = ''
              runHook preBuild
              pnpm build
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall
              cp -r build $out
              runHook postInstall
            '';
          };
        in
        {
          default = pkgs.buildGoModule {
            pname = "beans";
            inherit version;
            src = ./.;

            vendorHash = "sha256-sBTVjdkpR90UvEOWo2qCzezYDucBTebZck0t4xYulZ0=";

            preBuild = ''
              rm -rf internal/web/dist
              mkdir -p internal/web/dist
              cp -r ${frontend}/* internal/web/dist/
              touch internal/web/dist/.gitkeep
            '';

            ldflags = [
              "-X github.com/hmans/beans/internal/version.Version=${version}"
              "-X github.com/hmans/beans/internal/version.Commit=${version}"
              "-X github.com/hmans/beans/internal/version.Date=1970-01-01T00:00:00Z"
            ];

            subPackages = [
              "cmd/beans"
              "cmd/beans-serve"
              "cmd/beans-tui"
            ];

            meta = {
              description = "An agentic-first issue tracker";
              homepage = "https://github.com/hmans/beans";
              license = pkgs.lib.licenses.asl20;
              mainProgram = "beans";
            };
          };
        });
    };
}
