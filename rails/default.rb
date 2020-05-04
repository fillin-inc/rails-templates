# frozen_string_literal: true

gem 'enumerize'
gem 'mysql2'
gem 'rails-i18n'
gem 'redis-rails'
gem 'sass-rails'
gem 'seed-fu'
gem 'slim-rails'
gem 'unicorn'

gem_group :development, :test do
  gem 'factory_bot_rails'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rubocop-rails'
end

gem_group :development do
  gem 'annotate'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'bullet'
  gem 'capistrano', require: false
  gem 'capistrano-rails', require: false
  gem 'html2slim', require: false
  gem 'rack-lineprof'
  gem 'rack-mini-profiler'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'spring-commands-rubocop'
end

gem_group :test do
  gem 'database_cleaner'
  gem 'capybara'
  gem 'fakeredis'
  gem 'puma' # for capybara
  gem 'rspec-rails'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end

gsub_file 'Gemfile', /^gem\s+['']coffee-rails[''].*$/, ''
gsub_file 'Gemfile', /^\s+gem\s+['']chromedriver-helper[''].*$/, ''

initializer 'generators.rb', <<-CODE
  # frozen_string_literal: true

  Rails.application.config.generators do |g|
    g.assets false
    g.factory_bot false
    g.helper false
    g.jbuilder false
    g.template_engine = :slim
    g.test_framework :rspec,
                     controller_specs: false,
                     view_specs: false,
                     routing_specs: false
  end
CODE

initializer 'bullet.rb', <<-CODE
  # frozen_string_literal: true

  if Rails.env.development?
    Rails.application.config.after_initialize do
      Bullet.enable        = true
      Bullet.bullet_logger = true
      Bullet.console       = true
      Bullet.rails_logger  = true
    end
  end
CODE

initializer 'sass.rb', <<-CODE
  # frozen_string_literal: true

  Rails.application.config.sass.preferred_syntax = :sass
CODE

file '.rubocop.yml', <<-CODE
  require: rubocop-rails

  Rails/UnknownEnv:
    Environments:
      - production
      - development
      - test
      - staging

  Style/AsciiComments:
    Enabled: false

  Style/ClassAndModuleChildren:
    Enabled: false

  Style/Documentation:
    Enabled: false

  Metrics/LineLength:
    Max: 120

  Metrics/MethodLength:
    Max: 20
CODE

after_bundle do
  generate 'annotate:install'
  generate 'rspec:install'
  run 'bundle exec erb2slim app/views app/views -d'
  run 'bundle exec rubocop --auto-gen-config'
end
