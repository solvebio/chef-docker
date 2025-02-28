################
# action :create
################

# create a container without starting it
docker_container 'hello-world' do
  command '/hello'
  action :create
end

#############
# action :run
#############

# This command will exit succesfully. This will happen on every
# chef-client run.
docker_container 'busybox_ls' do
  repo 'busybox'
  command 'ls -la /'
  not_if "[ ! -z `docker ps -qaf 'name=busybox_ls$'` ]"
  action :run
end

# The :run_if_missing action will only run once. It is the default
# action.
docker_container 'alpine_ls' do
  repo 'alpine'
  tag '3.1'
  command 'ls -la /'
  action :run_if_missing
end

###############
# port property
###############

# This process remains running between chef-client runs, :run will do
# nothing on subsequent converges.
docker_container 'an_echo_server' do
  repo 'alpine'
  tag '3.1'
  command 'nc -ll -p 7 -e /bin/cat'
  port '7:7'
  action :run
end

# let docker pick the host port
docker_container 'another_echo_server' do
  repo 'alpine'
  tag '3.1'
  command 'nc -ll -p 7 -e /bin/cat'
  port '7'
  action :run
end

# specify the udp protocol
docker_container 'an_udp_echo_server' do
  repo 'alpine'
  tag '3.1'
  command 'nc -ul -p 7 -e /bin/cat'
  port '5007:7/udp'
  action :run
end

##############
# action :kill
##############

# start a container to be killed
execute 'bill' do
  command 'docker run --name bill -d busybox nc -ll -p 187 -e /bin/cat'
  not_if "[ ! -z `docker ps -qaf 'name=bill$'` ]"
  action :run
end

docker_container 'bill' do
  action :kill
end

##############
# action :stop
##############

# start a container to be stopped
execute 'hammer_time' do
  command 'docker run --name hammer_time -d busybox nc -ll -p 187 -e /bin/cat'
  not_if "[ ! -z `docker ps -qaf 'name=hammer_time$'` ]"
  action :run
end

docker_container 'hammer_time' do
  action :stop
end

###############
# action :pause
###############

# clean up existed container after a service restart
execute 'rm stale red_light' do
  command 'docker rm -f red_light'
  only_if 'docker ps -a | grep red_light | grep Exited'
  action :run
end

# start a container to be paused
execute 'red_light' do
  command 'docker run --name red_light -d busybox nc -ll -p 42 -e /bin/cat'
  not_if "[ ! -z `docker ps -qaf 'name=red_light$'` ]"
  action :run
end

docker_container 'red_light' do
  action :pause
end

#################
# action :unpause
#################

# start and pause a container to be unpaused
bash 'green_light' do
  code <<-EOF
  docker run --name green_light -d busybox nc -ll -p 42 -e /bin/cat
  docker pause green_light
  EOF
  not_if "[ ! -z `docker ps -qaf 'name=green_light$'` ]"
  action :run
end

docker_container 'green_light' do
  action :unpause
end

#################
# action :restart
#################

# create and stop a container to be restarted
bash 'quitter' do
  code <<-EOF
  docker run --name quitter -d busybox nc -ll -p 69 -e /bin/cat
  docker kill quitter
  EOF
  not_if "[ ! -z `docker ps -qaf 'name=quitter$'` ]"
  action :run
end

docker_container 'quitter' do
  not_if { ::File.exist? '/marker_container_quitter_restarter' }
  action :restart
end

file '/marker_container_quitter_restarter' do
  action :create
end

# start a container to be restarted
execute 'restarter' do
  command 'docker run --name restarter -d busybox nc -ll -p 69 -e /bin/cat'
  not_if "[ ! -z `docker ps -qaf 'name=restarter$'` ]"
  action :run
end

docker_container 'restarter' do
  not_if { ::File.exist? '/marker_container_restarter' }
  action :restart
end

file '/marker_container_restarter' do
  action :create
end

################
# action :delete
################

# create a container to be deleted
execute 'deleteme' do
  command 'docker run --name deleteme -d busybox nc -ll -p 187 -e /bin/cat'
  not_if { ::File.exist?('/marker_container_deleteme') }
  action :run
