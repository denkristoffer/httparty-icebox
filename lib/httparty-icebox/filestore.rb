require 'pathname'
require 'tmpdir'

module HTTParty
  module Icebox
    module Store
      class FileStore < AbstractStore
        def initialize(options = {})
          super

          options[:location] ||= Dir::tmpdir
          @path = Pathname.new(options[:location])

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
