{
  description = "Hugo development environment for The Comfy Seat";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          serve = pkgs.writeShellScriptBin "serve" ''
            exec hugo server --watch --buildDrafts --buildFuture "$@"
          '';

          build = pkgs.writeShellScriptBin "build" ''
            exec hugo --minify "$@"
          '';

          build-preview = pkgs.writeShellScriptBin "build-preview" ''
            exec hugo --minify --buildDrafts --buildFuture "$@"
          '';

          clean = pkgs.writeShellScriptBin "clean" ''
            rm -rf public/ resources/
            echo "Cleaned public/ and resources/"
          '';

          new-post = pkgs.writeShellScriptBin "new-post" ''
            set -euo pipefail
            if [ $# -eq 0 ]; then
              echo "Usage: new-post <slug>"
              echo "  Example: new-post my-new-article"
              exit 1
            fi
            slug="$1"
            post_date=$(date +%Y-%m-%d)
            file="content/posts/''${post_date}-''${slug}.md"
            title=$(printf '%s' "$slug" | ${pkgs.python3}/bin/python3 -c "
            import sys
            slug = sys.stdin.read().strip()
            words = slug.split('-')
            small = {'a','an','the','and','but','or','for','nor','on','at','to','by','in','of','with'}
            result = [w.capitalize() if i == 0 or w.lower() not in small else w for i, w in enumerate(words)]
            print(' '.join(result))
            ")
            if [ -f "$file" ]; then
              echo "Error: $file already exists" >&2
              exit 1
            fi
            printf -- '---\ntitle: "%s"\nslug: "%s"\ndate: %s\nauthor: gene\n---\n\n' \
              "$title" "$slug" "$post_date" > "$file"
            echo "Created $file"
          '';

        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.hugo
              pkgs.dart-sass
              serve
              build
              build-preview
              clean
              new-post
            ];

            shellHook = ''
              echo ""
              echo "The Comfy Seat — dev shell"
              echo ""
              echo "  serve              start local server (watch, drafts, future posts)"
              echo "  build              production build (minified)"
              echo "  build-preview      preview build (drafts + future posts)"
              echo "  clean              remove public/ and resources/"
              echo "  new-post <slug>    create a new post (e.g. new-post my-new-article)"
              echo ""
            '';
          };
        }
      );
    };
}
