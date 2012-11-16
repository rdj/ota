#!/usr/bin/env ruby

require 'rubygems'
require 'bundler'
Bundler.require

require 'yaml'

def path_for( file )
  File.join( File.dirname( __FILE__ ), file )
end

File.unlink( *Dir[ path_for('*.plist') ] )

config = YAML.load( File.read( path_for( 'ota.yml' ) ) )
plist_template = Erubis::EscapedEruby.new( File.read( path_for( 'ota.plist.erb' ) ) )
index_template = Erubis::EscapedEruby.new( File.read( path_for( 'ota.html.erb' ) ) )

apps = []

Dir[path_for('*.ipa')].each do |ipa_file|
  ipa_file = File.basename( ipa_file )
  match = /^(.+?)[.]app[.]AdHoc[.](.+?)[.]ipa$/i.match( ipa_file )
  raise "Can't parse #{ipa_file}" unless match

  apps << ( app = { 'name' => match[1], 'version' => match[2] } )
  app.merge! config[app['name']]
end

apps.each do |app|
  File.open( path_for( "#{app['name']}.app.AdHoc.#{app['version']}.plist" ), 'w' ) do |f|
    f.print plist_template.result( :config => config, :app => app )
  end
end

apks = Dir[path_for('*.apk')].map { |f| File.basename( f ) }

File.open( path_for( 'index.html' ), 'w' ) do |f|
  f.print index_template.result( :config => config, :apps => apps, :android_apks => apks )
end
