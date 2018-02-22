class Team < ApplicationRecord
    belongs_to :tournament

    serialize :group_team_ids, Array

    # FIXME: The uniqueness constraint should be scoped to just the ID of the
    #        user that's accessing the records.
    validates :challonge_id, numericality: { only_integer: true, greater_than: 0 } # , uniqueness: true
    validates :name, presence: true
    validates :seed, numericality: { only_integer: true, greater_than: 0 }

    scope :from_id, ->(id) { select { |team| team.all_challonge_ids.include?(id) } }

    def update!(obj)
        self.name = obj.name
        self.seed = obj.seed
        self.group_team_ids = obj.group_player_ids
    end

    def all_challonge_ids
        return [ challonge_id, group_team_ids ].flatten
    end
end
