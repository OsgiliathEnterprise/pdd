#!/usr/bin/env sh

get_prompt() {
  echo "Getting the prompt to send from asciidoctor story"
  local src="$1"
  local dst="$2"
  asciidoctor -a allow-uri-read -b html5 -d inline -q -s "$src/**/backlogs/*.adoc" -o -
}

# Returns the prompt
query_gemini_llm() {
  local bruno_path="./engine/bruno/prompt-executor"
  local prompt="$1"
  local key="$2"
  local cwd=$(pwd)/target/prompt
  mkdir "$cwd" || true
  local tmpfile="$cwd"/tmp.json
  rm "$tmpfile" || true
  (cd $bruno_path && bru run getGeminiLLMResponse.bru --output "$tmpfile" --env prod --env-var promptText="$prompt" --env-var apiKey="$key")
  # shellcheck disable=SC2002
  ret_val=$(cat "$tmpfile" | jq '.[0].results.[0].response.data.candidates.[0].content.parts.[0].text')
}

get_inline_prompt() {
  local file="$1"
  ret_val=$(asciidoctor -a allow-uri-read -b html5 -q -e "$file" -o - | tr -s '"' "'" | pandoc --from html --to markdown_strict -o - | tr -s '\n' ' ')
}

iterate_over_backlog() {
  echo "Iterate over backlog file"
  local src="$1"
  local dst="$2"
  for file in "$src"/prompts/contributors/backlogs/*; do
    if [[ -f "$file" ]]; then
      get_inline_prompt "$file"
      apiKey="$GEMINI_KEY"
      prompt=$ret_val
      query_gemini_llm "$prompt" "$apiKey"
      rm "$dst/$file" || true
      mkdir -p $(dirname "$dst/$file")
      echo "$ret_val" > "$dst/$file"
    fi
  done
}
src_dir="./meta"
dst_dir="./target"
iterate_over_backlog "$src_dir" "$dst_dir"

