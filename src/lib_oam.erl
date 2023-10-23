%%%-------------------------------------------------------------------
%%% @author c50 <joq62@c50>
%%% @copyright (C) 2023, c50
%%% @doc
%%%
%%% @end
%%% Created : 24 Oct 2023 by c50 <joq62@c50>
%%%-------------------------------------------------------------------
-module(lib_oam).


-define(ConnectNode(CookieStr,HostName),list_to_atom("control"++"_"++CookieStr++"@"++HostName)).

%% API
-export([all_nodes/1,
	 all_nodes/2]).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
all_nodes(ConnectNodes)->
    R1=[{ConnectNode,rpc:call(ConnectNode,erlang,nodes,[],5000)}||ConnectNode<-ConnectNodes],
    extract(R1,[]).

extract([],Acc) ->
    lists:usort(Acc);
extract([{ConnectNode,{badrpc,nodedown}}|T],Acc)->
    extract(T,Acc);
extract([{ConnectNode,Nodes}|T],Acc) ->
    NewAcc=lists:append(Nodes,Acc),
    extract(T,NewAcc).

    
%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
all_nodes(HostName,ConnectNodes)->
    CookieStr=atom_to_list(erlang:get_cookie()),
    AllNodes=all_nodes(ConnectNodes),
    NodesAtHost=[Node||Node<-AllNodes,
		       {ok,HostName}=:=rpc:call(Node,net,gethostname,[],5000)],
    NodesAtHost.


%%%===================================================================
%%% Internal functions
%%%===================================================================
