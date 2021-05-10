defmodule HuiMon.UI.HomeTest do
  use ExUnit.Case, async: true
  import Mox

  alias HuiMon.UI.Home
  alias HuiMon.Source.SolrMock

  test "init/2 graph text primitive is `DOWN` when ping fails" do
    SolrMock |> expect(:state, fn _solr -> {5000, {:test_solr, :pang}} end)
    {:ok, graph, _push_graph} = Home.init(nil, [])
    assert %{data: "DOWN"} = Scenic.Graph.get(graph, :ping_status) |> hd
  end

  test "init/2 graph text primitive is `UP` when ping is successful" do
    SolrMock |> expect(:state, fn _solr -> {5000, {:test_solr, {:pong, 15}}} end)
    {:ok, graph, _push_graph} = Home.init(nil, [])
    assert %{data: "UP"} = Scenic.Graph.get(graph, :ping_status) |> hd
  end
end
