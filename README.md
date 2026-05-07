[![Netlify Status](https://api.netlify.com/api/v1/badges/97ae1a85-7c98-42a3-90d2-b24f2e51e321/deploy-status)](https://app.netlify.com/projects/beantown-beanbag/deploys)

# The code behind beanbag.technicalissues.us

Check out the live version of this website at [https://beanbag.technicalissues.us](https://beanbag.technicalissues.us)

## Contributing

Want to add a post or fix an error? Create a branch and open a pull request against `main`.

See an error? Open an issue and I'll do my best to get it fixed. Pull requests are welcome.

## Images for posts

### Target dimensions

**Aim for 1200×630 px** — this hits the sweet spot for both in-site display and social share cards:

| Context | How it's used |
|---|---|
| Post header (in-site) | Displayed at `width: 100%` of the content column (~960 px). Hugo automatically downscales images wider than 960 px for display; the original is preserved for the OG image tag. |
| Post list thumbnail | Cropped to a fixed 200 px tall strip via `object-fit: cover`. Landscape images (≥2:1 wide) work best. |
| OG / Twitter card | `og:image` and `twitter:image` use the original file at its full resolution. The recommended size for `summary_large_image` is **1200×628 px** (≈1.91:1 ratio). |

Images **narrower than 960 px** are displayed as-is (never upscaled by the template), so compression artifacts show more when the browser CSS-stretches them to fill the column. If your image source is smaller than 960 px, convert it at `-q 90` instead of `-q 85` to preserve quality.

### Format and conversion

All post images live inside their [page bundle](https://gohugo.io/content-management/page-bundles/) directory (`content/posts/SLUG/`). Use the devshell helper to convert and place images — it picks the right quality automatically, tells you how the image measures up, and **strips all EXIF metadata** (GPS location, camera info, timestamps) as part of the WebP conversion:

```bash
# Enter the dev shell first
nix develop

# Convert and add to a post (prompts for bundle if not specified)
add-post-image ~/Downloads/photo.jpg
add-post-image ~/Downloads/photo.jpg 2026-05-04-my-post-slug
```

The command will output the front matter snippet to paste into your post.

Then reference the file in the post's front matter:

```yaml
image:
  path: 'output.webp'
  alt: 'Descriptive alt text'
  width: 1200   # optional, for og:image:width
  height: 630   # optional, for og:image:height
```
