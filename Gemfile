source 'https://rubygems.org'

gem 'rails', '~> 3.2.7'
gem 'rails-i18n'

# User account management.
gem 'devise'
gem 'devise-i18n'

# Forem is our forum software.
gem 'forem', git: "git://github.com/radar/forem.git"
gem 'forem-theme-base', git: "git://github.com/radar/forem-theme-base.git"
gem 'kaminari', '0.13.0'

# Industrial-strenth HTML sanitization.
gem 'sanitize'

# Shiny HTML editor & image storage.
gem 'ckeditor'
gem 'paperclip'

# Check HTTP headers to see what languages the user understands.
gem 'http_accept_language', git: "git://github.com/iain/http_accept_language.git"

group :development, :test do
  gem 'sqlite3'
  gem "rspec-rails", "~> 2.0"
end

group :production do
  gem 'pg'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'debugger'
