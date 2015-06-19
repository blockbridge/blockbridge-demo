for CID in $(docker ps -a -q --filter "name=bbsim-sn")
do
    echo "Starting storage node: $(docker start $CID)"
done
