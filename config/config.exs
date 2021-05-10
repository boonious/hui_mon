import Config

config :hui_mon,
  solr_source: HuiMon.Source.Solr

config :hui_mon, :viewport, %{
  name: :monitor_viewport,
  size: {700, 600},
  default_scene: {HuiMon.UI.Home, nil},
  drivers: [
    %{
      module: Scenic.Driver.Glfw,
      name: :glfw,
      opts: [resizeable: false, title: "hui_mon"]
    }
  ]
}

config :hui, :default_solr,
  url: "http://localhost:8983/solr/gettingstarted",
  handler: "select",
  options: [timeout: 1000]

import_config("#{config_env()}.exs")
