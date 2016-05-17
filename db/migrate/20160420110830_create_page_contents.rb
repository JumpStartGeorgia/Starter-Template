class CreatePageContents < ActiveRecord::Migration
  def up
    create_table :page_contents do |t|
      t.string :name

      t.timestamps null: false
    end

    PageContent.create_translation_table! title: :string, content: :text
  end

  def down
    drop_table :page_contents
    PageContent.drop_translation_table!
  end
end
