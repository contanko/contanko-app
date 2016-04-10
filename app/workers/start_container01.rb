require 'rubygems'
require "active_support/core_ext"
#require 'mechanize'
require 'logger'
#require "benchmark"
#require 'net/smtp'


# Worker classes are normal ruby classes
class StartContainer01
  # Just include the Mixin below and the perform_async method will be available
  include Sidekiq::Worker
  sidekiq_options :retry => false




def perform(cid, tid, instance_name, description, instance_type, image_name, env_vars,shared_vol)

begin

instance_name_id = tid + instance_name + cid


cmd = "vendor/fleet-v0.11.5-linux-amd64/fleetctl --endpoint http://172.17.42.1:4001 stop #{instance_name_id}.service"
cmd = "vendor/fleet-v0.11.5-linux-amd64/fleetctl --endpoint http://172.17.42.1:4001 start #{instance_name_id}.service"

# Put the results in a redis list so we can see them on the web interface at each new request
redis.rpush cid, "Start: " + cmd

value = `#{cmd} 2>&1`
value2 = `#{cmd2} 2>&1`


strline = cid +" "+ value +" " + value2

puts strline


redis.rpush cid, "Finish: " + strline


rescue 
        puts $!, $@
        #strline << $!, $@
        #next    # do_something_* again, with the next i

end

    # Put the results in a redis list so we can see them on the web interface at each new request
   # redis.rpush dbid, strline
  end

  # Create a redis client
  def redis
    @redis ||= Redis.new
  end

end
