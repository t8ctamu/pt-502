require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
abort("Refusing to run specs outside the test environment") unless Rails.env.test?
require "rspec/rails"
Rails.application.eager_load!
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.filter_rails_from_backtrace!
  OmniAuth.config.test_mode = true


  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include FactoryBot::Syntax::Methods
  config.before(:each) do
    AppSetting.current.update!(total_points_required: 0)
  end

  config.before(:suite) do
    %w[Member Admin Manager].each do |description|
      Role.find_or_create_by!(description: description)
    end
  end
end
