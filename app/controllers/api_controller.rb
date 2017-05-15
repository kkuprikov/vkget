class ApiController < ApplicationController

  def users_count
    @count = User.get_user_count_from_clickhouse(params)
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
    res = get_dictionary("city_id", "city_name")
    respond_to do |format|
      format.json { render json: JSON.parse(res) }
    end
  end

  def universities
    res = get_dictionary("university", "university_name")
    respond_to do |format|
      format.json { render json: JSON.parse(res) }
    end
  end

  private

  def get_dictionary id_column, data_column
    query = "select distinct #{id_column}, #{data_column} from vk.users where #{data_column}!='' format json"
    Rails.logger.error query
    res = Typhoeus.post('http://localhost:8123/', body: query).response_body
    Rails.logger.error res
    res
  end

end
