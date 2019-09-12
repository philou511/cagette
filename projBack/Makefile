ROPTS=-zav --no-p --chmod=u=rwX,g=rwX,o=rX --delete --exclude=www/.htaccess --exclude=.svn --exclude=.git --exclude=*.mtt --exclude=tpl/css --exclude=www/file --exclude=www/tmp --exclude=*node_modules* --exclude=*.php --exclude=tests.n
LANG=fr
PLUGINS?=0
ENV?="dev"

#To compile project with plugins, add PLUGINS=1 or type `export PLUGINS=1`

install:
	#copy config file from template
	cp ../config.xml.dist ../config.xml	
	@if [ $(ENV) = "dev" ]; then \
	make install_dev; \
	fi

#setup dev environnement from source
install_dev:
	#set config file to debug=1
	@sed -e 's?debug=.*?debug="1"?g' --in-place ../config.xml
	#install haxe dependencies in .haxelib
	haxelib newrepo 
	haxelib -always install cagette.hxml
	#haxelib -always install cagetteJs.hxml
	#template tools
	#haxelib run templo
	#sudo mv temploc2 /usr/bin
	#extra plugins
	@if [ $(PLUGINS) = 1 ]; then \
	haxelib git cagette-pro git@bitbucket.org:bubar/cagette-pro.git; \
	haxelib git cagette-hosted git@bitbucket.org:bubar/cagette-hosted.git; \
	haxelib git cagette-wholesale-order git@github.com:bablukid/cagette-wholesale-order.git; \
	fi
	#install npm dependencies
	npm install
	#npm run libs:dev
	#npm run build:js
	#compile
	@make css
	@make compile
	#@make frontend
	@echo "Well, it looks like everything is fine : librairies are installed, backend has been compiled !"


#compile backend to Neko
compile:
	@if [ $(PLUGINS) = 1 ]; then \
	echo "compile Cagette.net with plugins"; \
	haxe cagetteAllPlugins.hxml -D i18n_generation; \
	else \
	echo "compile Cagette.net core"; \
	haxe cagette.hxml; \
	fi
	

#compile SASS files to CSS
css:
	npm run build:sass

#compile frontend to JS
frontend:
	@if [ $(PLUGINS) = 1 ]; then \
	haxe cagetteAllPluginsJs.hxml; \
	else \
	haxe cagetteJs.hxml; \
	fi

	

#update POT file from source
i18n:	
	haxe cagette.hxml -D i18n_parsing

#compile templates in each language, required for production env.
templates:	
	@make LANG=fr ctemplates
	@make LANG=en ctemplates
	@make LANG=de ctemplates

ctemplates:
	(cd ../lang/$(LANG)/tpl; temploc2 -macros macros.mtt -output ../tmp/ *.mtt */*.mtt */*/*.mtt */*/*/*.mtt */*/*/*/*.mtt)

deploy: 
	#@make css
	#@make frontend PLUGINS=1	
	@make cp_plugin
	@make compile PLUGINS=1
	@make templates
	@make deploy_site
	
deploypp:
	#@make css
	#@make frontend PLUGINS=1
	@make cp_plugin
	@make compile PLUGINS=1
	@make templates	
	@make deploy_site_pp
	
deploy_site:
	rsync $(ROPTS) ../www  appcagette@agilocloud:/var/vhosts/appcagette/app.cagette.net/
	rsync $(ROPTS) ../data appcagette@agilocloud:/var/vhosts/appcagette/app.cagette.net/
	rsync $(ROPTS) ../lang appcagette@agilocloud:/var/vhosts/appcagette/app.cagette.net/
	
deploy_site_pp:
	rsync $(ROPTS) ../www  ppcagette@agilocloud:/var/vhosts/ppcagette/pp.cagette.net/
	rsync $(ROPTS) ../data ppcagette@agilocloud:/var/vhosts/ppcagette/pp.cagette.net/
	rsync $(ROPTS) ../lang ppcagette@agilocloud:/var/vhosts/ppcagette/pp.cagette.net/

# Bundle binaries (neko version) and send them online at www.cagette.net/cagette.tar
bundle:
	@make LANG=fr ctemplates
	@make LANG=en ctemplates
	haxe cagette.hxml
	rm -rf www/file/*.*
	tar -cvf cagette.tar www config.xml.dist lang data --exclude www/bower_components/bootstrap/node_modules
	scp cagette.tar root@www.cagette.net:/var/www/vhosts/cagette.net/httpdocs/
	
#Compile and run unit tests	
tests: 
	@if [ $(PLUGINS) = 1 ]; then \
	haxe testsPlugins.hxml; \
	else \
	haxe tests.hxml; \
	fi
	@docker-compose run --workdir="/var/www/www" neko neko tests.n mysql://root:root@mysql/tests

cp_plugin:
	cp -R .haxelib/cagette-hosted/git/tpl/* ../lang/master/tpl/plugin/hosted/
	cp -R .haxelib/cagette-pro/git/tpl/* ../lang/master/tpl/plugin/pro/
	cp -R .haxelib/cagette-wholesale-order/git/tpl/* ../lang/master/tpl/plugin/who/
		
