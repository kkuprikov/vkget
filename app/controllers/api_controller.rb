class ApiController < ApplicationController

  def users_count
    @count = User.get_user_count_from_clickhouse(params)
    respond_to do |format|
      format.json { render json: @count }
    end
  end

  def countries
    get_dictionary("country_id", "country_title")
    respond_to do |format|
      format.json { render json: res.to_json }
    end
  end

  def cities
    get_dictionary("city_id", "city_name")
    respond_to do |format|
      format.json { render json: res.to_json }
    end
  end

  def universities
    res = get_dictionary("university", "university_name")
    respond_to do |format|
      format.json { render json: res.to_json }
    end
  end

  private

  def get_dictionary id_column, data_column
    query = "select distinct #{id_column}, #{data_column} from vk.users where #{data_column}!=''"
    Rails.logger.error query
    Typhoeus.post('http://localhost:8123/', body: query).response_body
  end

end
