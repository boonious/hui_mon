defmodule HuiMon.UI.HomeTest do
  use ExUnit.Case
  import Mox
  import TestHelpers

  alias HuiMon.UI.Home
  alias HuiMon.Source.{SolrMock, SolrStub}
  alias Phoenix.PubSub

  @pubsub Application.get_env(:hui_mon, :pubsub)

  setup do
    # Solr ping returning :pang
    stub_with(SolrMock, SolrStub)
    start_supervised({Phoenix.PubSub, name: @pubsub.server})
    %{scene_args: [pubsub: @pubsub]}
  end

  describe "init/2" do
    test "ping status text primitive is `DOWN` when ping fails", %{scene_args: args} do
      {:ok, graph, _push_graph} = Home.init(args, [])
      assert %{data: "DOWN"} = Scenic.Graph.get(graph, :ping_status) |> hd
    end

    test "ping status text primitive is `UP` when ping is successful", %{scene_args: args} do
      SolrMock |> expect(:state, fn _solr -> {5000, {:test_solr, {:pong, 15}}} end)

      {:ok, graph, _push_graph} = Home.init(args, [])
      assert %{data: "UP"} = Scenic.Graph.get(graph, :ping_status) |> hd
    end

    test "scene subscribes to PubSub ping event notification", %{scene_args: args} do
      {:ok, _graph, _push_graph} = Home.init(args, [])

      message_ref = make_ref()
      PubSub.broadcast(@pubsub.server, @pubsub.topic, {:test_message, id: message_ref})

      assert_receive {:test_message, id: ^message_ref}
    end
  end

  describe "PubSub" do
    test "ping status change leads to a notification", %{scene_args: args} do
      {:ok, graph, _push_graph} = Home.init(args, [])
      assert %{data: "DOWN"} = Scenic.Graph.get(graph, :ping_status) |> hd

      bypass = Bypass.open()
      test_endpoint = [url: "http://localhost:#{bypass.port}/solr/test"]
      Application.put_env(:hui, :home_ui_test_solr, test_endpoint)

      # sets Solr to ok
      qtime = 30
      bypass_ping_ok(bypass, qtime)

      # poll Solr
      previous_status = :pang
      HuiMon.Source.Solr.handle_info(:poll, {5000, {:home_ui_test_solr, previous_status}})

      assert {:messages, [pong: ^qtime]} = Process.info(self(), :messages)
      assert_receive {:pong, ^qtime}
    end

    test "ping status unchanged leads to no notification", %{scene_args: args} do
      {:ok, graph, _push_graph} = Home.init(args, [])
      assert %{data: "DOWN"} = Scenic.Graph.get(graph, :ping_status) |> hd

      bypass = Bypass.open()
      test_endpoint = [url: "http://localhost:#{bypass.port}/solr/test"]
      Application.put_env(:hui, :home_ui_test_solr, test_endpoint)

      Bypass.down(bypass)
      previous_status = :pang
      HuiMon.Source.Solr.handle_info(:poll, {5000, {:home_ui_test_solr, previous_status}})

      assert {:messages, []} == Process.info(self(), :messages)
      refute_receive {:pong, _qtime}
    end

    test "ping status change leads graph update", %{scene_args: args} do
      {:ok, graph, _push_graph} = Home.init(args, [])
      assert %{data: "DOWN"} = Scenic.Graph.get(graph, :ping_status) |> hd

      qtime = 20
      new_status = {:pong, qtime}
      {:noreply, graph, _push_graph} = Home.handle_info(new_status, graph)
      assert %{data: "UP"} = Scenic.Graph.get(graph, :ping_status) |> hd

      new_status = :pang
      {:noreply, graph, _push_graph} = Home.handle_info(new_status, graph)
      assert %{data: "DOWN"} = Scenic.Graph.get(graph, :ping_status) |> hd
    end
  end
end
