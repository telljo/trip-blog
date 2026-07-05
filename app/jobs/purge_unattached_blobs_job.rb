class PurgeUnattachedBlobsJob < ApplicationJob
  GRACE_PERIOD = 48.hours

  queue_as :default

  def perform
    stale_unattached_blobs.find_each(&:purge_later)
  end

  private

  def stale_unattached_blobs
    ActiveStorage::Blob.unattached.where(created_at: ...GRACE_PERIOD.ago)
  end
end
