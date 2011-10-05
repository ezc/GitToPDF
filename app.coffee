#!/usr/bin/env coffee

_ = require 'underscore'
http = require 'http'
url = require 'url'

getIndex = (req, res) ->
  console.log "getting index"
  res.writeHead 200, { 'Content-Type': 'text/plain' }
  res.end 'Index'

getConvert = (req, res, query) ->
  console.log "getting converter"
  res.writeHead 200, { 'Content-Type': 'text/plain' }
  res.end "Converting: #{query}"

routes =
  '/'           : getIndex
  '/convert'    : getConvert
  '/favicon.ico': (req, res) ->


server = http.createServer (req, res) ->
  uri = url.parse req.url
  path = uri.pathname
  query = uri.query
  
  console.log "uri", uri

  if routes[path]
    routes[path](req, res, query)
  else
    console.log "cannot route", path
    res.writeHead 400, { 'Content-Type': 'text/plain' }
    res.end 'Not found'


server.listen 3000, 'localhost'

console.log 'Server running on localhost port 3000'

