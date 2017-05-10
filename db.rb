# Structure for tables
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

DataMapper.finalize

# AWS Helper methods
def aws_resource_name(resource)
  p resource.tags.select{|tag| tag.key == "Name"}
  # resource.tags.select{|tag| tag.key == "Name"}.first.try(:value) if resource.tags.select{|tag| tag.key == "Name"}.any?
  "Some-Name"
end

# ETL job :)
def reload_aws_resources
  ec2 = Aws::EC2::Client.new(region: 'eu-central-1')

  LOG.info "Flushing DB ..."
  Instance.auto_migrate!
  Vpc.auto_migrate!
  Subnet.auto_migrate!
  LOG.info "DB Flush done"

  LOG.info "Loading AWS Resources ..."
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

  LOG.info "AWS Resources Reloaded"
end

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
