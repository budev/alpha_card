# frozen_string_literal: true

# typed: false
require 'rack/test'

if ENV['CI'] || ENV['TRAVIS'] || ENV['COVERALLS'] || ENV['JENKINS_URL']
  require 'coveralls'
  Coveralls.wear!
else
  require 'simplecov'
  SimpleCov.start
end

require 'bundler/setup'
Bundler.setup

require 'alpha_card'

RSpec.configure do |config|
  config.order = 'random'

  config.before(:suite) do
    AlphaCard::Account.use_demo_credentials!
  end
end
