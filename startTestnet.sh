cd chain
rm -R geth
mkdir geth
cd ..
cp nodekey chain/geth/nodekey

geth --datadir ./chain init genesis.json

ethereumwallet  --rpc http://127.0.0.1:8545  &

geth --datadir "./chain/"  --rpc --rpcport "8545" --rpccorsdomain "*" --rpcapi "db,eth,net,web3,personal,miner,admin" -ws --wsorigins "*" --wsapi "db,eth,net,web3,personal,miner,admin"  --identity "HelloEthereum" --mine --minerthreads=1 --etherbase=0x4541216a71802b27c585059be7f36aceee3cc3e7 --networkid 15 