end

file '/marker_container_deleteme' do
  action :create
end

docker_container 'deleteme' do
  action :delete
end

##################
# action :redeploy
##################

docker_container 'redeployer' do
  repo 'alpine'
  tag '3.1'
  command 'nc -ll -p 7777 -e /bin/cat'
  port '7'
  action :run
end

docker_container 'unstarted_redeployer' do
  repo 'alpine'
  tag '3.1'
  command 'nc -ll -p 7777 -e /bin/cat'
  port '7'
  action :create
end

execute 'redeploy redeployers' do
  command 'touch /marker_container_redeployer'
  creates '/marker_container_redeployer'
  notifies :redeploy, 'docker_container[redeployer]', :immediately
  notifies :redeploy, 'docker_container[unstarted_redeployer]', :immediately
  action :run
end

#############
# bind mounts
#############

directory '/hostbits' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

file '/hostbits/hello.txt' do
  content 'hello there\n'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

directory '/more-hostbits' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

file '/more-hostbits/hello.txt' do
  content 'hello there\n'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

# docker inspect -f "{{ .HostConfig.Binds }}"
docker_container 'bind_mounter' do
  repo 'busybox'
  command 'ls -la /bits /more-bits'
  binds ['/hostbits:/bits', '/more-hostbits:/more-bits']
  action :run_if_missing
end

##############
# volumes_from
##############

# build a chef container
directory '/chefbuilder' do
  owner 'root'
  group 'root'
  action :create
end

execute 'copy chef to chefbuilder' do
  command 'tar cf - /opt/chef | tar xf - -C /chefbuilder'
  creates '/chefbuilder/opt'
  action :run
end

file '/chefbuilder/Dockerfile' do
  content <<-EOF
  FROM scratch
  ADD opt /opt
  EOF
  action :create
end

docker_image 'chef_container' do
  tag 'latest'
  source '/chefbuilder'
  action :build_if_missing
end

# create a volume container
docker_container 'chef_container' do
  command 'true'
  volumes '/opt/chef'
  action :create
end

# Inspect the docker logs with test-kitchen bussers
docker_container 'ohai_debian' do
  command '/opt/chef/embedded/bin/ohai platform'
  repo 'debian'
  volumes_from 'chef_container'
end

#####
# env
#####

# Inspect container logs with test-kitchen bussers
docker_container 'env' do
  repo 'debian'
  env ['PATH=/usr/bin', 'FOO=bar']
  command 'env'
  action :run_if_missing
end

############
# entrypoint
############

# Inspect container logs with test-kitchen bussers
docker_container 'ohai_again' do
  repo 'debian'
  volumes_from 'chef_container'
  entrypoint '/opt/chef/embedded/bin/ohai'
  action :run_if_missing
end

docker_container 'ohai_again_debian' do
  repo 'debian'
  volumes_from 'chef_container'
  entrypoint '/opt/chef/embedded/bin/ohai'
  command 'platform'
  action :run_if_missing
end

##########
# cmd_test
##########
directory '/cmd_test' do
  action :create
end

file '/cmd_test/Dockerfile' do
  content <<-EOF
  FROM alpine
  CMD [ "/bin/ls", "-la", "/" ]
  EOF
  action :create
end

docker_image 'cmd_test' do
  tag 'latest'
  source '/cmd_test'
  action :build_if_missing
end

docker_container 'cmd_test' do
  action :run_if_missing
end

#############
# :autoremove
#############

# Inspect volume container with test-kitchen bussers
docker_container 'sean_was_here' do
  command "touch /opt/chef/sean_was_here-#{Time.new.strftime('%Y%m%d%H%M')}"
  repo 'debian'
  volumes_from 'chef_container'
  autoremove true
  not_if { ::File.exist? '/marker_container_sean_was_here' }
  action :run
end

# marker to prevent :run on subsequent converges.
file '/marker_container_sean_was_here' do
  action :create
end

#########
# cap_add
#########

