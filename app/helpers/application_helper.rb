module ApplicationHelper
    def self.get_tournament_list(user)
        # TODO: If the user is in a subdomain, return both the user's own
        #       tournaments and the tournaments owned by the organization.
        #       Currently, we only return the latter.
        url = "https://#{user.user_name}:#{user.api_key}@api.challonge.com/" \
                "v1/tournaments.json"

        url << "?subdomain=#{user.subdomain}" if user.subdomain.present?

        return self.send_get_request(url)
    end

    def self.get_tournament_info(tournament)
        user = tournament.user

        url = "https://#{user.user_name}:#{user.api_key}@api.challonge.com/" \
                "v1/tournaments/#{tournament.challonge_id}.json?" \
                "include_participants=1&include_matches=1"

        return self.send_get_request(url)
    end

    def self.update_match(match, post_data, content_type = "application/x-www-form-urlencoded")
        user = match.tournament.user

        url = "https://#{user.user_name}:#{user.api_key}@api.challonge.com/" \
                "v1/tournaments/#{match.tournament.challonge_id}/matches/" \
                "#{match.challonge_id}.json"

        return self.send_put_request(url, post_data, content_type)
    end

    protected

    # Sends a GET request on `url`, treats the returned data as JSON, and parses
    # it into an object.  The return value is that object.
    def self.send_get_request(url)
        response = RestClient.get(url)
        return JSON.parse(response.body)
    end

    # Sends a PUT request on `url`, passing the given data in the request.  It
    # treats the returned data as JSON, and parses it into an object.  The return
    # value is that object.
    def self.send_put_request(url, post_data, content_type)
        response = RestClient.put(url, post_data, content_type: content_type)
        return JSON.parse(response.body)
    end
end
