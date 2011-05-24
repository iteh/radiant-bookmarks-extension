class Bookmark < ActiveRecord::Base

  extend Globalize2::LocalizedContent

  translates :title, :description, :content
  localized_content_for *self.translated_attribute_names

  serialize :meta, Hash

  named_scope :by_month, lambda { |d| { :conditions  => { :created_at  => d.beginning_of_month..d.end_of_month } } }
  named_scope :by_week, lambda { |d| { :conditions  => { :created_at  => d.beginning_of_week..d.end_of_week } } }
  named_scope :by_day, lambda { |d| { :conditions  => { :created_at  => d.beginning_of_day..d.end_of_day } } }
  named_scope :by_date_range, lambda { |start_date,end_date| { :conditions  => { :created_at  => start_date..end_date } } }

  def self.sync_from_delicious(username,password,options={})

    # integrate scraping stuff into https://github.com/jaimeiniesta/metainspector

    require 'www/delicious'
    require 'to_lang'
    require 'open-uri'
    require 'nokogiri'

    ToLang.start(Radiant::Config['bookmarks.google_api_key']) if Radiant::Config['bookmarks.google_api_key']

    WWW::Delicious.new(Radiant::Config['bookmarks.delicious_user'], Radiant::Config['bookmarks.delicious_password'] ) do |delicious|

      delicious_default_language = (Radiant::Config['bookmarks.default_language']) ? Radiant::Config['bookmarks.default_language'].to_sym : Radiant::Config['globalize.default_language'].to_sym
      delicious_translate_to_languages = Globalize2Extension.locales.map(&:to_sym) - [delicious_default_language]
      delicious.posts_all(:fromdt => Date.yesterday).each do |bookmark|

        next if Bookmark.find_by_uid(bookmark.uid)

        text_content = nil

        if Radiant::Config['bookmarks.read_it_later_api_key']
          read_it_later = HTTParty.get("https://text.readitlaterlist.com/v2/text",
                                     :query => {
                                         :apikey => Radiant::Config['bookmarks.read_it_later_api_key'],
                                         :url=> bookmark.url.to_s
                                     })
          if read_it_later.code == 200
            text_content = read_it_later.body
          end
        end

        meta = {:tags => bookmark.tags}
        html = open(bookmark.url.to_s).read
        doc = Nokogiri::HTML(html)
        doc.xpath("//meta").each { |element|
          meta[element.attributes["name"].value] = element.attributes["content"].value if element.attributes["name"]
          meta[element.attributes["property"].value] = element.attributes["content"].value if element.attributes["property"]
        }

        rss_feeds = doc.xpath("//link").select{ |link|
          link.attributes["type"] && link.attributes["type"].value =~ /(atom|rss)/
        }.map { |link|
          link.attributes["href"].value =~ /^http.*/ ? link.attributes["href"].value : File.join(url,link.attributes["href"].value)
        }
        meta[:rss_feeds] = rss_feeds

        I18n.locale = delicious_default_language
        current_bookmark = self.create :title => bookmark.title,
                                       :url => bookmark.url.to_s,
                                       :description => bookmark.notes,
                                       :uid => bookmark.uid,
                                       :orig_title => doc.xpath("//title").text,
                                       :orig_description => meta['description'],
                                       :content => text_content,
                                       :meta => meta


        delicious_translate_to_languages.each do |lang|
          I18n.locale = lang
          current_bookmark.title = bookmark.title.translate(lang.to_s, :from => delicious_default_language.to_s)
          current_bookmark.description = bookmark.notes.translate(lang.to_s, :from => delicious_default_language.to_s)
          current_bookmark.save!
        end if Radiant::Config['bookmarks.google_api_key']
      end
    end
  end

end
