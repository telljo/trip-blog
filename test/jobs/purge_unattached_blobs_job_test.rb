require "test_helper"

class PurgeUnattachedBlobsJobTest < ActiveJob::TestCase
  setup do
    @storage_keys = []
  end

  teardown do
    @storage_keys.each { |key| ActiveStorage::Blob.service.delete(key) }
  end

  test "purges stale unattached blobs but keeps recent and attached blobs" do
    stale_blob = create_blob("stale.txt", created_at: 3.days.ago)
    recent_blob = create_blob("recent.txt", created_at: 1.hour.ago)
    attached_blob = create_blob("attached.txt", created_at: 3.days.ago)
    posts(:one).attachments.attach(attached_blob)

    perform_enqueued_jobs(only: ActiveStorage::PurgeJob) do
      PurgeUnattachedBlobsJob.perform_now
    end

    assert_not ActiveStorage::Blob.exists?(stale_blob.id)
    assert_not ActiveStorage::Blob.service.exist?(stale_blob.key)
    assert ActiveStorage::Blob.exists?(recent_blob.id)
    assert ActiveStorage::Blob.service.exist?(recent_blob.key)
    assert ActiveStorage::Blob.exists?(attached_blob.id)
    assert ActiveStorage::Blob.service.exist?(attached_blob.key)
  end

  test "is scheduled daily in production" do
    recurring_tasks = YAML.safe_load_file(Rails.root.join("config/recurring.yml"))
    task = recurring_tasks.dig("production", "purge_unattached_blobs")

    assert_equal "PurgeUnattachedBlobsJob", task.fetch("class")
    assert_equal "every day at 3am", task.fetch("schedule")
  end

  private

  def create_blob(filename, created_at:)
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(filename),
      filename: filename,
      content_type: "text/plain",
      identify: false
    ).tap do |blob|
      blob.update_column(:created_at, created_at)
      @storage_keys << blob.key
    end
  end
end
