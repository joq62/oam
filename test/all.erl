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
   timer:sleep(4000),
   init:stop(),
    ok.


%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
init_test()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),

    AllHostNodes=host_server:get_host_nodes(),
    ['ctrl@c200','ctrl@c201','ctrl@c202','ctrl@c230','ctrl@c50']=lists:sort(AllHostNodes),
    Pong=[{N,net_adm:ping(N)}||N<-AllHostNodes],
    ConnectedNodes=[N||{N,pong}<-Pong],
    NotConnectedNodes=[N||{N,pang}<-Pong],
    io:format("ConnectedNodes ~p~n",[ConnectedNodes]),
    io:format("NotConnectedNodes ~p~n",[NotConnectedNodes]),
    
    {ok,AllFilenames}=application_server:all_filenames(),
    [
     "adder3.application",
     "kvs.application",
     "phoscon.application"
    ]=lists:sort(AllFilenames),
    {ok,"Repo is up to date"}=application_server:update(),
    
    %% Read ctrl logs
   % glurk=rpc:call('ctrl@c200',file,get_cwd,[],5000),
    LogFile=filename:join(?ControllerLogDir,?LogFile1),
    LogStrC200=rpc:call('ctrl@c200',os,cmd,["cat "++LogFile],2*5000),
    LC200=string:lexemes(LogStrC200,"\n"),
    [io:format("~p~n",[Str])||Str<-LC200],

    LogStrC50=rpc:call('ctrl@c50',os,cmd,["cat "++LogFile],2*5000),
    LC50=string:lexemes(LogStrC50,"\n"),
    [io:format("~p~n",[Str])||Str<-LC50],
    
    ok.





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
