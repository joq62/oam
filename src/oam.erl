%%%-------------------------------------------------------------------
%%% @author c50 <joq62@c50>
%%% @copyright (C) 2023, c50
%%% @doc
%%% 
%%% @end
%%% Created :  2 Jun 2023 by c50 <joq62@c50>
%%%-------------------------------------------------------------------
-module(oam). 

-behaviour(gen_server). 
%%--------------------------------------------------------------------
%% Include 
%%
%%--------------------------------------------------------------------

-include("log.api").

-define(InfraSpecId,"basic"). 

%% API



-export([
	 all_nodes/0,
	 all_nodes/1,
	 all_providers/0
	]).
%%
-export([
%	 create_worker/1,
%	 delete_worker/1,
	 create_provider/2,
	 delete_provider/1,
%	 start/1,
%	 stop/1,
%	 unload/1,
	
	 
	 ping/0]).


-export([start/0]).


-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3, format_status/2]).

-define(SERVER, ?MODULE).

%% Record and Data
-record(state, {
		session_deployments,
		connect_nodes
	       }).

%% Table or Data models
%% ClusterSpec: Workers [{HostName,NumWorkers}],CookieStr,MainDir, 
%% ProviderSpec: appl_name,vsn,app,erl_args,git_path
%% DeploymentRecord: node_name,node,app, dir,provider,host

%% WorkerDeployment: DeploymentId, ProviderSpec, DeploymentRecord
%% Deployment: DeploymentId, ProviderId, Vsn, App, NodeName, HostName, NodeDir, ProviderDir,GitPath, Status : {status, time()}  
%% Static if in file : DeploymentSpecId, ProviderId, Vsn, App,ProviderDir,GitPath
%% Runtime:  DeploymentId,NodeName, HostName, NodeDir, Status
%% 


%%%===================================================================
%%% API
%%%===================================================================
%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
-spec all_providers() -> [{Node :: node(),ProviderApp :: atom()}].

all_providers()->
    gen_server:call(?SERVER,{all_providers},infinity).

%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
-spec create_provider(ProviderSpec :: string(),HostName :: string()) -> 
	  {ok,Id :: integer()}| {error,Reason :: term()}.

create_provider(ProviderSpec,HostName)->
    gen_server:call(?SERVER,{create_provider,ProviderSpec,HostName},infinity).
%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
-spec delete_provider(Id :: integer())-> ok| {error,Reason :: term()}.

delete_provider(Id)->
    gen_server:call(?SERVER,{delete_provider,Id},infinity).

