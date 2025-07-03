# Anoma

This is the backend implementation of the Anoma testnet application.



## 🪙 Coinbase

This application makes use of Coinbase's websocket to get the latest BTC price
information. When running in `dev` it uses the sandbox endpoint, so no
credentials are required.
If you run in `prod` mode, these credentials are required.

The credentials are read from `COINBASE_API_KEY` and `COINBASE_SECRET`
environment variables.

## 💾 Run from source

Start a Docker database for this repository.

```shell
docker compose --file scripts/docker-compose.yml up -d db
```

Run the application and open the webpage.

```shell
# fetch the dependencies
mix deps.get
# create the database (this will nuke existing databases) and seed it with some test data
mix ecto.reset
# run the server
iex -S mix phx.server
```

## 🐳 Docker

```shell
docker compose --file scripts/docker-compose.yml up
```

Navigate to [http://localhost:4000/index.html](http://localhost:4000/index.html)