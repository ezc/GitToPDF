// https://github.com/DTrejo/run.js
// Used to run code in a directory and rerun it if any files are changed.
// usage: node run.js servercode.js
// servercode.js is whatever js file you want to run with node.

// Excludes filetypes in the ignoreExtensions array
var util = require('util')
  , fs = require('fs')
  , spawn = require('child_process').spawn
  , child // child process which runs the actual code
  , ignoreExtensions = ['.dirtydb', '.db', '.css', '.js']
  , runner = 'node' // switched out for coffee depending on extension.
  ;

if (process.argv.length !== 3) {
  console.log('Found ' + (process.argv.length - 1)
             + ' argument(s). Expected two.');
  console.log('Usage: \n  node run.js servercode.js');
  process.exit(1); // exit w/ an error code.
}

if (process.argv[2].match(/\.coffee$/)) runner = 'coffee';
if (process.argv[2].match(/\.sh$/)) runner = 'sh';

run();
watchFiles(parseFolder('.'), restart); // watch all files, restart if problem

process.stdin.resume();
process.stdin.setEncoding('utf8');

// executes the command given by the second argument
function run() {
  // run the server
  child = spawn(runner, [process.argv[2]]);

  // let the child's output escape.
  child.stdout.on('data', function(data) {
    util.print(data);
  });
  child.stderr.on('data', function(error) {
    util.print(error);
  });

  // let the user's typing get to the child
  process.stdin.pipe(child.stdin);

  console.log('\nStarting: ' + process.argv[2]);
}

function restart() {
  // kill if running
  if (child) child.kill();

  // run it again
  run();
}

/**
* Parses a folder and returns a list of files
*
* @param root {String}
* @return {Array}
*/
function parseFolder(root) {
  var fileList = []
    , files = fs.readdirSync(root);

  files.forEach(function(file) {
    var path = root + '/' + file
      , stat = fs.statSync(path);

    // add to list
    if (stat !== undefined && !stat.isDirectory()) {
      fileList.push(path);
    }

    // recur if directory, ignore dot directories and node_modules
    if (stat !== undefined && stat.isDirectory() && file.indexOf('.') !== 0 && file.indexOf('node_modules') !== 0) {
      fileList = fileList.concat(parseFolder(path));
    }
  });

  return fileList;
}


/**
* Adds change listener to the files
*
* @param files {Array}
*/
function watchFiles(files, callback) {

  var config = {  persistent: true, interval: 1 };

  console.log("Watching: ");

  files.forEach(function (file) {

    // don't watch things with given extensions, don't watch dotfiles.
    var ext = file.slice(file.lastIndexOf('.'), file.length);
    if (ignoreExtensions.indexOf(ext) !== -1 || file.indexOf('./.') === 0) {
      return;
    }

    console.log(file);

    // if one of the files changes
    fs.watchFile(file, config, function (curr, prev) {

      if ((curr.mtime + '') != (prev.mtime + '')) {
        console.log(file + ' changed');

        if (callback !== undefined) {
          callback();
        }
      }
    });
  });
}
