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
require 'fileutils'
require 'yaml'

require 'wildcloud/runner/tools'

module Wildcloud
  module Runner
    class Builder

      include Singleton
      include Tools

      def initialize
        FileUtils.rm_rf('/home/wildcloud')

        logger.info('Builder', 'Loading build configuration')
        @buildfile = YAML.load_file('/root/build.yml')

        logger.info('Builder', 'Cloning git repository')
        run("git clone #{@buildfile[:repository]} /home/wildcloud 2>&1")

        logger.info('Builder', 'Changing to application directory')
        Dir.chdir('/home/wildcloud')

        logger.info('Builder', 'Loading Cloudfile')
        @cloudfile = YAML.load_file('Cloudfile') if File.exists?('Cloudfile')
        @cloudfile ||= {}
        @cloudfile['templates'] ||= @cloudfile['modules']

        if @cloudfile['packages']
          logger.info('Builder', 'Installing system packages')
          packages = @cloudfile['packages'].kind_of?(Array) ? @cloudfile['packages'].join(' ') : @cloudfile['packages'].to_s
          run("env DEBCONF_TERSE='yes' DEBIAN_PRIORITY='critical' DEBIAN_FRONTEND=noninteractive apt-get --force-yes -qyu install #{packages}")
        end

        if @cloudfile['templates'].kind_of?(Hash)
          @cloudfile['templates'].each do |name, config|
            config ||= {}
            template = File.expand_path("../template/#{name}.rb", __FILE__)
            if File.exists?(template)
              logger.info('Builder', "Building template: #{name}")
              require template
              send("#{name}_build".to_sym, config)
            else
              logger.info('Builder', "Unavailable template: #{name}")
            end
          end
        end

        logger.info('Builder', 'Ensuring file permissions')
        FileUtils.chown_R('wildcloud', 'wildcloud', '.')

        logger.info('Builder', 'Build finished')
        File.open('/var/build.done', 'w') { |file| file.write('OK') }

      end

    end
  end
end