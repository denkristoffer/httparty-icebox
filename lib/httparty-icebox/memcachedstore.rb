module HTTParty
  module Icebox
    module Store
      class MemcachedStore < AbstractStore
        def initialize(options = {})
          super

          options[:name] ||= MEMCACHE

          self
        end

        def set(key, value)
          Cache.logger.info("Cache: set (#{key})")

          res = options[:name].set(key, value, @timeout)

          true
        end

        def get(key)
          data = options[:name].get(key) rescue nil
          Cache.logger.info("Cache: #{data.nil? ? "miss" : "hit"} (#{key})")

          data
        end

        def exists?(key)
          data = options[:name].get(key) rescue nil
          !data.nil?
        end

        def stale?(key)
          return true unless exists?(key)
        end
      end
    end
  end
end
