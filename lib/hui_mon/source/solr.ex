defmodule HuiMon.Source.Solr do
  use GenServer
  import Hui, only: [ping: 1]
  alias Phoenix.PubSub

  @default_poll_rate 5_000
  @default_solr :default_solr
  @pubsub Application.get_env(:hui_mon, :pubsub)

  @type ping_status :: {:pong, integer} | :pang
  @type poll_rate :: integer
  @type solr_instance :: atom

  @callback state(GenServer.server()) :: {poll_rate, {solr_instance, ping_status}}

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, @default_solr))
  end

  @spec state(GenServer.server()) :: {poll_rate, {solr_instance, ping_status}}
  def state(server \\ @default_solr), do: GenServer.call(server, :state)

  @spec poll(GenServer.server()) :: any
  def poll(server \\ @default_solr), do: send(server, :poll)

  # Server callbacks

  @impl true
  def init(opts) do
    solr = Keyword.get(Process.info(self()), :registered_name)
    rate = Keyword.get(opts, :poll_rate, @default_poll_rate)

    schedule_poll(self(), rate)
    {:ok, {rate, {solr, ping(solr)}}}
  end

  @impl true
  def handle_call(:state, _from, state), do: {:reply, state, state}

  @impl true
  def handle_info(:poll, {rate, {solr, status}}) do
    schedule_poll(self(), rate)
    new_status = ping(solr)

    maybe_update_ui(status, new_status)
    {:noreply, {rate, {solr, new_status}}}
  end

  defp maybe_update_ui(status, new_status) when status == new_status, do: :noop

  defp maybe_update_ui(_status, new_status) do
    PubSub.broadcast(@pubsub.server, @pubsub.topic, new_status)
  end

  defp schedule_poll(server, rate), do: Process.send_after(server, :poll, rate)
end
