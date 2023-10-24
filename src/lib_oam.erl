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
-export([
	 create_provider/3,
	 delete_provider/3,
	 all_providers/1,
	 all_providers/2,
	 all_nodes/1,
	 all_nodes/2
	]).

%%%===================================================================
%%% API
%%%===================================================================
%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
all_providers(ConnectNodes)->
    GetAppsResult=[{ProviderId,etcd_application:get_app(ProviderId)}||ProviderId<-etcd_application:all_providers()],
    AllProviderApps=[{ProviderId,App}||{ProviderId,{ok,App}}<-GetAppsResult],
  %  io:format("ConnectNodes ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE,ConnectNodes}]),
    AllNodes=all_nodes(ConnectNodes),
  %  io:format("AllNodes ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE,AllNodes}]),
    AllNodesApps=[{Node,rpc:call(Node,application,which_applications,[],5000)}||Node<-all_nodes(ConnectNodes)],
    Result=get_providers(AllNodesApps,AllProviderApps,[]),
			
    Result.

get_providers([],_AllProviderApps,Acc)->
    Acc;
get_providers([{Node,{badrpc,nodedown}}|T],AllProviderApps,Acc)->
     get_providers(T,AllProviderApps,Acc);
get_providers([{Node,AppList}|T],AllProviderApps,Acc)->
    FoundNodeProviders=get_providers2(AllProviderApps,{Node,AppList},[]),   
    get_providers(T,AllProviderApps,lists:append(FoundNodeProviders,Acc)).

get_providers2([],_,Acc)->
    Acc;
get_providers2([{ProviderId,WantedApp}|T],{Node,AppList},Acc)->
    HostName=get_hostname(Node),
    FoundNodeProviders=[{ProviderId,HostName,Node,App}||{App,_,_}<-AppList,
					   WantedApp=:=App],
    get_providers2(T,{Node,AppList},lists:append(FoundNodeProviders,Acc)).
%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
all_providers(HostName,ConnectNodes)->
    

    ok.
%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
create_provider(ProviderSpec,HostName,ConnectNodes)->
    
    ok.
    
%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
delete_provider(Id,ConnectNodes,SessionDeployments)->
    
    ok.
%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------



%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
all_nodes(ConnectNodes)->
 %   ping(ConnectNodes),
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
		       HostName=:=get_hostname(Node)],
    NodesAtHost.

%%%===================================================================
%%% Internal functions
%%%===================================================================
%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
 ping(Nodes)->
    [rpc:call(Node1,net_adm,ping,[Node2],500)||Node1<-Nodes,
						Node2<-Nodes].

%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
get_hostname(Node)->
    [_,HostName]=string:tokens(atom_to_list(Node),"@"),
    HostName.
