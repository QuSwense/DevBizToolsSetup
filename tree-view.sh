tree -if --dirsfirst --noreport | while IFS= read -r file; do
    [[ -e "$file" ]] || continue
    if ! git check-ignore -q "$file"; then
        echo "$file"
    fi
done > complete-files.txt
