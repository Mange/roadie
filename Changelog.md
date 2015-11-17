### dev

[full changelog](https://github.com/Mange/roadie/compare/v3.1.0...master)

* Nothing yet.

### 3.1.0

[full changelog](https://github.com/Mange/roadie/compare/v3.1.0.rc1...v3.1.0)

* Enchancements:
  * `NetHttpProvider` validates the whitelist hostnames; passing an invalid hostname will raise `ArgumentError`.
  * `NetHttpProvider` supports scheme-less URLs (`//foo.com/`), defaulting to `https`.

### 3.1.0.rc1

[full changelog](https://github.com/Mange/roadie/compare/v3.0.5...v3.1.0.rc1)

* Enhancements:
  * Allow user to specify asset providers for referenced assets with full URLs and inline them (#107)
  * Pass `Document` instance to transformation callbacks (#86)
  * Made `nokogiri` dependency more forgiving.
    * Supports `1.5.0`...`1.7.0` now instead of `1.6.0`...`1.7.0`. Some people out there are stuck on this older version of Nokogiri, and I don't want to leave them out.
  * Output better errors when no assets can be found.
    * The error will now show which providers were tried and in which order, along with the error message from the specific providers.
    * `Roadie::FilesystemProvider` shows the given path when inspected.
  * `data-roadie-ignore` attributes will now be removed from markup; hiding "development markers" in the final email.
  * Add a `Roadie::CachedProvider` asset provider that wraps other providers and cache them.
  * Add a `Roadie::PathRewriterProvider` asset provider that rewrites asset names for other providers.
    * This saves you from having to create custom providers if you require small tweaks to the lookup in order to use an official provider.
* **Deprecations:**
  * `Roadie::Stylesheet#each_inlinable_block` is now deprecated. You can iterate and filter the `blocks` at your own discresion.

### 3.0.5

[full changelog](https://github.com/Mange/roadie/compare/v3.0.4...v3.0.5)

* Bug fixes:
  * Don't try to inline external stylesheets. (#106)
  * Don't generate absolute URLs for anchor links. (Mange/roadie-rails#40)

### 3.0.4

[full changelog](https://github.com/Mange/roadie/compare/v3.0.3...v3.0.4)

* Bug fixes:
  * Schemeless URLs was accepted as-is, which isn't supported in a lot of email clients. (#104)

### 3.0.3

[full changelog](https://github.com/Mange/roadie/compare/v3.0.2...v3.0.3)

* Bug fixes:
  * CSS was mutated when parsed, breaking caches and memoized sources - [Brendan Mulholland (bmulholland)](https://github.com/bmulholland) (Mange/roadie-rails#32)

### 3.0.2

[full changelog](https://github.com/Mange/roadie/compare/v3.0.1...v3.0.2)

* Bug fixes:
  * Some `data:` URLs could cause exceptions. (#97)
  * Correctly parse properties with semicolons in their values - [Aidan Feldman (afeld)](https://github.com/afeld) (#100)

### 3.0.1

[full changelog](https://github.com/Mange/roadie/compare/v3.0.0...v3.0.1)

* Enhancements:
  * `CssNotFound` can take a provider which will be shown in error messages.
* Bug fixes:
  * URL rewriter no longer raises on absolute URLs that cannot be parsed by `URI`. Absolute URLs are completely ignored.
  * URL rewriter supports urls without a scheme (like `//assets.myapp.com/foo`).
  * URL rewriter no longer crashes on absolute URLs without a path (like `myapp://`).

### 3.0.0

[full changelog](https://github.com/Mange/roadie/compare/v3.0.0.pre1...v3.0.0)

* Enhancements:
  * `Roadie::ProviderList` responds to `#empty?` and `#last`
  *   `Roadie::FilesystemProvider` ignores query string in filename.

      Older versions of Rails generated `<link>` tags with query strings in their URLs, like such:
       `/stylesheets/email.css?1380694096`
  * Blacklist `:enabled`, `:disabled` and `:checked` pseudo functions - [Tyler Hunt (tylerhunt)](https://github.com/tylerhunt).
  * Add MRI 2.1.2 to Travis build matrix - [Grey Baker (greysteil)](https://github.com/greysteil).
  * Try to detect an upgrade from Roadie 2 and mention how to make it work with the new version.
  * Styles emitted in the `style` attribute should now be ordered as they were in the source CSS.

### 3.0.0.pre1

[full changelog](https://github.com/Mange/roadie/compare/v2.4.2...v3.0.0.pre1)

Complete rewrite of most of the code and a new direction for the gem.

* Breaking changes:
  * Removed Rails support into a separate Gem (`roadie-rails`).
  * Removed Sprockets dependency and AssetPipelineProvider.
  * Changed the entire public API.
  * Changed the API of custom providers.
  * Dropped support for Ruby 1.8.7.
  * Change `data-immutable` to `data-roadie-ignore`.
* New features:
  * Rewriting the URLs of `img[src]`.
  * A way to inject stylesheets without having to adjust template.
  * A before callback to compliment the after callback.
* Enhancements:
  * Better support for stylesheets using CSS fallbacks.
    This means that styles like this is now inlined: `width: 5em; width: 3rem;`, while Roadie would previously remove the first of the two.
    This sadly means that the HTML file will be much larger than before if you're using a non-optimized stylesheet (for example including your application stylesheet to the email). This was a bad idea even before this change, and this might get you to change.
  * Using HTML5 doctype instead of XHTML
  * Full support for JRuby
  * Experimental support for Rubinius

### 2.4.2

[full changelog](https://github.com/Mange/roadie/compare/v2.4.1...v2.4.2)

* Bug fixes:
  * Fix Nokogiri version to allow only 1.5.x on ruby 1.8.7
  * Blacklist :before, :after, :-ms-input-placeholder, :-moz-placeholder selectors – [Brian Bauer (bbauer)][https://github.com/bbauer].
  * Build failed on 1.8.7 due to a change in `css_parser`

### 2.4.1

[full changelog](https://github.com/Mange/roadie/compare/v2.4.0...v2.4.1)

* Bug fixes:
  * Allow Nokogiri 1.5.x again; 1.6.x is unsupported in Ruby 1.8.7.

### 2.4.0

[full changelog](https://github.com/Mange/roadie/compare/v2.3.4...v2.4.0)

* Enhancements:
  * Support Rails 4.0, with the help of:
    * [Ryunosuke SATO (tricknotes)](https://github.com/tricknotes)
    * [Dylan Markow](https://github.com/dmarkow)
  * Keep `!important` when outputting styles to help combat web mail styles being `!important`
  * Support `:nth-child`, `:last-child`, etc.
    * To make this work, Roadie have to catch errors from Nokogiri and ignore them. A warning will be printed when this happens so users can open issues with the project and tests can be expanded.
  * Support for custom inliner (#58) — [Harish Shetty (kandadaboggu)](https://github.com/kandadaboggu) with friends
* Bug fixes:
  * Don't crash when URL options have protocols with "://" in them (#52).
* Other:
  * Be more specific on which versions are required; require newer `css_parser`
  * Officially support MRI 2.0.0
  * Add experimental support for JRuby
  * Remove documentation that talks about passing CSS filenames as symbols; unsupported in Rails 4. (Thanks to [PikachuEXE](https://github.com/PikachuEXE))

### 2.3.4

[full changelog](https://github.com/Mange/roadie/compare/v2.3.3...v2.3.4)

* Enhancements:
  * Add `config.roadie.enabled` that can be set to `false` to disable Roadie completely.
* Bug fixes:
  * Proc objects to the `:css` option is now run in the context of the mailer instance, mirroring similar options from ActionMailer.
  * Fix some tests that would always pass
  * Improve JRuby compatibility
  * Update Gemfile.lock and fix issues with newer gem versions

### 2.3.3

[full changelog](https://github.com/Mange/roadie/compare/v2.3.2...v2.3.3)

* Enhancements:
  * Allow proc objects to the `:css` option
* Bug fixes:
  * Ignore HTML comments and CDATA sections in CSS (support TinyMCE)

### 2.3.2

[full changelog](https://github.com/Mange/roadie/compare/v2.3.1...v2.3.2)

* Bug fixes:
  * Don't fail on selectors which start with @ (#28) — [Roman Shterenzon (romanbsd)](https://github.com/romanbsd)

### 2.3.1

[full changelog](https://github.com/Mange/roadie/compare/v2.3.0...v2.3.1)

* Bug fixes:
  * Does not work with Rails 3.0 unless provider set specifically (#23)

### 2.3.0

[full changelog](https://github.com/Mange/roadie/compare/v2.3.0.pre1...v2.3.0)

* Nothing, really

### 2.3.0.pre1

[full changelog](https://github.com/Mange/roadie/compare/v2.2.0...v2.3.0.pre1)

* Enhancements:
  * Support Rails 3.2.pre1 - [Morton Jonuschat (yabawock)](https://github.com/yabawock)
  * Sped up the Travis builds
  * Official support for Rails 3.0 again
    * Dependencies allow 3.0
    * Travis builds 3.0 among the others

### 2.2.0

[full changelog](https://github.com/Mange/roadie/compare/v2.1.0...v2.2.0)

* Enhancements:
  * Support for the `url_options` method inside mailer instances
    * You can now dynamically alter the URL options on a per-email basis

### 2.1.0

[full changelog](https://github.com/Mange/roadie/compare/v2.1.0.pre2...v2.1.0)

* Full release!

### 2.1.0.pre2

[full changelog](https://github.com/Mange/roadie/compare/v2.1.0.pre1...v2.1.0.pre2)

* Bug: Roadie broke `url_for` inside mailer views

### 2.1.0.pre1

[full changelog](https://github.com/Mange/roadie/compare/v2.0.0...v2.1.0.pre1)

* Enhancements:
  * Support normal filesystem instead of only Asset pipeline
  * Enable users to create their own way of fetching CSS
  * Improve test coverage a bit
  * Use a railtie to hook into Rails
  * Use real Rails for testing integration

### 2.0.0

[full changelog](https://github.com/Mange/roadie/compare/v1.1.3...v2.0.0)

* Enhancements:
  * Support the Asset pipeline - [Arttu Tervo (arttu)](https://github.com/arttu)
* Dependencies:
  * Requires Rails 3.1 to work. You can keep on using the 1.x series in Rails 3.0

### 1.1.3

[full changelog](https://github.com/Mange/roadie/compare/v1.1.2...v1.1.3)

* Do not add another ".css" to filenames if already present - [Aliaxandr (saks)](https://github.com/saks)

### 1.1.2

[full changelog](https://github.com/Mange/roadie/compare/v1.1.1...v1.1.2)

* Support for Rails 3.1.0 and later inside gemspec

### 1.1.1

[full changelog](https://github.com/Mange/roadie/compare/v1.1.0...v1.1.1)

* Support for Rails 3.1.x (up to and including RC4)
  * Rails 3.0.x is still supported
* Added CI via [Travis CI](http://travis-ci.org)

### 1.1.0

[full changelog](https://github.com/Mange/roadie/compare/v1.0.1...v1.1.0)

* Enhancements:
  * Support for inlining `<link>` elements (thanks to [aliix](https://github.com/aliix))

### 1.0.1

[full changelog](https://github.com/Mange/roadie/compare/v1.0.0...v1.0.1)

* Enhancements:
  * Full, official support for Ruby 1.9.2 (in addition to 1.8.7)
* Dependencies:
  * Explicilty depend on nokogiri >= 1.4.4

### 1.0.0

[full changelog](https://github.com/Mange/roadie/compare/legacy...v1.0.0)

Roadie fork!

* Enhancements:
  * Support for Rails 3.0
  * Code cleanup
  * Support `!important`
  * Tests
  * + some other enhancements
* Deprecations:
  * Removed support for Rails 2.x

