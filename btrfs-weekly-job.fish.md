# checks

dysk --json | jq -r '.[] | select(.["fs-type"] == "btrfs") | .["mount-point"]'

wrap-with-dashes "disk.info"
disk.info

wrap-with-dashes "sudo btrfs filesystem show"
sudo btrfs filesystem show

wrap-with-dashes "sudo btrfs filesystem usage /var"
sudo btrfs filesystem usage /var

wrap-with-dashes "sudo btrfs filesystem df /var"
sudo btrfs filesystem df /var

wrap-with-dashes "sudo compsize -x /var"
sudo compsize -x /var

# work

wrap-with-dashes "sudo btrfs filesystem defrag -czstd -L3 -r /var"
sudo btrfs filesystem defrag -czstd -L3 -r /var

wrap-with-dashes "sudo btrfs balance start -dusage=80 -dlimit=10 -musage=80 -mlimit=10 /var"
sudo btrfs balance start -dusage=80 -dlimit=10 -musage=80 -mlimit=10 /var

wrap-with-dashes "sudo btrfs scrub start -B -r /var"
sudo btrfs scrub start -B -r /var
