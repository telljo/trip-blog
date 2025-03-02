class CreatePostAttachmentCaptions < ActiveRecord::Migration[8.0]
  def change
    create_table :post_attachment_captions do |t|
      t.references :attachment, null: false, foreign_key: { to_table: :active_storage_attachments }
      t.references :post, null: false, foreign_key: true
      t.text :text, null: false

      t.timestamps
    end
  end
end
