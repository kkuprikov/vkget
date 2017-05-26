class ApiController < ApplicationController

  def users_count
    @count = User.get_user_count_from_clickhouse(params)
    respond_to do |format|
      format.json { render json: @count }
    end
  end

  def user_ids
    @count = User.get_user_ids_from_clickhouse(params)
    respond_to do |format|
      format.json { render json: @count }
    end
  end


  def countries
    res = get_dictionary("country_id", "country_title")
    respond_to do |format|
      format.json { render json: JSON.parse(res) }
    end
  end

  def cities
    population = params[:population].to_i > 0 ? params[:population].to_i : 0
    query = "select * from (select distinct city_id, city_name, count(*) as pop from vk.users where city_name!='' and country_id=toString(#{params[:country_id]}) group by city_id, city_name, country_id) where pop > #{params[:population]} format JSON;"
    Rails.logger.error query
    res = Typhoeus.post('http://localhost:8123/', body: query).response_body
    respond_to do |format|
      format.json { render json: JSON.parse(res) }
    end
  end

  def universities
    res = get_dictionary("university", "university_name", "country_id=toString(#{params[:country_id]})")
    respond_to do |format|
      format.json { render json: JSON.parse(res) }
    end
  end

  private

  def get_dictionary id_column, data_column, where_clause=""
    query = "select distinct #{id_column}, #{data_column} from vk.users where #{data_column}!=''"
    query += " AND #{where_clause}" if !where_clause.blank?
    query += " format JSON"
    Rails.logger.error query
    Typhoeus.post('http://localhost:8123/', body: query).response_body
  end

end
