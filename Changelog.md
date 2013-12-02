### dev

[full changelog](https://github.com/Mange/roadie/compare/v2.4.3...master)

* Nothing yet

### 2.4.3

[full changelog](https://github.com/Mange/roadie/compare/v2.4.2...v2.4.3)

* Bug fixes:
  * Blacklist `:enabled`, `:disabled` and `:checked` pseudo functions - [Tyler Hunt (tylerhunt)](https://github.com/tylerhunt).

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

