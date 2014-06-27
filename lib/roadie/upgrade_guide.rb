#
# Let the user know that they need to act to get Roadie compatible with their
# Rails apps if they might have upgraded from Roadie 2.
# TODO: Remove this file by the time of version 3.1.
#

if defined?(Rails) && !defined?(ROADIE_I_KNOW_ABOUT_VERSION_3)
  begin
    require 'roadie/rails'
  rescue LoadError
    warn <<-WARNING
Hey there! It looks like you might have tried to upgrade to Roadie 3 from Roadie 2.

Roadie 3 is a completely new version that is no longer interfacing with Rails
out-of-the-box. In order to use it you need to add the gem roadie-rails too.

You should really read the upgrade guide since the API have changed:

  https://github.com/Mange/roadie-rails/blob/master/Upgrading.md#upgrading-from-roadie-2

I hope this new version will work better for you, but if you are not ready to
upgrade right now add a version specifier to your Gemfile:

  gem 'roadie', '~> 2.4' # Support any minor version in the Roadie 2 series.

In case you have a need for Roadie without the default Rails integration you
can remove this warning by setting a constant:

  # config/application.rb
  ROADIE_I_KNOW_ABOUT_VERSION_3 = true # Remove after Roadie 3.1

Thank you for your attention.
WARNING
    raise
  end
end
