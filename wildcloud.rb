#!/usr/bin/env ruby
# Copyright (C) 2011 Marek Jelen
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

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
  end

  class Builder

    def initialize
      FileUtils.rm_rf('/home/wildcloud')
      Wildcloud.logger.info('Loading build configuration')
      @build = YAML::load_file('/root/build.yml')

      Wildcloud.logger.info('Cloning git repository')
      Wildcloud.logger.info(`git clone #{@build[:repository]} /home/wildcloud`)

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
