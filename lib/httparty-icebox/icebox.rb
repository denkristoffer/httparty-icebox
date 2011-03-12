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
      receiver.extend(ClassMethods)

      receiver.class_eval do
        def self.get_without_caching(path, options = {})
          perform_request(Net::HTTP::Get, path, options)
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

    module Store
      class AbstractStore
        def initialize(options = {})
          @timeout = options[:timeout]
          message = "Cache: Using #{self.class.to_s.split('::').last} " <<
            "in location: #{options[:location]} " if options[:location] << 
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
    end
  end
end
