defmodule GossipMaster do

    use Supervisor
    @name Gossip.Master

    def start_link(num_nodes) do
        Supervisor.start_link(__MODULE__,{num_nodes}, name: @name)
        
    end

    def init(num_nodes) do
        IO.puts("Supervisor Started")

        children = [
            worker(GossipChildModule,[num_nodes],restart: :temporary)            
        ]

        supervise(children , strategy: :one_for_one)
    end

    def handle_cast({:actors_created,state_map},_from,state) do
        
    end
end