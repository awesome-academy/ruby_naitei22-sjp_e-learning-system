require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)
Dotenv::Rails.load

module RailsTutorial
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0
    config.i18n.default_locale = :vi
    config.i18n.available_locales = [:en, :vi]
    config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.{rb,yml}")]
  end
end
