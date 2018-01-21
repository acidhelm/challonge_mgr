# Challonge Mgr

Challonge Mgr is a Rails 5 app that uses the Challonge API to update your
tournament's bracket.  While you can update your bracket on Challonge
directly, the UI can be a bit fiddly, some controls are small, and common
tasks take several clicks.  My experience has been that unless there is a
person dedicated to maintaining the bracket, the bracket tends to be forgotten
about, which creates a worse viewing experience for folks who want to
follow the progress of the tournament.

My goal with Challonge Mgr is to make it super easy to update your bracket.  The
actions that you need to do -- starting a match, updating the score, and ending
a match -- can all be done with one click.  Challonge Mgr also shows other info,
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

Then run the Rails server:

```sh
$ bin/rails server
```

Open [the main page](http://localhost:3000/products/ui) in a browser, and you
should see an empty user list.

## Add your Challonge account

Click _Add a user_.  Enter your Challonge user name and your API key.  You can
find the API key in [your account settings](https://challonge.com/settings/developer).
Note that Challonge Mgr currently has **no security** regarding access to this
key, so you should only run it on a local computer that you control.  It should
work if you deploy it to a cloud service like Heroku, but your only security will
be obscurity.

# Create and manage a tournament

[Create your tournament](http://challonge.com/tournaments/new) on the Challonge
web site.   Be sure to click the "Start the tournament" button on your
tournament's Bracket settings page.

Back in the browser, click _Manage this user's tournaments_ next to your
Challonge user.  You'll see a list of the tournaments that are in progress and
owned by your Challonge account.  Click _Manage this tournament_ next to the
tournament that you are running.

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

Note that this feature is currently of limited usefulness, because it requires
giving spectators access to your Rails database.  If someone knows or guesses the
URL scheme, they can mess with anything in your Challonge account.  However, this
view is useful for broadcasters, since it gives them an easy-to-read list of the
upcoming matches.

If you use Xsplit for broadcasting, Challonge Mgr can automatically update the
team names in your video.  The `/view/<tournament_id>/gold` and
`/view/<tournament_id>/blue` URLs return the name of the team that is
currently on that cabinet, or an empty string if no match is in progress.
You can make your text labels get their text from those URLs, and the names
will be updated when you start each match.

# Known problems

There is **no security** around account data.  I plan to add a login system to
fix this.  I'm still learning Rails, so that's why I didn't do this right from
the beginning.

When you start a match, the bracket on Challonge does not indicate that the
match is in progress.  The Challonge API does not provide a way to mark a match
as being in progress, so I cannot fix this problem.  You will need to manually
mark matches as being in progress for now.  You should add a comment to
[this feedback page](http://feedback.challonge.com/forums/44455-feature-requests/suggestions/11251128-api-support-to-mark-an-match-in-progress)
if you would like this to be fixed.