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

Tested with [Travis CI](http://travis-ci.org) using the [following combinations](http://travis-ci.org/#!/Mange/roadie):

* Ruby 1.8.7 with Rails 3.0.x
* Ruby 1.9.2 with Rails 3.0.x
* Ruby 1.8.7 with Rails 3.1.x
* Ruby 1.9.2 with Rails 3.1.x

Let me know if you want any other combination supported officially

Features
--------

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

Sass is supported "by accident" as long as the stylesheets are generated and stored in the stylesheets directory. This is the default behavior from Sass. You are recommended to add a deploy task that generates the stylesheets to make sure that they are present at all times.

Install
-------

Add the gem to Rails' Gemfile

```ruby
gem 'roadie'
```

Usage
-----

Simply specify the `:css` option to mailer:

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

This will look for a css file called `email.css` in your `public/stylesheets` folder. The `css` method can take either a string, a symbol or an array of both. You should pass the CSS filename without the ".css" extension.

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
  <link rel="stylesheet" type="text/css" href="/stylesheets/emails/rock.css">        <!-- Will be inlined -->
  <link rel="stylesheet" type="text/css" href="http://www.metal.org/metal.css">      <!-- Will NOT be inlined -->
  <link rel="stylesheet" type="text/css" href="/stylesheets/jazz.css" media="print"> <!-- Will NOT be inlined -->
  <link rel="stylesheet" type="text/css" href="/ambient.css" data-immutable>         <!-- Will NOT be inlined -->
</head>
```

Bugs / TODO
-----------

* Improve overall performance
* Clean up stylesheet assignment code

Documentation
-------------

* [Online documentation for 1.1.1](http://rubydoc.info/gems/roadie/1.1.1/frames)
* [Online documentation for 1.0.1](http://rubydoc.info/gems/roadie/1.0.1/frames)
* [Online documentation for master](http://rubydoc.info/github/Mange/roadie/master/frames)
* [Changelog](https://github.com/Mange/roadie/blob/master/Changelog.md)

History and contributors
------------------------

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

