require 'wildcloud/logger'
require 'wildcloud/logger/middleware/console'
require 'wildcloud/logger/middleware/json'
require 'wildcloud/logger/middleware/logeen'

require 'json'

module Wildcloud
  module Runner
    module Tools

      def logger
        return @logger if @logger
        @logger = Wildcloud::Logger::Logger.new('instancexy')
        @logger.add(Wildcloud::Logger::Middleware::Console)
        @logger.add(Wildcloud::Logger::Middleware::Json)
        @logger.add(Wildcloud::Logger::Middleware::Logeen, :address => '10.0.0.1', :port => 4100)
        @logger
      end

      def run(command)
        logger.info('Tools', "Running '#{command}'")
        stdout = `#{command}`
        logger.info('Tools', stdout)
        stdout
      end

    end
  end
end