# frozen_string_literal: true

module ApplicationHelper
    # On success, returns an array of `tournament` objects that represent the
    # tournaments that are owned by the user.  If the user is in an organization,
    # the array also contains the tournaments that are owned by that organization.
    # On failure, returns an `error` object that describes the error.
    def self.get_tournament_list(user)
        url = "https://#{user.user_name}:#{user.api_key}@api.challonge.com/" \
                "v1/tournaments.json"

        tournaments = send_get_request(url)

        # The API returns a different response if the tournament list is empty.
        # It returns `{"tournaments":[]}`, so we need to handle that specially.
        if tournaments.is_a?(Hash) && tournaments["tournaments"] == []
            tournaments = []
        end

        # If an error occured, `send_get_request` will return a hash instead of
        # an array.
        return tournaments unless tournaments.is_a?(Array)

        if user.subdomain.present?
            url += "?subdomain=#{user.subdomain}"

            org_tournaments = send_get_request(url)

            tournaments.concat(org_tournaments) if org_tournaments.is_a?(Array)
        end

        return tournaments
    end

    def self.get_tournament_info(tournament)
        user = tournament.user

        url = "https://#{user.user_name}:#{user.api_key}@api.challonge.com/" \
                "v1/tournaments/#{tournament.challonge_id}.json?" \
                "include_participants=1&include_matches=1"

        return send_get_request(url)
    end

    def self.update_match(match, post_data, content_type = "application/x-www-form-urlencoded")
        user = match.tournament.user

        url = "https://#{user.user_name}:#{user.api_key}@api.challonge.com/" \
                "v1/tournaments/#{match.tournament.challonge_id}/matches/" \
                "#{match.challonge_id}.json"

        return send_put_request(url, post_data, content_type)
    end

    protected

    # Sends a GET request on `url`, treats the returned data as JSON, and parses
    # it into an object.  On success, the return value is that object.  On
    # failure, the return value is a hash that describes the error.
    def self.send_get_request(url)
        response = RestClient.get(url)
        return JSON.parse(response.body)
    rescue => e
        return handle_request_error(e, "send_get_request")
    end

    # Sends a PUT request on `url`, passing the given data in the request.  It
    # treats the returned data as JSON, and parses it into an object.  On success,
    # the return value is that object.  On failure, the return value is a hash
    # that describes the error.
    def self.send_put_request(url, post_data, content_type)
        response = RestClient.put(url, post_data, content_type: content_type)
        return JSON.parse(response.body)
    rescue => e
        return handle_request_error(e, "send_put_request")
    end

    def self.handle_request_error(e, method_name)
        Rails.logger.error "Exception (#{e.class.name}) in #{method_name}: #{e.message}"

        err = { error: { object: e, message: e.message } }
        err[:error][:http_code] = e.http_code if e.respond_to?(:http_code)

        return err
    end
end
