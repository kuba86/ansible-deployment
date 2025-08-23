#! /usr/bin/env fish

argparse 'title=' 'tags=' 'topic=' 'server_url=' 'apikey=' 'priority=' 'message=' -- $argv
or return

if not set -ql _flag_title; \
or not set -ql _flag_tags; \
or not set -ql _flag_topic; \
or not set -ql _flag_server_url; \
or not set -ql _flag_apikey
    echo "'title', 'tags', 'topic', 'server_url', 'apikey' are required."
    echo "'priority', 'message' are optional"
    return 1
end

set -l encoded_auth_token (echo -n :"$_flag_apikey" | base64)

if not set -ql _flag_priority
    set -l _flag_priority "default"
end

if not set -ql _flag_message
    set -l _flag_message ""
end

curl \
  --retry 5 \
  --connect-timeout 5 \
  --max-time 5 \
  --retry-delay 5 \
  --retry-all-errors \
  --fail \
  -H "Authorization: Basic $encoded_auth_token" \
  -H "Title: $_flag_title" \
  -H "Tags: $_flag_tags" \
  -H "Priority: $_flag_priority" \
  -d "$_flag_message" \
  "$_flag_server_url$_flag_topic"
