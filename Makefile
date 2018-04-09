ROPTS=-zav --no-p --chmod=u=rwX,g=rX,o= --delete --exclude=www/.htaccess --exclude=.svn --exclude=.git --exclude=*.mtt --exclude=tpl/css --exclude=www/file --exclude=*node_modules* --exclude=*.php
LANG=fr
PLUGINS?=0

install:
	#copy config file from template
	cp config.xml.dist config.xml	
	@if [ $(ENV) = "dev" ]; then \
	make install_dev; \
	fi

#setup dev environnement from source
install_dev:
	#set config file to debug=1
	@sed -e 's?debug=.*?debug="1"?g' --in-place config.xml
	#install haxe dependencies in .haxelib
	haxelib newrepo 
	haxelib -always install cagette.hxml
	haxelib -always install cagetteJs.hxml
	#template tools
	haxelib run templo
	sudo mv temploc2 /usr/bin
	#extra libs
	#@if [ $(PLUGINS) = 1 ]; then \
	#echo "haxelib git tamere"; \
	#fi
	#install npm dependencies
	npm install
	npm run libs:dev
	npm run build:js
	#compile
	@make css
	@make compile
	@make frontend
	@echo "Well, it looks like everything is fine : librairies are installed, backend and frontend has been compiled !dock"


#compile backend to Neko
compile:
	@if [ $(PLUGINS) = 1 ]; then \
	echo "compile with plugins"; \
	haxe cagetteAllPlugins.hxml; \
	else \
	echo "compile Cagette core"; \
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

i18n:	
	haxe potGeneration.hxml

#compile templates in each language, required for production env.
templates:	
	haxe templateGeneration.hxml
	@make LANG=fr ctemplates
	@make LANG=en ctemplates
	@make LANG=de ctemplates

ctemplates:
	(cd lang/$(LANG)/tpl; temploc2 -macros macros.mtt -output ../tmp/ *.mtt */*.mtt */*/*.mtt */*/*/*.mtt */*/*/*/*.mtt)

deploy: 
	@make templates
	@make compile
	@make deploy_site
	
deploypp:
	@make templates
	@make compile
	@make deploy_site_pp
	

test:
	rsync $(ROPTS) lang/* www-data@app.cagette.net:/data/cagettepp/lang/

deploy_site:
	rsync $(ROPTS) www www-data@app.cagette.net:/data/cagette/
	rsync $(ROPTS) data www-data@app.cagette.net:/data/cagette/
	rsync $(ROPTS) lang www-data@app.cagette.net:/data/cagette/
	
deploy_site_pp:
	rsync $(ROPTS) www www-data@app.cagette.net:/data/cagettepp/
	rsync $(ROPTS) data www-data@app.cagette.net:/data/cagettepp/
	rsync $(ROPTS) lang www-data@app.cagette.net:/data/cagettepp/

# Bundle binaries (neko version) and send them online at www.cagette.net/cagette.tar
bundle:
	@make LANG=fr ctemplates
	@make LANG=en ctemplates
	haxe cagette.hxml
	rm -rf www/file/*.*
	tar -cvf cagette.tar www config.xml.dist lang data --exclude www/bower_components/bootstrap/node_modules
	scp cagette.tar root@www.cagette.net:/var/www/vhosts/cagette.net/httpdocs/
	
cp_plugin:
	cp -R lang/master/tpl/plugin/hosted/* .haxelib/cagette-hosted/git/src/hosted/lang/master/tpl/hosted/
	cp -R lang/master/tpl/plugin/pro/* .haxelib/cagette-pro/git/src/pro/lang/master/tpl/
	cp -R lang/master/tpl/plugin/connector/* .haxelib/cagette-connector/git/src/connector/lang/master/tpl/
	cp -R lang/master/tpl/plugin/who/* .haxelib/cagette-wholesale-order/git/src/who/lang/master/tpl/

#unit tests	
tests: 
	haxe tests.hxml
	neko tests.n
		
