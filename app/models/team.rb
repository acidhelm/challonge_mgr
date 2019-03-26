# frozen_string_literal: true

class Team < ApplicationRecord
    belongs_to :tournament

    serialize :group_team_ids, Array

    validates :challonge_id, numericality: { only_integer: true, greater_than: 0 }
    validates :name, presence: true
    validates :seed, numericality: { only_integer: true, greater_than: 0 }
    validates :final_rank, numericality: { only_integer: true, greater_than: 0 },
                           allow_nil: true
    validate :validate_challonge_id_uniqueness
    validate :validate_group_team_ids, if: proc { |t| t.group_team_ids.present? }

    scope :from_id, ->(id) { select { |team| team.all_challonge_ids.include?(id) } }

    def update!(obj)
        # If a team has a Challonge account, its `name` field may be null or an
        # empty string.  When that's the case, use `display_name` instead.
        self.name = obj.name.presence || obj.display_name
        self.seed = obj.seed
        self.final_rank = obj.final_rank
        self.group_team_ids = obj.group_player_ids
        save!
    end

    def set_alt_name(alt_name)
        return update(alt_name: alt_name)
    end

    def all_challonge_ids
        return [ challonge_id, group_team_ids ].flatten
    end

    protected

    # This method checks that there are no other Teams in this Tournament with
    # this Team's `challonge_id`.  We can't use the built-in `uniqueness`
    # validator, because the same tournament might be in the database under
    # multiple users, and that would make the `uniqueness` validator fail.
    #
    # There `where.not(id: id)` check is necessary so that we don't find our
    # own `challonge_id` when an existing Team is being updated.
    def validate_challonge_id_uniqueness
        if tournament.teams.where.not(id: id).where(challonge_id: challonge_id).any?
            errors.add(:challonge_id, "is not unique")
        end
    end

    # Validates that the elements in `group_team_ids` are positive integers.
    def validate_group_team_ids
        unless group_team_ids.map { |n| n.is_a?(Integer) && n > 0 }.all?
            errors.add(:group_team_ids, "is not an array of positive Integers")
        end
    end
end
