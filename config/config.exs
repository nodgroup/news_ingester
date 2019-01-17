# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :news_ingester, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:news_ingester, :key)
#
# You can also configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env()}.exs"

config :news_ingester,
  # wait time between each crawl request / in seconds
  a_a_crawl_timer: 600,
  a_a_base_url: "https://api.aa.com.tr/abone/",
  a_a_search_path: "search",
  a_a_document_path: "document",
  a_a_picture_quality: "web",
  a_a_video_quality: "web",
  a_a_text_type: "newsml29",
  # AA doesn't return reply after header with 429
  a_a_429_wait_time: 10

# for dev and test, edit prod.exs for prod values
config :ex_aws,
       :dynamodb,
       access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
       secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
       scheme: "http://",
       host: "localhost",
       port: 8000,
       region: "us-east-1"

import_config("#{Mix.env()}.exs")
import_config("secret.exs")
