# frozen_string_literal: true

module ApplicationHelper
    # On success, returns an array of `tournament` objects that represent the
    # tournaments that are owned by the user.  If the user is in an organization,
    # the array also contains the tournaments that are owned by that organization.
    # On failure, returns an `error` object that describes the error.
    def self.get_tournament_list(user)
        url = "#{api_url_prefix(user)}tournaments.json"

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
        url = "#{api_url_prefix(tournament.user)}tournaments/" \
                "#{tournament.challonge_id}.json?" \
                "include_participants=1&include_matches=1"

        return send_get_request(url)
    end

    def self.update_match(match, new_scores_csv, winner_id)
        url = "#{api_url_prefix(match.tournament.user)}tournaments/" \
                "#{match.tournament.challonge_id}/matches/#{match.challonge_id}.json"

        params = { "match[scores_csv]" => new_scores_csv }
        params["match[winner_id]"] = winner_id if winner_id.present?

        return send_put_request(url, params)
    end

    def self.finalize_tournament(tournament)
        url = "#{api_url_prefix(tournament.user)}tournaments/" \
                "#{tournament.challonge_id}/finalize.json"

        return send_post_request(url)
    end

    protected

    def self.api_url_prefix(user)
        return "https://#{user.user_name}:#{user.api_key}@api.challonge.com/v1/"
    end

    # Sends a GET request on `url`, treats the returned data as JSON, and parses
    # it into an object.  On success, the return value is that object.  On
    # failure, the return value is a hash that describes the error.
    def self.send_get_request(url)
        response = RestClient.get(url)
        return JSON.parse(response.body)
    rescue => e
        return handle_request_error(e, __method__)
    end

    # Sends a PUT request on `url`, passing `params` with the request.  It treats
    # the returned data as JSON, and parses it into an object.  On success,
    # the return value is that object.  On failure, the return value is a hash
    # that describes the error.
    def self.send_put_request(url, params)
        response = RestClient.put(url, params)
        return JSON.parse(response.body)
    rescue => e
        return handle_request_error(e, __method__)
    end

    # Sends a POST request on `url`.  It treats the returned data as JSON, and
    # parses it into an object.  On success, the return value is that object.
    # On failure, the return value is a hash that describes the error.
    def self.send_post_request(url, post_data = "")
        response = RestClient.post(url, post_data)
        return JSON.parse(response.body)
    rescue => e
        return handle_request_error(e, __method__)
    end

    def self.handle_request_error(e, method_name)
        Rails.logger.error "Exception (#{e.class.name}) in #{method_name}: #{e.message}"
        message = nil

        # When an API call fails, Challonge returns a list of errors in the body.
        # Look for that list in the response.
        if e.is_a?(RestClient::ExceptionWithResponse)
            Rails.logger.error "Response body: #{e.response}"

            # Swallow exceptions if the response isn't JSON.  This happens when
            # the user name or API key is wrong, because the server returns
            # "HTTP Basic: Access denied."
            # This isn't a problem, because `ApplicationController#api_failed?`
            # special-cases 401 responses and shows a custom error message.
            resp = JSON.parse(e.response.to_s) rescue JSON::ParserError;

            if resp.is_a?(Hash) && resp.key?("errors")
                message = [ e.message, resp["errors"] ].join("; ")
            end
        end

        message ||= e.message

        err = { object: e, message: message }
        err[:http_code] = e.http_code if e.respond_to?(:http_code)

        return { error: err }
    end
end
