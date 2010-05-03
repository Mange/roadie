module MailStyle
  module InlineStyles
    module InstanceMethods
      def css_file_with_sass
        p "css_file_with_sass"
        if !Sass::Plugin.checked_for_updates || Sass::Plugin.options[:always_update] || Sass::Plugin.options[:always_check]
          Sass::Plugin.update_stylesheets
        end

        css_file_without_sass
      end

      #alias_method_chain :css_file, :sass
    end
  end
end

