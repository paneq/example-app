# frozen_string_literal: true

# This is a non-Rails example app!
# This file is auto-generated during the install process.
# If by any chance you've wanted a setup for Rails app, either run the `karafka:install`
# command again or refer to the install templates available in the source codes

ENV['RACK_ENV'] ||= 'development'
ENV['KARAFKA_ENV'] ||= ENV['RACK_ENV']
Bundler.require(:default, ENV['KARAFKA_ENV'])

# Zeitwerk custom loader for loading the app components before the whole
# Karafka framework configuration
APP_LOADER = Zeitwerk::Loader.new
APP_LOADER.enable_reloading

%w[
  lib
  app/consumers
  app/responders
  app/workers
].each(&APP_LOADER.method(:push_dir))

APP_LOADER.setup
APP_LOADER.eager_load

# App class
# @note The whole setup and routing could be placed in a single class definition
#   but we wanted to show you, that in case of bigger applications, you can create
#   a structure similar to rails config/routes.rb, etc.
class App < Karafka::App
  setup do |config|
    # Karafka will auto-discover kafka_hosts based on Zookeeper but we need it set manually
    # to run tests without running kafka and zookeeper
    config.kafka.seed_brokers = [ENV['KAFKA_HOST'] || 'kafka://127.0.0.1:9092']
    config.client_id = 'example'


    config.kafka.ssl_ca_certs_from_system = false
    config.kafka.sasl_over_ssl = false
    config.kafka.sasl_plain_username = "charlie"
    config.kafka.sasl_plain_password = "charlie"
    config.kafka.max_wait_time = 0.1
    config.kafka.fetcher_max_queue_size = 6000

    config.logger = Logger.new(STDOUT)
  end

  monitor.subscribe('app.initialized') do
    WaterDrop.setup { |config| config.deliver = !Karafka.env.test? }
  end
end

Karafka.monitor.subscribe(WaterDrop::Instrumentation::StdoutListener.new)
Karafka.monitor.subscribe(Karafka::Instrumentation::StdoutListener.new)
Karafka.monitor.subscribe(Karafka::Instrumentation::ProctitleListener.new)

App.consumer_groups.draw do
  consumer_group :"charlie-group" do
    topic(:g) { consumer TrivialConsumer }
  end
end

# Please read this page before you decide to use auto-reloading
# https://github.com/karafka/karafka/wiki/Auto-reload-of-code-changes-in-development
if Karafka::App.env.development?
  Karafka.monitor.subscribe(
    Karafka::CodeReloader.new(
      APP_LOADER
    )
  )
end

App.boot!
