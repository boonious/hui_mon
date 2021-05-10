defmodule HuiMon.UI.Home do
  use Scenic.Scene
  alias Scenic.{Graph, Scene}
  import Scenic.Primitives

  @pubsub %{server: HuiMon.PubSub, topic: "ping_status"}
  @solr_source Application.get_env(:hui_mon, :solr_source)
  @text_size 24

  # Scene callbacks

  @impl Scene
  def init(args, _opts) do
    {_rate, {_solr_instance, ping_status}} = @solr_source.state(:default_solr)

    graph =
      Graph.build(font: :roboto, font_size: @text_size)
      |> add_specs_to_graph([
        text_spec(parse_state(ping_status), id: :ping_status, translate: {20, 40})
      ])

    %{server: pubsub, topic: topic} = Keyword.get(args, :pubsub, @pubsub)
    Phoenix.PubSub.subscribe(pubsub, topic)

    {:ok, graph, push: graph}
  end

  @impl Scene
  def handle_info(:pang, graph) do
    graph = Graph.modify(graph, :ping_status, &text(&1, "DOWN"))
    {:noreply, graph, push: graph}
  end

  @impl Scene
  def handle_info({:pong, _qtime}, graph) do
    graph = Graph.modify(graph, :ping_status, &text(&1, "UP"))
    {:noreply, graph, push: graph}
  end

  @impl Scene
  def handle_input(_event, _context, state), do: {:noreply, state}

  defp parse_state({:pong, _qtime}), do: "UP"
  defp parse_state(:pang), do: "DOWN"
end
