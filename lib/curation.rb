require "curation/version"
require "metainspector"
require "open-uri"

module Curation
  class Error < StandardError; end

  class Page
    attr_reader :url, :title, :text, :image

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
      @title = find_title
    end

    def image
      @image = find_image
      @image = @image.to_s.gsub('http://', 'https://')
      @image
    end

    def text
      if json_ld.any?
        json_ld.each do |ld|
          next unless ld['@type'] == 'NewsArticle'
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

    protected

    def find_title
      if json_ld.any?
        # Some sites have tables in tables
        json_ld.flatten!
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
          return possibility unless possibility.blank?
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
            return possibility unless possibility.blank?
        end
      rescue
        puts 'Curation::Page find_image error'
      end
      return ''
    end

    def json_ld
      unless @json_ld
        @json_ld = []
        begin
          options = nokogiri.css('[type="application/ld+json"]')
          options.each do |option|
            string = option.inner_text
            hash = JSON.parse(string)
            @json_ld << hash
          end
        rescue
          puts 'Curation::Page json_ld error'
        end
      end
      @json_ld
    end

    def html
      @html ||= URI.open url
    rescue
      puts "Impossible to open #{url}"
    end

    def nokogiri
      @nokogiri ||= Nokogiri::HTML html
    rescue
      puts 'Curation::Page nokogiri error'
    end

    def metainspector
      @metainspector ||= MetaInspector.new url, document: html
    rescue
      puts 'Curation::Page metainspector error'
    end
  end
end
