require 'rubygems'
require 'sinatra'
# Sinatra common extensions
# https://github.com/sinatra/sinatra/tree/master/sinatra-contrib#classic-style
require 'sinatra/contrib'
require 'sinatra/reloader' if development?
require 'aws-sdk'
require 'haml'
require 'sqlite3'
require 'dm-core'
require 'dm-migrations'
require 'logger'
require 'json'

require './db'

# tbd. enable/disable the POST _method hack
# use Rack::MethodOverride

before do
  # tbd.
end

helpers do
  def class_for_state(state)
    state == "running" ? "success" : "alert"
  end

  def resource_name(name)
    name.nil? ? "no-resource-name-given" : name
  end
end

# Basic Authentication
#use Rack::Auth::Basic do |user, password|
#  true
#end

# Endpoints

# '/' ==> /vpcs'
get '/' do
  @vpcs = Vpc.all(:order => [:vid.desc])
  haml :vpcs
end

get '/vpcs/:vid' do
  @vpc = Vpc.first(:vid => params[:vid])
  halt 404 unless @vpc
  haml :vpcs_show
end

get '/instances' do
  @instances = Instance.all(:order => [:vpc_id.desc])
  haml :instances
end

get '/instances/:iid' do
  @instance = Instance.first(:iid => params[:iid])
  halt 404 unless @instance
  haml :instances_show
end

get '/reload' do
  reload_aws_resources
  redirect '/'
end
