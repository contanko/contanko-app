require 'rubygems'
require "active_support/core_ext"
#require 'mechanize'
require 'logger'
#require "benchmark"
#require 'net/smtp'


# Worker classes are normal ruby classes
class DestroyContainer01
  # Just include the Mixin below and the perform_async method will be available
  include Sidekiq::Worker
  sidekiq_options :retry => false

def perform(cid, tid, instance_name, description, instance_type, image_name, env_vars,shared_vol)

begin

instance_name_id = tid + instance_name + cid




unitfilekeyclean = %{[Unit]
Description=#{description}

[Service]
EnvironmentFile=/etc/environment
TimeoutStartSec=900s
ExecStartPre=/usr/bin/bash -c 'etcdctl rm /contanko/tanko/#{tid}/#{instance_type}/#{instance_name_id}-ip'
ExecStart=/usr/bin/bash -c 'etcdctl rm --recursive /contanko/tanko/#{tid}/#{instance_type}/#{instance_name_id}'

}

output = File.open( "/tmp/#{instance_name_id}-keyclean.service","w" ) 
output << unitfilekeyclean                                                                                                                                                        
output.close                                                                                                                                                                      
                                                                                                                                                                                  
cmdkeyclean = "vendor/fleet-v0.11.5-linux-amd64/fleetctl --endpoint http://"+ ENV["HOST_GATEWAY"] +":4001 submit /tmp/#{instance_name_id}-keyclean.service"                                                      
cmd2keyclean = "vendor/fleet-v0.11.5-linux-amd64/fleetctl --endpoint http://"+ ENV["HOST_GATEWAY"] +":4001 start /tmp/#{instance_name_id}-keyclean.service"                                      
                                                                                                                                                                                  
  valuekeyclean = `#{cmdkeyclean} 2>&1`                                                                                                                                                            
  value2keyclean = `#{cmd2keyclean} 2>&1`                                                                                                                                         
  strline2 = cid +" "+ valuekeyclean +" " + value2keyclean                                                                                                                        
  sleep(10) 


createcomp = ""

cmd = "vendor/fleet-v0.11.5-linux-amd64/fleetctl --endpoint http://"+ ENV["HOST_GATEWAY"] +":4001 destroy #{instance_name_id}.service"
cmd2 = "vendor/fleet-v0.11.5-linux-amd64/fleetctl --endpoint http://"+ ENV["HOST_GATEWAY"] +":4001 unload #{instance_name_id}.service"

# Put the results in a redis list so we can see them on the web interface at each new request
redis.rpush cid, "Start: " + cmd

value = `#{cmd} 2>&1`
value2 = `#{cmd2} 2>&1`

sleep(5)

if shared_vol.to_s.strip.length == 0

unitfilecleanup = %{[Unit]
Description=#{description}-volcleanup

[Service]
ExecStart=/usr/bin/bash -c ' \
    fleetctl list-units | grep -qi #{instance_name_id}.service && export RMDIR=false; \
    sleep 5; \
    fleetctl list-units | grep -qi #{instance_name_id}.service && export RMDIR=false; \
    if [[ $RMDIR != false ]] ; then $( sudo rm -rf /csync/#{instance_name_id} ); fi;'

[X-Fleet]
MachineMetadata=type=compute
}

output = File.open( "/tmp/#{instance_name_id}-cleanup.service","w" )

output << unitfilecleanup
output.close

cmdcleanup = "vendor/fleet-v0.11.5-linux-amd64/fleetctl --endpoint http://"+ ENV["HOST_GATEWAY"] +":4001 submit /tmp/#{instance_name_id}-cleanup.service"

cmd2cleanup = "vendor/fleet-v0.11.5-linux-amd64/fleetctl --endpoint http://"+ ENV["HOST_GATEWAY"] +":4001 start /tmp/#{instance_name_id}-cleanup.service"

  valuecleanup = `#{cmdcleanup} 2>&1`

  value2cleanup = `#{cmd2cleanup} 2>&1`
  strline2 ="#{cid} #{valuecleanup} #{value2cleanup}"
  sleep(10)
end

cmdstalker = "vendor/fleet-v0.11.5-linux-amd64/fleetctl --endpoint http://"+ ENV["HOST_GATEWAY"] +":4001 destroy #{instance_name_id}-stalker.service"

cmd2stalker = "vendor/fleet-v0.11.5-linux-amd64/fleetctl --endpoint http://"+ ENV["HOST_GATEWAY"] +":4001 unload #{instance_name_id}-stalker.service"

cmdcleanup = "vendor/fleet-v0.11.5-linux-amd64/fleetctl --endpoint http://"+ ENV["HOST_GATEWAY"] +":4001 destroy #{instance_name_id}-cleanup.service"
cmd2cleanup = "vendor/fleet-v0.11.5-linux-amd64/fleetctl --endpoint http://"+ ENV["HOST_GATEWAY"] +":4001 unload #{instance_name_id}-cleanup.service"

cmdkeyclean = "vendor/fleet-v0.11.5-linux-amd64/fleetctl --endpoint http://"+ ENV["HOST_GATEWAY"] +":4001 destroy #{instance_name_id}-keyclean.service"
cmd2keyclean = "vendor/fleet-v0.11.5-linux-amd64/fleetctl --endpoint http://"+ ENV["HOST_GATEWAY"] +":4001 unload #{instance_name_id}-keyclean.service"

valuestalker = `#{cmdstalker} 2>&1`                                                                                                                                                             
value2stalker = `#{cmd2stalker} 2>&1`

valuecleanup = `#{cmdcleanup} 2>&1`                                                                                                                                                             
value2cleanup = `#{cmd2cleanup} 2>&1`

valuekeyclean = `#{cmdkeyclean} 2>&1`
value2keyclean = `#{cmd2keyclean} 2>&1`
#value=""

strline = cid +" "+ value +" " + value2 +" "+ valuestalker + " " + value2stalker +" " + valuecleanup +" "+ value2cleanup

puts strline


redis.rpush cid, "Finish: " + strline

File.delete("/tmp/#{instance_name_id}.service")
File.delete("/tmp/#{instance_name_id}-cleanup.service")
File.delete("/tmp/#{instance_name_id}-keyclean.service")
File.delete("/tmp/#{instance_name_id}-stalker.service")

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
