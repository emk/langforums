module Forem
  module Formatters
    # Reopen class and add a custom sanitizer which isn't completely
    # useless.
    class RDiscount
      def self.sanitize(text)
        Sanitize.clean(text, Sanitize::Config::BASIC)
      end
    end
  end
end
