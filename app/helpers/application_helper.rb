# frozen_string_literal: true

module ApplicationHelper
    class << self
    # On success, returns an array of `tournament` objects that represent the
    # tournaments that are owned by the user.  If the user is in an organization,
    # the array also contains the tournaments that are owned by that organization.
    # On failure, returns an `error` object that describes the error.
    def get_tournament_list(user)
        url = get_api_url("tournaments.json")
        tournaments = send_get_request(url, user)

        # The API returns a different response if the tournament list is empty.
        # It returns `{"tournaments":[]}`, so we need to handle that specially.
        if tournaments.is_a?(Hash) && tournaments["tournaments"] == []
            tournaments = []
        end

        # If an error occured, `send_get_request` will return a hash instead of
        # an array.
        return tournaments unless tournaments.is_a?(Array)

        if user.subdomain.present?
            org_tournaments = send_get_request(url, user, subdomain: user.subdomain)

            tournaments.concat(org_tournaments) if org_tournaments.is_a?(Array)
        end

        return tournaments
    end

    # On success, returns a `tournament` object that contains the properties of
    # the given tournament. The caller can also request the teams and matches in
    # the tournament.
    # On failure, returns an `error` object that describes the error.
    def get_tournament_info(tournament, get_teams: true, get_matches: true)
        url = get_api_url("tournaments/#{tournament.challonge_id}.json")
        params = { include_participants: get_teams ? 1 : 0,
                   include_matches: get_matches ? 1 : 0 }

        return send_get_request(url, tournament.user, params)
    end

    # Sets the scores and optionally the winning team for a match.
    # On success, returns a `match` object that contains the updated properties
    # of the match.
    # On failure, returns an `error` object that describes the error.
    def update_match(match, new_scores_csv, winner_id)
        url = get_api_url("tournaments/#{match.tournament.challonge_id}/matches/" \
                            "#{match.challonge_id}.json")

        params = { "match[scores_csv]" => new_scores_csv }
        params["match[winner_id]"] = winner_id if winner_id.present?

        return send_put_request(url, match.tournament.user, params)
    end

    # Sets the scores and optionally the winning team for a match.
    # On success, returns... something.  The API's response isn't documented.
    # TODO: Finalize a test match and see what it returns.
    # On failure, returns an `error` object that describes the error.
    def finalize_tournament(tournament)
        url = get_api_url("tournaments/#{tournament.challonge_id}/finalize.json")

        return send_post_request(url, tournament.user)
    end

    # Checks that `param` is one of the elements in `legal_values`, and if not,
    # throws an `ArgumentError`.
    # If a more-complex test is required, the caller can pass a block.  An
    # exception will be thrown if the block returns false.  When the caller
    # passes a block, `legal_values` is not used.
    def validate_param(param, legal_values = nil)
        if block_given?
            raise ArgumentError, "Invalid parameter: #{param}" unless yield param
        else
            raise ArgumentError,
                  "Invalid parameter: #{param}. " \
                    "Legal values are: #{legal_values}" unless legal_values.include?(param)
        end
    end

    protected

    # Returns a string that holds the URL to the Challonge API endpoint, with
    # `str` appended to it.
    def get_api_url(str)
        return "https://api.challonge.com/v1/#{str}"
    end

    # Sends a GET request to `url`, treats the returned data as JSON, and parses
    # it into an object.  On success, the return value is that object.  On
    # failure, the return value is a hash that describes the error.
    def send_get_request(url, user, params = {})
        params = params.reverse_merge(api_key: user.api_key)
        response = RestClient.get(url, params: params)
        return JSON.parse(response.body)
    rescue => e
        return handle_request_error(e, __method__)
    end

    # Sends a PUT request to `url`, passing `params` with the request.  It treats
    # the returned data as JSON, and parses it into an object.  On success,
    # the return value is that object.  On failure, the return value is a hash
    # that describes the error.
    def send_put_request(url, user, params)
        params = params.reverse_merge(api_key: user.api_key)
        response = RestClient.put(url, params)
        return JSON.parse(response.body)
    rescue => e
        return handle_request_error(e, __method__)
    end

    # Sends a POST request to `url`.  It treats the returned data as JSON, and
    # parses it into an object.  On success, the return value is that object.
    # On failure, the return value is a hash that describes the error.
    def send_post_request(url, user, params = {})
        params = params.reverse_merge(api_key: user.api_key)
        post_data = URI.encode_www_form(params)
        response = RestClient.post(url, post_data)
        return JSON.parse(response.body)
    rescue => e
        return handle_request_error(e, __method__)
    end

    # Returns a hash in this form:
    # { error: { object: <the exception>,
    #            message: <error messages, separated by semicolons>,
    #            http_code: <the HTTP response code, if it's known>
    # } }
    def handle_request_error(exception, method_name)
        Rails.logger.error "Exception (#{exception.class.name}) in " \
                             "#{method_name}: #{exception.message}"
        message = nil

        # When an API call fails, Challonge returns a list of errors in the body.
        # Look for that list in the response.
        if exception.is_a?(RestClient::ExceptionWithResponse)
            Rails.logger.error "Response body: #{exception.response}"

            # Swallow exceptions if the response isn't JSON.  This happens when
            # the user name or API key is wrong, because the server returns
            # just the string "HTTP Basic: Access denied."
            # This isn't a problem, because `ApplicationController#api_failed?`
            # special-cases 401 responses and shows a custom error message.
            begin
                resp = JSON.parse(exception.response.to_s)
            rescue JSON::ParserError
                resp = nil
            end

            if resp.is_a?(Hash) && resp.key?("errors")
                message = [ exception.message, resp["errors"] ].join("; ")
            end
        end

        message ||= exception.message

        err = { object: exception, message: message }
        err[:http_code] = exception.http_code if exception.respond_to?(:http_code)

        return { error: err }
    end
    end # class << self
end
