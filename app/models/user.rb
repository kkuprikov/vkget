class User < ApplicationRecord
  serialize :career, JSON
  serialize :connections, JSON
  serialize :counters, JSON
  serialize :exports, JSON
  serialize :personal, JSON
  serialize :relatives, JSON
  serialize :universities, JSON

  def self.get_user_count_from_clickhouse params
    params[:fields] = "count(*)"
    get_from_clickhouse params
  end

  def self.get_user_ids_from_clickhouse params
    params[:fields] = "user_id"
    get_from_clickhouse params
  end  

  def self.get_from_clickhouse params
    Rails.logger.error params.keys
    where_clause = ""
    where_clause += " and toUInt64(user_id) IN (select user_id from vk.user_groups where group_id IN (#{params[:group_id]}))" if params[:group_id]
    where_clause += " and toUInt64(user_id) NOT IN (select user_id from vk.user_groups where group_id IN (#{params[:group_id_exclude]}))" if params[:group_id_exclude]

    where_keys = params.keys & ["city_id", "sex", "relation", "country_id"]
    where_keys.each { |key|
      key_ids = params[key].split(",").map{|x| "toString(#{x})"}.join(", ")
      where_clause += " and #{key} in (#{key_ids})"
    }

    if params[:age_from]
      from_clause = "(select * from vk.users where bdate != '')"
      where_clause += " and toDate(bdate) <= toDate('#{params[:age_from].to_i.years.ago.strftime('%Y-%m-%d')}')"
    end

    if params[:age_to]
      from_clause = "(select * from vk.users where bdate != '')"
      where_clause += " and toDate(bdate) >= toDate('#{params[:age_to].to_i.years.ago.strftime('%Y-%m-%d')}')"
    end

    if params[:age_undef]
      where_clause += " and bdate = ''"
    end

    if params[:university_ids]
      university_ids = params[:university_ids].split(",").map{|x| "toString(#{x})"}.join(", ")
      where_clause += " and university in (#{university_ids})"
    end

    if params[:graduated_from]
      where_clause += " and graduation!='' and toUInt32(graduation)>=#{params[:graduated_from]}"
    end

    if params[:graduated_to]
      where_clause += " and graduation!='' and toUInt32(graduation)<=#{params[:graduated_from]}"
    end

    if params[:career]
      where_clause += " and career like '%position\":\"#{params[:career]}%'"
    end

    if params[:first_name]
      where_clause += " and first_name like '%#{params[:first_name]}%'"
    end

    if !where_clause.blank?
      where_clause.slice!(0..3)
      where_clause = "where #{where_clause}"
    end
    from_clause ||= "vk.users" 
    query = "select #{params[:fields]} from #{from_clause} #{where_clause}"
    Rails.logger.error query
    Typhoeus.post('http://localhost:8123/', body: query).response_body
  end
end
