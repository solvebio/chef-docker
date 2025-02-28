require 'spec_helper'

describe 'docker_test::container' do
  cached(:chef_run) { ChefSpec::SoloRunner.converge('docker_test::container') }

  before do
    stub_command("[ ! -z `docker ps -qaf 'name=busybox_ls$'` ]").and_return(false)
    stub_command("[ ! -z `docker ps -qaf 'name=bill$'` ]").and_return(false)
    stub_command("[ ! -z `docker ps -qaf 'name=hammer_time$'` ]").and_return(false)
    stub_command('docker ps -a | grep red_light | grep Exited').and_return(true)
    stub_command("[ ! -z `docker ps -qaf 'name=red_light$'` ]").and_return(false)
    stub_command("[ ! -z `docker ps -qaf 'name=green_light$'` ]").and_return(false)
    stub_command("[ ! -z `docker ps -qaf 'name=quitter$'` ]").and_return(false)
    stub_command("[ ! -z `docker ps -qaf 'name=restarter$'` ]").and_return(false)
    stub_command("[ ! -z `docker ps -qaf 'name=uber_options$'` ]").and_return(false)
  end

  context 'testing create action' do
    it 'create docker_container[hello-world]' do
      expect(chef_run).to create_docker_container('hello-world').with(
        container_name: 'hello-world',
        repo: nil,
        tag: 'latest',
        command: '/hello',
        api_retries: 0, # expecting 3
        attach_stderr: true,
        attach_stdin: false,
        attach_stdout: true,
        autoremove: false,
        binds: nil,
        cap_add: nil,
        cap_drop: nil,
        cgroup_parent: '',
        cpu_shares: 0,
        cpuset_cpus: '',
        detach: true,
        devices: nil,
        dns: nil,
        dns_search: nil,
        domain_name: '',
        entrypoint: nil,
        env: nil,
        extra_hosts: nil,
        exposed_ports: nil,
        force: false,
        host: nil,
        host_name: nil,
        labels: nil,
        links: nil,
        log_config: nil,
        log_driver: nil,
        log_opts: [],
        mac_address: '',
        memory: 0,
        memory_swap: -1,
        network_disabled: false,
        network_mode: nil,
        open_stdin: false,
        outfile: nil,
        port: nil,
        port_bindings: nil,
        privileged: false,
        publish_all_ports: false,
        read_timeout: 60,
        remove_volumes: false,
        restart_maximum_retry_count: 0,
        restart_policy: 'no',
        security_opts: [''],
        signal: 'SIGKILL',
        stdin_once: false,
        timeout: nil,
        tty: false,
        ulimits: nil,
        user: '',
        volumes: nil,
        volumes_from: nil,
        working_dir: nil,
        write_timeout: nil
      )
    end
  end

  context 'testing run action' do
    it 'run docker_container[hello-world]' do
      expect(chef_run).to run_docker_container('busybox_ls').with(
        repo: 'busybox',
        command: 'ls -la /'
      )
    end

    it 'run_if_missing docker_container[alpine_ls]' do
      expect(chef_run).to run_if_missing_docker_container('alpine_ls').with(
        repo: 'alpine',
        tag: '3.1',
        command: 'ls -la /'
      )
    end
  end

  context 'testing ports property' do
    it 'run docker_container[an_echo_server]' do
      expect(chef_run).to run_docker_container('an_echo_server').with(
        repo: 'alpine',
        tag: '3.1',
        command: 'nc -ll -p 7 -e /bin/cat',
        port: '7:7'
      )
    end

    it 'run docker_container[another_echo_server]' do
      expect(chef_run).to run_docker_container('another_echo_server').with(
        repo: 'alpine',
        tag: '3.1',
        command: 'nc -ll -p 7 -e /bin/cat',
        port: '7'
      )
    end

    it 'run docker_container[an_udp_echo_server]' do
      expect(chef_run).to run_docker_container('an_udp_echo_server').with(
        repo: 'alpine',
        tag: '3.1',
        command: 'nc -ul -p 7 -e /bin/cat',
        port: '5007:7/udp'
      )
    end
  end

  context 'testing action :kill' do
    it 'run execute[bill]' do
      expect(chef_run).to run_execute('bill').with(
        command: 'docker run --name bill -d busybox nc -ll -p 187 -e /bin/cat'
      )
    end

    it 'kill docker_container[bill]' do
      expect(chef_run).to kill_docker_container('bill')
    end
  end

  context 'testing action :stop' do
    it 'run execute[hammer_time]' do
      expect(chef_run).to run_execute('hammer_time').with(
        command:  'docker run --name hammer_time -d busybox nc -ll -p 187 -e /bin/cat'
      )
    end

    it 'stop docker_container[hammer_time]' do
      expect(chef_run).to stop_docker_container('hammer_time')
    end
  end

  context 'testing action :pause' do
    it 'run execute[rm stale red_light]' do
      expect(chef_run).to run_execute('rm stale red_light').with(
        command: 'docker rm -f red_light'
      )
    end

    it 'run execute[red_light]' do
      expect(chef_run).to run_execute('red_light').with(
        command:  'docker run --name red_light -d busybox nc -ll -p 42 -e /bin/cat'
      )
    end

    it 'pause docker_container[red_light]' do
      expect(chef_run).to pause_docker_container('red_light')
    end
  end

  context 'testing action :unpause' do
    it 'run bash[green_light]' do
      expect(chef_run).to run_bash('green_light')
    end

    it 'unpause docker_container[green_light]' do
      expect(chef_run).to unpause_docker_container('green_light')
    end
  end

  context 'testing action :restart' do
    it 'run bash[quitter]' do
      expect(chef_run).to run_bash('quitter')
    end

    it 'restart docker_container[quitter]' do
      expect(chef_run).to restart_docker_container('quitter')
    end

    it 'create file[/marker_container_quitter_restarter]' do
      expect(chef_run).to create_file('/marker_container_quitter_restarter')
    end

    it 'run execute[restarter]' do
      expect(chef_run).to run_execute('restarter').with(
        command: 'docker run --name restarter -d busybox nc -ll -p 69 -e /bin/cat'
      )
    end

    it 'restart docker_container[restarter]' do
      expect(chef_run).to restart_docker_container('restarter')
    end

    it 'create file[/marker_container_restarter]' do
      expect(chef_run).to create_file('/marker_container_restarter')
    end
  end

  context 'testing action :delete' do
    it 'run execute[deleteme]' do
      expect(chef_run).to run_execute('deleteme').with(
        command: 'docker run --name deleteme -d busybox nc -ll -p 187 -e /bin/cat'
      )
    end

    it 'create file[/marker_container_deleteme' do
      expect(chef_run).to create_file('/marker_container_deleteme')
    end

    it 'delete docker_container[deleteme]' do
      expect(chef_run).to delete_docker_container('deleteme')
    end
  end

  context 'testing action :redeploy' do
    it 'runs docker_container[redeployer]' do
      expect(chef_run).to run_docker_container('redeployer').with(
        repo: 'alpine',
        tag: '3.1',
        command: 'nc -ll -p 7777 -e /bin/cat',
        port: '7'
      )
    end

    it 'creates docker_container[unstarted_redeployer]' do
      expect(chef_run).to create_docker_container('unstarted_redeployer').with(
        repo: 'alpine',
        tag: '3.1',
        command: 'nc -ll -p 7777 -e /bin/cat',
        port: '7'
      )
    end

    it 'runs execute[redeploy redeployers]' do
      expect(chef_run).to run_execute('redeploy redeployers')
    end
  end

  context 'testing bind_mounts' do
    it 'creates directory[/hostbits]' do
      expect(chef_run).to create_directory('/hostbits').with(
        owner: 'root',
        group: 'root',
        mode: '0755'
      )
    end

    it 'creates file[/hostbits/hello.txt]' do
      expect(chef_run).to create_file('/hostbits/hello.txt').with(
        content: 'hello there\n',
        owner: 'root',
        group: 'root',
        mode: '0644'
      )
    end

    it 'creates directory[/more-hostbits]' do
      expect(chef_run).to create_directory('/more-hostbits').with(
        owner: 'root',
        group: 'root',
        mode: '0755'
      )
    end

    it 'creates file[/more-hostbits/hello.txt]' do
      expect(chef_run).to create_file('/more-hostbits/hello.txt').with(
        content: 'hello there\n',
        owner: 'root',
        group: 'root',
        mode: '0644'
      )
    end

    it 'run_if_missing docker_container[bind_mounter]' do
      expect(chef_run).to run_if_missing_docker_container('bind_mounter').with(
        repo: 'busybox',
        command: 'ls -la /bits /more-bits',
        binds: ['/hostbits:/bits', '/more-hostbits:/more-bits']
      )
    end
  end

  context 'testing volumes_from' do
    it 'creates directory[/chefbuilder]' do
      expect(chef_run).to create_directory('/chefbuilder').with(
        owner: 'root',
        group: 'root'
      )
    end

    it 'runs execute[copy chef to chefbuilder]' do
      expect(chef_run).to run_execute('copy chef to chefbuilder').with(
        command: 'tar cf - /opt/chef | tar xf - -C /chefbuilder',
        creates: '/chefbuilder/opt'
      )
    end

    it 'creates file[/chefbuilder/Dockerfile]' do
      expect(chef_run).to create_file('/chefbuilder/Dockerfile')
    end

    it 'build_if_missing docker_image[chef_container]' do
      expect(chef_run).to build_if_missing_docker_image('chef_container').with(
        tag: 'latest',
        source: '/chefbuilder'
      )
    end

    it 'create docker_container[chef_container]' do
      expect(chef_run).to create_docker_container('chef_container').with(
        command: 'true',
        volumes: '/opt/chef'
      )
    end

    it 'run_if_missing docker_container[ohai_debian]' do
      expect(chef_run).to run_if_missing_docker_container('ohai_debian').with(
        command: '/opt/chef/embedded/bin/ohai platform',
        repo: 'debian',
        volumes_from: 'chef_container'
      )
    end
  end

  context 'testing env' do
    it 'run_if_missing docker_container[env]' do
      expect(chef_run).to run_if_missing_docker_container('env').with(
        repo: 'debian',
        env: ['PATH=/usr/bin', 'FOO=bar'],
        command: 'env'
      )
    end
  end

  context 'testing entrypoint' do
    it 'run_if_missing docker_container[ohai_again]' do
      expect(chef_run).to run_if_missing_docker_container('ohai_again').with(
        repo: 'debian',
        volumes_from: 'chef_container',
        entrypoint: '/opt/chef/embedded/bin/ohai'
      )
    end

    it 'run_if_missing docker_container[ohai_again_debian]' do
      expect(chef_run).to run_if_missing_docker_container('ohai_again_debian').with(
        repo: 'debian',
        volumes_from: 'chef_container',
        entrypoint: '/opt/chef/embedded/bin/ohai',
        command: 'platform'
      )
    end
  end

  context 'testing Dockefile CMD directive' do
    it 'creates directory[/cmd_test]' do
      expect(chef_run).to create_directory('/cmd_test')
    end

    it 'creates file[/cmd_test/Dockerfile]' do
      expect(chef_run).to create_file('/cmd_test/Dockerfile')
    end

    it 'build_if_missing docker_image[cmd_test]' do
      expect(chef_run).to build_if_missing_docker_image('cmd_test').with(
        tag: 'latest',
        source: '/cmd_test'
      )
    end

    it 'run_if_missing docker_container[cmd_test]' do
      expect(chef_run).to run_if_missing_docker_container('cmd_test')
    end
  end

  context 'testing autoremove' do
    it 'runs docker_container[sean_was_here]' do
      expect(chef_run).to run_docker_container('sean_was_here').with(
        repo: 'debian',
        volumes_from: 'chef_container',
        autoremove: true
      )
    end

    it 'creates file[/marker_container_sean_was_here]' do
      expect(chef_run).to create_file('/marker_container_sean_was_here')
    end
  end

  context 'testing cap_add' do
    it 'run_if_missing docker_container[cap_add_net_admin]' do
      expect(chef_run).to run_if_missing_docker_container('cap_add_net_admin').with(
        repo: 'debian',
        command: 'bash -c "ip addr add 10.9.8.7/24 brd + dev eth0 label eth0:0 ; ip addr list"',
        cap_add: 'NET_ADMIN'
      )
    end

    it 'run_if_missing docker_container[cap_add_net_admin_error]' do
      expect(chef_run).to run_if_missing_docker_container('cap_add_net_admin_error').with(
        repo: 'debian',
        command: 'bash -c "ip addr add 10.9.8.7/24 brd + dev eth0 label eth0:0 ; ip addr list"'
      )
    end
  end

  context 'testing cap_drop' do
    it 'run_if_missing docker_container[cap_drop_mknod]' do
      expect(chef_run).to run_if_missing_docker_container('cap_drop_mknod').with(
        repo: 'debian',
        command: 'bash -c "mknod -m 444 /dev/urandom2 c 1 9 ; ls -la /dev/urandom2"',
        cap_drop: 'MKNOD'
      )
    end

    it 'run_if_missing docker_container[cap_drop_mknod_error]' do
      expect(chef_run).to run_if_missing_docker_container('cap_drop_mknod_error').with(
        repo: 'debian',
        command: 'bash -c "mknod -m 444 /dev/urandom2 c 1 9 ; ls -la /dev/urandom2"'
      )
    end
  end

  context 'testing host_name and domain_name' do
    it 'run_if_missing docker_container[fqdn]' do
      expect(chef_run).to run_if_missing_docker_container('fqdn').with(
        repo: 'debian',
        command: 'hostname -f',
        host_name: 'computers',
        domain_name: 'biz'
      )
    end
  end

  context 'testing dns' do
    it 'run_if_missing docker_container[dns]' do
      expect(chef_run).to run_if_missing_docker_container('dns').with(
        repo: 'debian',
        command: 'cat /etc/resolv.conf',
        host_name: 'computers',
        dns: ['4.3.2.1', '1.2.3.4'],
        dns_search: ['computers.biz', 'chef.io']
      )
    end
  end

  context 'testing extra_hosts' do
    it 'run_if_missing docker_container[extra_hosts]' do
      expect(chef_run).to run_if_missing_docker_container('extra_hosts').with(
        repo: 'debian',
        command: 'cat /etc/hosts',
        extra_hosts: ['east:4.3.2.1', 'west:1.2.3.4']
      )
    end
  end

  context 'testing cpu_shares' do
    it 'run_if_missing docker_container[cpu_shares]' do
      expect(chef_run).to run_if_missing_docker_container('cpu_shares').with(
        repo: 'alpine',
        tag: '3.1',
        command: 'ls -la',
        cpu_shares: 512
      )
    end
  end

  context 'testing cpuset_cpus' do
    it 'run_if_missing docker_container[cpuset_cpus]' do
      expect(chef_run).to run_if_missing_docker_container('cpuset_cpus').with(
        repo: 'alpine',
        tag: '3.1',
        command: 'ls -la',
        cpuset_cpus: '0,1'
      )
    end
  end

  context 'testing restart_policy' do
    it 'run_if_missing docker_container[try_try_again]' do
      expect(chef_run).to run_if_missing_docker_container('try_try_again').with(
        repo: 'alpine',
        tag: '3.1',
        command: 'grep asdasdasd /etc/passwd',
        restart_policy: 'on-failure',
        restart_maximum_retry_count: 2
      )
    end

    it 'run_if_missing docker_container[reboot_survivor]' do
      expect(chef_run).to run_if_missing_docker_container('reboot_survivor').with(
        repo: 'alpine',
        tag: '3.1',
        command: 'nc -ll -p 123 -e /bin/cat',
        port: '123',
        restart_policy: 'always'
      )
    end

    it 'run_if_missing docker_container[reboot_survivor_retry]' do
      expect(chef_run).to run_if_missing_docker_container('reboot_survivor_retry').with(
        repo: 'alpine',
        tag: '3.1',
        command: 'nc -ll -p 123 -e /bin/cat',
        port: '123',
        restart_policy: 'always',
        restart_maximum_retry_count: 2
      )
    end
  end

  context 'testing links' do
    it 'runs docker_container[link_source]' do
      expect(chef_run).to run_docker_container('link_source').with(
        repo: 'alpine',
        tag: '3.1',
        env: ['FOO=bar', 'BIZ=baz'],
        command: 'nc -ll -p 321 -e /bin/cat',
        port: '321'
      )
    end

    it 'runs docker_container[link_source_2]' do
      expect(chef_run).to run_docker_container('link_source_2').with(
        repo: 'alpine',
        tag: '3.1',
        env: ['FOO=few', 'BIZ=buzz'],
        command: 'nc -ll -p 322 -e /bin/cat',
        port: '322'
      )
    end

    it 'run_if_missing docker_container[link_target_1]' do
      expect(chef_run).to run_if_missing_docker_container('link_target_1').with(
        repo: 'alpine',
        tag: '3.1',
        env: ['ASD=asd'],
        command: 'ping -c 1 hello',
        links: 'link_source:hello'
      )
    end

    it 'run_if_missing docker_container[link_target_2]' do
      expect(chef_run).to run_if_missing_docker_container('link_target_2').with(
        repo: 'alpine',
        tag: '3.1',
        command: 'env',
        links: ['link_source:hello']
      )
    end

    it 'run_if_missing docker_container[link_target_3]' do
      expect(chef_run).to run_if_missing_docker_container('link_target_3').with(
        repo: 'alpine',
        tag: '3.1',
        env: ['ASD=asd'],
        command: 'ping -c 1 hello_again',
        links: ['link_source:hello', 'link_source_2:hello_again']
      )
    end

    it 'run_if_missing docker_container[link_target_4]' do
      expect(chef_run).to run_if_missing_docker_container('link_target_4').with(
        repo: 'alpine',
        tag: '3.1',
        command: 'env',
        links: ['link_source:hello', 'link_source_2:hello_again']
      )
    end

    it 'runs execute[redeploy_link_source]' do
      expect(chef_run).to run_execute('redeploy_link_source')
    end
  end

  context 'testing link removal' do
    it 'run_if_missing docker_container[another_link_source]' do
      expect(chef_run).to run_if_missing_docker_container('another_link_source').with(
        repo: 'alpine',
        tag: '3.1',
        command: 'nc -ll -p 456 -e /bin/cat',
        port: '456'
      )
    end

    it 'run_if_missing docker_container[another_link_target]' do
      expect(chef_run).to run_if_missing_docker_container('another_link_target').with(
        repo: 'alpine',
        tag: '3.1',
        command: 'ping -c 1 hello',
        links: ['another_link_source:derp']
      )
    end

    it 'creates file[/marker_container_remover]' do
      expect(chef_run).to create_file('/marker_container_remover')
    end
  end

  context 'testing volume removal' do
    it 'creates directory[/dangler]' do
      expect(chef_run).to create_directory('/dangler').with(
        owner: 'root',
        group: 'root',
        mode: '0755'
      )
    end

    it 'creates file[/dangler/Dockerfile]' do
      expect(chef_run).to create_file('/dangler/Dockerfile')
    end

    it 'build_if_missing docker_image[dangler]' do
      expect(chef_run).to build_if_missing_docker_image('dangler').with(
        tag: 'latest',
        source: '/dangler'
      )
    end

    it 'creates docker_container[dangler]' do
      expect(chef_run).to create_docker_container('dangler').with(
        command: 'true'
      )
    end

    it 'creates file[/marker_container_dangler]' do
      expect(chef_run).to create_file('/marker_container_dangler')
    end

    it 'deletes docker_container[dangler_volume_remover]' do
      expect(chef_run).to delete_docker_container('dangler_volume_remover').with(
        container_name: 'dangler',
        remove_volumes: true
      )
    end
  end

  context 'testing mutator' do
    it 'tags docker_tag[mutator_from_busybox]' do
      expect(chef_run).to tag_docker_tag('mutator_from_busybox').with(
        target_repo: 'busybox',
        target_tag: 'latest',
        to_repo: 'someara/mutator',
        to_tag: 'latest'
      )
    end

    it 'run_if_missing docker_container[mutator]' do
      expect(chef_run).to run_if_missing_docker_container('mutator').with(
        repo: 'someara/mutator',
        tag: 'latest',
        command: "sh -c 'touch /mutator-`date +\"%Y-%m-%d_%H-%M-%S\"`'",
        outfile: '/mutator.tar',
        force: true
      )
    end

    it 'runs execute[commit mutator]' do
      expect(chef_run).to run_execute('commit mutator')
    end
  end

  context 'testing network_mode' do
    it 'runs docker_container[network_mode]' do
      expect(chef_run).to run_docker_container('network_mode').with(
        repo: 'alpine',
        tag: '3.1',
        command: 'nc -ll -p 777 -e /bin/cat',
        port: '777:777',
        network_mode: 'host'
      )
    end
  end

  context 'testing ulimits' do
    it 'runs docker_container[ulimits]' do
      expect(chef_run).to run_docker_container('ulimits').with(
        repo: 'alpine',
        tag: '3.1',
        command: 'nc -ll -p 778 -e /bin/cat',
        port: '778:778',
        cap_add: 'SYS_RESOURCE',
        ulimits: [
          { 'Name' => 'nofile', 'Soft' => 40_960, 'Hard' => 40_960 },
          { 'Name' => 'core', 'Soft' => 100_000_000, 'Hard' => 100_000_000 },
          { 'Name' => 'memlock', 'Soft' => 100_000_000, 'Hard' => 100_000_000 }
        ]
      )
    end
  end

  context 'testing api_timeouts' do
    it 'run_if_missing docker_container[api_timeouts]' do
      expect(chef_run).to run_if_missing_docker_container('api_timeouts').with(
        command: 'nc -ll -p 779 -e /bin/cat',
        repo: 'alpine',
        tag: '3.1',
        read_timeout: 60,
        write_timeout: 60
      )
    end
  end

  context 'testing uber_options' do
    it 'runs execute[uber_options]' do
      expect(chef_run).to run_execute('uber_options').with(
        command: 'docker run --name uber_options -d busybox nc -ll -p 187 -e /bin/cat'
      )
    end

    it 'runs docker_container[uber_options]' do
      expect(chef_run).to run_docker_container('uber_options').with(
        repo: 'alpine',
        tag: '3.1',
        hostname: 'www',
        domainname: 'computers.biz',
        env: ['FOO=foo', 'BAR=bar'],
        mac_address: '00:00:DE:AD:BE:EF',
        network_disabled: false,
        tty: true,
        volumes: ['/root'],
        working_dir: '/',
        binds: ['/hostbits:/bits', '/more-hostbits:/more-bits'],
        cap_add: %w(NET_ADMIN SYS_RESOURCE),
        cap_drop: 'MKNOD',
        cpu_shares: 512,
        cpuset_cpus: '0,1',
        dns: ['8.8.8.8', '8.8.4.4'],
        dns_search: ['computers.biz'],
        extra_hosts: ['east:4.3.2.1', 'west:1.2.3.4'],
        links: ['link_source:hello'],
        network_mode: 'host',
        port: '1234:1234',
        volumes_from: 'chef_container',
        user: 'operator',
        command: "-c 'nc -ll -p 1234 -e /bin/cat'",
        entrypoint: '/bin/sh',
        ulimits: [
          'nofile=40960:40960',
          'core=100000000:100000000',
          'memlock=100000000:100000000'
        ],
        labels: ['foo:bar', 'hello:world']
      )
    end
  end

  context 'testing overrides' do
    it 'creates directory[/overrides]' do
      expect(chef_run).to create_directory('/overrides').with(
        owner: 'root',
        group: 'root'
      )
    end

    it 'creates file[/overrides/Dockerfile]' do
      expect(chef_run).to create_file('/overrides/Dockerfile')
    end

    it 'build_if_missing docker_image[overrides]' do
      expect(chef_run).to build_if_missing_docker_image('overrides').with(
        tag: 'latest',
        source: '/overrides',
        force: true
      )
    end

    it 'run_if_missing docker_container[overrides-1]' do
      expect(chef_run).to run_if_missing_docker_container('overrides-1').with(
        repo: 'overrides'
      )
    end

    it 'run_if_missing docker_container[overrides-2]' do
      expect(chef_run).to run_if_missing_docker_container('overrides-2').with(
        repo: 'overrides',
        user: 'operator',
        entrypoint: '/bin/sh -c',
        command: 'ls -laR /',
        env: ['FOO=biz'],
        volume: '/var/log',
        workdir: '/tmp'
      )
    end
  end

  context 'testing host overrides' do
    it 'creates docker_container[host_override]' do
      expect(chef_run).to create_docker_container('host_override').with(
        repo: 'alpine',
        host: 'tcp://127.0.0.1:2376',
        command: 'ls -la /'
      )
    end
  end

  context 'testing logging drivers' do
    it 'run_if_missing docker_container[syslogger]' do
      expect(chef_run).to run_if_missing_docker_container('syslogger').with(
        command: 'nc -ll -p 780 -e /bin/cat',
        repo: 'alpine',
        tag: '3.1',
        log_driver: 'syslog',
        log_opts: 'syslog-tag=container-syslogger'
      )
    end
  end
end
