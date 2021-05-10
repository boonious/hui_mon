defmodule HuiMon.Source.SolrTest do
  use ExUnit.Case, async: true
  import TestHelpers
  alias HuiMon.Source.Solr

  @pubsub Application.get_env(:hui_mon, :pubsub)
  @solr :test_solr

  setup do
    bypass = Bypass.open()
    test_endpoint = [url: "http://localhost:#{bypass.port}/solr/test"]
    Application.put_env(:hui, :test_solr, test_endpoint)

    start_supervised({Phoenix.PubSub, name: @pubsub.server})

    %{bypass: bypass}
  end

  test "init/1 trigger a ping of Solr", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", "/solr/test/admin/ping", fn conn ->
      Plug.Conn.resp(conn, 200, "")
    end)

    start_supervised(%{id: @solr, start: {Solr, :start_link, [[name: @solr]]}})
  end

  test "state/1 returns :pong and qtime tuple when Solr is available", %{bypass: bypass} do
    qtime = 15
    bypass_ping_ok(bypass, qtime)
    start_supervised(%{id: @solr, start: {Solr, :start_link, [[name: @solr]]}})

    assert {_rate, {solr_instance, {:pong, ^qtime}}} = Solr.state(@solr)
    assert solr_instance == @solr
  end

  test "state/1 returns :pang when Solr is down", %{bypass: bypass} do
    Bypass.down(bypass)
    start_supervised(%{id: @solr, start: {Solr, :start_link, [[name: @solr]]}})
    assert {_rate, {_solr, :pang}} = Solr.state(@solr)
  end

  test "manual poll/1 instigates a ping", %{bypass: bypass} do
    Bypass.down(bypass)
    start_supervised(%{id: @solr, start: {Solr, :start_link, [[name: @solr]]}})
    assert {_rate, {_solr, :pang}} = Solr.state(@solr)

    Bypass.up(bypass)
    bypass_ping_ok(bypass)

    Solr.poll(@solr)
    assert {_rate, {_solr, {:pong, _qtime}}} = Solr.state(@solr)
  end

  test "periodic pings occur", %{bypass: bypass} do
    poll_rate = 100
    bypass_ping_ok(bypass)

    start_supervised(%{
      id: @solr,
      start: {Solr, :start_link, [[name: @solr, poll_rate: poll_rate]]}
    })

    assert {_rate, {_solr, {:pong, _qtime}}} = Solr.state(@solr)

    Bypass.down(bypass)
    Process.sleep(200)
    assert {^poll_rate, {:test_solr, :pang}} = Solr.state(@solr)
  end
end
