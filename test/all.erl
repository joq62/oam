%%% -------------------------------------------------------------------
%%% @author  : Joq Erlang
%%% @doc: : 
%%% Created :
%% Use cases
%% - monitor and report change of system state
%% - read and filter on events notice,warning and alert events
%%     read_latest(all_levels|NOTICE|WARNING|ALERT,1-N),
%%     
%% 
%%% -------------------------------------------------------------------
-module(all).      
 
-export([start/0]).

-define(TargetDir,"ctrl_dir").
-define(Vm,node()).
-define(TarFile,"ctrl.tar.gz").
-define(App,"ctrl").
-define(TarSrc,"release"++"/"++?TarFile).
-define(StartCmd,"./"++?TargetDir++"/"++"bin"++"/"++?App).

-define(LogFileToRead,"./logs/oam/log.logs/test_logfile.1").
-define(ControllerLogDir,"./logs/ctrl/log.logs").
-define(LogFile1,"test_logfile.1").
-define(LogFile2,"test_logfile.2").

-define(AppVm,adder3@c50).
-define(AdderApp,adder3).


-record(state,{
	       all_ctrl_nodes,
	       connected,
	       not_connected,
	       logs
}).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("log.api").
%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
start()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE}]),
    
    ok=setup(),
    ok=init_test(),

    timer:sleep(2000),
    io:format("Test OK !!! ~p~n",[?MODULE]),
%    LogStr=os:cmd("cat "++?LogFileToRead),
%    L1=string:lexemes(LogStr,"\n"),
%    [io:format("~p~n",[Str])||Str<-L1],

  %  rpc:call(?Vm,init,stop,[],5000),
 %  timer:sleep(4000),
 %  init:stop(),
    ok.


%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
init_test()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    
    {ok,AllFilenames}=application_server:all_filenames(),
    [
     "adder3.application",
     "kvs.application",
     "phoscon.application"
    ]=lists:sort(AllFilenames),
    {ok,"Repo is up to date"}=application_server:update(),
    

    io:format("****************** ~p~n",[{date(),time()}]),      
    AllHostNodes=lists:sort(host_server:get_host_nodes()),
    io:format("Hostnodes  ~p~n",[AllHostNodes]),
    Pong=[{N,net_adm:ping(N)}||N<-AllHostNodes],
    ConnectedNodes=[N||{N,pong}<-Pong],
    io:format("Connected nodes ~p~n",[ConnectedNodes]),   
    NotConnectedNodes=[N||{N,pang}<-Pong],
    io:format("Not Connected nodes ~p~n",[NotConnectedNodes]),
    Logs=read_logs(AllHostNodes,[]),
    io:format("Logs ~p~n",[Logs]),   
    State=#state{
	     all_ctrl_nodes=[],
	     connected=[],
	     not_connected=[],
	     logs=[]},
    spawn(fun()->monitor_loop(State) end),
    ok.

read_logs([],Acc)->
    lists:sort(Acc);
read_logs([Node|T],Acc)->
    LogFile=filename:join(?ControllerLogDir,?LogFile1),
    NewAcc=case rpc:call(Node,os,cmd,["cat "++LogFile],2*5000) of
	       {badrpc,_}->
		   [{Node,[]}|Acc];
	       LogStr->
		   L=string:lexemes(LogStr,"\n"),
		   [{Node,L}|Acc]
	   end,
    read_logs(T,NewAcc).    

