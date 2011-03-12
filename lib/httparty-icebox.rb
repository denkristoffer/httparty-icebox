require 'httparty'

dir = File.expand_path(File.dirname(__FILE__))
require File.join(dir, 'httparty-icebox', 'icebox')
require File.join(dir, 'httparty-icebox', 'cache')
require File.join(dir, 'httparty-icebox', 'filestore')
require File.join(dir, 'httparty-icebox', 'memorystore')
require File.join(dir, 'httparty-icebox', 'memcachedstore')
