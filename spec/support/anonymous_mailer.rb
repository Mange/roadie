# Subclass of ActionMailer::Base that does not crash when the class
# is anonymous. Subclassed in the specs whenever a new mailer is
# needed
class AnonymousMailer < ActionMailer::Base
  class << self
    # Pretty much like super, but returns "anonymous" when no
    # name is set
    def mailer_name
      if @mailer_name or name
        super
      else
        "anonymous"
      end
    end

    # Was an alias. (e.g. pointed to the old, non-overridden method)
    def controller_path
      mailer_name
    end
  end
end
