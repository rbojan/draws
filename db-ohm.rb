# Alternative zu Datamapper / sqlite
# OHM with redis backend
# Requirements: redis server, adjust to current db.rb

class Instance < Ohm::Model
  attribute :iid
  attribute :name
  attribute :vpc_id
  attribute :vpc_name
  attribute :subnet_id
  attribute :state
  index :name
end

def resource_name(resource)
  resource.tags.select{|tag| tag.key == "Name"}.first.try(:value)
end

def reload_aws_resources
  ec2 = Aws::EC2::Resource.new(region: 'eu-central-1')
  LOG.info "Flush start"
  Ohm.flush
  LOG.info "Flush stop"
  instances = ec2.instances
  instances.each do |instance|
    Instance.create iid: instance.id,
                    name: resource_name(instance),
                    vpc_id: instance.vpc_id,
                    vpc_name: "Name",
                    subnet_id: instance.subnet_id,
                    state: instance.state.name
  end
  LOG.info "AWS Resources Reloaded."
  LOG.info "#{instances.count} instance(s) were loaded."
end
