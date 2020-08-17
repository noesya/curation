require "curation/version"
require "metainspector"
require "open-uri"

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
      @url = url
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
      @text ||= find_text
    end

    def date
      @date ||= find_date
    end

    protected

    def find_title
      if json_ld.any?
        json_ld.each do |ld|
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
      if json_ld.any?
        json_ld.each do |ld|
          next unless ['NewsArticle', 'ReportageNewsArticle'].include? ld['@type']
          return ld['text'] if ld.has_key? 'text'
          return ld['articleBody'] if ld.has_key? 'articleBody'
        end
      end
      h = nokogiri.dup
      BLACKLIST.each do |tag|
        h.css(tag).remove
      end
      nodes = h.css('p')
      nodes.xpath('//style').remove
      text = nodes.to_html
      text.gsub!('<br><br>', '<br>')
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
            # require 'byebug'; byebug
            string = option.inner_text
            hash = JSON.parse(string)
            @json_ld << hash
          end
          # Some sites have tables in tables
          @json_ld.flatten!
        rescue
          puts 'Curation::Page json_ld error'
        end
      end
      @json_ld
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
        file.rewind
        @nokogiri = Nokogiri::HTML file
        file.rewind
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
  end
end
