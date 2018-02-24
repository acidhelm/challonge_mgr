class UsersController < ApplicationController
    before_action :set_user
    before_action :require_login
    before_action :correct_user?

    # GET /users/1
    def show
    end

    # GET /users/1/edit
    def edit
    end

    # PATCH/PUT /users/1
    def update
        respond_to do |format|
            if @user.update(user_params)
                format.html { redirect_to @user, notice: "The user was updated." }
            else
                format.html { render :edit }
            end
        end
    end

    private
    def set_user
        begin
            @user = User.find(params[:id])
        rescue ActiveRecord::RecordNotFound
            render_not_found_error(:user)
        end
    end

    def user_params
        params.require(:user).permit(:api_key, :subdomain, :password,
                                     :password_confirmation)
    end
end
