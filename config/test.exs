import Config

config :hui_mon,
  pubsub: %{server: :test_pubsub, topic: "test_solr_status"},
  solr_source: HuiMon.Source.SolrMock

config :hui, :default_solr,
  url: "http://localhost:8983/solr/gettingstarted",
  handler: "select",
  options: [timeout: 1000]
