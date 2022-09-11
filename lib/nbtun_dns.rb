class NbtUn

  def load_zones
    zones = {}

    data = @netbox.get_zones
    data.each do |zone|
      next unless zone['active']

      name = zone['name']
      zones[name] = {}
    end

    types = ['A', 'CNAME']

    data = @netbox.get_records
    data.each do |record|
      next unless record['active']
      next unless types.include? record['type']

      zone = record['zone']['name']
      next unless zones[zone]

      name = "#{record['name']}.#{zone}"
      rec = { type: record['type'], value: record['value'] }
      zones[zone][name] = rec
    end

    add_ips_to_zones zones
  end

  def add_ips_to_zones(inp_zones)
    zones = inp_zones.clone

    list = @netbox.get_ips
    list.each do |item|
      next unless item['family']['value'] == 4
      next if item['dns_name'] == ''

      name = item['dns_name']
      host, zone = name.split('.', 2)
      next unless zone

      puts "duplicated name '#{name}' found" if zones[zone] && zones[zone][name]

      addr, mask = item['address'].split('/')
      next unless addr

      rec = { type: 'A', value: addr }

      zones[zone] = {} unless zones[zone]
      zones[zone][name] = rec
    end

    zones
  end

end
