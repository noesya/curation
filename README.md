# Curation

When you build content curation tools, you need to extract the content of pages (title, text, image...). This requires different strategies and some fine tuning to work efficiently.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'curation'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install curation

## Usage

```
page = Curation::Page.new url
article = Article.new
article.title = page.title
article.text = page.text
article.image = page.image
article.save
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/curation. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/curation/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Curation project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/curation/blob/master/CODE_OF_CONDUCT.md).
