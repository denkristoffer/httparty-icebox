require 'logger'
require 'fileutils'
require 'tmpdir'
require 'pathname'
require 'digest/md5'

module HTTParty #:nodoc:
  # == Caching for HTTParty
  # See documentation in HTTParty::Icebox::ClassMethods.cache
  #
  module Icebox

    module ClassMethods

      # Enable caching and set cache options
      # Returns memoized cache object
      #
      # Following options are available, default values are in []:
      #
      # +store+::       Storage mechanism for cached data (memory, filesystem, your own) [memory]
      # +timeout+::     Cache expiration in seconds [60]
      # +logger+::      Path to logfile or logger instance [nil, silent]
      #
      # Any additional options are passed to the Cache constructor
      #
      # Usage:
      #
      #   # Enable caching in HTTParty, in memory, for 1 minute
      #   cache # Use default values
      #
      #   # Enable caching in HTTParty, on filesystem (/tmp), for 10 minutes
      #   cache :store => 'file', :timeout => 600, :location => '/tmp/'
      #
      #   # Use your own cache store (see +AbstractStore+ class below)
      #   cache :store => 'memcached', :timeout => 600, :server => '192.168.1.1:1001'
      #
      def cache(options={})
        options[:store]   ||= 'memory'
        options[:timeout] ||= 60
        logger = options[:logger]
        @cache ||= Cache.new( options.delete(:store), options )
      end

    end

    # When included, extend class with +cache+ method
    # and redefine +get+ method to use cache
    #
    def self.included(receiver) #:nodoc:
      receiver.extend ClassMethods
      receiver.class_eval do

        # Get reponse from network
        #
        # TODO: Why alias :new :old is not working here? Returns NoMethodError
        #
        def self.get_without_caching(path, options={})
          perform_request Net::HTTP::Get, path, options
        end

        # Get response from cache, if available
        #
        def self.get_with_caching(path, options={})
          key = path.downcase # this makes a copy of path
          key << options[:query].to_s if defined? options[:query]
          if cache.exists?(key) and not cache.stale?(key)
            Cache.logger.debug "CACHE -- GET #{path}#{options[:query]}"
            return cache.get(key)
          else
            Cache.logger.debug "/!\\ NETWORK -- GET #{path}#{options[:query]}"

            begin
              response = get_without_caching(path, options)
              timeout = response.headers['cache-control'] && response.headers['cache-control'][/max-age=(\d+)/, 1].to_i
              cache.set(key, response, :timeout => timeout) if response.code.to_s == "200" # this works for string and integer response codes
              return response
            rescue
              if cache.exists?(key)
                Cache.logger.debug "!!! NETWORK FAILED -- RETURNING STALE CACHE"
                return cache.get(key, true)
              else
                raise
              end
            end
          end
        end

        # Redefine original HTTParty +get+ method to use cache
        #
        def self.get(path, options={})
          self.get_with_caching(path, options)
        end

      end
    end

    # === Cache container
    #
    # Pass a store name ('memory', etc) to new
    #
    class Cache
      attr_accessor :store

      def initialize(store, options={})
        self.class.logger = options[:logger]
        @store = self.class.lookup_store(store).new(options)
      end

      def get(key, force=false)
        @store.get encode(key) if !stale?(key) || force
      end

      def set(key, value, options={})
        @store.set encode(key), value, options
      end

      def exists?(key)
        @store.exists? encode(key)
      end

      def stale?(key)
        @store.stale? encode(key)
      end

      def self.logger; @logger || default_logger; end
      def self.default_logger; logger = ::Logger.new(STDERR); end

      # Pass a filename (String), IO object, Logger instance or +nil+ to silence the logger
      def self.logger=(device); @logger = device.kind_of?(::Logger) ? device : ::Logger.new(device); end

      private

      # Return store class based on passed name
      def self.lookup_store(name)
        store_name = "#{name.capitalize}Store"
        return Store::const_get(store_name)
      rescue NameError => e
        raise Store::StoreNotFound, "The cache store '#{store_name}' was not found. Did you load any such class?"
      end

      def encode(key); Digest::MD5.hexdigest(key); end
    end


    # === Cache stores
    #
    module Store

      class StoreNotFound < StandardError; end #:nodoc:

      # ==== Abstract Store
      # Inherit your store from this class
      # *IMPORTANT*: Do not forget to call +super+ in your +initialize+ method!
      #
      class AbstractStore
        def initialize(options={})
          raise ArgumentError, "You need to set the :timeout parameter" unless options[:timeout]
          @timeout = options[:timeout]
          message =  "Cache: Using #{self.class.to_s.split('::').last}"
          message << " in location: #{options[:location]}" if options[:location]
          message << " with timeout #{options[:timeout]} sec"
          Cache.logger.info message unless options[:logger].nil?
          return self
        end
        %w{set get exists? stale?}.each do |method_name|
          define_method(method_name) { raise NoMethodError, "Please implement method #{method_name} in your store class" }
        end
      end

      # ==== Store objects in memory
      # See HTTParty::Icebox::ClassMethods.cache
      class MemoryStore < AbstractStore
        def initialize(options={})
          super; @store = {}; self
        end
        def set(key, value, options={})
          Cache.logger.info("Cache: set (#{key})")
          value_timeout = options[:timeout]
          @store[key] = [Time.now, value_timeout, value]
          true
        end
        def get(key)
          data = @store[key][2]
          Cache.logger.info("Cache: #{data.nil? ? "miss" : "hit"} (#{key})")
          data
        end
        def exists?(key)
          !@store[key].nil?
        end
        def stale?(key)
          return true unless exists?(key)
          Time.now - created(key) > value_timeout(key)
        end
        private
        def created(key)
          @store[key][0]
        end
        def value_timeout(key)
          @store[key][1]
        end
      end

      # ==== Store objects on the filesystem
      # See HTTParty::Icebox::ClassMethods.cache
      #
      # TODO implement a timeout on a per value basis, like the MemoryStore's `value_timeout`
      class FileStore < AbstractStore
        def initialize(options={})
          super
          options[:location] ||= Dir::tmpdir
          @path = Pathname.new( options[:location] )
          FileUtils.mkdir_p( @path )
          self
        end
        def set(key, value, options = {})
          Cache.logger.info("Cache: set (#{key})")
          File.open( @path.join(key), 'w' ) { |file| file << Base64.encode64(Marshal.dump(value))  }
          true
        end
        def get(key)
          data = Marshal.load(Base64.decode64(File.read( @path.join(key))))
          Cache.logger.info("Cache: #{data.nil? ? "miss" : "hit"} (#{key})")
          data
        end
        def exists?(key)
          File.exists?( @path.join(key) )
        end
        def stale?(key)
          return true unless exists?(key)
          Time.now - created(key) > @timeout
        end
        private
        def created(key)
          File.mtime( @path.join(key) )
        end
      end
    end
  end
end
