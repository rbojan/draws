# Datamapper config
# Logger level tbd. for production (:info)
LOG = DataMapper::Logger.new($stdout, :debug) if development?
LOG = DataMapper::Logger.new($stdout, :debug) if production?
DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/cache-db.sqlite")

# Structure for tables (schema)
class Instance
  include DataMapper::Resource
  property :id, Serial
  property :iid, String
  property :name, String
  property :instance_type, String
  property :private_ip_address, String
  property :public_ip_address, String
  property :vpc_id, String
  property :subnet_id, String
  property :state, String
  property :resource_json, Text

  belongs_to :vpc, 'Vpc',
    :parent_key => [ :vid ],   # in the remote model (Vpc)
    :child_key  => [ :vpc_id ] # local to this model (Instance)
    #:required   => true        # the vpc_id must be present
  belongs_to :subnet, 'Subnet', :parent_key => [ :sid ], :child_key  => [ :subnet_id ]
end

class Vpc
  include DataMapper::Resource
  property :id, Serial
  property :vid, String
  property :name, String
  property :cidr_block, String
  property :state, String

  property :resource_json, Text

  has n, :instances, 'Instance',
    :parent_key => [ :vid ], # local to this model (Vpc)
    :child_key  => [ :vpc_id ]  # in the remote model (Instance)

  has n, :db_instances, 'DbInstance',
    :parent_key => [ :vid ], # local to this model (Vpc)
    :child_key  => [ :vpc_id ]  # in the remote model (DbInstance)

  has n, :subnets, 'Subnet', :parent_key => [ :vid ], :child_key => [ :vpc_id ]
end

class Subnet
  include DataMapper::Resource
  property :id, Serial
  property :sid, String
  property :name, String
  property :cidr_block, String
  property :vpc_id, String
  property :availability_zone, String
  property :available_ip_address_count, String

  property :resource_json, Text

  belongs_to :vpc, 'Vpc', :parent_key => [ :vid ], :child_key  => [ :vpc_id ]
  has n, :instances, 'Instance', :parent_key => [ :sid ], :child_key  => [ :subnet_id ]
end

class DbInstance
  include DataMapper::Resource
  property :id, Serial
  property :dbiid, String
  property :name, String
  property :db_instance_class, String
  property :address, String
  property :engine, String
  property :vpc_id, String
  property :availability_zone, String
  property :secondary_availability_zone, String

  property :resource_json, Text

  belongs_to :vpc, 'Vpc', :parent_key => [ :vid ], :child_key  => [ :vpc_id ]
end

# Load DB on startup
DataMapper.finalize.auto_upgrade!


# AWS Helper methods
def aws_resource_name(resource)
  tags_with_key_name = resource.tags.select{|tag| tag.key == "Name"}
  if tags_with_key_name.any?
    tags_with_key_name.first.try(:value)
  else
    "no-resource-tag-name"
  end
end

# AWS ETL job :)
def reload_aws_resources

  LOG.info "Flushing DB ..."
  DataMapper.finalize.auto_migrate!
  LOG.info "Flushing DB done"

  LOG.info "Loading AWS Resources ..."
  ENV['AWS_REGION'] ||= 'eu-central-1'
  LOG.info "AWS Region: #{ENV['AWS_REGION']}"
  ec2 = Aws::EC2::Client.new(region: ENV['AWS_REGION'])
  rds = Aws::RDS::Client.new(region: ENV['AWS_REGION'])

  reservations = ec2.describe_instances.reservations
  reservations.each do |reservation|
    reservation.instances.each do |instance|
      resource_json = instance.to_h.to_json
      Instance.create iid: instance.instance_id,
                      name: aws_resource_name(instance),
                      instance_type: instance.instance_type,
                      private_ip_address: instance.private_ip_address,
                      public_ip_address: instance.public_ip_address,
                      vpc_id: instance.vpc_id,
                      subnet_id: instance.subnet_id,
                      state: instance.state.name,
                      resource_json: resource_json
    end
  end
  LOG.info "#{reservations.count} instance(s) were loaded"

  vpcs = ec2.describe_vpcs.vpcs
  vpcs.each do |vpc|
    resource_json = vpc.to_h.to_json
    Vpc.create vid: vpc.vpc_id,
               name: aws_resource_name(vpc),
               cidr_block: vpc.cidr_block,
               state: vpc.state,
               resource_json: resource_json
  end
  LOG.info "#{vpcs.count} VPC(s) were loaded"

  subnets = ec2.describe_subnets.subnets
  subnets.each do |subnet|
    resource_json = subnet.to_h.to_json
    Subnet.create sid: subnet.subnet_id,
                  name: aws_resource_name(subnet),
                  cidr_block: subnet.cidr_block,
                  vpc_id: subnet.vpc_id,
                  availability_zone: subnet.availability_zone,
                  available_ip_address_count: subnet.available_ip_address_count,
                  resource_json: resource_json
  end
  LOG.info "#{subnets.count} Subnet(s) were loaded"

  db_instances = rds.describe_db_instances.db_instances
  db_instances.each do |db_instance|
    resource_json = db_instance.to_h.to_json
    DbInstance.create dbiid: db_instance.dbi_resource_id,
                      name: db_instance.db_instance_identifier,
                      vpc_id: db_instance.db_subnet_group.vpc_id,
                      engine: db_instance.engine,
                      db_instance_class: db_instance.db_instance_class,
                      address:  db_instance.endpoint.address,
                      availability_zone: db_instance.availability_zone,
                      secondary_availability_zone: db_instance.secondary_availability_zone,
                      resource_json: resource_json
  end
  LOG.info "#{db_instances.count} RDS DB Instance(s) were loaded"

  LOG.info "Loading AWS Resources done"
end

