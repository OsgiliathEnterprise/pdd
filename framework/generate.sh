#!/usr/bin/env sh

get_prompt() {
  echo "Getting the prompt to send from asciidoctor story"
  local src="$1"
  local dst="$2"
  asciidoctor -a allow-uri-read -b html5 -d inline -q -s "$src/**/backlog/*.adoc" -o -
}
# Set source and destination directories
query_llm() {
  local bruno_path="./engine/bruno/prompt-executor"
  local prompt="$1"
  local key="$2"
  local CWD=$(pwd)/target/prompt
  mkdir "$CWD" || true
  local TMPFILE="$CWD"/tmp.json
  rm "$TMPFILE" || true
  cd $bruno_path && bru run --output "$TMPFILE" --env prod --env-var promptText="$prompt" --env-var apiKey="$key"
  RESULT=$(cat "$TMPFILE" | jq '.[0].results.[0].response.data.candidates.[0].content.parts.[0].text')
}

src_dir="./meta"
dst_dir="./target"
echo "Calling get_prompt with src_dir: $src_dir and dst_dir: $dst_dir"
STORY=$(get_prompt "$src_dir" "$dst_dir" | tr -s '\n' ' ')
API_KEY="$GEMINI_KEY"
query_llm "$STORY" "$API_KEY"
echo "the LLM result call is $RESULT"

