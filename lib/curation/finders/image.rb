module Image

  def image
    @image ||= find_image.to_s.gsub('http://', 'https://')
  end

  protected

  def find_image
    log "Curation::Page find_image #{url}"
    if json_ld.any?
      json_ld.each do |ld|
        ld = ld.first if ld.is_a?(Array)
        if ld.has_key? 'image'
          image_data = ld['image']
          if image_data.is_a? String
            log "Curation::Page find_image json_ld string"
            return image_data 
          end
          if image_data.is_a? Array
            first = image_data.first
            if first.is_a? String
              log "Curation::Page find_image json_ld array"
              return first 
            end
            if first.is_a? Hash
              log "Curation::Page find_image json_ld array url"
              return first['url'] 
            end
          end
          if image_data.is_a? Hash
            log "Curation::Page find_image json_ld url"
            return image_data['url'] 
          end
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

end