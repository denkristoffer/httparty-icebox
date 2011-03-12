require 'logger'

module HTTParty
  module Icebox
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
          raise NameError, "The cache store '#{store_name}' was " <<
            "not found. Did you load any such class?"
      end

      def encode(key)
        Digest::MD5.hexdigest(key)
      end
    end
  end
end
