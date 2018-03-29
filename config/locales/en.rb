{
    en: {
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
                instructions1: "This list shows the tournaments that are underway" \
                  " and owned by your user.  If the tournament that you want to" \
                  " manage doesn't appear here, check that you have started the" \
                  " tournament on the Challonge web site.  Challonge Mgr can only" \
                  " manage tournaments that have had their teams and seeds set up" \
                  " on the Challonge site.",
                instructions2_html: "If the tournament has been started and doesn't" \
                  " appear in this list, click the <i>Reload the tournament list" \
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
                seed: "Seed",
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
            },
            match_list: {
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
        cancel_link: "Cancel"
    }
}
