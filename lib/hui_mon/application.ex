defmodule HuiMon.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    ui_config = Application.get_env(:hui_mon, :viewport)

    children = [
      HuiMon.Source.Solr,
      {Scenic, viewports: [ui_config]}
    ]

    opts = [strategy: :one_for_one, name: HuiMon.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
