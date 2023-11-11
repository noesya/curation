require "curation/version"
require "curation/tools/raw"
require "curation/tools/nokogiri"
require "curation/tools/jsonld"
require "curation/tools/metainspector"
require "curation/finders/image"
require "curation/finders/publication_date"
require "curation/finders/text"
require "curation/finders/title"
require "metainspector"
require "open-uri"
require "htmlentities"

module Curation
  class Error < StandardError; end

  class Page
    # Tools
    include Raw
    include Jsonld
    include Metainspector
    include Nokogiri
    # Finders
    include Title
    include Image
    include PublicationDate
    include Text

    attr_reader :url
    attr_accessor :verbose

    def initialize(url, html = nil)
      @url = url.to_s.gsub('http://', 'https://')
      @html = html
      @verbose = false
    end

    protected

    def log(message)
      puts message if verbose
    end
  end
end
