Roadie
======

> Making HTML emails comfortable for the Rails rockstars

Roadie tries to make sending HTML emails a little less painful in Rails 3 by inlining stylesheets and rewrite relative URLs for you.

If you want to have this in Rails 2, please see [MailStyle](https://www.github.com/purify/mail_style).

How does it work?
-----------------

Email clients have bad support for stylesheets, and some of them blocks stylesheets from downloading. The easiest way to handle this is to work with all styles inline, but that is error prone and hard to work with as you cannot use classes and/or reuse styling.

This gem helps making this easier by automatically inlining stylesheet rules into the document before sending it. You just give it a list of stylesheets and it will go though all of the selectors assigning the styles to the maching elements. Careful attention has been put into rules being applied in the correct order, so it should behave just like in the browser¹.

Roadie also rewrites all relative URLs in the email to a absolute counterpart, making images you insert and those referenced in your stylesheets work. No more headaches about how to write the stylesheets while still having them work with emails from your acceptance environments.

¹: Of course, rules like `:hover` will not work by definition. Only static styles can be added.

Build Status
------------

[![Build history and status](https://secure.travis-ci.org/Mange/roadie.png)](http://travis-ci.org/#!/Mange/roadie)

Tested with [Travis CI](http://travis-ci.org) using the [all combinations of](http://travis-ci.org/#!/Mange/roadie):

* Ruby:
  * 1.8.7
  * 1.9.2
  * 1.9.3
* Rails
  * 3.0
  * 3.1
  * 3.2

Let me know if you want any other combination supported officially.

### Versioning ###

This project follows [Semtantic Versioning](http://semver.org/) and has been since version 1.0.0.

Features
--------

* Supports Rails' Asset Pipeline and simple filesystem access out of the box
* You can add support for CSS from any place inside your apps
* Writes CSS styles inline
  * Respects `!important` styles
  * Does not overwrite styles already present in the `style` attribute of tags
  * Supports the same CSS selectors as [Nokogiri](http://nokogiri.org/) (use CSS3 selectors in your emails!)
* Makes image urls absolute
  * Hostname and port configurable on a per-environment basis
* Makes link `href`s absolute
* Automatically adds proper html skeleton when missing (you don't have to create a layout for emails)²

²: This might be removed in a future version, though. You really ought to create a good layout and not let Roadie guess how you want to have it structured

### What about Sass / Less? ###

Sass is supported as long as the stylesheets are generated and stored in the asset directories. You are recommended to add a deploy task that generates the stylesheets to make sure that they are present at all times on the machine generating the emails.

Install
-------

Add the gem to Rails' Gemfile

```ruby
gem 'roadie'
```

Configuring
-----------

Roadie listens to the following options (set in `Application.rb` or in your environment's configuration files:

* `config.action_mailer.default_url_options` - Used for making URLs absolute
* `config.assets.enabled` - If the asset pipeline is turned off, Roadie will default to searching for assets in `public/stylesheets`
* `config.roadie.provider` - Set the provider manually, ignoring all other options. Use for advanced cases, or when you have non-default paths or other options.

Usage
-----

Just add a `<link rel="stylesheet" />` or `<style type="text/css"></style>` element inside your email layout and it will be inlined automatically.

You can also specify the `:css` option to mailer to have it inlined automatically without you having to make a layout:

```ruby
class Notifier < ActionMailer::Base
  default :css => :email, :from => 'support@mycompany.com'

  def registration_mail
    mail(:subject => 'Welcome Aboard', :to => 'someone@example.com')
  end

  def newsletter
    mail(:subject => 'Newsletter', :to => 'someone@example.com', :css => [:email, :newsletter])
  end
end
```

This will look for a css file called `email.css` in your assets. The `css` method can take either a string, a symbol or an array of both. The ".css" extension will be added automatically.

### Image URL rewriting ###

If you have `default_url_options[:host]` set in your mailer, then Roadie will do it's best to make the URLs of images and in stylesheets absolute.

In `application.rb`:

```ruby
class Application
  config.action_mailer.default_url_options = {:host => 'example.com'}
end
```

If you want to to be different depending on your environment, just set it in your environment's configuration instead.

### Ignoring stylesheets ###

By default, `style` and `link` elements in the email document's `head` are processed along with the stylesheets and removed from the `head`.

You can set a special `data-immutable="true"` attribute on `style` and `link` tags you do not want to be processed and removed from the document's `head`. This is the place to put things like `:hover` selectors that you want to have for email clients allowing them.

Style and link elements with `media="print"` are always ignored.

### Inlining link tags ###

Any `link` element that is part of your email will be linked in. You can exclude them by setting `data-immutable` as you would on normal `style` elements. Linked stylesheets for print media is also ignored as you would expect.

If the `link` tag uses an absolute URL to the stylesheet, it will not be inlined. Use a relative path instead:

```html
<head>
  <link rel="stylesheet" type="text/css" href="/assets/emails/rock.css">             <!-- Will be inlined -->
  <link rel="stylesheet" type="text/css" href="http://www.metal.org/metal.css">      <!-- Will NOT be inlined -->
  <link rel="stylesheet" type="text/css" href="/assets/jazz.css" media="print">      <!-- Will NOT be inlined -->
  <link rel="stylesheet" type="text/css" href="/ambient.css" data-immutable>         <!-- Will NOT be inlined -->
</head>
```

Writing your own provider
-------------------------

A provider handles searching CSS files for you. Cou can easily create your own provider for your specific app by subclassing `Roadie::AssetProvider`. See the API documentation for information about how to build them.

Example Subclassing the `AssetPipelineProvider`:

```ruby
# application.rb
config.roadie.provider = UserAssetsProvider.new

# lib/user_assets_provider.rb
class UserAssetsProvider < Roadie::AssetPipelineProvider
  def find(name)
    super
  rescue CSSFileNotFound
    user = User.find_by_name(name)
    raise unless user
    user.custom_css
  end
end
```

Bugs / TODO
-----------

* Improve overall performance
* Clean up stylesheet assignment code

Getting segmentation faults or other C-like problems?
-----------------------------------------------------

Roadie uses Nokogiri to parse the HTML of your email, so any C-like problems like segfaults are likely in that end. The best way to fix this is to first upgrade libxml2 on your system and then reinstall Nokogiri.
Instructions on how to do this on most platforms, see [Nokogiri's official install guide](http://nokogiri.org/tutorials/installing_nokogiri.html).

Note that on my Mac OS X boxes, I don't have to do it as complex as they do it in the guide since I didn't install libxslt. YMMW.

Documentation
-------------

* [Online documentation for 2.0.0](http://rubydoc.info/gems/roadie/2.0.0/frames)
* [Online documentation for 1.1.3](http://rubydoc.info/gems/roadie/1.1.3/frames)
* [Online documentation for master](http://rubydoc.info/github/Mange/roadie/master/frames)
* [Changelog](https://github.com/Mange/roadie/blob/master/Changelog.md)

History and contributors
------------------------

Major contributors to Roadie:

* [Arttu Tervo (arttu)](https://github.com/arttu) - Original Asset pipeline support

You can [see all contributors](https://github.com/Mange/roadie/contributors) on GitHub.

This gem was originally developed for Rails 2 use on [Purify](http://purifyapp.com) under the name [MailStyle](https://www.github.com/purify/mail_style). However, the author stopped maintaining it and a fork took place to make it Rails 3 compatible.

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

Copyright (c) 2009-2011

* [Jim Neath](http://jimneath.org)
* Magnus Bergmark <magnus.bergmark@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the ‘Software’), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED ‘AS IS’, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

