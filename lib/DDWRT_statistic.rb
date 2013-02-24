require 'net/http'
require 'net/telnet'
require 'date'
require 'JSON'
require 'mysql2'
require 'active_record'
require "DDWRT_statistic/version"

module DDWRTStatistic

	ActiveRecord::Base.establish_connection(
      :adapter  => "mysql2",
      :host     => "localhost",
      :username => "root",
      :password => "1111",
      :database => "DDWRT"
    )
 

	class ResultData
	  attr_accessor :date, :snr, :signal, :noise, :channel, :frequency, :temperature, :humidity, :wind, :speed 
	  @@speed = 0
	end

	class Statistics < ActiveRecord::Base  
	end

	class DDWRT
	  attr_accessor :iwlist, :iwconfig, :data

	  def initialize
	    @@data = ResultData.new    
	  end
	   
	  def index
	    @scan_result = ""
	    @config_result = ""
	    weather = get_weather

	    print "\nconnection to router"

	    ap = connection('192.168.1.2', 'root', '1') 

	    puts " - OK"
	    
	    ap.cmd("iwlist ath0 scanning") { |c| @scan_result << c }
	    ap.cmd("iwconfig ath0") { |c| @config_result << c }


	    @scan_result = parser(@scan_result, "64:70:02:64:B2:D0", "Bit Rates")
	    prepare_data( @scan_result, @config_result, weather )
	    puts "\n* * * * * * * * * * RESULTS * * * * * * * * * * * * * * * * * * * *"

	    
	    if Statistics.new(
	      :date => @@data.date,
	      :snr => @@data.snr,
	      :signal => @@data.signal,
	      :noise => @@data.noise,
	      :channel => @@data.channel,
	      :frequency => @@data.frequency,
	      :temperature => @@data.temperature,
	      :humidity => @@data.humidity,
	      :wind => @@data.wind,
	      :speed => @@data.speed
	      ).save then
	        puts 'Insert success!!! )))'
	        puts_info
	      else
	        puts 'Insert failed ((('
	      end
	  end

	  def parser (string, st, en)
	    string = string[string.index(st) + st.length, string.length]
	    string = string[0, string.index(en)]
	  end

	  def connection (ip, name, pass) 
	    localhost = Net::Telnet::new("Host" => ip,
	                             "Timeout" => 10,
	                             "Prompt" => /[$%#>] \z/)
	    localhost.login("Name" => name, "Password" => pass)
	    return localhost  
	  end

	  def speed_test
	    uri = URI('http://cs5151.userapi.com/u5516966/97048765/w_fbd274eb.jpg')

	    Net::HTTP.start(uri.host, uri.port) do |http|
	    request = Net::HTTP::Get.new uri.request_uri
	      http.request request do |response|
	        open 'd://test.txt', 'w' do |io|
	          response.read_body do |chunk|
	            io.write chunk
	          end
	        end
	      end     
	    end
	  end

	  def get_speed
	    speed = 0
	    5.times do
	        start = Time.now.to_f
	        speed_test  
	        speed += (900 / (Time.now.to_f - start) * 8).to_f
	        print '.'     
	    end
	    puts ' '
	    @@data.speed = speed / 5 
	  end

	  def get_weather
	    print "\ngeting weather"
	    uri = URI('http://openweathermap.org/data/weather/?type=json')
	    res = Net::HTTP.get_response(uri) 
	    puts " - OK"
	    JSON.parse(res.body)
	    
	  end

	  def puts_info
	    puts "\nnow: " + @@data.date.to_s
	    puts "\nsnr: " + @@data.snr + 'db'
	    puts "\nrssi: " + @@data.signal + "dBm"
	    puts "\nnoise level: " + @@data.noise + "dBm"
	    puts "\nchannel: " + @@data.channel
	    puts "\nfrequency: " + @@data.frequency + "GHz"
	    puts "\ntemperature: " + @@data.temperature.to_s + ' C'
	    puts "\nhumidity: " + @@data.humidity.to_s + ' %'
	    puts "\nwind: " + @@data.wind.to_s + ' m/s'
	    puts "\ninternet speed: " + @@data.speed.to_s + ' kbt/s' 
	  end

	  def prepare_data (scan_result, config_result, weather)
	    puts "\nparse date"
	    @@data.date = Time.now
	    puts "\nparse snr"
	    @@data.snr = parser(scan_result, "Quality=", "/94")
	    puts "\nparse rssi"
	    @@data.signal = parser(scan_result, "Signal level=", "dBm")
	    puts "\nparse noise"
	    @@data.noise = parser(config_result, "Noise level=", "dBm")
	    puts "\nparse channel"
	    @@data.channel = parser(scan_result, "Channel", ")")
	    puts "\nparse frequency"
	    @@data.frequency = parser(scan_result, "Frequency:", "GHz")
	    puts "\nparse temperature"
	    @@data.temperature = weather['temp']
	    puts "\nparse humidity"
	    @@data.humidity = weather['humidity']
	    puts "\nparse wind"
	    @@data.wind = weather['wind']
	    print "\ntesting internet speed"
	    @@data.speed = get_speed
	    return @@data
	  end
	end
	
	DDWRT.new.index()
end
