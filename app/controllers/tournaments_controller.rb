class TournamentsController < ApplicationController
    before_action :set_tournament, only: [:show, :edit, :update, :destroy]

    # GET /tournaments
    def index
        user = User.find(params[:user])

        if params[:refresh].present?
            url = "https://#{user.user_name}:#{user.api_key}@api.challonge.com/" \
                    "v1/tournaments.json"
            response = RestClient.get(url)
            tournaments_array = JSON.parse(response.body)

            @tournaments = tournaments_array.map do |t|
                OpenStruct.new(t["tournament"].with_indifferent_access)
            end.select { |t| t.state == "underway" }.map do |t|
                if (tourney = user.tournaments.find_by(challonge_id: t.id)).present?
                    tourney.update(description: t.description,
                                   challonge_id: t.id,
                                   name: t.name,
                                   state: t.state,
                                   challonge_url: t.full_challonge_url)

                    tourney
                else
                    user.tournaments.create!(
                      description: t.description, challonge_id: t.id, name: t.name,
                      state: t.state, challonge_url: t.full_challonge_url)
                end
            end
        else
            @tournaments = user.tournaments.where(state: "underway")
        end
    end

    # GET /tournaments/1
    def show
    end

    # GET /tournaments/new
    def new
        @tournament = Tournament.new
    end

    # GET /tournaments/1/edit
    def edit
    end

    # POST /tournaments
    def create
        @tournament = Tournament.new(tournament_params)

        respond_to do |format|
            if @tournament.save
                format.html { redirect_to @tournament, notice: "The tournament was created." }
            else
                format.html { render :new }
            end
        end
    end

    # PATCH/PUT /tournaments/1
    def update
        respond_to do |format|
            if @tournament.update(tournament_params)
                format.html { redirect_to @tournament, notice: "The tournament was updated." }
            else
                format.html { render :edit }
            end
        end
    end

    # DELETE /tournaments/1
    def destroy
        @tournament.destroy

        respond_to do |format|
            format.html { redirect_to tournaments_url, notice: "The tournament was deleted." }
        end
    end

    private
    # Use callbacks to share common setup or constraints between actions.
    def set_tournament
        @tournament = Tournament.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def tournament_params
        params.require(:tournament).permit(:description, :challonge_id, :name, :state, :challonge_url, :user_id)
    end
end
