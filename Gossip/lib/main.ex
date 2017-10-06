defmodule MainServerModule do
    
    def main(args \\ []) do
        {_,inputParsedVal,_} = OptionParser.parse(args, switches: [ help: :boolean ],aliases: [ h: :help ])
        [arg1 | list]=inputParsedVal;
        numNodes=String.to_integer arg1
        topology=hd(list)
        algorithm=hd(tl(list))

        #GossipMaster.start_link(numNodes)
        if(algorithm=="gossip") do            
            GossipChildModule.start_link(numNodes, topology) 
            :ets.new(:num_nodes_lookup, [:set, :public, :named_table])
            :ets.insert_new(:num_nodes_lookup, {"num_nodes", numNodes})
            :ets.insert_new(:num_nodes_lookup, {"start_time", :erlang.system_time})
            pid = spawn(GossipStarter, :gossipTerminator , [])
            startGossiping(numNodes)                                                             
        end                       
    end 

    def startGossiping(numNodes) do
        pid = spawn(GossipStarter, :greet , [])
        send pid, {self(), numNodes }
        receive do
            { :ok , message} ->
            IO.puts message    
        end 
    end
end

defmodule GossipStarter do
    def greet do
        receive do
            {_, numNodes} ->
            random_number = :rand.uniform(numNodes)
            random_node="node_"<>Integer.to_string(random_number)   
            spawn fn -> GenServer.call(String.to_atom(random_node),{:passMessage,"Hi there"}) end              
        end    
    end

    def gossipTerminator do
        [{_, count}] = :ets.lookup(:num_nodes_lookup, "num_nodes") 
        if count == 0 do    
            [{_, time}] = :ets.lookup(:num_nodes_lookup, "start_time")
            total_time_taken = :erlang.system_time - time
            IO.puts "Network has converged in " <> Integer.to_string(total_time_taken) 
            Process.exit(self(), :kill)
        else 
            :timer.sleep(100)
            IO.puts "Remaining Nodes " <> Integer.to_string(count)
            gossipTerminator()
        end       
    end
end
    
    