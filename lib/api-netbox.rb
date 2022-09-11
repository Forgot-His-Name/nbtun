class ApiNetbox

  def initialize(opts)
    @opts = opts

    raise 'NETBOX_HOST option not defined' unless @opts[:host]
    raise 'NETBOX_TOKEN option not defined' unless @opts[:token]
  end

  def make_api_call(entrypoint)
    url = "https://#{@opts[:host]}/api/#{entrypoint}"
    uri = URI.parse url
    headers = { 'Content-Type' => 'application/json' }
    headers['Authorization'] = "TOKEN #{@opts[:token]}"
    req = Net::HTTP::Get.new uri, headers

    http = Net::HTTP.new uri.host, uri.port
    http.use_ssl = true

    resp = http.request req
    resp_data = JSON.parse(resp.body)

    if resp_data['error']
      pp resp_data['error']

      raise 'netbox api returns error'
    end

    resp_data['results']
  end

  def get_ips
    make_api_call 'ipam/ip-addresses.json'
  end

  def get_zones
    make_api_call 'plugins/netbox-dns/zones.json'
  end

  def get_records
    make_api_call 'plugins/netbox-dns/records.json'
  end

end
