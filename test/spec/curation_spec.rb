require "test_helper"
require "byebug"

class TestCuration < Minitest::Test
  def setup
    file = File.open 'test/data.json'
    @data = JSON.load file
    @data.each do |page|
      page['curation'] = Curation::Page.new page['url']
      # page['curation'].verbose = true
    end
    file.close
  end

  def test_titles_are_extracted
    @data.each do |page|
      assert_equal page['title'], page['curation'].title
    end
  end

  def test_images_are_extracted
    @data.each do |page|
      assert_equal page['image'], page['curation'].image
    end
  end

  def test_texts_are_more_or_less_extracted
    @data.each do |page|
      # puts page['url']
      # puts page['curation'].text
      assert page['curation'].text.include? page['text_extract']
    end
  end

  def test_dates_are_extracted
    @data.each do |page|
      if page['date']
        # puts page['url']
        # puts page['curation'].date
        date = Date.parse page['date']
        assert_equal page['curation'].date, date
      end
    end
  end
end
