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
git = require 'nodegit'
module.exports = ->
	###
	 	Main Constructor

	 	Params:

	 		- "server address"
	 		- "username [default=git]"
	 		- "options hash"
	###
	###
	Gitonode = (serveraddress, username, options)=>
		@options = _.extend
			location: '/var/tmp'
			username: if username then username else "git"
		, options || {}
		@options.address = serveraddress
	
	Gitonode.prototype.###

	all = "@all"  # Constant
	class GitonodeErr
		constructor: (@errCode,@errString)->
			@
		getCode: ()->
			@errCode
		getMessage: ()->
			@errString
	class Gitonode
		constructor: (serveraddress, username, options)->
			@options = _.extend
				location: '/var/tmp'
				username: if username then username else "git"
			, options || {}
			@options.address = serveraddress

			# Note that we have not yet pulled in anything
			@dirty = false

			# Initialize "models" to empties
			@groups = []
			@users = []
			@repos = []

			@
		
		reload: (callback)->
			# reload from server
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
				# Do the commit
				@dirty = false
				callback(null)
			else
				# Terminate immediately
				callback(new GitonodeErr(100,"No changes to commit"))
			@



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