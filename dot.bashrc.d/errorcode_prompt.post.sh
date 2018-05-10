_errorcode_prompt () {
  # without this, and with local, there's an extra space in the output;
  # evidently some interaction between local and implicit arrays
  #typeset -a PIPESTATUS_SIG
  #local i signame PIPESTATUS_SIG
  for i in "${PIPESTATUS[@]}"; do
    if [[ "$i" -gt 128 ]]; then
      signame=$(builtin kill -l $(($i - 128)) 2>/dev/null)
      signame="${signame:3}"
      PIPESTATUS_SIG[${#PIPESTATUS_SIG[*]}]="$i ($signame)"
    else
      PIPESTATUS_SIG[${#PIPESTATUS_SIG[*]}]="$i"
    fi
  done
  printf "%s" "${PIPESTATUS_SIG[*]}"
}
