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
            bundle="content/posts/''${post_date}-''${slug}"
            file="''${bundle}/index.md"
            title=$(printf '%s' "$slug" | ${pkgs.python3}/bin/python3 -c "
            import sys
            slug = sys.stdin.read().strip()
            words = slug.split('-')
            small = {'a','an','the','and','but','or','for','nor','on','at','to','by','in','of','with'}
            result = [w.capitalize() if i == 0 or w.lower() not in small else w for i, w in enumerate(words)]
            print(' '.join(result))
            ")
            if [ -d "$bundle" ]; then
              echo "Error: $bundle already exists" >&2
              exit 1
            fi
            mkdir -p "$bundle"
            printf -- '---\ntitle: "%s"\nslug: "%s"\ndate: %s\nauthor: gene\n---\n\n' \
              "$title" "$slug" "$post_date" > "$file"
            echo "Created $file"
            echo "(Place post images in $bundle/ and reference them with relative paths)"
          '';

          add-post-image = pkgs.writeShellScriptBin "add-post-image" ''
            set -euo pipefail
            SRC="''${1:-}"
            if [ -z "$SRC" ]; then
              echo "Usage: add-post-image <source-image> [post-bundle-name]"
              echo "  Example: add-post-image ~/Downloads/photo.jpg 2026-05-04-my-post"
              exit 1
            fi
            if [ ! -f "$SRC" ]; then
              echo "Error: file not found: $SRC" >&2; exit 1
            fi

            WIDTH=$(magick identify -format "%w" "$SRC")
            HEIGHT=$(magick identify -format "%h" "$SRC")

            echo ""
            echo "=== Image analysis: ''${WIDTH}x''${HEIGHT} ==="

            # Quality choice
            if [ "$WIDTH" -lt 960 ]; then
              QUALITY=90
              echo "  Size:    SMALL (< 960 px wide) — CSS will upscale to fill the column"
              echo "           Quality set to q90 to reduce upscale artifacts"
            elif [ "$WIDTH" -lt 1200 ]; then
              QUALITY=85
              echo "  Size:    OK for display (≥ 960 px); a bit narrow for social cards (ideal 1200 px)"
            else
              QUALITY=85
              echo "  Size:    GOOD for both display and social cards"
            fi

            if [ "$WIDTH" -gt 1920 ]; then
              echo "  Warning: Very wide (''${WIDTH}px). Tip: resize to ~1200px first to reduce file size:"
              echo "           magick '$SRC' -resize 1200x resized.jpg"
            fi

            # Aspect ratio check (ideal OG card is ~1.91:1)
            RATIO_NUM=$((WIDTH * 100 / HEIGHT))
            if [ "$RATIO_NUM" -lt 150 ]; then
              echo "  Aspect:  TALL or SQUARE — social card will letterbox; landscape (≥3:2) works better"
            elif [ "$RATIO_NUM" -lt 175 ]; then
              echo "  Aspect:  Close to 3:2 — acceptable; ideal for OG cards is closer to 1.91:1 (190)"
            elif [ "$RATIO_NUM" -lt 205 ]; then
              echo "  Aspect:  GOOD — close to the 1.91:1 OG card ideal"
            else
              echo "  Aspect:  Wide (>2:1) — list thumbnail will look good; OG card may crop top/bottom"
            fi
            echo ""

            BASENAME=$(basename "$SRC")
            STEM="''${BASENAME%.*}"
            WEBPFILE="''${STEM}.webp"

            if [ $# -ge 2 ]; then
              MATCH=$(find content/posts -maxdepth 1 -type d -name "*$2*" 2>/dev/null | head -1)
              if [ -z "$MATCH" ]; then
                echo "Error: no post bundle matching '$2'" >&2
                echo "Available bundles:"; ls content/posts/; exit 1
              fi
              BUNDLE="$MATCH"
            else
              echo ""
              echo "Available post bundles (most recent first):"
              ls -1dt content/posts/*/ 2>/dev/null | head -15 | while read -r d; do basename "$d"; done
              echo ""
              printf "Bundle name (full or partial): "
              read -r INPUT
              MATCH=$(find content/posts -maxdepth 1 -type d -name "*$INPUT*" 2>/dev/null | head -1)
              if [ -z "$MATCH" ]; then
                echo "Error: no bundle matching '$INPUT'" >&2; exit 1
              fi
              BUNDLE="$MATCH"
            fi

            DEST="$BUNDLE/$WEBPFILE"
            echo "Converting: $SRC → $DEST"
            cwebp -q "$QUALITY" "$SRC" -o "$DEST"
            echo ""
            echo "✓ EXIF metadata stripped (GPS, camera info, timestamps removed by default)"
            echo ""
            echo "Add to front matter (or use as inline image):"
            echo "  image:"
            echo "    path: '$WEBPFILE'"
            echo "    alt: 'TODO: describe the image'"
            echo ""
            echo "For inline markdown: ![alt text]($WEBPFILE)"
          '';

        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.hugo
              pkgs.imagemagick
              pkgs.libwebp
              serve
              build
              build-preview
              clean
              new-post
              add-post-image
            ];

            shellHook = ''
              echo ""
              echo "The Comfy Seat — dev shell"
              echo ""
              echo "  serve                       start local server (watch, drafts, future posts)"
              echo "  build                       production build (minified)"
              echo "  build-preview               preview build (drafts + future posts)"
              echo "  clean                       remove public/ and resources/"
              echo "  new-post <slug>             scaffold a new post bundle"
              echo "  add-post-image <img> [slug] convert image to WebP and add to post bundle"
              echo ""
              echo "Raw image tools (if you need manual control):"
              echo "  cwebp -q 85 src.png -o out.webp   convert to WebP"
              echo "  magick src.png -resize 1200x out.jpg   resize with ImageMagick"
              echo ""
            '';
          };
        }
      );
    };
}
