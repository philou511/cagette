ROPTS=-zav --no-p --chmod=u=rwX,g=rwX,o=rX --delete --exclude=www/.htaccess --exclude=.svn --exclude=.git --exclude=*.mtt --exclude=tpl/css --exclude=www/file --exclude=www/tmp --exclude=*node_modules* --exclude=*.php --exclude=tests.n
LANG=fr
PLUGINS?=0
ENV?="dev"

#To compile project with plugins, add PLUGINS=1 or type `export PLUGINS=1`

install:
	@if [ $(ENV) = "dev" ]; then \
	make install_dev; \
	fi

#setup dev environnement from source
install_dev:
	#install haxe dependencies in .haxelib
	haxelib newrepo 
	haxelib -always install cagetteJs.hxml
	#install npm dependencies
	npm install
	npm run libs:dev
	#npm run build:js
	#compile
	@make frontend
	@echo "Well, it looks like everything is fine : librairies are installed, frontend has been compiled !"



#compile frontend to JS
frontend:
	@if [ $(PLUGINS) = 1 ]; then \
	haxe cagetteAllPluginsJs.hxml; \
	else \
	haxe cagetteJs.hxml; \
	fi

	
		