# Inspect system with test-kitchen bussers
docker_container 'cap_add_net_admin' do
  repo 'debian'
  command 'bash -c "ip addr add 10.9.8.7/24 brd + dev eth0 label eth0:0 ; ip addr list"'
  cap_add 'NET_ADMIN'
  action :run_if_missing
end

docker_container 'cap_add_net_admin_error' do
  repo 'debian'
  command 'bash -c "ip addr add 10.9.8.7/24 brd + dev eth0 label eth0:0 ; ip addr list"'
  action :run_if_missing
end

##########
# cap_drop
##########

# Inspect container logs with test-kitchen bussers
docker_container 'cap_drop_mknod' do
  repo 'debian'
  command 'bash -c "mknod -m 444 /dev/urandom2 c 1 9 ; ls -la /dev/urandom2"'
  cap_drop 'MKNOD'
  action :run_if_missing
end

docker_container 'cap_drop_mknod_error' do
  repo 'debian'
  command 'bash -c "mknod -m 444 /dev/urandom2 c 1 9 ; ls -la /dev/urandom2"'
  action :run_if_missing
end

###########################
# host_name and domain_name
###########################

# Inspect container logs with test-kitchen bussers
docker_container 'fqdn' do
  repo 'debian'
  command 'hostname -f'
  host_name 'computers'
  domain_name 'biz'
  action :run_if_missing
end

#####
# dns
#####

# Inspect container logs with test-kitchen bussers
docker_container 'dns' do
  repo 'debian'
  command 'cat /etc/resolv.conf'
  host_name 'computers'
  dns ['4.3.2.1', '1.2.3.4']
  dns_search ['computers.biz', 'chef.io']
  action :run_if_missing
end

#############
# extra_hosts
#############

# Inspect container logs with test-kitchen bussers
docker_container 'extra_hosts' do
  repo 'debian'
  command 'cat /etc/hosts'
  extra_hosts ['east:4.3.2.1', 'west:1.2.3.4']
  action :run_if_missing
end

############
# cpu_shares
############

# docker inspect -f '{{ .HostConfig.CpuShares }}' cpu_shares
docker_container 'cpu_shares' do
  repo 'alpine'
  tag '3.1'
  command 'ls -la'
  cpu_shares 512
  action :run_if_missing
end

#############
# cpuset_cpus
#############

# docker inspect cpu_shares | grep '"CpusetCpus": "0,1"'
docker_container 'cpuset_cpus' do
  repo 'alpine'
  tag '3.1'
  command 'ls -la'
  cpuset_cpus '0,1'
  action :run_if_missing
end

################
# restart_policy
################

# docker inspect restart_policy | grep 'RestartPolicy'
docker_container 'try_try_again' do
  repo 'alpine'
  tag '3.1'
  command 'grep asdasdasd /etc/passwd'
  restart_policy 'on-failure'
  restart_maximum_retry_count 2
  action :run_if_missing
end

docker_container 'reboot_survivor' do
  repo 'alpine'
  tag '3.1'
  command 'nc -ll -p 123 -e /bin/cat'
  port '123'
  restart_policy 'always'
  action :run_if_missing
end

docker_container 'reboot_survivor_retry' do
  repo 'alpine'
  tag '3.1'
  command 'nc -ll -p 123 -e /bin/cat'
  port '123'
  restart_policy 'always'
  restart_maximum_retry_count 2
  action :run_if_missing
end

#######
# links
#######

# docker inspect -f "{{ .Config.Env }}" link_source
# docker inspect -f "{{ .NetworkSettings.IPAddress }}" link_source
docker_container 'link_source' do
  repo 'alpine'
  tag '3.1'
  env ['FOO=bar', 'BIZ=baz']
  command 'nc -ll -p 321 -e /bin/cat'
  port '321'
  action :run
end

docker_container 'link_source_2' do
  repo 'alpine'
  tag '3.1'
  env ['FOO=few', 'BIZ=buzz']
  command 'nc -ll -p 322 -e /bin/cat'
  port '322'
  action :run
end

