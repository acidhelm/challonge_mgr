# If you get an error about scripts being disabled, run:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted
# That will let scripts run for that PowerShell session only.
# You can also use `-Scope CurrentUser` to make the change permanent,
# but that has security implications, because _all_ scripts can run,
# including malicious ones.

# TODO: Change this to your server's URL.  Include the port if it's different
#       than the default.
$server = "http://YOUR-SERVER-NAME.example.com"

# TODO: Change this to your tournament's name.  This is the part of your
#       tournament's URL after "challonge.com/".
$tournament = "YOUR-TOURNAMENT-NAME"

$desktop = [Environment]::GetFolderPath("desktop")
$view_url = "$server/view/$tournament"
$gold_name_url = "$view_url/gold"
$blue_name_url = "$view_url/blue"
$gold_score_url = "$view_url/gold_score"
$blue_score_url = "$view_url/blue_score"
$on_deck_gold_name_url = "$view_url/on_deck_gold"
$on_deck_blue_name_url = "$view_url/on_deck_blue"
$gold_name_file = Join-Path $desktop "gold.txt"
$blue_name_file = Join-Path $desktop "blue.txt"
$gold_score_file = Join-Path $desktop "gold_score.txt"
$blue_score_file = Join-Path $desktop "blue_score.txt"
$on_deck_gold_name_file = Join-Path $desktop "on_deck_gold.txt"
$on_deck_blue_name_file = Join-Path $desktop "on_deck_blue.txt"

if ( ( $server -cmatch "YOUR-" ) -or ( $tournament -cmatch "YOUR-" ) )
{
    "Before you can use this script, you must edit it and set `$server and `$tournament"
    "to match your setup.  See the TODO comments at the top of the file."
    exit
}

"Downloading team names from $view_url. Press Ctrl+C to stop."

while (1)
{
    Invoke-WebRequest $gold_name_url -OutFile $gold_name_file
    Invoke-WebRequest $blue_name_url -OutFile $blue_name_file
    Invoke-WebRequest $gold_score_url -OutFile $gold_score_file
    Invoke-WebRequest $blue_score_url -OutFile $blue_score_file
    Invoke-WebRequest $on_deck_gold_name_url -OutFile $on_deck_gold_name_file
    Invoke-WebRequest $on_deck_blue_name_url -OutFile $on_deck_blue_name_file
    sleep 5
}
