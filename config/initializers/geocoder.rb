# frozen_string_literal: true

Geocoder.configure(
  # Geocoding options
  # timeout: 3,                 # geocoding service timeout (secs)
  # lookup: :nominatim,         # name of geocoding service (symbol)
  # ip_lookup: :ipinfo_io,      # name of IP address geocoding service (symbol)
  language: :en, # ISO-639 language code
  use_https: true, # use HTTPS for lookup requests? (if supported)
  # http_proxy: nil,            # HTTP proxy server (user:pass@host:port)
  # https_proxy: nil,           # HTTPS proxy server (user:pass@host:port)
  lookup: :google,
  api_key: ENV["GOOGLE_MAPS_RAILS_API_KEY"], # API key for geocoding service
  cache: ActiveSupport::Cache::FileStore.new("./db/cache"), # cache object (must respond to #[], #[]=, and #del)

  # Exceptions that should not be rescued by default
  # (if you want to implement custom error handling);
  # supports SocketError and Timeout::Error
  # always_raise: [],

  # Calculation options
  units: :km, # :km for kilometers or :mi for miles
  distances: :linear, # :spherical or :linear

  # Cache configuration
  cache_options: {
    expiration: 2.days,
    prefix: "geocoder:"
  }
)