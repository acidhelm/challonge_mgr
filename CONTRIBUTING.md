# Talk to us on Slack

If you are in the [KQ Slack team](https://kqchat.slack.com), join the
`streaming_dev` channel.

# Running the unit tests

If you are doing development on Challonge Mgr, you should run the unit tests
after making significant changes.  The system tests access your Challonge
account to test with live data, so you need to tell the tests your account
name and API key.  The tests only do read operations; no data in your account
will be changed.

Add these lines to your `.env` file before running the tests:

```
CHALLONGE_MGR_TEST_USER_NAME=your_user_name
CHALLONGE_MGR_TEST_USER_API_KEY=your_api_key
CHALLONGE_MGR_TEST_USER_SUBDOMAIN=your_subdomain
```

Setting `CHALLONGE_MGR_TEST_USER_SUBDOMAIN` is optional.

To run the tests, run these commands in the `challonge_mgr` directory:

```sh
$ bin/rails test
$ bin/rails test:system
```
