fs = require 'fs'
path = require 'path'
fu = require '../lib/fileutils.coffee'
Seq = require 'seq'
_ = require 'underscore'

includedExts = ['.html']
ignoredFiles = ['.DS_Store']

root_dir = "/Users/tlorenz/Dropboxes/Gmail/Dropbox/dev/javascript/node/gittopdf/bdd_nodechat"

class Folder
  constructor: (@name, @fullPath, @depth, @files, @folders) ->


collectFilesAndFolders = (fullPath, includedExts, ignoredFiles, callback) ->
  ctx = { }

  getFullPath = (x) -> path.join fullPath, x
  matchesExts = (x) ->
    _(includedExts).isEmpty() or
    _(includedExts).include(path.extname x)

  Seq()
    .seq(-> fs.readdir fullPath, this)
    .seq((items) -> ctx.items = items; this(null, items))

    # Collect Files
    .flatten()
    .seqFilter((x) ->
      fu.isFile getFullPath(x), (err, isFile) =>
        isIncluded = (not _(ignoredFiles).include x) and matchesExts x
        this(null, isFile and isIncluded)
    )
    .unflatten()
    .seq((files) -> ctx.files = files; this(null, ctx.items))

    # Collect Folders
    .flatten().seqFilter((x) -> fu.isDirectory getFullPath(x), this).unflatten()
    .seq((subFolders) -> callback(null, { files: ctx.files, subFolders }))

getFoldersRec = (name, fullPath, depth, includedExts, ignoredFiles, done) ->
  ctx = { }

  getFullPath = (x) -> path.join fullPath, x

  Seq()
    .seq(-> collectFilesAndFolders fullPath, includedExts, ignoredFiles, this)
    .seq((res) ->
      # Call back immediately if there are no sub folders
      if res.subFolders.length == 0
        done null, new Folder(name, fullPath, depth, res.files, [])
      else
        ctx = res
        this(null, res.subFolders)
    )
    # Handle all subfolders
    .flatten().seqMap((folder) ->
      getFoldersRec(
        "#{name}/#{folder}"
        getFullPath(folder)
        depth + 1
        includedExts
        ignoredFiles
        this)
    ).unflatten()
    .seq((folders) ->
      done null, new Folder(name, fullPath, depth, ctx.files, folders)
      this())

getFoldersRec(
  "bdd_nodechat"
  root_dir
  0
  includedExts
  ignoredFiles
  (err, res) ->
    console.log res
 )
