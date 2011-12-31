#!/usr/bin/env ruby
#
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

require 'logger'
require 'yaml'
require 'fileutils'

module Wildcloud

  def self.logger
    @log ||= Logger.new('/var/build.log')
  end

  def self.start
    handler = Runner
    handler = Builder unless File.exists?('/var/build.done')
    handler.new.start
  rescue Exception => e
    logger.error(e)
    File.open('/var/build.done', 'w') { |file| file.write('FAIL') }
  end

  class Builder

    def initialize
      FileUtils.rm_rf('/home/wildcloud')
      Wildcloud.logger.info('Loading build configuration')
      @build = YAML::load_file('/root/build.yml')

      Wildcloud.logger.info('Cloning git repository')
      Wildcloud.logger.info(`git clone #{@build[:repository]} /home/wildcloud 2>&1`)

      Wildcloud.logger.info('Moving into application directory')
      Dir.chdir('/home/wildcloud')

      Wildcloud.logger.info('Loading Cloudfile')
      @config = YAML::load_file('Cloudfile') if File.exists?('Cloudfile')
    end

    def start
      if @config['packages']
        Wildcloud.logger.info('Installing system packages')
        packages = @config['packages'].respond_to?(:join) ? @config['packages'].join(' ') : @config['packages'].to_s
        Wildcloud.logger.info(`env DEBCONF_TERSE='yes' DEBIAN_PRIORITY='critical' DEBIAN_FRONTEND=noninteractive apt-get --force-yes -qyu install #{packages}`)
      end
      @config['modules'].each do |name, config|
        Wildcloud.logger.info("Building module: #{name}")
        builder = "build_#{name}".to_sym
        send(builder, config) if respond_to?(builder)
      end if @config['modules']
      FileUtils.chown_R('wildcloud', 'wildcloud', '.')
      File.open('/var/build.done', 'w') { |file| file.write('OK') }
      Wildcloud.logger.info('Build finished')
    end

    def build_ruby(config)
      Wildcloud.logger.info(`bundle install --deployment`) if File.exists?('Gemfile')
    end

  end

  class Runner

    def start
      Dir.chdir('/home/wildcloud')
      `foreman start`
    end

  end

end

Wildcloud.start
