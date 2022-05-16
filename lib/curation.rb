require "curation/version"
require "metainspector"
require "open-uri"
require "htmlentities"

module Curation
  class Error < StandardError; end

  class Page
    attr_reader :url

    BLACKLIST = [
      'head', 'script', 'style', 'iframe', 'nav', 'noscript', 'header', 'footer', 'aside',
      '.navigation', '.top-menu-container', '.navbar', '.navbar-header', '.breadcrumb',
      '#breadcrumbs', '[typeof="v:Breadcrumb"]', '.skip-link', '.search', '.search-form',
      '.categories', '.post-categories', '.datas', '.post-datas', '.twitter-media',
      '.instagram-media', '.widget', '.related-post-tags', '.social-list', '.top-scroll',
      '.comments', '.signature', '.publicite', '.footer', '.Footer', '.footer-copyright',
      '[itemprop*="author"]', '[style*="display:none;"]', '[style*="display:none"]',
      '[style*="display: none;"]', '[style*="display: none"]', '[aria-hidden="true"]'
    ]

    def initialize(url, html = nil)
      @url = url.to_s.gsub('http://', 'https://')
      @html = html
    end

    def title
      @title ||= find_title
    end

    def image
      unless @image
        @image = find_image
        @image = @image.to_s.gsub('http://', 'https://')
      end
      @image
    end

    def text
      # require 'byebug'; byebug
      @text ||= find_text
    end

    def date
      @date ||= find_date
    end

    protected

    def find_title
      if json_ld.any?
        json_ld.each do |ld|
          # require 'byebug'; byebug
          ld = ld.first if ld.is_a?(Array)
          return ld['headline'] if ld.has_key? 'headline'
        end
      end
      begin
        [
          metainspector.best_title,
          metainspector.title,
          nokogiri.css('[itemprop="headline"]')&.first&.inner_text,
          nokogiri.css('title')&.first&.inner_text
        ].each do |possibility|
          return possibility unless possibility.to_s.empty?
        end
      rescue
        puts 'Curation::Page find_title error'
      end
      return ''
    end

    def find_image
      if json_ld.any?
        json_ld.each do |ld|
          ld = ld.first if ld.is_a?(Array)
          if ld.has_key? 'image'
            image_data = ld['image']
            return image_data if image_data.is_a? String
            if image_data.is_a? Array
              first = image_data.first
              return first if first.is_a? String
              return first['url'] if first.is_a? Hash
            end
            return image_data['url'] if image_data.is_a? Hash
          end
        end
      end
      begin
        [
          metainspector.images.best,
          nokogiri.css('[property="og:image"]').first&.attributes['content'].value
        ].each do |possibility|
          return possibility unless possibility.to_s.empty?
        end
      rescue
        puts 'Curation::Page find_image error'
      end
      return ''
    end

    def find_text
      text = find_text_with_json_ld || find_text_with_nokogiri
      text.to_s.gsub!('<br><br>', '<br>')
      # require 'byebug'; byebug
      text = clean_encoding text
      text
    end

    def find_text_with_json_ld
      if json_ld.any?
        json_ld.each do |ld|
          next unless ['NewsArticle', 'ReportageNewsArticle'].include? ld['@type']
          return ld['text'] if ld.has_key? 'text'
          return ld['articleBody'] if ld.has_key? 'articleBody'
        end
      end
      nil
    end

    def find_text_with_nokogiri
      h = nokogiri.dup
      BLACKLIST.each do |tag|
        h.css(tag).remove
      end
      nodes = h.css('p')
      nodes.xpath('//style').remove
      text = nodes.to_html
      text
    end

    def find_date
      if json_ld.any?
        json_ld.each do |ld|
          next unless ['NewsArticle', 'ReportageNewsArticle'].include? ld['@type']
          return Date.parse ld['datePublished'] if ld.has_key? 'datePublished'
        end
      end
      return Date.parse metatags['date'] rescue nil
      return Date.parse metatags['pubdate'] rescue nil
      return Date.parse nokogiri.css('meta[property="article:published"]').first['content'] rescue nil
      return Date.parse nokogiri.css('meta[property="article:published_time"]').first['content'] rescue nil
      return Date.parse nokogiri.css('meta[property="og:article:published_time"]').first['content'] rescue nil
      chunks = html.split('DisplayDate')
      if chunks.count > 1
        value = chunks[1]
        value = value.split(',').first
        value = value.gsub('"', '')
        value = value[1..-1] if value[0] == ':'
        return Date.parse value rescue nil
      end
      begin
        value = nokogiri.css('.postDate').first
        value = value.inner_text
        value = value.gsub(' — ', '')
        return Date.parse value
      rescue
      end
      begin
        value = nokogiri.css('.gta_post_date').first
        value = value.inner_text
        return Date.parse value
      rescue
      end
    end

    private

    def json_ld
      unless defined?(@json_ld)
        @json_ld = []
        begin
          options = nokogiri.css('[type="application/ld+json"]')
          options.each do |option|
            @json_ld << json_ld_from_object(option)
          end
          # Some sites have tables in tables
          @json_ld.flatten!
          # require 'byebug'; byebug
        rescue
          puts 'Curation::Page json_ld error'
        end
      end
      @json_ld
    end

    def json_ld_from_object(object)
      JSON.parse object.inner_text
    rescue
      {}
    end

    def file
      @file ||= URI.open url, 'User-Agent' => "Mozilla/5.0"
    rescue
      puts "Curation::Page file error with url #{url}"
    end

    def html
      unless @html
        file.rewind
        @html = file.read
        file.rewind
      end
      @html
    rescue
      puts "Curation::Page html error"
    end

    def nokogiri
      unless @nokogiri
        if file.nil?
          @nokogiri = metainspector.parsed
        else
          file.rewind
          @nokogiri = Nokogiri::HTML file
          file.rewind
        end
      end
      @nokogiri
    rescue
      puts 'Curation::Page nokogiri error'
    end

    def metainspector
      unless @metainspector
        @metainspector = html.nil?  ? MetaInspector.new(url)
                                    : MetaInspector.new(url, document: html)
      end
      @metainspector
    rescue
      puts 'Curation::Page metainspector error'
    end

    def metatags
      @metatags ||= metainspector.meta_tag['name']
    rescue
      puts 'Curation::Page metatags error'
    end

    # r&Atilde;&copy;forme -> réforme
    def clean_encoding(text)
      clean_text = HTMLEntities.new.decode text
      double_encoding = false
      [
        'Ã©', # é
        'Ã¨', # è
        'Ã®', # î
        'Ãª', # ê
      ].each do |string|
        # require 'byebug'; byebug
        double_encoding = true if clean_text.include? string
      end
      if double_encoding
        clean_text.encode('iso-8859-1', undef: :replace)
                  .force_encoding('utf-8')
      else
        text
      end
    end
  end
end
