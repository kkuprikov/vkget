class UsersController < ApplicationController

  def index
    @dummy_user = User.new
  end

  def count
    @count = User.get_user_count_from_clickhouse(params)
    respond_to do |format|
      format.json { render json: @count }
    end
  end

end
