require 'rubygems'
require "active_support/core_ext"
#require 'mechanize'
require 'logger'
#require "benchmark"
#require 'net/smtp'


# Worker classes are normal ruby classes
class DeployContainer01
  # Just include the Mixin below and the perform_async method will be available
  include Sidekiq::Worker
  sidekiq_options :retry => false


def perform(cid, tid, instance_name, description, instance_type, image_name, env_vars, instance_link, ports, shared_vol, depends_on, dp_ins_type)

begin

instance_name_id = tid + instance_name + cid

if env_vars.length > 1

env_array = env_vars.split(",")

envs=""
 env_array.each do |env_array|

  envs = envs + " -e " + env_array
 end
end


if ports.length > 1

ports_array = ports.split(",")

portmap=""
 ports_array.each do |ports_array|

  portmap = portmap + " -p " + ports_array
 end
else
 portmap = " -P "
end

if instance_link.length > 1

#vols = " --volumes-from " + instance_link + " "
vol_array = instance_link.split(",")                                                                            
                                                                                                           
 vols=""                                                                                                    
  vol_array.each do |vol_array|                                                                             
  if shared_vol.length > 1
    vols = vols + " -v /csync/"+ shared_vol  +":" + vol_array
  else                                                                                                         
    vols = vols + " -v /csync/"+ instance_name_id  +":" + vol_array   
  end                                                                      
 end

end

portdis=""
if ports.length > 1

ports_array = ports.split(",")

  ports_array.each do |ports_array|

  portdis = portdis + "ExecStartPost=/usr/bin/bash -c \'etcdctl set /contanko/tanko/"+ tid  +"/"+ instance_type  +"/"+ instance_name_id +"-ip ${COREOS_PRIVATE_IPV4}:$(docker inspect -f \"{{(index (index .NetworkSettings.Ports \\\\\""+ ports_array  +"\\\\\") 0).HostPort}}\" " + instance_name_id +")\'" + "\n" + portdis 

 end

end

binds_to=""
if depends_on.length > 1                                                                                                                                                               

  depends_on_array = depends_on.split(",")                                                                                                                                                    
  depends_on_array.each do |depends_on_array|                                                                                                                                               
  binds_to = "After=" + depends_on_array +".service"

  end

unitfilestalker = %{[Unit]                                                                                                                                
Description=#{description}-stalker                                                                                                                                                       
After=#{instance_name_id}                                                                                                                                                                       
                                                                                                                                                                                  
[Service]
ExecStart=/usr/bin/bash -c ' \
    export IPPORT=$(etcdctl get /contanko/tanko/#{tid}/#{dp_ins_type}/#{depends_on}-ip); \
    while true; do \
        if [[ $IPPORT != $(etcdctl get /contanko/tanko/#{tid}/#{dp_ins_type}/#{depends_on}-ip) ]] ; then $(fleetctl stop #{instance_name_id}.service  && fleetctl start #{instance_name_id}.service); fi; \
        sleep 45; \
    done'
RestartSec=30s
Restart=on-failure

[X-Fleet]
MachineOf=#{instance_name_id}.service
} 

output = File.open( "/tmp/#{instance_name_id}-stalker.service","w" )

output << unitfilestalker
output.close

cmdstalker = "vendor/fleet-v0.11.5-linux-amd64/fleetctl --endpoint http://"+ ENV["HOST_GATEWAY"] +":4001 submit /tmp/#{instance_name_id}-stalker.service"                                                      
cmd2stalker = "vendor/fleet-v0.11.5-linux-amd64/fleetctl --endpoint http://"+ ENV["HOST_GATEWAY"] +":4001 start /tmp/#{instance_name_id}-stalker.service"

end

#ExecStartPre=/usr/bin/docker pull #{image_name}

unitfile = %{[Unit]
Description=#{description}

[Service]
EnvironmentFile=/etc/environment
TimeoutStartSec=900s

ExecStartPre=-/usr/bin/docker kill #{instance_name_id}
ExecStartPre=-/usr/bin/docker rm #{instance_name_id}
ExecStartPre=/bin/bash -c "/usr/bin/docker inspect #{image_name} &> /dev/null || /usr/bin/docker pull #{image_name}"
ExecStartPre=-/usr/bin/bash -c 'sudo chown -R $(etcdctl get /contanko/tanko/#{tid}/#{instance_type}/#{instance_name_id}/volperms) /csync/#{instance_name_id}'
ExecStart=/bin/bash -c 'docker run --rm --name #{instance_name_id} #{envs} #{vols} #{portmap} #{image_name}'
ExecStartPost=/usr/bin/sleep 5
ExecStartPost=-/usr/bin/bash -c '/usr/bin/etcdctl set /contanko/tanko/#{tid}/#{instance_type}/#{instance_name_id}/volperms $(sudo stat -c %%u:%%g /csync/#{instance_name_id})'
#{portdis}
ExecStartPost=-/usr/bin/bash -c "for entry in `docker inspect --format='{{range $p, $conf := .NetworkSettings.Ports}} {{$p}}{{(index $conf 0).HostPort}} {{end}}' #{instance_name_id}` ; do wtf=$(echo $entry | sed 's/\\/tcp/ ${COREOS_PRIVATE_IPV4}:/g' | sed 's/\\/udp/ ${COREOS_PRIVATE_IPV4}:/g') && $(etcdctl set /contanko/tanko/#{tid}/#{instance_type}/#{instance_name_id}/port/$wtf); done"
ExecStartPost=-/bin/bash -c 'fleetctl stop #{instance_name_id}-stalker.service && fleetctl start #{instance_name_id}-stalker.service'
ExecStop=/usr/bin/docker kill #{instance_name_id}
RestartSec=30s
Restart=on-failure

[X-Fleet]
MachineMetadata=type=compute
}

output = File.open( "/tmp/#{instance_name_id}.service","w" )

output << unitfile
output.close

cmd = "vendor/fleet-v0.11.5-linux-amd64/fleetctl --endpoint http://"+ ENV["HOST_GATEWAY"] +":4001 submit /tmp/#{instance_name_id}.service"
cmd2 = "vendor/fleet-v0.11.5-linux-amd64/fleetctl --endpoint http://"+ ENV["HOST_GATEWAY"] +":4001 start /tmp/#{instance_name_id}.service"

# Put the results in a redis list so we can see them on the web interface at each new request
redis.rpush cid, "Start: " + cmd

value = `#{cmd} 2>&1`
value2 = `#{cmd2} 2>&1`

if depends_on.length > 1
  valuestalker = `#{cmdstalker} 2>&1`                                                                                                                                                             
  value2stalker = `#{cmd2stalker} 2>&1` 
  strline2 = cid +" "+ valuestalker +" " + value2stalker
else
  strline2 = ""
end

strline = cid +" "+ value +" " + value2 + " " + strline2
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
