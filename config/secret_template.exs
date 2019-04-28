use Mix.Config

# Configuration for storing assets on S3.
#
# In production, use the following environment variables:
#
#    LEVEL_ASSET_STORE_BUCKET
#
config :level, :asset_store,
  bucket: "REPLACE ME",
  adapter: Level.AssetStore.S3Adapter

# Configuration for web push notifications.
# The keys should be URL-safe, Base64 encoded.
#
# Use https://github.com/web-push-libs/web-push#command-line
# to generate these them.
#
# In production, use the following environment variables:
#
#    LEVEL_WEB_PUSH_PUBLIC_KEY
#    LEVEL_WEB_PUSH_PRIVATE_KEY
#
config :web_push_encryption, :vapid_details,
  subject: "REPLACE ME",
  public_key: "REPLACE ME",
  private_key: "REPLACE ME"

# Configuration for the Postgres database.
#
# In production, use the following environment variables:
#
#    LEVEL_DATABASE_URL
#
config :level, Level.Repo,
  username: "postgres",
  password: "postgres"

# Configuration for AWS.
#
# In production, use the following environment variables:
#
#    AWS_ACCESS_KEY_ID
#    AWS_SECRET_ACCESS_KEY
#
config :ex_aws,
  access_key_id: "REPLACE ME",
  secret_access_key: "REPLACE ME"

# Configuration for Stripe.
#
# In production, use the following environment variables:
#
#    STRIPE_PUBLIC_KEY
#    STRIPE_PRIVATE_KEY
#
config :level, :stripe,
  public_key: "REPLACE ME WITH TEST PUBLIC KEY",
  private_key: "REPLACE ME WITH TEST PRIVATE KEY"

# Configuration for Billing.
#
# In production, use the following environment variables:
#
#    LEVEL_BILLING_ENABLED
#    LEVEL_BILLING_PLAN_ID
#
config :level, Level.Billing,
  enabled: false,
  plan_id: "REPLACE ME"
