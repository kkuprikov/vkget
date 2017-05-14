class User < ApplicationRecord
  serialize :career, JSON
  serialize :connections, JSON
  serialize :counters, JSON
  serialize :exports, JSON
  serialize :personal, JSON
  serialize :relatives, JSON
  serialize :universities, JSON

  def self.get_user_count_from_clickhouse params
    Rails.logger.error params.keys
    where_clause = ""
    where_clause += " and toUInt64(user_id) IN (select user_id from vk.user_groups where group_id IN (#{params[:group_id]}))" if params[:group_id]
    where_clause += " and toUInt64(user_id) NOT IN (select user_id from vk.user_groups where group_id IN (#{params[:group_id_exclude]}))" if params[:group_id_exclude]

    # if params[:sex]
      # 0 - undef
      # 1 - female
      # 2 - male
    #   sex_ids = params[:sex].split(",").map{|x| "toString(#{x})"}.join(", ")
    #   where_clause += "and sex in (#{sex_ids})"
    # end

    #TODO: age from..to: get from birth date

    where_keys = params.keys & ["city_id", "sex", "relation"]
    where_keys.each { |key|
      key_ids = params[key].split(",").map{|x| "toString(#{x})"}.join(", ")
      where_clause += " and #{key} in (#{key_ids})"
    }

    if params[:age_from]
      where_clause += " and bdate != '' and toDate(bdate) <= toDate(#{params[:age_from].to_i.years.ago.strftime('%Y-%m-%d')})"
    end

    if params[:age_to]
      where_clause += " and bdate != '' and toDate(bdate) >= toDate(#{params[:age_to].to_i.years.ago.strftime('%Y-%m-%d')})"
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

    if !where_clause.blank?
      where_clause.slice!(0..3)
      where_clause = "where #{where_clause}"
    end
    query = "select count(*) from vk.users #{where_clause}"
    Typhoeus.post('http://localhost:8123/', body: query).response_body
  end
end
