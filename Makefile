all:
	#INFO: with_ebin_commit STARTED
	#INFO: Cleaning up to prepare build STARTED	 
	#INFO: Deleting crash reports
	rm -rf erl_cra* rebar3_crashreport;
	rm -rf *~ */*~ */*/*~ */*/*/*~;
	#INFO: Deleting euinit test applications dirs
	rm -rf logs;
	rm -rf *_specs;
	rm -rf test_ebin;
	#INFO: Deleting tilde files and beams
	rm -rf *~ */*~ */*/*~;
	rm -rf apps/*/src/*.beam;
	rm -rf test/*.beam test/*/*.beam;
	rm -rf *.beam;
	#INFO: Deleting files and dirs created during builds
	rm -rf _build;
	rm -rf ebin;
	rm -rf rebar.lock
	#INFO: Compile application
	rm -rf common_include;
	cp -r ~/erlang/simple_system/common_include .
	rm -rf release
	rebar3 compile
	rm -rf _build*;
	git status
	echo Ok there you go!
	#INFO: no_ebin_commit ENDED SUCCESSFUL
clean:
	#INFO: clean STARTED
	#INFO: with_ebin_commit STARTED
	#INFO: Cleaning up to prepare build STARTED	 
	#INFO: Deleting crash reports
	rm -rf erl_cra* rebar3_crashreport;
	rm -rf *~ */*~ */*/*~ */*/*/*~;
	#INFO: Deleting euinit test applications dirs
	rm -rf logs;
	rm -rf *_specs;
	rm -rf test_ebin;
	#INFO: Deleting tilde files and beams
	rm -rf *~ */*~ */*/*~;
	rm -rf apps/*/src/*.beam;
	rm -rf test/*.beam test/*/*.beam;
	rm -rf *.beam;
	#INFO: Deleting files and dirs created during builds
	rm -rf *_specs;
	rm -rf _build;
	rm -rf ebin;
	rm -rf rebar.lock
	#INFO: Deleting files and dirs created during execution/runtime 
	rm -rf logs;
	rm -rf *_a;
	#INFO: clean ENDED SUCCESSFUL
eunit: 
	#INFO: eunit STARTED
	#INFO: with_ebin_commit STARTED
	#INFO: Cleaning up to prepare build STARTED	 
	#INFO: Deleting crash reports
	rm -rf erl_cra* rebar3_crashreport;
	rm -rf *~ */*~ */*/*~ */*/*/*~;
	#INFO: Deleting euinit test applications dirs
	rm -rf logs;
	rm -rf *_specs;
	rm -rf test_ebin;
	#INFO: Deleting tilde files and beams
	rm -rf *~ */*~ */*/*~;
	rm -rf apps/*/src/*.beam;
	rm -rf test/*.beam test/*/*.beam;
	rm -rf *.beam;
	#INFO: Deleting files and dirs created during builds
	rm -rf _build;
	rm -rf rebar.lock
	#INFO: Deleting files and dirs created during execution/runtime 
	rm -rf logs;
	rm -rf catalog_specs;
	rm -rf *_a;
	#INFO: Creating eunit test code using test_ebin dir;
	mkdir test_ebin;
	rm -rf common_include;
	cp -r ~/erlang/simple_system/common_include .
	#rm test/dependent_apps.erl;
	#cp /home/joq62/erlang/dev_support/dependent_apps.erl test;
	erlc -I include -I common_include -o test_ebin test/*.erl;
	#INFO: Creating Common applications needed for testing
	#INFO: Compile application
	rebar3 compile
	rebar3 release;
	#INFO: Starts the eunit testing .................
	erl -pa test_ebin\
	 -pa _build/default/lib/*/ebin\
	 -sname oam\
	 -run $(m) start\
	 -setcookie a