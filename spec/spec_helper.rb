$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require "rubygems"
require "bundler/setup"

# https://www.ruby-lang.org/ja/news/2020/10/02/ruby-2-7-2-released/
# Feature #17000: 2.7.2 turns off deprecation warnings by default
# https://bugs.ruby-lang.org/issues/17000
ruby_version = Gem::Version.create(RUBY_VERSION)
ruby27_version = Gem::Version.create("2.7.2")
if ruby_version >= ruby27_version
  if ENV["WARNING"]
    Warning[:deprecated] = true
  end
end

require "rails"
require "action_view"
require "action_dispatch"
require "action_controller"

require "activerecord-turntable"
require "active_record/turntable/active_record_ext/fixtures"

require "rspec/its"
require "rspec/collection_matchers"
require "rspec/parameterized"
require "rspec/rails"
require "webmock/rspec"
require "timecop"
require "pry-byebug"
require "factory_bot"
# Change use_parent_strategy, factory_bot v5
# https://github.com/thoughtbot/factory_bot/commit/d0208eda9c65cbc476a02d2f7503234195610005
factory_bot_current_version = Gem::Version.create(FactoryBot::VERSION)
factory_bot_v5_version = Gem::Version.create("5.0.0")
if factory_bot_current_version >= factory_bot_v5_version
  FactoryBot.use_parent_strategy = false
end

require "faker"
require "coveralls"
Coveralls.wear!

MIGRATIONS_ROOT = File.expand_path(File.join(File.dirname(__FILE__), "migrations"))

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
database_yaml = File.read(File.join(File.dirname(__FILE__), "config/database.yml"))
database_yaml = ERB.new(database_yaml).result
ActiveRecord::Base.configurations = YAML.load(database_yaml)
ActiveRecord::Base.establish_connection(:test)

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  include TurntableHelper

  config.filter_run focus: true
  config.filter_run_excluding with_katsubushi: true
  config.run_all_when_everything_filtered = true
  config.use_transactional_fixtures = true

  config.before(:suite) do
    reload_turntable!(File.join(File.dirname(__FILE__), "config/turntable.rb"), :test)
  end

  config.include FactoryBot::Syntax::Methods
  config.before(:suite) do
    FactoryBot.find_definitions
  end

  config.before(:each) do
    Dir[File.join(File.dirname(File.dirname(__FILE__)), "spec/models/*.rb")].each { |f| require f }
  end
end