%%--------------------------------------------------------------------
%% @doc
%% Create provider directory and starts the slave node 
%% @end
%%--------------------------------------------------------------------
-spec all_nodes() -> ListOfNodes :: term().
%%  Tabels or State
%%  ListOfNodes: [nodes()

all_nodes() ->
    gen_server:call(?SERVER,{all_nodes},infinity).

%%--------------------------------------------------------------------
%% @doc
%% Create provider directory and starts the slave node 
%% @end
%%--------------------------------------------------------------------
-spec all_nodes(HostName :: string()) -> ListOfNodes :: term() |{error,Reason :: term()}.
%%  Tabels or State
%%  ListOfNodes: [nodes()

all_nodes(HostName) ->
    gen_server:call(?SERVER,{all_nodes,HostName},infinity).


%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
start()->
    application:start(?MODULE).
%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%% @end
%%--------------------------------------------------------------------
-spec start_link() -> {ok, Pid :: pid()} |
	  {error, Error :: {already_started, pid()}} |
	  {error, Error :: term()} |
	  ignore.
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
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
ping()-> 
    gen_server:call(?SERVER, {ping},infinity).    

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%% @end
%%--------------------------------------------------------------------
-spec init(Args :: term()) -> {ok, State :: term()} |
	  {ok, State :: term(), Timeout :: timeout()} |
	  {ok, State :: term(), hibernate} |
	  {stop, Reason :: term()} |
	  ignore.
init([]) ->

    pong=etcd:ping(),
    %% set cookie 
    {ok,CookieStr}=etcd_infra:get_cookie_str(?InfraSpecId),
    erlang:set_cookie(list_to_atom(CookieStr)),

    %% Connect nodes
    {ok,ConnectNodes}=etcd_infra:get_connect_nodes(?InfraSpecId),
    [net_adm:ping(ConnectNode)||ConnectNode<-ConnectNodes],
    
    ?LOG_NOTICE("Server started ",[]),
  
    {ok, #state{
	    session_deployments=[],
	    connect_nodes=ConnectNodes}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%% @end
%%--------------------------------------------------------------------
-spec handle_call(Request :: term(), From :: {pid(), term()}, State :: term()) ->
	  {reply, Reply :: term(), NewState :: term()} |
	  {reply, Reply :: term(), NewState :: term(), Timeout :: timeout()} |
	  {reply, Reply :: term(), NewState :: term(), hibernate} |
	  {noreply, NewState :: term()} |
	  {noreply, NewState :: term(), Timeout :: timeout()} |
	  {noreply, NewState :: term(), hibernate} |
	  {stop, Reason :: term(), Reply :: term(), NewState :: term()} |
	  {stop, Reason :: term(), NewState :: term()}.



handle_call({all_nodes}, _From, State) ->
    Reply=lib_oam:all_nodes(State#state.connect_nodes),
    
    {reply, Reply, State};


handle_call({all_nodes,HostName}, _From, State) ->
    Reply = lib_oam:all_nodes(HostName,State#state.connect_nodes),
    {reply, Reply, State};

handle_call({all_providers}, _From, State) ->
    Reply = lib_oam:all_providers(State#state.connect_nodes),
    {reply, Reply, State};

handle_call({all_providers,HostName}, _From, State) ->
    Reply = lib_oam:all_providers(HostName,State#state.connect_nodes),
    {reply, Reply, State};

handle_call({create_provider,ProviderSpec,HostName}, _From, State) ->
    Reply = case lib_oam:create_provider(ProviderSpec,HostName,State#state.connect_nodes) of
		{error,Reason}->
		    NewState=State,
		    {error,Reason};
		{ok,Id,Node}->
		    NewState=State#state{session_deployments=[{Id,Node,ProviderSpec,HostName}|State#state.session_deployments]},
		    {ok,Id,Node}
	    end,
    {reply, Reply, NewState};


handle_call({delete_provider,Id}, _From, State) ->
    Reply = case lib_oam:delete_provider(Id,State#state.connect_nodes,State#state.session_deployments) of
		{error,Reason}->
		    NewState=State,
		    {error,Reason};
		{ok,Id}->
		    NewState=State#state{session_deployments=lists:keydelete(Id,1,State#state.session_deployments)},
		    ok
	    end,
    {reply, Reply, NewState};


handle_call({ping}, _From, State) ->
    Reply = pong,
    {reply, Reply, State};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%% @end
%%--------------------------------------------------------------------
-spec handle_cast(Request :: term(), State :: term()) ->
	  {noreply, NewState :: term()} |
	  {noreply, NewState :: term(), Timeout :: timeout()} |
	  {noreply, NewState :: term(), hibernate} |
	  {stop, Reason :: term(), NewState :: term()}.
handle_cast(_Request, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%% @end
%%--------------------------------------------------------------------
-spec handle_info(Info :: timeout() | term(), State :: term()) ->
	  {noreply, NewState :: term()} |
	  {noreply, NewState :: term(), Timeout :: timeout()} |
	  {noreply, NewState :: term(), hibernate} |
	  {stop, Reason :: normal | term(), NewState :: term()}.
handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%% @end
%%--------------------------------------------------------------------
-spec terminate(Reason :: normal | shutdown | {shutdown, term()} | term(),
		State :: term()) -> any().
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%% @end
%%--------------------------------------------------------------------
-spec code_change(OldVsn :: term() | {down, term()},
		  State :: term(),
		  Extra :: term()) -> {ok, NewState :: term()} |
	  {error, Reason :: term()}.
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called for changing the form and appearance
%% of gen_server status when it is returned from sys:get_status/1,2
%% or when it appears in termination error logs.
%% @end
%%--------------------------------------------------------------------
-spec format_status(Opt :: normal | terminate,
		    Status :: list()) -> Status :: term().
format_status(_Opt, Status) ->
    Status.

%%%===================================================================
%%% Internal functions
%%%===================================================================
