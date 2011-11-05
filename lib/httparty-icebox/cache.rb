module HTTParty
  module Icebox
    class Cache
      attr_accessor :store

      def initialize(store, options = {})
        @store = store.new(options)
      end

      def get(key, force = false)
        @store.get(encode(key)) if force || !stale?(key)
      end
      
      def set(key, value)
        @store.set(encode(key), value)
      end
      
      def exists?(key)
        @store.exists?(encode(key))
      end
      
      def stale?(key)
        @store.stale?(encode(key))
      end

      private
      def encode(key)
        Digest::MD5.hexdigest(key)
      end
    end
  end
end
