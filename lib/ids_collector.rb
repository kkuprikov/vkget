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
    ActiveRecord::Base.establish_connection(
      adapter: 'sqlite3',
      database: 'db/development.sqlite3'
    )
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


  def collect_ids range_ids#, refresh_visited_pages = false

    #@visited_pages = [] if refresh_visited_pages

    # html = Net::HTTP.get(@catalog_url)
    # catalog = Nokogiri::HTML(html)
    # range_urls = []
    # catalog.css('div.column4 a').each do |column|
    #   range_urls << column[:href].split("?").last
    # end

    threads = []
    Thread.abort_on_exception = false
    range_ids.each do |range_id|
      # ActiveRecord::Base.establish_connection(
      #   adapter:  "sqlite3",
      #   database: "db/development.sqlite3"
      # )
      print "Start time: #{Time.now}"
      (0..99).each do |x|
        threads << Thread.new("#{@catalog_url}#{range_id}-#{x}") do |url_with_ids|
          Thread.current[:users] = []
          (0..99).each do |y|
            ids = []
            page = "#{url_with_ids}-#{y}"
            # puts "Fetching #{url_with_ids}-#{x}-#{y}"
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
              begin
                # Two subcatalogs for one api request
                get_users_info(ids) if (ids.size > 0) && (y % 2 == 1)
              rescue SQLite3::ConstraintException
                print "Constraint exception caught..."
              end    

            rescue Errno::ETIMEDOUT, Errno::ECONNRESET, Net::OpenTimeout
              sleep(1)
              retry if (retries += 1) < 3
              retries = 0
              next
            end
          end
          # @lock.synchronize do
            # begin
              # retries ||= 0
              # ActiveRecord::Base.establish_connection(
                # adapter:  "postgresql",
                # database: "vkget_development"
              # )
              begin
                ActiveRecord::Base.connection_pool.with_connection do
                  User.import Thread.current[:users], on_duplicate_key_ignore: true
                end
              ensure
                puts "Insert processed with #{Thread.current[:users].count} items"
                ActiveRecord::Base.connection_pool.release_connection
              end
                # ActiveRecord::Base.connection.close
            # rescue ActiveRecord::StatementInvalid
              # retry if (retries += 1) < 3
            # end
          end
          print " #{Time.now}: pages processed #{@visited_pages.count} "
          Thread.exit
        end
      end
      threads.each { |thr| thr.join; ActiveRecord::Base.connection.close }
      sleep(10)
    end
    # end
  end

  def get_users_info ids
    users = Net::HTTP.get(URI("#{@api_url}users.get?user_ids=#{ids.join(",")}&fields=#{@fields}&v=5.63"))
    save_data(Oj.load(users)["response"])
  end

  def save_data response
    if !response
      print "Response is nil!"
      return
    end
    # users = []
    response.each do |user_data|
      user = {}
      next if user_data["deactivated"] || Time.at(user_data["last_seen"]["time"]) < (DateTime.now - @days_offline)
      
      user[:id] = user_data["id"]
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

      # if user_data["contacts"]
      #   user.mobile_phone = user_data["contacts"]["mobile_phone"] 
      #   user.home_phone = user_data["contacts"]["home_phone"]
      #   user.counters = user_data["contacts"]["counters"]
      # end

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

      # puts user_data
      user.attributes = user_data.except("city", "contacts", "country", "education", "occupation", "timezone", "hidden", "last_seen", "education_form", "education_status", "relation_partner", "facebook_name")
      Thread.current[:users] << user
    end
  end

  def collect_groups
    group_uri = URI("#{@api_url}groups.get?user_ids=#{id}&access_token=#{@access_token}&v=5.63")
    puts group_uri
    # JSON.parse(Net::HTTP.get(group_uri))["response"]["items"] rescue puts "ERROR URL #{group_uri}"
    Oj.load(Net::HTTP.get(group_uri))["response"]["items"] rescue puts "ERROR URL #{group_uri}"
  end

end
