require "test_helper"
require 'byebug'
class TestCuration < Minitest::Test
  def setup
    file = File.open 'test/data.json'
    @data = JSON.load file
    @data.each do |page|
      page['curation'] = Curation::Page.new page['url']
    end
    file.close
  end

  def test_titles_are_extracted
    @data.each do |page|
      assert_equal page['curation'].title, page['title']
    end
  end

  def test_images_are_extracted
    @data.each do |page|
      assert_equal page['curation'].image, page['image']
    end
  end
end
