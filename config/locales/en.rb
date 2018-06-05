{
    en: {
        blue_cab_name: "Blue",
        browser_title: "%{title} - Challonge Mgr",
        browser_title_view: "Viewing %{title}",
        cancel_link: "Cancel",
        gold_cab_name: "Gold",
        errors: {
            login_required: "You must log in.",
            page_access_denied: "You cannot access that page.",
            match_not_found: "That match was not found.",
            tournament_not_found: "That tournament was not found.",
            user_not_found: "That user was not found.",
            login_failed: "The user name or password was incorrect.",
            cant_finalize_tournament: "The tournament still has unplayed matches" \
                                        " and cannot be finalized yet."
        },
        notices: {
            user_updated: "The user was updated.",
            tournament_updated: "The tournament was updated.",
            auth_error: "Authentication error. Check that your Challonge user name" \
                          " and API key are correct."
        },
        slack: {
            tbd: "TBD",
            match_starting: "%{tournament_name}: Match #%{match_number} is about to start:" \
                              " %{left_team} vs. %{right_team}.",
            on_deck_match: " The on-deck match is %{first_team} vs. %{second_team}.",
            match_complete: "%{tournament_name}: %{winning_team} defeated" \
                              " %{losing_team} %{winning_score}-%{losing_score}."
        },
        sessions: {
            new: {
                page_title: "Log in",
                account_setup_instructions_html: "Enter the user name and password" \
                  " of your Challonge Mgr account. If you haven't made an account" \
                  " yet, see <a href='%{readme_url}'>the instructions in the readme" \
                  " file</a> on how to set one up.",
                user_name_html: "<u>U</u>ser name",
                user_name_accesskey: "u",
                password_html: "<u>P</u>assword",
                password_accesskey: "p",
                log_in_button: "Log in"
            }
        },
        users: {
            show: {
                user_name: "User name:",
                api_key: "API key:",
                subdomain: "Subdomain:",
                view_tournaments: "View this user's tournaments"
            },
            edit: {
                page_title: "Edit settings for %{user_name}",
                page_header: "Edit settings for %{user_name}"
            },
            form: {
                errors_list_header: {
                    one: "1 error prevented this user from being saved:",
                    other: "%{count} errors prevented this user from being saved:"
                },
                api_key: "API key",
                subdomain: "Subdomain (leave this blank if you don't have one)",
                password: "Password (leave this blank to keep your current password)",
                password_confirmation: "Confirm the new password"
            },
            edit_user: "Edit this user's settings",
            log_out: "Log out"
        },
        tournaments: {
            index: {
                page_title: "Tournament list for %{user_name}",
                page_header: "Challonge tournaments owned by %{user_name}",
                instructions1_html: "This list shows the tournaments that are underway" \
                  " and owned by your user.  Click the <i>Manage this tournament</i>" \
                  " link next to the tournament that you want to manage.",
                instructions2: "If the tournament that you want to manage isn't" \
                  " listed here, check that you have started the" \
                  " tournament on the Challonge web site.  Challonge Mgr can only" \
                  " manage tournaments that have had their teams and seeds set up" \
                  " on the Challonge site.",
                instructions3_html: "If the tournament has been started and isn't" \
                  " listed here, click the <i>Reload the tournament list" \
                  " from Challonge</i> link below the list.",
                name: "Name",
                challonge_url: "Challonge URL",
                state: "State",
                actions: "Actions",
                manage_tournament: "Manage this tournament",
                reload_tournaments: "Reload the tournament list from Challonge",
            },
            show: {
                upcoming_matches: "Upcoming matches:",
                completed_matches: "Completed matches:",
                team_records: "Team records:",
                finalize_tournament: "Finalize the tournament:",
                finalize_text_html: "All the matches in the tournament have been played." \
                  " Click <i>Finalize the tournament</i> to complete the tournament" \
                  " and show the final standings. Once you finalize the tournament," \
                  " no more changes can be made to it.",
                finalize_tournament_button: "Finalize the tournament",
                final_standings: "Final standings:",
                place: "Place",
                seed: "Seed",
                name: "Team",
                record: "Team (W-L)",
                team_record: "%{name} (%{wins} - %{losses})",
                reload: "Reload this tournament from Challonge",
                tournament_list: "Back to the tournament list"
            },
            edit: {
                page_title: "Edit settings for %{name}",
                page_header: "Edit settings for %{name}"
            },
            form: {
                errors_list_header: {
                    one: "1 error prevented this tournament from being saved:",
                    other: "%{count} errors prevented this tournament from being saved:"
                },
                gold_on_left: "The Gold cabinet is on the left side",
                send_slack_notifications: "Send Slack notifications when matches begin and end",
                slack_notifications_channel: "Slack channel"
            },
            current_match: {
                header: "Current match: #%{number} in %{round_name}",
                add_a_win: "Add 1 win",
                subtract_a_win: "Subtract 1 win",
                this_team_won: "This team won",
                switch_sides: "Switch sides",
            },
            match_list: {
                match_number: "Match #",
                round: "Round",
                teams: "Teams",
                actions: "Actions",
                winner_of_match: "Winner of match %{number}",
                loser_of_match: "Loser of match %{number}",
                forfeited: "(forfeited)",
                switch_sides: "Switch sides",
                start_this_match: "Start this match"
            },
            previous_matches: {
                header: "Previous matches:",
                none: "None",
                match_won: "Defeated %{loser} %{winning_score} - %{losing_score}",
                match_won_forfeited: "Defeated %{loser} by forfeit",
                match_lost: "Lost to %{winner} %{winning_score} - %{losing_score}",
                match_lost_forfeited: "Lost to %{winner} by forfeit"
            },
            edit_tournament: "Edit this tournament's settings"
        },
        matches: {
            round_names: {
                winners_round: "winners' round %{round}",
                winners_round_cap: "Winners' round %{round}",
                losers_round: "losers' round %{round}",
                losers_round_cap: "Losers' round %{round}",
                round_with_group_cap: "Group %{group}, round %{round}",
                round_with_group: "group %{group}, round %{round}",
                round: "round %{round}",
                round_cap: "Round %{round}"
            }
        }
    }
}
