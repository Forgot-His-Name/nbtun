class NbtUn

  def initialize
    @opts = {}

    @opts[:netbox] = {}
    @opts[:netbox][:host] = ENV['NETBOX_HOST']
    @opts[:netbox][:token] = ENV['NETBOX_TOKEN']

    @netbox = ApiNetbox.new @opts[:netbox]

    @conf_file = ENV['CONF_FILE']
    @unbound_host = ENV['UNBOUND_HOST']

    $stdout.sync = true

    @last_reload = ''
  end

  def main_loop
    loop do
      sync

      sleep 60
    end
  end

  def sync
    zones = load_zones

    old_conf = read_config @conf_file
    new_conf = gen_config zones

    unless old_conf == new_conf
      puts "config changed"
      write_config @conf_file, new_conf
    end

    if @last_reload != 'ok' || old_conf != new_conf
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

    puts "run '#{cmd}'"
    @last_reload = `#{cmd}`.strip
    puts "got '#{@last_reload}'"
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

  def gen_config(zones)
    conf = [ "# auto generated, do not edit\n", 'server:' ]

    zones.each do |zone, hosts|
      conf << "  local-zone: \"#{zone}.\" static"
      hosts.each do |name, params|
        case params[:type]
        when 'A'
          conf << "    local-data: \"#{name}. IN A #{params[:value]}\""
        when 'CNAME'
          conf << "    local-data: \"#{name}. IN CNAME #{params[:value]}\""
        end
      end
    end

    conf << ""
    conf.join("\n")
  end

end
