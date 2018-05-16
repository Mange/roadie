Roadie
======

[![Build history and status](https://travis-ci.org/Mange/roadie.svg?branch=master)](http://travis-ci.org/#!/Mange/roadie)
[![Code Climate](https://codeclimate.com/github/Mange/roadie.png)](https://codeclimate.com/github/Mange/roadie)
[![Code coverage status](https://codecov.io/github/Mange/roadie/coverage.svg?branch=master)](https://codecov.io/github/Mange/roadie?branch=master)
[![Gem](https://img.shields.io/gem/v/roadie.svg)](https://rubygems.org/gems/roadie)
[![Passive maintenance](https://img.shields.io/badge/maintenance-Passive-yellow.svg)][passive]


|||
|---|---|
| :warning: | This gem is now in [passive maintenance mode][passive]. [(more)][passive] |

> Making HTML emails comfortable for the Ruby rockstars

Roadie tries to make sending HTML emails a little less painful by inlining stylesheets and rewriting relative URLs for you inside your emails.


How does it work?
-----------------

Email clients have bad support for stylesheets, and some of them blocks stylesheets from downloading. The easiest way to handle this is to work with inline styles (`style="..."`), but that is error prone and hard to work with as you cannot use classes and/or reuse styling over your HTML.

This gem makes this easier by automatically inlining stylesheets into the document. You give Roadie your CSS, or let it find it by itself from the `<link>` and `<style>` tags in the markup, and it will go through all of the selectors assigning the styles to the matching elements. Careful attention has been put into selectors being applied in the correct order, so it should behave just like in the browser.

"Dynamic" selectors (`:hover`, `:visited`, `:focus`, etc.), or selectors not understood by Nokogiri will be inlined into a single `<style>` element for those email clients that support it. This changes specificity a great deal for these rules, so it might not work 100% out of the box. (See more about this below)

Roadie also rewrites all relative URLs in the email to an absolute counterpart,
making images you insert and those referenced in your stylesheets work. No more
headaches about how to write the stylesheets while still having them work with
emails from your acceptance environments. You can disable this on specific
elements using a `data-roadie-ignore` marker.

Features
--------

* Writes CSS styles inline.
  * Respects `!important` styles.
  * Does not overwrite styles already present in the `style` attribute of tags.
  * Supports the same CSS selectors as [Nokogiri](http://nokogiri.org/); use CSS3 selectors in your emails!
  * Keeps `:hover` and friends around in a separate `<style>` element.
* Makes image urls absolute.
  * Hostname and port configurable on a per-environment basis.
  * Can be disabled on individual elements.
* Makes link `href`s and `img` `src`s absolute.
* Automatically adds proper HTML skeleton when missing; you don't have to create a layout for emails.
  * Also supports HTML fragments / partial documents, where layout is not added.
* Allows you to inject stylesheets in a number of ways, at runtime.
* Removes `data-roadie-ignore` markers before finishing the HTML.

Install & Usage
---------------

[Add this gem to your Gemfile as recommended by Rubygems](http://rubygems.org/gems/roadie) and run `bundle install`.

```ruby
gem 'roadie', '~> 3.2'
```

You can then create a new instance of a Roadie document:

```ruby
# Transform full documents with the #transform method.
document = Roadie::Document.new "<html><body></body></html>"
document.add_css "body { color: green; }"
document.transform
    # => "<html><body style=\"color:green;\"></body></html>"

# Transform partial documents with #transform_partial.
document = Roadie::Document.new "<div>Hello world!</div>"
document.add_css "div { color: green; }"
document.transform_partial
    # => "<div style=\"color:green;\">Hello world!</div>"
```

Your document instance can be configured with several options:

* `url_options` - Dictates how absolute URLs should be built.
* `keep_uninlinable_css` - Set to false to skip CSS that cannot be inlined.
* `merge_media_queries` - Set to false to not group media queries. Some users might prefer to not group rules within media queries because
  it will result in rules getting reordered.
  e.g.
  ```
  @media(max-width: 600px) { .col-6 { display: block; } }
  @media(max-width: 400px) { .col-12 { display: inline-block; } }
  @media(max-width: 600px) { .col-12 { display: block; } }
  ```
  will become
  ```
  @media(max-width: 600px) { .col-6 { display: block; } .col-12 { display: block; } }
  @media(max-width: 400px) { .col-12 { display: inline-block; } }
  ```
  which would change the styling on the page
  (before it would've yielded display: block; for .col-12 at max-width: 600px
  and now it yields inline-block;)
* `asset_providers` - A list of asset providers that are invoked when CSS files are referenced. See below.
* `external_asset_providers` - A list of asset providers that are invoked when absolute CSS URLs are referenced. See below.
* `before_transformation` - A callback run before transformation starts.
* `after_transformation` - A callback run after transformation is completed.

### Making URLs absolute ###

In order to make URLs absolute you need to first configure the URL options of the document.

```ruby
html = '... <a href="/about-us">Read more!</a> ...'
document = Roadie::Document.new html
document.url_options = {host: "myapp.com", protocol: "https"}
document.transform
  # => "... <a href=\"https://myapp.com/about-us\">Read more!</a> ..."
```

The following URLs will be rewritten for you:
* `a[href]` (HTML)
* `img[src]` (HTML)
* `url()` (CSS)

You can disable individual elements by adding an `data-roadie-ignore` marker on
them. CSS will still be inlined on those elements, but URLs will not be
rewritten.

```html
<a href="|UNSUBSCRIBE_URL|" data-roadie-ignore>Unsubscribe</a>
```

### Referenced stylesheets ###

By default, `style` and `link` elements in the email document's `head` are processed along with the stylesheets and removed from the `head`.

You can set a special `data-roadie-ignore` attribute on `style` and `link` tags that you want to ignore (the attribute will be removed, however). This is the place to put things like `:hover` selectors that you want to have for email clients allowing them.

Style and link elements with `media="print"` are also ignored.

```html
<head>
  <link rel="stylesheet" type="text/css" href="/assets/emails/rock.css">         <!-- Will be inlined with normal providers -->
  <link rel="stylesheet" type="text/css" href="http://www.metal.org/metal.css">  <!-- Will be inlined with external providers, *IF* specified; otherwise ignored. -->
  <link rel="stylesheet" type="text/css" href="/assets/jazz.css" media="print">  <!-- Will NOT be inlined; print style -->
  <link rel="stylesheet" type="text/css" href="/ambient.css" data-roadie-ignore> <!-- Will NOT be inlined; ignored -->
  <style></style>                    <!-- Will be inlined -->
  <style data-roadie-ignore></style> <!-- Will NOT be inlined; ignored -->
</head>
```

Roadie will use the given asset providers to look for the actual CSS that is referenced. If you don't change the default, it will use the `Roadie::FilesystemProvider` which looks for stylesheets on the filesystem, relative to the current working directory.

Example:

```ruby
# /home/user/foo/stylesheets/primary.css
body { color: green; }

# /home/user/foo/script.rb
html = <<-HTML
<html>
  <head>
  <link rel="stylesheet" type="text/css" href="/stylesheets/primary.css">
  </head>
  <body>
  </body>
</html>
HTML

Dir.pwd # => "/home/user/foo"
document = Roadie::Document.new html
document.transform # =>
                   # <!DOCTYPE html>
                   # <html>
                   #   <head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8"></head>
                   #   <body style="color:green;"></body>
                   # </html>
```

If a referenced stylesheet cannot be found, the `#transform` method will raise an `Roadie::CssNotFound` error. If you instead want to ignore missing stylesheets, you can use the `NullProvider`.

### Configuring providers ###

You can write your own providers if you need very specific behavior for your app, or you can use the built-in providers. Providers come in two groups: normal and external. Normal providers handle paths without host information (`/style/foo.css`) while external providers handle URLs with host information (`//example.com/foo.css`, `localhost:3001/bar.css`, and so on).

The default configuration is to not have any external providers configured, which will cause those referenced stylesheets to be ignored. Adding one or more providers for external assets causes all of them to be searched and inlined, so if you only want this to happen to specific stylesheets you need to add ignore markers to every other styleshheet (see above).

Included providers:
* `FilesystemProvider` – Looks for files on the filesystem, relative to the given directory unless otherwise specified.
* `ProviderList` – Wraps a list of other providers and searches them in order. The `asset_providers` setting is an instance of this. It behaves a lot like an array, so you can push, pop, shift and unshift to it.
* `NullProvider` – Does not actually provide anything, it always finds empty stylesheets. Use this in tests or if you want to ignore stylesheets that cannot be found by your other providers (or if you want to force the other providers to never run).
* `NetHttpProvider` – Downloads stylesheets using `Net::HTTP`. Can be given a whitelist of hosts to download from.
* `CachedProvider` – Wraps another provider (or `ProviderList`) and caches responses inside the provided cache store.
* `PathRewriterProvider` – Rewrites the passed path and then passes it on to another provider (or `ProviderList`).

If you want to search several locations on the filesystem, you can declare that:

```ruby
document.asset_providers = [
  Roadie::FilesystemProvider.new(App.root.join("resources", "stylesheets")),
  Roadie::FilesystemProvider.new(App.root.join("system", "uploads", "stylesheets")),
]
```

#### `NullProvider` ####

If you want to ignore stylesheets that cannot be found instead of crashing, push the `NullProvider` to the end:

```ruby
# Don't crash on missing assets
document.asset_providers << Roadie::NullProvider.new

# Don't download assets in tests
document.external_asset_providers.unshift Roadie::NullProvider.new
```

**Note:** This will cause the referenced stylesheet to be removed from the source code, so email client will never see it either.

#### `NetHttpProvider` ####

The `NetHttpProvider` will download the URLs that is is given using Ruby's standard `Net::HTTP` library.

You can give it a whitelist of hosts that downloads are allowed from:

```ruby
document.external_asset_providers << Roadie::NetHttpProvider.new(
  whitelist: ["myapp.com", "assets.myapp.com", "cdn.cdnnetwork.co.jp"],
)
document.external_asset_providers << Roadie::NetHttpProvider.new # Allows every host
```

#### `CachedProvider` ####

You might want to cache providers from working several times. If you are sending several emails quickly from the same process, this might also save a lot of time on parsing the stylesheets if you use in-memory storage such as a hash.

You can wrap any other kind of providers with it, even a `ProviderList`:

```ruby
document.external_asset_providers = Roadie::CachedProvider.new(document.external_asset_providers, my_cache)
```

If you don't pass a cache backend, it will use a normal `Hash`. The cache store must follow this protocol:

```ruby
my_cache["key"] = some_stylesheet_instance # => #<Roadie::Stylesheet instance>
my_cache["key"]                            # => #<Roadie::Stylesheet instance>
my_cache["missing"]                        # => nil
```

**Warning:** The default `Hash` store will never be cleared, so make sure you don't allow the number of unique asset paths to grow too large in a single run. This is especially important if you run Roadie in a daemon that accepts arbritary documents, and/or if you use hash digests in your filenames. Making a new instance of `CachedProvider` will use a new `Hash` instance.

You can implement your own custom cache store by implementing the `[]` and `[]=` methods.

```ruby
class MyRoadieMemcacheStore
  def initialize(memcache)
    @memcache = memcache
  end

  def [](path)
    css = memcache.read("assets/#{path}/css")
    if css
      name = memcache.read("assets/#{path}/name") || "cached #{path}"
      Roadie::Stylesheet.new(name, css)
    end
  end

  def []=(path, stylesheet)
    memcache.write("assets/#{path}/css", stylesheet.to_s)
    memcache.write("assets/#{path}/name", stylesheet.name)
    stylesheet # You need to return the set Stylesheet
  end
end

document.external_asset_providers = Roadie::CachedProvider.new(
  document.external_asset_providers,
  MyRoadieMemcacheStore.new(MemcacheClient.instance)
)
```

If you are using Rspec, you can test your implementation by using the shared examples for the "roadie cache store" role:

```ruby
require "roadie/rspec"

describe MyRoadieMemcacheStore do
  let(:memcache_client) { MemcacheClient.instance }
  subject { MyRoadieMemcacheStore.new(memcache_client) }

  it_behaves_like "roadie cache store" do
    before { memcache_client.clear }
  end
end
```

#### `PathRewriterProvider` ####

With this provider, you can rewrite the paths that are searched in order to more easily support another provider. Examples could include rewriting absolute URLs into something that can be found on the filesystem, or to access internal hosts instead of external ones.

```ruby
filesystem = Roadie::FilesystemProvider.new("assets")
document.asset_providers << Roadie::PathRewriterProvider.new(filesystem) do |path|
  path.sub('stylesheets', 'css').downcase
end

document.external_asset_providers = Roadie::PathRewriterProvider.new(filesystem) do |url|
  if url =~ /myapp\.com/
    URI.parse(url).path.sub(%r{^/assets}, '')
  else
    url
  end
end
```

You can also wrap a list, for example to implement `external_asset_providers` by composing the normal `asset_providers`:

```ruby
document.external_asset_providers =
  Roadie::PathRewriterProvider.new(document.asset_providers) do |url|
    URI.parse(url).path
  end
```

### Writing your own provider ###

Writing your own provider is also easy. You need to provide:
 * `#find_stylesheet(name)`, returning either a `Roadie::Stylesheet` or `nil`.
 * `#find_stylesheet!(name)`, returning either a `Roadie::Stylesheet` or raising `Roadie::CssNotFound`.

```ruby
class UserAssetsProvider
  def initialize(user_collection)
    @user_collection = user_collection
  end

  def find_stylesheet(name)
    if name =~ %r{^/users/(\d+)\.css$}
      user = @user_collection.find_user($1)
      Roadie::Stylesheet.new("user #{user.id} stylesheet", user.stylesheet)
    end
  end

  def find_stylesheet!(name)
    find_stylesheet(name) or raise Roadie::CssNotFound.new(name, "does not match a user stylesheet", self)
  end

  # Instead of implementing #find_stylesheet!, you could also:
  #     include Roadie::AssetProvider
  # That will give you a default implementation without any error message. If
  # you have multiple error cases, it's recommended that you implement
  # #find_stylesheet! without #find_stylesheet and raise with an explanatory
  # error message.
end

# Try to look for a user stylesheet first, then fall back to normal filesystem lookup.
document.asset_providers = [
  UserAssetsProvider.new(app),
  Roadie::FilesystemProvider.new('./stylesheets'),
]
```

You can test for compliance by using the built-in RSpec examples:

```ruby
require 'spec_helper'
require 'roadie/rspec'

describe MyOwnProvider do
  # Will use the default `subject` (MyOwnProvider.new)
  it_behaves_like "roadie asset provider", valid_name: "found.css", invalid_name: "does_not_exist.css"

  # Extra setup just for these tests:
  it_behaves_like "roadie asset provider", valid_name: "found.css", invalid_name: "does_not_exist.css" do
    subject { MyOwnProvider.new(...) }
    before { stub_dependencies }
  end
end
```

### Keeping CSS that is impossible to inline

Some CSS is impossible to inline properly. `:hover` and `::after` comes to
mind. Roadie tries its best to keep these around by injecting them inside a new
`<style>` element in the `<head>` (or at the beginning of the partial if
transforming a partial document).

The problem here is that Roadie cannot possible adjust the specificity for you,
so they will not apply the same way as they did before the styles were inlined.

Another caveat is that a lot of email clients does not support this (which is
the entire point of inlining in the first place), so don't put anything
important in here. Always handle the case of these selectors not being part of
the email.

#### Specificity problems ####

Inlined styles will have much higher specificity than styles in a `<style>`. Here's an example:

```html
<style>p:hover { color: blue; }</style>
<p style="color: green;">Hello world</p>
```

When hovering over this `<p>`, the color will not change as the `color: green` rule takes precedence. You can get it to work by adding `!important` to the `:hover` rule.

It would be foolish to try to automatically inject `!important` on every rule automatically, so this is a manual process.

#### Turning it off ####

If you'd rather skip this and have the styles not possible to inline disappear, you can turn off this feature by setting the `keep_uninlinable_css` option to false.

```ruby
document.keep_uninlinable_css = false
```

### Callbacks ###

Callbacks allow you to do custom work on documents before they are transformed. The Nokogiri document tree is passed to the callable along with the `Roadie::Document` instance:

```ruby
class TrackNewsletterLinks
  def call(dom, document)
    dom.css("a").each { |link| fix_link(link) }
  end

  def fix_link(link)
    divider = (link['href'] =~ /?/ ? '&' : '?')
    link['href'] = link['href'] + divider + 'source=newsletter'
  end
end

document.before_transformation = ->(dom, document) {
  logger.debug "Inlining document with title #{dom.at_css('head > title').try(:text)}"
}
document.after_transformation = TrackNewsletterLinks.new
```

### XHTML vs HTML ###

You can configure the underlying HTML/XML engine to output XHTML or HTML (which
is the default). One usecase for this is that `{` tokens usually gets escaped
to `&#123;`, which would be a problem if you then pass the resulting HTML on to
some other templating engine that uses those tokens (like Handlebars or Mustache).

```ruby
document.mode = :xhtml
```

This will also affect the emitted `<!DOCTYPE>` if transforming a full document.
Partial documents does not have a `<!DOCTYPE>`.

Build Status
------------

Tested with [Travis CI](http://travis-ci.org) using:

* MRI 2.1
* MRI 2.2
* MRI 2.3
* MRI 2.4
* JRuby (latest)
* Rubinius (failures on Rubinius will not fail the build due to a long history of instability in `rbx`)

[(Build status)](http://travis-ci.org/#!/Mange/roadie)

Let me know if you want any other VM supported officially.

### Versioning ###

This project follows [Semantic Versioning](http://semver.org/) and has been since version 1.0.0.

FAQ
---

### Why is my markup changed in subtle ways?

Roadie uses Nokogiri to parse and regenerate the HTML of your email, which means that some unintentional changes might show up.

One example would be that Nokogiri might remove your `&nbsp;`s in some cases.

Another example is Nokogiri's lack of HTML5 support, so certain new element might have spaces removed. I recommend you don't use HTML5 in emails anyway because of bad email client support (that includes web mail!).

### I'm getting segmentation faults (or other C-like problems)! What should I do? ###

Roadie uses Nokogiri to parse the HTML of your email, so any C-like problems like segfaults are likely in that end. The best way to fix this is to first upgrade libxml2 on your system and then reinstall Nokogiri.
Instructions on how to do this on most platforms, see [Nokogiri's official install guide](http://nokogiri.org/tutorials/installing_nokogiri.html).

### What happened to my `@keyframes`?

The CSS Parser used in Roadie does not handle keyframes. I don't think any email clients do either, but if you want to keep on trying you can add them manually to a `<style>` element (or a separate referenced stylesheet) and [tell Roadie not to touch them](#referenced-stylesheets).

### How do I get rid of the `<body>` elements that are added?

It sounds like you want to transform a partial document. Maybe you are building
partials or template fragments to later place in other documents. Use
`Document#transform_partial` instead of `Document#transform` in order to treat
the HTML as a partial document.

### Can I skip URL rewriting on a specific element?

If you add the `data-roadie-ignore` attribute on an element, URL rewriting will
not be performed on that element. This could be really useful for you if you
intend to send the email through some other rendering pipeline that replaces
some placeholders/variables.

```html
<a href="/about-us">About us</a>
<a href="|UNSUBSCRIBE_URL|" data-roadie-ignore>Unsubscribe</a>
```

Note that this will not skip CSS inlining on the element; it will still get the
correct styles applied.

### What should I do about "Invalid URL" errors?

If the URL is invalid on purpose, see _Can I skip URL rewriting on a specific
element?_ above. Otherwise, you can try to parse it yourself using Ruby's `URI`
class and see if you can figure it out.

```ruby
require "uri"
URI.parse("https://example.com/best image.jpg") # raises
URI.parse("https://example.com/best%20image.jpg") # Works!
```

Documentation
-------------

* [Online documentation for gem](https://www.omniref.com/ruby/gems/roadie)
* [Online documentation for master](https://www.omniref.com/github/Mange/roadie)
* [Changelog](https://github.com/Mange/roadie/blob/master/Changelog.md)

Running specs
-------------

```bash
bundle install
rake
```

Security
--------

Roadie is set up with the assumption that all CSS and HTML passing through it is under your control. It is not recommended to run arbritary HTML with the default settings.

Care has been given to try to secure all file system accesses, but it is never guaranteed that someone cannot access something they should not be able to access.

In order to secure Roadie against file system access, only use your own asset providers that you yourself can secure against your particular environment.

If you have found any security vulnerability, please email me at `magnus.bergmark+security@gmail.com` to disclose it. [For very sensitive issues, please use my public GPG key.][gpg] You can also encrypt your message with my public key and open an issue if you do not want to email me directly. Thank you.

History and contributors
------------------------

This gem was previously tied to Rails. It is now framework-agnostic and supports any type of HTML documents. If you want to use it with Rails, check out [roadie-rails](https://github.com/Mange/roadie-rails).

Major contributors to Roadie:

* [Arttu Tervo (arttu)](https://github.com/arttu) - Original Asset pipeline support
* [Ryunosuke SATO (tricknotes)](https://github.com/tricknotes) - Initial Rails 4 support
* [Leung Ho Kuen (PikachuEXE)](https://github.com/PikachuEXE) - A lot of bug reporting and triaging.

You can [see all contributors](https://github.com/Mange/roadie/contributors) on GitHub.

License
-------

(The MIT License)

Copyright (c) 2009-2018 Magnus Bergmark, Jim Neath / Purify, and contributors.

* [Magnus Bergmark](https://github.com/Mange) <magnus.bergmark@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the ‘Software’), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED ‘AS IS’, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[gpg]: https://gist.github.com/Mange/baf25e23e653a206ec2d#file-keybase-md
[passive]: https://github.com/Mange/roadie/issues/155
