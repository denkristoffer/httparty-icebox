require 'logger'
require 'fileutils'
require 'tmpdir'
require 'pathname'
require 'digest/md5'

module HTTParty
  module Icebox
    module ClassMethods
      def cache(options = {})
        options[:store] ||= 'memory'
        options[:timeout] ||= 60
        logger = options[:logger]

        @cache ||= Cache.new(options.delete(:store), options)
      end
    end

    def self.included(receiver)
      receiver.extend ClassMethods

      receiver.class_eval do
        def self.get_without_caching(path, options = {})
          perform_request Net::HTTP::Get, path, options
        end

        def self.get_with_caching(path, options = {})
          key = path.downcase
          key << options[:query].to_s if defined? options[:query]

          if cache.exists?(key) and not cache.stale?(key)
            Cache.logger.debug "CACHE -- GET #{path}#{options[:query]}"

            return cache.get(key)
          else
            Cache.logger.debug "/!\\ NETWORK -- GET #{path}#{options[:query]}"
            response = get_without_caching(path, options)
            cache.set(key, response) if response.code.to_s == "200"

            return response
          end
        end

        def self.get(path, options = {})
          self.get_with_caching(path, options)
        end
      end
    end

    class Cache
      attr_accessor :store

      def initialize(store, options = {})
        self.class.logger = options[:logger]
        @store = self.class.lookup_store(store).new(options)
      end

      def get(key)
        @store.get(encode(key)) unless stale?(key)
      end

      def set(key, value)
        self.class.logger.info("Cache: set (#{key})")
        @store.set(encode(key), value)
      end

      def exists?(key)
        @store.exists?(encode(key))
      end

      def stale?(key)
        @store.stale?(encode(key))
      end

      def self.logger
        @logger || default_logger
      end

      def self.default_logger
        logger = ::Logger.new(STDERR)
      end

      def self.logger=(device)
        @logger = device.kind_of?(::Logger) ? device : ::Logger.new(device)
      end

      private
      def self.lookup_store(name)
        store_name = "#{name.capitalize}Store"

        return Store::const_get(store_name)

        rescue NameError => e
          raise Store::StoreNotFound, "The cache store '#{store_name}' was " <<
            "not found. Did you load any such class?"
      end

      def encode(key)
        Digest::MD5.hexdigest(key)
      end
    end

    module Store
      class StoreNotFound < StandardError; end

      class AbstractStore
        def initialize(options = {})
          @timeout = options[:timeout]
          message = "Cache: Using #{self.class.to_s.split('::').last} " <<
            " in location: #{options[:location]} " if options[:location] << 
            "with timeout #{options[:timeout]} sec"

          Cache.logger.info(message) unless options[:logger].nil?

          self
        end

        %w[ set get exists? stale? ].each do |method_name|
          define_method(method_name) do
            raise NoMethodError, "Please implement method #{method_name} in " <<
              "your store class"
          end
        end
      end

      class MemoryStore < AbstractStore
        def initialize(options = {})
          super

          @store = {}

          self
        end

        def set(key, value)
          Cache.logger.info("Cache: set (#{key})")

          @store[key] = [Time.now, value]

          true
        end

        def get(key)
          data = @store[key][1]
          Cache.logger.info("Cache: #{data.nil? ? "miss" : "hit"} (#{key})")

          data
        end

        def exists?(key)
          !@store[key].nil?
        end

        def stale?(key)
          return true unless exists?(key)

          Time.now - created(key) > @timeout
        end

        private
        def created(key)
          @store[key][0]
        end
      end

      class FileStore < AbstractStore
        def initialize(options = {})
          super

          options[:location] ||= Dir::tmpdir
          @path = Pathname.new(options[:location])

          FileUtils.mkdir_p(@path)

          self
        end

        def set(key, value)
          Cache.logger.info("Cache: set (#{key})")
          File.open(@path.join(key), 'w') { |file| file << Marshal.dump(value) }

          true
        end

        def get(key)
          data = Marshal.load(File.read(@path.join(key)))
          Cache.logger.info("Cache: #{data.nil? ? "miss" : "hit"} (#{key})")

          data
        end

        def exists?(key)
          File.exists?(@path.join(key))
        end

        def stale?(key)
          return true unless exists?(key)

          Time.now - created(key) > @timeout
        end

        private
        def created(key)
          File.mtime(@path.join(key))
        end
      end
    end
  end
end
