# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = "https://ab9451d6aff85a5a31ed9f21b51e4230@o4508907857379328.ingest.us.sentry.io/4508907857641472"
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

  # Add data like request headers and IP for users,
  # see https://docs.sentry.io/platforms/ruby/data-management/data-collected/ for more info
  config.send_default_pii = true
end
