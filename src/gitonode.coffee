###
Copyright (c) 2012 Max Parker-Shames <max@starshiptolstoy.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
###

require 'underscore'
#ngit = require 'gift'
path = require 'path'
fs = require 'fs'
peg = require 'pegjs'
{exec} = require 'child_process'

module.exports = ->
	###
	 	Main Constructor

	 	Params:

	 		- location to root of initialized git repository for gitolite
	###
	class Gitonode
		constructor: (loc)->
			# Modify passed location to get the actual git directory
			@location = path.normalize(loc)
			# Check for consistency of repository
			if !fs.existsSync(path.join(@location,'.git'))
				throw "No git repository at location"

			# Note that we have not yet pulled in anything
			@dirty = false

			# Initialize "models" to empties
			@groups = []
			@users = []
			@repos = []

			# Reload
			try
				reload()
			catch (err)
				throw err

			if !checkValidity()
				throw "Invalid gitolite repository at location"

			# Instantiate the parser
			@parser = peg.buildParser fs.readFileSync './schema.peg', 'utf-8'

			@
		
		checkValidity: ->
			# Check to make sure our repository contains the proper files
			if fs.existsSync(path.join(@location,'conf/gitlite.conf')) && fs.existsSync(path.join(@location,'keydir'))
				return true
			else
				return false
		fetchUser: (username)->
			users.forEach (user)->
				if user.name is username
					return user
			return null
		populateModels: (callback)->
			# Assumes we have already created a valid git repository
			# parse gitolite config
			config = path.join(@location,'conf/gitolite.conf')
			keys = path.join(@location,'keydir')
			fs.readFile config, (err,data)->
				if err
					throw err
				# ensure file ends with a newline
				data = data + "\n \n"
				try
					presult = @parser.parse data
					# Traverse the generated tree and create the repos, groups, and users modules as appropriate.
					presult.forEach (repo)->
						# Construct the repository object
						rname = repo.name
						# Find all users and relevant access levels
						rusrs = []
						repo.access.forEach (alevel)->
							access = alevel.level
							alevel.users.forEach (uname)->
								rusrs.push { "name": uname, "access": access }
							# TODO: add configuration objects
						repository = { "name": rname, "users": rusrs }
						@repos.push repository
						# Add users to users array if they don't already exist there
						rusrs.forEach (user)->
							ruser = fetchUser user.name
							if ruser is null
								# Instantiate the new object
								ruser =
									name: user.name
									access: []
							else
								# Remove element from array
								



				catch (e)
					# Parse error
					throw 'Parse error: '+e.message
				# Now attempt to read in the user keyfiles and append them as necessary to the users array
				fs.readdir keys,(err,files)->
					if err
						throw err
					files.forEach (file)->
						fs.readFile file, (err,data)->
							if err
								throw err
							# Append key contents (data) to user named file
							# TODO

					# We're done. Call the callback function
					callback()
			@




		reload: (callback)->
			# reload from server
			exec "git pull .", {cwd: @location},(err, stdout, stderr)=>
				if stderr
					# There were problems
					throw "reload failed"
				
				# Now populate models
				populateModels(callback)
				@dirty = false
			@


			# Initialize repo
			git.repo @options.address,(err,repo)=>
				if err
					throw err
				repo.branch "master",(err,branch)->
					if err
						throw err

					# TODO: fetch the files
					# and populate models
					@dirty = true
					return callback()

		commit: (callback)->
			# Commit changes to the server
			if @dirty is true
				# Do the commit TODO

				@dirty = false
				callback(null)
			else
				# Terminate immediately
				throw "No changes to commit"
			@


		###
		addGroup: (group)->
			if group instanceof GitonodeGroup
				@groups.push group
				@dirty = true
				true
			else
				false
		addUser: (user)->
			if user instanceof GitonodeUser
				@users.push user
				@dirty = true
				true
			else
				false
		addRepo: (repo)->
			if repo instanceof GitonodeRepository
				@repos.push repo
				@dirty = true
				true
			else
				false
		getUsers: (callback)->
			if @dirty
				callback @users
			else
				reload getUsers(callback)
			true
		getRepos: (callback)->
			if @dirty
				callback @repos
			else
				reload getRepos(callback)
			true
		getGroups: (callback)->
			if @dirty
				callback @repos
			else
				reload getGroups(callback)
			true
		initGroup: (groupName)->
			grp = new GitonodeGroup groupName,[],[]
			@groups.push grp
			@dirty = true
			grp
		initUser: (userName)->
			usr = new GitonodeUser userName, []
			@users.push usr
			@dirty = true
			usr
		initRepo: (repoName)->
			rpo = new GitonodeRepository repoName,[],[]
			@repos.push rpo
			@dirty = true
			rpo
	class GitonodeUser
		constructor: (@name,@keys)->
			@
		addKey: (keyString)->
			@keys.push keyString
			@
	class GitonodeGroup
		constructor: (@name,@children,@users)->
			@childrenHasAll = false
			@
		addGroup: (gitoGroup)->
			if gitoGroup == "@all"
				@childrenHasAll = true
				return true
			else if gitoGroup instanceof GitonodeGroup
				@children.push gitoGroup
				return true
			else
				return false
			@
		addUser: (gitoUser)->
			if gitoUser instanceof GitonodeUser
				@users.push gitoUser
				return true
			else
				return false
			@
	class GitonodeRepository
		constructor: (@name,@users,@groups)->
			@allGroup = false
			@
		addUser: (gitoUser,permission)->
			if gitoUser instanceof GitonodeUser
				@users.push
					'user': gitoUser
					'permission': if permission then permission else "R"
				true
			else
				false
		addGroup: (gitoGroup, permission)->
			if gitoGroup instanceof GitonodeGroup
				@groups.push
					'group': gitoGroup
					'permission': if permisison then permission else "R"
			else if gitoGroup is "@all"
				@allGroup = if permission then permission else "R"
			else
				false
	###