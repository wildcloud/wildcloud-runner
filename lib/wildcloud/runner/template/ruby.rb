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

module Wildcloud
  module Runner

    module RubyTemplate

      def ruby_use(config)
        return unless config['version']
        version = config['version']

        logger.info('Ruby', "Changing to #{version}")
        change = run("rvm use #{version} 2>&1")

        if change =~ /To install do/
          logger.info('Ruby', "#{version} is not default Ruby, installing.")
          run("rvm install #{version} 2>&1")

          logger.info('Ruby', "Changing to #{version}")
          run("rvm use #{version} 2>&1")

          logger.info('Ruby', "Ensuring bundler #{version}")
          run("gem install bundler foreman 2>&1")
        end
      end

    end

    class Builder

      include RubyTemplate

      def ruby_build(config)
        ruby_use(config)
        if File.exists?('Gemfile')
          logger.info('Ruby', 'Bundling your gems')
          run("bundle install --deployment 2>&1")
        end
      end

    end

    class Runner

      include RubyTemplate

      def ruby_run(config)
        ruby_use(config)
      end

    end

  end
end