# docker inspect -f "{{ .HostConfig.Links }}" link_target_1
# docker inspect -f "{{ .Config.Env }}" link_target_1
docker_container 'link_target_1' do
  repo 'alpine'
  tag '3.1'
  env ['ASD=asd']
  command 'ping -c 1 hello'
  links 'link_source:hello'
  subscribes :run, 'docker_container[link_source]'
  action :run_if_missing
end

# docker logs linker_target_2
docker_container 'link_target_2' do
  repo 'alpine'
  tag '3.1'
  command 'env'
  links ['link_source:hello']
  subscribes :run, 'docker_container[link_source]'
  action :run_if_missing
end

# docker logs linker_target_3
docker_container 'link_target_3' do
  repo 'alpine'
  tag '3.1'
  env ['ASD=asd']
  command 'ping -c 1 hello_again'
  links ['link_source:hello', 'link_source_2:hello_again']
  subscribes :run, 'docker_container[link_source]'
  subscribes :run, 'docker_container[link_source_2]'
  action :run_if_missing
end

# docker logs linker_target_4
docker_container 'link_target_4' do
  repo 'alpine'
  tag '3.1'
  command 'env'
  links ['link_source:hello', 'link_source_2:hello_again']
  subscribes :run, 'docker_container[link_source]'
  subscribes :run, 'docker_container[link_source_2]'
  action :run_if_missing
end

# When we deploy the link_source container links are broken and we
# have to redeploy the linked containers to fix them.
execute 'redeploy_link_source' do
  command 'touch /marker_container_redeploy_link_source'
  creates '/marker_container_redeploy_link_source'
  notifies :redeploy, 'docker_container[link_source_2]'
  notifies :redeploy, 'docker_container[link_target_1]'
  notifies :redeploy, 'docker_container[link_target_2]'
  notifies :redeploy, 'docker_container[link_target_3]'
  notifies :redeploy, 'docker_container[link_target_4]'
  action :run
end

##############
# link removal
##############

# docker inspect -f "{{ .Volumes }}" another_link_source
# docker inspect -f "{{ .HostConfig.Links }}" another_link_source
docker_container 'another_link_source' do
  repo 'alpine'
  tag '3.1'
  command 'nc -ll -p 456 -e /bin/cat'
  port '456'
  action :run_if_missing
end

# docker inspect -f "{{ .HostConfig.Links }}" another_link_target
docker_container 'another_link_target' do
  repo 'alpine'
  tag '3.1'
  command 'ping -c 1 hello'
  links ['another_link_source:derp']
  action :run_if_missing
end

file '/marker_container_remover' do
  notifies :remove_link, 'docker_container[another_link_target]', :immediately
  action :create
end

################
# volume removal
################

directory '/dangler' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

file '/dangler/Dockerfile' do
  content <<-EOF
  FROM busybox
  RUN mkdir /stuff
  VOLUME /stuff
  EOF
  action :create
end

docker_image 'dangler' do
  tag 'latest'
  source '/dangler'
  action :build_if_missing
end

# create a volume container
docker_container 'dangler' do
  command 'true'
  not_if { ::File.exist?('/marker_container_dangler') }
  action :create
end

file '/marker_container_dangler' do
  action :create
end

docker_container 'dangler_volume_remover' do
  container_name 'dangler'
  remove_volumes true
  action :delete
end

#########
# mutator
#########

docker_tag 'mutator_from_busybox' do
  target_repo 'busybox'
  target_tag 'latest'
  to_repo 'someara/mutator'
  to_tag 'latest'
end

docker_container 'mutator' do
  repo 'someara/mutator'
  tag 'latest'
  command "sh -c 'touch /mutator-`date +\"%Y-%m-%d_%H-%M-%S\"`'"
  outfile '/mutator.tar'
  force true
  action :run_if_missing
end

execute 'commit mutator' do
  command 'touch /marker_container_mutator'
  creates '/marker_container_mutator'
  notifies :commit, 'docker_container[mutator]', :immediately
  notifies :export, 'docker_container[mutator]', :immediately
  notifies :redeploy, 'docker_container[mutator]', :immediately
  action :run
end

##############
# network_mode
##############

