defmodule HuiMon.Source.SolrStub do
  @behaviour HuiMon.Source.Solr

  def state(), do: {5000, {:default_solr, :pang}}
  def state(_), do: {5000, {:default_solr, :pang}}
end
