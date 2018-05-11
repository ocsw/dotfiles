_errorcode_prompt () {
  # first copy the status array in case we do something that changes it as we
  # go along
  local pipestatus_num=("${PIPESTATUS[@]}")

  local stat_num signame pipestatus_sig
  # without this, and with local, the array gets a null element 0;
  # order doesn't matter
  typeset -a pipestatus_sig

  for stat_num in "${pipestatus_num[@]}"; do
    if [[ "$stat_num" -gt 128 ]]; then
      signame=$(builtin kill -l $(($stat_num - 128)) 2>/dev/null)
      signame="${signame:3}"
      pipestatus_sig=("${pipestatus_sig[@]}" "$stat_num ($signame)")
    else
      # this would be better but less backwards-compatible:
      # pipestatus_sig+=("$stat_num")
      # see https://stackoverflow.com/questions/1951506/add-a-new-element-to-an-array-without-specifying-the-index-in-bash
      pipestatus_sig=("${pipestatus_sig[@]}" "$stat_num")
    fi
  done

  printf "%s" "${pipestatus_sig[*]}"
}
