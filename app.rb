require 'rubygems'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'aws-sdk'
require 'haml'
require 'sqlite3'
require 'dm-core'
require 'dm-migrations'
require 'logger'
require 'json'

require './db'

# Custom logger
LOG = Logger.new(STDOUT)

# define content types for all routes (tbd. add :json)
# need to add require 'sinatra/respond_with'
# respond_to :html

# Datamapper config
DataMapper::Logger.new($stdout, :debug) if development?
DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/cache-db.sqlite")

# Reload AWS Resources on startup
# reload_aws_resources

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

  # View helpers - currently not used
  def remote_user
    request.env['REMOTE_USER']
  end

  def admin?
    remote_user.start_with? 'admin'
  end

  def owner?(user)
    admin? || remote_user == user
  end

end

# Basic Authentication
#use Rack::Auth::Basic do |user, password|
#  true
#end

# Endpoints
get '/' do
  redirect "/vpcs"
end

get '/vpcs' do
  @vpcs = Vpc.all(:order => [:vid.desc])
  haml :vpcs
end

get '/vpcs/:vid' do
  @vpc = Vpc.first(:vid => params[:vid])
  haml :vpcs_show
end

get '/instances' do
  @instances = Instance.all(:order => [:vpc_id.desc])
  haml :instances
end

get '/instances/:iid' do
  @instance = Instance.first(:iid => params[:iid])
  haml :instances_show
end

get '/reload' do
  reload_aws_resources
  redirect '/'
end
