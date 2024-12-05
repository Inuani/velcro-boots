include .env

# Access routes in a local replica
# canisterId.localhost:4943/whatever_route
# http://bw4dl-smaaa-aaaaa-qaacq-cai.localhost:4943/hi

#icx-asset --replica http://127.0.0.1:4943 --pem ~/.config/dfx/identity/raygen/identity.pem upload $(CANISTER_ID_VELCRO_BOOT) /index.html=src/frontend/public/index.html

# npx repomix --ignore ".mops/,.dfx/,.vscode,node_module/,.gitignore,src/frontend/public/bundle.js,src/frontend/public/edge.html"   

# dfx canister call --ic velcro_boot invalidate_cache

# dfx canister --ic deposit-cycles 1000000000000 velcro_boot

REPLICA_URL := $(if $(filter ic,$(subst ',,$(DFX_NETWORK))),https://ic0.app,http://127.0.0.1:4943)

all:
	dfx deploy velcro_boot
	dfx canister call velcro_boot invalidate_cache
	
ic:
	dfx deploy --ic
	dfx canister call --ic $(CANISTER_ID_VELCRO_BOOT) invalidate_cache

upload_assets:
	npm run build
	icx-asset --replica $(REPLICA_URL) --pem ~/.config/dfx/identity/raygen/identity.pem sync $(CANISTER_ID_VELCRO_BOOT) src/frontend/public
	dfx canister call velcro_boot invalidate_cache

gen_cmacs:
	python3 scripts/hashed_cmacs.py -k 00000000000000000000000000000000 -u 044354E2E51090 -c 2000 -d src/backend/hashed_cmacs.mo
