### dev

[full changelog](https://github.com/Mange/roadie/compare/v2.3.0.pre1...master)

* Nothing yet

### 2.3.0.pre1

[full changelog](https://github.com/Mange/roadie/compare/v2.2.0...v2.3.0.pre1)

* Enhancements:
  * Support Rails 3.2.pre1  - [Morton Jonuschat (yabawock)](https://github.com/yabawock)
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

* Bug: Roadie broke url_for inside mailer views

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