monitor_loop(State)->
    AllHostNodes=lists:sort(host_server:get_host_nodes()),
    Pong=[{N,net_adm:ping(N)}||N<-AllHostNodes],
    ConnectedNodes=[N||{N,pong}<-Pong],
    NotConnectedNodes=[N||{N,pang}<-Pong],
    Logs=read_logs(AllHostNodes,[]),
    StatusAllHostNodes=if 
			   AllHostNodes=/=State#state.all_ctrl_nodes->
			       {true,AllHostNodes,{io,format,["Updated AllHostNodes~p~n~n",[AllHostNodes]]}};
			   true ->
			       {false,AllHostNodes}
		       end,
    StatusConnectedNodes=if 
			     ConnectedNodes=/=State#state.connected->
				 {true,
				  ConnectedNodes,
				  {io,format,["Updated Connected  ~p~n~n",[ConnectedNodes]]}};
			     true ->
				 {false,ConnectedNodes}
			 end,
    StatusNotConnectedNodes=if 
				NotConnectedNodes=/=State#state.not_connected->
				    {true,
				     NotConnectedNodes,
				     {io,format,["Updated Not Connected  ~p~n~n",[NotConnectedNodes]]}};
				true->
				    {false,NotConnectedNodes}
			    end,
    NodeInfoList=[StatusAllHostNodes,StatusConnectedNodes,StatusNotConnectedNodes],
    NodeInfoUpdated=[NodeInfo||{true,NodeInfo,Print}<-NodeInfoList],
    IsNodeInfoUpdated= case NodeInfoUpdated of
			   []->
			       false;
			   _->
			       true
		       end,
     {AreLogsUpdate,UpdatedLogs,DiffLists}=are_logs_updated(Logs,State#state.logs,[]),
  %  io:format("IsNodeInfoUpdated,AreLogsUpdate ~p~n",[ {IsNodeInfoUpdated,AreLogsUpdate}]),
    case {IsNodeInfoUpdated,AreLogsUpdate} of
	{false,false}->
	    no_action;
	{false,true} ->
	    io:format(" ~n"),
	    io:format("--------------------------- ~p",[{date(),time()}]),
	    io:format("--------------------------- ~n"),
	    print(DiffLists);		  	
	{true,false}->
	    io:format(" ~n"),
	    io:format("--------------------------- ~p",[{date(),time()}]),
	    io:format("--------------------------- ~n"),
	    [erlang:apply(M,F,A)||{true,NodeInfo,{M,F,A}}<-NodeInfoList];
	{true,true}->
	    io:format(" ~n"),
	    io:format("--------------------------- ~p",[{date(),time()}]),
	    io:format("--------------------------- ~n"),
	    [erlang:apply(M,F,A)||{true,NodeInfo,{M,F,A}}<-NodeInfoList],
	    print(DiffLists)
    end,
  NewState=State#state{
	       all_ctrl_nodes=AllHostNodes,
	       connected=ConnectedNodes,
	       not_connected=NotConnectedNodes,
	       logs=UpdatedLogs}, 
    timer:sleep(10*1000),
    monitor_loop(NewState).

are_logs_updated([],_CurrentLogs,Acc)->
    UpdatedLogs=[{Node,Logs}||{_,{Node,Logs,_}}<-Acc],
    DiffLists=[{Node,DiffList}||{true,{Node,_,DiffList}}<-Acc],
    AreLogsUpdate=case DiffLists of
		      []->
			  false;
		      _->
			  true
		  end,
    {AreLogsUpdate,UpdatedLogs,DiffLists};
are_logs_updated([{Node,Logs}|T],CurrentLogs,Acc)->
 %   io:format("Node ~p~n",[Node]),
 %   io:format("Logs ~p~n",[Logs]),	    
 %   io:format("CurrentLogs ~p~n",[CurrentLogs]),
    NewAcc=case lists:keyfind(Node,1,CurrentLogs) of
	       false->
		   [{true,{Node,Logs,Logs}}|Acc];
	       {Node,CurrentNodeLog}->
		   DiffList=[Log||Log<-Logs,
				  false=:=lists:member(Log,CurrentNodeLog)],
		   case DiffList of
		       []->
			   [{false,{Node,Logs,[]}}|Acc];
		       DiffList->
			   [{true,{Node,Logs,DiffList}}|Acc]
		       
		   end
	   end,
    are_logs_updated(T,CurrentLogs,NewAcc).
	 			  
    
    
 %   case Node of
%	ctrl@c200->
%	    io:format("Node ~p~n",[Node]),
%	    io:format("Logs ~p~n",[Logs]),	    
%	    io:format("CurrentLogs ~p~n",[CurrentLogs]),
%	    io:format("DiffList ~p~n",[DiffList]);
%	_->
%	    ok
    

print([])->
    ok;
print([{Node,[]}|T])->
    print(T);
print([{Node,DiffList}|T])->
    io:format("~p~n",[Node]),
    [io:format("~p~n",[Log])||Log<-DiffList],
    print(T).
    
print([],_CurrentLogs,Acc)->
    Acc;
print([{Node,Logs}|T],CurrentLogs,Acc)->
    DiffList=[Log||Log<-Logs,
		   false=:=lists:member(Log,CurrentLogs)],
    case DiffList of
	[]->
	    no_action;
	DiffList->
	    [io:format("~p~n",[Log])||Log<-DiffList]
    end,
    print(T,CurrentLogs,[{Node,Logs}|Acc]).    
