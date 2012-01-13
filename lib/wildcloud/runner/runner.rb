# Copyright 2011 Marek Jelen
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'singleton'
require 'yaml'
require 'pty'

require 'wildcloud/runner/tools'

module Wildcloud
  module Runner
    class Runner

      include Tools
      include Singleton

      def initialize

        $0 = "Wildcloud::Runner"

        logger.info('Runner', 'Changing to application directory')
        Dir.chdir('/home/wildcloud')

        logger.info('Runner', 'Loading Cloudfile')
        @cloudfile = YAML.load_file('Cloudfile') if File.exists?('Cloudfile')
        @cloudfile ||= {}
        @cloudfile['templates'] ||= @cloudfile['modules']

        if @cloudfile['templates'].kind_of?(Hash)
          @cloudfile['templates'].each do |name, config|
            config ||= {}
            template = File.expand_path("../template/#{name}.rb", __FILE__)
            if File.exists?(template)
              logger.info('Runner', "Running template: #{name}")
              require template
              send("#{name}_run".to_sym, config)
            else
              logger.info('Runner', "Unavailable template: #{name}")
            end
          end
        end

        @processes = {}
        @commands = YAML.load_file('Procfile')
        @commands.each do |name, command|
          start_process(name, command)
        end

      end

      def start_process(name, command)
        prc = @processes[name] = {}

        prc[:name] = name
        prc[:command] = command

        prc[:input], prc[:output] = IO.pipe

        logger.info(name, "Starting #{command}")

        prc[:pid] = fork do

          $0 = "Process: #{name}"

          $stdout.reopen(prc[:output])
          $stderr = $stdout

          prc[:input].close

          stdout, stdin, pid = PTY.spawn(command)

          while line = stdout.readline
            $stdout << line
          end

          Process.wait(pid)

        end

        logger.info(name, "Process started with PID #{prc[:pid]}.")

        prc[:output].close

        logger.info(name, "Starting control thread.")

        prc[:collector] = Thread.new do
          Process.wait(prc[:pid])
          logger.info(name, "Process waiting 10s to restart.")
          sleep(10)
          start_process(name, command)
        end

        logger.info(name, "Starting reading thread.")

        prc[:reader] = Thread.new do
          logger.info(name, "Waiting for data.")
          until prc[:input].eof?
            begin
              logger.info(name, prc[:input].gets.chomp)
            rescue Exception => e
              logger.info(name, "Exception #{e.message}")
            end
          end
          logger.info(name, "Pipe closed.")
        end

      rescue Exception => e
        logger.info(name, "Exception #{e.message}")
      end

    end
  end
end