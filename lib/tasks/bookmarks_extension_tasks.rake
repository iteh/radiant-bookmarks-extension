namespace :radiant do
  namespace :extensions do
    namespace :bookmarks do
      
      desc "Runs the migration of the Bookmarks extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          BookmarksExtension.migrator.migrate(ENV["VERSION"].to_i)
          Rake::Task['db:schema:dump'].invoke
        else
          BookmarksExtension.migrator.migrate
          Rake::Task['db:schema:dump'].invoke
        end
      end
      
      desc "Copies public assets of the Bookmarks to the instance public/ directory."
      task :update => :environment do
        is_svn_or_dir = proc {|path| path =~ /\.svn/ || File.directory?(path) }
        puts "Copying assets from BookmarksExtension"
        Dir[BookmarksExtension.root + "/public/**/*"].reject(&is_svn_or_dir).each do |file|
          path = file.sub(BookmarksExtension.root, '')
          directory = File.dirname(path)
          mkdir_p RAILS_ROOT + directory, :verbose => false
          cp file, RAILS_ROOT + path, :verbose => false
        end
        unless BookmarksExtension.root.starts_with? RAILS_ROOT # don't need to copy vendored tasks
          puts "Copying rake tasks from BookmarksExtension"
          local_tasks_path = File.join(RAILS_ROOT, %w(lib tasks))
          mkdir_p local_tasks_path, :verbose => false
          Dir[File.join BookmarksExtension.root, %w(lib tasks *.rake)].each do |file|
            cp file, local_tasks_path, :verbose => false
          end
        end
      end  
      
      desc "Syncs all available translations for this ext to the English ext master"
      task :sync => :environment do
        # The main translation root, basically where English is kept
        language_root = BookmarksExtension.root + "/config/locales"
        words = TranslationSupport.get_translation_keys(language_root)
        
        Dir["#{language_root}/*.yml"].each do |filename|
          next if filename.match('_available_tags')
          basename = File.basename(filename, '.yml')
          puts "Syncing #{basename}"
          (comments, other) = TranslationSupport.read_file(filename, basename)
          words.each { |k,v| other[k] ||= words[k] }  # Initializing hash variable as empty if it does not exist
          other.delete_if { |k,v| !words[k] }         # Remove if not defined in en.yml
          TranslationSupport.write_file(filename, basename, comments, other)
        end
      end

      desc "Generates Entries for Bookmarks"
      task :generate_bookmark_summery_entries => :environment do

        site = (Site.find(ENV['SITE_ID'] || 1))

        VhostExtension.HOST = site.hostnames.first.domain

        layout = Layout.find_by_name("newspost",:conditions => {:site_id => site.id})
        bookmark_root = if (ENV['SLUG'])
                          Page.find_by_slug(ENV['SLUG'], :conditions => {  :site_id => 1})
                        else
                          Page.first(:conditions => { :parent_id => nil, :site_id => site.id})
                        end
        last_page = Page.first(:conditions => {"page_fields.name" => "generated_bookmarks_page",:site_id => site.id},:order => "published_at DESC", :joins => :fields)
        last_page_date = last_page ? last_page.published_at : Bookmark.first(:order => "created_at ASC").created_at

        (last_page_date.to_date + 1.day).step(Date.today.to_date,7) do |week|


          bookmarks = Bookmark.by_week week

          if bookmarks.empty?
            puts "KEINE links vom #{week.beginning_of_week} bis #{week.end_of_week}"
            next
          end

          this_weeks_tags =bookmarks.map {|bookmark| bookmark.meta[:tags]}.flatten.map{|tag| tag.gsub(/[^[:alnum:]]/, '')}.uniq
          new_bookmark_page = Page.new_with_defaults
          new_bookmark_page.site = site

          new_bookmark_page.title = "Links der Woche vom #{week.beginning_of_week} bis #{week.end_of_week}"
          puts new_bookmark_page.title
          new_bookmark_page.breadcrumb = new_bookmark_page.title
          new_bookmark_page.slug = new_bookmark_page.title.parameterize
          new_bookmark_page.parent_id = bookmark_root.id
          new_bookmark_page.fields.build(:name => "generated_bookmarks_page",:content => week.to_s)
          new_bookmark_page.status = Status[:published]
          new_bookmark_page.update_status
          new_bookmark_page.published_at = week.end_of_week
          new_bookmark_page.created_at = week.end_of_week
          new_bookmark_page.created_by_id = site.users.first.id
          new_bookmark_page.updated_by_id = site.users.first.id
          new_bookmark_page.layout = layout

          #weird but otherwise we get the same parts again and again in the loop
          new_bookmark_page.parts = []
          extended = new_bookmark_page.parts.build(:name =>"extended" ,:filter_id => "Textile")
          body = new_bookmark_page.parts.build(:name =>"body",:filter_id => "Textile")

          body.content = "Diese Woche Links zu den Themen #{this_weeks_tags.join(", ")}"
          # TODO: add when translated h4. <r:title/> <r:description/>

          extended.content = %Q{<r:bookmarks date="#{week.to_s}">
<r:bookmark>
h3. <r:orig_title/>

"<r:orig_title/>":<r:url/>

<r:orig_description/>
<br/>
</r:bookmark>
</r:bookmarks>}
          begin
          new_bookmark_page.save!
          body.save!
          extended.save!
          new_bookmark_page.update_attributes(:created_by_id => site.users.first.id, :updated_by_id => site.users.first.id)
            MetaTag.send(:with_scope, :find => { :conditions => {:site_id => site.id}}, :create => {:site_id => site.id }) do
              new_bookmark_page.meta_tags = this_weeks_tags.join(";")
            end
          new_bookmark_page.save!
          rescue Exception => e
            puts "not stored tags #{this_weeks_tags.join(";")}, #{e}"
          end

        end
      end

    end
  end
end