# aws.rb Dump
#
#
# AWS Resources
#
# Aws> ec2.describe_subnets.subnets[0].to_h
# [Aws::EC2::Client 200 0.548193 0 retries] describe_subnets()
# => {:subnet_id=>"subnet-2e891746",
#  :state=>"available",
#  :vpc_id=>"vpc-0261bf6a",
#  :cidr_block=>"172.31.0.0/20",
#  :ipv_6_cidr_block_association_set=>[],
#  :assign_ipv_6_address_on_creation=>false,
#  :available_ip_address_count=>4091,
#  :availability_zone=>"eu-central-1a",
#  :default_for_az=>true,
#  :map_public_ip_on_launch=>true}
#
# Aws> ec2.describe_subnets.subnets[1].to_h
# [Aws::EC2::Client 200 0.431825 0 retries] describe_subnets()
# => {:subnet_id=>"subnet-ec147d84",
#  :state=>"available",
#  :vpc_id=>"vpc-08b91060",
#  :cidr_block=>"10.1.1.0/24",
#  :ipv_6_cidr_block_association_set=>[],
#  :assign_ipv_6_address_on_creation=>false,
#  :available_ip_address_count=>250,
#  :availability_zone=>"eu-central-1a",
#  :default_for_az=>false,
#  :map_public_ip_on_launch=>false,
#  :tags=>[{:key=>"Name", :value=>"coreit-public"}]}
# Aws>
#
#
# Aws> ec2.describe_vpcs.vpcs[0]
# [Aws::EC2::Client 200 0.447983 0 retries] describe_vpcs()
# => #<struct Aws::EC2::Types::Vpc
#  vpc_id="vpc-0261bf6a",
#  state="available",
#  cidr_block="172.31.0.0/16",
#  dhcp_options_id="dopt-039c706b",
#  tags=[#<struct Aws::EC2::Types::Tag key="Name", value="Default">],
#  instance_tenancy="default",
#  is_default=true,
#  ipv_6_cidr_block_association_set=[]>
#
# Aws> ec2.describe_vpcs.vpcs[1]
# [Aws::EC2::Client 200 0.411531 0 retries] describe_vpcs()
# => #<struct Aws::EC2::Types::Vpc
#  vpc_id="vpc-08b91060",
#  state="available",
#  cidr_block="10.1.0.0/16",
#  dhcp_options_id="dopt-039c706b",
#  tags=[#<struct Aws::EC2::Types::Tag key="Name", value="coreit">],
#  instance_tenancy="default",
#  is_default=false,
#  ipv_6_cidr_block_association_set=[]>#
#
#
# Aws> rds.describe_db_instances[:db_instances][1].to_h
# [Aws::RDS::Client 200 0.498392 0 retries] describe_db_instances()
# => {:db_instance_identifier=>"stage-rancher-server",
#  :db_instance_class=>"db.t2.micro",
#  :engine=>"mysql",
#  :db_instance_status=>"available",
#  :master_username=>"rancher",
#  :db_name=>"rancher",
#  :endpoint=>{:address=>"stage-rancher-server.clrzznqs5nb4.eu-central-1.rds.amazonaws.com", :port=>3306, :hosted_zone_id=>"Z1RLNUO7B9Q6NB"},
#  :allocated_storage=>5,
#  :instance_create_time=>2017-11-29 16:30:13 UTC,
#  :preferred_backup_window=>"01:37-02:07",
#  :backup_retention_period=>7,
#  :db_security_groups=>[],
#  :vpc_security_groups=>[{:vpc_security_group_id=>"sg-0d660067", :status=>"active"}],
#  :db_parameter_groups=>[{:db_parameter_group_name=>"default.mysql5.6", :parameter_apply_status=>"in-sync"}],
#  :availability_zone=>"eu-central-1c",
#  :db_subnet_group=>
#   {:db_subnet_group_name=>"stage",
#    :db_subnet_group_description=>"Data subnet group for stage",
#    :vpc_id=>"vpc-hha748d8",
#    :subnet_group_status=>"Complete",
#    :subnets=>
#     [{:subnet_identifier=>"subnet-300aba72", :subnet_availability_zone=>{:name=>"eu-central-1a"}, :subnet_status=>"Active"},
#      {:subnet_identifier=>"subnet-3000611e3", :subnet_availability_zone=>{:name=>"eu-central-1b"}, :subnet_status=>"Active"},
#      {:subnet_identifier=>"subnet-3005d309", :subnet_availability_zone=>{:name=>"eu-central-1c"}, :subnet_status=>"Active"}]},
#  :preferred_maintenance_window=>"thu:03:05-thu:03:35",
#  :pending_modified_values=>{},
#  :latest_restorable_time=>2017-11-29 22:40:00 UTC,
#  :multi_az=>true,
#  :engine_version=>"5.6.37",
#  :auto_minor_version_upgrade=>true,
#  :read_replica_db_instance_identifiers=>[],
#  :license_model=>"general-public-license",
#  :option_group_memberships=>[{:option_group_name=>"default:mysql-5-6", :status=>"in-sync"}],
#  :secondary_availability_zone=>"eu-central-1b",
#  :publicly_accessible=>false,
#  :storage_type=>"gp2",
#  :db_instance_port=>0,
#  :storage_encrypted=>false,
#  :dbi_resource_id=>"db-YTKKUN354HHHIBKFJE6AHYME4A",
#  :ca_certificate_identifier=>"rds-ca-2015",
#  :domain_memberships=>[],
#  :copy_tags_to_snapshot=>false,
#  :monitoring_interval=>0,
#  :db_instance_arn=>"arn:aws:rds:eu-central-1:000270007572:db:stage-rancher-server",
#  :iam_database_authentication_enabled=>false,
#  :performance_insights_enabled=>false}
