# Steepr 1.5.0 App Store assets

## iPhone screenshots

Upload `final/01` through `final/08` in filename order. Every image is 1284 × 2778 pixels. `01-one-tap-quick-picks.png` and `02-expanded-tea-library.png` were recaptured from the 1.5.0 build on the iPhone 17 Pro simulator (six Quick Picks, 52-tea library caption). `03` through `08` and the Watch captures are carried forward unchanged from 1.4.0. The Live Activities composition dates from 1.3.0 because the headless simulator cannot render the Lock Screen or Dynamic Island.

The source captures are in `raw/` and `watch-raw/`. The local HTML layouts add headlines and device framing to those real captures. Regenerate a composition by opening the page at a 1284 × 2778 viewport and capturing it:

- `design/index.html?shot=quick` (or `library`, `timer`, `completion`, `pro`)
- `design/watch.html?shot=watch`
- `design/personal.html` (capture `raw/05-personal-timing.png` by launching the Debug build with `--screenshot-learned-brew`)

## Apple Watch screenshots

`watch/` contains the Watch captures carried forward from 1.4.0 at 416 × 496 pixels, flattened to RGB for App Store Connect.

## Product page header

The 1.4.0 header is unchanged and lives in `../1.4.0/header/`.

<!-- 1.4.0 notes below -->

`header/product-page-header.png` is a 3840 × 1646 pixel, opaque promotional header for the App Store product page. It was generated for this release from a tea still-life prompt: an ivory ceramic cup with amber tea on a forest green surface, loose leaves, warm side light, negative space, and no text, device, logo, or people. It is separate from the screenshot set.

## Release checks

- Validate the screenshot and header dimensions with `sips` before uploading.
- Review the eight iPhone screenshots in order on the App Store Connect 1.5.0 product page.
- Verify the new header on a supported iOS product page after it is staged.
