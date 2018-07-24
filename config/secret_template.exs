use Mix.Config

# In production, use the following environment variables:
#
#    LEVEL_ASSET_STORE_BUCKET
#
config :level, :asset_store, bucket: "REPLACE ME"

# In production, use the following environment variables:
#
#    LEVEL_DATABASE_URL
#
config :level, Level.Repo,
  username: "postgres",
  password: "postgres"

# In production, use the following environment variables:
#
#    AWS_ACCESS_KEY_ID
#    AWS_SECRET_ACCESS_KEY
#
config :ex_aws,
  access_key_id: "REPLACE ME",
  secret_access_key: "REPLACE ME"
