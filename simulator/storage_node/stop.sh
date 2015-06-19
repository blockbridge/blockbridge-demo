for CID in $(docker ps -q --filter "name=bbsim-sn")
do
    echo "Stopping storage node $(docker stop $CID)"
done
