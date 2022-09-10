class NbtUn

  def initialize
    @opts = {}

    @opts[:netbox] = {}
    @opts[:netbox][:host] = ENV['NETBOX_HOST']
    @opts[:netbox][:token] = ENV['NETBOX_TOKEN']

    @netbox = ApiNetbox.new @opts[:netbox]

    @conf_file = ENV['CONF_FILE']
    @unbound_host = ENV['UNBOUND_HOST']

    @last_reload = ''

    @zones = {}
    @names = {}
  end

  def main_loop
    loop do
      sync

      sleep 60
    end
  end

  def sync
    load_ips

    old_conf = read_config @conf_file
    new_conf = gen_config

    unless old_conf == new_conf
      puts "config changed"
      write_config @conf_file, new_conf
    end

    unless @last_reload == 'ok' && old_conf == new_conf
      unbound_reload
    end
  end

  def unbound_reload
    begin
      addr = Resolv.getaddress @unbound_host
    rescue Resolv::ResolvError
      puts "failed to resolv host '#{@unbound_host}'"
      return false
    end

    cmd = "unbound-control -s #{addr} reload"

    puts "call #{cmd}"
    @last_reload = `#{cmd}`
    puts @last_reload
  end

  def load_ips
    @zones = {}
    @names = {}

    list = @netbox.get_ips
    list.each do |item|
      next unless item['family']['value'] == 4
      next if item['dns_name'] == ''

      name = item['dns_name']
      puts "duplicated name '#{name}' found" if @names[name]

      host, zone = name.split('.', 2)
      next unless zone

      addr, mask = item['address'].split('/')

      @zones[zone] = {} unless @zones[zone]
      @zones[zone][name] = addr if addr

      @names[name] = addr if addr
    end
  end

  def write_config(path, conf)
    File.open(path, 'w') do |file|
      file.write conf
    end
  end

  def read_config(path)
    conf = ''
    begin
      conf = File.read(path)
    rescue Errno::ENOENT
    end

    conf
  end

  def gen_config
    conf = [ "# auto generated, do not edit\n", 'server:' ]

    @zones.each do |zone, hosts|
      conf << "  local-zone: \"#{zone}.\" static"
      hosts.each do |name, addr|
        conf << "    local-data: \"#{name}. IN A #{addr}\""
      end
    end

    conf << ""
    conf.join("\n")
  end

end
