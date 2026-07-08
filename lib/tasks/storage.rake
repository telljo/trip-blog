namespace :storage do
  desc "Backfill Cache-Control metadata for existing public GCS Active Storage objects"
  task backfill_gcs_cache_control: :environment do
    require "google/cloud/storage"

    configurations = Rails.application.config.active_storage.service_configurations
    google_config = configurations.fetch("google")
    bucket_name = google_config.fetch("bucket")
    cache_control = ENV.fetch("CACHE_CONTROL", google_config.fetch("cache_control"))
    prefix = ENV["PREFIX"]
    dry_run = ENV.fetch("DRY_RUN", "true") != "false"

    storage = Google::Cloud::Storage.new(
      project_id: google_config.fetch("project"),
      credentials: google_config["credentials"].presence
    )

    bucket = storage.bucket(bucket_name)
    raise "GCS bucket #{bucket_name.inspect} was not found" unless bucket

    updated_count = 0
    skipped_count = 0

    bucket.files(prefix: prefix).all do |file|
      if file.cache_control == cache_control
        skipped_count += 1
        next
      end

      updated_count += 1
      puts "#{dry_run ? "Would update" : "Updating"} #{file.name}"

      next if dry_run

      file.update { |metadata| metadata.cache_control = cache_control }
    end

    puts "Bucket: #{bucket_name}"
    puts "Cache-Control: #{cache_control}"
    puts "Prefix: #{prefix.presence || "(all objects)"}"
    puts "Updated: #{updated_count}"
    puts "Already current: #{skipped_count}"
    puts "Dry run: #{dry_run}"
    puts "Run with DRY_RUN=false to apply metadata updates." if dry_run
  end
end
