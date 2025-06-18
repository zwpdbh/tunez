drop_tables: 
	mix ecto.drop && MIX_ENV=test mix ecto.drop

run_app:
	iex -S mix phx.server

run_db:
	docker-compose -f docker-compose.dev.yml up -d