**Note: This is an experimental branch; don't use it in any application!**

Details on the experiment:

This branch have better, more "real", integration tests by actually invoking real Rails applications rather than to try to fake rails in any way. This should make it easier to make larger changes to how Roadie works.

The plan is to merge in this branch at one point; or perhaps cherry-picking only some of the commits to a more clean version of it.

Roadie
======

> Making HTML emails comfortable for the Ruby rockstars

Roadie tries to make sending HTML emails a little less painful by inlining stylesheets and rewriting relative URLs for you inside your emails.

[![Build history and status](https://secure.travis-ci.org/Mange/roadie.png)](http://travis-ci.org/#!/Mange/roadie)

How does it work?
-----------------

Email clients have bad support for stylesheets, and some of them blocks stylesheets from downloading. The easiest way to handle this is to work with all styles inline, but that is error prone and hard to work with as you cannot use classes and/or reuse styling.

This gem helps making this easier by automatically inlining stylesheet rules into the document before sending it. You just give it a list of stylesheets and it will go though all of the selectors assigning the styles to the maching elements. Careful attention has been put into rules being applied in the correct order, so it should behave just like in the browser¹.

Roadie also rewrites all relative URLs in the email to a absolute counterpart, making images you insert and those referenced in your stylesheets work. No more headaches about how to write the stylesheets while still having them work with emails from your acceptance environments.

¹: Of course, rules like `:hover` will not work by definition. Only static styles can be added.

Features
--------

* Writes CSS styles inline
  * Respects `!important` styles
  * Does not overwrite styles already present in the `style` attribute of tags
  * Supports the same CSS selectors as [Nokogiri](http://nokogiri.org/) (use CSS3 selectors in your emails!)
* Makes image urls absolute
  * Hostname and port configurable on a per-environment basis
* Makes link `href`s and `img` `src`s absolute
* Automatically adds proper html skeleton when missing (you don't have to create a layout for emails)²
* Allows you to inject stylesheets in a number of ways, at runtime

²: This might be removed in a future version, though. You really ought to create a good layout and not let Roadie guess how you want to have it structured.

Install & Usage
---------------

Add this gem to your Gemfile and bundle.

```ruby
gem 'roadie', '~> x.y.0'
```

You may then create a new instance of a Roadie document:

```ruby
document = Roadie::Document.new "<html><body></body></html>"
document.add_css "body { color: green; }"
document.transform
    # => "<html><body style=\"color:green;\"></body></html>"
```

Your document instance can be configured several options:

* `url_options` - Dictates how absolute URLs should be built.
* `asset_providers` - A single (or list of) asset providers that are invoked when external CSS is referenced. See below.
* `before_inlining` - A callback run before inlining starts.
* `after_inlining` - A callback run after inlining is completed.

### Making URLs absolute ###

In order to make URLs absolute you need to first configure the URL options of the document.

```ruby
html = "... <a href="/about-us">Read more!</a> ..."
document = Roadie::Document.new html
document.url_options = {host: "myapp.com", protocol: "https"}
document.transform
  # => "... <a href="https://myapp.com/about-us">Read more!</a> ..."
```

The following URLs will be rewritten for you:
* `a[href]` (HTML)
* `img[src]` (HTML)
* `url()` (CSS)

### Referenced stylesheets ###

By default, `style` and `link` elements in the email document's `head` are processed along with the stylesheets and removed from the `head`.

You can set a special `data-roadie-ignore` attribute on `style` and `link` tags that you want to ignore (the attribute will be removed, however). This is the place to put things like `:hover` selectors that you want to have for email clients allowing them.

Style and link elements with `media="print"` are also ignored.

```html
<head>
  <link rel="stylesheet" type="text/css" href="/assets/emails/rock.css">         <!-- Will be inlined -->
  <link rel="stylesheet" type="text/css" href="http://www.metal.org/metal.css">  <!-- Will NOT be inlined; absolute URL -->
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
body { color: blue; }

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
                   # <html>
                   #   <head>
                   #   </head>
                   #   <body style="color: green;">
                   #   </body>
                   # </html>
```

If a referenced stylesheet cannot be found, the `#transform` method will raise an `Roadie::CSSNotFound` error. If you instead want to ignore missing stylesheets, you can use the `NullProvider`.

### Configuring providers ###

You can write your own providers if you need very specific behavior for your app, or you can use the built-in providers.

Included providers:
* `FilesystemProvider` - Looks for files on the filesystem, relative to the given directory unless otherwise specified.
* `ProviderList` – Wraps a list of other providers and searches them in order. The `asset_providers` setting is an instance of this. It behaves a lot like an array, so you can push, pop, shift and unshift to it.
* `NullProvider` - Does not actually provide anything, it always finds empty stylesheets. Use this in tests or if you want to ignore stylesheets that cannot be found by your other providers.

If you want to search several locations on the filesystem, just declare that:

```ruby
document.asset_providers = [
  Roadie::FilesystemProvider.new(App.root.join("resources", "stylesheets")),
  Roadie::FilesystemProvider.new(App.root.join("system", "uploads", "stylesheets")),
]
```

If you want to ignore stylesheets that cannot be found instead of crashing, push the `NullProvider` to the end:

```ruby
document.asset_providers.push Roadie::NullProvider.new
```

### Writing your own provider ###

Writing your own provider is also easy. You just need to provide:
 * `#find_stylesheet(name)`, returning either strings or nil.
 * `#find_stylesheet!(name)`, returning either strings or raising Roadie::CSSNotFound.

```ruby
class UserAssetsProvider
  def initialize(user_collection)
    @user_collection = user_collection
  end

  def find_stylesheet(name)
    if name =~ %r{^/users/(\d+)\.css$}
      @user_collection.find_user($1).stylesheet
    end
  end

  def find_stylesheet!(name)
    find_stylesheet(name) or raise Roadie::CSSNotFound.new(name)
  end

  # Instead of implementing #find_stylesheet!, you could also:
  # include Roadie::AssetProvider
end

# Try to look for a user stylesheet first, then fall back to normal filesystem lookup.
document.asset_providers = [
  UserAssetsProvider.new(app),
  Roadie::FilesystemProvider.new('./stylesheets'),
]
```

### Callbacks ###

Callbacks allow you to do custom work on documents before they are inlined. The Nokogiri document tree is passed to the callable:

```ruby
class TrackNewsletterLinks
  def call(document)
    document.css("a").each { |link| fix_link(link) }
  end

  def fix_link(link)
    divider = (link['href'] =~ /?/ ? '&' : '?')
    link['href'] = link['href'] + divider + 'source=newsletter'
  end
end

document.before_inlining = { |document| logger.debug "Inlining document with title #{document.at_css('head > title').try(:text)}" }
document.after_inlining = TrackNewsletterLinks.new
```

Build Status
------------

Tested with [Travis CI](http://travis-ci.org) using [almost all combinations of](http://travis-ci.org/#!/Mange/roadie):

* Ruby:
  * MRI 1.9.3
  * MRI 2.0.0
* Rails
  * 3.0
  * 3.1
  * 3.2
  * 4.0

Let me know if you want any other combination supported officially.

### Versioning ###

This project follows [Semantic Versioning](http://semver.org/) and has been since version 1.0.0.

Bugs / TODO
-----------

* Improve overall performance
* Clean up stylesheet assignment code

FAQ
---

### I'm getting segmentation faults (or other C-like problems)! What should I do? ###

Roadie uses Nokogiri to parse the HTML of your email, so any C-like problems like segfaults are likely in that end. The best way to fix this is to first upgrade libxml2 on your system and then reinstall Nokogiri.
Instructions on how to do this on most platforms, see [Nokogiri's official install guide](http://nokogiri.org/tutorials/installing_nokogiri.html).

### My `:hover` selectors don't work. How can I fix them? ###

Put any styles using `:hover` in a separate stylesheet and make sure it is ignored. (See "Ignoring stylesheets" above)

### My `@media` queries don't work. How can I fix them? ###

Put any styles using them in a separate stylesheet and make sure it is ignored. (See "Ignoring stylesheets" above)

### My vendor-specific styles don't work. How can I fix them? ###

Put any styles using them in a separate stylesheet and make sure it is ignored. (See "Ignoring stylesheets" above)

Documentation
-------------

* [Online documentation for gem](http://rubydoc.info/gems/roadie/frames)
* [Online documentation for master](http://rubydoc.info/github/Mange/roadie/master/frames)
* [Changelog](https://github.com/Mange/roadie/blob/master/Changelog.md)

Running specs
-------------

Start by setting up your machine, then you can run the specs like normal:

```bash
./setup.sh install
rake spec
```

History and contributors
------------------------

Major contributors to Roadie:

* [Arttu Tervo (arttu)](https://github.com/arttu) - Original Asset pipeline support
* [Ryunosuke SATO (tricknotes)](https://github.com/tricknotes) - Initial Rails 4 support

You can [see all contributors](https://github.com/Mange/roadie/contributors) on GitHub.

This gem was originally developed for Rails 2 use on [Purify](http://purifyapp.com) under the name [MailStyle](https://www.github.com/purify/mail_style). However, the author stopped maintaining it and a fork took place to make it Rails 3+ compatible.

The following people have contributed to the orignal gem:

* [Jim Neath](http://jimneath.org) (Original author)
* [Lars Klevans](http://tastybyte.blogspot.com/)
* [Jonas Grimfelt](http://github.com/grimen)
* [Ben Johnson](http://www.binarylogic.com)
* [Istvan Hoka](http://istvanhoka.com/)
* [Voraz](http://blog.voraz.com.br)

License
-------

(The MIT License)

Copyright (c) 2009-2013

* [Jim Neath](http://jimneath.org)
* Magnus Bergmark <magnus.bergmark@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the ‘Software’), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED ‘AS IS’, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

