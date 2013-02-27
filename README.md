# HTTParty-Icebox - Caching for HTTParty

## Deprecation notice
HTTParty-Icebox is no longer being maintained.

As I haven't used HTTParty for a long time, and don't like feeling bad about neglecting HTTParty-Icebox, I've decided to deprecate it. Check out [CacheBar](https://github.com/vigetlabs/cachebar) instead.

If you're interested in taking over let me know. I should still have my unfinished rewrite somewhere.


## Description

Cache responses in HTTParty models

## Installation

### RubyGems

You can install the latest Film Buff gem using RubyGems

    gem install httparty-icebox

### GitHub

Alternatively you can check out the latest code directly from Github

    git clone http://github.com/sachse/httparty-icebox.git

## Usage



### Examples

Enable caching with default values:

    require 'httparty-icebox'
    
    include HTTParty::Icebox
    
    cache
    # Use HTTParty's .get method as usual, the response will now be cached
    cached_response = HTTParty.get("https://github.com/sachse/httparty-icebox")

Cache responses for 5 minutes on the system in the directory "/tmp":

    require 'httparty-icebox'
    
    include HTTParty::Icebox
    
    cache :store => 'file', :timeout => 300, :location => '/tmp/'
    # Use HTTParty's .get method as usual, the response will now be cached
    cached_response = HTTParty.get("https://github.com/sachse/httparty-icebox")

## Authors

- [Kristoffer Sachse](https://github.com/sachse) (Current maintainer)

- [Karel Minarik](http://karmi.cz) (Original creator through [a gist](https://gist.github.com/209521/))

## Contribute

Fork the project, implement your changes in it's own branch, and send
a pull request to me. I'll gladly consider any help or ideas.

### Contributors

- [Martyn Loughran](https://github.com/mloughran) - Major parts of this code are based on the architecture of ApiCache.
- [David Heinemeier Hansson](https://github.com/dhh) - Other parts are inspired by the ActiveSupport::Cache in Ruby On Rails.
- [Amit Chakradeo](https://github.com/amit) - For pointing out response objects have to be stored marshalled on FS.
- Marlin Forbes - For pointing out the query parameters have to be included in the cache key.
- [ramieblatt](https://github.com/ramieblatt) - Original Memcached store.
