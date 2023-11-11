module Jsonld

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
        log 'Curation::Page json_ld error'
      end
    end
    @json_ld
  end

  def json_ld_from_object(object)
    JSON.parse object.inner_text
  rescue
    {}
  end
end
