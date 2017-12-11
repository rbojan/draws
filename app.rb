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

  def tags(resource_json)
    if !JSON.parse(resource_json).key?('tags')
      return []
    else
      JSON.parse(resource_json)['tags'].sort_by { |h| h['key'] }
    end
  end

  def tag_filter
    ENV['DRAWS_TAG_FILTER'] ||= 'Project,Stage'
    ENV['DRAWS_TAG_FILTER'].delete(' ').split(',')
  end

  def aws_region
    ENV['AWS_REGION'] ||= 'eu-central-1'
  end
end

if ENV['DRAWS_ENABLE_BASIC_AUTH'] == 'true'
  use Rack::Auth::Basic do |username, password|
    username == ENV['DRAWS_USERNAME'] && password == ENV['DRAWS_USER_PASSWORD']
  end
end

# Endpoints

# '/' ==> /vpcs'
get '/' do
  @vpcs = Vpc.all(:order => [:name.asc])
  haml :vpcs
end

get '/vpcs/:vid' do
  @vpc = Vpc.first(:vid => params[:vid])
  halt 404 unless @vpc
  @subnets = Subnet.all(:order => 'name', :vpc_id => params[:vid])
  @db_instances = DbInstance.all(:order => 'db_instance_class', :vpc_id => params[:vid])
  haml :vpcs_show
end

get '/instances' do
  @instances = Instance.all(:order => [:name.asc])
  haml :instances
end

get '/instances/:iid' do
  @instance = Instance.first(:iid => params[:iid])
  halt 404 unless @instance
  haml :instances_show
end

get '/reload' do
  reload_aws_resources
  File.write('last_reload', Time.now)
  redirect '/'
end

get '/help' do
  @version = File.open('version', &:gets)
  @last_reload = File.exist?('last_reload') ? File.open('last_reload', &:gets) : 'No Resources loaded'
  haml :help
end
