# Orion OS — branding assets

> **All assets in this directory are placeholders.** Real branding lands in
> milestone **M8**. Do not ship the placeholder logo or wallpaper to end users.

## Layout

```
branding/
├── logo/
│   ├── orion-logo.png        # 512×512 placeholder mark
│   └── orion-logo-64.png     # 64×64 small version (taskbar / favicon)
└── wallpapers/
    ├── orion-default-1080p.png   # 1920×1080
    └── orion-default-4k.png      # 3840×2160
```

## Why placeholders ship now (P#1.8)

The image build (P#1.4) and ISO build (P#1.5) need *some* asset paths to
exist so the file-installation step in the recipe does not fail. Shipping
placeholders unblocks end-to-end pipeline testing without forcing the M8
brand work to happen early.

## Placeholder design

- **Logo:** Deep navy circle, three-dot Orion-belt motif in white, small
  blue accent star. Generated programmatically — see PR description for
  the script.
- **Wallpapers:** Vertical gradient (#050a1e → #0f193e), random
  starfield, three-star belt accent at the lower-left third.

## Replacing these assets

When real assets land in M8:

1. Replace files **in place** keeping the same filenames so recipes do not
   need updating.
2. Delete this `README.md` once the assets are real.
3. Do **not** delete intermediate sizes; the OSes that reference each
   resolution must continue to work.

## Licensing

Placeholders are released under the same GPL-3.0-or-later licence as the
rest of the project. Real M8 assets may carry their own creative licence
(e.g. CC-BY-SA); that decision happens in the M8 PR with full attribution.
