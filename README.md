# Challonge Mgr

Challonge Mgr is a Rails 5 app that uses the Challonge API to update your
tournament's bracket.  While you can update your bracket on Challonge
directly, the UI can be a bit fiddly, some controls are small, and common
tasks take several clicks.  My experience has been that unless there is a
person dedicated to maintaining the bracket, the bracket tends to be forgotten
about, which creates a worse viewing experience for folks who want to
follow the progress of the tournament.

My goal with Challonge Mgr is to make it super easy to update your bracket.  The
actions that you need to do -- start a match, update the score, and end a
match -- can all be done with one click.  Challonge Mgr also shows other info,
like the order of upcoming matches, that can be useful for your commentators.

Challonge Mgr can also send notifications to a Slack channel.  That lets viewers
see the results of matches right away, and players can monitor the channel to see
when their match is coming up.

# Getting started

To set up Challonge Mgr, clone the repo and set up gems and the initial database:

```sh
$ git clone git@github.com:acidhelm/challonge_mgr.git
$ cd challonge_mgr
$ bundle install --path vendor/bundle
$ bin/rails db:create db:migrate
```

There are two configuration keys that you will need to set, but you'll only have
to do this once.  In the `challonge_mgr` directory, run:

```sh
$ ruby -e 'require "securerandom"; puts "ATTR_ENCRYPTED_KEY=#{SecureRandom.hex 16}"' > .env
```

That creates an encryption key that only works on your computer.  You should not
move that file to any other computer; generate a new one if you need to.

The other key is for the Slack API.  If you don't plan on sending tournament
updates to Slack, you can skip this step.

Open the `.env` file in a text editor, and add this line:

```
SLACK_TOKEN=[the API token]
```

Use a key from Slackbot in [the team's custom integrations
page](https://kqchat.slack.com/apps/manage/custom-integrations).  The token is
the string after "token=" in the URL.


Then run the Rails server:

```sh
$ bin/rails server
```

## Add your Challonge account

Challonge Mgr accounts are used to hold your Challonge login information.  You
will need your Challonge API key, which you can find in
[your account settings](https://challonge.com/settings/developer).

There is no UI for creating accounts, but you can make an account in the Rails
console.  Run the console:

```sh
$ bin/rails console
```

Then run this command to make an account:

```ruby
> User.create user_name: "Your Challonge user name",
              api_key: "Your API key",
              password: "A password"
```

The password that you set here will be used to log in to Challonge Mgr.  It does
not have to be the same as your Challonge password.
              
## Log in

Open [the login page](http://localhost:3000/login) in a browser and enter the
user name and password that you just set.  After logging in, you will see your
list of tournaments.

# Create and manage a tournament

[Create your tournament](http://challonge.com/tournaments/new) on the Challonge
web site, then set up the teams and the bracket.  Be sure to click the "Start the
tournament" button on your tournament's Bracket settings page.

Back in the browser, click _Reload the tournament list from Challonge_ if your
new tournament isn't already in the tournament list.  Click _Manage this tournament_
next to the tournament that you are running.

## Update matches

When a match is about to start, click the _Start this match_ link next to it.
Challonge Mgr will show this match in the "Current match" section of the page.
As each team wins a game, click the _Add 1 win_ button under that team's name.
If you mistakenly add a win for the wrong team, click the _Subtract 1 win_
button to correct the score.  Click the _Switch sides_ button if the cabinets
that the teams are on is opposite of the order in which they are shown on the page.

When a match is complete, click the _This team won_ button under the winning
team's name.  The page will refresh and show the match in the "Completed
matches" section.

## Tournament settings

You can change the order of the cabinets and configure Slack notifications
by clicking the _Edit this tournament's settings_ link at the bottom of the
match listing.

The order of the cabinets is set by the _The Gold cabinet is on the left side_
check box.  You can set the default value for this option by changing the
value of `config.gold_on_left_default` in the `config/applcation.rb` file.
If you set that value to match your cabinets, then you shouldn't have to toggle
this check box.

If you turn on Slack notifications and enter a channel name, Challonge Mgr will
post a message to the channel when a match begins and ends.  The notification
that's sent at the start of a match also says which teams are up next.  You
can tell your players to watch the channel to help them know when their turn
is coming up.

# Features for spectators and streamers

Challonge Mgr also provides a read-only view of the match list.  Spectators
can go to `/view/<tournament_id>` to see the list.  For example,
`/view/elboniakq1` shows the progress of
[the "elboniakq1" tournament](http://challonge.com/elboniakq1).

This view is also useful for your commentators, since it gives them an easy-to-read
list of the upcoming matches, and the match history of the teams that are in the
current match.

If you use Xsplit for broadcasting, Challonge Mgr can automatically update the
team names in your video.  The `/view/<tournament_id>/gold` and
`/view/<tournament_id>/blue` URLs return the name of the team that is
currently on that cabinet, or an empty string if no match is in progress.
You can make your text labels get their text from those URLs, and the names
will be updated when you start each match.

Similarly, each team's score can be retrieved from the
`/view/<tournament_id>/gold_score` and `/view/<tournament_id>/blue_score` URLs.
Those actions return 0 if no match is in progress.

# Known problems

When you start a match, the bracket on Challonge does not indicate that the
match is in progress.  The Challonge API does not provide a way to mark a match
as being in progress, so I cannot fix this problem.  You will need to manually
mark matches as being in progress for now.  You should add a comment to
[this feedback page](http://feedback.challonge.com/forums/44455-feature-requests/suggestions/11251128-api-support-to-mark-an-match-in-progress)
if you would like this to be fixed.
