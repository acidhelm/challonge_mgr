# frozen_string_literal: true

class Team < ApplicationRecord
    belongs_to :tournament

    serialize :group_team_ids, Array

    # FIXME: The uniqueness constraint should be scoped to just the ID of the
    #        user that's accessing the records.
    validates :challonge_id, numericality: { only_integer: true, greater_than: 0 } # , uniqueness: true
    validates :name, presence: true
    validates :seed, numericality: { only_integer: true, greater_than: 0 }
    validates :final_rank, numericality: { only_integer: true, greater_than: 0 },
                           allow_nil: true

    scope :from_id, ->(id) { select { |team| team.all_challonge_ids.include?(id) } }

    def update!(obj)
        # If a team has a Challonge account, its `name` field may be null or an
        # empty string.  When that's the case, use `display_name` instead.
        self.name = obj.name.present? ? obj.name : obj.display_name
        self.seed = obj.seed
        self.final_rank = obj.final_rank
        self.group_team_ids = obj.group_player_ids
        save!
    end

    def all_challonge_ids
        return [ challonge_id, group_team_ids ].flatten
    end
end