%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
application_server_test()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),

    %% Clean up before test 
   rpc:call(?Vm,application_server,stop_app,["adder3.application"],5000),
   rpc:call(?Vm,application_server,unload_app,["adder3.application"],5000),

    pong=rpc:call(?Vm,application_server,ping,[],5000),
    {ok,AllFilenames}=rpc:call(?Vm,application_server,all_filenames,[],5000),
    [
     "adder3.application",
     "kvs.application",
     "phoscon.application"
    ]=lists:sort(AllFilenames),
    {ok,"Repo is up to date"}=rpc:call(?Vm,application_server, update,[],5000),

    %Load and start adder3

    {error,["Not loaded ","adder3.application"]}=rpc:call(?Vm,application_server,start_app,["adder3.application"],5000),
    {error,["Not started ","adder3.application"]}=rpc:call(?Vm,application_server,stop_app,["adder3.application"],5000),
    {error,["Not loaded ","adder3.application"]}=rpc:call(?Vm,application_server,unload_app,["adder3.application"],5000),
    
    pong=rpc:call(?Vm,application_server,ping,[],5000),

    ok=rpc:call(?Vm,application_server,load_app,["adder3.application"],5*5000),
    {error,["Not started ","adder3.application"]}=rpc:call(?Vm,application_server,stop_app,["adder3.application"],5000),

    ok=rpc:call(?Vm,application_server,start_app,["adder3.application"],5*5000),
    AppVm=adder3@c50,
    42=rpc:call(AppVm,adder3,add,[20,22],5000),
    
    {error,["Already loaded ","adder3.application"]}=rpc:call(?Vm,application_server,load_app,["adder3.application"],5000),
    {error,[" Application started , needs to be stopped ","adder3.application"]}=rpc:call(?Vm,application_server,unload_app,["adder3.application"],5000),

    ok=rpc:call(?Vm,application_server,stop_app,["adder3.application"],5000),
    pang=net_adm:ping(AppVm),
    {error,["Not started ","adder3.application"]}=rpc:call(?Vm,application_server,stop_app,["adder3.application"],5000),
    {error,["Already loaded ","adder3.application"]}=rpc:call(?Vm,application_server,load_app,["adder3.application"],5000),
    ok=rpc:call(?Vm,application_server,unload_app,["adder3.application"],5000),
    
    ok.
%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
deployment_server_test()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    pong=rpc:call(?Vm,deployment_server,ping,[],5000),
    {ok,AllFilenames}=rpc:call(?Vm,deployment_server,all_filenames,[],5000),
    [
     "adder3.deployment",
      "kvs.deployment",
      "log2.deployment",
      "log2.deployment~",
      "phoscon_zigbee.deployment"
    ]=lists:sort(AllFilenames),
   
    [
     {"adder3.application","c50"},
     {"kvs.application","c50"},
     {"phoscon.application","c50"}
    ]=lists:sort(rpc:call(?Vm,deployment_server, get_applications_to_deploy,[],5000)),
   
    {ok,"Repo is up to date"}=rpc:call(?Vm,deployment_server, update,[],5000),
  
    ok.

%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
host_server_test()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    pong=rpc:call(?Vm,host_server,ping,[],5000),
   {ok,AllFilenames}=rpc:call(?Vm,host_server,all_filenames,[],5000),
    ["c200.host","c201.host","c202.host","c230.host","c50.host"]=lists:sort(AllFilenames),
    ['ctrl@c200','ctrl@c201','ctrl@c202','ctrl@c230','ctrl@c50']=lists:sort(rpc:call(?Vm,host_server, get_host_nodes,[],5000)),
    
    [
     {app1,[{value1,v11},{value2,12}]},
     {app2,[{value1,v21},{value2,22}]},
     {conbee,[{conbee_addr,"172.17.0.2"},
	      {conbee_port,80},
	      {conbee_key,"Glurk"}]}
    ]=rpc:call(?Vm,host_server,get_application_config,[],5000),

   
    {ok,"Repo is up to date"}=rpc:call(?Vm,host_server, update,[],5000),
  
    ok.
%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------

setup()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),

    ok=application:start(log),
    pong=log:ping(),
    file:make_dir(?MainLogDir),
    [NodeName,_HostName]=string:tokens(atom_to_list(node()),"@"),
    NodeNodeLogDir=filename:join(?MainLogDir,NodeName),
    ok=log:create_logger(NodeNodeLogDir,?LocalLogDir,?LogFile,?MaxNumFiles,?MaxNumBytes),
    ok=application:start(git_handler),
    pong=git_handler:ping(),  
    ok=application:start(application_server),
    pong=application_server:ping(),
    ok=application:start(host_server),
    pong=host_server:ping(),
    ok=application:start(deployment_server),
    pong=deployment_server:ping(),
    ok=application:start(oam),
    pong=oam:ping(),

 %   ok=initial_trade_resources(),
    
    ok.


initial_trade_resources()->
    [rd:add_local_resource(ResourceType,Resource)||{ResourceType,Resource}<-[]],
    [rd:add_target_resource_type(TargetType)||TargetType<-[controller,adder3]],
    rd:trade_resources(),
    timer:sleep(3000),
    ok.
