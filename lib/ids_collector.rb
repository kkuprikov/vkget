# require 'open-uri'
require 'net/http'
require 'nokogiri'
# require 'json'
require 'monitor'
require 'active_record'
require 'activerecord-import'
require 'oj'

class IdsCollector

  attr_accessor :visited_pages

  def initialize
    Net::HTTP.keep_alive_timeout = 5
    @catalog_url = URI("https://vk.com/catalog.php?selection=")
    @api_url = URI("https://api.vk.com/method/")
    @days_offline = 14
    @ids_per_api_request = 300
    @lock = Monitor.new
    @visit_lock = Monitor.new
    @new_user_lock = Monitor.new
    @visited_pages = []
    @fields = "sex,bdate,city,country,home_town,domain,has_mobile,contacts,education,universities,last_seen,followers_count,occupation,relatives,relation,personal,connections,exports,career"
    @access_token = "bc69ac54e448b362c950236de2c0a535b85282cb9b6913d411c38d9689dfdc6da49754c1d2ad2a8a2ae6c"
  end


  def collect_ids range_ids

    threads = []
    Thread.abort_on_exception = false
    range_ids.each do |range_id|

      puts "Start time: #{Time.now}"
      (0..99).each do |x|
        threads << Thread.new("#{@catalog_url}#{range_id}-#{x}") do |url_with_ids|
          Thread.current[:users] = []
          (0..99).each do |y|
            ids = []
            page = "#{url_with_ids}-#{y}"
#            print "Fetching #{url_with_ids}-#{y}"
            next if @visited_pages.include?(page)
            @visit_lock.synchronize do
              @visited_pages << page
            end
            begin
              retries ||= 0
              html_with_ids = Net::HTTP.get(URI(page))
              catalog_with_ids = Nokogiri::HTML(html_with_ids)
              
              catalog_with_ids.css('div.column2 a').each do |column|
                ids << column[:href]
              end
              get_users_info(ids) if (ids.size > 0)# && (y % 2 == 1)
            rescue Errno::ETIMEDOUT, Errno::ECONNRESET, Net::OpenTimeout
              sleep(1)
              retry if (retries += 1) < 5
              retries = 0
              next
            end
          end
          Thread.exit
        end
      end
      threads.each { |thr| 
        thr.join
        User.import thr[:users], on_duplicate_key_ignore: true
       # print "Insert processed with #{thr[:users].count} items "
      }
      puts "Stop time #{Time.now}"
    end
    # end
  end

  def get_users_info ids
    url = "#{@api_url}users.get?user_ids=#{ids.join(",")}&fields=#{@fields}&v=5.63"
    users = Net::HTTP.get(URI(url))
    response = Oj.load(users)["response"]
   # response ? save_data(response) : puts "Response is nil! #{url}"
    if response
      save_data(response)
    else
      puts "Response is nil! #{url}"
    end
  end

  def save_data response
    response.each do |user_data|
      user = {}
      next if user_data["deactivated"] || Time.at(user_data["last_seen"]["time"]) < (DateTime.now - @days_offline)
      user = user_data.except("city", "contacts", "country", "education", "occupation", "timezone", "hidden", "last_seen", "education_form", "education_status", "relation_partner", "facebook_name").symbolize_keys
      
      begin
        user[:bdate] = user_data["bdate"].to_date if !user_data["bdate"].blank?
      rescue ArgumentError
        nil
      end
      
      user[:last_seen_platform] = user_data["last_seen"]["platform"] if user_data["last_seen"]
      if user_data["city"]
        user[:city_id] = user_data["city"]["id"]
        user[:city_name] = user_data["city"]["title"] if user_data["city"]
      end

      if user_data["country"]
        user[:country_id] = user_data["country"]["id"] 
        user[:country_title] = user_data["country"]["title"] 
      end
      
      if user_data["education"]
        user[:university_id] = user_data["education"]["university_id"] 
        user[:university_name] = user_data["education"]["university_name"]
        user[:faculty_id] = user_data["education"]["faculty_id"]
        user[:faculty_name] = user_data["education"]["faculty_name"]
        user[:graduation_year] = user_data["education"]["graduation_year"]
      end

      if user_data["occupation"]
        user[:occupation_type] = user_data["occupation"]["type"] 
        user[:occupation_id] = user_data["occupation"]["id"]
        user[:occupation_name] = user_data["occupation"]["name"]
      end

      Thread.current[:users] << user
    end
  end

  def collect_group_members id, offset
    group_uri = URI("#{@api_url}groups.getMembers?group_id=#{id}&offset=#{offset}000&v=5.63")
    res = Oj.load(Net::HTTP.get(group_uri))["response"]
    puts res if !res["items"]
    puts offset
  end

end
