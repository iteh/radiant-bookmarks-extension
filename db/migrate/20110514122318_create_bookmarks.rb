class CreateBookmarks < ActiveRecord::Migration
  def self.up
    create_table :bookmarks do |t|
      t.text :meta
      t.string :orig_title
      t.string :orig_description
      t.string :url
      t.string :uid
      t.timestamps
    end
    Bookmark.create_translation_table! :title => :string, :description => :text, :content => :text
  end

  def self.down
    drop_table :bookmarks
    Bookmark.drop_translation_table!
  end
end