docker_container 'network_mode' do
  repo 'alpine'
  tag '3.1'
  command 'nc -ll -p 777 -e /bin/cat'
  port '777:777'
  network_mode 'host'
  action :run
end

#########
# ulimits
#########

docker_container 'ulimits' do
  repo 'alpine'
  tag '3.1'
  command 'nc -ll -p 778 -e /bin/cat'
  port '778:778'
  cap_add 'SYS_RESOURCE'
  ulimits [
    { 'Name' => 'nofile', 'Soft' => 40_960, 'Hard' => 40_960 },
    { 'Name' => 'core', 'Soft' => 100_000_000, 'Hard' => 100_000_000 },
    { 'Name' => 'memlock', 'Soft' => 100_000_000, 'Hard' => 100_000_000 }
  ]
  action :run
end

##############
# api_timeouts
##############

docker_container 'api_timeouts' do
  command 'nc -ll -p 779 -e /bin/cat'
  repo 'alpine'
  tag '3.1'
  read_timeout 60
  write_timeout 60
end

##############
# uber_options
##############

# start a container to be modified
execute 'uber_options' do
  command 'docker run --name uber_options -d busybox nc -ll -p 187 -e /bin/cat'
  not_if "[ ! -z `docker ps -qaf 'name=uber_options$'` ]"
  action :run
end

docker_container 'uber_options' do
  repo 'alpine'
  tag '3.1'
  hostname 'www'
  domainname 'computers.biz'
  env ['FOO=foo', 'BAR=bar']
  mac_address '00:00:DE:AD:BE:EF'
  network_disabled false
  tty true
  volumes ['/root']
  working_dir '/'
  binds ['/hostbits:/bits', '/more-hostbits:/more-bits']
  cap_add %w(NET_ADMIN SYS_RESOURCE)
  cap_drop 'MKNOD'
  cpu_shares 512
  cpuset_cpus '0,1'
  dns ['8.8.8.8', '8.8.4.4']
  dns_search ['computers.biz']
  extra_hosts ['east:4.3.2.1', 'west:1.2.3.4']
  links ['link_source:hello']
  network_mode 'host'
  port '1234:1234'
  volumes_from 'chef_container'
  user 'operator'
  command "-c 'nc -ll -p 1234 -e /bin/cat'"
  entrypoint '/bin/sh'
  ulimits [
    'nofile=40960:40960',
    'core=100000000:100000000',
    'memlock=100000000:100000000'
  ]
  labels ['foo:bar', 'hello:world']
  action :run
end

###########
# overrides
###########

# build a chef container
directory '/overrides' do
  owner 'root'
  group 'root'
  action :create
end

file '/overrides/Dockerfile' do
  content <<-EOF
  FROM busybox
  RUN adduser -D bob
  CMD [ "ls", "-la", "/" ]
  USER bob
  ENV FOO foo
  ENV BAR bar
  ENV BIZ=biz BAZ=baz
  VOLUME /home
  WORKDIR /var
  EOF
  notifies :build, 'docker_image[overrides]'
  action :create
end

docker_image 'overrides' do
  tag 'latest'
  source '/overrides'
  force true
  action :build_if_missing
  notifies :redeploy, 'docker_container[overrides-1]'
  notifies :redeploy, 'docker_container[overrides-2]'
end

docker_container 'overrides-1' do
  repo 'overrides'
  action :run_if_missing
end

docker_container 'overrides-2' do
  repo 'overrides'
  user 'operator'
  entrypoint '/bin/sh -c'
  command 'ls -laR /'
  env ['FOO=biz']
  volume '/var/log'
  workdir '/tmp'
  action :run_if_missing
end

#################
# host override
#################

docker_container 'host_override' do
  repo 'alpine'
  host 'tcp://127.0.0.1:2376'
  command 'ls -la /'
  action :create
end

#################
# logging drivers
#################

docker_container 'syslogger' do
  command 'nc -ll -p 780 -e /bin/cat'
  repo 'alpine'
  tag '3.1'
  log_driver 'syslog'
  log_opts 'syslog-tag=container-syslogger'
end
