module HTTParty
  module Icebox
    module Store
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
    end
  end
end
