# HTTParty-Icebox - Caching for HTTParty

## Description

Film Buff provides a Ruby wrapper for IMDb's JSON API, which is the fastest and easiest way to get information from IMDb.

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
    response = HTTParty.get("https://github.com/sachse/httparty-icebox")

Cache responses for 5 minutes on the system in the directory "/tmp":

    require 'httparty-icebox'
    
    include HTTParty::Icebox
    
    cache :store => 'file', :timeout => 300, :location => '/tmp/'
    # Use HTTParty's .get method as usual, the response will now be cached
    response = HTTParty.get("https://github.com/sachse/httparty-icebox")

## Authors

- [Karel Minarik](http://karmi.cz)
- [Kristoffer Sachse](https://github.com/sachse)

## Contribute

Fork the project, implement your changes in it's own branch, and send
a pull request to me. I'll gladly consider any help or ideas.

### Contributors

- Martyn Loughran (https://github.com/mloughran) Major parts of this code are based on the architecture of ApiCache.
- David Heinemeier Hansson (https://github.com/dhh) Other parts are inspired by the ActiveSupport::Cache in Ruby On Rails.
- Amit Chakradeo (https://github.com/amit) For pointing out response objects have to be stored marshalled on FS
- Marlin Forbes () For pointing out the query parameters have to be included in the cache key
