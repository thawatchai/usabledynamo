require 'rubygems'
require 'active_support/all'
require 'aws-sdk'
# require 'aws-sdk-core/dynamodb'
require 'spork'
require 'usabledynamo'
#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.

  # This file is copied to spec/ when you run 'rails generate rspec:install'
  ENV["RAILS_ENV"] ||= 'test'

  # AWS.config(:dynamo_db => { :api_version => '2012-08-10' })
  # AWS.config(:use_ssl => false,
  #            :dynamo_db_endpoint => 'localhost',
  #            :dynamo_db_port => 8000,
  #            :access_key_id => "xxx",
  #            :secret_access_key => "xxx")
  Aws.config[:credentials] = Aws::Credentials.new("xxx", "xxx")
  Aws.config[:region] = ENV["S3_REGION"] || 'us-east-1'
  Aws.config[:endpoint] = "http://localhost:8000"

  I18n.enforce_available_locales = false

  # require File.expand_path("../../config/environment", __FILE__)
  # require 'rspec/rails'
  # require 'rspec/autorun'
  #require 'rspec-prof'

  # Requires supporting ruby files with custom matchers and macros, etc,
  # in spec/support/ and its subdirectories.
  Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}
  Dir["#{File.dirname(__FILE__)}/fixtures/**/*.rb"].each {|f| require f}

  RSpec.configure do |config|
    # == Mock Framework
    #
    # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
    #
    # config.mock_with :mocha
    # config.mock_with :flexmock
    # config.mock_with :rr
    config.mock_with :rspec

    # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
    # config.fixture_path = "fixtures"

    # If you're not using ActiveRecord, or you'd prefer not to run each of your
    # examples within a transaction, remove the following line or assign false
    # instead of true.
    # config.use_transactional_fixtures = false #true

    # config.use_instantiated_fixtures  = false

    # If true, the base class of anonymous controllers will be inferred
    # automatically. This will be the default behavior in future versions of
    # rspec-rails.
    # config.infer_base_class_for_anonymous_controllers = false

#    config.include Warden::Test::Helpers
#    Warden.test_mode!
#    config.after(:each, :type => :acceptance) { Warden.test_reset! }

    # config.before(:suite) do
    #   I18n.default_locale = :en
    #   DatabaseCleaner.strategy = :truncation #:transaction
    #   DatabaseCleaner.clean_with(:truncation)
    #   DatabaseCleaner[:mongoid].strategy = :truncation
    # end

    # config.before(:each) do
    #   Modules::Common.stub(:delete_cache)
    #   DatabaseCleaner.start
    #   if example.metadata[:type] == :feature
    #     Capybara.current_driver = :poltergeist # or equivalent javascript driver you are using
    #     I18n.locale = :en
    #   else
    #     Capybara.use_default_driver # presumed to be :rack_test
    #   end
    # end

    # config.after(:each) do
    #   DatabaseCleaner.clean
    # end
  end
end

Spork.each_run do
  # This code will be run each time you run your specs.

end

