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
  gem 'capybara'
  gem 'fakeredis'
  gem 'puma' # for capybara
  gem 'rspec-rails'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end

gsub_file 'Gemfile', /^gem\s+['']coffee-rails[''].*$/, ''
gsub_file 'Gemfile', /^\s+gem\s+['']chromedriver-helper[''].*$/, ''

initializer 'generators.rb', <<~CODE
  # frozen_string_literal: true

  Rails.application.config.generators do |g|
    g.assets false
    g.factory_bot dir: 'spec/factories'
    g.helper false
    g.jbuilder false
    g.template_engine = :slim
    g.test_framework :rspec,
                     controller_specs: false,
                     view_specs: false,
                     routing_specs: false
  end
CODE

initializer 'bullet.rb', <<~CODE
  # frozen_string_literal: true

  if Rails.env.development?
    Rails.application.config.after_initialize do
      Bullet.enable        = true
      Bullet.console       = true
      Bullet.rails_logger  = true
      Bullet.bullet_logger = false
    end
  end
CODE

initializer 'sass.rb', <<~CODE
  # frozen_string_literal: true

  Rails.application.config.sass.preferred_syntax = :sass
CODE

file 'config/locales/.keep'
initializer 'locale.rb', <<~CODE
  # frozen_string_literal: true

  Rails.application.config.i18n do |i18n|
    i18n.default_locale = :ja
    i18n.available_locales = [:ja, :en]
    i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.yml').to_s]
  end
CODE

initializer 'rack_lineprof.rb', <<~CODE
  # frozen_string_literal: true

  Rails.application.config.middleware.use Rack::Lineprof if Rails.env.development?
CODE

file '.rubocop.yml', <<~CODE
  require: rubocop-rails

  AllCops:
    Exclude:
      - 'db/**/*'
      - 'vendor/**/*'
      - 'node_modules/**/*'
      - 'tmp/**/*'
      - 'bin/*'
    DisplayCopNames: true

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

  Style/TrailingCommaInHashLiteral:
    EnforcedStyleForMultiline: comma

  Metrics/LineLength:
    Max: 120
    Exclude:
      - 'app/views/**/*'

  Layout/MultilineMethodCallIndentation:
    EnforcedStyle: indented

  Lint/AmbiguousBlockAssociation:
    Exclude:
      - 'spec/**/*'

  Metrics/BlockLength:
    Exclude:
      - 'spec/**/*'

  Metrics/MethodLength:
    Max: 25
CODE

file 'db/seeds.rb', <<~CODE
  SeedFu.seed
CODE
file 'db/fixtures/development/.keep'

file 'app/assets/stylesheets/application.sass', <<~CODE
  @charset 'utf-8'
CODE
run 'rm app/assets/stylesheets/application.css'

file 'config/unicorn.rb', <<~'CODE'
  # frozen_string_literal: true

  rails_root = File.expand_path('../', __dir__)

  ENV['BUNDLE_GEMFILE'] = "#{rails_root}/Gemfile"

  worker_processes 2
  working_directory rails_root

  timeout 60

  listen "#{rails_root}/tmp/sockets/unicorn.sock"
  pid "#{rails_root}/tmp/pids/unicorn.pid"

  stderr_path "#{rails_root}/log/unicorn_error.log"
  stdout_path "#{rails_root}/log/unicorn.log"

  preload_app true

  before_fork do |server, worker|
    defined?(ActiveRecord::Base) && ActiveRecord::Base.connection.disconnect!

    old_pid = "#{server.config[:pid]}.oldbin"
    if old_pid != server.pid
      begin
        sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
        Process.kill(sig, File.read(old_pid).to_i)
      rescue Errno::ENOENT, Errno::ESRCH # rubocop:disable Lint/SuppressedException
      end
    end
  end

  after_fork do |_server, _worker|
    defined?(ActiveRecord::Base) && ActiveRecord::Base.establish_connection
  end
CODE

file 'spec/factories/.keep'
file 'spec/factories_spec.rb', <<~CODE
  # frozen_string_literal: true

  require 'rails_helper'

  describe FactoryBot do
    it { FactoryBot.lint traits: true }
  end
CODE
file 'spec/support/initializers/factory_bot.rb', <<~CODE
  # frozen_string_literal: true

  RSpec.configure do |config|
    config.include FactoryBot::Syntax::Methods
  end
CODE

file 'spec/support/initializers/capybara.rb', <<~CODE
  # frozen_string_literal: true

  # for Docker
  Capybara.register_driver :headless_chrome do |app|
    options = ::Selenium::WebDriver::Chrome::Options.new.tap do |opts|
      opts.args << '--headless'
      opts.args << '--disable-gpu'
      opts.args << '--no-sandbox'
    end
    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  end

  RSpec.configure do |config|
    config.before(:each, type: :system) do
      driven_by :rack_test
    end

    config.before(:each, type: :system, js: true) do
      driven_by :headless_chrome
    end
  end
CODE

after_bundle do
  generate 'annotate:install'
  generate 'rspec:install'
  run 'bundle exec erb2slim app/views app/views -d'
  run 'bundle exec rubocop --auto-gen-config'
end
