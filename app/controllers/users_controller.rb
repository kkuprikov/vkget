class UsersController < ApplicationController
  def index
    @dummy_user = User.new
  end
end
