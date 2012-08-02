module Forem
  module Formatters
    # Reopen class and add a custom sanitizer which isn't completely
    # useless.
    module HTML
      def self.format(text)
        text.html_safe
      end

      def self.sanitize(text)
        Sanitize.clean(text, Sanitize::Config::BASIC)
      end
    end
  end
end

Forem.formatter = Forem::Formatters::HTML
