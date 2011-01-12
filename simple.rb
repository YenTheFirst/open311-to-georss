require 'sinatra'
require 'net/http'
require 'net/https'
require 'xmlsimple'


$server="mayors24.cityofboston.gov"
$port="4443"
$base_link="/open311/v2/requests.xml?jurisdiction_id=cityofboston.gov&status=opened&service_code=unshoveled-sidewalk-report"
$rfc822="%a, %d %b %Y %H:%M:%S %Z"
get '/rss.xml' do
	http=Net::HTTP.new($server,$port)
	http.use_ssl=true
	xml=http.get($base_link).body
	output_rss(XmlSimple.xml_in(xml))
end

def output_rss(the_hash)
	builder do |xml|
		xml.instruct! :xml, :version => '1.0'
		xml.rss :version => "2.0" do
			xml.channel "xmlns:georss"=>"http://www.georss.org/georss" do
				xml.title "Boston Snow georsss"
				xml.description "cityofboston open311 unshoveled snow"
				xml.link "https://#{$server}:#{$port}#{$base_link}"
				
				the_hash["request"].each do |ticket|
					descrip=ticket["service_name"].to_s+" on "+ticket["address"].to_s
					
					xml.item do
						xml.title descrip
						xml.link "https://#{$server}#{ticket["media_url"]}"
						xml.description  descrip
						
						xml.pubDate ((Time.parse(ticket["requested_datetime"][0]) rescue Time.now).strftime($rfc822))
						xml.guid ticket["token"].to_s
						xml.tag!("georss:point",(ticket["lat"].to_s+" "+ticket["long"].to_s))
					end
				end
			end
		end
	end
end